# frozen_string_literal: true

class PlanetVersion < PaperTrail::Version
  self.table_name = :planet_versions

  belongs_to :whodunnit, class_name: "User", optional: true
end
