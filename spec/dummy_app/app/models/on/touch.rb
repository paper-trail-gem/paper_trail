# frozen_string_literal: true

module On
  class Touch < ActiveRecord::Base
    self.table_name = :on_touch
    has_paper_trail on: [:touch]
  end
end
