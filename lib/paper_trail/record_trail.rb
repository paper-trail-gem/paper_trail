# frozen_string_literal: true

require "paper_trail/events/create"
require "paper_trail/events/destroy"
require "paper_trail/events/update"

module PaperTrail
  # Represents the "paper trail" for a single record.
  class RecordTrail
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
    E_STI_ITEM_TYPES_NOT_UPDATED = <<~STR.squish.freeze
      It looks like %s is an STI subclass, and you have not yet updated your
      `item_type`s. Starting with
      [#1108](https://github.com/paper-trail-gem/paper_trail/pull/1108), we now
      store the subclass name instead of the base_class. You must migrate
      existing `versions` records if you use STI. A migration generator has been
      provided. See section 5.c. Generators in the README for instructions. This
      warning will continue until you have thoroughly read the instructions.
    STR

    RAILS_GTE_5_1 = ::ActiveRecord.gem_version >= ::Gem::Version.new("5.1.0.beta1")

    def initialize(record)
      @record = record
      assert_sti_item_type_updated
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

    # Returns true if this instance is the current, live one;
    # returns false if this instance came from a previous version.
    def live?
      source_version.nil?
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
      return unless enabled?
      event = Events::Create.new(@record, true)

      # Merge data from `Event` with data from PT-AT. We no longer use
      # `data_for_create` but PT-AT still does.
      data = event.data.merge(data_for_create)

      versions_assoc = @record.send(@record.class.versions_association_name)
      version = versions_assoc.new(data)
      version.save!
      version
    end

    # PT-AT extends this method to add its transaction id.
    #
    # @api private
    def data_for_create
      {}
    end

    # `recording_order` is "after" or "before". See ModelConfig#on_destroy.
    #
    # @api private
    # @return - The created version object, so that plugins can use it, e.g.
    # paper_trail-association_tracking
    def record_destroy(recording_order)
      return unless enabled? && !@record.new_record?
      in_after_callback = recording_order == "after"
      event = Events::Destroy.new(@record, in_after_callback)

      # Merge data from `Event` with data from PT-AT. We no longer use
      # `data_for_destroy` but PT-AT still does.
      data = event.data.merge(data_for_destroy)

      version = @record.class.paper_trail.version_class.new(data)
      if version.save
        assign_and_reset_version_association(version)
        version
      else
        log_version_errors(version, :destroy)
      end
    end

    # PT-AT extends this method to add its transaction id.
    #
    # @api private
    def data_for_destroy
      {}
    end

    # @api private
    # @return - The created version object, so that plugins can use it, e.g.
    # paper_trail-association_tracking
    def record_update(force:, in_after_callback:, is_touch:)
      return unless enabled?
      event = Events::Update.new(@record, in_after_callback, is_touch, nil)
      return unless force || event.changed_notably?

      # Merge data from `Event` with data from PT-AT. We no longer use
      # `data_for_update` but PT-AT still does.
      data = event.data.merge(data_for_update)

      versions_assoc = @record.send(@record.class.versions_association_name)
      version = versions_assoc.new(data)
      if version.save
        version
      else
        log_version_errors(version, :update)
      end
    end

    # PT-AT extends this method to add its transaction id.
    #
    # @api private
    def data_for_update
      {}
    end

    # @api private
    # @return - The created version object, so that plugins can use it, e.g.
    # paper_trail-association_tracking
    def record_update_columns(changes)
      return unless enabled?
      event = Events::Update.new(@record, false, false, changes)

      # Merge data from `Event` with data from PT-AT. We no longer use
      # `data_for_update_columns` but PT-AT still does.
      data = event.data.merge(data_for_update_columns)

      versions_assoc = @record.send(@record.class.versions_association_name)
      version = versions_assoc.new(data)
      if version.save
        version
      else
        log_version_errors(version, :update)
      end
    end

    # PT-AT extends this method to add its transaction id.
    #
    # @api private
    def data_for_update_columns
      {}
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

    # Save, and create a version record regardless of options such as `:on`,
    # `:if`, or `:unless`.
    #
    # Arguments are passed to `save`.
    #
    # This is an "update" event. That is, we record the same data we would in
    # the case of a normal AR `update`.
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
      # `@record.update_columns` skips dirty-tracking, so we can't just use
      # `@record.changes` or @record.saved_changes` from `ActiveModel::Dirty`.
      # We need to build our own hash with the changes that will be made
      # directly to the database.
      changes = {}
      attributes.each do |k, v|
        changes[k] = [@record[k], v]
      end
      @record.update_columns(attributes)
      record_update_columns(changes)
    end

    # Given `@record`, when building the query for the `versions` association,
    # what `item_type` (if any) should we use in our query. Returning nil
    # indicates that rails should do whatever it normally does.
    def versions_association_item_type
      type_column = @record.class.inheritance_column
      item_type = (respond_to?(type_column) ? send(type_column) : nil) ||
        @record.class.name
      if item_type == @record.class.base_class.name
        nil
      else
        item_type
      end
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

    # @api private
    def assert_sti_item_type_updated
      # Does the user promise they have updated their `item_type`s?
      return if ::PaperTrail.config.i_have_updated_my_existing_item_types

      # Is this class an STI subclass?
      record_class = @record.class
      return if record_class.descends_from_active_record?

      # Have we already issued this warning?
      ::PaperTrail.config.classes_warned_about_sti_item_types ||= []
      return if ::PaperTrail.config.classes_warned_about_sti_item_types.include?(record_class)

      ::Kernel.warn(format(E_STI_ITEM_TYPES_NOT_UPDATED, record_class.name))
      ::PaperTrail.config.classes_warned_about_sti_item_types << record_class
    end

    # @api private
    def assign_and_reset_version_association(version)
      @record.send("#{@record.class.version_association_name}=", version)
      @record.send(@record.class.versions_association_name).reset
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
