require "rails_helper"

# The `json_versions` table tests postgres' `json` data type. So, that
# table is only created when testing against postgres and ActiveRecord >= 4.
if JsonVersion.table_exists?
  RSpec.describe JsonVersion, type: :model do
    it "includes the VersionConcern module" do
      expect(described_class).to include(PaperTrail::VersionConcern)
    end

    describe "Methods" do
      describe "Class" do
        describe "#where_object" do
          it { expect(described_class).to respond_to(:where_object) }

          it "escapes values" do
            f = Fruit.create(name: "Bobby")
            expect(
              f.
                versions.
                where_object(name: "Robert'; DROP TABLE Students;--").
                count
            ).to eq(0)
          end

          context "invalid arguments" do
            it "raises an error" do
              expect { described_class.where_object(:foo) }.to raise_error(ArgumentError)
              expect { described_class.where_object([]) }.to raise_error(ArgumentError)
            end
          end

          context "valid arguments", versioning: true do
            let(:fruit_names) { %w(apple orange lemon banana lime coconut strawberry blueberry) }
            let(:fruit) { Fruit.new }
            let(:name) { "pomegranate" }
            let(:color) { FFaker::Color.name }

            before do
              fruit.update_attributes!(name: name)
              fruit.update_attributes!(name: fruit_names.sample, color: color)
              fruit.update_attributes!(name: fruit_names.sample, color: FFaker::Color.name)
            end

            it "locates versions according to their `object` contents" do
              expect(described_class.where_object(name: name)).to eq([fruit.versions[1]])
              expect(described_class.where_object(color: color)).to eq([fruit.versions[2]])
            end
          end
        end

        describe "#where_object_changes" do
          it { expect(described_class).to respond_to(:where_object_changes) }

          it "escapes values" do
            f = Fruit.create(name: "Bobby")
            expect(
              f.
                versions.
                where_object_changes(name: "Robert'; DROP TABLE Students;--").
                count
            ).to eq(0)
          end

          context "invalid arguments" do
            it "raises an error" do
              expect { described_class.where_object_changes(:foo) }.to raise_error(ArgumentError)
              expect { described_class.where_object_changes([]) }.to raise_error(ArgumentError)
            end
          end

          context "valid arguments", versioning: true do
            let(:color) { %w(red green) }
            let(:fruit) { Fruit.create!(name: name[0]) }
            let(:name) { %w(banana kiwi mango) }

            before do
              fruit.update_attributes!(name: name[1], color: color[0])
              fruit.update_attributes!(name: name[2], color: color[1])
            end

            it "finds versions according to their `object_changes` contents" do
              expect(
                fruit.versions.where_object_changes(name: name[0])
              ).to match_array(fruit.versions[0..1])
              expect(
                fruit.versions.where_object_changes(color: color[0])
              ).to match_array(fruit.versions[1..2])
            end

            it "finds versions with multiple attributes changed" do
              expect(
                fruit.versions.where_object_changes(color: color[0], name: name[0])
              ).to match_array([fruit.versions[1]])
            end
          end
        end
      end
    end
  end
end
