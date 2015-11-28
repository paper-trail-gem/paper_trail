require 'singleton'
require 'paper_trail/serializers/yaml'

module PaperTrail
  class Config
    include Singleton
    attr_accessor :timestamp_field, :serializer, :version_limit
    attr_reader :serialized_attributes
    attr_writer :track_associations

    def initialize
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
        ::ActiveSupport::Deprecation.warn(
          "ActiveRecord 5.0 deprecated `serialized_attributes` "  +
          "without replacement, so this PaperTrail config setting does " +
          "nothing with this version, and is always turned off"
        )
      end
      @serialized_attributes = value
    end

    def track_associations
      @track_associations.nil? ?
        PaperTrail::VersionAssociation.table_exists? :
        @track_associations
    end
    alias_method :track_associations?, :track_associations

    # Indicates whether PaperTrail is on or off.
    def enabled
      PaperTrail.paper_trail_store[:paper_trail_enabled].nil? ||
        PaperTrail.paper_trail_store[:paper_trail_enabled]
    end

    def enabled= enable
      PaperTrail.paper_trail_store[:paper_trail_enabled] = enable
    end
  end
end
