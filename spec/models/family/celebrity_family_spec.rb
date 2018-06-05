# frozen_string_literal: true

require "spec_helper"

module Family
  RSpec.describe CelebrityFamily, type: :model, versioning: true do
    describe "#reify" do
      context "belongs_to" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "Jermaine Jackson")
          parent.path_to_stardom = "Emulating Motown greats such as the Temptations and The Supremes"
          child1 = parent.children.build(name: "Jaimy Jermaine Jackson")
          parent.children.build(name: "Autumn Joy Jackson")
          parent.save!
          # Jay was actually their first child
          parent.update_attributes!(
            name: "Hazel Gordy",
            children_attributes: { id: child1.id, name: "Jay Jackson" }
          )
          # We expect `reify` for all versions to have item_type 'Family::CelebrityFamily',
          # not 'Family::Family'.
          expect(parent.versions.count).to eq(2)  # A create and an update
          parent.versions.each do |parent_version|
            expect(parent_version.item_type).to eq(parent.class.name)
          end
        end
      end

      context "has_many" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "Gomez Addams")
          parent.path_to_stardom = "Buy a Victorian house next to a sprawling graveyard, and just become super aloof."
          parent.children.build(name: "Wednesday")
          parent.save!
          parent.name = "Morticia Addams"
          parent.children.build(name: "Pugsley")
          parent.save!

          # We expect `reify` to look for item_type 'Family::Family', not
          # '::Family::Family'. See PR #996
          previous_parent = parent.versions.last.reify(has_many: true)
          previous_children = previous_parent.children
          expect(previous_children.size).to eq 1
          expect(previous_children.first.name).to eq "Wednesday"
          parent.versions.each do |parent_version|
            expect(parent_version.item_type).to eq(parent.class.name)
          end
        end
      end

      context "has_many through" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "Grandad")
          parent.path_to_stardom = "Took a suitcase and started running a market trading company out of it, while proclaiming, 'This time next year, we'll be millionaires!'"
          parent.grandsons.build(name: "Del Boy")
          parent.save!
          parent.name = "Del"
          parent.grandsons.build(name: "Rodney")
          parent.save!

          # We expect `reify` to look for item_type 'Family::Family', not
          # '::Family::Family'. See PR #996
          previous_parent = parent.versions.last.reify(has_many: true)
          previous_grandsons = previous_parent.grandsons
          expect(previous_grandsons.size).to eq 1
          expect(previous_grandsons.first.name).to eq "Del Boy"
        end
      end

      context "has_one" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "parent1")
          parent.path_to_stardom = ""
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
