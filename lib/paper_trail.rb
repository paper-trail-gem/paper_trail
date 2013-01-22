require 'paper_trail/config'
require 'paper_trail/controller'
require 'paper_trail/has_paper_trail'
require 'paper_trail/version'

require 'paper_trail/serializers/yaml'
require 'paper_trail/serializers/json'

# PaperTrail's module methods can be called in both models and controllers.
module PaperTrail

  # Switches PaperTrail on or off.
  def self.enabled=(value)
    PaperTrail.config.enabled = value
  end

  # Returns `true` if PaperTrail is on, `false` otherwise.
  # PaperTrail is enabled by default.
  def self.enabled?
    !!PaperTrail.config.enabled
  end

  # Returns `true` if PaperTrail is enabled for the request, `false` otherwise.
  #
  # See `PaperTrail::Controller#paper_trail_enabled_for_controller`.
  def self.enabled_for_controller?
    !!paper_trail_store[:request_enabled_for_controller]
  end

  # Sets whether PaperTrail is enabled or disabled for the current request.
  def self.enabled_for_controller=(value)
    paper_trail_store[:request_enabled_for_controller] = value
  end

  # Set the field which records when a version was created.
  def self.timestamp_field=(field_name)
    PaperTrail.config.timestamp_field = field_name
  end

  # Returns the field which records when a version was created.
  def self.timestamp_field
    PaperTrail.config.timestamp_field
  end

  # Returns who is reponsible for any changes that occur.
  def self.whodunnit
    paper_trail_store[:whodunnit]
  end

  # Sets who is responsible for any changes that occur.
  # You would normally use this in a migration or on the console,
  # when working with models directly.  In a controller it is set
  # automatically to the `current_user`.
  def self.whodunnit=(value)
    paper_trail_store[:whodunnit] = value
  end

  # Returns any information from the controller that you want
  # PaperTrail to store.
  #
  # See `PaperTrail::Controller#info_for_paper_trail`.
  def self.controller_info
    paper_trail_store[:controller_info]
  end

  # Sets any information from the controller that you want PaperTrail
  # to store.  By default this is set automatically by a before filter.
  def self.controller_info=(value)
    paper_trail_store[:controller_info] = value
  end

  # Getter and Setter for PaperTrail Serializer
  def self.serializer=(value)
    PaperTrail.config.serializer = value
  end

  def self.serializer
    PaperTrail.config.serializer
  end

  private

  # Thread-safe hash to hold PaperTrail's data.
  # Initializing with needed default values.
  def self.paper_trail_store
    Thread.current[:paper_trail] ||= {
      :request_enabled_for_controller => true
    }
  end

  # Returns PaperTrail's configuration object.
  def self.config
    @@config ||= PaperTrail::Config.instance
  end

  def self.configure
    yield config
  end

end


ActiveSupport.on_load(:active_record) do
  include PaperTrail::Model
end

ActiveSupport.on_load(:action_controller) do
  include PaperTrail::Controller
end
