# frozen_string_literal: true

class Tomato < Plant
  class << self
    def sti_name
      "tomato"
    end
  end
end
