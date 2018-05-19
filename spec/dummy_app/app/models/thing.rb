# frozen_string_literal: true

class Thing < ActiveRecord::Base
  has_paper_trail save_changes: false

  belongs_to :person, optional: true
end
