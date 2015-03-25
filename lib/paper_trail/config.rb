require 'singleton'

module PaperTrail
  class Config
    include Singleton
    attr_accessor :enabled, :timestamp_field, :serializer, :version_limit
    attr_reader :serialized_attributes
    attr_writer :track_associations

    def initialize
      @enabled         = true # Indicates whether PaperTrail is on or off.
      @timestamp_field = :created_at
      @serializer      = PaperTrail::Serializers::YAML

      # This setting only defaults to false on AR 4.2+, because that's when
      # it was deprecated. We want it to function with older versions of
      # ActiveRecord by default.
      if ::ActiveRecord::VERSION::STRING < '4.2'
        @serialized_attributes = true
      end
    end

    def serialized_attributes=(value)
      if ::ActiveRecord::VERSION::MAJOR >= 5
        warn("DEPRECATED: ActiveRecord 5.0 deprecated `serialized_attributes` "  +
          "without replacement, so this PaperTrail config setting does " +
          "nothing with this version, and is always turned off")
      end
      @serialized_attributes = value
    end

    def track_associations
      @track_associations ||= PaperTrail::VersionAssociation.table_exists?
    end
    alias_method :track_associations?, :track_associations
  end
end
