# frozen_string_literal: true

class Fluxor < ActiveRecord::Base
  if ActiveRecord.gem_version >= Gem::Version.new("5.0")
    belongs_to :widget, optional: true
  else
    belongs_to :widget
  end
end
