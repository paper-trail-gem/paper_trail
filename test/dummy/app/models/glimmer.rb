class Glimmer < ActiveRecord::Base
  belongs_to :widget
  has_one :gadget
  
  has_paper_trail
end
 