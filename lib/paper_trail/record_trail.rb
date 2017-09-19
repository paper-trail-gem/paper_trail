module PaperTrail
  # Represents the "paper trail" for a single record.
  class RecordTrail
    # The respond_to? check here is specific to ActiveRecord 4.0 and can be
    # removed when support for ActiveRecord < 4.2 is dropped.
    RAILS_GTE_5_1 = ::ActiveRecord.respond_to?(:gem_version) &&
      ::ActiveRecord.gem_version >= ::Gem::Version.new("5.1.0.beta1")

    def initialize(record)
      @record = record
      @in_after_callback = false
    end

    # Utility method for reifying. Anything executed inside the block will
    # appear like a new record.
    #
    # > .. as best as I can tell, the purpose of
    # > appear_as_new_record was to attempt to prevent the callbacks in
    # > AutosaveAssociation (which is the module responsible for persisting
    # > foreign key changes earlier than most people want most of the time
    # > because backwards compatibility or the maintainer hates himself or
    # > something) from running. By also stubbing out persisted? we can
    # > actually prevent those. A more stable option might be to use suppress
    # > instead, similar to the other branch in reify_has_one.
    # > -Sean Griffin (https://github.com/airblade/paper_trail/pull/899)
    #
    def appear_as_new_record
      @record.instance_eval {
        alias :old_new_record? :new_record?
        alias :new_record? :present?
        alias :old_persisted? :persisted?
        alias :persisted? :nil?
      }
      yield
      @record.instance_eval {
        alias :new_record? :old_new_record?
        alias :persisted? :old_persisted?
      }
    end

    def attributes_before_change
      Hash[@record.attributes.map do |k, v|
        if @record.class.column_names.include?(k)
          [k, attribute_in_previous_version(k)]
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

    def enabled?
      PaperTrail.enabled? && PaperTrail.enabled_for_controller? && enabled_for_model?
    end

    def enabled_for_model?
      @record.class.paper_trail.enabled?
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
    # @api private
    def merge_metadata_into(data)
      merge_metadata_from_model_into(data)
      merge_metadata_from_controller_into(data)
    end

    # Updates `data` from `controller_info`.
    # @api private
    def merge_metadata_from_controller_into(data)
      data.merge(PaperTrail.controller_info || {})
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
          attribute_in_previous_version(value)
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
    def object_attrs_for_paper_trail
      attrs = attributes_before_change.except(*@record.paper_trail_options[:skip])
      AttributeSerializers::ObjectAttribute.new(@record.class).serialize(attrs)
      attrs
    end

    # Returns who put `@record` into its current state.
    def originator
      (source_version || versions.last).try(:whodunnit)
    end

    # Returns the object (not a Version) as it was most recently.
    def previous_version
      (source_version ? source_version.previous : versions.last).try(:reify)
    end

    def record_create
      @in_after_callback = true
      return unless enabled?
      versions_assoc = @record.send(@record.class.versions_association_name)
      version = versions_assoc.create! data_for_create
      update_transaction_id(version)
      save_associations(version)
    ensure
      @in_after_callback = false
    end

    # Returns data for record create
    # @api private
    def data_for_create
      data = {
        event: @record.paper_trail_event || "create",
        whodunnit: PaperTrail.whodunnit
      }
      if @record.respond_to?(:updated_at)
        data[:created_at] = @record.updated_at
      end
      if record_object_changes? && changed_notably?
        data[:object_changes] = recordable_object_changes
      end
      add_transaction_id_to(data)
      merge_metadata_into(data)
    end

    def record_destroy
      if enabled? && !@record.new_record?
        version = @record.class.paper_trail.version_class.create(data_for_destroy)
        if version.errors.any?
          log_version_errors(version, :destroy)
        else
          @record.send("#{@record.class.version_association_name}=", version)
          @record.send(@record.class.versions_association_name).reset
          update_transaction_id(version)
          save_associations(version)
        end
      end
    end

    # Returns data for record destroy
    # @api private
    def data_for_destroy
      data = {
        item_id: @record.id,
        item_type: @record.class.base_class.name,
        event: @record.paper_trail_event || "destroy",
        object: recordable_object,
        whodunnit: PaperTrail.whodunnit
      }
      add_transaction_id_to(data)
      merge_metadata_into(data)
    end

    # Returns a boolean indicating whether to store serialized version diffs
    # in the `object_changes` column of the version record.
    # @api private
    def record_object_changes?
      @record.paper_trail_options[:save_changes] &&
        @record.class.paper_trail.version_class.column_names.include?("object_changes")
    end

    def record_update(force)
      @in_after_callback = true
      if enabled? && (force || changed_notably?)
        versions_assoc = @record.send(@record.class.versions_association_name)
        version = versions_assoc.create(data_for_update)
        if version.errors.any?
          log_version_errors(version, :update)
        else
          update_transaction_id(version)
          save_associations(version)
        end
      end
    ensure
      @in_after_callback = false
    end

    # Returns data for record update
    # @api private
    def data_for_update
      data = {
        event: @record.paper_trail_event || "update",
        object: recordable_object,
        whodunnit: PaperTrail.whodunnit
      }
      if @record.respond_to?(:updated_at)
        data[:created_at] = @record.updated_at
      end
      if record_object_changes?
        data[:object_changes] = recordable_object_changes
      end
      add_transaction_id_to(data)
      merge_metadata_into(data)
    end

    # Returns an object which can be assigned to the `object` attribute of a
    # nascent version record. If the `object` column is a postgres `json`
    # column, then a hash can be used in the assignment, otherwise the column
    # is a `text` column, and we must perform the serialization here, using
    # `PaperTrail.serializer`.
    # @api private
    def recordable_object
      if @record.class.paper_trail.version_class.object_col_is_json?
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
    def recordable_object_changes
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
        # ActiveRecord 4.2 deprecated `reset_column!` in favor of
        # `restore_column!`.
        if @record.respond_to?("restore_#{column}!")
          @record.send("restore_#{column}!")
        else
          @record.send("reset_#{column}!")
        end
      end
    end

    # Saves associations if the join table for `VersionAssociation` exists.
    def save_associations(version)
      return unless PaperTrail.config.track_associations?
      save_bt_associations(version)
      save_habtm_associations(version)
    end

    # Save all `belongs_to` associations.
    # @api private
    def save_bt_associations(version)
      @record.class.reflect_on_all_associations(:belongs_to).each do |assoc|
        save_bt_association(assoc, version)
      end
    end

    # When a record is created, updated, or destroyed, we determine what the
    # HABTM associations looked like before any changes were made, by using
    # the `paper_trail_habtm` data structure. Then, we create
    # `VersionAssociation` records for each of the associated records.
    # @api private
    def save_habtm_associations(version)
      @record.class.reflect_on_all_associations(:has_and_belongs_to_many).each do |a|
        next unless save_habtm_association?(a)
        habtm_assoc_ids(a).each do |id|
          PaperTrail::VersionAssociation.create(
            version_id: version.transaction_id,
            foreign_key_name: a.name,
            foreign_key_id: id
          )
        end
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

    # Mimics the `touch` method from `ActiveRecord::Persistence`, but also
    # creates a version. A version is created regardless of options such as
    # `:on`, `:if`, or `:unless`.
    #
    # TODO: look into leveraging the `after_touch` callback from
    # `ActiveRecord` to allow the regular `touch` method to generate a version
    # as normal. May make sense to switch the `record_update` method to
    # leverage an `after_update` callback anyways (likely for v4.0.0)
    def touch_with_version(name = nil)
      unless @record.persisted?
        raise ::ActiveRecord::ActiveRecordError, "can not touch on a new record object"
      end
      attributes = @record.send :timestamp_attributes_for_update_in_model
      attributes << name if name
      current_time = @record.send :current_time_from_proper_timezone
      attributes.each { |column|
        @record.send(:write_attribute, column, current_time)
      }
      record_update(true) unless will_record_after_update?
      @record.save!(validate: false)
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
    def without_versioning(method = nil)
      paper_trail_was_enabled = enabled_for_model?
      @record.class.paper_trail.disable
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
      @record.class.paper_trail.enable if paper_trail_was_enabled
    end

    # Temporarily overwrites the value of whodunnit and then executes the
    # provided block.
    def whodunnit(value)
      raise ArgumentError, "expected to receive a block" unless block_given?
      current_whodunnit = PaperTrail.whodunnit
      PaperTrail.whodunnit = value
      yield @record
    ensure
      PaperTrail.whodunnit = current_whodunnit
    end

    private

    def add_transaction_id_to(data)
      return unless @record.class.paper_trail.version_class.column_names.include?("transaction_id")
      data[:transaction_id] = PaperTrail.transaction_id
    end

    # @api private
    def attribute_changed_in_latest_version?(attr_name)
      if @in_after_callback && RAILS_GTE_5_1
        @record.saved_change_to_attribute?(attr_name.to_s)
      else
        @record.attribute_changed?(attr_name.to_s)
      end
    end

    # @api private
    def attribute_in_previous_version(attr_name)
      if @in_after_callback && RAILS_GTE_5_1
        @record.attribute_before_last_save(attr_name.to_s)
      else
        # TODO: after dropping support for rails 4.0, remove send, because
        # attribute_was is no longer private.
        @record.send(:attribute_was, attr_name.to_s)
      end
    end

    # @api private
    def changed_in_latest_version
      if @in_after_callback && RAILS_GTE_5_1
        @record.saved_changes.keys
      else
        @record.changed
      end
    end

    # @api private
    def changes_in_latest_version
      if @in_after_callback && RAILS_GTE_5_1
        @record.saved_changes
      else
        @record.changes
      end
    end

    # Given a HABTM association, returns an array of ids.
    # @api private
    def habtm_assoc_ids(habtm_assoc)
      current = @record.send(habtm_assoc.name).to_a.map(&:id) # TODO: `pluck` would use less memory
      removed = @record.paper_trail_habtm.try(:[], habtm_assoc.name).try(:[], :removed) || []
      added = @record.paper_trail_habtm.try(:[], habtm_assoc.name).try(:[], :added) || []
      current + removed - added
    end

    def log_version_errors(version, action)
      version.logger && version.logger.warn(
        "Unable to create version for #{action} of #{@record.class.name}" +
          "##{@record.id}: " + version.errors.full_messages.join(", ")
      )
    end

    # Save a single `belongs_to` association.
    # @api private
    def save_bt_association(assoc, version)
      assoc_version_args = {
        version_id: version.id,
        foreign_key_name: assoc.foreign_key
      }

      if assoc.options[:polymorphic]
        associated_record = @record.send(assoc.name) if @record.send(assoc.foreign_type)
        if associated_record && associated_record.class.paper_trail.enabled?
          assoc_version_args[:foreign_key_id] = associated_record.id
        end
      elsif assoc.klass.paper_trail.enabled?
        assoc_version_args[:foreign_key_id] = @record.send(assoc.foreign_key)
      end

      if assoc_version_args.key?(:foreign_key_id)
        PaperTrail::VersionAssociation.create(assoc_version_args)
      end
    end

    # Returns true if the given HABTM association should be saved.
    # @api private
    def save_habtm_association?(assoc)
      @record.class.paper_trail_save_join_tables.include?(assoc.name) ||
        assoc.klass.paper_trail.enabled?
    end

    # Returns true if `save` will cause `record_update`
    # to be called via the `after_update` callback.
    def will_record_after_update?
      on = @record.paper_trail_options[:on]
      on.nil? || on.include?(:update)
    end

    def update_transaction_id(version)
      return unless @record.class.paper_trail.version_class.column_names.include?("transaction_id")
      if PaperTrail.transaction? && PaperTrail.transaction_id.nil?
        PaperTrail.transaction_id = version.id
        version.transaction_id = version.id
        version.save
      end
    end

    def version
      @record.public_send(@record.class.version_association_name)
    end

    def versions
      @record.public_send(@record.class.versions_association_name)
    end
  end
end
