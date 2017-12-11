# frozen_string_literal: true

module On
  class EmptyArray < ActiveRecord::Base
    self.table_name = :on_empty_array
    has_paper_trail on: []
  end
end
