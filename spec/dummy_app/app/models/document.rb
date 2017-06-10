class Document < ActiveRecord::Base
  has_paper_trail(
    versions: :paper_trail_versions,
    on: %i[create update]
  )
end
