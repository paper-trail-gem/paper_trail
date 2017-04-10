require "rails/generators"
require "rails/generators/active_record"

module PaperTrail
  # Installs PaperTrail in a rails app.
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    source_root File.expand_path("../templates", __FILE__)
    class_option(
      :with_changes,
      type: :boolean,
      default: false,
      desc: "Store changeset (diff) with each version"
    )
    class_option(
      :with_associations,
      type: :boolean,
      default: false,
      desc: "Store transactional IDs to support association restoration"
    )

    desc "Generates (but does not run) a migration to add a versions table." \
         "  Also generates an initializer file for configuring PaperTrail"

    def create_migration_file
      add_paper_trail_migration("create_versions")
      add_paper_trail_migration("add_object_changes_to_versions") if options.with_changes?
      if options.with_associations?
        add_paper_trail_migration("create_version_associations")
        add_paper_trail_migration("add_transaction_id_column_to_versions")
      end
    end

    def create_initializer
      create_file(
        "config/initializers/paper_trail.rb",
        "PaperTrail.config.track_associations = #{!!options.with_associations?}"
      )
    end

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    protected

    def add_paper_trail_migration(template)
      migration_dir = File.expand_path("db/migrate")
      if self.class.migration_exists?(migration_dir, template)
        ::Kernel.warn "Migration already exists: #{template}"
      else
        migration_template(
          "#{template}.rb.erb",
          "db/migrate/#{template}.rb",
          migration_version: migration_version
        )
      end
    end

    def migration_version
      major = ActiveRecord::VERSION::MAJOR
      if major >= 5
        "[#{major}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
