class Translation < ActiveRecord::Base
  has_paper_trail :ignore_if => Proc.new { |t| t.language_code != 'US' }
end
