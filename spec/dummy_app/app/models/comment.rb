# frozen_string_literal: true

class Comment < ApplicationRecord
  has_paper_trail debounce_ms: 1000, ignore: [:flagged]
end
