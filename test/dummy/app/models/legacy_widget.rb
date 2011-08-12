class LegacyWidget < ActiveRecord::Base
  has_paper_trail :version_method_name => 'custom_version'
end