require 'paper_trail/version_association_concern'

module PaperTrail
  class VersionAssociation < ::ActiveRecord::Base
    include PaperTrail::VersionAssociationConcern
  end
end