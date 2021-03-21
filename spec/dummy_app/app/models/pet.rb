# frozen_string_literal: true

class Pet < ActiveRecord::Base
  belongs_to :owner, class_name: "Person", optional: true
  belongs_to :animal, optional: true
  has_paper_trail
end
