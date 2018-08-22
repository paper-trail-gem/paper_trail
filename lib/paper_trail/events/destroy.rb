# frozen_string_literal: true

require "paper_trail/events/base"

module PaperTrail
  module Events
    # See docs in `Base`.
    #
    # @api private
    class Destroy < Base
      # Return attributes of nascent `Version` record.
      #
      # @api private
      def data
        data = {
          item_id: @record.id,
          item_type: @record.class.base_class.name,
          event: @record.paper_trail_event || "destroy",
          whodunnit: PaperTrail.request.whodunnit
        }
        if record_object?
          data[:object] = recordable_object(false)
        end
        if record_object_changes?
          # Rails' implementation returns nothing on destroy :/
          changes = @record.attributes.map { |attr, value| [attr, [value, nil]] }.to_h
          data[:object_changes] = prepare_object_changes(changes)
        end
        merge_metadata_into(data)
      end
    end
  end
end
