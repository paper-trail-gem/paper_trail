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
    YAML_COLUMN_PERMITTED_CLASSES = [
      ::ActiveRecord::Type::Time::Value,
      ::ActiveSupport::TimeWithZone,
      ::ActiveSupport::TimeZone,
      ::BigDecimal,
      ::Date,
      ::Symbol,
      ::Time
    ].freeze

    config.load_defaults(::ActiveRecord.gem_version.segments.take(2).join("."))

    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.active_support.escape_html_entities_in_json = true
    config.active_support.test_order = :sorted
    config.secret_key_base = "A fox regularly kicked the screaming pile of biscuits."

    # `use_yaml_unsafe_load` was added in 5.2.8.1, 6.0.5.1, 6.1.6.1, and 7.0.3.1
    if ::ActiveRecord.gem_version >= Gem::Version.new("7.0.3.1")
      ::ActiveRecord.use_yaml_unsafe_load = false
      ::ActiveRecord.yaml_column_permitted_classes = YAML_COLUMN_PERMITTED_CLASSES
    elsif ::ActiveRecord::Base.respond_to?(:use_yaml_unsafe_load)
      ::ActiveRecord::Base.use_yaml_unsafe_load = false
      ::ActiveRecord::Base.yaml_column_permitted_classes = YAML_COLUMN_PERMITTED_CLASSES
    end
  end
end
