require "spec_helper"

# The `json_versions` table tests postgres' `json` data type. So, that
# table is only created when testing against postgres.
if JsonVersion.table_exists?
  RSpec.describe JsonVersion, type: :model do
    it "includes the VersionConcern module" do
      expect(described_class).to include(PaperTrail::VersionConcern)
    end

    describe ".where_object" do
      it "escapes values" do
        f = Fruit.create(name: "Bobby")
        expect {
          f.
            versions.
            where_object(name: "Robert'; DROP TABLE Students;--").
            count
        }.not_to raise_error
      end

      context "invalid argument (not a Hash)" do
        it "raises an error" do
          expect { described_class.where_object(:foo) }.to raise_error(ArgumentError)
          expect { described_class.where_object([]) }.to raise_error(ArgumentError)
        end
      end

      context "valid arguments", versioning: true do
        it "locates versions according to their `object` contents" do
          fruit_names = %w[apple orange lemon banana lime coconut strawberry blueberry]
          fruit = Fruit.new
          name = "pomegranate"
          color = FFaker::Color.name
          fruit.update_attributes!(name: name)
          fruit.update_attributes!(name: fruit_names.sample, color: color)
          fruit.update_attributes!(name: fruit_names.sample, color: FFaker::Color.name)
          expect(described_class.where_object(name: name)).to eq([fruit.versions[1]])
          expect(described_class.where_object(color: color)).to eq([fruit.versions[2]])
        end
      end
    end

    describe ".where_object_changes" do
      it "escapes values" do
        f = Fruit.create(name: "Bobby")
        expect {
          f.
            versions.
            where_object_changes(name: "Robert'; DROP TABLE Students;--").
            count
        }.not_to raise_error
      end

      context "invalid argument (not a Hash)" do
        it "raises an error" do
          expect { described_class.where_object_changes(:foo) }.to raise_error(ArgumentError)
          expect { described_class.where_object_changes([]) }.to raise_error(ArgumentError)
        end
      end

      context "valid arguments", versioning: true do
        let(:fruit) { Fruit.create!(name: "banana") }

        before do
          fruit.update_attributes!(name: "kiwi", color: "red")
          fruit.update_attributes!(name: "mango", color: "green")
        end

        it "finds versions according to their `object_changes` contents" do
          expect(
            fruit.versions.where_object_changes(name: "banana")
          ).to match_array(fruit.versions[0..1])
          expect(
            fruit.versions.where_object_changes(color: "red")
          ).to match_array(fruit.versions[1..2])
        end

        it "finds versions with multiple attributes changed" do
          expect(
            fruit.versions.where_object_changes(color: "red", name: "banana")
          ).to match_array([fruit.versions[1]])
        end
      end
    end
  end
end
