# frozen_string_literal: true

class JsonbVersion < ApplicationRecord
  include PaperTrail::VersionConcern

  self.table_name = "jsonb_versions"
end
