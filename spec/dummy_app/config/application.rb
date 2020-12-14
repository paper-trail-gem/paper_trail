# frozen_string_literal: true

require File.expand_path("boot", __dir__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(:default, Rails.env)
require "paper_trail"

module Dummy
  class Application < Rails::Application
    config.load_defaults(::Rails.gem_version.segments.take(2).join("."))

    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.active_support.escape_html_entities_in_json = true
    config.active_support.test_order = :sorted
    config.secret_key_base = "A fox regularly kicked the screaming pile of biscuits."

    # In rails >= 6.0, "`.represent_boolean_as_integer=` is now always true,
    # so setting this is deprecated and will be removed in Rails 6.1."
    if ::ENV["DB"] == "sqlite" &&
        ::Gem::Requirement.new("~> 5.2").satisfied_by?(::Rails.gem_version)
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end
  end
end
