require 'active_support/concern'

module PaperTrail
  module VersionAssociationConcern
    extend ::ActiveSupport::Concern

    included do
      belongs_to :version

      attr_accessible :version_id, :foreign_key_name, :foreign_key_id if PaperTrail.active_record_protected_attributes?
    end
  end
end
