# frozen_string_literal: true

# AR does not require all of AS, but PT does. PT uses core_ext like
# `String#squish`, so we require `active_support/all`. Instead of eagerly
# loading all of AS here, we could put specific `require`s in only the various
# PT files that need them, but this seems easier to troubleshoot, though it may
# add a few milliseconds to rails boot time. If that becomes a pain point, we
# can revisit this decision.
require "active_support/all"

# We used to `require "active_record"` here, but that was [replaced with a
# Railtie](https://github.com/paper-trail-gem/paper_trail/pull/1281) in PT 12.
# As a result, we cannot reference `ActiveRecord` in this file (ie. until our
# Railtie has loaded). If we did, it would cause [problems with non-Rails
# projects](https://github.com/paper-trail-gem/paper_trail/pull/1401).

require "paper_trail/errors"
require "paper_trail/cleaner"
require "paper_trail/compatibility"
require "paper_trail/config"
require "paper_trail/record_history"
require "paper_trail/request"
require "paper_trail/version_number"
require "paper_trail/serializers/json"

# An ActiveRecord extension that tracks changes to your models, for auditing or
# versioning.
module PaperTrail
  E_TIMESTAMP_FIELD_CONFIG = <<-EOS.squish.freeze
    PaperTrail.timestamp_field= has been removed, without replacement. It is no
    longer configurable. The timestamp column in the versions table must now be
    named created_at.
  EOS

  extend PaperTrail::Cleaner

  class << self
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

    # Returns PaperTrail's `::Gem::Version`, convenient for comparisons. This is
    # recommended over `::PaperTrail::VERSION::STRING`.
    #
    # Added in 7.0.0
    #
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
    # Given a block, temporarily sets the given `options`, executes the block,
    # and returns the value of the block.
    #
    # Without a block, this currently just returns `PaperTrail::Request`.
    # However, please do not use `PaperTrail::Request` directly. Currently,
    # `Request` is a `Module`, but in the future it is quite possible we may
    # make it a `Class`. If we make such a choice, we will not provide any
    # warning and will not treat it as a breaking change. You've been warned :)
    #
    # @api public
    def request(options = nil, &block)
      if options.nil? && !block
        Request
      else
        Request.with(options, &block)
      end
    end

    # Set the field which records when a version was created.
    # @api public
    def timestamp_field=(_field_name)
      raise Error, E_TIMESTAMP_FIELD_CONFIG
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

    # Returns PaperTrail's global configuration object, a singleton. These
    # settings affect all threads.
    # @api public
    def config
      @config ||= PaperTrail::Config.instance
      yield @config if block_given?
      @config
    end
    alias configure config

    # @api public
    def version
      VERSION::STRING
    end

    def active_record_gte_7_0?
      @active_record_gte_7_0 ||= ::ActiveRecord.gem_version >= ::Gem::Version.new("7.0.0")
    end

    def deprecator
      @deprecator ||= ActiveSupport::Deprecation.new("16.0", "PaperTrail")
    end
  end
end

# PT is built on ActiveRecord, but does not require Rails. If Rails is defined,
# our Railtie makes sure not to load the AR-dependent parts of PT until AR is
# ready. A typical Rails `application.rb` has:
#
# ```
# require 'rails/all' # Defines `Rails`
# Bundler.require(*Rails.groups) # require 'paper_trail' (this file)
# ```
#
# Non-rails applications should take similar care to load AR before PT.
if defined?(Rails)
  require "paper_trail/frameworks/rails"
else
  require "paper_trail/frameworks/active_record"
end
