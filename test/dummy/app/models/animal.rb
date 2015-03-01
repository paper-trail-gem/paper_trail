class Animal < ActiveRecord::Base
  has_paper_trail
  self.inheritance_column = 'species'

  attr_accessible :species, :name if ::PaperTrail.active_record_protected_attributes?
end
