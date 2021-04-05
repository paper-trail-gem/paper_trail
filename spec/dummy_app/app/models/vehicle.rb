# frozen_string_literal: true

class Vehicle < ActiveRecord::Base
  # This STI parent class specifically does not call `has_paper_trail`.
  # Of its sub-classes, only `Car` and `Bicycle` are versioned.
  belongs_to :owner, class_name: "Person", optional: true
end
