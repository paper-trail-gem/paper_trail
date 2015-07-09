# This model does not record versions when updated.
class NotOnUpdate < ActiveRecord::Base
  has_paper_trail :on => [:create, :destroy]
end
