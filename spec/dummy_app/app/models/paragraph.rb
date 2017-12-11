# frozen_string_literal: true

class Paragraph < ActiveRecord::Base
  belongs_to :section

  has_paper_trail
end
