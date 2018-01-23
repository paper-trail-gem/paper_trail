# frozen_string_literal: true

class AbstractVersion < ActiveRecord::Base
  include PaperTrail::VersionConcern
  self.abstract_class = true
end
