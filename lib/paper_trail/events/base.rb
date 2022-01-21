# frozen_string_literal: true

module PaperTrail
  module Events
    # We refer to times in the lifecycle of a record as "events". There are
    # three events:
    #
    # - create
    #   - `after_create` we call `RecordTrail#record_create`
    # - update
    #   - `after_update` we call `RecordTrail#record_update`
    #   - `after_touch` we call `RecordTrail#record_update`
    #   - `RecordTrail#save_with_version` calls `RecordTrail#record_update`
    #   - `RecordTrail#update_columns` is also referred to as an update, though
    #     it uses `RecordTrail#record_update_columns` rather than
    #     `RecordTrail#record_update`
    # - destroy
    #   - `before_destroy` or `after_destroy` we call `RecordTrail#record_destroy`
    #
    # The value inserted into the `event` column of the versions table can also
    # be overridden by the user, with `paper_trail_event`.
    #
    # @api private
    class Base
      # @api private
      def initialize(record, in_after_callback)
        @record = record
        @in_after_callback = in_after_callback
      end

      # Determines whether it is appropriate to generate a new version
      # instance. A timestamp-only update (e.g. only `updated_at` changed) is
      # considered notable unless an ignored attribute was also changed.
      #
      # @api private
      def changed_notably?
        if ignored_attr_has_changed?
          timestamps = @record.send(:timestamp_attributes_for_update_in_model).map(&:to_s)
          (notably_changed - timestamps).any?
        else
          notably_changed.any?
        end
      end

      private

      # Rails 5.1 changed the API of `ActiveRecord::Dirty`. See
      # https://github.com/paper-trail-gem/paper_trail/pull/899
      #
      # @api private
      def attribute_changed_in_latest_version?(attr_name)
        if @in_after_callback
          @record.saved_change_to_attribute?(attr_name.to_s)
        else
          @record.attribute_changed?(attr_name.to_s)
        end
      end

      # @api private
      def nonskipped_attributes_before_change(is_touch)
        record_attributes = @record.attributes.except(*@record.paper_trail_options[:skip])
        record_attributes.each_key do |k|
          if @record.class.column_names.include?(k)
            record_attributes[k] = attribute_in_previous_version(k, is_touch)
          end
        end
      end

      # Rails 5.1 changed the API of `ActiveRecord::Dirty`. See
      # https://github.com/paper-trail-gem/paper_trail/pull/899
      #
      # Event can be any of the three (create, update, destroy).
      #
      # @api private
      def attribute_in_previous_version(attr_name, is_touch)
        if @in_after_callback && !is_touch
          # For most events, we want the original value of the attribute, before
          # the last save.
          @record.attribute_before_last_save(attr_name.to_s)
        else
          # We are either performing a `record_destroy` or a
          # `record_update(is_touch: true)`.
          @record.attribute_in_database(attr_name.to_s)
        end
      end

      # @api private
      def calculated_ignored_array
        ignore = @record.paper_trail_options[:ignore].dup
        # Remove Hash arguments and then evaluate whether the attributes (the
        # keys of the hash) should also get pushed into the collection.
        ignore.delete_if do |obj|
          obj.is_a?(Hash) &&
            obj.each { |attr, condition|
              ignore << attr if condition.respond_to?(:call) && condition.call(@record)
            }
        end
      end

      # @api private
      def changed_and_not_ignored
        skip = @record.paper_trail_options[:skip]
        (changed_in_latest_version - calculated_ignored_array) - skip
      end

      # @api private
      def changed_in_latest_version
        # Memoized to reduce memory usage
        @changed_in_latest_version ||= changes_in_latest_version.keys
      end

      # Memoized to reduce memory usage
      #
      # @api private
      def changes_in_latest_version
        @changes_in_latest_version ||= load_changes_in_latest_version
      end

      # @api private
      def evaluate_only
        only = @record.paper_trail_options[:only].dup
        # Remove Hash arguments and then evaluate whether the attributes (the
        # keys of the hash) should also get pushed into the collection.
        only.delete_if do |obj|
          obj.is_a?(Hash) &&
            obj.each { |attr, condition|
              only << attr if condition.respond_to?(:call) && condition.call(@record)
            }
        end
        only
      end

      # An attributed is "ignored" if it is listed in the `:ignore` option
      # and/or the `:skip` option.  Returns true if an ignored attribute has
      # changed.
      #
      # @api private
      def ignored_attr_has_changed?
        ignored = calculated_ignored_array + @record.paper_trail_options[:skip]
        ignored.any? && (changed_in_latest_version & ignored).any?
      end

      # Rails 5.1 changed the API of `ActiveRecord::Dirty`. See
      # https://github.com/paper-trail-gem/paper_trail/pull/899
      #
      # @api private
      def load_changes_in_latest_version
        if @in_after_callback
          @record.saved_changes
        else
          @record.changes
        end
      end

      # PT 10 has a new optional column, `item_subtype`
      #
      # @api private
      def merge_item_subtype_into(data)
        if @record.class.paper_trail.version_class.columns_hash.key?("item_subtype")
          data.merge!(item_subtype: @record.class.name)
        end
      end

      # Updates `data` from the model's `meta` option and from `controller_info`.
      # Metadata is always recorded; that means all three events (create, update,
      # destroy) and `update_columns`.
      #
      # @api private
      def merge_metadata_into(data)
        merge_metadata_from_model_into(data)
        merge_metadata_from_controller_into(data)
      end

      # Updates `data` from `controller_info`.
      #
      # @api private
      def merge_metadata_from_controller_into(data)
        data.merge(PaperTrail.request.controller_info || {})
      end

      # Updates `data` from the model's `meta` option.
      #
      # @api private
      def merge_metadata_from_model_into(data)
        @record.paper_trail_options[:meta].each do |k, v|
          data[k] = model_metadatum(v, data[:event])
        end
      end

      # Given a `value` from the model's `meta` option, returns an object to be
      # persisted. The `value` can be a simple scalar value, but it can also
      # be a symbol that names a model method, or even a Proc.
      #
      # @api private
      def model_metadatum(value, event)
        if value.respond_to?(:call)
          value.call(@record)
        elsif value.is_a?(Symbol) && @record.respond_to?(value, true)
          metadatum_from_model_method(event, value)
        else
          value
        end
      end

      # The model method can either be an attribute or a non-attribute method.
      #
      # If it is an attribute that is changing in an existing object,
      # be sure to grab the correct version.
      #
      # @api private
      def metadatum_from_model_method(event, method)
        if event != "create" &&
            @record.has_attribute?(method) &&
            attribute_changed_in_latest_version?(method)
          attribute_in_previous_version(method, false)
        else
          @record.send(method)
        end
      end

      # @api private
      def notable_changes
        changes_in_latest_version.delete_if { |k, _v|
          !notably_changed.include?(k)
        }
      end

      # @api private
      def notably_changed
        # Memoized to reduce memory usage
        @notably_changed ||= begin
          only = evaluate_only
          cani = changed_and_not_ignored
          only.empty? ? cani : (cani & only)
        end
      end

      # Returns hash of attributes (with appropriate attributes serialized),
      # omitting attributes to be skipped.
      #
      # @api private
      def object_attrs_for_paper_trail(is_touch)
        attrs = nonskipped_attributes_before_change(is_touch)
        AttributeSerializers::ObjectAttribute.new(@record.class).serialize(attrs)
        attrs
      end

      # @api private
      def prepare_object_changes(changes)
        changes = serialize_object_changes(changes)
        recordable_object_changes(changes)
      end

      # Returns an object which can be assigned to the `object_changes`
      # attribute of a nascent version record. If the `object_changes` column is
      # a postgres `json` column, then a hash can be used in the assignment,
      # otherwise the column is a `text` column, and we must perform the
      # serialization here, using `PaperTrail.serializer`.
      #
      # @api private
      # @param changes HashWithIndifferentAccess
      def recordable_object_changes(changes)
        if PaperTrail.config.object_changes_adapter.respond_to?(:diff)
          # We'd like to avoid the `to_hash` here, because it increases memory
          # usage, but that would be a breaking change because
          # `object_changes_adapter` expects a plain `Hash`, not a
          # `HashWithIndifferentAccess`.
          changes = PaperTrail.config.object_changes_adapter.diff(changes.to_hash)
        end

        if @record.class.paper_trail.version_class.object_changes_col_is_json?
          changes
        else
          PaperTrail.serializer.dump(changes)
        end
      end

      # Returns a boolean indicating whether to store serialized version diffs
      # in the `object_changes` column of the version record.
      #
      # @api private
      def record_object_changes?
        @record.class.paper_trail.version_class.column_names.include?("object_changes")
      end

      # Returns a boolean indicating whether to store the original object during save.
      #
      # @api private
      def record_object?
        @record.class.paper_trail.version_class.column_names.include?("object")
      end

      # Returns an object which can be assigned to the `object` attribute of a
      # nascent version record. If the `object` column is a postgres `json`
      # column, then a hash can be used in the assignment, otherwise the column
      # is a `text` column, and we must perform the serialization here, using
      # `PaperTrail.serializer`.
      #
      # @api private
      def recordable_object(is_touch)
        if @record.class.paper_trail.version_class.object_col_is_json?
          object_attrs_for_paper_trail(is_touch)
        else
          PaperTrail.serializer.dump(object_attrs_for_paper_trail(is_touch))
        end
      end

      # @api private
      def serialize_object_changes(changes)
        AttributeSerializers::ObjectChangesAttribute.
          new(@record.class).
          serialize(changes)

        # We'd like to convert this `HashWithIndifferentAccess` to a plain
        # `Hash`, but we don't, to save memory.
        changes
      end
    end
  end
end
