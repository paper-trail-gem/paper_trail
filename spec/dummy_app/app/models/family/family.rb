# frozen_string_literal: true

module Family
  class Family < ActiveRecord::Base
    has_paper_trail

    has_many :familie_lines, class_name: "::Family::FamilyLine", foreign_key: :parent_id
    has_many :children, class_name: "::Family::Family", foreign_key: :parent_id
    has_many :grandsons, through: :familie_lines
    has_one :mentee, class_name: "::Family::Family", foreign_key: :partner_id
    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      belongs_to :parent, class_name: "::Family::Family", foreign_key: :parent_id, optional: true
    else
      belongs_to :parent, class_name: "::Family::Family", foreign_key: :parent_id
    end
    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      belongs_to :mentor, class_name: "::Family::Family", foreign_key: :partner_id, optional: true
    else
      belongs_to :mentor, class_name: "::Family::Family", foreign_key: :partner_id
    end

    accepts_nested_attributes_for :mentee
    accepts_nested_attributes_for :children
  end
end
