# frozen_string_literal: true

# Demonstrates a table that omits the `object` column.
class NoObject < ActiveRecord::Base
  has_paper_trail(
    class_name: "NoObjectVersion",
    meta: { metadatum: 42 }
  )
  validates :letter, length: { is: 1 }, presence: true
end
