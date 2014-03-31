require File.expand_path('../version_concern', __FILE__)

module PaperTrail
  class Version < ::ActiveRecord::Base
    self.table_name = "paper_trail_versions"
    include PaperTrail::VersionConcern
  end
end
