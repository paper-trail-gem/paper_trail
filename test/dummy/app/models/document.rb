class Document < ActiveRecord::Base
  has_paper_trail :association => :paper_trail_versions
end
