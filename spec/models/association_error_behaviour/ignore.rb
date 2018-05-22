# frozen_string_literal: true

require "spec_helper"

RSpec.describe Person, type: :model, versioning: true do
  it "baseline test setup" do
    expect(Person.new).to be_versioned
  end

  # See https://github.com/paper-trail-gem/paper_trail/issues/594
  describe "#association reify error behaviour" do
    it "association reify error behaviour = :ignore" do
      ::PaperTrail.config.association_reify_error_behaviour = :ignore
      person = Person.create(name: "Frank")
      thing = Thing.create(name: "BMW 325")
      thing = Thing.create(name: "BMX 1.0")

      person.thing = thing
      person.thing = thing
      person.update_attributes(name: "Steve")

      thing.update_attributes(name: "BMW 330")
      thing.update_attributes(name: "BMX 2.0")
      person.update_attributes(name: "Peter")

      expect(person.reload.versions.length).to(eq(3))

      expect(person.versions.first.logger).to_not(
        receive(:warn).with(/Unable to reify has_one association/)
      )

      person.reload.versions.second.reify(has_one: true)
    end
  end
end
