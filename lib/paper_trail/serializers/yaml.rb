require 'yaml'

module PaperTrail
  module Serializers
    module Yaml
      extend self # makes all instance methods become module methods as well

      def load(string)
        YAML.load string
      end

      def dump(object)
        YAML.dump object
      end
    end
  end
end
