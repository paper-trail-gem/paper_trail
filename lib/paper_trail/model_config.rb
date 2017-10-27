require "active_support/core_ext"

module PaperTrail
  # Configures an ActiveRecord model, mostly at application boot time, but also
  # sometimes mid-request, with methods like enable/disable.
  class ModelConfig
    E_CANNOT_RECORD_AFTER_DESTROY = <<-STR.strip_heredoc.freeze
      paper_trail.on_destroy(:after) is incompatible with ActiveRecord's
      belongs_to_required_by_default and has no effect. Please use :before
      or disable belongs_to_required_by_default.
    STR

    def initialize(model_class)
      @model_class = model_class
    end

    # Switches PaperTrail off for this class.
    def disable
      ::PaperTrail.enabled_for_model(@model_class, false)
    end

    # Switches PaperTrail on for this class.
    def enable
      ::PaperTrail.enabled_for_model(@model_class, true)
    end

    def enabled?
      return false unless @model_class.include?(::PaperTrail::Model::InstanceMethods)
      ::PaperTrail.enabled_for_model?(@model_class)
    end

    # Adds a callback that records a version after a "create" event.
    def on_create
      @model_class.after_create { |r|
        r.paper_trail.record_create if r.paper_trail.save_version?
      }
      return if @model_class.paper_trail_options[:on].include?(:create)
      @model_class.paper_trail_options[:on] << :create
    end

    # Adds a callback that records a version before or after a "destroy" event.
    def on_destroy(recording_order = "before")
      unless %w[after before].include?(recording_order.to_s)
        raise ArgumentError, 'recording order can only be "after" or "before"'
      end

      if recording_order.to_s == "after" && cannot_record_after_destroy?
        ::ActiveSupport::Deprecation.warn(E_CANNOT_RECORD_AFTER_DESTROY)
      end

      @model_class.send(
        "#{recording_order}_destroy",
        ->(r) { r.paper_trail.record_destroy if r.paper_trail.save_version? }
      )

      return if @model_class.paper_trail_options[:on].include?(:destroy)
      @model_class.paper_trail_options[:on] << :destroy
    end

    # Adds a callback that records a version after an "update" event.
    def on_update
      @model_class.before_save { |r|
        r.paper_trail.reset_timestamp_attrs_for_update_if_needed
      }
      @model_class.after_update { |r|
        r.paper_trail.record_update(nil) if r.paper_trail.save_version?
      }
      @model_class.after_update { |r|
        r.paper_trail.clear_version_instance
      }
      return if @model_class.paper_trail_options[:on].include?(:update)
      @model_class.paper_trail_options[:on] << :update
    end

    # Set up `@model_class` for PaperTrail. Installs callbacks, associations,
    # "class attributes", instance methods, and more.
    # @api private
    def setup(options = {})
      options[:on] ||= %i[create update destroy]
      options[:on] = Array(options[:on]) # Support single symbol
      @model_class.send :include, ::PaperTrail::Model::InstanceMethods
      setup_options(options)
      setup_associations(options)
      setup_transaction_callbacks
      setup_callbacks_from_options options[:on]
      setup_callbacks_for_habtm options[:join_tables]
    end

    def version_class
      @_version_class ||= @model_class.version_class_name.constantize
    end

    private

    def active_record_gem_version
      Gem::Version.new(ActiveRecord::VERSION::STRING)
    end

    def cannot_record_after_destroy?
      Gem::Version.new(ActiveRecord::VERSION::STRING).release >= Gem::Version.new("5") &&
        ::ActiveRecord::Base.belongs_to_required_by_default
    end

    def habtm_assocs_not_skipped
      @model_class.reflect_on_all_associations(:has_and_belongs_to_many).
        reject { |a| @model_class.paper_trail_options[:skip].include?(a.name.to_s) }
    end

    def setup_associations(options)
      @model_class.class_attribute :version_association_name
      @model_class.version_association_name = options[:version] || :version

      # The version this instance was reified from.
      @model_class.send :attr_accessor, @model_class.version_association_name

      @model_class.class_attribute :version_class_name
      @model_class.version_class_name = options[:class_name] || "PaperTrail::Version"

      @model_class.class_attribute :versions_association_name
      @model_class.versions_association_name = options[:versions] || :versions

      @model_class.send :attr_accessor, :paper_trail_event

      @model_class.has_many(
        @model_class.versions_association_name,
        -> { order(model.timestamp_sort_order) },
        class_name: @model_class.version_class_name,
        as: :item
      )
    end

    # Adds callbacks to record changes to habtm associations such that on save
    # the previous version of the association (if changed) can be reconstructed.
    def setup_callbacks_for_habtm(join_tables)
      @model_class.send :attr_accessor, :paper_trail_habtm
      @model_class.class_attribute :paper_trail_save_join_tables
      @model_class.paper_trail_save_join_tables = Array.wrap(join_tables)
      habtm_assocs_not_skipped.each(&method(:setup_habtm_change_callbacks))
    end

    def setup_callbacks_from_options(options_on = [])
      options_on.each do |event|
        public_send("on_#{event}")
      end
    end

    def setup_habtm_change_callbacks(assoc)
      assoc_name = assoc.name
      %w[add remove].each do |verb|
        @model_class.send(:"before_#{verb}_for_#{assoc_name}").send(
          :<<,
          lambda do |*args|
            update_habtm_state(assoc_name, :"before_#{verb}", args[-2], args.last)
          end
        )
      end
    end

    def setup_options(options)
      @model_class.class_attribute :paper_trail_options
      @model_class.paper_trail_options = options.dup

      %i[ignore skip only].each do |k|
        @model_class.paper_trail_options[k] = [@model_class.paper_trail_options[k]].
          flatten.
          compact.
          map { |attr| attr.is_a?(Hash) ? attr.stringify_keys : attr.to_s }
      end

      @model_class.paper_trail_options[:meta] ||= {}
      if @model_class.paper_trail_options[:save_changes].nil?
        @model_class.paper_trail_options[:save_changes] = true
      end
    end

    # Reset the transaction id when the transaction is closed.
    def setup_transaction_callbacks
      @model_class.after_commit { PaperTrail.clear_transaction_id }
      @model_class.after_rollback { PaperTrail.clear_transaction_id }
      @model_class.after_rollback { paper_trail.clear_rolled_back_versions }
    end

    def update_habtm_state(name, callback, model, assoc)
      model.paper_trail_habtm ||= {}
      model.paper_trail_habtm[name] ||= { removed: [], added: [] }
      state = model.paper_trail_habtm[name]
      assoc_id = assoc.id
      case callback
      when :before_add
        state[:added] |= [assoc_id]
        state[:removed] -= [assoc_id]
      when :before_remove
        state[:removed] |= [assoc_id]
        state[:added] -= [assoc_id]
      else
        raise "Invalid callback: #{callback}"
      end
    end
  end
end
