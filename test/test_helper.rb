require 'rubygems'

require 'test/unit'
require 'shoulda'

require 'active_record'
require 'action_controller'
require 'action_controller/test_process'
require 'active_support'
require 'active_support/test_case'

require 'lib/paper_trail'

def connect_to_database
  ActiveRecord::Base.establish_connection(
    :adapter  => "sqlite3",
    :database => ":memory:"
  )
  ActiveRecord::Migration.verbose = false
end

def load_schema
  connect_to_database
  load File.dirname(__FILE__) + '/schema.rb'
end

def change_schema
  load File.dirname(__FILE__) + '/schema_change.rb'
end

class ActiveRecord::Base
  def logger
    @logger ||= Logger.new(nil)
  end
end

class ActionController::Base
  def logger
    @logger ||= Logger.new(nil)
  end
end

load_schema
