require 'singleton'

module PaperTrail
  class Config
    include Singleton
    attr_accessor :enabled, :timestamp_field, :serializer, :version_limit

    def initialize
      @enabled         = true # Indicates whether PaperTrail is on or off.
      @timestamp_field = :created_at
      @serializer      = PaperTrail::Serializers::Yaml
    end
  end
end
