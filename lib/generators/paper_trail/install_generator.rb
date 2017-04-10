require "rails/generators"
require "rails/generators/active_record"

module PaperTrail
  # Installs PaperTrail in a rails app.
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    # Class names of MySQL adapters.
    # - `MysqlAdapter` - Used by gems: `mysql`, `activerecord-jdbcmysql-adapter`.
    # - `Mysql2Adapter` - Used by `mysql2` gem.
    MYSQL_ADAPTERS = [
      "ActiveRecord::ConnectionAdapters::MysqlAdapter",
      "ActiveRecord::ConnectionAdapters::Mysql2Adapter"
    ].freeze

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
          item_type_options: item_type_options,
          migration_version: migration_version,
          versions_table_options: versions_table_options
        )
      end
    end

    private

    # MySQL 5.6 utf8mb4 limit is 191 chars for keys used in indexes.
    # See https://github.com/airblade/paper_trail/issues/651
    def item_type_options
      opt = { null: false }
      opt[:limit] = 191 if mysql?
      ", #{opt}"
    end

    def migration_version
      major = ActiveRecord::VERSION::MAJOR
      if major >= 5
        "[#{major}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end

    def mysql?
      MYSQL_ADAPTERS.include?(ActiveRecord::Base.connection.class.name)
    end

    # Even modern versions of MySQL still use `latin1` as the default character
    # encoding. Many users are not aware of this, and run into trouble when they
    # try to use PaperTrail in apps that otherwise tend to use UTF-8. Postgres, by
    # comparison, uses UTF-8 except in the unusual case where the OS is configured
    # with a custom locale.
    #
    # - https://dev.mysql.com/doc/refman/5.7/en/charset-applications.html
    # - http://www.postgresql.org/docs/9.4/static/multibyte.html
    #
    # Furthermore, MySQL's original implementation of UTF-8 was flawed, and had
    # to be fixed later by introducing a new charset, `utf8mb4`.
    #
    # - https://mathiasbynens.be/notes/mysql-utf8mb4
    # - https://dev.mysql.com/doc/refman/5.5/en/charset-unicode-utf8mb4.html
    #
    def versions_table_options
      if mysql?
        ', { options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" }'
      else
        ""
      end
    end
  end
end
