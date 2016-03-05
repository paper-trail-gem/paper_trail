module PaperTrail
  # Given a version record and some options, builds a new model object.
  # @api private
  module Reifier
    class << self
      # See `VersionConcern#reify` for documentation.
      # @api private
      def reify(version, options)
        options = options.dup

        options.reverse_merge!(
          version_at: version.created_at,
          mark_for_destruction: false,
          has_one: false,
          has_many: false,
          unversioned_attributes: :nil
        )

        attrs = version.class.object_col_is_json? ?
          version.object :
          PaperTrail.serializer.load(version.object)

        # Normally a polymorphic belongs_to relationship allows us to get the
        # object we belong to by calling, in this case, `item`.  However this
        # returns nil if `item` has been destroyed, and we need to be able to
        # retrieve destroyed objects.
        #
        # In this situation we constantize the `item_type` to get hold of the
        # class...except when the stored object's attributes include a `type`
        # key.  If this is the case, the object we belong to is using single
        # table inheritance and the `item_type` will be the base class, not the
        # actual subclass. If `type` is present but empty, the class is the base
        # class.

        if options[:dup] != true && version.item
          model = version.item
          # Look for attributes that exist in the model and not in this
          # version. These attributes should be set to nil.
          if options[:unversioned_attributes] == :nil
            (model.attribute_names - attrs.keys).each { |k| attrs[k] = nil }
          end
        else
          inheritance_column_name = version.item_type.constantize.inheritance_column
          class_name = attrs[inheritance_column_name].blank? ?
            version.item_type :
            attrs[inheritance_column_name]
          klass = class_name.constantize
          # The `dup` option always returns a new object, otherwise we should
          # attempt to look for the item outside of default scope(s).
          if options[:dup] || (item_found = klass.unscoped.find_by_id(version.item_id)).nil?
            model = klass.new
          elsif options[:unversioned_attributes] == :nil
            model = item_found
            # Look for attributes that exist in the model and not in this
            # version. These attributes should be set to nil.
            (model.attribute_names - attrs.keys).each { |k| attrs[k] = nil }
          end
        end

        model.class.unserialize_attributes_for_paper_trail! attrs

        # Set all the attributes in this version on the model.
        attrs.each do |k, v|
          if model.has_attribute?(k)
            model[k.to_sym] = v
          elsif model.respond_to?("#{k}=")
            model.send("#{k}=", v)
          else
            version.logger.warn(
              "Attribute #{k} does not exist on #{version.item_type} (Version id: #{version.id})."
            )
          end
        end

        model.send "#{model.class.version_association_name}=", version

        unless options[:has_one] == false
          reify_has_ones version.transaction_id, model, options
        end

        unless options[:has_many] == false
          reify_has_manys version.transaction_id, model, options
        end

        model
      end

      private

      # Replaces each record in `array` with its reified version, if present
      # in `versions`.
      #
      # @api private
      # @param array - The collection to be modified.
      # @param options
      # @param versions - A `Hash` mapping IDs to `Version`s
      # @return nil - Always returns `nil`
      #
      # Once modified by this method, `array` will be assigned to the
      # AR association currently being reified.
      #
      def prepare_array_for_has_many(array, options, versions)
        # Iterate each child to replace it with the previous value if there is
        # a version after the timestamp.
        array.map! do |record|
          if (version = versions.delete(record.id)).nil?
            record
          elsif version.event == 'create'
            options[:mark_for_destruction] ? record.tap(&:mark_for_destruction) : nil
          else
            version.reify(options.merge(has_many: false, has_one: false))
          end
        end

        # Reify the rest of the versions and add them to the collection, these
        # versions are for those that have been removed from the live
        # associations.
        array.concat(
          versions.values.map { |v|
            v.reify(options.merge(has_many: false, has_one: false))
          }
        )

        array.compact!

        nil
      end

      # Restore the `model`'s has_one associations as they were when this
      # version was superseded by the next (because that's what the user was
      # looking at when they made the change).
      def reify_has_ones(transaction_id, model, options = {})
        version_table_name = model.class.paper_trail_version_class.table_name
        model.class.reflect_on_all_associations(:has_one).each do |assoc|
          if assoc.klass.paper_trail_enabled_for_model?
            version = model.class.paper_trail_version_class.joins(:version_associations).
              where("version_associations.foreign_key_name = ?", assoc.foreign_key).
              where("version_associations.foreign_key_id = ?", model.id).
              where("#{version_table_name}.item_type = ?", assoc.class_name).
              where("created_at >= ? OR transaction_id = ?", options[:version_at], transaction_id).
              order("#{version_table_name}.id ASC").
              first
            if version
              if version.event == 'create'
                if options[:mark_for_destruction]
                  model.send(assoc.name).mark_for_destruction if model.send(assoc.name, true)
                else
                  model.appear_as_new_record do
                    model.send "#{assoc.name}=", nil
                  end
                end
              else
                child = version.reify(options.merge(has_many: false, has_one: false))
                model.appear_as_new_record do
                  without_persisting(child) do
                    model.send "#{assoc.name}=", child
                  end
                end
              end
            end
          end
        end
      end

      # Restore the `model`'s has_many associations as they were at version_at
      # timestamp We lookup the first child versions after version_at timestamp or
      # in same transaction.
      def reify_has_manys(transaction_id, model, options = {})
        assoc_has_many_through, assoc_has_many_directly =
          model.class.reflect_on_all_associations(:has_many).
            partition { |assoc| assoc.options[:through] }
        reify_has_many_directly(transaction_id, assoc_has_many_directly, model, options)
        reify_has_many_through(transaction_id, assoc_has_many_through, model, options)
      end

      # Restore the `model`'s has_many associations not associated through
      # another association.
      def reify_has_many_directly(transaction_id, associations, model, options = {})
        version_table_name = model.class.paper_trail_version_class.table_name
        associations.each do |assoc|
          next unless assoc.klass.paper_trail_enabled_for_model?
          version_id_subquery = PaperTrail::VersionAssociation.
            joins(model.class.version_association_name).
            select("MIN(version_id)").
            where("foreign_key_name = ?", assoc.foreign_key).
            where("foreign_key_id = ?", model.id).
            where("#{version_table_name}.item_type = ?", assoc.class_name).
            where("created_at >= ? OR transaction_id = ?", options[:version_at], transaction_id).
            group("item_id").
            to_sql
          versions = versions_by_id(model.class, version_id_subquery)
          collection = Array.new model.send(assoc.name).reload # to avoid cache
          prepare_array_for_has_many(collection, options, versions)
          model.send(assoc.name).proxy_association.target = collection
        end
      end

      # Restore the `model`'s has_many associations through another association.
      # This must be called after the direct has_manys have been reified
      # (reify_has_many_directly).
      def reify_has_many_through(transaction_id, associations, model, options = {})
        associations.each do |assoc|
          next unless assoc.klass.paper_trail_enabled_for_model?

          # Load the collection of through-models. For example, if `model` is a
          # Chapter, having many Paragraphs through Sections, then
          # `through_collection` will contain Sections.
          through_collection = model.send(assoc.options[:through])

          # Examine the `source_reflection`, i.e. the "source" of `assoc` the
          # `ThroughReflection`. The source can be a `BelongsToReflection`
          # or a `HasManyReflection`.
          #
          # If the association is a has_many association again, then call
          # reify_has_manys for each record in `through_collection`.
          if !assoc.source_reflection.belongs_to? && through_collection.present?
            through_collection.each do |through_model|
              reify_has_manys(transaction_id, through_model, options)
            end

            # At this point, the "through" part of the association chain has
            # been reified, but not the final, "target" part. To continue our
            # example, `model.sections` (including `model.sections.paragraphs`)
            # has been loaded. However, the final "target" part of the
            # association, that is, `model.paragraphs`, has not been loaded. So,
            # we do that now.
            collection = through_collection.flat_map { |through_model|
              through_model.public_send(assoc.name.to_sym).to_a
            }
          else
            collection_keys = through_collection.map { |through_model|
              through_model.send(assoc.association_foreign_key)
            }

            version_id_subquery = assoc.klass.paper_trail_version_class.
              select("MIN(id)").
              where("item_type = ?", assoc.class_name).
              where("item_id IN (?)", collection_keys).
              where("created_at >= ? OR transaction_id = ?", options[:version_at], transaction_id).
              group("item_id").
              to_sql
            versions = versions_by_id(assoc.klass, version_id_subquery)
            collection = Array.new assoc.klass.where(assoc.klass.primary_key => collection_keys)
            prepare_array_for_has_many(collection, options, versions)
          end

          # To continue our example above, assign to `model.paragraphs` the
          # `collection` (an array of `Paragraph`s).
          model.send(assoc.name).proxy_association.target = collection
        end
      end

      # Given a SQL fragment that identifies the IDs of version records,
      # returns a `Hash` mapping those IDs to `Version`s.
      #
      # @api private
      # @param klass - An ActiveRecord class.
      # @param version_id_subquery - String. A SQL subquery that selects
      #   the IDs of version records.
      # @return A `Hash` mapping IDs to `Version`s
      #
      def versions_by_id(klass, version_id_subquery)
        klass.
          paper_trail_version_class.
          where("id IN (#{version_id_subquery})").
          inject({}) { |acc, v| acc.merge!(v.item_id => v) }
      end

      # Temporarily suppress #save so we can reassociate with the reified
      # master of a has_one relationship. Since ActiveRecord 5 the related
      # object is saved when it is assigned to the association. ActiveRecord
      # 5 also happens to be the first version that provides #suppress.
      def without_persisting(record)
        if record.class.respond_to? :suppress
          record.class.suppress { yield }
        else
          yield
        end
      end
    end
  end
end
