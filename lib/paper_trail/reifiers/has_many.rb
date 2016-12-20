module PaperTrail
  module Reifiers
    # Reify a single, direct (not `through`) `has_many` association of `model`.
    # @api private
    module HasMany
      class << self
        # @api private
        def reify(assoc, model, options, transaction_id, version_table_name)
          versions = load_versions_for_hm_association(
            assoc,
            model,
            version_table_name,
            transaction_id,
            options[:version_at]
          )
          collection = Array.new model.send(assoc.name).reload # to avoid cache
          prepare_array(collection, options, versions)
          model.send(assoc.name).proxy_association.target = collection
        end

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
        def prepare_array(array, options, versions)
          # Iterate each child to replace it with the previous value if there is
          # a version after the timestamp.
          array.map! do |record|
            if (version = versions.delete(record.id)).nil?
              record
            elsif version.event == "create"
              options[:mark_for_destruction] ? record.tap(&:mark_for_destruction) : nil
            else
              version.reify(
                options.merge(
                  has_many: false,
                  has_one: false,
                  belongs_to: false,
                  has_and_belongs_to_many: false
                )
              )
            end
          end

          # Reify the rest of the versions and add them to the collection, these
          # versions are for those that have been removed from the live
          # associations.
          array.concat(
            versions.values.map { |v|
              v.reify(
                options.merge(
                  has_many: false,
                  has_one: false,
                  belongs_to: false,
                  has_and_belongs_to_many: false
                )
              )
            }
          )

          array.compact!

          nil
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
            paper_trail.version_class.
            where("id IN (#{version_id_subquery})").
            inject({}) { |a, e| a.merge!(e.item_id => e) }
        end

        private

        # Given a `has_many` association on `model`, return the version records
        # from the point in time identified by `tx_id` or `version_at`.
        # @api private
        def load_versions_for_hm_association(assoc, model, version_table, tx_id, version_at)
          version_id_subquery = ::PaperTrail::VersionAssociation.
            joins(model.class.version_association_name).
            select("MIN(version_id)").
            where("foreign_key_name = ?", assoc.foreign_key).
            where("foreign_key_id = ?", model.id).
            where("#{version_table}.item_type = ?", assoc.class_name).
            where("created_at >= ? OR transaction_id = ?", version_at, tx_id).
            group("item_id").
            to_sql
          versions_by_id(model.class, version_id_subquery)
        end
      end
    end
  end
end
