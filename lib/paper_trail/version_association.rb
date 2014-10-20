module PaperTrail
  class VersionAssociation < ActiveRecord::Base
    belongs_to :version

    attr_accessible :version_id, :foreign_key_name, :foreign_key_id if PaperTrail.try(:active_record_protected_attributes?)
  end
end