# frozen_string_literal: true

class LimitedBicycle < Vehicle
  has_paper_trail limit: 3
end
