# frozen_string_literal: true

module On
  class Touch < ApplicationRecord
    self.table_name = :on_touch
    has_paper_trail on: [:touch]
  end
end
