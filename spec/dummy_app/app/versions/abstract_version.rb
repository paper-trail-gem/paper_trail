# frozen_string_literal: true

class AbstractVersion < ApplicationRecord
  include PaperTrail::VersionConcern
  self.abstract_class = true
end
