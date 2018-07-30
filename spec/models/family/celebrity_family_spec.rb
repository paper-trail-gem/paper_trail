# frozen_string_literal: true

require "spec_helper"

module Family
  RSpec.describe CelebrityFamily, type: :model, versioning: true do
    it { is_expected.to be_versioned }

    describe "#create" do
      # https://github.com/paper-trail-gem/paper_trail/pull/1108
      it "creates a version record with item_type == class.name, not base_class" do
        carter = described_class.create(
          name: "Carter",
          path_to_stardom: "Mexican radio"
        )
        v = carter.versions.last
        expect(v[:event]).to eq("create")
        expect(v[:item_type]).to eq("Family::CelebrityFamily")
      end
    end

    describe "#reify" do
      context "belongs_to" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "Jermaine Jackson")
          parent.path_to_stardom = "Emulating Motown greats such as the Temptations and "\
                                   "The Supremes"
          child1 = parent.children.build(name: "Jaimy Jermaine Jackson")
          parent.children.build(name: "Autumn Joy Jackson")
          parent.save!
          parent.update_attributes!(
            name: "Hazel Gordy",
            children_attributes: { id: child1.id, name: "Jay Jackson" }
          )
          # We expect `reify` for all versions to have item_type 'Family::CelebrityFamily',
          # not 'Family::Family'. See PR #1108
          expect(parent.versions.count).to eq(2) # A create and an update
          parent.versions.each do |parent_version|
            expect(parent_version.item_type).to eq(parent.class.name)
          end
        end
      end

      context "has_many" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "Gomez Addams")
          parent.path_to_stardom = "Buy a Victorian house next to a sprawling graveyard, "\
                                   "and just become super aloof."
          parent.children.build(name: "Wednesday")
          parent.save!
          parent.name = "Morticia Addams"
          parent.children.build(name: "Pugsley")
          parent.save!

          # We expect `reify` for all versions to have item_type 'Family::CelebrityFamily',
          # not 'Family::Family'. See PR #1108
          expect(parent.versions.count).to eq(2)
          parent.versions.each do |parent_version|
            expect(parent_version.item_type).to eq(parent.class.name)
          end
        end
      end

      context "has_many through" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "Grandad")
          parent.path_to_stardom = "Took a suitcase and started running a market trading "\
                                   "company out of it, while proclaiming, 'This time next "\
                                   "year, we'll be millionaires!'"
          parent.grandsons.build(name: "Del Boy")
          parent.save!
          parent.name = "Del"
          parent.grandsons.build(name: "Rodney")
          parent.save!

          # We expect `reify` for all versions to have item_type 'Family::CelebrityFamily',
          # not 'Family::Family'. See PR #1108
          expect(parent.versions.count).to eq(2)
          parent.versions.each do |parent_version|
            expect(parent_version.item_type).to eq(parent.class.name)
          end
        end
      end

      context "has_one" do
        it "uses the correct item_type in queries" do
          parent = described_class.new(name: "Minnie Marx")
          parent.path_to_stardom = "Gain a relentless dedication to the stage by having a "\
                                   "mother who performs as a yodeling harpist, and then "\
                                   "bring up 5 boys who have a true zest for comedy."
          parent.build_mentee(name: "Abraham Schönberg")
          parent.save!
          parent.update_attributes(
            name: "Samuel Marx",
            mentee_attributes: { id: parent.mentee.id, name: "Al Shean" }
          )

          # We expect `reify` for all versions to have item_type 'Family::CelebrityFamily',
          # not 'Family::Family'. See PR #1108
          expect(parent.versions.count).to eq(2)
          parent.versions.each do |parent_version|
            expect(parent_version.item_type).to eq(parent.class.name)
          end
        end
      end
    end

    describe "#update" do
      # https://github.com/paper-trail-gem/paper_trail/pull/1108
      it "creates a version record with item_type == class.name, not base_class" do
        carter = described_class.create(
          name: "Carter",
          path_to_stardom: "Mexican radio"
        )
        carter.update(path_to_stardom: "Johnny")
        v = carter.versions.last
        expect(v[:event]).to eq("update")
        expect(v[:item_type]).to eq("Family::CelebrityFamily")
      end
    end
  end
end
