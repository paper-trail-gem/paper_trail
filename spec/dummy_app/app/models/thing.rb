# frozen_string_literal: true

class Thing < ApplicationRecord
  has_paper_trail versions: {
    scope: -> { order("id desc") },
    extend: PrefixVersionsInspectWithCount
  }
  belongs_to :person, optional: true
end
