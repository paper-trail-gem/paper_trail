# frozen_string_literal: true

require "singleton"
require "paper_trail/serializers/yaml"

module PaperTrail
  # Global configuration affecting all threads. Some thread-specific
  # configuration can be found in `paper_trail.rb`, others in `controller.rb`.
  class Config
    include Singleton
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

    def track_associations=(_)
      raise AssociationTrackingRemovedError
    end

    def track_associations?
      raise AssociationTrackingRemovedError
    end

    # Error for PT v10.x for when association tracking is attempted to be
    # used without the paper_trail-association_tracking gem present
    class AssociationTrackingRemovedError < RuntimeError
      MESSAGE_FMT = "Association Tracking for PaperTrail has been extracted "\
                    "to a seperate gem. Please add "\
                    "`paper_trail-association_tracking` to your Gemfile."

      def message
        format(MESSAGE_FMT)
      end
    end
  end
end
