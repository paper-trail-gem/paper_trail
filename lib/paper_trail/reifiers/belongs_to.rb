module PaperTrail
  module Reifiers
    # Reify a single `belongs_to` association of `model`.
    # @api private
    module BelongsTo
      class << self
        # @api private
        def reify(assoc, model, options, transaction_id)
          id = model.send(assoc.foreign_key)
          version = load_version(assoc, id, transaction_id, options[:version_at])
          record = load_record(assoc, id, options, version)
          model.send("#{assoc.name}=".to_sym, record)
        end

        private

        # Given a `belongs_to` association and a `version`, return a record that
        # can be assigned in order to reify that association.
        # @api private
        def load_record(assoc, id, options, version)
          if version.nil?
            assoc.klass.where(assoc.klass.primary_key => id).first
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

        # Given a `belongs_to` association and an `id`, return a version record
        # from the point in time identified by `transaction_id` or `version_at`.
        # @api private
        def load_version(assoc, id, transaction_id, version_at)
          assoc.klass.paper_trail.version_class.
            where("item_type = ?", assoc.klass.name).
            where("item_id = ?", id).
            where("created_at >= ? OR transaction_id = ?", version_at, transaction_id).
            order("id").limit(1).first
        end
      end
    end
  end
end
