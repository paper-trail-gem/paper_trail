# frozen_string_literal: true

class Truck < Vehicle
  # This STI child class specifically does not call `has_paper_trail`.
  # Of the sub-classes of `Vehicle`, only `Car` and `Bicycle` are versioned.
end
