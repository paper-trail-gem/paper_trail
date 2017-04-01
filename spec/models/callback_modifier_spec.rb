require "rails_helper"

describe CallbackModifier, type: :model do
  with_versioning do
    describe "callback-methods", versioning: true do
      describe "paper_trail_on_destroy" do
        it "should add :destroy to paper_trail_options[:on]" do
          modifier = NoArgDestroyModifier.create!(some_content: FFaker::Lorem.sentence)
          expect(modifier.paper_trail_options[:on]).to eq [:destroy]
        end

        context "when :before" do
          it "should create the version before destroy" do
            modifier = BeforeDestroyModifier.create!(some_content: FFaker::Lorem.sentence)
            modifier.test_destroy
            expect(modifier.versions.last.reify).not_to be_flagged_deleted
          end
        end

        context "when :after" do
          it "should create the version after destroy" do
            modifier = AfterDestroyModifier.create!(some_content: FFaker::Lorem.sentence)
            modifier.test_destroy
            expect(modifier.versions.last.reify).to be_flagged_deleted
          end
        end

        context "when no argument" do
          it "should default to before destroy" do
            modifier = NoArgDestroyModifier.create!(some_content: FFaker::Lorem.sentence)
            modifier.test_destroy
            expect(modifier.versions.last.reify).not_to be_flagged_deleted
          end
        end
      end

      describe "paper_trail_on_update" do
        it "should add :update to paper_trail_options[:on]" do
          modifier = UpdateModifier.create!(some_content: FFaker::Lorem.sentence)
          expect(modifier.paper_trail_options[:on]).to eq [:update]
        end

        it "should create a version" do
          modifier = UpdateModifier.create!(some_content: FFaker::Lorem.sentence)
          modifier.update_attributes! some_content: "modified"
          expect(modifier.versions.last.event).to eq "update"
        end
      end

      describe "paper_trail_on_create" do
        it "should add :create to paper_trail_options[:on]" do
          modifier = CreateModifier.create!(some_content: FFaker::Lorem.sentence)
          expect(modifier.paper_trail_options[:on]).to eq [:create]
        end

        it "should create a version" do
          modifier = CreateModifier.create!(some_content: FFaker::Lorem.sentence)
          expect(modifier.versions.last.event).to eq "create"
        end
      end

      context "when no callback-method used" do
        it "should set paper_trail_options[:on] to [:create, :update, :destroy]" do
          modifier = DefaultModifier.create!(some_content: FFaker::Lorem.sentence)
          expect(modifier.paper_trail_options[:on]).to eq %i(create update destroy)
        end

        it "should default to track destroy" do
          modifier = DefaultModifier.create!(some_content: FFaker::Lorem.sentence)
          modifier.destroy
          expect(modifier.versions.last.event).to eq "destroy"
        end

        it "should default to track update" do
          modifier = DefaultModifier.create!(some_content: FFaker::Lorem.sentence)
          modifier.update_attributes! some_content: "modified"
          expect(modifier.versions.last.event).to eq "update"
        end

        it "should default to track create" do
          modifier = DefaultModifier.create!(some_content: FFaker::Lorem.sentence)
          expect(modifier.versions.last.event).to eq "create"
        end
      end

      context "when only one callback-method" do
        it "does only track the corresponding event" do
          modifier = CreateModifier.create!(some_content: FFaker::Lorem.sentence)
          modifier.update_attributes!(some_content: "modified")
          modifier.test_destroy
          expect(modifier.versions.collect(&:event)).to eq ["create"]
        end
      end
    end
  end
end
