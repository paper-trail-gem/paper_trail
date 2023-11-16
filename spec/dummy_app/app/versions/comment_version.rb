# frozen_string_literal: true

class CommentVersion < PaperTrail::Version
  self.table_name = "comment_versions"
  # add rails validation to require whodunnit
  validates :whodunnit, presence: true
end
