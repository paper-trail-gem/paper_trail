require 'singleton'
require 'paper_trail/serializers/yaml'

module PaperTrail
  class Config
    include Singleton
    attr_accessor :timestamp_field, :serializer, :version_limit
    attr_writer :enabled_in_all_threads, :track_associations

    def initialize
      @timestamp_field = :created_at
      @serializer      = PaperTrail::Serializers::YAML
      @enabled_in_all_threads = true
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

    # @api public
    # @deprecated in 5.0
    def enabled
      ::ActiveSupport::Deprecation.warn "Use enabled? (with question mark)", caller(1)
      enabled?
    end

    # @api public
    def enabled?
      !!(@enabled_in_all_threads && enabled_in_current_thread?)
    end

    # @api public
    # @deprecated in 5.0
    def enabled= enable
      ::ActiveSupport::Deprecation.warn "Use enabled_in_current_thread=", caller(1)
      self.enabled_in_current_thread = enable
    end

    # Enable or disable PaperTrail in the current thread. Ignored if
    # PaperTrail is disabled globally. See also `enabled_in_all_threads=`,
    # which is not thread-safe.
    # @api public
    def enabled_in_current_thread= enable
      PaperTrail.paper_trail_store[:paper_trail_enabled] = enable
    end

    private

    # Irrespective of whether PaperTrail is enabled globally, returns a boolean
    # indicating if PaperTrail is enabled for the current thread.
    # @api private
    def enabled_in_current_thread?
      value = PaperTrail.paper_trail_store.fetch(:paper_trail_enabled, true)
      value.nil? ? true : value
    end
  end
end
