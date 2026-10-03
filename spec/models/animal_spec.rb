# frozen_string_literal: true

require "spec_helper"

RSpec.describe Animal, :versioning do
  it "baseline test setup" do
    expect(described_class.new).to be_versioned
    expect(described_class.inheritance_column).to eq("species")
  end

  describe "#descends_from_active_record?" do
    it "returns true, meaning that Animal is not an STI subclass" do
      expect(described_class.descends_from_active_record?).to eq(true)
    end
  end

  it "works with custom STI inheritance column" do
    animal = described_class.create(name: "Animal")
    animal.update(name: "Animal from the Muppets")
    animal.update(name: "Animal Muppet")
    animal.destroy
    dog = Dog.create(name: "Snoopy")
    dog.update(name: "Scooby")
    dog.update(name: "Scooby Doo")
    dog.destroy
    cat = Cat.create(name: "Garfield")
    cat.update(name: "Garfield (I hate Mondays)")
    cat.update(name: "Garfield The Cat")
    cat.destroy
    expect(PaperTrail::Version.count).to(eq(12))
    expect(animal.versions.count).to(eq(4))
    expect(animal.versions.first.reify).to(be_nil)
    animal.versions[(1..-1)].each do |v|
      expect(v.reify.class.name).to(eq("Animal"))
    end
    dog_versions = PaperTrail::Version.where(item_id: dog.id).order(:created_at)
    expect(dog_versions.count).to(eq(4))
    expect(dog_versions.first.reify).to(be_nil)
    expect(dog_versions.map { |v| v.reify.class.name }).to eq(%w[NilClass Dog Dog Dog])
    cat_versions = PaperTrail::Version.where(item_id: cat.id).order(:created_at)
    expect(cat_versions.count).to(eq(4))
    expect(cat_versions.first.reify).to(be_nil)
    expect(cat_versions.map { |v| v.reify.class.name }).to eq(%w[NilClass Cat Cat Cat])
  end

  it "allows the inheritance_column (species) to be updated" do
    cat = Cat.create!(name: "Leo")
    cat.update(name: "Spike", species: "Dog")
    dog = described_class.find(cat.id)
    expect(dog).to be_instance_of(Dog)
  end

  describe "reifying ignored columns" do
    let(:attributes) { { "species" => "NamelessAnimal", "name" => "Historical name" } }
    let(:version) do
      PaperTrail::Version.new(
        item_type: "Animal",
        event: "update",
        object: PaperTrail.serializer.dump(attributes)
      )
    end

    [false, true].each do |dup|
      it "skips ignored columns with an inherited setter when dup is #{dup}" do
        expect(NamelessAnimal.new).to respond_to(:name=)

        reified = version.reify(dup: dup)

        expect(reified).to be_an_instance_of(NamelessAnimal)
        expect(reified.species).to eq("NamelessAnimal")
        expect(reified).not_to have_attribute("name")
        expect(version.object_deserialized).to eq(attributes)
      end
    end

    it "skips ignored columns when reifying a destroyed record" do
      version.event = "destroy"

      expect(version.reify).not_to have_attribute("name")
    end

    it "skips ignored columns stored with symbol keys" do
      attributes[:name] = attributes.delete("name")

      expect(version.reify(dup: true)).not_to have_attribute("name")
      expect(version.object_deserialized).to eq(attributes)
    end

    it "restores the column for a sibling subclass that does not ignore it" do
      attributes["species"] = "Dog"

      reified = version.reify(dup: true)

      expect(reified).to be_an_instance_of(Dog)
      expect(reified.name).to eq("Historical name")
    end
  end

  context "with callback-methods" do
    context "when only has_paper_trail set in super class" do
      let(:callback_cat) { Cat.create(name: "Markus") }

      it "trails all events" do
        callback_cat.update(name: "Billie")
        callback_cat.destroy
        expect(callback_cat.versions.collect(&:event)).to eq %w[create update destroy]
      end

      it "does not break reify" do
        callback_cat.destroy
        expect { callback_cat.versions.last.reify }.not_to raise_error
      end
    end
  end
end
