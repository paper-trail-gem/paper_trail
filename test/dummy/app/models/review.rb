class Review < ActiveRecord::Base
  belongs_to :reviewable, polymorphic: true

  has_paper_trail
end
