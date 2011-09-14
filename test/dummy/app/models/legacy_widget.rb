class LegacyWidget < ActiveRecord::Base
  has_paper_trail :version_name => 'custom_version'
end
