module Family
  class Grandson < ActiveRecord::Base
    has_paper_trail

    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      belongs_to :child, optional: true
    else
      belongs_to :child
    end
    has_many :families
    has_many :parents, through: :families
  end
end
