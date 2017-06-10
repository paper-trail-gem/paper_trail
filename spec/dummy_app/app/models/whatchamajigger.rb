class Whatchamajigger < ActiveRecord::Base
  has_paper_trail
  belongs_to :owner, polymorphic: true
end
