require 'rails/generators'
require 'rails/generators/active_record'

module PaperTrail
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)
    class_option :with_changes, :type => :boolean, :default => false, :desc => "Store changeset (diff) with each version"

    desc 'Generates (but does not run) a migration to add a versions table.'

    def create_migration_file
      migration_template 'create_versions.rb', 'db/migrate/create_versions.rb'
      migration_template 'add_object_changes_to_versions.rb', 'db/migrate/add_object_changes_to_versions.rb' if options.with_changes?
    end

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end
  end
end
