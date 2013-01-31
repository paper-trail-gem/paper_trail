require 'active_support/json'

module PaperTrail
  module Serializers
    module Json
      extend self # makes all instance methods become module methods as well

      def load(string)
        ActiveSupport::JSON.decode string
      end

      def dump(object)
        ActiveSupport::JSON.encode object
      end
    end
  end
end
