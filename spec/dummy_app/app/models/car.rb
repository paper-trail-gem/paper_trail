# frozen_string_literal: true

class Car < Vehicle
  has_paper_trail
  attribute :color, type: ActiveModel::Type::String
  attr_accessor :top_speed
end
