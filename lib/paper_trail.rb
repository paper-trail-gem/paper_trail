require 'paper_trail/config'
require 'paper_trail/has_paper_trail'
require 'paper_trail/cleaner'
require 'paper_trail/version_number'

# Require serializers
Dir[File.join(File.dirname(__FILE__), 'paper_trail', 'serializers', '*.rb')].each { |file| require file }

module PaperTrail
  extend PaperTrail::Cleaner

  # Switches PaperTrail on or off.
  def self.enabled=(value)
    PaperTrail.config.enabled = value
  end

  # Returns `true` if PaperTrail is on, `false` otherwise.
  # PaperTrail is enabled by default.
  def self.enabled?
    !!PaperTrail.config.enabled
  end

  # Sets whether PaperTrail is enabled or disabled for the current request.
  def self.enabled_for_controller=(value)
    paper_trail_store[:request_enabled_for_controller] = value
  end

  # Returns `true` if PaperTrail is enabled for the request, `false` otherwise.
  #
  # See `PaperTrail::Rails::Controller#paper_trail_enabled_for_controller`.
  def self.enabled_for_controller?
    !!paper_trail_store[:request_enabled_for_controller]
  end

  # Set the field which records when a version was created.
  def self.timestamp_field=(field_name)
    PaperTrail.config.timestamp_field = field_name
  end

  # Returns the field which records when a version was created.
  def self.timestamp_field
    PaperTrail.config.timestamp_field
  end

  # Sets who is responsible for any changes that occur.
  # You would normally use this in a migration or on the console,
  # when working with models directly.  In a controller it is set
  # automatically to the `current_user`.
  def self.whodunnit=(value)
    paper_trail_store[:whodunnit] = value
  end

  # Returns who is reponsible for any changes that occur.
  def self.whodunnit
    paper_trail_store[:whodunnit]
  end

  # Sets any information from the controller that you want PaperTrail
  # to store.  By default this is set automatically by a before filter.
  def self.controller_info=(value)
    paper_trail_store[:controller_info] = value
  end

  # Returns any information from the controller that you want
  # PaperTrail to store.
  #
  # See `PaperTrail::Rails::Controller#info_for_paper_trail`.
  def self.controller_info
    paper_trail_store[:controller_info]
  end

  # Getter and Setter for PaperTrail Serializer
  def self.serializer=(value)
    PaperTrail.config.serializer = value
  end

  def self.serializer
    PaperTrail.config.serializer
  end

  def self.active_record_protected_attributes?
    @active_record_protected_attributes ||= ::ActiveRecord::VERSION::STRING.to_f < 4.0 || !!defined?(ProtectedAttributes)
  end

  private

  # Thread-safe hash to hold PaperTrail's data.
  # Initializing with needed default values.
  def self.paper_trail_store
    Thread.current[:paper_trail] ||= { :request_enabled_for_controller => true }
  end

  # Returns PaperTrail's configuration object.
  def self.config
    @@config ||= PaperTrail::Config.instance
  end

  def self.configure
    yield config
  end
end

# Ensure `ProtectedAttributes` gem gets required if it is available before the `Version` class gets loaded in
unless PaperTrail.active_record_protected_attributes?
  PaperTrail.send(:remove_instance_variable, :@active_record_protected_attributes)
  begin
    require 'protected_attributes'
  rescue LoadError; end # will rescue if `ProtectedAttributes` gem is not available
end

require 'paper_trail/version'

# Require frameworks
require 'paper_trail/frameworks/rails'
require 'paper_trail/frameworks/sinatra'
require 'paper_trail/frameworks/rspec' if defined? RSpec
require 'paper_trail/frameworks/cucumber' if defined? World

ActiveSupport.on_load(:active_record) do
  include PaperTrail::Model
end

if defined?(ActionController)
  ActiveSupport.on_load(:action_controller) do
    include PaperTrail::Rails::Controller
  end
end
