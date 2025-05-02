# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module PaperTrail
  # Basic structure to support a generator that builds a migration
  class MigrationGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    # Define arguments for the generator
    argument :version_class_name, type: :string, default: "Version",
      desc: "The name of the Version class (e.g., CommentVersion)"

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    protected

    def add_paper_trail_migration(template, extra_options = {})
      migration_dir = File.expand_path("db/migrate")
      if self.class.migration_exists?(migration_dir, template)
        ::Kernel.warn "Migration already exists: #{template}"
      else
        # Map the dynamic template name to the actual template file
        template_file = map_template_name(template)

        migration_template(
          "#{template_file}.rb.erb",
          "db/migrate/#{template}.rb",
          {
            migration_version: migration_version,
            table_name: table_name,
            version_class_name: version_class_name
          }.merge(extra_options)
        )
      end
    end

    def migration_version
      format(
        "[%d.%d]",
        ActiveRecord::VERSION::MAJOR,
        ActiveRecord::VERSION::MINOR
      )
    end

    # Convert Version class name to table name using Rails conventions
    def table_name
      version_class_name.underscore.pluralize
    end

    # Map the dynamic template name to the actual template file
    def map_template_name(template)
      if template.start_with?("create_")
        "create_versions"
      elsif template.start_with?("add_object_changes_to_")
        "add_object_changes_to_versions"
      else
        template
      end
    end
  end
end
