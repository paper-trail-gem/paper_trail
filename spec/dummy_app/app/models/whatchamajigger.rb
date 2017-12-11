# frozen_string_literal: true

class Whatchamajigger < ActiveRecord::Base
  has_paper_trail

  if ActiveRecord.gem_version >= Gem::Version.new("5.0")
    belongs_to :owner, polymorphic: true, optional: true
  else
    belongs_to :owner, polymorphic: true
  end
end
