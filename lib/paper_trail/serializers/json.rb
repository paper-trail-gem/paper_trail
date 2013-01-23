require 'active_support/json'

module PaperTrail
  module Serializers
    module Json
      def self.load(string)
        ActiveSupport::JSON.decode string
      end

      def self.dump(hash)
        ActiveSupport::JSON.encode hash
      end
    end
  end
end
