# frozen_string_literal: true

# Looks like the API for programatically running migrations will change
# in rails 5.2. This is an undocumented change, AFAICT. Then again,
# how many people use the programmatic interface? Most people probably
# just use rake. Maybe we're doing it wrong.
class PaperTrailSpecMigrator
  def initialize(migrations_path)
    @migrations_path = migrations_path
  end

  def migrate
    if ::ActiveRecord.gem_version >= ::Gem::Version.new("5.2.0.rc1")
      ::ActiveRecord::MigrationContext.new(@migrations_path).migrate
    else
      ::ActiveRecord::Migrator.migrate(@migrations_path)
    end
  end
end
