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
        if options[:dup] != true && version.item
          model = version.item
          if options[:unversioned_attributes] == :nil
            init_unversioned_attrs(attrs, model)
          end
        else
          klass = version_reification_class(version, attrs)
          # The `dup` option always returns a new object, otherwise we should
          # attempt to look for the item outside of default scope(s).
          find_cond = { klass.primary_key => version.item_id }
          if options[:dup] || (item_found = klass.unscoped.where(find_cond).first).nil?
            model = klass.new
          elsif options[:unversioned_attributes] == :nil
            model = item_found
            init_unversioned_attrs(attrs, model)
          end
        end
        model
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
        enums = model.class.respond_to?(:defined_enums) ? model.class.defined_enums : {}
        is_enum_without_type_caster = ::ActiveRecord::VERSION::MAJOR < 5 && enums.key?(k)
        if model.has_attribute?(k) && !is_enum_without_type_caster
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
      # Single Table Inheritance (STI) with custom inheritance columns.
      #
      # For example, imagine a `version` whose `item_type` is "Animal". The
      # `animals` table is an STI table (it has cats and dogs) and it has a
      # custom inheritance column, `species`. If `attrs["species"]` is "Dog",
      # this method returns the constant `Dog`. If `attrs["species"]` is blank,
      # this method returns the constant `Animal`. You can see this particular
      # example in action in `spec/models/animal_spec.rb`.
      #
      # TODO: Duplication: similar `constantize` in VersionConcern#version_limit
      def version_reification_class(version, attrs)
        inheritance_column_name = version.item_type.constantize.inheritance_column
        inher_col_value = attrs[inheritance_column_name]
        class_name = inher_col_value.blank? ? version.item_type : inher_col_value
        class_name.constantize
      end
    end
  end
end
