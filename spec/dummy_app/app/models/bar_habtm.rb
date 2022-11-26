# frozen_string_literal: true

class BarHabtm < ApplicationRecord
  has_and_belongs_to_many :foo_habtms
  has_paper_trail
end
