# frozen_string_literal: true

require "paper_trail/events/create"
require "paper_trail/events/destroy"
require "paper_trail/events/update"

module PaperTrail
  # Represents the "paper trail" for a single record.
  class RecordTrail
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
      @record.send(:"#{@record.class.version_association_name}=", nil)
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

      build_version_on_create(in_after_callback: true).tap do |version|
        version.save!
        # Because the version object was created using version_class.new instead
        # of versions_assoc.build?, the association cache is unaware. So, we
        # invalidate the `versions` association cache with `reset`.
        versions.reset
      rescue StandardError => e
        handle_version_errors e, version, :create
      end
    end

    # Returns the original version of this object or just this object if there has been no changes.
    #
    # @api public
    def reify_original
      versions.second&.reify || @record
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
      begin
        version.save!
        assign_and_reset_version_association(version)
        version
      rescue StandardError => e
        handle_version_errors e, version, :destroy
      end
    end

    # @api private
    # @param force [boolean] Insert a `Version` even if `@record` has not
    #   `changed_notably?`.
    # @param in_after_callback [boolean] True when called from an `after_update`
    #   or `after_touch` callback.
    # @param is_touch [boolean] True when called from an `after_touch` callback.
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

      begin
        version.save!
        # Because the version object was created using version_class.new instead
        # of versions_assoc.build?, the association cache is unaware. So, we
        # invalidate the `versions` association cache with `reset`.
        versions.reset
        version
      rescue StandardError => e
        handle_version_errors e, version, :update
      end
    end

    # Invoked via callback when a user attempts to persist a reified
    # `Version`.
    def reset_timestamp_attrs_for_update_if_needed
      return if live?
      @record.send(:timestamp_attributes_for_update_in_model).each do |column|
        @record.send(:"restore_#{column}!")
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
    # `in_after_callback`: Indicates if this method is being called within an
    #                      `after` callback. Defaults to `false`.
    # `options`: Optional arguments passed to `save`.
    #
    # This is an "update" event. That is, we record the same data we would in
    # the case of a normal AR `update`.
    def save_with_version(in_after_callback: false, **options)
      ::PaperTrail.request(enabled: false) do
        @record.save(**options)
      end
      record_update(force: true, in_after_callback: in_after_callback, is_touch: false)
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

    # @api private
    def assign_and_reset_version_association(version)
      @record.send(:"#{@record.class.version_association_name}=", version)
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
      data = event.data

      # Copy the (recently set) `updated_at` from the record to the `created_at`
      # of the `Version`. Without this feature, these two timestamps would
      # differ by a few milliseconds. To some people, it seems a little
      # unnatural to tamper with creation timestamps in this way. But, this
      # feature has existed for a long time, almost a decade now, and some users
      # may rely on it now.
      if @record.respond_to?(:updated_at) &&
          @record.paper_trail_options[:synchronize_version_creation_timestamp] != false
        data[:created_at] = @record.updated_at
      end

      # Merge data from `Event` with data from PT-AT. We no longer use
      # `data_for_update` but PT-AT still does. To save memory, we use `merge!`
      # instead of `merge`.
      data.merge!(data_for_update)

      # Using `version_class.new` reduces memory usage compared to
      # `versions_assoc.build`. It's a trade-off though. We have to clear
      # the association cache (see `versions.reset`) and that could cause an
      # additional query in certain applications.
      @record.class.paper_trail.version_class.new(data)
    end

    # PT-AT extends this method to add its transaction id.
    #
    # @api public
    def data_for_create
      {}
    end

    # PT-AT extends this method to add its transaction id.
    #
    # @api public
    def data_for_destroy
      {}
    end

    # PT-AT extends this method to add its transaction id.
    #
    # @api public
    def data_for_update
      {}
    end

    # PT-AT extends this method to add its transaction id.
    #
    # @api public
    def data_for_update_columns
      {}
    end

    # Is PT enabled for this particular record?
    # @api private
    def enabled?
      PaperTrail.enabled? &&
        PaperTrail.request.enabled? &&
        PaperTrail.request.enabled_for_model?(@record.class)
    end

    def log_version_errors(version, action)
      version.logger&.warn(
        "Unable to create version for #{action} of #{@record.class.name}" \
        "##{@record.id}: " + version.errors.full_messages.join(", ")
      )
    end

    # Centralized handler for version errors
    # @api private
    def handle_version_errors(e, version, action)
      case PaperTrail.config.version_error_behavior
      when :legacy
        # legacy behavior was to raise on create and log on update/delete
        if action == :create
          raise e
        else
          log_version_errors(version, action)
        end
      when :log
        log_version_errors(version, action)
      when :exception
        raise e
      when :silent
        # noop
      end
    end

    # @api private
    # @return - The created version object, so that plugins can use it, e.g.
    # paper_trail-association_tracking
    def record_update_columns(changes)
      return unless enabled?
      data = Events::Update.new(@record, false, false, changes).data

      # Merge data from `Event` with data from PT-AT. We no longer use
      # `data_for_update_columns` but PT-AT still does.
      data.merge!(data_for_update_columns)

      versions_assoc = @record.send(@record.class.versions_association_name)
      version = versions_assoc.new(data)
      begin
        version.save!
        version
      rescue StandardError => e
        handle_version_errors e, version, :update
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
