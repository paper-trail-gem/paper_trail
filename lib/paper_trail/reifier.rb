# frozen_string_literal: true

require "paper_trail/attribute_serializers/object_attribute"

module PaperTrail
  # Given a version record and some options, builds a new model object.
  # @api private
  module Reifier
    class << self
      # See `VersionConcern#reify` for documentation.
      # @api private
      def reify(version, options)
        options = apply_defaults_to(options, version)
        attrs = version.object_deserialized
        model = init_model(attrs, options, version)
        reify_attributes(model, version, attrs)
        model.send "#{model.class.version_association_name}=", version
        model
      end

      private

      # Given a hash of `options` for `.reify`, return a new hash with default
      # values applied.
      # @api private
      def apply_defaults_to(options, version)
        {
          version_at: version.created_at,
          mark_for_destruction: false,
          has_one: false,
          has_many: false,
          belongs_to: false,
          has_and_belongs_to_many: false,
          unversioned_attributes: :nil
        }.merge(options)
      end

      # Initialize a model object suitable for reifying `version` into. Does
      # not perform reification, merely instantiates the appropriate model
      # class and, if specified by `options[:unversioned_attributes]`, sets
      # unversioned attributes to `nil`.
      #
      # Normally a polymorphic belongs_to relationship allows us to get the
      # object we belong to by calling, in this case, `item`.  However this
      # returns nil if `item` has been destroyed, and we need to be able to
      # retrieve destroyed objects.
      #
      # In this situation we constantize the `item_type` to get hold of the
      # class...except when the stored object's attributes include a `type`
      # key.  If this is the case, the object we belong to is using single
      # table inheritance (STI) and the `item_type` will be the base class,
      # not the actual subclass. If `type` is present but empty, the class is
      # the base class.
      def init_model(attrs, options, version)
        klass = version_reification_class(version, attrs)

        # The `dup` option and destroyed version always returns a new object,
        # otherwise we should attempt to load item or to look for the item
        # outside of default scope(s).
        model = if options[:dup] == true || version.event == "destroy"
                  klass.new
                else
                  version.item || init_model_by_finding_item_id(klass, version) || klass.new
                end

        if options[:unversioned_attributes] == :nil && !model.new_record?
          init_unversioned_attrs(attrs, model)
        end

        model
      end

      # @api private
      def init_model_by_finding_item_id(klass, version)
        klass.unscoped.where(klass.primary_key => version.item_id).first
      end

      # Look for attributes that exist in `model` and not in this version.
      # These attributes should be set to nil. Modifies `attrs`.
      # @api private
      def init_unversioned_attrs(attrs, model)
        (model.attribute_names - attrs.keys).each { |k| attrs[k] = nil }
      end

      # Reify onto `model` an attribute named `k` with value `v` from `version`.
      #
      # `ObjectAttribute#deserialize` will return the mapped enum value and in
      # Rails < 5, the []= uses the integer type caster from the column
      # definition (in general) and thus will turn a (usually) string to 0
      # instead of the correct value.
      #
      # @api private
      def reify_attribute(k, v, model, version)
        if model.has_attribute?(k)
          model[k.to_sym] = v
        elsif model.respond_to?("#{k}=")
          model.send("#{k}=", v)
        elsif version.logger
          version.logger.warn(
            "Attribute #{k} does not exist on #{version.item_type} (Version id: #{version.id})."
          )
        end
      end

      # Reify onto `model` all the attributes of `version`.
      # @api private
      def reify_attributes(model, version, attrs)
        AttributeSerializers::ObjectAttribute.new(model.class).deserialize(attrs)
        attrs.each do |k, v|
          reify_attribute(k, v, model, version)
        end
      end

      # Given a `version`, return the class to reify. This method supports
      # Single Table Inheritance (STI) with custom inheritance columns and
      # custom inheritance column values.
      #
      # For example, imagine a `version` whose `item_type` is "Animal". The
      # `animals` table is an STI table (it has cats and dogs) and it has a
      # custom inheritance column, `species`. If `attrs["species"]` is "Dog",
      # this method returns the constant `Dog`. If `attrs["species"]` is blank,
      # this method returns the constant `Animal`.
      #
      # The values contained in the inheritance columns may be non-camelized
      # strings (e.g. 'dog' instead of 'Dog'). To reify classes in this case
      # we need to call the parents class `sti_class_for` method to retrieve
      # the correct record class.
      #
      # You can see these particular examples in action in
      # `spec/models/animal_spec.rb` and `spec/models/plant_spec.rb`
      def version_reification_class(version, attrs)
        clazz = version.item_type.constantize
        inheritance_column_name = clazz.inheritance_column
        inher_col_value = attrs[inheritance_column_name]
        return clazz if inher_col_value.blank?

        # Rails 6.1 adds a public method for clients to use to customize STI classes. If that
        # method is not available, fall back to using the private one
        if clazz.public_methods.include?(:sti_class_for)
          return clazz.sti_class_for(inher_col_value)
        end

        clazz.send(:find_sti_class, inher_col_value)
      end
    end
  end
end
