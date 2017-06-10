class Thing < ActiveRecord::Base
  has_paper_trail save_changes: false
end
