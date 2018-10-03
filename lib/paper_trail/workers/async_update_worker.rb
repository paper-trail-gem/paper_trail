# frozen_string_literal: true

module PaperTrail
  module Workers
    class AsyncUpdateWorker
      include Sidekiq::Worker

      sidekiq_options retry: 0, queue: :audit

      def perform(record_hash, class_name, data_to_merge, old_object = nil, is_touch = false, force = false)
        record = class_name.constantize.new(record_hash)
        event = Events::Update.new(record, true, is_touch, force)
        data = event.data.merge(item_type: class_name, item_id: record.id)
        data = data.merge(data_to_merge)
        data[:object] = old_object
        data[:object] = PaperTrail.serializer.dump(record.attributes) if is_touch
        return if event.changed_notably?
        Version.create(data)
      end
    end
  end
end
