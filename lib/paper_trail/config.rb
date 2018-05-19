# frozen_string_literal: true

require "singleton"
require "paper_trail/serializers/yaml"

module PaperTrail
  # Global configuration affecting all threads. Some thread-specific
  # configuration can be found in `paper_trail.rb`, others in `controller.rb`.
  class Config
    DPR_TRACK_ASSOC = <<~STR
      Association tracking is an endangered feature. For the past three or four
      years it has been an experimental feature, not recommended for production.
      It has a long list of known issues
      (https://github.com/paper-trail-gem/paper_trail#4b1-known-issues) and has no
      regular volunteers caring for it.

      If you don't use this feature, I strongly recommend disabling it.

      If you do use this feature, please head over to
      https://github.com/paper-trail-gem/paper_trail/issues/1070 and volunteer to work
      on the known issues.

      If we can't make a serious dent in the list of known issues over the next
      few years, then I'm inclined to delete it, though that would make me sad
      because I've put dozens of hours into it, and I know others have too.
    STR

    include Singleton
    attr_accessor :serializer, :version_limit, :association_reify_error_behaviour

    def initialize
      # Variables which affect all threads, whose access is synchronized.
      @mutex = Mutex.new
      @enabled = true

      # Variables which affect all threads, whose access is *not* synchronized.
      @serializer = PaperTrail::Serializers::YAML
    end

    def track_associations=(value)
      @track_associations = !!value
      if @track_associations
        ::ActiveSupport::Deprecation.warn(DPR_TRACK_ASSOC, caller(1))
      end
    end

    # As of PaperTrail 5, `track_associations?` defaults to false. Tracking
    # associations is an experimental feature so we recommend setting
    # PaperTrail.config.track_associations = false in your
    # config/initializers/paper_trail.rb
    #
    # In PT 4, we checked `PaperTrail::VersionAssociation.table_exists?`
    # here, but that proved to be problematic in situations when the database
    # connection had not been established, or when the database does not exist
    # yet (as with `rake db:create`).
    def track_associations?
      if @track_associations.nil?
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
