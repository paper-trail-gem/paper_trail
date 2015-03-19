class Widget < ActiveRecord::Base
  has_paper_trail
  has_one :wotsit
  has_many :whatchamajiggers, :as => :owner

  EXCLUDED_NAME = 'Biglet'

  validates :name, :exclusion => { :in => [EXCLUDED_NAME] }

  if ::ActiveRecord::VERSION::MAJOR >= 4 # `has_many` syntax for specifying order uses a lambda in Rails 4
    has_many :fluxors, lambda { order(:name) }
  else
    has_many :fluxors, :order => :name
  end
end
