# frozen_string_literal: true

module PaperTrail
  # Represents the "paper trail" for a single record.
  class RecordTrail
    DPR_TOUCH_WITH_VERSION = <<-STR.squish.freeze
      my_model.paper_trail.touch_with_version is deprecated, please use
      my_model.paper_trail.save_with_version, which is slightly different. It's
      a save, not a touch, so make sure you understand the difference by reading
      the ActiveRecord documentation for both.
    STR
    DPR_WHODUNNIT = <<-STR.squish.freeze
      my_model_instance.paper_trail.whodunnit('John') is deprecated,
      please use PaperTrail.request(whodunnit: 'John')
    STR
    DPR_WITHOUT_VERSIONING = <<-STR
      my_model_instance.paper_trail.without_versioning is deprecated, without
      an exact replacement. To disable versioning for a particular model,

      ```
      PaperTrail.request.disable_model(Banana)
      # changes to Banana model do not create versions,
      # but eg. changes to Kiwi model do.
      PaperTrail.request.enable_model(Banana)
      ```

      Or, you may want to disable all models,

      ```
      PaperTrail.request.enabled = false
      # no versions created
      PaperTrail.request.enabled = true

      # or, with a block,
      PaperTrail.request(enabled: false) do
        # no versions created
      end
      ```
    STR

    RAILS_GTE_5_1 = ::ActiveRecord.gem_version >= ::Gem::Version.new("5.1.0.beta1")

    def initialize(record)
      @record = record
      @in_after_callback = false
    end

    def attributes_before_change(is_touch)
      Hash[@record.attributes.map do |k, v|
        if @record.class.column_names.include?(k)
          [k, attribute_in_previous_version(k, is_touch)]
        else
          [k, v]
        end
      end]
    end

    def changed_and_not_ignored
      ignore = @record.paper_trail_options[:ignore].dup
      # Remove Hash arguments and then evaluate whether the attributes (the
      # keys of the hash) should also get pushed into the collection.
      ignore.delete_if do |obj|
        obj.is_a?(Hash) &&
          obj.each { |attr, condition|
            ignore << attr if condition.respond_to?(:call) && condition.call(@record)
          }
      end
      skip = @record.paper_trail_options[:skip]
      changed_in_latest_version - ignore - skip
    end

    # Invoked after rollbacks to ensure versions records are not created for
    # changes that never actually took place. Optimization: Use lazy `reset`
    # instead of eager `reload` because, in many use cases, the association will
    # not be used.
    def clear_rolled_back_versions
      versions.reset
    end

    # Invoked via`after_update` callback for when a previous version is
    # reified and then saved.
    def clear_version_instance
      @record.send("#{@record.class.version_association_name}=", nil)
    end

    # Determines whether it is appropriate to generate a new version
    # instance. A timestamp-only update (e.g. only `updated_at` changed) is
    # considered notable unless an ignored attribute was also changed.
    def changed_notably?
      if ignored_attr_has_changed?
        timestamps = @record.send(:timestamp_attributes_for_update_in_model).map(&:to_s)
        (notably_changed - timestamps).any?
      else
        notably_changed.any?
      end
    end

    # @api private
    def changes
      notable_changes = changes_in_latest_version.delete_if { |k, _v|
        !notably_changed.include?(k)
      }
      AttributeSerializers::ObjectChangesAttribute.
        new(@record.class).
        serialize(notable_changes)
      notable_changes.to_hash
    end

    # Is PT enabled for this particular record?
    # @api private
    def enabled?
      PaperTrail.enabled? &&
        PaperTrail.request.enabled? &&
        PaperTrail.request.enabled_for_model?(@record.class)
    end

    # Not sure why, but this method was mentioned in the README in the past,
    # so we need to deprecate it properly.
    # @deprecated
    def enabled_for_model?
      ::ActiveSupport::Deprecation.warn(
        "MyModel#paper_trail.enabled_for_model? is deprecated, use " \
        "PaperTrail.request.enabled_for_model?(MyModel) instead.",
        caller(1)
      )
      PaperTrail.request.enabled_for_model?(@record.class)
    end

    # An attributed is "ignored" if it is listed in the `:ignore` option
    # and/or the `:skip` option.  Returns true if an ignored attribute has
    # changed.
    def ignored_attr_has_changed?
      ignored = @record.paper_trail_options[:ignore] + @record.paper_trail_options[:skip]
      ignored.any? && (changed_in_latest_version & ignored).any?
    end

    # Returns true if this instance is the current, live one;
    # returns false if this instance came from a previous version.
    def live?
      source_version.nil?
    end

    # Updates `data` from the model's `meta` option and from `controller_info`.
    # Metadata is always recorded; that means all three events (create, update,
    # destroy) and `update_columns`.
    # @api private
    def merge_metadata_into(data)
      merge_metadata_from_model_into(data)
      merge_metadata_from_controller_into(data)
    end

    # Updates `data` from `controller_info`.
    # @api private
    def merge_metadata_from_controller_into(data)
      data.merge(PaperTrail.request.controller_info || {})
    end

    # Updates `data` from the model's `meta` option.
    # @api private
    def merge_metadata_from_model_into(data)
      @record.paper_trail_options[:meta].each do |k, v|
        data[k] = model_metadatum(v, data[:event])
      end
    end

    # Given a `value` from the model's `meta` option, returns an object to be
    # persisted. The `value` can be a simple scalar value, but it can also
    # be a symbol that names a model method, or even a Proc.
    # @api private
    def model_metadatum(value, event)
      if value.respond_to?(:call)
        value.call(@record)
      elsif value.is_a?(Symbol) && @record.respond_to?(value, true)
        # If it is an attribute that is changing in an existing object,
        # be sure to grab the current version.
        if event != "create" &&
            @record.has_attribute?(value) &&
            attribute_changed_in_latest_version?(value)
          attribute_in_previous_version(value, false)
        else
          @record.send(value)
        end
      else
        value
      end
    end

    # Returns the object (not a Version) as it became next.
    # NOTE: if self (the item) was not reified from a version, i.e. it is the
    #  "live" item, we return nil.  Perhaps we should return self instead?
    def next_version
      subsequent_version = source_version.next
      subsequent_version ? subsequent_version.reify : @record.class.find(@record.id)
    rescue StandardError # TODO: Rescue something more specific
      nil
    end

    def notably_changed
      only = @record.paper_trail_options[:only].dup
      # Remove Hash arguments and then evaluate whether the attributes (the
      # keys of the hash) should also get pushed into the collection.
      only.delete_if do |obj|
        obj.is_a?(Hash) &&
          obj.each { |attr, condition|
            only << attr if condition.respond_to?(:call) && condition.call(@record)
          }
      end
      only.empty? ? changed_and_not_ignored : (changed_and_not_ignored & only)
    end

    # Returns hash of attributes (with appropriate attributes serialized),
    # omitting attributes to be skipped.
    #
    # @api private
    def object_attrs_for_paper_trail(is_touch)
      attrs = attributes_before_change(is_touch).
        except(*@record.paper_trail_options[:skip])
      AttributeSerializers::ObjectAttribute.new(@record.class).serialize(attrs)
      attrs
    end

    # Returns who put `@record` into its current state.
    #
    # @api public
    def originator
      (source_version || versions.last).try(:whodunnit)
    end

    # Returns the object (not a Version) as it was most recently.
    #
    # @api public
    def previous_version
      (source_version ? source_version.previous : versions.last).try(:reify)
    end

    def record_create
      @in_after_callback = true
      return unless enabled?
      versions_assoc = @record.send(@record.class.versions_association_name)
      versions_assoc.create! data_for_create
    ensure
      @in_after_callback = false
    end

    # Returns data for record create
    # @api private
    def data_for_create
      data = {
        event: @record.paper_trail_event || "create",
        whodunnit: PaperTrail.request.whodunnit
      }
      if @record.respond_to?(:updated_at)
        data[:created_at] = @record.updated_at
      end
      if record_object_changes? && changed_notably?
        data[:object_changes] = recordable_object_changes(changes)
      end
      merge_metadata_into(data)
    end

    # `recording_order` is "after" or "before". See ModelConfig#on_destroy.
    #
    # @api private
    # @return - The created version object, so that plugins can use it, e.g.
    # paper_trail-association_tracking
    def record_destroy(recording_order)
      @in_after_callback = recording_order == "after"
      if enabled? && !@record.new_record?
        version = @record.class.paper_trail.version_class.create(data_for_destroy)
        if version.errors.any?
          log_version_errors(version, :destroy)
        else
          @record.send("#{@record.class.version_association_name}=", version)
          @record.send(@record.class.versions_association_name).reset
          version
        end
      end
    ensure
      @in_after_callback = false
    end

    # Returns data for record destroy
    # @api private
    def data_for_destroy
      data = {
        item_id: @record.id,
        item_type: @record.class.base_class.name,
        event: @record.paper_trail_event || "destroy",
        object: recordable_object(false),
        whodunnit: PaperTrail.request.whodunnit
      }
      merge_metadata_into(data)
    end

    # Returns a boolean indicating whether to store serialized version diffs
    # in the `object_changes` column of the version record.
    # @api private
    def record_object_changes?
      @record.paper_trail_options[:save_changes] &&
        @record.class.paper_trail.version_class.column_names.include?("object_changes")
    end

    # @api private
    # @return - The created version object, so that plugins can use it, e.g.
    # paper_trail-association_tracking
    def record_update(force:, in_after_callback:, is_touch:)
      @in_after_callback = in_after_callback
      if enabled? && (force || changed_notably?)
        versions_assoc = @record.send(@record.class.versions_association_name)
        version = versions_assoc.create(data_for_update(is_touch))
        if version.errors.any?
          log_version_errors(version, :update)
        else
          version
        end
      end
    ensure
      @in_after_callback = false
    end

    # Used during `record_update`, returns a hash of data suitable for an AR
    # `create`. That is, all the attributes of the nascent `Version` record.
    #
    # @api private
    def data_for_update(is_touch)
      data = {
        event: @record.paper_trail_event || "update",
        object: recordable_object(is_touch),
        whodunnit: PaperTrail.request.whodunnit
      }
      if @record.respond_to?(:updated_at)
        data[:created_at] = @record.updated_at
      end
      if record_object_changes?
        data[:object_changes] = recordable_object_changes(changes)
      end
      merge_metadata_into(data)
    end

    # @api private
    # @return - The created version object, so that plugins can use it, e.g.
    # paper_trail-association_tracking
    def record_update_columns(changes)
      return unless enabled?
      versions_assoc = @record.send(@record.class.versions_association_name)
      version = versions_assoc.create(data_for_update_columns(changes))
      if version.errors.any?
        log_version_errors(version, :update)
      else
        version
      end
    end

    # Returns data for record_update_columns
    # @api private
    def data_for_update_columns(changes)
      data = {
        event: @record.paper_trail_event || "update",
        object: recordable_object(false),
        whodunnit: PaperTrail.request.whodunnit
      }
      if record_object_changes?
        data[:object_changes] = recordable_object_changes(changes)
      end
      merge_metadata_into(data)
    end

    # Returns an object which can be assigned to the `object` attribute of a
    # nascent version record. If the `object` column is a postgres `json`
    # column, then a hash can be used in the assignment, otherwise the column
    # is a `text` column, and we must perform the serialization here, using
    # `PaperTrail.serializer`.
    #
    # @api private
    def recordable_object(is_touch)
      if @record.class.paper_trail.version_class.object_col_is_json?
        object_attrs_for_paper_trail(is_touch)
      else
        PaperTrail.serializer.dump(object_attrs_for_paper_trail(is_touch))
      end
    end

    # Returns an object which can be assigned to the `object_changes`
    # attribute of a nascent version record. If the `object_changes` column is
    # a postgres `json` column, then a hash can be used in the assignment,
    # otherwise the column is a `text` column, and we must perform the
    # serialization here, using `PaperTrail.serializer`.
    #
    # @api private
    def recordable_object_changes(changes)
      if PaperTrail.config.object_changes_adapter
        changes = PaperTrail.config.object_changes_adapter.diff(changes)
      end

      if @record.class.paper_trail.version_class.object_changes_col_is_json?
        changes
      else
        PaperTrail.serializer.dump(changes)
      end
    end

    # Invoked via callback when a user attempts to persist a reified
    # `Version`.
    def reset_timestamp_attrs_for_update_if_needed
      return if live?
      @record.send(:timestamp_attributes_for_update_in_model).each do |column|
        @record.send("restore_#{column}!")
      end
    end

    # AR callback.
    # @api private
    def save_version?
      if_condition = @record.paper_trail_options[:if]
      unless_condition = @record.paper_trail_options[:unless]
      (if_condition.blank? || if_condition.call(@record)) && !unless_condition.try(:call, @record)
    end

    def source_version
      version
    end

    # Mimics the `touch` method from `ActiveRecord::Persistence` (without
    # actually calling `touch`), but also creates a version.
    #
    # A version is created regardless of options such as `:on`, `:if`, or
    # `:unless`.
    #
    # This is an "update" event. That is, we record the same data we would in
    # the case of a normal AR `update`.
    #
    # Some advanced PT users disable all callbacks (eg. `has_paper_trail(on:
    # [])`) and use only this method, giving them complete control over when
    # version records are inserted. It's unclear under which specific
    # circumstances this technique should be adopted.
    #
    # @deprecated
    def touch_with_version(name = nil)
      ::ActiveSupport::Deprecation.warn(DPR_TOUCH_WITH_VERSION, caller(1))
      unless @record.persisted?
        raise ::ActiveRecord::ActiveRecordError, "can not touch on a new record object"
      end
      attributes = @record.send :timestamp_attributes_for_update_in_model
      attributes << name if name
      current_time = @record.send :current_time_from_proper_timezone
      attributes.each { |column|
        @record.send(:write_attribute, column, current_time)
      }
      ::PaperTrail.request(enabled: false) do
        @record.save!(validate: false)
      end
      record_update(force: true, in_after_callback: false, is_touch: false)
    end

    # Save, and create a version record regardless of options such as `:on`,
    # `:if`, or `:unless`.
    #
    # Arguments are passed to `save`.
    #
    # This is an "update" event. That is, we record the same data we would in
    # the case of a normal AR `update`.
    #
    # In older versions of PaperTrail, a method named `touch_with_version` was
    # used for this purpose. `save_with_version` is not exactly the same.
    # First, the arguments are different. It passes all arguments to `save`.
    # Second, it doesn't set any timestamp attributes prior to the `save` the
    # way `touch_with_version` did.
    def save_with_version(*args)
      ::PaperTrail.request(enabled: false) do
        @record.save(*args)
      end
      record_update(force: true, in_after_callback: false, is_touch: false)
    end

    # Like the `update_column` method from `ActiveRecord::Persistence`, but also
    # creates a version to record those changes.
    # @api public
    def update_column(name, value)
      update_columns(name => value)
    end

    # Like the `update_columns` method from `ActiveRecord::Persistence`, but also
    # creates a version to record those changes.
    # @api public
    def update_columns(attributes)
      # `@record.update_columns` skips dirty tracking, so we can't just use `@record.changes` or
      # @record.saved_changes` from `ActiveModel::Dirty`. We need to build our own hash with the
      # changes that will be made directly to the database.
      changes = {}
      attributes.each do |k, v|
        changes[k] = [@record[k], v]
      end
      @record.update_columns(attributes)
      record_update_columns(changes)
    end

    # Returns the object (not a Version) as it was at the given timestamp.
    def version_at(timestamp, reify_options = {})
      # Because a version stores how its object looked *before* the change,
      # we need to look for the first version created *after* the timestamp.
      v = versions.subsequent(timestamp, true).first
      return v.reify(reify_options) if v
      @record unless @record.destroyed?
    end

    # Returns the objects (not Versions) as they were between the given times.
    def versions_between(start_time, end_time)
      versions = send(@record.class.versions_association_name).between(start_time, end_time)
      versions.collect { |version| version_at(version.created_at) }
    end

    # Executes the given method or block without creating a new version.
    # @deprecated
    def without_versioning(method = nil)
      ::ActiveSupport::Deprecation.warn(DPR_WITHOUT_VERSIONING, caller(1))
      paper_trail_was_enabled = PaperTrail.request.enabled_for_model?(@record.class)
      PaperTrail.request.disable_model(@record.class)
      if method
        if respond_to?(method)
          public_send(method)
        else
          @record.send(method)
        end
      else
        yield @record
      end
    ensure
      PaperTrail.request.enable_model(@record.class) if paper_trail_was_enabled
    end

    # @deprecated
    def whodunnit(value)
      raise ArgumentError, "expected to receive a block" unless block_given?
      ::ActiveSupport::Deprecation.warn(DPR_WHODUNNIT, caller(1))
      ::PaperTrail.request(whodunnit: value) do
        yield @record
      end
    end

    private

    # Rails 5.1 changed the API of `ActiveRecord::Dirty`. See
    # https://github.com/paper-trail-gem/paper_trail/pull/899
    #
    # @api private
    def attribute_changed_in_latest_version?(attr_name)
      if @in_after_callback && RAILS_GTE_5_1
        @record.saved_change_to_attribute?(attr_name.to_s)
      else
        @record.attribute_changed?(attr_name.to_s)
      end
    end

    # Rails 5.1 changed the API of `ActiveRecord::Dirty`. See
    # https://github.com/paper-trail-gem/paper_trail/pull/899
    #
    # Event can be any of the three (create, update, destroy).
    #
    # @api private
    def attribute_in_previous_version(attr_name, is_touch)
      if RAILS_GTE_5_1
        if @in_after_callback && !is_touch
          # For most events, we want the original value of the attribute, before
          # the last save.
          @record.attribute_before_last_save(attr_name.to_s)
        else
          # We are either performing a `record_destroy` or a
          # `record_update(is_touch: true)`.
          @record.attribute_in_database(attr_name.to_s)
        end
      else
        @record.attribute_was(attr_name.to_s)
      end
    end

    # Rails 5.1 changed the API of `ActiveRecord::Dirty`. See
    # https://github.com/paper-trail-gem/paper_trail/pull/899
    #
    # @api private
    def changed_in_latest_version
      if @in_after_callback && RAILS_GTE_5_1
        @record.saved_changes.keys
      else
        @record.changed
      end
    end

    # Rails 5.1 changed the API of `ActiveRecord::Dirty`. See
    # https://github.com/paper-trail-gem/paper_trail/pull/899
    #
    # @api private
    def changes_in_latest_version
      if @in_after_callback && RAILS_GTE_5_1
        @record.saved_changes
      else
        @record.changes
      end
    end

    def log_version_errors(version, action)
      version.logger&.warn(
        "Unable to create version for #{action} of #{@record.class.name}" \
          "##{@record.id}: " + version.errors.full_messages.join(", ")
      )
    end

    def version
      @record.public_send(@record.class.version_association_name)
    end

    def versions
      @record.public_send(@record.class.versions_association_name)
    end
  end
end
