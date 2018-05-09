# frozen_string_literal: true

require "spec_helper"

RSpec.describe Person, type: :model, versioning: true do
  it "baseline test setup" do
    expect(Person.new).to be_versioned
  end

  describe "#cars and bicycles" do
    it "can be reified" do
      person = Person.create(name: "Frank")
      car = Car.create(name: "BMW 325")
      bicycle = Bicycle.create(name: "BMX 1.0")

      person.car = car
      person.bicycle = bicycle
      person.update_attributes(name: "Steve")

      car.update_attributes(name: "BMW 330")
      bicycle.update_attributes(name: "BMX 2.0")
      person.update_attributes(name: "Peter")

      expect(person.reload.versions.length).to(eq(3))

      # See https://github.com/paper-trail-gem/paper_trail/issues/594
      expect {
        person.reload.versions.second.reify(has_one: true)
      }.to(
        raise_error(::PaperTrail::Reifiers::HasOne::FoundMoreThanOne) do |err|
          expect(err.message.squish).to match(
            /Expected to find one Vehicle, but found 2/
          )
        end
      )
    end
  end
end
