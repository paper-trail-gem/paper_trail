require "active_support/concern"

module PaperTrail
  # Functionality for `PaperTrail::VersionAssociation`. Exists in a module
  # for the same reasons outlined in version_concern.rb.
  module VersionAssociationConcern
    extend ::ActiveSupport::Concern

    included do
      belongs_to :version

      if PaperTrail.active_record_protected_attributes?
        attr_accessible :version_id, :foreign_key_name, :foreign_key_id
      end
    end
  end
end
