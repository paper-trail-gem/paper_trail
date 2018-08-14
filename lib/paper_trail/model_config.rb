# frozen_string_literal: true

module PaperTrail
  # Configures an ActiveRecord model, mostly at application boot time, but also
  # sometimes mid-request, with methods like enable/disable.
  class ModelConfig
    E_CANNOT_RECORD_AFTER_DESTROY = <<-STR.strip_heredoc.freeze
      paper_trail.on_destroy(:after) is incompatible with ActiveRecord's
      belongs_to_required_by_default. Use on_destroy(:before)
      or disable belongs_to_required_by_default.
    STR
    E_HPT_ABSTRACT_CLASS = <<~STR.squish.freeze
      An application model (%s) has been configured to use PaperTrail (via
      `has_paper_trail`), but the version model it has been told to use (%s) is
      an `abstract_class`. This could happen when an advanced feature called
      Custom Version Classes (http://bit.ly/2G4ch0G) is misconfigured. When all
      version classes are custom, PaperTrail::Version is configured to be an
      `abstract_class`. This is fine, but all application models must be
      configured to use concrete (not abstract) version models.
    STR

    def initialize(model_class)
      @model_class = model_class
    end

    # Adds a callback that records a version after a "create" event.
    #
    # @api public
    def on_create
      @model_class.after_create { |r|
        r.paper_trail.record_create if r.paper_trail.save_version?
      }
      return if @model_class.paper_trail_options[:on].include?(:create)
      @model_class.paper_trail_options[:on] << :create
    end

    # Adds a callback that records a version before or after a "destroy" event.
    #
    # @api public
    def on_destroy(recording_order = "before")
      unless %w[after before].include?(recording_order.to_s)
        raise ArgumentError, 'recording order can only be "after" or "before"'
      end

      if recording_order.to_s == "after" && cannot_record_after_destroy?
        raise E_CANNOT_RECORD_AFTER_DESTROY
      end

      @model_class.send(
        "#{recording_order}_destroy",
        lambda do |r|
          return unless r.paper_trail.save_version?
          r.paper_trail.record_destroy(recording_order)
        end
      )

      return if @model_class.paper_trail_options[:on].include?(:destroy)
      @model_class.paper_trail_options[:on] << :destroy
    end

    # Adds a callback that records a version after an "update" event.
    #
    # @api public
    def on_update
      @model_class.before_save { |r|
        r.paper_trail.reset_timestamp_attrs_for_update_if_needed
      }
      @model_class.after_update { |r|
        if r.paper_trail.save_version?
          r.paper_trail.record_update(
            force: false,
            in_after_callback: true,
            is_touch: false
          )
        end
      }
      @model_class.after_update { |r|
        r.paper_trail.clear_version_instance
      }
      return if @model_class.paper_trail_options[:on].include?(:update)
      @model_class.paper_trail_options[:on] << :update
    end

    # Adds a callback that records a version after a "touch" event.
    # @api public
    def on_touch
      @model_class.after_touch { |r|
        r.paper_trail.record_update(
          force: true,
          in_after_callback: true,
          is_touch: true
        )
      }
    end

    # Set up `@model_class` for PaperTrail. Installs callbacks, associations,
    # "class attributes", instance methods, and more.
    # @api private
    def setup(options = {})
      options[:on] ||= %i[create update destroy touch]
      options[:on] = Array(options[:on]) # Support single symbol
      @model_class.send :include, ::PaperTrail::Model::InstanceMethods
      setup_options(options)
      setup_associations(options)
      @model_class.after_rollback { paper_trail.clear_rolled_back_versions }
      setup_callbacks_from_options options[:on]
    end

    def version_class
      @_version_class ||= @model_class.version_class_name.constantize
    end

    private

    def active_record_gem_version
      Gem::Version.new(ActiveRecord::VERSION::STRING)
    end

    # Raises an error if the provided class is an `abstract_class`.
    # @api private
    def assert_concrete_activerecord_class(class_name)
      if class_name.constantize.abstract_class?
        raise format(E_HPT_ABSTRACT_CLASS, @model_class, class_name)
      end
    end

    def cannot_record_after_destroy?
      Gem::Version.new(ActiveRecord::VERSION::STRING).release >= Gem::Version.new("5") &&
        ::ActiveRecord::Base.belongs_to_required_by_default
    end

    # Define the association usually called `versions`. The name is configurable
    # via `versions_association_name`.
    #
    # Single Table Inheritance (STI) is supported, with custom inheritance
    # columns. Imagine a `version` whose `item_type` is "Animal". The `animals`
    # table is an STI table (it has cats and dogs) and it has a custom
    # inheritance column, `species`. If `attrs["species"]` is "Dog", `item_type`
    # is "Dog". If `attrs["species"]` is blank, `item_type` is "Animal". See
    # `spec/models/animal_spec.rb`.
    def setup_versions_association(klass)
      klass.has_many(
        klass.versions_association_name,
        lambda do |object|
          relation = order(model.timestamp_sort_order)
          item_type = object.paper_trail.versions_association_item_type
          unless item_type.nil?
            relation = relation.unscope(where: :item_type).where(item_type: item_type)
          end
          relation
        end,
        class_name: klass.version_class_name,
        as: :item
      )
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

      assert_concrete_activerecord_class(@model_class.version_class_name)

      setup_versions_association(@model_class)
    end

    def setup_callbacks_from_options(options_on = [])
      options_on.each do |event|
        public_send("on_#{event}")
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
    end
  end
end
