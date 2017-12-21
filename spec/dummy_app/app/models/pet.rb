# frozen_string_literal: true

class Pet < ActiveRecord::Base
  belongs_to :owner, class_name: "Person"
  belongs_to :animal

  has_paper_trail
end
