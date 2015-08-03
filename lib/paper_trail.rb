require 'request_store'

# Require core library
Dir[File.join(File.dirname(__FILE__), 'paper_trail', '*.rb')].each do |file|
  require File.join('paper_trail', File.basename(file, '.rb'))
end

# Require serializers
Dir[File.join(File.dirname(__FILE__), 'paper_trail', 'serializers', '*.rb')].each do |file|
  require File.join('paper_trail', 'serializers', File.basename(file, '.rb'))
end

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

  # ActiveRecord 5 drops support for serialized attributes; for previous
  # versions of ActiveRecord it is supported, we have a config option
  # to enable it within PaperTrail.
  def self.serialized_attributes?
    !!PaperTrail.config.serialized_attributes && ::ActiveRecord::VERSION::MAJOR < 5
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

  # Sets whether PaperTrail is enabled or disabled for this model in the
  # current request.
  def self.enabled_for_model(model, value)
    paper_trail_store[:"enabled_for_#{model}"] = value
  end

  # Returns `true` if PaperTrail is enabled for this model in the current
  # request, `false` otherwise.
  def self.enabled_for_model?(model)
    !!paper_trail_store.fetch(:"enabled_for_#{model}", true)
  end

  # Set the field which records when a version was created.
  def self.timestamp_field=(field_name)
    PaperTrail.config.timestamp_field = field_name
  end

  # Returns the field which records when a version was created.
  def self.timestamp_field
    PaperTrail.config.timestamp_field
  end

  # Sets who is responsible for any changes that occur. You would normally use
  # this in a migration or on the console, when working with models directly.
  # In a controller it is set automatically to the `current_user`.
  def self.whodunnit=(value)
    paper_trail_store[:whodunnit] = value
  end

  # Returns who is reponsible for any changes that occur.
  def self.whodunnit
    paper_trail_store[:whodunnit]
  end

  # Sets any information from the controller that you want PaperTrail to
  # store.  By default this is set automatically by a before filter.
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
    @active_record_protected_attributes ||= ::ActiveRecord::VERSION::MAJOR < 4 || !!defined?(ProtectedAttributes)
  end

  def self.transaction?
    ::ActiveRecord::Base.connection.open_transactions > 0
  end

  def self.transaction_id
    paper_trail_store[:transaction_id]
  end

  def self.transaction_id=(id)
    paper_trail_store[:transaction_id] = id
  end

  private

  # Thread-safe hash to hold PaperTrail's data. Initializing with needed
  # default values.
  def self.paper_trail_store
    RequestStore.store[:paper_trail] ||= { :request_enabled_for_controller => true }
  end

  # Returns PaperTrail's configuration object.
  def self.config
    @@config ||= PaperTrail::Config.instance
    yield @@config if block_given?
    @@config
  end

  class << self
    alias_method :configure, :config
  end
end

# Ensure `ProtectedAttributes` gem gets required if it is available before the
# `Version` class gets loaded in.
unless PaperTrail.active_record_protected_attributes?
  PaperTrail.send(:remove_instance_variable, :@active_record_protected_attributes)
  begin
    require 'protected_attributes'
  rescue LoadError
    # In case `ProtectedAttributes` gem is not available.
  end
end

ActiveSupport.on_load(:active_record) do
  include PaperTrail::Model
end

# Require frameworks
require 'paper_trail/frameworks/sinatra'
if defined?(::Rails) && ActiveRecord::VERSION::STRING >= '3.2'
  require 'paper_trail/frameworks/rails'
else
  require 'paper_trail/frameworks/active_record'
end
