# frozen_string_literal: true

require "spec_helper"

RSpec.describe JoinedVersion, versioning: true do
  let(:widget) { Widget.create!(name: FFaker::Name.name) }
  let(:version) { described_class.first }

  describe "default_scope" do
    it { expect(described_class.default_scopes).not_to be_empty }
  end

  describe "VersionConcern::ClassMethods" do
    before { widget } # persist a widget

    describe "#subsequent" do
      it "does not raise error when there is a default_scope that joins" do
        described_class.subsequent(version).first
      end
    end

    describe "#preceding" do
      it "does not raise error when there is a default scope that joins" do
        described_class.preceding(version).first
      end
    end

    describe "#between" do
      it "does not raise error when there is a default scope that joins" do
        described_class.between(Time.current, 1.minute.from_now).first
      end
    end
  end

  describe "#index" do
    it { is_expected.to respond_to(:index) }

    it "does not raise error when there is a default scope that joins" do
      widget # persist a widget
      version.index
    end
  end
end
