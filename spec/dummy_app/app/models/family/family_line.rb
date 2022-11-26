# frozen_string_literal: true

module Family
  class FamilyLine < ApplicationRecord
    has_paper_trail
    belongs_to :parent,
      class_name: "::Family::Family",
      optional: true
    belongs_to :grandson,
      class_name: "::Family::Family",
      optional: true
  end
end
