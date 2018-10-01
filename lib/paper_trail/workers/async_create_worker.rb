# frozen_string_literal: true

module PaperTrail
  module Workers
    class AsyncCreateWorker
      include Sidekiq::Worker

      sidekiq_options retry: 0, queue: :audit

      def perform(record_hash, class_name, data_to_merge)
        record = class_name.constantize.new(record_hash)
        event = Events::Create.new(record, true)
        data = event.data.merge(item_type: class_name, item_id: record.id)
        data = data.merge(data_to_merge)
        Version.create(data)
        # TODO: Use correct class to save data
        # versions_assoc = record.send(record.class.versions_association_name)
        # versions_assoc.create!(event.data)
      end
    end
  end
end
