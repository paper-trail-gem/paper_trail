# frozen_string_literal: true

class Whatchamajigger < ApplicationRecord
  has_paper_trail
  belongs_to :owner, polymorphic: true, optional: true
end
