module PaperTrail
  module Rails
    class Engine < ::Rails::Engine
      paths['app/models'] << 'lib/paper_trail/frameworks/active_record/models'
      config.paper_trail = ActiveSupport::OrderedOptions.new
      initializer 'paper_trail.initialisation' do |app|
        ActiveRecord::Base.send :include, PaperTrail::Model
        PaperTrail.enabled_in_all_threads = app.config.paper_trail.fetch(:enabled, true)
      end
    end
  end
end
