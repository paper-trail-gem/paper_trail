class PostWithStatus < ActiveRecord::Base
  has_paper_trail
  enum status: { draft: 0, published: 1, archived: 2 }
end
