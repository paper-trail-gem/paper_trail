module PaperTrail
  module Workers
    class AsyncDestroyWorker
      include Sidekiq::Worker

      sidekiq_options retry: 0, queue: :audit

      def perform(record_hash, class_name, data_to_merge, recording_order)
        record = class_name.constantize.new(record_hash)
        in_after_callback = recording_order == "after"
        event = Events::Destroy.new(record, in_after_callback)
        data = event.data.merge(data_to_merge)
        data[:object] = PaperTrail.serializer.dump(record_hash)
        Version.create(data)
      end
    end
  end
end
