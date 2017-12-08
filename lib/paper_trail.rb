require "active_support"
require "request_store"
require "paper_trail/cleaner"
require "paper_trail/config"
require "paper_trail/has_paper_trail"
require "paper_trail/record_history"
require "paper_trail/reifier"
require "paper_trail/request"
require "paper_trail/version_association_concern"
require "paper_trail/version_concern"
require "paper_trail/version_number"
require "paper_trail/serializers/json"
require "paper_trail/serializers/yaml"

# An ActiveRecord extension that tracks changes to your models, for auditing or
# versioning.
module PaperTrail
  E_RAILS_NOT_LOADED = <<-EOS.squish.freeze
    PaperTrail has been loaded too early, before rails is loaded. This can
    happen when another gem defines the ::Rails namespace, then PT is loaded,
    all before rails is loaded. You may want to reorder your Gemfile, or defer
    the loading of PT by using `require: false` and a manual require elsewhere.
  EOS
  E_TIMESTAMP_FIELD_CONFIG = <<-EOS.squish.freeze
    PaperTrail.timestamp_field= has been removed, without replacement. It is no
    longer configurable. The timestamp column in the versions table must now be
    named created_at.
  EOS

  extend PaperTrail::Cleaner

  class << self
    # @api private
    def clear_transaction_id
      request.transaction_id = nil
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

    # See PaperTrail::Request for information
    # @api public
    def enabled_for_controller=(value)
      request.enabled_for_controller = value
    end

    # See PaperTrail::Request for information
    # @api public
    def enabled_for_controller?
      request.enabled_for_controller?
    end

    # See PaperTrail::Request for information
    # @api public
    def enabled_for_model(model, value)
      request.enabled_for_model(model, value)
    end

    # See PaperTrail::Request for information
    # @api public
    def enabled_for_model?(model)
      request.enabled_for_model?(model)
    end

    # Returns the PaperTrail::Request object for setting keys for a single request
    # All methods that handle request-level configuration and are now handled
    # by PaperTrail::Request
    #
    # We will add deprecation notices for these methods in a later version
    # For now, please refer to PaperTrail::Request for method documentation
    # @api public
    def request(options = nil)
      if options
        old_request = @request
        @request ||= PaperTrail::Request.new
        yield
        @request = old_request
      else
        @request ||= PaperTrail::Request.new
      end
    end

    # Returns a `::Gem::Version`, convenient for comparisons. This is
    # recommended over `::PaperTrail::VERSION::STRING`.
    # @api public
    def gem_version
      ::Gem::Version.new(VERSION::STRING)
    end

    # Set the field which records when a version was created.
    # @api public
    def timestamp_field=(_field_name)
      raise(E_TIMESTAMP_FIELD_CONFIG)
    end

    # See PaperTrail::Request for information
    # @api public
    def whodunnit=(value)
      request.whodunnit = value
    end

    # See PaperTrail::Request for information
    # @api public
    def whodunnit(value = nil, &block)
      request.whodunnit(value, &block)
    end

    # See PaperTrail::Request for information
    # @api public
    def controller_info=(value)
      request.controller_info = value
    end

    # See PaperTrail::Request for information
    # @api public
    def controller_info(value = nil, &block)
      request.controller_info(value, &block)
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

    # @api public
    def transaction?
      ::ActiveRecord::Base.connection.open_transactions > 0
    end

    # See PaperTrail::Request for information
    # @api public
    def transaction_id
      request.transaction_id
    end

    # See PaperTrail::Request for information
    # @api public
    def transaction_id=(id)
      request.transaction_id = id
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

ActiveSupport.on_load(:active_record) do
  include PaperTrail::Model
end

# Require frameworks
if defined?(::Rails)
  # Rails module is sometimes defined by gems like rails-html-sanitizer
  # so we check for presence of Rails.application.
  if defined?(::Rails.application)
    require "paper_trail/frameworks/rails"
  else
    ::Kernel.warn(::PaperTrail::E_RAILS_NOT_LOADED)
  end
else
  require "paper_trail/frameworks/active_record"
end
