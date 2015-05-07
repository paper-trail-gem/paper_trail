if JsonVersion.table_exists?

  require 'rails_helper'

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
            let(:fruit_names) { %w(apple orange lemon banana lime strawberry blueberry) }
            let(:tropical_fruit_names) { %w(coconut pineapple kiwi mango melon) }
            let(:fruit) { Fruit.new }
            let(:name) { 'pomegranate' }
            let(:color) { Faker::Color.name }

            before do
              fruit.update_attributes!(:name => name)
              fruit.update_attributes!(:name => tropical_fruit_names.sample, :color => color)
              fruit.update_attributes!(:name => fruit_names.sample, :color => Faker::Color.name)
            end

            it "should be able to locate versions according to their `object_changes` contents" do
              expect(fruit.versions.where_object_changes(:name => name)).to eq(fruit.versions[0..1])
              expect(fruit.versions.where_object_changes(:color => color)).to eq(fruit.versions[1..2])
            end

            it "should be able to handle queries for multiple attributes" do
              expect(fruit.versions.where_object_changes(:color => color, :name => name)).to eq([fruit.versions[1]])
            end
          end
        end
      end

    end
  end

end
