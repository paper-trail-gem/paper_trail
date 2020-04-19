# frozen_string_literal: true

require "paper_trail/frameworks/rails/engine"

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
        include PaperTrail::Rails::Controller
      end

      ActiveSupport.on_load(:active_record) do
        ::PaperTrail::Compatibility.check_activerecord(::ActiveRecord.gem_version)
        require "paper_trail/has_paper_trail"
        require "paper_trail/reifier"
        require "paper_trail/frameworks/active_record/models/paper_trail/version"
        include PaperTrail::Model
      end
    end
  end
end
