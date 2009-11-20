require 'test/unit'
RAILS_ROOT = File.join(File.dirname(__FILE__), %w{.. .. .. ..})
$:.unshift(File.join(File.dirname(__FILE__), %w{.. lib}))

unless defined?(ActiveRecord)
  if File.directory? RAILS_ROOT + 'config'
    puts 'using config/boot.rb'
    ENV['RAILS_ENV'] = 'test'
    require File.join(RAILS_ROOT, 'config', 'boot.rb')
  else
    # simply use installed gems if available
    puts 'using rubygems'
    require 'rubygems'
    gem 'actionpack'; gem 'activerecord'; gem 'activesupport'; gem 'rails'
  end

  %w(action_pack action_controller active_record active_support initializer).each {|f| require f}
end
require 'shoulda'
require 'paper_trail'

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

def connect_to_database
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

  db_adapter = ENV['DB']

  # no db passed, try one of these fine config-free DBs before bombing.
  db_adapter ||=
    begin
      require 'rubygems'
      require 'sqlite'
      'sqlite'
    rescue MissingSourceFile
      begin
        require 'sqlite3'
        'sqlite3'
      rescue MissingSourceFile
      end
    end

  if db_adapter.nil?
    raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
end

def load_schema
  connect_to_database
  load(File.dirname(__FILE__) + "/schema.rb")
  require File.dirname(__FILE__) + '/../rails/init.rb'
end

def change_schema
  load(File.dirname(__FILE__) + "/schema_change.rb")
end
