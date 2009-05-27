class PaperTrailGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      m.migration_template 'create_versions.rb', 'db/migrate', :migration_file_name => 'create_versions'
    end
  end

end
