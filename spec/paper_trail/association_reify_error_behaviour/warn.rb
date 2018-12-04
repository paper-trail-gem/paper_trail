# frozen_string_literal: true

require "spec_helper"

RSpec.describe PaperTrail, versioning: true do
  it "baseline test setup" do
    expect(Person.new).to be_versioned
  end

  # See https://github.com/paper-trail-gem/paper_trail/issues/594
  describe "#association reify error behaviour" do
    it "association reify error behaviour = :warn" do
      ::PaperTrail.config.association_reify_error_behaviour = :warn

      person = Person.create(name: "Frank")
      thing = Thing.create(name: "BMW 325")
      thing2 = Thing.create(name: "BMX 1.0")

      person.thing = thing
      person.thing_2 = thing2
      person.update(name: "Steve")

      thing.update(name: "BMW 330")
      thing.update(name: "BMX 2.0")
      person.update(name: "Peter")

      expect(person.reload.versions.length).to(eq(3))

      logger = person.versions.first.logger

      allow(logger).to receive(:warn)

      person.reload.versions.second.reify(has_one: true)

      expect(logger).to(
        have_received(:warn).with(/Unable to reify has_one association/).twice
      )
    end
  end
end
