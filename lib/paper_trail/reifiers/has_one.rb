# frozen_string_literal: true

module PaperTrail
  module Reifiers
    # Reify a single `has_one` association of `model`.
    # @api private
    module HasOne
      # A more helpful error message, instead of the AssociationTypeMismatch
      # you would get if, eg. we were to try to assign a Bicycle to the :car
      # association (before, if there were multiple records we would just take
      # the first and hope for the best).
      # @api private
      class FoundMoreThanOne < RuntimeError
        MESSAGE_FMT = <<~STR
          Unable to reify has_one association. Expected to find one %s,
          but found %d.

          This is a known issue, and a good example of why association tracking
          is an experimental feature that should not be used in production.

          That said, this is a rare error. In spec/models/person_spec.rb we
          reproduce it by having two STI models with the same foreign_key (Car
          and Bicycle are both Vehicles and the FK for both is owner_id)

          If you'd like to help fix this error, please read
          https://github.com/paper-trail-gem/paper_trail/issues/594
          and see spec/models/person_spec.rb
        STR

        def initialize(base_class_name, num_records_found)
          @base_class_name = base_class_name.to_s
          @num_records_found = num_records_found.to_i
        end

        def message
          format(MESSAGE_FMT, @base_class_name, @num_records_found)
        end
      end

      class << self
        # @api private
        def reify(assoc, model, options, transaction_id)
          version = load_version(assoc, model, transaction_id, options[:version_at])
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
        def load_version(assoc, model, transaction_id, version_at)
          base_class_name = assoc.klass.base_class.name
          versions = load_versions(assoc, model, transaction_id, version_at, base_class_name)
          case versions.length
          when 0
            nil
          when 1
            versions.first
          else
            case PaperTrail.config.association_reify_error_behaviour.to_s
            when "warn"
              version = versions.first
              version.logger&.warn(
                FoundMoreThanOne.new(base_class_name, versions.length).message
              )
              version
            when "ignore"
              versions.first
            else # "error"
              raise FoundMoreThanOne.new(base_class_name, versions.length)
            end
          end
        end

        # @api private
        def load_versions(assoc, model, transaction_id, version_at, base_class_name)
          version_table_name = model.class.paper_trail.version_class.table_name
          model.class.paper_trail.version_class.joins(:version_associations).
            where("version_associations.foreign_key_name = ?", assoc.foreign_key).
            where("version_associations.foreign_key_id = ?", model.id).
            where("#{version_table_name}.item_type = ?", base_class_name).
            where("created_at >= ? OR transaction_id = ?", version_at, transaction_id).
            order("#{version_table_name}.id ASC").
            load
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
