# frozen_string_literal: true

class Customer < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_paper_trail
end
