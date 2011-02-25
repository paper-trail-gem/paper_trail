class Authorship < ActiveRecord::Base
  belongs_to :book
  belongs_to :person
  has_paper_trail
end
