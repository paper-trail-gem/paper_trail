# frozen_string_literal: true

require "spec_helper"
require "rails/generators"

RSpec.describe Pet, type: :model, versioning: true do
  it { is_expected.to be_versioned }

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
    # (A fix in PT_AT to better reify STI tables and thus have these next four
    # examples function is in the works. -- @LorinT)

    # As a side-effect to the fix for Issue #594, this errantly brings back Beethoven.
    # expect(second_version.animals.first.name).to(eq("Snoopy"))

    # This will work when PT-AT has PR #5 merged:
    # expect(second_version.dogs.first.name).to(eq("Snoopy"))
    # (specifically needs the base_class removed in reifiers/has_many_through.rb)

    # As a side-effect to the fix for Issue #594, this errantly brings back Sylvester.
    # expect(second_version.animals.second.name).to(eq("Garfield"))

    # This will work when PT-AT has PR #5 merged:
    # expect(second_version.cats.first.name).to(eq("Garfield"))

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

  context "Older version entry present where item_type refers to the base_class" do
    let(:cat) { Cat.create(name: "Garfield") }   # Index 0
    let(:animal) { Animal.create }               # Index 4

    before do
      # This line runs the `let` for :cat, creating two entries
      cat.update_attributes(name: "Sylvester")   # Index 1 - second
      cat.update_attributes(name: "Cheshire")    # Index 2 - third
      cat.destroy                                # Index 3 - fourth
      # Prior to PR#1108 a subclassed version's item_type referred to the base_class, but
      # now it refers to the class itself.  In order to simulate an entry having been made
      # in the old way, set one of our versions to be "Animal" instead of "Cat".
      versions = PaperTrail::Version.order(:id)
      versions.second.update(item_type: cat.class.base_class.name)

      # This line runs the `let` for :animal, creating two entries
      animal.update(name: "Muppets Drummer")    # Index 5
      animal.destroy                            # Index 6
    end

    it "can reify a subclassed item" do
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

    it "has a generator that builds migrations to upgrade older entries" do
      # When using the has_many :versions association, it only finds versions in which
      # item_type refers directly to the subclass name.
      expect(cat.versions.count).to eq(3)
      # To have has_many :versions work properly, you can generate and run a migration
      # that examines all existing models to identify use of STI, then updates all older
      # version entries that may refer to the base_class so they refer to the subclass.
      # (This is the same as running:  rails g paper_trail:update_sti; rails db:migrate)
      migrator = ::PaperTrailSpecMigrator.new
      expect {
        migrator.generate_and_migrate("paper_trail:update_sti", [])
      }.to output(/Associated 1 record to Cat/).to_stdout
      # And now it finds all four changes
      cat_versions = cat.versions.order(:id).to_a
      expect(cat_versions.length).to eq(4)
      expect(cat_versions.map(&:event)).to eq(%w[create update update destroy])

      # And Animal is unaffected
      animal_versions = animal.versions.order(:id).to_a
      expect(animal_versions.length).to eq(3)
      expect(animal_versions.map(&:event)).to eq(%w[create update destroy])
    end

    # After creating a bunch of records above, we change the inheritance_column
    # so that we can demonstrate passing hints to the migration generator.
    context "simulate a historical change to inheritance_column" do
      before do
        Animal.inheritance_column = "species_xyz"
      end

      after do
        # Clean up the temporary switch-up
        Animal.inheritance_column = "species"
      end

      it "no hints given to generator, does not generate the correct migration" do
        # Because of the change to inheritance_column, the generator `rails g
        # paper_trail:update_sti` would be unable to determine the previous
        # inheritance_column, so a generated migration *with no hints* would
        # accomplish nothing.
        migrator = ::PaperTrailSpecMigrator.new
        hints = []
        expect {
          migrator.generate_and_migrate("paper_trail:update_sti", hints)
        }.not_to output(/Associated 1 record to Cat/).to_stdout

        expect(cat.versions.length).to eq(3)
        # And older Cat changes remain stored as Animal.
        expect(PaperTrail::Version.where(item_type: "Animal", item_id: cat.id).count).to eq(1)
      end

      it "giving hints to the generator, updates older entries in a custom way" do
        # Pick up all version IDs regarding our single cat Garfield / Sylvester / Cheshire
        cat_ids = PaperTrail::Version.where(item_type: %w[Animal Cat], item_id: cat.id).
          order(:id).pluck(:id)

        # This time (as opposed to above example) we are going to provide hints
        # to the generator.
        #
        # You can specify custom inheritance_column settings over a range of
        # IDs so that the generated migration will properly update all your historic versions,
        # having them now to refer to the proper subclass.

        # This is the same as running:
        #   rails g paper_trail:update_sti Animal(species):1..4; rails db:migrate
        migrator = ::PaperTrailSpecMigrator.new
        hints = ["Animal(species):#{cat_ids.first}..#{cat_ids.last}"]
        expect {
          migrator.generate_and_migrate("paper_trail:update_sti", hints)
        }.to output(/Associated 1 record to Cat/).to_stdout

        # And now the has_many :versions properly finds all four changes
        cat_versions = cat.versions.order(:id).to_a

        expect(cat_versions.length).to eq(4)
        expect(cat_versions.map(&:event)).to eq(%w[create update update destroy])

        # And Animal is still unaffected
        animal_versions = animal.versions.order(:id).to_a
        expect(animal_versions.length).to eq(3)
        expect(animal_versions.map(&:event)).to eq(%w[create update destroy])
      end
    end
  end
end
