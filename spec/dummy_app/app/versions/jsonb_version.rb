# frozen_string_literal: true

class JsonbVersion < ActiveRecord::Base
  include PaperTrail::VersionConcern

  self.table_name = "jsonb_versions"
end
