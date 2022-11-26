# frozen_string_literal: true

class Editorship < ApplicationRecord
  belongs_to :book
  belongs_to :editor
  has_paper_trail
end
