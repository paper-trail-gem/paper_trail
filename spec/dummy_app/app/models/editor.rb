# to demonstrate a has_through association that does not have paper_trail enabled
class Editor < ActiveRecord::Base
  has_many :editorships, dependent: :destroy
end
