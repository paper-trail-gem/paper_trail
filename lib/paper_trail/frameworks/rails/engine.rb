module PaperTrail
  module Rails
    class Engine < ::Rails::Engine
      paths['app/models'] << 'lib/paper_trail/frameworks/active_record/models'
    end
  end
end
