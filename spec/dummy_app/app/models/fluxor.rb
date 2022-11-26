# frozen_string_literal: true

class Fluxor < ApplicationRecord
  belongs_to :widget, optional: true
end
