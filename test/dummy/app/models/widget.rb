class Widget < ActiveRecord::Base
  has_paper_trail
  has_one :wotsit

  if ActiveRecord::VERSION::STRING.to_f >= 4.0 # `has_many` syntax for specifying order uses a lambda in Rails 4
    has_many :fluxors, -> { order(:name) }
  else
    has_many :fluxors, :order => :name
  end
end
