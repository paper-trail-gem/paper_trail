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
          object: recordable_object(false),
          whodunnit: PaperTrail.request.whodunnit
        }
        merge_metadata_into(data)
      end
    end
  end
end
