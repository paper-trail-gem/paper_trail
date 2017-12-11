# frozen_string_literal: true

module On
  class Create < ActiveRecord::Base
    self.table_name = :on_create
    has_paper_trail on: [:create]
  end
end
