# frozen_string_literal: true

module PaperTrail
  module Rails
    # See http://guides.rubyonrails.org/engines.html
    class Engine < ::Rails::Engine
      paths["app/models"] << "lib/paper_trail/frameworks/active_record/models"
      config.paper_trail = ActiveSupport::OrderedOptions.new
      initializer "paper_trail.initialisation" do |app|
        PaperTrail.enabled = app.config.paper_trail.fetch(:enabled, true)
      end
    end
  end
end
