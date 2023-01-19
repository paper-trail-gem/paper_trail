# frozen_string_literal: true

class Gizmo < ApplicationRecord
  has_paper_trail synchronize_version_creation_timestamp: false
end
