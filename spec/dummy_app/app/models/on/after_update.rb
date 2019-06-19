# frozen_string_literal: true

module On
  class AfterUpdate < ActiveRecord::Base
    self.table_name = :on_update
    has_paper_trail on: [:update], model_after: true
  end
end
