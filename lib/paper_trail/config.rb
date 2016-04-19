require "singleton"
require "active_support/core_ext"
require "paper_trail/serializers/yaml"

module PaperTrail
  # Global configuration affecting all threads. Some thread-specific
  # configuration can be found in `paper_trail.rb`, others in `controller.rb`.
  class Config
    include Singleton

    E_IMPLICIT_SERIALIZER = <<-EOS.strip_heredoc.freeze
      You have not specified a serializer for PaperTrail. By default, database
      columns like versions.object will be serialized with YAML, but in the
      future this may change to JSON. To continue using YAML, please call

          PaperTrail.serializer = PaperTrail::Serializers::YAML

      If you're using Rails, an initializer would be a good place for this.
    EOS

    attr_accessor :timestamp_field, :version_limit
    attr_writer :track_associations

    def initialize
      # Variables which affect all threads, whose access is synchronized.
      @mutex = Mutex.new
      @enabled = true

      # Variables which affect all threads, whose access is *not* synchronized.
      @timestamp_field = :created_at
      @serializer = PaperTrail::Serializers::YAML
      @user_warned_about_serializer = false
      @user_configured_serializer = false
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

    # Users are warned if they have not explicitly chosen a serializer,
    # because the default may change in the future.
    def serializer
      unless @user_configured_serializer || @user_warned_about_serializer
        ActiveSupport::Deprecation.warn(E_IMPLICIT_SERIALIZER)
        @user_warned_about_serializer = true
      end
      @serializer
    end

    # Users will be warned if they have not explicitly chosen a serializer,
    # so we keep track of whether this method has been called.
    def serializer=(value)
      @user_configured_serializer = true
      @serializer = value
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
