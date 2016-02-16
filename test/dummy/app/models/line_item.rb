class LineItem < ActiveRecord::Base
  belongs_to :order, dependent: :destroy
  has_paper_trail
end
