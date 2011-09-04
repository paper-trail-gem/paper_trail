class Widget < ActiveRecord::Base
  has_paper_trail
  has_one :wotsit
  has_many :fluxors, :order => :name
  has_many :glimmers, :order => :name
end
