# frozen_string_literal: true

class ChairWithReadonly < ApplicationRecord
  self.table_name = "chairs"

  has_paper_trail
  attr_readonly :id
end
