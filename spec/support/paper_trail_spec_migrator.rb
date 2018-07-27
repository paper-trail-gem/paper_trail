# frozen_string_literal: true

# Manage migrations including running generators to build them, and cleaning up strays
class PaperTrailSpecMigrator
  def initialize
    @migrations_path = dummy_app_migrations_dir
  end

  # Looks like the API for programatically running migrations will change
  # in rails 5.2. This is an undocumented change, AFAICT. Then again,
  # how many people use the programmatic interface? Most people probably
  # just use rake. Maybe we're doing it wrong.
  def migrate
    if ::ActiveRecord.gem_version >= ::Gem::Version.new("5.2.0.rc1")
      ::ActiveRecord::MigrationContext.new(@migrations_path).migrate
    else
      ::ActiveRecord::Migrator.migrate(@migrations_path)
    end
  end

  # Generate a migration, run it, and delete it. We use this for testing the
  # UpdateStiGenerator. We delete the file because we don't want it to exist
  # when we run migrations at the beginning of the next full test suite run.
  #
  # - generator [String] - name of generator, eg. "paper_trail:update_sti"
  # - generator_invoke_args [Array] - arguments to `Generators#invoke`
  def generate_and_migrate(generator, generator_invoke_args)
    files = generate(generator, generator_invoke_args)
    begin
      migrate
    ensure
      files.each do |file|
        File.delete(Rails.root.join(file))
      end
    end
  end

  private

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
    t = Time.now.to_f
    sleep((t.ceil - t).abs + 0.01)
  end
end
