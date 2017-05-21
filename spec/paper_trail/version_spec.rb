require "rails_helper"

module PaperTrail
  ::RSpec.describe(Version, versioning: true) do
    describe ".creates" do
      it "returns only create events" do
        animal = Animal.create(name: "Foo")
        animal.update_attributes(name: "Bar")
        expect(described_class.creates.pluck(:event)).to eq(["create"])
      end
    end

    describe ".updates" do
      it "returns only update events" do
        animal = Animal.create
        animal.update_attributes(name: "Animal")
        expect(described_class.updates.pluck(:event)).to eq(["update"])
      end
    end

    describe ".destroys" do
      it "returns only destroy events" do
        animal = Animal.create
        animal.destroy
        expect(described_class.destroys.pluck(:event)).to eq(["destroy"])
      end
    end

    describe ".not_creates" do
      it "returns all versions except create events" do
        animal = Animal.create
        animal.update_attributes(name: "Animal")
        animal.destroy
        expect(described_class.not_creates.pluck(:event)).to eq(%w[update destroy])
      end
    end

    describe ".subsequent" do
      context "given a timestamp" do
        it "returns all versions that were created after the timestamp" do
          animal = Animal.create
          2.times do
            animal.update_attributes(name: FFaker::Lorem.word)
          end
          value = described_class.subsequent(1.hour.ago, true)
          expect(value).to eq(animal.versions.to_a)
          expect(value.to_sql).to match(
            /ORDER BY #{described_class.arel_table[:created_at].asc.to_sql}/
          )
        end
      end

      context "given a Version" do
        it "grab the timestamp from the version and use that as the value" do
          animal = Animal.create
          2.times do
            animal.update_attributes(name: FFaker::Lorem.word)
          end
          expect(described_class.subsequent(animal.versions.first)).to eq(
            animal.versions.to_a.drop(1)
          )
        end
      end
    end

    describe ".preceding" do
      context "given a timestamp" do
        it "returns all versions that were created before the timestamp" do
          animal = Animal.create
          2.times do
            animal.update_attributes(name: FFaker::Lorem.word)
          end
          value = described_class.preceding(5.seconds.from_now, true)
          expect(value).to eq(animal.versions.reverse)
          expect(value.to_sql).to match(
            /ORDER BY #{described_class.arel_table[:created_at].desc.to_sql}/
          )
        end
      end

      context "given a Version" do
        it "grab the timestamp from the version and use that as the value" do
          animal = Animal.create
          2.times do
            animal.update_attributes(name: FFaker::Lorem.word)
          end
          expect(described_class.preceding(animal.versions.last)).to eq(
            animal.versions.to_a.tap(&:pop).reverse
          )
        end
      end
    end
  end
end
