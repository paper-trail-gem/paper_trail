module Family
  class Partner < ActiveRecord::Base
    has_paper_trail

    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      belongs_to :parent, optional: true
    else
      belongs_to :parent
    end
  end
end
