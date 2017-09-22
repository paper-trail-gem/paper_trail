module Family
  class Family < ActiveRecord::Base
    has_paper_trail

    belongs_to :parent
    belongs_to :grandson
  end
end
