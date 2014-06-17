class PostWithStatus < ActiveRecord::Base
  has_paper_trail

  # ActiveRecord::Enum is only supported in AR4.1+
  if defined?(ActiveRecord::Enum)
    enum :status => { :draft => 0, :published => 1, :archived => 2 }
  end
end
