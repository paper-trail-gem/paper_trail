class Skipper < ActiveRecord::Base
  has_paper_trail ignore: [:created_at], skip: [:another_timestamp]
end
