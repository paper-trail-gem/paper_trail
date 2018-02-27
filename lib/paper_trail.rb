# frozen_string_literal: true

# AR does not require all of AS, but PT does. PT uses core_ext like
# `String#squish`, so we require `active_support/all`. Instead of eagerly
# loading all of AS here, we could put specific `require`s in only the various
# PT files that need them, but this seems easier to troubleshoot, though it may
# add a few milliseconds to rails boot time. If that becomes a pain point, we
# can revisit this decision.
require "active_support/all"

# AR is required for, eg. has_paper_trail.rb, so we could put this `require` in
# all of those files, but it seems easier to troubleshoot if we just make sure
# AR is loaded here before loading *any* of PT. See discussion of
# performance/simplicity tradeoff for activesupport above.
require "active_record"

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
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.clear_transaction_id is deprecated, " \
        "use PaperTrail.request.clear_transaction_id",
        caller(1)
      )
      request.clear_transaction_id
    end

    # Switches PaperTrail on or off, for all threads.
    # @api public
    def enabled=(value)
      PaperTrail.config.enabled = value
    end

    # Returns `true` if PaperTrail is on, `false` otherwise. This is the
    # on/off switch that affects all threads. Enabled by default.
    # @api public
    def enabled?
      !!PaperTrail.config.enabled
    end

    # @deprecated
    def enabled_for_controller=(value)
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.enabled_for_controller= is deprecated, " \
        "use PaperTrail.request.enabled_for_controller=",
        caller(1)
      )
      request.enabled_for_controller = value
    end

    # @deprecated
    def enabled_for_controller?
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.enabled_for_controller? is deprecated, " \
        "use PaperTrail.request.enabled_for_controller?",
        caller(1)
      )
      request.enabled_for_controller?
    end

    # @deprecated
    def enabled_for_model(model, value)
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.enabled_for_model is deprecated, " \
        "use PaperTrail.request.enabled_for_model",
        caller(1)
      )
      request.enabled_for_model(model, value)
    end

    # @deprecated
    def enabled_for_model?(model)
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.enabled_for_model? is deprecated, " \
        "use PaperTrail.request.enabled_for_model?",
        caller(1)
      )
      request.enabled_for_model?(model)
    end

    # Returns PaperTrail's `::Gem::Version`, convenient for comparisons. This is
    # recommended over `::PaperTrail::VERSION::STRING`.
    # @api public
    def gem_version
      ::Gem::Version.new(VERSION::STRING)
    end

    # Set variables for the current request, eg. whodunnit.
    #
    # All request-level variables are now managed here, as of PT 9. Having the
    # word "request" right there in your application code will remind you that
    # these variables only affect the current request, not all threads.
    #
    # Given a block, temporarily sets the given `options` and execute the block.
    #
    # Without a block, this currently just returns `PaperTrail::Request`.
    # However, please do not use `PaperTrail::Request` directly. Currently,
    # `Request` is a `Module`, but in the future it is quite possible we may
    # make it a `Class`. If we make such a choice, we will not provide any
    # warning and will not treat it as a breaking change. You've been warned :)
    #
    # @api public
    def request(options = nil, &block)
      if options.nil? && !block_given?
        Request
      else
        Request.with(options, &block)
        nil
      end
    end

    # Set the field which records when a version was created.
    # @api public
    def timestamp_field=(_field_name)
      raise(E_TIMESTAMP_FIELD_CONFIG)
    end

    # @deprecated
    def whodunnit=(value)
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.whodunnit= is deprecated, use PaperTrail.request.whodunnit=",
        caller(1)
      )
      request.whodunnit = value
    end

    # @deprecated
    def whodunnit(value = nil, &block)
      if value.nil?
        ::ActiveSupport::Deprecation.warn(
          "PaperTrail.whodunnit is deprecated, use PaperTrail.request.whodunnit",
          caller(1)
        )
        request.whodunnit
      elsif block_given?
        ::ActiveSupport::Deprecation.warn(
          "Passing a block to PaperTrail.whodunnit is deprecated, " \
          'use PaperTrail.request(whodunnit: "John") do .. end',
          caller(1)
        )
        request(whodunnit: value, &block)
      else
        raise ArgumentError, "Invalid arguments"
      end
    end

    # @deprecated
    def controller_info=(value)
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.controller_info= is deprecated, use PaperTrail.request.controller_info=",
        caller(1)
      )
      request.controller_info = value
    end

    # @deprecated
    def controller_info
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.controller_info is deprecated, use PaperTrail.request.controller_info",
        caller(1)
      )
      request.controller_info
    end

    # Set the PaperTrail serializer. This setting affects all threads.
    # @api public
    def serializer=(value)
      PaperTrail.config.serializer = value
    end

    # Get the PaperTrail serializer used by all threads.
    # @api public
    def serializer
      PaperTrail.config.serializer
    end

    # @api public
    def transaction?
      ::ActiveRecord::Base.connection.open_transactions.positive?
    end

    # @deprecated
    def transaction_id
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.transaction_id is deprecated without replacement.",
        caller(1)
      )
      request.transaction_id
    end

    # @deprecated
    def transaction_id=(id)
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.transaction_id= is deprecated without replacement.",
        caller(1)
      )
      request.transaction_id = id
    end

    # Returns PaperTrail's global configuration object, a singleton. These
    # settings affect all threads.
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
