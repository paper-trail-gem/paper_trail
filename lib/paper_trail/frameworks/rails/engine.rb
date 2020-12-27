# frozen_string_literal: true

module PaperTrail
  module Rails
    # See http://guides.rubyonrails.org/engines.html
    class Engine < ::Rails::Engine
      paths["app/models"] << "lib/paper_trail/frameworks/active_record/models"
    end
  end
end
