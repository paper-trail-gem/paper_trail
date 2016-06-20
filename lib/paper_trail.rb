require "request_store"
require "paper_trail/cleaner"
require "paper_trail/config"
require "paper_trail/has_paper_trail"
require "paper_trail/record_history"
require "paper_trail/reifier"
require "paper_trail/version_association_concern"
require "paper_trail/version_concern"
require "paper_trail/version_number"
require "paper_trail/serializers/json"
require "paper_trail/serializers/yaml"

# An ActiveRecord extension that tracks changes to your models, for auditing or
# versioning.
module PaperTrail
  extend PaperTrail::Cleaner

  class << self
    # @api private
    def clear_transaction_id
      self.transaction_id = nil
    end

    # Switches PaperTrail on or off.
    # @api public
    def enabled=(value)
      PaperTrail.config.enabled = value
    end

    # Returns `true` if PaperTrail is on, `false` otherwise.
    # PaperTrail is enabled by default.
    # @api public
    def enabled?
      !!PaperTrail.config.enabled
    end

    def serialized_attributes?
      ActiveSupport::Deprecation.warn(
        "PaperTrail.serialized_attributes? is deprecated without replacement " +
          "and always returns false."
      )
      false
    end

    # Sets whether PaperTrail is enabled or disabled for the current request.
    # @api public
    def enabled_for_controller=(value)
      paper_trail_store[:request_enabled_for_controller] = value
    end

    # Returns `true` if PaperTrail is enabled for the request, `false` otherwise.
    #
    # See `PaperTrail::Rails::Controller#paper_trail_enabled_for_controller`.
    # @api public
    def enabled_for_controller?
      !!paper_trail_store[:request_enabled_for_controller]
    end

    # Sets whether PaperTrail is enabled or disabled for this model in the
    # current request.
    # @api public
    def enabled_for_model(model, value)
      paper_trail_store[:"enabled_for_#{model}"] = value
    end

    # Returns `true` if PaperTrail is enabled for this model in the current
    # request, `false` otherwise.
    # @api public
    def enabled_for_model?(model)
      !!paper_trail_store.fetch(:"enabled_for_#{model}", true)
    end

    # Set the field which records when a version was created.
    # @api public
    def timestamp_field=(field_name)
      PaperTrail.config.timestamp_field = field_name
    end

    # Returns the field which records when a version was created.
    # @api public
    def timestamp_field
      PaperTrail.config.timestamp_field
    end

    # Sets who is responsible for any changes that occur. You would normally use
    # this in a migration or on the console, when working with models directly.
    # In a controller it is set automatically to the `current_user`.
    # @api public
    def whodunnit=(value)
      paper_trail_store[:whodunnit] = value
    end

    # Returns who is reponsible for any changes that occur.
    # @api public
    def whodunnit
      paper_trail_store[:whodunnit]
    end

    # Sets any information from the controller that you want PaperTrail to
    # store.  By default this is set automatically by a before filter.
    # @api public
    def controller_info=(value)
      paper_trail_store[:controller_info] = value
    end

    # Returns any information from the controller that you want
    # PaperTrail to store.
    #
    # See `PaperTrail::Rails::Controller#info_for_paper_trail`.
    # @api public
    def controller_info
      paper_trail_store[:controller_info]
    end

    # Getter and Setter for PaperTrail Serializer
    # @api public
    def serializer=(value)
      PaperTrail.config.serializer = value
    end

    # @api public
    def serializer
      PaperTrail.config.serializer
    end

    # Returns a boolean indicating whether "protected attibutes" should be
    # configured, e.g. attr_accessible, mass_assignment_sanitizer,
    # whitelist_attributes, etc.
    # @api public
    def active_record_protected_attributes?
      @active_record_protected_attributes ||= ::ActiveRecord::VERSION::MAJOR < 4 ||
        !!defined?(ProtectedAttributes)
    end

    # @api public
    def transaction?
      ::ActiveRecord::Base.connection.open_transactions > 0
    end

    # @api public
    def transaction_id
      paper_trail_store[:transaction_id]
    end

    # @api public
    def transaction_id=(id)
      paper_trail_store[:transaction_id] = id
    end

    # Thread-safe hash to hold PaperTrail's data. Initializing with needed
    # default values.
    # @api private
    def paper_trail_store
      RequestStore.store[:paper_trail] ||= { request_enabled_for_controller: true }
    end

    # Returns PaperTrail's configuration object.
    # @api private
    def config
      @config ||= PaperTrail::Config.instance
      yield @config if block_given?
      @config
    end
    alias configure config

    def version
      VERSION::STRING
    end
  end
end

# If available, ensure that the `protected_attributes` gem is loaded
# before the `Version` class.
unless PaperTrail.active_record_protected_attributes?
  PaperTrail.send(:remove_instance_variable, :@active_record_protected_attributes)
  begin
    require "protected_attributes"
  rescue LoadError # rubocop:disable Lint/HandleExceptions
    # In case `protected_attributes` gem is not available.
  end
end

ActiveSupport.on_load(:active_record) do
  include PaperTrail::Model
end

# Require frameworks
require "paper_trail/frameworks/sinatra"
if defined?(::Rails) && ActiveRecord::VERSION::STRING >= "3.2"
  require "paper_trail/frameworks/rails"
else
  require "paper_trail/frameworks/active_record"
end
