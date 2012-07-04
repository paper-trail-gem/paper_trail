require 'yaml'

module PaperTrail
  module Serializers
    class Yaml
      def self.load(string)
        new.load(string)
      end

      def self.dump(hash)
        new.dump(hash)
      end

      def load(string)
        YAML.load(string)
      end

      def dump(hash)
        YAML.dump(hash)
      end
    end
  end
end