class PostVersion < PaperTrail::Version
  self.table_name = "post_versions"

  attr_accessible :comments_count if ::PaperTrail.active_record_protected_attributes?

  def self.meta
    { comments_count: 42 }
  end
end
