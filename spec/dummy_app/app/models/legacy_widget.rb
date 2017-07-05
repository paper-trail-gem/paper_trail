# The `legacy_widgets` table has a `version` column that would conflict with our
# `version` method. It is configured to define a method named `custom_version`
# instead.
class LegacyWidget < ActiveRecord::Base
  has_paper_trail ignore: :version, version: "custom_version"
end
