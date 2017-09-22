module Family
  class Parent < ActiveRecord::Base
    has_paper_trail

    has_one :partner
    has_many :children
    has_many :families
    has_many :grandsons, through: :families

    accepts_nested_attributes_for :children
  end
end
