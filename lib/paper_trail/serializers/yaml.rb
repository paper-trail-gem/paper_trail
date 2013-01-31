require 'yaml'

module PaperTrail
  module Serializers
    module Yaml
      def self.load(string)
        YAML.load string
      end

      def self.dump(object)
        YAML.dump object
      end
    end
  end
end
