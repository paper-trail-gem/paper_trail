# frozen_string_literal: true

class Wotsit < ApplicationRecord
  has_paper_trail

  belongs_to :widget, optional: true

  def created_on
    created_at.to_date
  end
end
