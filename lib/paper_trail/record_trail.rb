# frozen_string_literal: true

require "paper_trail/events/create"
require "paper_trail/events/destroy"
require "paper_trail/events/update"

module PaperTrail
  # Represents the "paper trail" for a single record.
  class RecordTrail
    RAILS_GTE_5_1 = ::ActiveRecord.gem_version >= ::Gem::Version.new("5.1.0.beta1")

    def initialize(record)
      @record = record
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
      subsequent_version ? subsequent_version.reify : @record.class.find(record_id)
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

      build_version_on_create(in_after_callback: true).tap do |version|
        version.save!
        # Because the version object was created using version_class.new instead
        # of versions_assoc.build?, the association cache is unaware. So, we
        # invalidate the `versions` association cache with `reset`.
        versions.reset
      end
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

      version = @record.class.paper_trail.version_class.create(data)
      if version.errors.any?
        log_version_errors(version, :destroy)
      else
        assign_and_reset_version_association(version)
        version
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

      version = build_version_on_update(
        force: force,
        in_after_callback: in_after_callback,
        is_touch: is_touch
      )
      return unless version

      if version.save
        # Because the version object was created using version_class.new instead
        # of versions_assoc.build?, the association cache is unaware. So, we
        # invalidate the `versions` association cache with `reset`.
        versions.reset
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
      version = versions_assoc.create(data)
      if version.errors.any?
        log_version_errors(version, :update)
      else
        version
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

    private

    def record_id
      id_key = @record.paper_trail_options[:id_key]
      id_key.present? ? @record[id_key] : @record.id
    end

    # @api private
    def assign_and_reset_version_association(version)
      @record.send("#{@record.class.version_association_name}=", version)
      @record.send(@record.class.versions_association_name).reset
    end

    # @api private
    def build_version_on_create(in_after_callback:)
      event = Events::Create.new(@record, in_after_callback)

      # Merge data from `Event` with data from PT-AT. We no longer use
      # `data_for_create` but PT-AT still does.
      data = event.data.merge!(data_for_create)

      # Pure `version_class.new` reduces memory usage compared to `versions_assoc.build`
      @record.class.paper_trail.version_class.new(data)
    end

    # @api private
    def build_version_on_update(force:, in_after_callback:, is_touch:)
      event = Events::Update.new(@record, in_after_callback, is_touch, nil)
      return unless force || event.changed_notably?

      # Merge data from `Event` with data from PT-AT. We no longer use
      # `data_for_update` but PT-AT still does. To save memory, we use `merge!`
      # instead of `merge`.
      data = event.data.merge!(data_for_update)

      # Using `version_class.new` reduces memory usage compared to
      # `versions_assoc.build`. It's a trade-off though. We have to clear
      # the association cache (see `versions.reset`) and that could cause an
      # additional query in certain applications.
      @record.class.paper_trail.version_class.new(data)
    end

    def log_version_errors(version, action)
      version.logger&.warn(
        "Unable to create version for #{action} of #{@record.class.name}" \
          "##{record_id}: " + version.errors.full_messages.join(", ")
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
