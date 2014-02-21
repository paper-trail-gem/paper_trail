require 'yaml'

module PaperTrail
  module Serializers
    module YAML
      extend self # makes all instance methods become module methods as well

      def load(string)
        with_unformatted_dates_and_times { ::YAML.load string }
      end

      def dump(object)
        with_unformatted_dates_and_times { ::YAML.dump object }
      end
      
      def with_unformatted_dates_and_times
        date_format, time_format = Date::DATE_FORMATS[:default], Time::DATE_FORMATS[:default]
        Date::DATE_FORMATS[:default] = Time::DATE_FORMATS[:default] = nil
        yield.tap { Date::DATE_FORMATS[:default], Time::DATE_FORMATS[:default] = date_format, time_format }
      end
    end
  end
end
