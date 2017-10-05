module PaperTrail
  module Reifiers
    # Reify a single `has_one` association of `model`.
    # @api private
    module HasOne
      class << self
        # @api private
        def reify(assoc, model, options, transaction_id)
          version = load_version_for_has_one(assoc, model, transaction_id, options[:version_at])
          return unless version
          if version.event == "create"
            create_event(assoc, model, options)
          else
            noncreate_event(assoc, model, options, version)
          end
        end

        private

        # @api private
        def create_event(assoc, model, options)
          if options[:mark_for_destruction]
            model.send(assoc.name).mark_for_destruction if model.send(assoc.name, true)
          else
            model.paper_trail.appear_as_new_record do
              model.send "#{assoc.name}=", nil
            end
          end
        end

        # Given a has-one association `assoc` on `model`, return the version
        # record from the point in time identified by `transaction_id` or `version_at`.
        # @api private
        def load_version_for_has_one(assoc, model, transaction_id, version_at)
          version_table_name = model.class.paper_trail.version_class.table_name
          model.class.paper_trail.version_class.joins(:version_associations).
            where("version_associations.foreign_key_name = ?", assoc.foreign_key).
            where("version_associations.foreign_key_id = ?", model.id).
            where("#{version_table_name}.item_type = ?", assoc.klass.name).
            where("created_at >= ? OR transaction_id = ?", version_at, transaction_id).
            order("#{version_table_name}.id ASC").
            first
        end

        # @api private
        def noncreate_event(assoc, model, options, version)
          child = version.reify(
            options.merge(
              has_many: false,
              has_one: false,
              belongs_to: false,
              has_and_belongs_to_many: false
            )
          )
          model.paper_trail.appear_as_new_record do
            without_persisting(child) do
              model.send "#{assoc.name}=", child
            end
          end
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
end
