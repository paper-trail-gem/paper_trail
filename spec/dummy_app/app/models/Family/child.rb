module Family
  class Child < ActiveRecord::Base
    has_paper_trail

    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      belongs_to :parent, optional: true
    else
      belongs_to :parent
    end
    has_many :grandsons
  end
end
