# frozen_string_literal: true

module PaperTrail
  module Rails
    # See http://guides.rubyonrails.org/engines.html
    class Engine < ::Rails::Engine
      DPR_CONFIG_ENABLED = <<~EOS.squish.freeze
        The rails configuration option config.paper_trail.enabled is deprecated.
        Please use PaperTrail.enabled= instead. People were getting confused
        that PT has both, specifically regarding *when* each was happening. If
        you'd like to keep config.paper_trail, join the discussion at
        https://github.com/paper-trail-gem/paper_trail/pull/1176
      EOS
      private_constant :DPR_CONFIG_ENABLED
      DPR_RUDELY_ENABLING = <<~EOS.squish.freeze
        At some point early in the rails boot process, you have set
        PaperTrail.enabled = false. PT's rails engine is now overriding your
        setting, and setting it to true. We're not sure why, but this is how PT
        has worked since 5.0, when the config.paper_trail.enabled option was
        introduced. This is now deprecated. In the future, PT will not override
        your setting. See
        https://github.com/paper-trail-gem/paper_trail/pull/1176 for discussion.
      EOS
      private_constant :DPR_RUDELY_ENABLING

      paths["app/models"] << "lib/paper_trail/frameworks/active_record/models"

      # --- Begin deprecated section ---
      config.paper_trail = ActiveSupport::OrderedOptions.new
      initializer "paper_trail.initialisation" do |app|
        enable = app.config.paper_trail[:enabled]
        if enable.nil?
          unless PaperTrail.enabled?
            ::ActiveSupport::Deprecation.warn(DPR_RUDELY_ENABLING)
            PaperTrail.enabled = true
          end
        else
          ::ActiveSupport::Deprecation.warn(DPR_CONFIG_ENABLED)
          PaperTrail.enabled = enable
        end
      end
      # --- End deprecated section ---
    end
  end
end
