# frozen_string_literal: true

module On
  class Destroy < ActiveRecord::Base
    self.table_name = :on_destroy
    has_paper_trail on: [:destroy]
  end
end
