# frozen_string_literal: true

require "spec_helper"

module Family
  RSpec.describe Family, type: :model, versioning: true do
    describe "#reify" do
      context "belongs_to" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "parent1")
          parent.children.build(name: "child1")
          parent.save!
          parent.update_attributes!(
            name: "parent2",
            children_attributes: { id: parent.children.first.id, name: "child2" }
          )
          last_child_version = parent.children.first.versions.last

          # We expect `reify` to look for item_type 'Family::Family', not
          # '::Family::Family'. See PR #996
          previous_children = last_child_version.reify(belongs_to: true)
          expect(previous_children.parent.name).to eq "parent1"
        end
      end

      context "has_many" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "parent1")
          parent.children.build(name: "child1")
          parent.save!
          parent.name = "parent2"
          parent.children.build(name: "child2")
          parent.save!

          # We expect `reify` to look for item_type 'Family::Family', not
          # '::Family::Family'. See PR #996
          previous_parent = parent.versions.last.reify(has_many: true)
          previous_children = previous_parent.children
          expect(previous_children.size).to eq 1
          expect(previous_children.first.name).to eq "child1"
        end
      end

      context "has_many through" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "parent1")
          parent.grandsons.build(name: "grandson1")
          parent.save!
          parent.name = "parent2"
          parent.grandsons.build(name: "grandson2")
          parent.save!

          # We expect `reify` to look for item_type 'Family::Family', not
          # '::Family::Family'. See PR #996
          previous_parent = parent.versions.last.reify(has_many: true)
          previous_grandsons = previous_parent.grandsons
          expect(previous_grandsons.size).to eq 1
          expect(previous_grandsons.first.name).to eq "grandson1"
        end
      end

      context "has_one" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "parent1")
          parent.build_mentee(name: "partner1")
          parent.save!
          parent.update_attributes(
            name: "parent2",
            mentee_attributes: { id: parent.mentee.id, name: "partner2" }
          )

          # We expect `reify` to look for item_type 'Family::Family', not
          # '::Family::Family'. See PR #996
          previous_parent = parent.versions.last.reify(has_one: true)
          previous_partner = previous_parent.mentee
          expect(previous_partner.name).to eq "partner1"
        end
      end
    end
  end
end
