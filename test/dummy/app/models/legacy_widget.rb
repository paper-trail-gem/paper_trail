class LegacyWidget < ActiveRecord::Base
  has_paper_trail :ignore => :version,
                  :version_name => 'custom_version'
end
