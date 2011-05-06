class Animal < ActiveRecord::Base
  has_paper_trail
  set_inheritance_column 'species'
end
