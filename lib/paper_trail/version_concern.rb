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
        attr_accessible(
          :item_type,
          :item_id,
          :event,
          :whodunnit,
          :object,
          :object_changes,
          :transaction_id,
          :created_at
        )
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

      # Returns versions after `obj`.
      #
      # @param obj - a `Version` or a timestamp
      # @param timestamp_arg - boolean - When true, `obj` is a timestamp.
      #   Default: false.
      # @return `ActiveRecord::Relation`
      # @api public
      def subsequent(obj, timestamp_arg = false)
        if timestamp_arg != true && self.primary_key_is_int?
          return where(arel_table[primary_key].gt(obj.id)).order(arel_table[primary_key].asc)
        end

        obj = obj.send(PaperTrail.timestamp_field) if obj.is_a?(self)
        where(arel_table[PaperTrail.timestamp_field].gt(obj)).order(self.timestamp_sort_order)
      end

      # Returns versions before `obj`.
      #
      # @param obj - a `Version` or a timestamp
      # @param timestamp_arg - boolean - When true, `obj` is a timestamp.
      #   Default: false.
      # @return `ActiveRecord::Relation`
      # @api public
      def preceding(obj, timestamp_arg = false)
        if timestamp_arg != true && self.primary_key_is_int?
          return where(arel_table[primary_key].lt(obj.id)).order(arel_table[primary_key].desc)
        end

        obj = obj.send(PaperTrail.timestamp_field) if obj.is_a?(self)
        where(arel_table[PaperTrail.timestamp_field].lt(obj)).
          order(self.timestamp_sort_order('desc'))
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
          where_conditions = "object @> '#{args.to_json}'::jsonb"
        elsif columns_hash['object'].type == :json
          where_conditions = args.map do |field, value|
            "object->>'#{field}' = '#{value}'"
          end
          where_conditions = where_conditions.join(" AND ")
        else
          arel_field = arel_table[:object]

          where_conditions = args.map do |field, value|
            PaperTrail.serializer.where_object_condition(arel_field, field, value)
          end.reduce do |condition1, condition2|
            condition1.and(condition2)
          end
        end

        where(where_conditions)
      end

      def where_object_changes(args = {})
        raise ArgumentError, 'expected to receive a Hash' unless args.is_a?(Hash)

        if columns_hash['object_changes'].type == :jsonb
          args.each { |field, value| args[field] = [value] }
          where_conditions = "object_changes @> '#{args.to_json}'::jsonb"
        elsif columns_hash['object'].type == :json
          where_conditions = args.map do |field, value|
            "((object_changes->>'#{field}' ILIKE '[#{value.to_json},%') " +
              "OR (object_changes->>'#{field}' ILIKE '[%,#{value.to_json}]%'))"
          end
          where_conditions = where_conditions.join(" AND ")
        else
          arel_field = arel_table[:object_changes]

          where_conditions = args.map do |field, value|
            PaperTrail.serializer.where_object_changes_condition(arel_field, field, value)
          end.reduce do |condition1, condition2|
            condition1.and(condition2)
          end
        end

        where(where_conditions)
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
        ::PaperTrail::Reifier.reify(self, options)
      end
    end

    # Returns what changed in this version of the item.
    # `ActiveModel::Dirty#changes`. returns `nil` if your `versions` table does
    # not have an `object_changes` text column.
    def changeset
      return nil unless self.class.column_names.include? 'object_changes'
      @changeset ||= load_changeset
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
      if reload || @sibling_versions.nil?
        @sibling_versions = self.class.with_item_keys(item_type, item_id)
      end
      @sibling_versions
    end

    def next
      @next ||= sibling_versions.subsequent(self).first
    end

    def previous
      @previous ||= sibling_versions.preceding(self).first
    end

    # Returns an integer representing the chronological position of the
    # version among its siblings (see `sibling_versions`). The "create" event,
    # for example, has an index of 0.
    # @api public
    def index
      @index ||= RecordHistory.new(sibling_versions, self.class).index(self)
    end

    # TODO: The `private` method has no effect here. Remove it?
    # AFAICT it is not possible to have private instance methods in a mixin,
    # though private *class* methods are possible.
    private

    # @api private
    def load_changeset
      changes = HashWithIndifferentAccess.new(object_changes_deserialized)
      if PaperTrail.serialized_attributes?
        item_type.constantize.unserialize_attribute_changes_for_paper_trail!(changes)
      end
      changes
    rescue # TODO: Rescue something specific
      {}
    end

    # @api private
    def object_changes_deserialized
      if self.class.object_changes_col_is_json?
        object_changes
      else
        PaperTrail.serializer.load(object_changes)
      end
    end

    # In Rails 3.1+, calling reify on a previous version confuses the
    # IdentityMap, if enabled. This prevents insertion into the map.
    # @api private
    def without_identity_map(&block)
      if defined?(::ActiveRecord::IdentityMap) && ::ActiveRecord::IdentityMap.respond_to?(:without)
        ::ActiveRecord::IdentityMap.without(&block)
      else
        block.call
      end
    end

    # Checks that a value has been set for the `version_limit` config
    # option, and if so enforces it.
    # @api private
    def enforce_version_limit!
      limit = PaperTrail.config.version_limit
      return unless limit.is_a? Numeric
      previous_versions = sibling_versions.not_creates
      return unless previous_versions.size > limit
      excess_versions = previous_versions - previous_versions.last(limit)
      excess_versions.map(&:destroy)
    end
  end
end
