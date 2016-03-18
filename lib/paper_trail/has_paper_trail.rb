require "active_support/core_ext/object" # provides the `try` method
require "paper_trail/attributes_serialization"

module PaperTrail
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      # Declare this in your model to track every create, update, and destroy.
      # Each version of the model is available in the `versions` association.
      #
      # Options:
      #
      # - :on - The events to track (optional; defaults to all of them). Set
      #   to an array of `:create`, `:update`, `:destroy` as desired.
      # - :class_name - The name of a custom Version class.  This class should
      #   inherit from `PaperTrail::Version`.
      # - :ignore - An array of attributes for which a new `Version` will not be
      #   created if only they change. It can also aceept a Hash as an
      #   argument where the key is the attribute to ignore (a `String` or
      #   `Symbol`), which will only be ignored if the value is a `Proc` which
      #   returns truthily.
      # - :if, :unless - Procs that allow to specify conditions when to save
      #   versions for an object.
      # - :only - Inverse of `ignore`. A new `Version` will be created only
      #   for these attributes if supplied it can also aceept a Hash as an
      #   argument where the key is the attribute to track (a `String` or
      #   `Symbol`), which will only be counted if the value is a `Proc` which
      #   returns truthily.
      # - :skip - Fields to ignore completely.  As with `ignore`, updates to
      #   these fields will not create a new `Version`.  In addition, these
      #   fields will not be included in the serialized versions of the object
      #   whenever a new `Version` is created.
      # - :meta - A hash of extra data to store. You must add a column to the
      #   `versions` table for each key. Values are objects or procs (which
      #   are called with `self`, i.e. the model with the paper trail).  See
      #   `PaperTrail::Controller.info_for_paper_trail` for how to store data
      #   from the controller.
      # - :versions - The name to use for the versions association.  Default
      #   is `:versions`.
      # - :version - The name to use for the method which returns the version
      #   the instance was reified from. Default is `:version`.
      # - :save_changes - Whether or not to save changes to the object_changes
      #   column if it exists. Default is true
      #
      def has_paper_trail(options = {})
        options[:on] ||= [:create, :update, :destroy]

        # Wrap the :on option in an array if necessary. This allows a single
        # symbol to be passed in.
        options[:on] = Array(options[:on])

        setup_model_for_paper_trail(options)

        setup_callbacks_from_options options[:on]
      end

      def setup_model_for_paper_trail(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods
        send :extend, AttributesSerialization

        class_attribute :version_association_name
        self.version_association_name = options[:version] || :version

        # The version this instance was reified from.
        attr_accessor version_association_name

        class_attribute :version_class_name
        self.version_class_name = options[:class_name] || "PaperTrail::Version"

        class_attribute :paper_trail_options

        self.paper_trail_options = options.dup

        [:ignore, :skip, :only].each do |k|
          paper_trail_options[k] = [paper_trail_options[k]].flatten.compact.map { |attr|
            attr.is_a?(Hash) ? attr.stringify_keys : attr.to_s
          }
        end

        paper_trail_options[:meta] ||= {}
        paper_trail_options[:save_changes] = true if paper_trail_options[:save_changes].nil?

        class_attribute :versions_association_name
        self.versions_association_name = options[:versions] || :versions

        attr_accessor :paper_trail_event

        # `has_many` syntax for specifying order uses a lambda in Rails 4
        if ::ActiveRecord::VERSION::MAJOR >= 4
          has_many versions_association_name,
            -> { order(model.timestamp_sort_order) },
            class_name: version_class_name, as: :item
        else
          has_many versions_association_name,
            class_name: version_class_name,
            as: :item,
            order: paper_trail_version_class.timestamp_sort_order
        end

        # Reset the transaction id when the transaction is closed.
        after_commit :reset_transaction_id
        after_rollback :reset_transaction_id
        after_rollback :clear_rolled_back_versions
      end

      def setup_callbacks_from_options(options_on = [])
        options_on.each do |option|
          send "paper_trail_on_#{option}"
        end
      end

      # Record version before or after "destroy" event
      def paper_trail_on_destroy(recording_order = "before")
        unless %w(after before).include?(recording_order.to_s)
          raise ArgumentError, 'recording order can only be "after" or "before"'
        end

        if recording_order == "after" &&
            Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new("5")
          if ::ActiveRecord::Base.belongs_to_required_by_default
            ::ActiveSupport::Deprecation.warn(
              "paper_trail_on_destroy(:after) is incompatible with ActiveRecord " +
                "belongs_to_required_by_default and has no effect. Please use :before " +
                "or disable belongs_to_required_by_default."
            )
          end
        end

        send "#{recording_order}_destroy", :record_destroy, if: :save_version?

        return if paper_trail_options[:on].include?(:destroy)
        paper_trail_options[:on] << :destroy
      end

      # Record version after "update" event
      def paper_trail_on_update
        before_save :reset_timestamp_attrs_for_update_if_needed!, on: :update
        after_update :record_update, if: :save_version?
        after_update :clear_version_instance!

        return if paper_trail_options[:on].include?(:update)
        paper_trail_options[:on] << :update
      end

      # Record version after "create" event
      def paper_trail_on_create
        after_create :record_create, if: :save_version?

        return if paper_trail_options[:on].include?(:create)
        paper_trail_options[:on] << :create
      end

      # Switches PaperTrail off for this class.
      def paper_trail_off!
        PaperTrail.enabled_for_model(self, false)
      end

      # Switches PaperTrail on for this class.
      def paper_trail_on!
        PaperTrail.enabled_for_model(self, true)
      end

      def paper_trail_enabled_for_model?
        return false unless include?(PaperTrail::Model::InstanceMethods)
        PaperTrail.enabled_for_model?(self)
      end

      def paper_trail_version_class
        @paper_trail_version_class ||= version_class_name.constantize
      end
    end

    # Wrap the following methods in a module so we can include them only in the
    # ActiveRecord models that declare `has_paper_trail`.
    module InstanceMethods
      # Returns true if this instance is the current, live one;
      # returns false if this instance came from a previous version.
      def live?
        source_version.nil?
      end

      # Returns who put the object into its current state.
      def paper_trail_originator
        (source_version || send(self.class.versions_association_name).last).try(PaperTrail.whodunnit_field)
      end

      def originator
        ::ActiveSupport::Deprecation.warn "Use paper_trail_originator instead of originator."
        paper_trail_originator
      end

      # Invoked after rollbacks to ensure versions records are not created
      # for changes that never actually took place.
      # Optimization: Use lazy `reset` instead of eager `reload` because, in
      # many use cases, the association will not be used.
      def clear_rolled_back_versions
        send(self.class.versions_association_name).reset
      end

      # Returns the object (not a Version) as it was at the given timestamp.
      def version_at(timestamp, reify_options = {})
        # Because a version stores how its object looked *before* the change,
        # we need to look for the first version created *after* the timestamp.
        v = send(self.class.versions_association_name).subsequent(timestamp, true).first
        return v.reify(reify_options) if v
        self unless destroyed?
      end

      # Returns the objects (not Versions) as they were between the given times.
      # TODO: Either add support for the third argument, `_reify_options`, or
      # add a deprecation warning if someone tries to use it.
      def versions_between(start_time, end_time, _reify_options = {})
        versions = send(self.class.versions_association_name).between(start_time, end_time)
        versions.collect { |version| version_at(version.send(PaperTrail.timestamp_field)) }
      end

      # Returns the object (not a Version) as it was most recently.
      def previous_version
        preceding_version = source_version ?
          source_version.previous :
          send(self.class.versions_association_name).last
        preceding_version.reify if preceding_version
      end

      # Returns the object (not a Version) as it became next.
      # NOTE: if self (the item) was not reified from a version, i.e. it is the
      #  "live" item, we return nil.  Perhaps we should return self instead?
      def next_version
        subsequent_version = source_version.next
        subsequent_version ? subsequent_version.reify : self.class.find(id)
      rescue
        nil
      end

      def paper_trail_enabled_for_model?
        self.class.paper_trail_enabled_for_model?
      end

      # Executes the given method or block without creating a new version.
      def without_versioning(method = nil)
        paper_trail_was_enabled = paper_trail_enabled_for_model?
        self.class.paper_trail_off!
        method ? method.to_proc.call(self) : yield(self)
      ensure
        self.class.paper_trail_on! if paper_trail_was_enabled
      end

      # Utility method for reifying. Anything executed inside the block will
      # appear like a new record.
      def appear_as_new_record
        instance_eval {
          alias :old_new_record? :new_record?
          alias :new_record? :present?
        }
        yield
        instance_eval { alias :new_record? :old_new_record? }
      end

      # Temporarily overwrites the value of whodunnit and then executes the
      # provided block.
      def whodunnit(value)
        raise ArgumentError, "expected to receive a block" unless block_given?
        current_whodunnit = PaperTrail.whodunnit
        PaperTrail.whodunnit = value
        yield self
      ensure
        PaperTrail.whodunnit = current_whodunnit
      end

      # Mimics the `touch` method from `ActiveRecord::Persistence`, but also
      # creates a version. A version is created regardless of options such as
      # `:on`, `:if`, or `:unless`.
      #
      # TODO: look into leveraging the `after_touch` callback from
      # `ActiveRecord` to allow the regular `touch` method to generate a version
      # as normal. May make sense to switch the `record_update` method to
      # leverage an `after_update` callback anyways (likely for v4.0.0)
      def touch_with_version(name = nil)
        raise ActiveRecordError, "can not touch on a new record object" unless persisted?

        attributes = timestamp_attributes_for_update_in_model
        attributes << name if name
        current_time = current_time_from_proper_timezone

        attributes.each { |column| write_attribute(column, current_time) }

        record_update(true) unless will_record_after_update?
        save!(validate: false)
      end

      private

      # Returns true if `save` will cause `record_update`
      # to be called via the `after_update` callback.
      def will_record_after_update?
        on = paper_trail_options[:on]
        on.nil? || on.include?(:update)
      end

      def source_version
        send self.class.version_association_name
      end

      def record_create
        if paper_trail_switched_on?
          data = {
            event: paper_trail_event || 'create'
          }

          data[PaperTrail.whodunnit_field] = PaperTrail.whodunnit

          if respond_to?(:updated_at)
            data[PaperTrail.timestamp_field] = updated_at
          end
          if pt_record_object_changes? && changed_notably?
            data[:object_changes] = pt_recordable_object_changes
          end
          if self.class.paper_trail_version_class.column_names.include?("transaction_id")
            data[:transaction_id] = PaperTrail.transaction_id
          end
          version = send(self.class.versions_association_name).create! merge_metadata(data)
          set_transaction_id(version)
          save_associations(version)
        end
      end

      def record_update(force = nil)
        if paper_trail_switched_on? && (force || changed_notably?)
          data = {
            event: paper_trail_event || "update",
            object: pt_recordable_object
          }

          data[PaperTrail.whodunnit_field] = PaperTrail.whodunnit

          if respond_to?(:updated_at)
            data[PaperTrail.timestamp_field] = updated_at
          end
          if pt_record_object_changes?
            data[:object_changes] = pt_recordable_object_changes
          end
          if self.class.paper_trail_version_class.column_names.include?("transaction_id")
            data[:transaction_id] = PaperTrail.transaction_id
          end
          version = send(self.class.versions_association_name).create merge_metadata(data)
          set_transaction_id(version)
          save_associations(version)
        end
      end

      # Returns a boolean indicating whether to store serialized version diffs
      # in the `object_changes` column of the version record.
      # @api private
      def pt_record_object_changes?
        paper_trail_options[:save_changes] &&
          self.class.paper_trail_version_class.column_names.include?("object_changes")
      end

      # Returns an object which can be assigned to the `object` attribute of a
      # nascent version record. If the `object` column is a postgres `json`
      # column, then a hash can be used in the assignment, otherwise the column
      # is a `text` column, and we must perform the serialization here, using
      # `PaperTrail.serializer`.
      # @api private
      def pt_recordable_object
        if self.class.paper_trail_version_class.object_col_is_json?
          object_attrs_for_paper_trail
        else
          PaperTrail.serializer.dump(object_attrs_for_paper_trail)
        end
      end

      # Returns an object which can be assigned to the `object_changes`
      # attribute of a nascent version record. If the `object_changes` column is
      # a postgres `json` column, then a hash can be used in the assignment,
      # otherwise the column is a `text` column, and we must perform the
      # serialization here, using `PaperTrail.serializer`.
      # @api private
      def pt_recordable_object_changes
        if self.class.paper_trail_version_class.object_changes_col_is_json?
          changes_for_paper_trail
        else
          PaperTrail.serializer.dump(changes_for_paper_trail)
        end
      end

      def changes_for_paper_trail
        notable_changes = changes.delete_if { |k, _v| !notably_changed.include?(k) }
        self.class.serialize_attribute_changes_for_paper_trail!(notable_changes)
        notable_changes.to_hash
      end

      # Invoked via`after_update` callback for when a previous version is
      # reified and then saved.
      def clear_version_instance!
        send("#{self.class.version_association_name}=", nil)
      end

      # Invoked via callback when a user attempts to persist a reified
      # `Version`.
      def reset_timestamp_attrs_for_update_if_needed!
        return if live?
        timestamp_attributes_for_update_in_model.each do |column|
          # ActiveRecord 4.2 deprecated `reset_column!` in favor of
          # `restore_column!`.
          if respond_to?("restore_#{column}!")
            send("restore_#{column}!")
          else
            send("reset_#{column}!")
          end
        end
      end

      def record_destroy
        if paper_trail_switched_on? && !new_record?
          data = {
            item_id: id,
            item_type: self.class.base_class.name,
            event: paper_trail_event || "destroy",
            object: pt_recordable_object,
          }

          data[PaperTrail.whodunnit_field] = PaperTrail.whodunnit

          if self.class.paper_trail_version_class.column_names.include?("transaction_id")
            data[:transaction_id] = PaperTrail.transaction_id
          end
          version = self.class.paper_trail_version_class.create(merge_metadata(data))
          send("#{self.class.version_association_name}=", version)
          send(self.class.versions_association_name).send :load_target
          set_transaction_id(version)
          save_associations(version)
        end
      end

      # Saves associations if the join table for `VersionAssociation` exists.
      def save_associations(version)
        return unless PaperTrail.config.track_associations?
        self.class.reflect_on_all_associations(:belongs_to).each do |assoc|
          assoc_version_args = {
            version_id: version.id,
            foreign_key_name: assoc.foreign_key
          }

          if assoc.options[:polymorphic]
            associated_record = send(assoc.name) if send(assoc.foreign_type)
            if associated_record && associated_record.class.paper_trail_enabled_for_model?
              assoc_version_args[:foreign_key_id] = associated_record.id
            end
          elsif assoc.klass.paper_trail_enabled_for_model?
            assoc_version_args[:foreign_key_id] = send(assoc.foreign_key)
          end

          if assoc_version_args.key?(:foreign_key_id)
            PaperTrail::VersionAssociation.create(assoc_version_args)
          end
        end
      end

      def set_transaction_id(version)
        return unless self.class.paper_trail_version_class.column_names.include?("transaction_id")
        if PaperTrail.transaction? && PaperTrail.transaction_id.nil?
          PaperTrail.transaction_id = version.id
          version.transaction_id = version.id
          version.save
        end
      end

      def reset_transaction_id
        PaperTrail.transaction_id = nil
      end

      def merge_metadata(data)
        # First we merge the model-level metadata in `meta`.
        paper_trail_options[:meta].each do |k, v|
          data[k] =
            if v.respond_to?(:call)
              v.call(self)
            elsif v.is_a?(Symbol) && respond_to?(v)
              # If it is an attribute that is changing in an existing object,
              # be sure to grab the current version.
              if has_attribute?(v) && send("#{v}_changed?".to_sym) && data[:event] != "create"
                send("#{v}_was".to_sym)
              else
                send(v)
              end
            else
              v
            end
        end

        # Second we merge any extra data from the controller (if available).
        data.merge(PaperTrail.controller_info || {})
      end

      def attributes_before_change
        changed = changed_attributes.select { |k, _v| self.class.column_names.include?(k) }
        attributes.merge(changed)
      end

      # Returns hash of attributes (with appropriate attributes serialized),
      # ommitting attributes to be skipped.
      def object_attrs_for_paper_trail
        attrs = attributes_before_change.except(*paper_trail_options[:skip])
        self.class.serialize_attributes_for_paper_trail!(attrs)
        attrs
      end

      # Determines whether it is appropriate to generate a new version
      # instance. A timestamp-only update (e.g. only `updated_at` changed) is
      # considered notable unless an ignored attribute was also changed.
      def changed_notably?
        if ignored_attr_has_changed?
          timestamps = timestamp_attributes_for_update_in_model.map(&:to_s)
          (notably_changed - timestamps).any?
        else
          notably_changed.any?
        end
      end

      # An attributed is "ignored" if it is listed in the `:ignore` option
      # and/or the `:skip` option.  Returns true if an ignored attribute has
      # changed.
      def ignored_attr_has_changed?
        ignored = paper_trail_options[:ignore] + paper_trail_options[:skip]
        ignored.any? && (changed & ignored).any?
      end

      def notably_changed
        only = paper_trail_options[:only].dup
        # Remove Hash arguments and then evaluate whether the attributes (the
        # keys of the hash) should also get pushed into the collection.
        only.delete_if do |obj|
          obj.is_a?(Hash) &&
            obj.each { |attr, condition|
              only << attr if condition.respond_to?(:call) && condition.call(self)
            }
        end
        only.empty? ? changed_and_not_ignored : (changed_and_not_ignored & only)
      end

      def changed_and_not_ignored
        ignore = paper_trail_options[:ignore].dup
        # Remove Hash arguments and then evaluate whether the attributes (the
        # keys of the hash) should also get pushed into the collection.
        ignore.delete_if do |obj|
          obj.is_a?(Hash) &&
            obj.each { |attr, condition|
              ignore << attr if condition.respond_to?(:call) && condition.call(self)
            }
        end
        skip = paper_trail_options[:skip]
        changed - ignore - skip
      end

      def paper_trail_switched_on?
        PaperTrail.enabled? &&
          PaperTrail.enabled_for_controller? &&
          paper_trail_enabled_for_model?
      end

      def save_version?
        if_condition     = paper_trail_options[:if]
        unless_condition = paper_trail_options[:unless]
        (if_condition.blank? || if_condition.call(self)) && !unless_condition.try(:call, self)
      end
    end
  end
end
