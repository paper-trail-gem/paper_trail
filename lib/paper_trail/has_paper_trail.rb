require "active_support/core_ext/object" # provides the `try` method
require "paper_trail/attribute_serializers/legacy_active_record_shim"
require "paper_trail/attribute_serializers/object_attribute"
require "paper_trail/attribute_serializers/object_changes_attribute"
require "paper_trail/model_config"
require "paper_trail/record_trail"

module PaperTrail
  # Extensions to `ActiveRecord::Base`.  See `frameworks/active_record.rb`.
  # It is our goal to have the smallest possible footprint here, because
  # `ActiveRecord::Base` is a very crowded namespace! That is why we introduced
  # `.paper_trail` and `#paper_trail`.
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    # :nodoc:
    module ClassMethods
      # Declare this in your model to track every create, update, and destroy.
      # Each version of the model is available in the `versions` association.
      #
      # Options:
      #
      # - :on - The events to track (optional; defaults to all of them). Set
      #   to an array of `:create`, `:update`, `:destroy` as desired.
      # - :class_name - The name of a custom Version class.  This class should
      #   inherit from `PaperTrail::Version`.
      # - :ignore - An array of attributes for which a new `Version` will not be
      #   created if only they change. It can also aceept a Hash as an
      #   argument where the key is the attribute to ignore (a `String` or
      #   `Symbol`), which will only be ignored if the value is a `Proc` which
      #   returns truthily.
      # - :if, :unless - Procs that allow to specify conditions when to save
      #   versions for an object.
      # - :only - Inverse of `ignore`. A new `Version` will be created only
      #   for these attributes if supplied it can also aceept a Hash as an
      #   argument where the key is the attribute to track (a `String` or
      #   `Symbol`), which will only be counted if the value is a `Proc` which
      #   returns truthily.
      # - :skip - Fields to ignore completely.  As with `ignore`, updates to
      #   these fields will not create a new `Version`.  In addition, these
      #   fields will not be included in the serialized versions of the object
      #   whenever a new `Version` is created.
      # - :meta - A hash of extra data to store. You must add a column to the
      #   `versions` table for each key. Values are objects or procs (which
      #   are called with `self`, i.e. the model with the paper trail).  See
      #   `PaperTrail::Controller.info_for_paper_trail` for how to store data
      #   from the controller.
      # - :versions - The name to use for the versions association.  Default
      #   is `:versions`.
      # - :version - The name to use for the method which returns the version
      #   the instance was reified from. Default is `:version`.
      # - :save_changes - Whether or not to save changes to the object_changes
      #   column if it exists. Default is true
      # - :join_tables - If the model has a has_and_belongs_to_many relation
      #   with an unpapertrailed model, passing the name of the association to
      #   the join_tables option will paper trail the join table but not save
      #   the other model, allowing reification of the association but with the
      #   other models latest state (if the other model is paper trailed, this
      #   option does nothing)
      #
      # @api public
      def has_paper_trail(options = {})
        paper_trail.setup(options)
      end

      # @api public
      def paper_trail
        ::PaperTrail::ModelConfig.new(self)
      end

      # @api private
      def paper_trail_deprecate(new_method, old_method = nil)
        old = old_method.nil? ? new_method : old_method
        msg = format("Use paper_trail.%s instead of %s", new_method, old)
        ::ActiveSupport::Deprecation.warn(msg, caller(2))
      end

      # @deprecated
      def paper_trail_on_destroy(*args)
        paper_trail_deprecate "on_destroy", "paper_trail_on_destroy"
        paper_trail.on_destroy(*args)
      end

      # @deprecated
      def paper_trail_on_update
        paper_trail_deprecate "on_update", "paper_trail_on_update"
        paper_trail.on_update
      end

      # @deprecated
      def paper_trail_on_create
        paper_trail_deprecate "on_create", "paper_trail_on_create"
        paper_trail.on_create
      end

      # @deprecated
      def paper_trail_off!
        paper_trail_deprecate "disable", "paper_trail_off!"
        paper_trail.disable
      end

      # @deprecated
      def paper_trail_on!
        paper_trail_deprecate "enable", "paper_trail_on!"
        paper_trail.enable
      end

      # @deprecated
      def paper_trail_enabled_for_model?
        paper_trail_deprecate "enabled?", "paper_trail_enabled_for_model?"
        paper_trail.enabled?
      end

      # @deprecated
      def paper_trail_version_class
        paper_trail_deprecate "version_class", "paper_trail_version_class"
        paper_trail.version_class
      end
    end

    # Wrap the following methods in a module so we can include them only in the
    # ActiveRecord models that declare `has_paper_trail`.
    module InstanceMethods
      def paper_trail
        ::PaperTrail::RecordTrail.new(self)
      end

      def dependent_versions(class_name, foreign_key)
        children = []
        versions = PaperTrail::Version.where(item_type: class_name)
        versions.where("created_at >= ?", created_at).each do |m|
          child = m.reify
          next unless child.present?
          # check the child's belongs_to to make sure it is a child
          children << child if child.try(foreign_key) == id
        end
        children
      end

      # @deprecated
      def live?
        self.class.paper_trail_deprecate "live?"
        paper_trail.live?
      end

      # @deprecated
      def paper_trail_originator
        self.class.paper_trail_deprecate "originator", "paper_trail_originator"
        paper_trail.originator
      end

      # @deprecated
      def originator
        self.class.paper_trail_deprecate "originator"
        paper_trail.originator
      end

      # @deprecated
      def clear_rolled_back_versions
        self.class.paper_trail_deprecate "clear_rolled_back_versions"
        paper_trail.clear_rolled_back_versions
      end

      # @deprecated
      def source_version
        self.class.paper_trail_deprecate "source_version"
        paper_trail.source_version
      end

      # @deprecated
      def version_at(*args)
        self.class.paper_trail_deprecate "version_at"
        paper_trail.version_at(*args)
      end

      # @deprecated
      def versions_between(start_time, end_time, _reify_options = {})
        self.class.paper_trail_deprecate "versions_between"
        paper_trail.versions_between(start_time, end_time)
      end

      # @deprecated
      def previous_version
        self.class.paper_trail_deprecate "previous_version"
        paper_trail.previous_version
      end

      # @deprecated
      def next_version
        self.class.paper_trail_deprecate "next_version"
        paper_trail.next_version
      end

      # @deprecated
      def paper_trail_enabled_for_model?
        self.class.paper_trail_deprecate "enabled_for_model?", "paper_trail_enabled_for_model?"
        paper_trail.enabled_for_model?
      end

      # @deprecated
      def without_versioning(method = nil, &block)
        self.class.paper_trail_deprecate "without_versioning"
        paper_trail.without_versioning(method, &block)
      end

      # @deprecated
      def appear_as_new_record(&block)
        self.class.paper_trail_deprecate "appear_as_new_record"
        paper_trail.appear_as_new_record(&block)
      end

      # @deprecated
      def whodunnit(value, &block)
        self.class.paper_trail_deprecate "whodunnit"
        paper_trail.whodunnit(value, &block)
      end

      # @deprecated
      def touch_with_version(name = nil)
        self.class.paper_trail_deprecate "touch_with_version"
        paper_trail.touch_with_version(name)
      end

      # `record_create` is deprecated in favor of `paper_trail.record_create`,
      # but does not yet print a deprecation warning. When the `after_create`
      # callback is registered (by ModelConfig#on_create) we still refer to this
      # method by name, e.g.
      #
      #     @model_class.after_create :record_create, if: :save_version?
      #
      # instead of using the preferred method `paper_trail.record_create`, e.g.
      #
      #     @model_class.after_create { |r| r.paper_trail.record_create if r.save_version?}
      #
      # We still register the callback by name so that, if someone calls
      # `has_paper_trail` twice, the callback will *not* be registered twice.
      # Our own test suite calls `has_paper_trail` many times for the same
      # class.
      #
      # In the future, perhaps we should require that users only set up
      # PT once per class.
      #
      # @deprecated
      def record_create
        paper_trail.record_create
      end

      # See deprecation comment for `record_create`
      # @deprecated
      def record_update(force = nil)
        paper_trail.record_update(force)
      end

      # @deprecated
      def pt_record_object_changes?
        self.class.paper_trail_deprecate "record_object_changes?", "pt_record_object_changes?"
        paper_trail.record_object_changes?
      end

      # @deprecated
      def pt_recordable_object
        self.class.paper_trail_deprecate "recordable_object", "pt_recordable_object"
        paper_trail.recordable_object
      end

      # @deprecated
      def pt_recordable_object_changes
        self.class.paper_trail_deprecate "recordable_object_changes", "pt_recordable_object_changes"
        paper_trail.recordable_object_changes
      end

      # @deprecated
      def changes_for_paper_trail
        self.class.paper_trail_deprecate "changes", "changes_for_paper_trail"
        paper_trail.changes
      end

      # See deprecation comment for `record_create`
      # @deprecated
      def clear_version_instance!
        paper_trail.clear_version_instance
      end

      # See deprecation comment for `record_create`
      # @deprecated
      def reset_timestamp_attrs_for_update_if_needed!
        paper_trail.reset_timestamp_attrs_for_update_if_needed
      end

      # See deprecation comment for `record_create`
      # @deprecated
      def record_destroy
        paper_trail.record_destroy
      end

      # @deprecated
      def save_associations(version)
        self.class.paper_trail_deprecate "save_associations"
        paper_trail.save_associations(version)
      end

      # @deprecated
      def save_associations_belongs_to(version)
        self.class.paper_trail_deprecate "save_associations_belongs_to"
        paper_trail.save_associations_belongs_to(version)
      end

      # @deprecated
      def save_associations_has_and_belongs_to_many(version)
        self.class.paper_trail_deprecate(
          "save_associations_habtm",
          "save_associations_has_and_belongs_to_many"
        )
        paper_trail.save_associations_habtm(version)
      end

      # @deprecated
      # @api private
      def reset_transaction_id
        ::ActiveSupport::Deprecation.warn(
          "reset_transaction_id is deprecated, use PaperTrail.clear_transaction_id"
        )
        PaperTrail.clear_transaction_id
      end

      # @deprecated
      # @api private
      def merge_metadata(data)
        self.class.paper_trail_deprecate "merge_metadata"
        paper_trail.merge_metadata(data)
      end

      # @deprecated
      def attributes_before_change
        self.class.paper_trail_deprecate "attributes_before_change"
        paper_trail.attributes_before_change
      end

      # @deprecated
      def object_attrs_for_paper_trail
        self.class.paper_trail_deprecate "object_attrs_for_paper_trail"
        paper_trail.object_attrs_for_paper_trail
      end

      # @deprecated
      def changed_notably?
        self.class.paper_trail_deprecate "changed_notably?"
        paper_trail.changed_notably?
      end

      # @deprecated
      def ignored_attr_has_changed?
        self.class.paper_trail_deprecate "ignored_attr_has_changed?"
        paper_trail.ignored_attr_has_changed?
      end

      # @deprecated
      def notably_changed
        self.class.paper_trail_deprecate "notably_changed"
        paper_trail.notably_changed
      end

      # @deprecated
      def changed_and_not_ignored
        self.class.paper_trail_deprecate "changed_and_not_ignored"
        paper_trail.changed_and_not_ignored
      end

      # The new method is named "enabled?" for consistency.
      # @deprecated
      def paper_trail_switched_on?
        self.class.paper_trail_deprecate "enabled?", "paper_trail_switched_on?"
        paper_trail.enabled?
      end

      # @deprecated
      # @api private
      def save_version?
        self.class.paper_trail_deprecate "save_version?"
        paper_trail.save_version?
      end
    end
  end
end
