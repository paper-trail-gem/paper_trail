# frozen_string_literal: true

require "spec_helper"

# The `json_versions` table tests postgres' `json` data type. So, that
# table is only created when testing against postgres.
if JsonVersion.table_exists?
  RSpec.describe JsonVersion, type: :model do
    it "includes the VersionConcern module" do
      expect(described_class).to include(PaperTrail::VersionConcern)
    end

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
        it "locates versions according to their `object` contents" do
          fruit = Fruit.create!(name: "apple")
          expect(fruit.versions.length).to eq(1)
          fruit.update_attributes!(name: "banana", color: "aqua")
          expect(fruit.versions.length).to eq(2)
          fruit.update_attributes!(name: "coconut", color: "black")
          expect(fruit.versions.length).to eq(3)
          where_apple = described_class.where_object(name: "apple")
          expect(where_apple.to_sql).to eq(
            <<-SQL.squish
              SELECT "json_versions".*
              FROM "json_versions"
              WHERE (object->>'name' = 'apple')
            SQL
          )
          expect(where_apple).to eq([fruit.versions[1]])
          expect(
            described_class.where_object(color: "aqua")
          ).to eq([fruit.versions[2]])
        end
      end
    end

    describe "#where_object_changes" do
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
        it "finds versions according to their `object_changes` contents" do
          fruit = Fruit.create!(name: "apple")
          fruit.update_attributes!(name: "banana", color: "red")
          fruit.update_attributes!(name: "coconut", color: "green")
          where_apple = fruit.versions.where_object_changes(name: "apple")
          expect(where_apple.to_sql.squish).to eq(
            <<-SQL.squish
              SELECT "json_versions".*
              FROM "json_versions"
              WHERE "json_versions"."item_id" = #{fruit.id}
                AND "json_versions"."item_type" = 'Fruit'
                AND
                  (((object_changes->>'name' ILIKE '["apple",%')
                  OR (object_changes->>'name' ILIKE '[%,"apple"]%')))
              ORDER BY "json_versions"."created_at" ASC,
                "json_versions"."id" ASC
            SQL
          )
          expect(where_apple).to match_array(fruit.versions[0..1])
          expect(
            fruit.versions.where_object_changes(color: "red")
          ).to match_array(fruit.versions[1..2])
        end

        it "finds versions with multiple attributes changed" do
          fruit = Fruit.create!(name: "apple")
          fruit.update_attributes!(name: "banana", color: "red")
          fruit.update_attributes!(name: "coconut", color: "green")
          where_red_apple = fruit.versions.where_object_changes(color: "red", name: "apple")
          expect(where_red_apple.to_sql.squish).to eq(
            <<-SQL.squish
              SELECT "json_versions".*
              FROM "json_versions"
              WHERE "json_versions"."item_id" = #{fruit.id}
                AND "json_versions"."item_type" = 'Fruit'
                AND (((object_changes->>'color' ILIKE '["red",%')
                    OR (object_changes->>'color' ILIKE '[%,"red"]%'))
                  and ((object_changes->>'name' ILIKE '["apple",%')
                    OR (object_changes->>'name' ILIKE '[%,"apple"]%')))
              ORDER BY "json_versions"."created_at" ASC,
                "json_versions"."id" ASC
            SQL
          )
          expect(where_red_apple).to match_array([fruit.versions[1]])
        end
      end
    end
  end
end
