# frozen_string_literal: true

module PaperTrail
  # Represents code to load within Rails framework. See documentation in
  # `railties/lib/rails/railtie.rb`.
  # @api private
  class Railtie < ::Rails::Railtie
    # PaperTrail only has one initializer.
    #
    # We specify `before: "load_config_initializers"` to ensure that the PT
    # initializer happens before "app initializers" (those defined in
    # the app's `config/initalizers`).
    initializer "paper_trail", before: "load_config_initializers" do |app|
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

      if ::Rails::VERSION::STRING >= "7.1"
        app.deprecators[:paper_trail] = PaperTrail.deprecator
      end
    end
  end
end
