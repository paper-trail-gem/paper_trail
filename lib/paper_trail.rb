require "active_support"
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

    # Sets who is responsible for any changes that occur. You would normally use
    # this in a migration or on the console, when working with models directly.
    # In a controller it is set automatically to the `current_user`.
    # @api public
    def whodunnit=(value)
      paper_trail_store[:whodunnit] = value
    end

    # If nothing passed, returns who is reponsible for any changes that occur.
    #
    #   PaperTrail.whodunnit = "someone"
    #   PaperTrail.whodunnit # => "someone"
    #
    # If value and block passed, set this value as whodunnit for the duration of the block
    #
    #   PaperTrail.whodunnit("me") do
    #     puts PaperTrail.whodunnit # => "me"
    #   end
    #
    # @api public
    def whodunnit(value = nil)
      if value
        raise ArgumentError, "no block given" unless block_given?

        previous_whodunnit = paper_trail_store[:whodunnit]
        paper_trail_store[:whodunnit] = value

        begin
          yield
        ensure
          paper_trail_store[:whodunnit] = previous_whodunnit
        end
      elsif paper_trail_store[:whodunnit].respond_to?(:call)
        paper_trail_store[:whodunnit].call
      else
        paper_trail_store[:whodunnit]
      end
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

    # @api public
    def transaction?
      ::ActiveRecord::Base.connection.open_transactions.positive?
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
