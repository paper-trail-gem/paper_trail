# frozen_string_literal: true

class Book < ApplicationRecord
  has_many :authorships, dependent: :destroy
  has_many :authors, through: :authorships

  has_many :editorships, dependent: :destroy
  has_many :editors, through: :editorships

  has_paper_trail
end
