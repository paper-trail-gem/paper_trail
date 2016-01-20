module PaperTrail
  module Rails
    class Railtie < ::Rails::Railtie
      config.paper_trail = ActiveSupport::OrderedOptions.new
      initializer 'paper_trail.initialisation' do |app|
        ActiveRecord::Base.send :include, PaperTrail::Model

        unless app.config.paper_trail.fetch(:enabled, true)
          PaperTrail.config.disable!
        end
      end
    end
  end
end
