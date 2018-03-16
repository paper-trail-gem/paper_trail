# frozen_string_literal: true

require "spec_helper"
require_dependency "on/create"

module On
  RSpec.describe Touch, type: :model, versioning: true do
    describe "#create" do
      it "does not create a version" do
        record = described_class.create(name: "Alice")
        expect(record.versions.count).to eq(0)
      end
    end

    describe "#touch" do
      it "creates a version" do
        record = described_class.create(name: "Alice")
        expect { record.touch }.to(
          change { record.versions.count }.by(+1)
        )
        expect(record.versions.last.event).to eq("update")
      end
    end

    describe "#update" do
      it "does not create a version" do
        record = described_class.create(name: "Alice")
        record.update(name: "Andrew")
        expect(record.versions.count).to eq(0)
      end
    end
  end
end
