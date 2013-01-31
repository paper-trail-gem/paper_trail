require 'active_support/json'

module PaperTrail
  module Serializers
    module Json
      def self.load(string)
        ActiveSupport::JSON.decode string
      end

      def self.dump(object)
        ActiveSupport::JSON.encode object
      end
    end
  end
end
