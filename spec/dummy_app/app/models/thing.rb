# frozen_string_literal: true

class Thing < ActiveRecord::Base
  has_paper_trail versions: {
    extend: PrefixVersionsInspectWithCount,
    scope: -> { order("id desc") }
  }

  if ActiveRecord.gem_version >= Gem::Version.new("5.0")
    belongs_to :person, optional: true
  else
    belongs_to :person
  end
end
