module PaperTrail
  module Reifiers
    # Reify a single HABTM association of `model`.
    # @api private
    module HasAndBelongsToMany
      class << self
        # @api private
        def reify(pt_enabled, assoc, model, options, transaction_id)
          version_ids = ::PaperTrail::VersionAssociation.
            where("foreign_key_name = ?", assoc.name).
            where("version_id = ?", transaction_id).
            pluck(:foreign_key_id)

          model.send(assoc.name).proxy_association.target =
            version_ids.map do |id|
              if pt_enabled
                version = load_version(assoc, id, transaction_id, options[:version_at])
                if version
                  next version.reify(
                    options.merge(
                      has_many: false,
                      has_one: false,
                      belongs_to: false,
                      has_and_belongs_to_many: false
                    )
                  )
                end
              end
              assoc.klass.where(assoc.klass.primary_key => id).first
            end
        end

        private

        # Given a HABTM association `assoc` and an `id`, return a version record
        # from the point in time identified by `transaction_id` or `version_at`.
        # @api private
        def load_version(assoc, id, transaction_id, version_at)
          assoc.klass.paper_trail.version_class.
            where("item_type = ?", assoc.klass.name).
            where("item_id = ?", id).
            where("created_at >= ? OR transaction_id = ?", version_at, transaction_id).
            order("id").
            limit(1).
            first
        end
      end
    end
  end
end
