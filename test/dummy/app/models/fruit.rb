class Fruit < ActiveRecord::Base
  if ENV['DB'] == 'postgres' || JsonVersion.table_exists?
    has_paper_trail :class_name => 'JsonVersion'
  end
end
