class Widget < ActiveRecord::Base
  has_one :wotsit
  has_many :fluxors, :order => :name
  has_many :glimmers, :order => :name
  
  has_paper_trail
end
