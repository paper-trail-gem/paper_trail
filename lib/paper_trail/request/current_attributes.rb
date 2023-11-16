# frozen_string_literal: true

module PaperTrail
  module Request
    # Thread-isolated attributes for managing the current request.
    class CurrentAttributes < ActiveSupport::CurrentAttributes
      attribute :enabled
      attribute :enabled_for
      attribute :controller_info
      attribute :whodunnit
      attribute :skip_reset

      def enabled_for
        super || self.enabled_for = {}
      end

      def controller_info
        super || self.controller_info = {}
      end

      # Overrides ActiveSupport::CurrentAttributes#reset to support skipping.
      def reset
        return if skip_reset
        super
      end
    end
  end
end
