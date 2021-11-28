# frozen_string_literal: true

# Demonstrates the `if` and `unless` configuration options.
class Translation < ActiveRecord::Base
  has_paper_trail(
    if: proc { |t| t.language_code == "US" },
    unless: proc { |t| t.draft_status == "DRAFT" }
  )
end
