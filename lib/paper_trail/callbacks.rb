module PaperTrail
  module Callbacks
    # The cleanup_* methods are only used to provide backward-compatibility
    # They should be removed as soon as the "traditional" way of using
    # PaperTrail `has_papertrail :on => [...]` with or without the :on option
    # and not setting the paper_trail_* methods is no longer supported.
    def setup_callbacks_from_options(options_on = [])
      options_on.each do |option|
        send "paper_trail_on_#{option}"
      end

      paper_trail_options[:on] = options_on
    end

    # Record version before or after "destroy" event
    def paper_trail_on_destroy(recording_order = 'after')
      unless %(after before).include?(recording_order.to_s)
        fail ArgumentError, 'recording order can only be "after" or "before"'
      end

      cleanup_callback_chain

      send "#{recording_order}_destroy",
           :record_destroy,
           :if => :save_version?
    end

    # Record version after "update" event
    def paper_trail_on_update
      cleanup_callback_chain

      before_save  :reset_timestamp_attrs_for_update_if_needed!,
                   :on => :update
      after_update :record_update,
                   :if => :save_version?
      after_update :clear_version_instance!
    end

    # Record version after "create" event
    def paper_trail_on_create
      cleanup_callback_chain

      after_create :record_create,
                   :if => :save_version?
    end

    private

      # The cleanup_* methods are only used to provide backward-compatibility
      # They should be removed as soon as the "traditional" way of using
      # PaperTrail `has_papertrail :on => [...]` with or without the :on option
      # and not setting the paper_trail_* methods is no longer supported.
      def cleanup_callback_chain
        on_options = paper_trail_options.try(:delete, :on) || []
        on_options.each do |on_option|
          send "cleanup_#{on_option}_callbacks"
        end
      end

      def cleanup_create_callbacks
        callback =
          _create_callbacks.find do |cb|
            cb.filter.eql?(:record_create) && cb.kind.eql?(:after)
          end

        _create_callbacks.delete(callback)
      end

      def cleanup_update_callbacks
        callback =
          _save_callbacks.find do |cb|
            cb.filter.eql?(:reset_timestamp_attrs_for_update_if_needed!) && cb.kind.eql?(:before)
          end

        _save_callbacks.delete(callback)

        callback =
          _update_callbacks.find do |cb|
            cb.filter.eql?(:record_update) && cb.kind.eql?(:after)
          end

        _update_callbacks.delete(callback)
        callback =
          _update_callbacks.find do |cb|
            cb.filter.eql?(:clear_version_instance!) && cb.kind.eql?(:after)
          end

        _update_callbacks.delete(callback)
      end

      def cleanup_destroy_callbacks
        callback =
          _destroy_callbacks.find do |cb|
            cb.filter.eql?(:record_destroy)
          end

        _destroy_callbacks.delete(callback)
      end
  end
end
