# frozen_string_literal: true

require File.expand_path("boot", __dir__)

# Here a conventional app would load the Rails components it needs, but we have
# already loaded these in our spec_helper.
# require "active_record/railtie"
# require "action_controller/railtie"

# Here a conventional app would require gems, but again, we have already loaded
# these in our spec_helper.
# Bundler.require(:default, Rails.env)

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

    # `use_yaml_unsafe_load` was added in 7.0.3.1, will be removed in 7.1.0?
    if ::ActiveRecord.respond_to?(:use_yaml_unsafe_load)
      ::ActiveRecord.use_yaml_unsafe_load = false
      ::ActiveRecord.yaml_column_permitted_classes = [
        ::ActiveRecord::Type::Time::Value,
        ::ActiveSupport::TimeWithZone,
        ::ActiveSupport::TimeZone,
        ::BigDecimal,
        ::Date,
        ::Symbol,
        ::Time
      ]
    end
  end
end
