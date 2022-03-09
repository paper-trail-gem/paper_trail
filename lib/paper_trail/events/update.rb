# frozen_string_literal: true

require "paper_trail/events/base"

module PaperTrail
  module Events
    # See docs in `Base`.
    #
    # @api private
    class Update < Base
      # - is_touch - [boolean] - Used in the two situations that are touch-like:
      #   - `after_touch` we call `RecordTrail#record_update`
      # - force_changes - [Hash] - Only used by `RecordTrail#update_columns`,
      #   because there dirty-tracking is off, so it has to track its own changes.
      #
      # @api private
      def initialize(record, in_after_callback, is_touch, force_changes)
        super(record, in_after_callback)
        @is_touch = is_touch
        @force_changes = force_changes
      end

      # Return attributes of nascent `Version` record.
      #
      # @api private
      def data
        data = {
          item: @record,
          event: @record.paper_trail_event || "update",
          whodunnit: PaperTrail.request.whodunnit
        }
        if @record.respond_to?(:updated_at)
          data[:created_at] = @record.updated_at
        end
        if record_object?
          data[:object] = recordable_object(@is_touch)
        end
        merge_object_changes_into(data)
        merge_item_subtype_into(data)
        merge_metadata_into(data)
      end

      # If it is a touch event, and changed are empty, it is assumed to be
      # implicit `touch` mutation, and will a version is created.
      #
      # See https://github.com/rails/rails/commit/dcb825902d79d0f6baba956f7c6ec5767611353e
      #
      # @api private
      def changed_notably?
        if @is_touch && changes_in_latest_version.empty?
          true
        else
          super
        end
      end

      private

      # @api private
      def merge_object_changes_into(data)
        if record_object_changes?
          changes = @force_changes.nil? ? notable_changes : @force_changes
          data[:object_changes] = prepare_object_changes(changes)
        end
      end

      # `touch` cannot record `object_changes` because rails' `touch` does not
      # perform dirty-tracking. Specifically, methods from `Dirty`, like
      # `saved_changes`, return the same values before and after `touch`.
      #
      # See https://github.com/rails/rails/issues/33429
      #
      # @api private
      def record_object_changes?
        !@is_touch && super
      end
    end
  end
end
