# frozen_string_literal: true

class Whatchamajigger < ActiveRecord::Base
  has_paper_trail
  belongs_to :owner, polymorphic: true, optional: true
end
