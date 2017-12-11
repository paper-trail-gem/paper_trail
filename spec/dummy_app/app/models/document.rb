# frozen_string_literal: true

# Demonstrates a "custom versions association name". Instead of the assication
# being named `versions`, it will be named `paper_trail_versions`.
class Document < ActiveRecord::Base
  has_paper_trail(
    versions: :paper_trail_versions,
    on: %i[create update]
  )
end
