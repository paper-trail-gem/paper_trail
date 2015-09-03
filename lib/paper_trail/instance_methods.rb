 module PaperTrail
  module Model   
    module InstanceMethods
      # Returns true if this instance is the current, live one;
      # returns false if this instance came from a previous version.
      def live?
        source_version.nil?
      end

      # Returns who put the object into its current state.
      def paper_trail_originator
        (source_version || send(self.class.versions_association_name).last).try(:whodunnit)
      end

      def originator
        ::ActiveSupport::Deprecation.warn "Use paper_trail_originator instead of originator."
        self.paper_trail_originator
      end

      # Invoked after rollbacks to ensure versions records are not created
      # for changes that never actually took place
      def clear_rolled_back_versions
        send(self.class.versions_association_name).reload
      end

      # Returns the object (not a Version) as it was at the given timestamp.
      def version_at(timestamp, reify_options={})
        # Because a version stores how its object looked *before* the change,
        # we need to look for the first version created *after* the timestamp.
        v = send(self.class.versions_association_name).subsequent(timestamp, true).first
        return v.reify(reify_options) if v
        self unless self.destroyed?
      end

      # Returns the objects (not Versions) as they were between the given times.
      def versions_between(start_time, end_time, reify_options={})
        versions = send(self.class.versions_association_name).between(start_time, end_time)
        versions.collect { |version| version_at(version.send PaperTrail.timestamp_field) }
      end

      # Returns the object (not a Version) as it was most recently.
      def previous_version
        preceding_version = source_version ? source_version.previous : send(self.class.versions_association_name).last
        preceding_version.reify if preceding_version
      end

      # Returns the object (not a Version) as it became next.
      # NOTE: if self (the item) was not reified from a version, i.e. it is the
      #  "live" item, we return nil.  Perhaps we should return self instead?
      def next_version
        subsequent_version = source_version.next
        subsequent_version ? subsequent_version.reify : self.class.find(self.id)
      rescue
        nil
      end

      def paper_trail_enabled_for_model?
        self.class.paper_trail_enabled_for_model?
      end

      # Executes the given method or block without creating a new version.
      def without_versioning(method = nil)
        paper_trail_was_enabled = self.paper_trail_enabled_for_model?
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
        raise ArgumentError, 'expected to receive a block' unless block_given?
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
      # `ActiveRecord` to allow the regular `touch` method go generate a version
      # as normal. May make sense to switch the `record_update` method to
      # leverage an `after_update` callback anyways (likely for v4.0.0)
      def touch_with_version(name = nil)
        raise ActiveRecordError, "can not touch on a new record object" unless persisted?

        attributes = timestamp_attributes_for_update_in_model
        attributes << name if name
        current_time = current_time_from_proper_timezone

        attributes.each { |column| write_attribute(column, current_time) }

        record_update(true) unless will_record_after_update?
        save!(:validate => false)
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
            :event     => paper_trail_event || 'create',
            :whodunnit => PaperTrail.whodunnit
          }
          if respond_to?(:updated_at)
            data[PaperTrail.timestamp_field] = updated_at
          end
          if paper_trail_options[:save_changes] && changed_notably? && self.class.paper_trail_version_class.column_names.include?('object_changes')
            data[:object_changes] = self.class.paper_trail_version_class.object_changes_col_is_json? ? changes_for_paper_trail :
              PaperTrail.serializer.dump(changes_for_paper_trail)
          end
          if self.class.paper_trail_version_class.column_names.include?('transaction_id')
            data[:transaction_id] = PaperTrail.transaction_id
          end
          version = send(self.class.versions_association_name).create! merge_metadata(data)
          set_transaction_id(version)
          save_associations(version)
        end
      end

      def record_update(force = nil)
        if paper_trail_switched_on? && (force || changed_notably?)
          object_attrs = object_attrs_for_paper_trail(attributes_before_change)
          data = {
            :event     => paper_trail_event || 'update',
            :object    => self.class.paper_trail_version_class.object_col_is_json? ? object_attrs : PaperTrail.serializer.dump(object_attrs),
            :whodunnit => PaperTrail.whodunnit
          }
          if respond_to?(:updated_at)
            data[PaperTrail.timestamp_field] = updated_at
          end
          if paper_trail_options[:save_changes] && self.class.paper_trail_version_class.column_names.include?('object_changes')
            data[:object_changes] = self.class.paper_trail_version_class.object_changes_col_is_json? ? changes_for_paper_trail :
              PaperTrail.serializer.dump(changes_for_paper_trail)
          end
          if self.class.paper_trail_version_class.column_names.include?('transaction_id')
            data[:transaction_id] = PaperTrail.transaction_id
          end
          version = send(self.class.versions_association_name).create merge_metadata(data)
          set_transaction_id(version)
          save_associations(version)
        end
      end

      def changes_for_paper_trail
        _changes = changes.delete_if { |k,v| !notably_changed.include?(k) }
        if PaperTrail.serialized_attributes?
          self.class.serialize_attribute_changes_for_paper_trail!(_changes)
        end
        _changes.to_hash
      end

      # Invoked via`after_update` callback for when a previous version is
      # reified and then saved.
      def clear_version_instance!
        send("#{self.class.version_association_name}=", nil)
      end

      # Invoked via callback when a user attempts to persist a reified
      # `Version`.
      def reset_timestamp_attrs_for_update_if_needed!
        return if self.live?
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
        if paper_trail_switched_on? and not new_record?
          object_attrs = object_attrs_for_paper_trail(attributes_before_change)
          data = {
            :item_id   => self.id,
            :item_type => self.class.base_class.name,
            :event     => paper_trail_event || 'destroy',
            :object    => self.class.paper_trail_version_class.object_col_is_json? ? object_attrs : PaperTrail.serializer.dump(object_attrs),
            :whodunnit => PaperTrail.whodunnit
          }
          if self.class.paper_trail_version_class.column_names.include?('transaction_id')
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
              :version_id => version.id,
              :foreign_key_name => assoc.foreign_key
          }

          if assoc.options[:polymorphic]
            associated_record = send(assoc.name) if send(assoc.foreign_type)
            if associated_record && associated_record.class.paper_trail_enabled_for_model?
              assoc_version_args.merge!(:foreign_key_id => associated_record.id)
            end
          elsif assoc.klass.paper_trail_enabled_for_model?
            assoc_version_args.merge!(:foreign_key_id => send(assoc.foreign_key))
          end

          PaperTrail::VersionAssociation.create(assoc_version_args) if assoc_version_args.has_key?(:foreign_key_id)
        end
      end

      def set_transaction_id(version)
        return unless self.class.paper_trail_version_class.column_names.include?('transaction_id')
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
        paper_trail_options[:meta].each do |k,v|
          data[k] =
            if v.respond_to?(:call)
              v.call(self)
            elsif v.is_a?(Symbol) && respond_to?(v)
              # If it is an attribute that is changing in an existing object,
              # be sure to grab the current version.
              if has_attribute?(v) && send("#{v}_changed?".to_sym) && data[:event] != 'create'
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
        attributes.tap do |prev|
          enums = self.respond_to?(:defined_enums) ? self.defined_enums : {}
          changed_attributes.select { |k,v| self.class.column_names.include?(k) }.each do |attr, before|
            before = enums[attr][before] if enums[attr]
            prev[attr] = before
          end
        end
      end

      # Returns hash of attributes (with appropriate attributes serialized),
      # ommitting attributes to be skipped.
      def object_attrs_for_paper_trail(attributes_hash)
        attrs = attributes_hash.except(*paper_trail_options[:skip])
        if PaperTrail.serialized_attributes?
          self.class.serialize_attributes_for_paper_trail!(attrs)
        end
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
          obj.is_a?(Hash) && obj.each { |attr, condition| only << attr if condition.respond_to?(:call) && condition.call(self) }
        end
        only.empty? ? changed_and_not_ignored : (changed_and_not_ignored & only)
      end

      def changed_and_not_ignored
        ignore = self.paper_trail_options[:ignore].dup
        # Remove Hash arguments and then evaluate whether the attributes (the
        # keys of the hash) should also get pushed into the collection.
        ignore.delete_if do |obj|
          obj.is_a?(Hash) && obj.each { |attr, condition| ignore << attr if condition.respond_to?(:call) && condition.call(self) }
        end
        skip = self.paper_trail_options[:skip]
        changed - ignore - skip
      end

      def paper_trail_switched_on?
        PaperTrail.enabled? && PaperTrail.enabled_for_controller? && self.paper_trail_enabled_for_model?
      end

      def save_version?
        if_condition     = self.paper_trail_options[:if]
        unless_condition = self.paper_trail_options[:unless]
        (if_condition.blank? || if_condition.call(self)) && !unless_condition.try(:call, self)
      end
    end
  end
end
