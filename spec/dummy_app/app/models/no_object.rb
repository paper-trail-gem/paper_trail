# frozen_string_literal: true

# Demonstrates a table that omits the `object` column.
class NoObject < ApplicationRecord
  has_paper_trail(
    versions: { class_name: "NoObjectVersion" },
    meta: { metadatum: 42 }
  )
  validates :letter, length: { is: 1 }, presence: true
end
