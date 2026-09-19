# frozen_string_literal: true

# Demonstrates `encrypts ignore_case: true`. See also the `original_title` column.
class Palimpsest < ApplicationRecord
  has_paper_trail

  encrypts :title, deterministic: true, ignore_case: true
end
