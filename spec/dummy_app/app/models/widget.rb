# frozen_string_literal: true

class Widget < ActiveRecord::Base
  EXCLUDED_NAME = "Biglet"
  has_paper_trail
  has_one :wotsit
  has_many(:fluxors, -> { order(:name) })
  has_many :whatchamajiggers, as: :owner
  validates :name, exclusion: { in: [EXCLUDED_NAME] }
end
