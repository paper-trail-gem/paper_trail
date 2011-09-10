class Gadget < ActiveRecord::Base
  belongs_to :glimmer
  has_paper_trail
  
  after_commit do
    glimmer.update_attributes :child_updated_at => Time.now if glimmer.present?
  end
end
