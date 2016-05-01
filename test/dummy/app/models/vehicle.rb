class Vehicle < ActiveRecord::Base
  # This STI parent class specifically does not call `has_paper_trail`.
  # Of the sub-classes of `Vehicle`, only `Car` is versioned.
end
