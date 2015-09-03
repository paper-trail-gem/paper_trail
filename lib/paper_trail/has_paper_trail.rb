require 'active_support/core_ext/object' # provides the `try` method
require 'paper_trail/instance_methods'
require 'paper_trail/model_setup_concern'
require 'paper_trail/callbacks'

module PaperTrail
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      include Callbacks
      include ModelSetupConcern
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
      #
      def has_paper_trail(options = {})
        setup_model_for_paper_trail(options)

        options[:on] ||= [:create, :update, :destroy]

        # Wrap the :on option in an array if necessary. This allows a single
        # symbol to be passed in.
        options_on = Array(options[:on])

        setup_callbacks_from_options options_on, options
      end

      # Switches PaperTrail off for this class.
      def paper_trail_off!
        PaperTrail.enabled_for_model(self, false)
      end

      # Switches PaperTrail on for this class.
      def paper_trail_on!
        PaperTrail.enabled_for_model(self, true)
      end

      def paper_trail_enabled_for_model?
        return false unless self.include?(PaperTrail::Model::InstanceMethods)
        PaperTrail.enabled_for_model?(self)
      end

      def paper_trail_version_class
        @paper_trail_version_class ||= version_class_name.constantize
      end

      # Used for `Version#object` attribute.
      def serialize_attributes_for_paper_trail!(attributes)
        # Don't serialize before values before inserting into columns of type
        # `JSON` on `PostgreSQL` databases.
        return attributes if self.paper_trail_version_class.object_col_is_json?

        serialized_attributes.each do |key, coder|
          if attributes.key?(key)
            # Fall back to current serializer if `coder` has no `dump` method.
            coder = PaperTrail.serializer unless coder.respond_to?(:dump)
            attributes[key] = coder.dump(attributes[key])
          end
        end
      end

      # TODO: There is a lot of duplication between this and
      # `serialize_attributes_for_paper_trail!`.
      def unserialize_attributes_for_paper_trail!(attributes)
        # Don't serialize before values before inserting into columns of type
        # `JSON` on `PostgreSQL` databases.
        return attributes if self.paper_trail_version_class.object_col_is_json?

        serialized_attributes.each do |key, coder|
          if attributes.key?(key)
            # Fall back to current serializer if `coder` has no `dump` method.
            # TODO: Shouldn't this be `:load`?
            coder = PaperTrail.serializer unless coder.respond_to?(:dump)
            attributes[key] = coder.load(attributes[key])
          end
        end
      end

      # Used for Version#object_changes attribute.
      def serialize_attribute_changes_for_paper_trail!(changes)
        # Don't serialize before values before inserting into columns of type `JSON`
# on `PostgreSQL` databases.
        return changes if self.paper_trail_version_class.object_changes_col_is_json?

        serialized_attributes.each do |key, coder|
          if changes.key?(key)
            # Fall back to current serializer if `coder` has no `dump` method.
            coder = PaperTrail.serializer unless coder.respond_to?(:dump)
            old_value, new_value = changes[key]
            changes[key] = [coder.dump(old_value),
                            coder.dump(new_value)]
          end
        end
      end

      # TODO: There is a lot of duplication between this and
      # `serialize_attribute_changes_for_paper_trail!`.
      def unserialize_attribute_changes_for_paper_trail!(changes)
        # Don't serialize before values before inserting into columns of type
        # `JSON` on `PostgreSQL` databases.
        return changes if self.paper_trail_version_class.object_changes_col_is_json?

        serialized_attributes.each do |key, coder|
          if changes.key?(key)
            # Fall back to current serializer if `coder` has no `dump` method.
            # TODO: Shouldn't this be `:load`?
            coder = PaperTrail.serializer unless coder.respond_to?(:dump)
            old_value, new_value = changes[key]
            changes[key] = [coder.load(old_value),
                            coder.load(new_value)]
          end
        end
      end
    end
  end
end
