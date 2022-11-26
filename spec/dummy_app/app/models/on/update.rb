# frozen_string_literal: true

module On
  class Update < ApplicationRecord
    self.table_name = :on_update
    has_paper_trail on: [:update]
  end
end
