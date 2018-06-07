# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pet, type: :model, versioning: true do
  it "baseline test setup" do
    expect(Pet.new).to be_versioned
  end

  it "should reify successfully" do
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
    # (A fix in PT_AT to better reify STI tables and thus have these next four
    # examples function is in the works. -- @LorinT)

    # As a side-effect to the fix for Issue #594, this errantly brings back Beethoven.
    # expect(second_version.animals.first.name).to(eq("Snoopy"))

    # This will work when PT-AT has PR #5 merged:
    expect(second_version.dogs.first.name).to(eq("Snoopy"))
    # (specifically needs the base_class removed in reifiers/has_many_through.rb)

    # As a side-effect to the fix for Issue #594, this errantly brings back Sylvester.
    # expect(second_version.animals.second.name).to(eq("Garfield"))

    # This will work when PT-AT has PR #5 merged:
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

  it "should reify a subclassed item when item_type refers to the base_class" do
    cat = Cat.create(name: "Garfield")
    cat.update_attributes(name: "Sylvester")
    cat.update_attributes(name: "Cheshire")

    animal = Animal.create
    animal.update(name: "Muppets Drummer")

    # We get back a create and two updates
    versions = PaperTrail::Version.order(:id)
    # Historically ActiveRecord would cause the version's item_type to refer to the
    # base_class, so set one of our versions to use the base_class instead of "Cat"
    versions.second.update(item_type: cat.class.base_class.name)

    # Still the reification process correctly brings back Cat since `species` is
    # properly set to this sub-classed name.
    expect(versions.second.reify).to be_a(Cat) # Sylvester
    expect(versions.third.reify).to be_a(Cat) # Cheshire

    # Creating an object from the base class is correctly identified as "Animal"
    expect(versions.fifth.reify).to be_an(Animal)
  end
end
