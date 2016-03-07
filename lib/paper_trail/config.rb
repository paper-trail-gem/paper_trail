require 'singleton'
require 'paper_trail/serializers/yaml'

module PaperTrail
  class Config
    include Singleton
    attr_accessor :timestamp_field, :serializer, :version_limit
    attr_writer :track_associations

    def initialize
      @timestamp_field = :created_at
      @whodunnit_field = :whodunnit
      @serializer      = PaperTrail::Serializers::YAML
    end

    def serialized_attributes
      ActiveSupport::Deprecation.warn(
        "PaperTrail.config.serialized_attributes is deprecated without " +
          "replacement and always returns false."
      )
      false
    end

    def serialized_attributes=(_)
      ActiveSupport::Deprecation.warn(
        "PaperTrail.config.serialized_attributes= is deprecated without " +
          "replacement and no longer has any effect."
      )
    end

    def track_associations
      @track_associations.nil? ?
        PaperTrail::VersionAssociation.table_exists? :
        @track_associations
    end
    alias_method :track_associations?, :track_associations

    # Indicates whether PaperTrail is on or off. Default: true.
    def enabled
      value = PaperTrail.paper_trail_store.fetch(:paper_trail_enabled, true)
      value.nil? ? true : value
    end

    def enabled= enable
      PaperTrail.paper_trail_store[:paper_trail_enabled] = enable
    end

    def whodunnit_field=(field_name)
      @whodunnit_field = field_name
    end

    def whodunnit_field
      @whodunnit_field
    end
  end
end
