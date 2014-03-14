require 'rails/generators'
require 'rails/generators/active_record'

module PaperTrail
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)
    class_option :with_changes, :type => :boolean, :default => false, :desc => "Store changeset (diff) with each version"

    desc 'Generates (but does not run) a migration to add a versions table.'

    def create_migration_file
      add_paper_trail_migration('create_versions')
      add_paper_trail_migration('add_object_changes_to_versions') if options.with_changes?
      add_paper_trail_migration('create_version_associations')
      add_paper_trail_migration('add_transaction_id_column_to_versions')
    end

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    protected
    def add_paper_trail_migration(template)
      migration_dir = File.expand_path('db/migrate')

      if !self.class.migration_exists?(migration_dir, template)
        migration_template "#{template}.rb", "db/migrate/#{template}.rb"
      end
    end
  end
end
