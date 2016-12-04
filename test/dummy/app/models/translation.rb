class Translation < ActiveRecord::Base
  has_paper_trail(
    if: proc { |t| t.language_code == "US" },
    unless: proc { |t| t.type == "DRAFT" }
  )
end
