require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record/migration'

module PaperTrail
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    extend ActiveRecord::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    desc 'Generates (but does not run) a migration to add a versions table.'

    def create_migration_file
      migration_template 'create_versions.rb', 'db/migrate/create_versions.rb'
      migration_template 'create_version_associations.rb', 'db/migrate/create_version_associations.rb'
    end
  end
end
