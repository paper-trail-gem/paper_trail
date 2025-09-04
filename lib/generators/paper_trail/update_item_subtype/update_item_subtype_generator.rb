# frozen_string_literal: true

require_relative "../migration_generator"

module PaperTrail
  # Updates STI entries for PaperTrail
  class UpdateItemSubtypeGenerator < MigrationGenerator
    source_root File.expand_path("templates", __dir__)

    # Remove the inherited version_class_name argument as we use an option instead
    remove_argument :version_class_name

    argument :hints, type: :array, default: [], banner: "hint1 hint2"

    class_option :version_class_name,
      type: :string,
      default: "Version",
      aliases: ["-v"],
      desc: "The name of the Version class (e.g., CommentVersion)"

    desc(
      "Generates (but does not run) a migration to update item_subtype for " \
      "STI entries in an existing versions table."
    )

    def create_migration_file
      add_paper_trail_migration("update_#{table_name}_for_item_subtype", sti_type_options: options)
    end

    # Return the version class name from options
    def version_class_name
      options[:version_class_name]
    end

    # Return the fully qualified class name for use in ERB templates
    def fully_qualified_version_class_name
      version_class_name == "Version" ? "PaperTrail::Version" : version_class_name
    end
  end
end
