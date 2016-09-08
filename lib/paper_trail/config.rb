require "singleton"
require "paper_trail/serializers/yaml"

module PaperTrail
  # Global configuration affecting all threads. Some thread-specific
  # configuration can be found in `paper_trail.rb`, others in `controller.rb`.
  class Config
    include Singleton
    attr_accessor :serializer, :version_limit
    attr_reader :timestamp_field # deprecated
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

    # Set the field which records when a version was created.
    # @api public
    # @deprecated
    def timestamp_field=(field_name)
      ::ActiveSupport::Deprecation.warn(
        "PaperTrail.config.timestamp_field= is deprecated without replacement." \
          "See https://github.com/airblade/paper_trail/pull/861 for discussion",
        caller(1)
      )
      @timestamp_field = field_name
    end

    # Previously, we checked `PaperTrail::VersionAssociation.table_exists?`
    # here, but that proved to be problematic in situations when the database
    # connection had not been established, or when the database does not exist
    # yet (as with `rake db:create`).
    def track_associations?
      if @track_associations.nil?
        ActiveSupport::Deprecation.warn <<-EOS.strip_heredoc.gsub(/\s+/, " ")
          PaperTrail.track_associations has not been set. As of PaperTrail 5, it
          defaults to false. Tracking associations is an experimental feature so
          we recommend setting PaperTrail.config.track_associations = false in
          your config/initializers/paper_trail.rb
        EOS
        false
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
