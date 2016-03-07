# The purpose of this custom version class is to test the scope methods on the
# VersionConcern::ClassMethods module. See
# https://github.com/airblade/paper_trail/issues/295 for more details.
class JoinedVersion < PaperTrail::Version
  default_scope { joins("INNER JOIN widgets ON widgets.id = versions.item_id") }
end
