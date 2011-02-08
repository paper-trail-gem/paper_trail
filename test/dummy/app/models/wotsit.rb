class Wotsit < ActiveRecord::Base
  has_paper_trail
  belongs_to :widget
end
