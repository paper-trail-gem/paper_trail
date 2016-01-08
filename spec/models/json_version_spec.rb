require 'rails_helper'

# The `json_versions` table tests postgres' `json` data type. So, that
# table is only created when testing against postgres and ActiveRecord >= 4.
if JsonVersion.table_exists?

  describe JsonVersion, :type => :model do
    it "should include the `VersionConcern` module to get base functionality" do
      expect(JsonVersion).to include(PaperTrail::VersionConcern)
    end

    describe "Methods" do
      describe "Class" do

        describe '#where_object' do
          it { expect(JsonVersion).to respond_to(:where_object) }

          context "invalid arguments" do
            it "should raise an error" do
              expect { JsonVersion.where_object(:foo) }.to raise_error(ArgumentError)
              expect { JsonVersion.where_object([]) }.to raise_error(ArgumentError)
            end
          end

          context "valid arguments", :versioning => true do
            let(:fruit_names) { %w(apple orange lemon banana lime coconut strawberry blueberry) }
            let(:fruit) { Fruit.new }
            let(:name) { 'pomegranate' }
            let(:color) { Faker::Color.name }

            before do
              fruit.update_attributes!(:name => name)
              fruit.update_attributes!(:name => fruit_names.sample, :color => color)
              fruit.update_attributes!(:name => fruit_names.sample, :color => Faker::Color.name)
            end

            it "should be able to locate versions according to their `object` contents" do
              expect(JsonVersion.where_object(:name => name)).to eq([fruit.versions[1]])
              expect(JsonVersion.where_object(:color => color)).to eq([fruit.versions[2]])
            end
          end
        end

        describe '#where_object_changes' do
          it { expect(JsonVersion).to respond_to(:where_object_changes) }

          context "invalid arguments" do
            it "should raise an error" do
              expect { JsonVersion.where_object_changes(:foo) }.to raise_error(ArgumentError)
              expect { JsonVersion.where_object_changes([]) }.to raise_error(ArgumentError)
            end
          end

          context "valid arguments", :versioning => true do
            let(:color) { %w[red green] }
            let(:fruit) { Fruit.create!(:name => name[0]) }
            let(:name) { %w[banana kiwi mango] }

            before do
              fruit.update_attributes!(:name => name[1], :color => color[0])
              fruit.update_attributes!(:name => name[2], :color => color[1])
            end

            it "finds versions according to their `object_changes` contents" do
              expect(
                fruit.versions.where_object_changes(:name => name[0])
              ).to match_array(fruit.versions[0..1])
              expect(
                fruit.versions.where_object_changes(:color => color[0])
              ).to match_array(fruit.versions[1..2])
            end

            it "finds versions with multiple attributes changed" do
              expect(
                fruit.versions.where_object_changes(:color => color[0], :name => name[0])
              ).to match_array([fruit.versions[1]])
            end
          end
        end
      end
    end
  end
end
