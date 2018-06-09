# frozen_string_literal: true

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
    end

    # Wrap the following methods in a module so we can include them only in the
    # ActiveRecord models that declare `has_paper_trail`.
    module InstanceMethods
      # @api public
      def paper_trail
        ::PaperTrail::RecordTrail.new(self)
      end
    end
  end
end
