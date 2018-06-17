# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pet, type: :model, versioning: true do
  it "baseline test setup" do
    expect(Pet.new).to be_versioned
  end

  it "can reify successfully" do
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
    # (A fix in PT_AT to better reify STI tables and thus have these next two
    # examples function is in the works. -- @LorinT)
    # As a side-effect to the fix for Issue #594, this errantly brings back Beethoven...
    # expect(second_version.animals.first.name).to(eq("Snoopy"))
    # ... and this errantly brings back Sylvester.
    # expect(second_version.animals.second.name).to(eq("Garfield"))
    expect(second_version.dogs.first.name).to(eq("Snoopy"))
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

  it "can reify a subclassed item when item_type refers to the base_class" do
    cat = Cat.create(name: "Garfield")        # Index 0
    cat.update_attributes(name: "Sylvester")  # Index 1 - second
    cat.update_attributes(name: "Cheshire")   # Index 2 - third
    cat.destroy                               # Index 3 - fourth
    # With PT <= v9.1 a subclassed version's item_type referred to the base_class, but
    # now it refers to the class itself.  In order to simulate an entry having been made
    # in the old way, set one of our versions to be "Animal" instead of "Cat".
    versions = PaperTrail::Version.order(:id)
    versions.second.update(item_type: cat.class.base_class.name)

    animal = Animal.create                    # Index 4
    animal.update(name: "Muppets Drummer")    # Index 5
    animal.destroy                            # Index 6

    versions = PaperTrail::Version.order(:id)

    # Still the reification process correctly brings back Cat since `species` is
    # properly set to this sub-classed name.
    expect(versions.second.reify).to be_a(Cat) # Sylvester
    expect(versions.third.reify).to be_a(Cat) # Cheshire
    expect(versions.fourth.reify).to be_a(Cat) # Cheshire that was destroyed

    # Creating an object from the base class is correctly identified as "Animal"
    expect(versions[5].reify).to be_an(Animal) # Muppets Drummer
    expect(versions[6].reify).to be_an(Animal) # Animal that was destroyed
  end
end
