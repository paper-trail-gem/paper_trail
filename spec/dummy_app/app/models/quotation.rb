# frozen_string_literal: true

class Quotation < ApplicationRecord
  belongs_to :chapter
  has_many :citations, dependent: :destroy
  has_paper_trail
end
