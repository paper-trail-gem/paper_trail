# frozen_string_literal: true

require "spec_helper"

RSpec.describe Wotsit, versioning: true do
  it "update! records timestamps" do
    wotsit = described_class.create!(name: "wotsit")
    wotsit.update!(name: "changed")
    reified = wotsit.versions.last.reify
    expect(reified.created_at).not_to(be_nil)
    expect(reified.updated_at).not_to(be_nil)
  end

  it "update! does not raise error" do
    wotsit = described_class.create!(name: "name1")
    expect { wotsit.update!(name: "name2") }.not_to(raise_error)
  end
end
