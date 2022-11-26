# frozen_string_literal: true

class Paragraph < ApplicationRecord
  belongs_to :section

  has_paper_trail
end
