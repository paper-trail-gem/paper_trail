class Glimmer < ActiveRecord::Base
  belongs_to :widget
  has_paper_trail
end
