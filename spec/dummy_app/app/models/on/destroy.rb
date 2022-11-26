# frozen_string_literal: true

module On
  class Destroy < ApplicationRecord
    self.table_name = :on_destroy
    has_paper_trail on: [:destroy]
  end
end
