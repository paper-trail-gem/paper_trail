# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe ModelConfig do
    describe "has_paper_trail" do
      describe "passing an abstract class to class_name" do
        it "raises an error" do
          expect {
            Class.new(ActiveRecord::Base) do
              has_paper_trail class_name: "AbstractVersion"
            end
          }.to raise_error(
            /use concrete \(not abstract\) version models/
          )
        end
      end

      describe "versions:" do
        it "name can be passed instead of an options hash" do
          klass = Class.new(ActiveRecord::Base) do
            has_paper_trail versions: :drafts
          end
          expect(klass.reflect_on_association(:drafts)).to be_a(
            ActiveRecord::Reflection::HasManyReflection
          )
        end
        it "name can be passed in the options hash" do
          klass = Class.new(ActiveRecord::Base) do
            has_paper_trail versions: { name: :drafts }
          end
          expect(klass.reflect_on_association(:drafts)).to be_a(
            ActiveRecord::Reflection::HasManyReflection
          )
        end
        it "allows any option that has_many supports" do
          klass = Class.new(ActiveRecord::Base) do
            has_paper_trail versions: { autosave: true, validate: true }
          end
          expect(klass.reflect_on_association(:versions).options[:autosave]).to eq true
          expect(klass.reflect_on_association(:versions).options[:validate]).to eq true
        end
        it "can even override options that PaperTrail adds to has_many" do
          klass = Class.new(ActiveRecord::Base) do
            has_paper_trail versions: { as: :foo }
          end
          expect(klass.reflect_on_association(:versions).options[:as]).to eq :foo
        end
        it "raises an error on unknown has_many options" do
          expect {
            Class.new(ActiveRecord::Base) do
              has_paper_trail versions: { read_my_mind: true, validate: true }
            end
          }.to raise_error(
            /Unknown key: :read_my_mind. Valid keys are: .*:class_name,/
          )
        end
      end
    end
  end
end
