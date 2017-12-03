module PaperTrail
  module Sidekiq
    # Can be added to the sidekiq server middleware chain to enable paper trail in sidekiq easily
    class TaggingMiddleware
      def initialize(config)
        @config = config
      end

      def call(_worker, _msg, _queue)
        PaperTrail.with_paper_trail_config(@config) do
          yield
        end
      end
    end
  end
end
