module Family
  class FamilyLine < ActiveRecord::Base
    has_paper_trail

    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      belongs_to :parent, class_name: "::Family::Family", foreign_key: :parent_id, optional: true
    else
      belongs_to :parent, class_name: "::Family::Family", foreign_key: :parent_id
    end
    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      belongs_to :grandson, class_name: "::Family::Family",
                            foreign_key: :grandson_id,
                            optional: true
    else
      belongs_to :grandson, class_name: "::Family::Family",
                            foreign_key: :grandson_id
    end
  end
end
