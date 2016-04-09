require "singleton"
require "paper_trail/serializers/yaml"

module PaperTrail
  # Global configuration affecting all threads. Some thread-specific
  # configuration can be found in `paper_trail.rb`, others in `controller.rb`.
  class Config
    include Singleton
    attr_accessor :timestamp_field, :serializer, :version_limit
    attr_writer :track_associations

    def initialize
      # Variables which affect all threads, whose access is synchronized.
      @mutex = Mutex.new
      @enabled = true

      # Variables which affect all threads, whose access is *not* synchronized.
      @timestamp_field = :created_at
      @serializer = PaperTrail::Serializers::YAML
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

    def track_associations?
      if @track_associations.nil?
        PaperTrail::VersionAssociation.table_exists?
      else
        @track_associations
      end
    end

    # Indicates whether PaperTrail is on or off. Default: true.
    def enabled
      @mutex.synchronize { !!@enabled }
    end

    def enabled=(enable)
      @mutex.synchronize { @enabled = enable }
    end
  end
end
