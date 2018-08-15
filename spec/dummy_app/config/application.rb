# frozen_string_literal: true

require File.expand_path("boot", __dir__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(:default, Rails.env)
require "paper_trail"

# As of PT 10, PT-AT is a development dependency in paper_trail.gemspec
# https://github.com/paper-trail-gem/paper_trail/issues/1070
# https://github.com/westonganger/paper_trail-association_tracking/issues/2
# https://github.com/westonganger/paper_trail-association_tracking/issues/7
require "paper_trail-association_tracking"

module Dummy
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.active_support.escape_html_entities_in_json = true
    config.active_support.test_order = :sorted

    # Disable assets in rails 4.2. In rails 5, config does not respond to
    # assets, probably because it was moved out of railties to some other gem,
    # and we only have dev. dependencies on railties, not all of rails. When
    # we drop support for rails 4.2, we can remove this whole conditional.
    if config.respond_to?(:assets)
      config.assets.enabled = false
    end

    config.secret_key_base = "A fox regularly kicked the screaming pile of biscuits."

    # `raise_in_transactional_callbacks` was added in rails 4, then deprecated
    # in rails 5. Oh, how fickle are the gods.
    if ActiveRecord.respond_to?(:gem_version)
      v = ActiveRecord.gem_version
      if v >= Gem::Version.new("4.2") && v < Gem::Version.new("5.0.0.beta1")
        config.active_record.raise_in_transactional_callbacks = true
      end
      if v >= Gem::Version.new("5.0.0.beta1") && v < Gem::Version.new("5.1")
        config.active_record.belongs_to_required_by_default = true
        config.active_record.time_zone_aware_types = [:datetime]
      end
      if v >= Gem::Version.new("5.1")
        config.load_defaults "5.1"
        config.active_record.time_zone_aware_types = [:datetime]
      end
    end

    if ::ENV["DB"] == "sqlite" && ::Rails.gem_version >= ::Gem::Version.new("5.2")
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end
  end
end
