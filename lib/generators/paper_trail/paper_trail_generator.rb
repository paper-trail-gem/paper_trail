require 'rails/generators/named_base'
require 'rails/generators/migration'

class PaperTrailGenerator < Rails::Generators::NamedBase
  include Rails::Generators::Migration
  
  desc "Generates (but does not run) a migration to add a versions table."

  source_root File.expand_path('../templates', __FILE__)
  
  argument :name, :type => :string, :default => "create_versions"
  
  # Implement the required interface for Rails::Generators::Migration.
  # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
  def self.next_migration_number(dirname)
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end

  def create_migration_file
    migration_template 'create_versions.rb', 'db/migrate/create_versions.rb'
  end


end
