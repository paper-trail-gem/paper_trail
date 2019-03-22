# frozen_string_literal: true

require "paper_trail/attribute_serializers/object_changes_attribute"
require "paper_trail/queries/versions/where_object"
require "paper_trail/queries/versions/where_object_changes"

module PaperTrail
  # Originally, PaperTrail did not provide this module, and all of this
  # functionality was in `PaperTrail::Version`. That model still exists (and is
  # used by most apps) but by moving the functionality to this module, people
  # can include this concern instead of sub-classing the `Version` model.
  module VersionConcern
    extend ::ActiveSupport::Concern

    included do
      if ::ActiveRecord.gem_version >= Gem::Version.new("5.0")
        belongs_to :item, polymorphic: true, optional: true
      else
        belongs_to :item, polymorphic: true
      end

      validates_presence_of :event
      after_create :enforce_version_limit!
    end

    # :nodoc:
    module ClassMethods
      def item_subtype_column_present?
        column_names.include?("item_subtype")
      end

      def with_item_keys(item_type, item_id)
        where item_type: item_type, item_id: item_id
      end

      def creates
        where event: "create"
      end

      def updates
        where event: "update"
      end

      def destroys
        where event: "destroy"
      end

      def not_creates
        where "event <> ?", "create"
      end

      def between(start_time, end_time)
        where(
          arel_table[:created_at].gt(start_time).
          and(arel_table[:created_at].lt(end_time))
        ).order(timestamp_sort_order)
      end

      # Defaults to using the primary key as the secondary sort order if
      # possible.
      def timestamp_sort_order(direction = "asc")
        [arel_table[:created_at].send(direction.downcase)].tap do |array|
          array << arel_table[primary_key].send(direction.downcase) if primary_key_is_int?
        end
      end

      # Given a hash of attributes like `name: 'Joan'`, query the
      # `versions.objects` column.
      #
      # ```
      # SELECT "versions".*
      # FROM "versions"
      # WHERE ("versions"."object" LIKE '%
      # name: Joan
      # %')
      # ```
      #
      # This is useful for finding versions where a given attribute had a given
      # value. Imagine, in the example above, that Joan had changed her name
      # and we wanted to find the versions before that change.
      #
      # Based on the data type of the `object` column, the appropriate SQL
      # operator is used. For example, a text column will use `like`, and a
      # jsonb column will use `@>`.
      #
      # @api public
      def where_object(args = {})
        raise ArgumentError, "expected to receive a Hash" unless args.is_a?(Hash)
        Queries::Versions::WhereObject.new(self, args).execute
      end

      # Given a hash of attributes like `name: 'Joan'`, query the
      # `versions.objects_changes` column.
      #
      # ```
      # SELECT "versions".*
      # FROM "versions"
      # WHERE .. ("versions"."object_changes" LIKE '%
      # name:
      # - Joan
      # %' OR "versions"."object_changes" LIKE '%
      # name:
      # -%
      # - Joan
      # %')
      # ```
      #
      # This is useful for finding versions immediately before and after a given
      # attribute had a given value. Imagine, in the example above, that someone
      # changed their name to Joan and we wanted to find the versions
      # immediately before and after that change.
      #
      # Based on the data type of the `object` column, the appropriate SQL
      # operator is used. For example, a text column will use `like`, and a
      # jsonb column will use `@>`.
      #
      # @api public
      def where_object_changes(args = {})
        raise ArgumentError, "expected to receive a Hash" unless args.is_a?(Hash)
        Queries::Versions::WhereObjectChanges.new(self, args).execute
      end

      def primary_key_is_int?
        @primary_key_is_int ||= columns_hash[primary_key].type == :integer
      rescue StandardError # TODO: Rescue something more specific
        true
      end

      # Returns whether the `object` column is using the `json` type supported
      # by PostgreSQL.
      def object_col_is_json?
        %i[json jsonb].include?(columns_hash["object"].type)
      end

      # Returns whether the `object_changes` column is using the `json` type
      # supported by PostgreSQL.
      def object_changes_col_is_json?
        %i[json jsonb].include?(columns_hash["object_changes"].try(:type))
      end

      # Returns versions before `obj`.
      #
      # @param obj - a `Version` or a timestamp
      # @param timestamp_arg - boolean - When true, `obj` is a timestamp.
      #   Default: false.
      # @return `ActiveRecord::Relation`
      # @api public
      def preceding(obj, timestamp_arg = false)
        if timestamp_arg != true && primary_key_is_int?
          preceding_by_id(obj)
        else
          preceding_by_timestamp(obj)
        end
      end

      # Returns versions after `obj`.
      #
      # @param obj - a `Version` or a timestamp
      # @param timestamp_arg - boolean - When true, `obj` is a timestamp.
      #   Default: false.
      # @return `ActiveRecord::Relation`
      # @api public
      def subsequent(obj, timestamp_arg = false)
        if timestamp_arg != true && primary_key_is_int?
          subsequent_by_id(obj)
        else
          subsequent_by_timestamp(obj)
        end
      end

      private

      # @api private
      def preceding_by_id(obj)
        where(arel_table[primary_key].lt(obj.id)).order(arel_table[primary_key].desc)
      end

      # @api private
      def preceding_by_timestamp(obj)
        obj = obj.send(:created_at) if obj.is_a?(self)
        where(arel_table[:created_at].lt(obj)).
          order(timestamp_sort_order("desc"))
      end

      # @api private
      def subsequent_by_id(version)
        where(arel_table[primary_key].gt(version.id)).order(arel_table[primary_key].asc)
      end

      # @api private
      def subsequent_by_timestamp(obj)
        obj = obj.send(:created_at) if obj.is_a?(self)
        where(arel_table[:created_at].gt(obj)).order(timestamp_sort_order)
      end
    end

    # @api private
    def object_deserialized
      if self.class.object_col_is_json?
        object
      else
        PaperTrail.serializer.load(object)
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
      unless self.class.column_names.include? "object"
        raise "reify can't be called without an object column"
      end
      return nil if object.nil?
      ::PaperTrail::Reifier.reify(self, options)
    end

    # Returns what changed in this version of the item.
    # `ActiveModel::Dirty#changes`. returns `nil` if your `versions` table does
    # not have an `object_changes` text column.
    def changeset
      return nil unless self.class.column_names.include? "object_changes"
      @changeset ||= load_changeset
    end

    # Returns who put the item into the state stored in this version.
    def paper_trail_originator
      @paper_trail_originator ||= previous.try(:whodunnit)
    end

    # Returns who changed the item from the state it had in this version. This
    # is an alias for `whodunnit`.
    def terminator
      @terminator ||= whodunnit
    end
    alias version_author terminator

    def sibling_versions(reload = false)
      if reload || !defined?(@sibling_versions) || @sibling_versions.nil?
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

    private

    # @api private
    def load_changeset
      if PaperTrail.config.object_changes_adapter&.respond_to?(:load_changeset)
        return PaperTrail.config.object_changes_adapter.load_changeset(self)
      end

      # First, deserialize the `object_changes` column.
      changes = HashWithIndifferentAccess.new(object_changes_deserialized)

      # The next step is, perhaps unfortunately, called "de-serialization",
      # and appears to be responsible for custom attribute serializers. For an
      # example of a custom attribute serializer, see
      # `Person::TimeZoneSerializer` in the test suite.
      #
      # Is `item.class` good enough? Does it handle `inheritance_column`
      # as well as `Reifier#version_reification_class`? We were using
      # `item_type.constantize`, but that is problematic when the STI parent
      # is not versioned. (See `Vehicle` and `Car` in the test suite).
      #
      # Note: `item` returns nil if `event` is "destroy".
      unless item.nil?
        AttributeSerializers::ObjectChangesAttribute.
          new(item.class).
          deserialize(changes)
      end

      # Finally, return a Hash mapping each attribute name to
      # a two-element array representing before and after.
      changes
    end

    # If the `object_changes` column is a Postgres JSON column, then
    # ActiveRecord will deserialize it for us. Otherwise, it's a string column
    # and we must deserialize it ourselves.
    # @api private
    def object_changes_deserialized
      if self.class.object_changes_col_is_json?
        object_changes
      else
        begin
          PaperTrail.serializer.load(object_changes)
        rescue StandardError # TODO: Rescue something more specific
          {}
        end
      end
    end

    # Enforces the `version_limit`, if set. Default: no limit.
    # @api private
    def enforce_version_limit!
      limit = version_limit
      return unless limit.is_a? Numeric
      previous_versions = sibling_versions.not_creates.
        order(self.class.timestamp_sort_order("asc"))
      return unless previous_versions.size > limit
      excess_versions = previous_versions - previous_versions.last(limit)
      excess_versions.map(&:destroy)
    end

    # See docs section 2.e. Limiting the Number of Versions Created.
    # The version limit can be global or per-model.
    #
    # @api private
    #
    # TODO: Duplication: similar `constantize` in Reifier#version_reification_class
    def version_limit
      if self.class.item_subtype_column_present?
        klass = (item_subtype || item_type).constantize
        if klass&.paper_trail_options&.key?(:limit)
          return klass.paper_trail_options[:limit]
        end
      end
      PaperTrail.config.version_limit
    end
  end
end
