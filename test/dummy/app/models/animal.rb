class Animal < ActiveRecord::Base
  has_paper_trail
  self.inheritance_column = 'species'
end
