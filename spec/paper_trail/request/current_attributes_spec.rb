# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  module Request
    ::RSpec.describe CurrentAttributes.new do
      describe ".enabled_for" do
        context "when enabled_for is nil" do
          it "sets enabled_for to an empty hash to and returns it" do
            expect(described_class.attributes[:enabled_for]).to be_nil
            expect(described_class.enabled_for).to eq({})
            expect(described_class.attributes[:enabled_for]).to eq({})
          end
        end
      end

      describe ".controller_info" do
        context "when controller_info is nil" do
          it "sets controller_info to an empty hash to and returns it" do
            expect(described_class.attributes[:controller_info]).to be_nil
            expect(described_class.controller_info).to eq({})
            expect(described_class.attributes[:controller_info]).to eq({})
          end
        end
      end
    end
  end
end
