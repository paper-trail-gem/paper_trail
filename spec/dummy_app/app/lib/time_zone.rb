# frozen_string_literal: true

if ActiveRecord.gem_version > Gem::Version.new("5.2")
  module ActiveModel
    module Type
      class TimeZone < Value
        def type
          :time_zone
        end

        def serialize(value)
          super(cast(value).try(:name))
        end

        def deserialize(value)
          ::Time.find_zone(value)
        end

        def cast(value)
          cast_value(value)
        end

        private

        def cast_value(value)
          if value.is_a? ActiveSupport::TimeZone
            value
          else
            ::Time.find_zone(value) # nil if can't find time zone
          end
        end
      end
    end
  end
end
