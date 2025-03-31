# frozen_string_literal: true

# This custom serializer excludes nil values
module CustomJsonSerializer
  extend PaperTrail::Serializers::JSON

  def self.load(string)
    parsed_value = super
    parsed_value.is_a?(Hash) ? parsed_value.reject { |k, v| k.blank? || v.blank? } : parsed_value
  end

  def self.dump(object)
    object.is_a?(Hash) ? super(object.compact) : super
  end
end
