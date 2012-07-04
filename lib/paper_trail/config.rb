module PaperTrail
  class Config
    include Singleton
    attr_accessor :enabled, :timestamp_field, :serializer

    def initialize
      # Indicates whether PaperTrail is on or off.
      @enabled         = true
      @timestamp_field = :created_at
      @serializer      = PaperTrail::Serializers::Yaml
    end
  end
end
