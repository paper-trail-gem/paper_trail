# frozen_string_literal: true

# AR 6.1 does not autoload MigrationContext, so we must `require` it.
#
# ```
# # lib/active_record.rb
# autoload :Migration
# autoload :Migrator, "active_record/migration"
# ```
#
# The above may indicate that we should use `Migrator` instead of
# MigrationContext.
require "active_record/migration"

# Manage migrations including running generators to build them, and cleaning up strays
class PaperTrailSpecMigrator
  def initialize
    @migrations_path = dummy_app_migrations_dir
  end

  def migrate
    ::ActiveRecord::MigrationContext.new(
      @migrations_path,
      schema_migration
    ).migrate
  end

  # Generate a migration, run it, and delete it. We use this for testing the
  # UpdateStiGenerator. We delete the file because we don't want it to exist
  # when we run migrations at the beginning of the next full test suite run.
  #
  # - generator [String] - name of generator, eg. "paper_trail:update_sti"
  # - generator_invoke_args [Array] - arguments to `Generators#invoke`
  def generate_and_migrate(generator, generator_invoke_args)
    generate(generator, generator_invoke_args)
    begin
      migrate
    ensure
      cmd = "git clean -x --force --quiet " + dummy_app_migrations_dir.to_s
      unless system(cmd)
        raise "Unable to clean up after PT migration generator test"
      end
    end
  end

  private

  def schema_migration
    if Rails::VERSION::STRING >= "7.2"
      ::ActiveRecord::Base.connection_pool.schema_migration
    else
      ::ActiveRecord::Base.connection.schema_migration
    end
  end

  def dummy_app_migrations_dir
    Pathname.new(File.expand_path("../dummy_app/db/migrate", __dir__))
  end

  # Run the specified migration generator.
  #
  # We sleep until the next whole second because that is the precision of the
  # timestamp that rails puts in generator filenames. If we didn't sleep,
  # there's a good chance two tests would run within the same second and
  # generate the same exact migration filename. Then, even though we delete the
  # generated migrations after running them, some form of caching (perhaps
  # filesystem, perhaps rails) will run the cached migration file.
  #
  # - generator [String] - name of generator, eg. "paper_trail:update_sti"
  # - generator_invoke_args [Array] - arguments to `Generators#invoke`
  def generate(generator, generator_invoke_args)
    sleep_until_the_next_whole_second
    Rails::Generators.invoke(generator, generator_invoke_args, destination_root: Rails.root)
  end

  def sleep_until_the_next_whole_second
    t = Time.current.to_f
    sleep((t.ceil - t).abs + 0.01)
  end
end
