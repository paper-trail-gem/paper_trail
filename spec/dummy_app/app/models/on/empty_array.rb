# frozen_string_literal: true

module On
  class EmptyArray < ApplicationRecord
    self.table_name = :on_empty_array
    has_paper_trail on: []
  end
end
