module PaperTrail
  module Callbacks
    def setup_callbacks_from_options(options_on, options = {})
      options_on.each do |option|
        send "paper_trail_#{option}", options
      end
    end

    # Record version before or after "destroy" event
    def paper_trail_destroy(options = {})
      setup_model_if_necessary options
      recording_order = options[:recording_order] || 'after'

      unless %(after before).include?(recording_order.to_s)
        fail ArgumentError, 'recording order can only be "after" or "before"'
      end

      send "#{recording_order}_destroy",
           :record_destroy,
           :if => :save_version?
    end

    # Record version after "destroy" event
    def paper_trail_after_destroy(options = {})
      options[:recording_order] = :after
      paper_trail_destroy options
    end

    # Record version before "destroy" event
    def paper_trail_before_destroy(options = {})
      options[:recording_order] = :before
      paper_trail_destroy options
    end

    # Record version after "update" event
    def paper_trail_update(options = {})
      setup_model_if_necessary options
      before_save  :reset_timestamp_attrs_for_update_if_needed!,
                   :on => :update
      after_update :record_update,
                   :if => :save_version?
      after_update :clear_version_instance!
    end

    # Record version after "create" event
    def paper_trail_create(options = {})
      setup_model_if_necessary options
      after_create :record_create,
                   :if => :save_version?
    end

    private

      def setup_model_if_necessary(options)
        return true if model_set_up?

        setup_model_for_paper_trail options
        @_set_up = true
      end

      def model_set_up?
        @_set_up
      end
  end
end
