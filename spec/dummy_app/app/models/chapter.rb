# frozen_string_literal: true

class Chapter < ApplicationRecord
  has_many :sections, dependent: :destroy
  has_many :paragraphs, through: :sections

  has_many :quotations, dependent: :destroy
  has_many :citations, through: :quotations

  has_paper_trail
end
