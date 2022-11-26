# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :customer, touch: :touched_at
  has_many :line_items
  has_paper_trail
end
