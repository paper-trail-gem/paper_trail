# frozen_string_literal: true

module On
  class AfterCreate < ActiveRecord::Base
    self.table_name = :on_create
    has_paper_trail on: [:create], model_after: true
  end
end
