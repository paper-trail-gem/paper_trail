require 'active_support/concern'

module PaperTrail
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
