# frozen_string_literal: true

require "singleton"
require "paper_trail/serializers/yaml"

module PaperTrail
  # Global configuration affecting all threads. Some thread-specific
  # configuration can be found in `paper_trail.rb`, others in `controller.rb`.
  class Config
    include Singleton

    E_PT_AT_REMOVED = <<-EOS.squish
      Association Tracking for PaperTrail has been extracted to a seperate gem.
      To use it, please add `paper_trail-association_tracking` to your Gemfile.
      If you don't use it (most people don't, that's the default) and you set
      `track_associations = false` somewhere (probably a rails initializer) you
      can remove that line now.
    EOS

    attr_accessor(
      :association_reify_error_behaviour,
      :object_changes_adapter,
      :serializer,
      :version_limit
    )

    def initialize
      # Variables which affect all threads, whose access is synchronized.
      @mutex = Mutex.new
      @enabled = true

      # Variables which affect all threads, whose access is *not* synchronized.
      @serializer = PaperTrail::Serializers::YAML
    end

    # Indicates whether PaperTrail is on or off. Default: true.
    def enabled
      @mutex.synchronize { !!@enabled }
    end

    def enabled=(enable)
      @mutex.synchronize { @enabled = enable }
    end

    # In PT 10, the paper_trail-association_tracking gem was changed from a
    # runtime dependency to a development dependency. We raise an error about
    # this for the people who don't read changelogs.
    #
    # We raise a generic RuntimeError instead of a specific PT error class
    # because there is no known use case where someone would want to rescue
    # this. If we think of such a use case in the future we can revisit this
    # decision.
    #
    # @override If PT-AT is `require`d, it will replace this method with its
    # own implementation.
    def track_associations=(value)
      if value
        raise E_PT_AT_REMOVED
      else
        ::Kernel.warn(E_PT_AT_REMOVED)
      end
    end

    # @override If PT-AT is `require`d, it will replace this method with its
    # own implementation.
    def track_associations?
      raise E_PT_AT_REMOVED
    end
  end
end
