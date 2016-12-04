require "active_support/concern"

module PaperTrail
  # Functionality for `PaperTrail::VersionAssociation`. Exists in a module
  # for the same reasons outlined in version_concern.rb.
  module VersionAssociationConcern
    extend ::ActiveSupport::Concern

    included do
      belongs_to :version
    end
  end
end
