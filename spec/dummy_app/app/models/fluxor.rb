# frozen_string_literal: true

class Fluxor < ActiveRecord::Base
  belongs_to :widget, optional: true
end
