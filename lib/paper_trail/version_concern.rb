require 'active_support/concern'

module PaperTrail
  module VersionConcern
    extend ::ActiveSupport::Concern

    included do
      belongs_to :item, :polymorphic => true

      # Since the test suite has test coverage for this, we want to declare
      # the association when the test suite is running. This makes it pass when
      # DB is not initialized prior to test runs such as when we run on Travis
      # CI (there won't be a db in `test/dummy/db/`).
      if PaperTrail.config.track_associations?
        has_many :version_associations, :dependent => :destroy
      end

      validates_presence_of :event

      if PaperTrail.active_record_protected_attributes?
        attr_accessible :item_type, :item_id, :event, :whodunnit, :object, :object_changes, :transaction_id, :created_at
      end

      after_create :enforce_version_limit!

      scope :within_transaction, lambda { |id| where :transaction_id => id }
    end

    module ClassMethods
      def with_item_keys(item_type, item_id)
        where :item_type => item_type, :item_id => item_id
      end

      def creates
        where :event => 'create'
      end

      def updates
        where :event => 'update'
      end

      def destroys
        where :event => 'destroy'
      end

      def not_creates
        where 'event <> ?', 'create'
      end

      # Expects `obj` to be an instance of `PaperTrail::Version` by default,
      # but can accept a timestamp if `timestamp_arg` receives `true`
      def subsequent(obj, timestamp_arg = false)
        if timestamp_arg != true && self.primary_key_is_int?
          return where(arel_table[primary_key].gt(obj.id)).order(arel_table[primary_key].asc)
        end

        obj = obj.send(PaperTrail.timestamp_field) if obj.is_a?(self)
        where(arel_table[PaperTrail.timestamp_field].gt(obj)).order(self.timestamp_sort_order)
      end

      def preceding(obj, timestamp_arg = false)
        if timestamp_arg != true && self.primary_key_is_int?
          return where(arel_table[primary_key].lt(obj.id)).order(arel_table[primary_key].desc)
        end

        obj = obj.send(PaperTrail.timestamp_field) if obj.is_a?(self)
        where(arel_table[PaperTrail.timestamp_field].lt(obj)).order(self.timestamp_sort_order('desc'))
      end


      def between(start_time, end_time)
        where(
          arel_table[PaperTrail.timestamp_field].gt(start_time).
          and(arel_table[PaperTrail.timestamp_field].lt(end_time))
        ).order(self.timestamp_sort_order)
      end

      # Defaults to using the primary key as the secondary sort order if
      # possible.
      def timestamp_sort_order(direction = 'asc')
        [arel_table[PaperTrail.timestamp_field].send(direction.downcase)].tap do |array|
          array << arel_table[primary_key].send(direction.downcase) if self.primary_key_is_int?
        end
      end

      # Performs an attribute search on the serialized object by invoking the
      # identically-named method in the serializer being used.
      def where_object(args = {})
        raise ArgumentError, 'expected to receive a Hash' unless args.is_a?(Hash)

        if columns_hash['object'].type == :jsonb
          where("object @> ?", args.to_json)
        elsif columns_hash['object'].type == :json
          predicates = []
          values = []
          args.each do |field, value|
            predicates.push "object->>? = ?"
            values.concat([field, value.to_s])
          end
          sql = predicates.join(" and ")
          where(sql, *values)
        else
          arel_field = arel_table[:object]
          where_conditions = args.map { |field, value|
            PaperTrail.serializer.where_object_condition(arel_field, field, value)
          }.reduce { |a, e| a.and(e) }
          where(where_conditions)
        end
      end

      def where_object_changes(args = {})
        raise ArgumentError, 'expected to receive a Hash' unless args.is_a?(Hash)

        if columns_hash['object_changes'].type == :jsonb
          args.each { |field, value| args[field] = [value] }
          where("object_changes @> ?", args.to_json)
        elsif columns_hash['object'].type == :json
          predicates = []
          values = []
          args.each do |field, value|
            predicates.push(
              "((object_changes->>? ILIKE ?) OR (object_changes->>? ILIKE ?))"
            )
            values.concat([field, "[#{value.to_json},%", field, "[%,#{value.to_json}]%"])
          end
          sql = predicates.join(" and ")
          where(sql, *values)
        else
          arel_field = arel_table[:object_changes]
          where_conditions = args.map { |field, value|
            PaperTrail.serializer.where_object_changes_condition(arel_field, field, value)
          }.reduce { |a, e| a.and(e) }
          where(where_conditions)
        end
      end

      def primary_key_is_int?
        @primary_key_is_int ||= columns_hash[primary_key].type == :integer
      rescue
        true
      end

      # Returns whether the `object` column is using the `json` type supported
      # by PostgreSQL.
      def object_col_is_json?
        [:json, :jsonb].include?(columns_hash['object'].type)
      end

      # Returns whether the `object_changes` column is using the `json` type
      # supported by PostgreSQL.
      def object_changes_col_is_json?
        [:json, :jsonb].include?(columns_hash['object_changes'].try(:type))
      end
    end

    # Restore the item from this version.
    #
    # Optionally this can also restore all :has_one and :has_many (including
    # has_many :through) associations as they were "at the time", if they are
    # also being versioned by PaperTrail.
    #
    # Options:
    #
    # - :has_one
    #   - `true` - Also reify has_one associations.
    #   - `false - Default.
    # - :has_many
    #   - `true` - Also reify has_many and has_many :through associations.
    #   - `false` - Default.
    # - :mark_for_destruction
    #   - `true` - Mark the has_one/has_many associations that did not exist in
    #     the reified version for destruction, instead of removing them.
    #   - `false` - Default. Useful for persisting the reified version.
    # - :dup
    #   - `false` - Default.
    #   - `true` - Always create a new object instance. Useful for
    #     comparing two versions of the same object.
    # - :unversioned_attributes
    #   - `:nil` - Default. Attributes undefined in version record are set to
    #     nil in reified record.
    #   - `:preserve` - Attributes undefined in version record are not modified.
    #
    def reify(options = {})
      return nil if object.nil?

      without_identity_map do
        options.reverse_merge!(
          :version_at => created_at,
          :mark_for_destruction => false,
          :has_one    => false,
          :has_many   => false,
          :unversioned_attributes => :nil
        )

        attrs = self.class.object_col_is_json? ? object : PaperTrail.serializer.load(object)

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

        if options[:dup] != true && item
          model = item
          # Look for attributes that exist in the model and not in this
          # version. These attributes should be set to nil.
          if options[:unversioned_attributes] == :nil
            (model.attribute_names - attrs.keys).each { |k| attrs[k] = nil }
          end
        else
          inheritance_column_name = item_type.constantize.inheritance_column
          class_name = attrs[inheritance_column_name].blank? ? item_type : attrs[inheritance_column_name]
          klass = class_name.constantize
          # The `dup` option always returns a new object, otherwise we should
          # attempt to look for the item outside of default scope(s).
          if options[:dup] || (_item = klass.unscoped.find_by_id(item_id)).nil?
            model = klass.new
          elsif options[:unversioned_attributes] == :nil
            model = _item
            # Look for attributes that exist in the model and not in this
            # version. These attributes should be set to nil.
            (model.attribute_names - attrs.keys).each { |k| attrs[k] = nil }
          end
        end

        if PaperTrail.serialized_attributes?
          model.class.unserialize_attributes_for_paper_trail! attrs
        end

        # Set all the attributes in this version on the model.
        attrs.each do |k, v|
          if model.has_attribute?(k)
            model[k.to_sym] = v
          elsif model.respond_to?("#{k}=")
            model.send("#{k}=", v)
          else
            logger.warn "Attribute #{k} does not exist on #{item_type} (Version id: #{id})."
          end
        end

        model.send "#{model.class.version_association_name}=", self

        unless options[:has_one] == false
          reify_has_ones model, options
        end

        unless options[:has_many] == false
          reify_has_manys model, options
        end

        model
      end
    end

    # Returns what changed in this version of the item.
    # `ActiveModel::Dirty#changes`. returns `nil` if your `versions` table does
    # not have an `object_changes` text column.
    def changeset
      return nil unless self.class.column_names.include? 'object_changes'

      _changes = self.class.object_changes_col_is_json? ? object_changes : PaperTrail.serializer.load(object_changes)
      @changeset ||= HashWithIndifferentAccess.new(_changes).tap do |changes|
        if PaperTrail.serialized_attributes?
          item_type.constantize.unserialize_attribute_changes_for_paper_trail!(changes)
        end
      end
    rescue
      {}
    end

    # Returns who put the item into the state stored in this version.
    def paper_trail_originator
      @paper_trail_originator ||= previous.whodunnit rescue nil
    end

    def originator
      ::ActiveSupport::Deprecation.warn "Use paper_trail_originator instead of originator."
      self.paper_trail_originator
    end

    # Returns who changed the item from the state it had in this version. This
    # is an alias for `whodunnit`.
    def terminator
      @terminator ||= whodunnit
    end
    alias_method :version_author, :terminator

    def sibling_versions(reload = false)
      @sibling_versions = nil if reload == true
      @sibling_versions ||= self.class.with_item_keys(item_type, item_id)
    end

    def next
      @next ||= sibling_versions.subsequent(self).first
    end

    def previous
      @previous ||= sibling_versions.preceding(self).first
    end

    def index
      table = self.class.arel_table unless @index
      @index ||=
        if self.class.primary_key_is_int?
          sibling_versions.select(table[self.class.primary_key]).order(table[self.class.primary_key].asc).index(self)
        else
          sibling_versions.select([table[PaperTrail.timestamp_field], table[self.class.primary_key]]).
            order(self.class.timestamp_sort_order).index(self)
        end
    end

    private

    # In Rails 3.1+, calling reify on a previous version confuses the
    # IdentityMap, if enabled. This prevents insertion into the map.
    def without_identity_map(&block)
      if defined?(::ActiveRecord::IdentityMap) && ::ActiveRecord::IdentityMap.respond_to?(:without)
        ::ActiveRecord::IdentityMap.without(&block)
      else
        block.call
      end
    end

    # Restore the `model`'s has_one associations as they were when this
    # version was superseded by the next (because that's what the user was
    # looking at when they made the change).
    def reify_has_ones(model, options = {})
      version_table_name = model.class.paper_trail_version_class.table_name
      model.class.reflect_on_all_associations(:has_one).each do |assoc|
        if assoc.klass.paper_trail_enabled_for_model?
          version = model.class.paper_trail_version_class.joins(:version_associations).
            where("version_associations.foreign_key_name = ?", assoc.foreign_key).
            where("version_associations.foreign_key_id = ?", model.id).
            where("#{version_table_name}.item_type = ?", assoc.class_name).
            where("created_at >= ? OR transaction_id = ?", options[:version_at], transaction_id).
            order("#{version_table_name}.id ASC").first
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
              child = version.reify(options.merge(:has_many => false, :has_one => false))
              model.appear_as_new_record do
                model.send "#{assoc.name}=", child
              end
            end
          end
        end
      end
    end

    # Restore the `model`'s has_many associations as they were at version_at
    # timestamp We lookup the first child versions after version_at timestamp or
    # in same transaction.
    def reify_has_manys(model, options = {})
      assoc_has_many_through, assoc_has_many_directly =
        model.class.reflect_on_all_associations(:has_many).
        partition { |assoc| assoc.options[:through] }
      reify_has_many_directly(assoc_has_many_directly, model, options)
      reify_has_many_through(assoc_has_many_through, model, options)
    end

    # Restore the `model`'s has_many associations not associated through
    # another association.
    def reify_has_many_directly(associations, model, options = {})
      version_table_name = model.class.paper_trail_version_class.table_name
      associations.each do |assoc|
        next unless assoc.klass.paper_trail_enabled_for_model?
        version_id_subquery = PaperTrail::VersionAssociation.joins(model.class.version_association_name).
          select("MIN(version_id)").
          where("foreign_key_name = ?", assoc.foreign_key).
          where("foreign_key_id = ?", model.id).
          where("#{version_table_name}.item_type = ?", assoc.class_name).
          where("created_at >= ? OR transaction_id = ?", options[:version_at], transaction_id).
          group("item_id").to_sql
        versions = model.class.paper_trail_version_class.where("id IN (#{version_id_subquery})").inject({}) do |acc, v|
          acc.merge!(v.item_id => v)
        end

        # Pass true to force the model to load.
        collection = Array.new model.send(assoc.name, true)

        # Iterate each child to replace it with the previous value if there is
        # a version after the timestamp.
        collection.map! do |c|
          if (version = versions.delete(c.id)).nil?
            c
          elsif version.event == 'create'
            options[:mark_for_destruction] ? c.tap { |r| r.mark_for_destruction } : nil
          else
            version.reify(options.merge(:has_many => false, :has_one => false))
          end
        end

        # Reify the rest of the versions and add them to the collection, these
        # versions are for those that have been removed from the live
        # associations.
        collection += versions.values.map { |version| version.reify(options.merge(:has_many => false, :has_one => false)) }

        model.send(assoc.name).proxy_association.target = collection.compact
      end
    end

    # Restore the `model`'s has_many associations through another association.
    # This must be called after the direct has_manys have been reified
    # (reify_has_many_directly).
    def reify_has_many_through(associations, model, options = {})
      associations.each do |assoc|
        next unless assoc.klass.paper_trail_enabled_for_model?
        through_collection = model.send(assoc.options[:through])
        collection_keys = through_collection.map { |through_model| through_model.send(assoc.foreign_key) }

        version_id_subquery = assoc.klass.paper_trail_version_class.
          select("MIN(id)").
          where("item_type = ?", assoc.class_name).
          where("item_id IN (?)", collection_keys).
          where("created_at >= ? OR transaction_id = ?", options[:version_at], transaction_id).
          group("item_id").to_sql
        versions = assoc.klass.paper_trail_version_class.where("id IN (#{version_id_subquery})").inject({}) do |acc, v|
          acc.merge!(v.item_id => v)
        end

        collection = Array.new assoc.klass.where(assoc.klass.primary_key => collection_keys)

        # Iterate each child to replace it with the previous value if there is
        # a version after the timestamp.
        collection.map! do |c|
          if (version = versions.delete(c.id)).nil?
            c
          elsif version.event == 'create'
            options[:mark_for_destruction] ? c.tap { |r| r.mark_for_destruction } : nil
          else
            version.reify(options.merge(:has_many => false, :has_one => false))
          end
        end

        # Reify the rest of the versions and add them to the collection, these
        # versions are for those that have been removed from the live
        # associations.
        collection += versions.values.map { |version| version.reify(options.merge(:has_many => false, :has_one => false)) }

        model.send(assoc.name).proxy_association.target = collection.compact
      end
    end

    # Checks that a value has been set for the `version_limit` config
    # option, and if so enforces it.
    def enforce_version_limit!
      return unless PaperTrail.config.version_limit.is_a? Numeric
      previous_versions = sibling_versions.not_creates
      return unless previous_versions.size > PaperTrail.config.version_limit
      excess_previous_versions = previous_versions - previous_versions.last(PaperTrail.config.version_limit)
      excess_previous_versions.map(&:destroy)
    end
  end
end
