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
      base.extend ClassMethods
    end

    # :nodoc:
    module ClassMethods
      # Declare this in your model to track every create, update, and destroy.
      # Each version of the model is available in the `versions` association.
      #
      # Options:
      #
      # - :on - The events to track (optional; defaults to all of them). Set
      #   to an array of `:create`, `:update`, `:destroy` and `:touch` as desired.
      # - :class_name (deprecated) - The name of a custom Version class that
      #   includes `PaperTrail::VersionConcern`.
      # - :ignore - An array of attributes for which a new `Version` will not be
      #   created if only they change. It can also accept a Hash as an
      #   argument where the key is the attribute to ignore (a `String` or
      #   `Symbol`), which will only be ignored if the value is a `Proc` which
      #   returns truthily.
      # - :if, :unless - Procs that allow to specify conditions when to save
      #   versions for an object.
      # - :only - Inverse of `ignore`. A new `Version` will be created only
      #   for these attributes if supplied it can also accept a Hash as an
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
      # - :versions - Either,
      #   - A String (deprecated) - The name to use for the versions
      #     association.  Default is `:versions`.
      #   - A Hash - options passed to `has_many`, plus `name:` and `scope:`.
      # - :version - The name to use for the method which returns the version
      #   the instance was reified from. Default is `:version`.
      #
      # Plugins like the experimental `paper_trail-association_tracking` gem
      # may accept additional options.
      #
      # You can define a default set of options via the configurable
      # `PaperTrail.config.has_paper_trail_defaults` hash in your applications
      # initializer. The hash can contain any of the following options and will
      # provide an overridable default for all models.
      #
      # @api public
      def has_paper_trail(options = {})
        defaults = PaperTrail.config.has_paper_trail_defaults
        paper_trail.setup(defaults.merge(options))
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
