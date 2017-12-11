# frozen_string_literal: true

require "paper_trail/version_concern"

module PaperTrail
  # This is the default ActiveRecord model provided by PaperTrail. Most simple
  # applications will only use this and its partner, `VersionAssociation`, but
  # it is possible to sub-class, extend, or even do without this model entirely.
  # See the readme for details.
  class Version < ::ActiveRecord::Base
    include PaperTrail::VersionConcern
  end
end
