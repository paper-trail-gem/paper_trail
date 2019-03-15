# frozen_string_literal: true

# The purpose of this custom version class is to test the scope methods on the
# VersionConcern::ClassMethods module.
class JoinedVersion < PaperTrail::Version
  default_scope { joins("INNER JOIN widgets ON widgets.id = versions.item_id") }
end
