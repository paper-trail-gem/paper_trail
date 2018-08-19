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
      Please add `paper_trail-association_tracking` to your Gemfile.
    EOS

    attr_accessor(
      :association_reify_error_behaviour,
      :classes_warned_about_sti_item_types,
      :i_have_updated_my_existing_item_types,
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
    def track_associations=(_)
      raise E_PT_AT_REMOVED
    end

    def track_associations?
      raise E_PT_AT_REMOVED
    end
  end
end
