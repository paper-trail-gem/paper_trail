# This custom serializer excludes nil values
module CustomJsonSerializer
  extend PaperTrail::Serializers::Json

  def self.load(string)
    parsed_value = super(string)
    parsed_value.is_a?(Hash) ? parsed_value.reject { |k,v| k.blank? || v.blank? } : parsed_value
  end

  def self.dump(object)
    object.is_a?(Hash) ? super(object.reject { |k,v| v.nil? }) : super
  end
end