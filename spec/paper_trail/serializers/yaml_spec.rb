# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module Serializers
    ::RSpec.describe(YAML, versioning: true) do
      let(:array) { ::Array.new(10) { ::FFaker::Lorem.word } }
      let(:hash) {
        {
          alice: "bob",
          binary: 0xdeadbeef,
          octal_james_bond: 0o7,
          int: 42,
          float: 4.2
        }
      }
      let(:hash_with_indifferent_access) { ActiveSupport::HashWithIndifferentAccess.new(hash) }

      describe ".load" do
        it "deserializes YAML to Ruby" do
          expect(described_class.load(hash.to_yaml)).to eq(hash)
          expect(described_class.load(array.to_yaml)).to eq(array)
        end

        it "calls the expected load method based on Psych version" do
          # `use_yaml_unsafe_load` was added in 5.2.8.1, 6.0.5.1, 6.1.6.1, and 7.0.3.1
          if rails_supports_safe_load?
            allow(::YAML).to receive(:safe_load)
            described_class.load("string")
            expect(::YAML).to have_received(:safe_load)
            # Psych 4+ implements .unsafe_load
          elsif ::YAML.respond_to?(:unsafe_load)
            allow(::YAML).to receive(:unsafe_load)
            described_class.load("string")
            expect(::YAML).to have_received(:unsafe_load)
          else # Psych < 4
            allow(::YAML).to receive(:load)
            described_class.load("string")
            expect(::YAML).to have_received(:load)
          end
        end
      end

      describe ".dump" do
        it "serializes Ruby to YAML" do
          expect(described_class.dump(hash)).to eq(hash.to_yaml)
          expect(described_class.dump(hash_with_indifferent_access)).
            to eq(hash.stringify_keys.to_yaml)
          expect(described_class.dump(array)).to eq(array.to_yaml)
        end
      end

      describe ".where_object" do
        it "constructs the correct WHERE query" do
          matches = described_class.where_object_condition(
            ::PaperTrail::Version.arel_table[:object], :arg1, "Val 1"
          )
          expect(matches.instance_of?(Arel::Nodes::Matches)).to(eq(true))
          expect(arel_value(matches.right)).to eq("%\narg1: Val 1\n%")
        end
      end

      private

      def rails_supports_safe_load?
        # Rails 7.0.3.1 onwards will always support YAML safe loading
        return true if ::ActiveRecord.gem_version >= Gem::Version.new("7.0.3.1")

        # Older Rails versions may or may not, depending on whether they have been patched.
        defined?(ActiveRecord::Base.use_yaml_unsafe_load)
      end
    end
  end
end
