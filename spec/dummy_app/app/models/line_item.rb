# frozen_string_literal: true

class LineItem < ActiveRecord::Base
  belongs_to :order, dependent: :destroy
  has_paper_trail
end
