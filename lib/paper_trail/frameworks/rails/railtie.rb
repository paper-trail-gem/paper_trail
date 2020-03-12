# frozen_string_literal: true

module PaperTrail
  # Represents code to load within Rails framework. See documentation in
  # `rails/railtie.rb`.
  # @api private
  class Railtie < ::Rails::Railtie
    # PaperTrail only has one initializer. The `initializer` method can take a
    # `before:` or `after:` argument, but that's only relevant for railties with
    # more than one initializer.
    initializer "paper_trail" do
      # `on_load` is a "lazy load hook". It "declares a block that will be
      # executed when a Rails component is fully loaded". (See
      # `active_support/lazy_load_hooks.rb`)
      ActiveSupport.on_load(:action_controller) do
        require "paper_trail/frameworks/rails/controller"

        # Mix our extensions into `ActionController::Base`, which is `self`
        # because of the `class_eval` in `lazy_load_hooks.rb`.
        include PaperTrail::Rails::Controller
      end

      ActiveSupport.on_load(:active_record) do
        require "paper_trail/frameworks/active_record"
      end
    end
  end
end
