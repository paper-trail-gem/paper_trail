require "singleton"
require "paper_trail/serializers/yaml"

module PaperTrail
  # Manages the request_store that affects the current request
  class Request
    PUBLIC_KEY_PATTERNS = [
      "request_enabled_for_controller"

    ].freeze
    def initialize; end

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

    # Sets who is responsible for any changes that occur. You would normally use
    # this in a migration or on the console, when working with models directly.
    # In a controller it is set automatically to the `current_user`.
    # @api public
    def whodunnit=(value)
      paper_trail_store[:whodunnit] = value
    end

    # If nothing passed, returns who is reponsible for any changes that occur.
    #
    #   PaperTrail.request.whodunnit = "someone"
    #   PaperTrail.request.whodunnit # => "someone"
    #
    # If value and block passed, set this value as whodunnit for the duration of the block
    #
    #   PaperTrail.request.whodunnit("me") do
    #     puts PaperTrail.request.whodunnit # => "me"
    #   end
    #
    # @api public
    def whodunnit(value = nil)
      config_handler(:whodunnit, value) do
        yield
      end
    end

    # Sets any information from the controller that you want PaperTrail to
    # store.  By default this is set automatically by a before filter.
    # @api public
    def controller_info=(value)
      paper_trail_store[:controller_info] = value
    end

    # If nothing passed, returns the paper trail info from the controller that you want PaperTrail
    # to store
    # See `PaperTrail::Rails::Controller#info_for_paper_trail`.
    #
    #   PaperTrail.request.controller_info = { ip: request_user_ip }
    #   PaperTrail.request.controller_info # => { ip: '127.0.0.1' }
    #
    # If value and block passed, set this value as the controller info for the duration of the block
    #
    #   PaperTrail.request.controller_info({ ip: '127.0.0.1' }) do
    #     puts PaperTrail.request.controller_info # => { ip: '127.0.0.1' }
    #   end
    #
    # @api public
    def controller_info(value = nil)
      config_handler(:controller_info, value) do
        yield
      end
    end

    # @api public
    def transaction_id
      paper_trail_store[:transaction_id]
    end

    # @api public
    def transaction_id=(id)
      paper_trail_store[:transaction_id] = id
    end

    # TODO: Make this private and have the request method take in a block
    # Allows for paper trail settings to be set with a block
    #
    # config = { whodunnit: 'system', controller_info: { ip: '127.0.0.1' } }
    # PaperTrail.with_paper_trail_config(config) do
    #   puts PaperTrail.request.controller_info # => { ip: '127.0.0.1' }
    #   puts PaperTrail.request.whodunnit # => 'system'
    # end
    #
    # @api public
    def with_paper_trail_config(config)
      raise ArgumentError, "no block given" unless block_given?

      previous_config = {}
      config.each do |config_key, config_value|
        if config_value
          previous_config[config_key] = paper_trail_store[config_key]
          paper_trail_store[config_key] = config_value
        elsif paper_trail_store[config_key].respond_to?(:call)
          paper_trail_store[config_key].call
        end
      end

      begin
        yield
      ensure
        previous_config.each do |config_key, config_value|
          paper_trail_store[config_key] = config_value
        end
      end
    end

    # Standard getter/setter that has three behaviors:
    # If a value is passed in, it behaves as a setter for
    # the duration of a yielded block.
    # If no value is passed in but the config is is a proc,
    # then it will call that proc
    # If no value is passed in and the current value is not a proc,
    # it will simply return that value
    # @api private
    def config_handler(config, value = nil)
      if value
        with_paper_trail_config(Hash[config, value]) { yield }
      elsif paper_trail_store[config].respond_to?(:call)
        paper_trail_store[config].call
      else
        paper_trail_store[config]
      end
    end

    # Thread-safe hash to hold PaperTrail's data. Initializing with needed
    # default values.
    # @api private
    def paper_trail_store
      RequestStore.store[:paper_trail] ||= { request_enabled_for_controller: true }
    end
  end
end
