# frozen_string_literal: true

class Editorship < ActiveRecord::Base
  belongs_to :book
  belongs_to :editor
  has_paper_trail
end
