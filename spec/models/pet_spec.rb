# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pet, type: :model, versioning: true do
  it "baseline test setup" do
    expect(Pet.new).to be_versioned
  end

  it "can be reified" do
    person = Person.create(name: "Frank")
    dog = Dog.create(name: "Snoopy")
    cat = Cat.create(name: "Garfield")

    person.pets << Pet.create(animal: dog)
    person.pets << Pet.create(animal: cat)
    person.update_attributes(name: "Steve")

    dog.update_attributes(name: "Beethoven")
    cat.update_attributes(name: "Sylvester")
    person.update_attributes(name: "Peter")

    expect(person.reload.versions.length).to(eq(3))

    second_version = person.reload.versions.second.reify(has_many: true)
    expect(second_version.pets.length).to(eq(2))
    expect(second_version.animals.length).to(eq(2))
    expect(second_version.animals.map { |a| a.class.name }).to(eq(%w[Dog Cat]))
    expect(second_version.pets.map { |p| p.animal.class.name }).to(eq(%w[Dog Cat]))
    expect(second_version.animals.first.name).to(eq("Snoopy"))
    expect(second_version.dogs.first.name).to(eq("Snoopy"))
    expect(second_version.animals.second.name).to(eq("Garfield"))
    expect(second_version.cats.first.name).to(eq("Garfield"))

    last_version = person.reload.versions.last.reify(has_many: true)
    expect(last_version.pets.length).to(eq(2))
    expect(last_version.animals.length).to(eq(2))
    expect(last_version.animals.map { |a| a.class.name }).to(eq(%w[Dog Cat]))
    expect(last_version.pets.map { |p| p.animal.class.name }).to(eq(%w[Dog Cat]))
    expect(last_version.animals.first.name).to(eq("Beethoven"))
    expect(last_version.dogs.first.name).to(eq("Beethoven"))
    expect(last_version.animals.second.name).to(eq("Sylvester"))
    expect(last_version.cats.first.name).to(eq("Sylvester"))
  end
end
