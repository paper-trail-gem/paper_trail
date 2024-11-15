# frozen_string_literal: true

require "spec_helper"

RSpec.describe Wotsit, versioning: true do
  context "when handling attr_readonly attributes" do
    context "without raise_on_assign_to_attr_readonly" do
      before do
        # Rails 7.1 first introduces this setting, and framework_defaults 7.0 has it as false
        if ActiveRecord.respond_to?(:raise_on_assign_to_attr_readonly)
          ActiveRecord.raise_on_assign_to_attr_readonly = false
        end
      end

      it "update! records timestamps" do
        wotsit = described_class.create!(name: "wotsit")
        wotsit.update!(name: "changed")
        reified = wotsit.versions.last.reify
        expect(reified.created_at).not_to(be_nil)
        expect(reified.updated_at).not_to(be_nil)
      end
    end

    if ActiveRecord.respond_to?(:raise_on_assign_to_attr_readonly)
      context "with raise_on_assign_to_attr_readonly enabled" do
        before do
          ActiveRecord.raise_on_assign_to_attr_readonly = true
        end

        it "update! records timestamps" do
          wotsit = described_class.create!(name: "wotsit")
          wotsit.update!(name: "changed")
          reified = wotsit.versions.last.reify
          expect(reified.created_at).not_to(be_nil)
          expect(reified.updated_at).not_to(be_nil)
          expect(reified.name).to eq("wotsit")
        end
      end
    end
  end

  it "update! does not raise error" do
    wotsit = described_class.create!(name: "name1")
    expect { wotsit.update!(name: "name2") }.not_to(raise_error)
  end
end
