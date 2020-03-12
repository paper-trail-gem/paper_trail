# frozen_string_literal: true

require "paper_trail/frameworks/rails/engine"

module PaperTrail
  # Represents code to load within Rails framework
  # @api private
  class Railtie < ::Rails::Railtie
    initializer "paper_trail" do
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
