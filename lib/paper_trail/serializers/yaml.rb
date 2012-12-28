require 'yaml'

module PaperTrail
  module Serializers
    class Yaml
      def self.load(string)
        YAML.load string
      end

      def self.dump(hash)
        YAML.dump hash
      end
    end
  end
end
