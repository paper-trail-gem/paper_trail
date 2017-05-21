require "rails_helper"

module PaperTrail
  ::RSpec.describe Cleaner, versioning: true do
    describe "clean_versions!" do
      let(:animal) { ::Animal.new }
      let(:dog) { ::Dog.new }
      let(:cat) { ::Cat.new }
      let(:animals) { [animal, dog, cat] }

      before do
        animals.each do |animal|
          3.times do
            animal.update_attribute(:name, FFaker::Name.name)
          end
        end
      end

      it "baseline test setup" do
        expect(PaperTrail::Version.count).to(eq(9))
        animals.each { |animal| expect(animal.versions.size).to(eq(3)) }
      end

      context "no options provided" do
        it "removes extra versions for each item" do
          PaperTrail.clean_versions!
          expect(PaperTrail::Version.count).to(eq(3))
          animals.each { |animal| expect(animal.versions.size).to(eq(1)) }
        end

        it "removes the earliest version(s)" do
          before = animals.map { |animal| animal.versions.last.reify.name }
          PaperTrail.clean_versions!
          after = animals.map { |animal| animal.versions.last.reify.name }
          expect(after).to(eq(before))
        end
      end

      context "keeping 2" do
        it "keeps two records, instead of the usual one" do
          PaperTrail.clean_versions!(keeping: 2)
          expect(PaperTrail::Version.all.count).to(eq(6))
          animals.each { |animal| expect(animal.versions.size).to(eq(2)) }
        end
      end

      context "with the :date option" do
        it "only deletes versions created on the given date" do
          animal.versions.each do |ver|
            ver.update_attribute(:created_at, (ver.created_at - 1.day))
          end
          date = animal.versions.first.created_at.to_date
          animal.update_attribute(:name, FFaker::Name.name)
          expect(PaperTrail::Version.count).to(eq(10))
          expect(animal.versions.size).to(eq(4))
          expect(animal.paper_trail.versions_between(date, (date + 1.day)).size).to(eq(3))
          PaperTrail.clean_versions!(date: date)
          expect(PaperTrail::Version.count).to(eq(8))
          expect(animal.versions.reload.size).to(eq(2))
          expect(animal.versions.first.created_at.to_date).to(eq(date))
          # Why use `equal?` here instead of something less strict?
          # Doesn't `to_date` always produce a new date object?
          expect(date.equal?(animal.versions.last.created_at.to_date)).to eq(false)
        end
      end

      context "with the :item_id option" do
        context "single ID received" do
          it "only deletes the versions for the Item with that ID" do
            PaperTrail.clean_versions!(item_id: animal.id)
            expect(animal.versions.size).to(eq(1))
            expect(PaperTrail::Version.count).to(eq(7))
          end
        end

        context "collection of IDs received" do
          it "only deletes versions for the Item(s) with those IDs" do
            PaperTrail.clean_versions!(item_id: [animal.id, dog.id])
            expect(animal.versions.size).to(eq(1))
            expect(dog.versions.size).to(eq(1))
            expect(PaperTrail::Version.count).to(eq(5))
          end
        end
      end

      context "options combinations" do
        context ":date" do
          before do
            [animal, dog].each do |animal|
              animal.versions.each do |ver|
                ver.update_attribute(:created_at, (ver.created_at - 1.day))
              end
              animal.update_attribute(:name, FFaker::Name.name)
            end
          end

          it "baseline test setup" do
            date = animal.versions.first.created_at.to_date
            expect(PaperTrail::Version.count).to(eq(11))
            [animal, dog].each do |animal|
              expect(animal.versions.size).to(eq(4))
              expect(animal.versions.between(date, (date + 1.day)).size).to(eq(3))
            end
          end

          context "and :keeping" do
            it "restrict cleaning properly" do
              date = animal.versions.first.created_at.to_date
              PaperTrail.clean_versions!(date: date, keeping: 2)
              [animal, dog].each do |animal|
                animal.versions.reload
                expect(animal.versions.size).to(eq(3))
                expect(animal.versions.between(date, (date + 1.day)).size).to(eq(2))
              end
              expect(PaperTrail::Version.count).to(eq(9))
            end
          end

          context "and :item_id" do
            it "restrict cleaning properly" do
              date = animal.versions.first.created_at.to_date
              PaperTrail.clean_versions!(date: date, item_id: dog.id)
              dog.versions.reload
              expect(dog.versions.size).to(eq(2))
              expect(dog.versions.between(date, (date + 1.day)).size).to(eq(1))
              expect(PaperTrail::Version.count).to(eq(9))
            end
          end

          context ", :item_id, and :keeping" do
            it "restrict cleaning properly" do
              date = animal.versions.first.created_at.to_date
              PaperTrail.clean_versions!(date: date, item_id: dog.id, keeping: 2)
              dog.versions.reload
              expect(dog.versions.size).to(eq(3))
              expect(dog.versions.between(date, (date + 1.day)).size).to(eq(2))
              expect(PaperTrail::Version.count).to(eq(10))
            end
          end
        end

        context ":keeping and :item_id" do
          it "restrict cleaning properly" do
            PaperTrail.clean_versions!(keeping: 2, item_id: animal.id)
            expect(animal.versions.size).to(eq(2))
            expect(PaperTrail::Version.count).to(eq(8))
          end
        end
      end
    end
  end
end
