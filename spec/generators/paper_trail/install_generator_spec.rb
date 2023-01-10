# frozen_string_literal: true

require "spec_helper"
require "generator_spec/test_case"
require "generators/paper_trail/install/install_generator"

RSpec.describe PaperTrail::InstallGenerator, type: :generator do
  include GeneratorSpec::TestCase
  destination File.expand_path("tmp", __dir__)

  after do
    prepare_destination # cleanup the tmp directory
  end

  describe "no options" do
    before do
      prepare_destination
      run_generator
    end

    it "generates a migration for creating the 'versions' table" do
      expected_parent_class = lambda {
        old_school = "ActiveRecord::Migration"
        ar_version = ActiveRecord::VERSION
        format("%s[%d.%d]", old_school, ar_version::MAJOR, ar_version::MINOR)
      }.call
      expected_create_table_options = lambda {
        if described_class::MYSQL_ADAPTERS.include?(ActiveRecord::Base.connection.class.name)
          ', options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci"'
        else
          ""
        end
      }.call
      expected_item_type_options = lambda {
        if described_class::MYSQL_ADAPTERS.include?(ActiveRecord::Base.connection.class.name)
          ", null: false, limit: 191"
        else
          ", null: false"
        end
      }.call
      expect(destination_root).to(
        have_structure {
          directory("db") {
            directory("migrate") {
              migration("create_versions") {
                contains("class CreateVersions < " + expected_parent_class)
                contains "def change"
                contains "create_table :versions#{expected_create_table_options}"
                contains "  t.string   :item_type#{expected_item_type_options}"
              }
            }
          }
        }
      )
      expect(destination_root).not_to(
        have_structure {
          directory("db") {
            directory("migrate") {
              migration("add_object_changes_to_versions")
            }
          }
        }
      )
    end
  end

  describe "`--with-changes` option set to `true`" do
    before do
      prepare_destination
      run_generator %w[--with-changes]
    end

    it "generates a migration for creating the 'versions' table" do
      expect(destination_root).to(
        have_structure {
          directory("db") {
            directory("migrate") {
              migration("create_versions") {
                contains "class CreateVersions"
                contains "def change"
                contains "create_table :versions"
              }
            }
          }
        }
      )
    end

    it "generates a migration for adding the 'object_changes' column to the 'versions' table" do
      expect(destination_root).to(
        have_structure {
          directory("db") {
            directory("migrate") {
              migration("add_object_changes_to_versions") {
                contains "class AddObjectChangesToVersions"
                contains "def change"
                contains "add_column :versions, :object_changes, :text"
              }
            }
          }
        }
      )
    end
  end

  describe "`--uuid` option set to `true`" do
    before do
      prepare_destination
      run_generator %w[--uuid]
    end

    it "generates a migration for creating the 'versions' table with item_id type string" do
      expected_item_id_type = "string"
      expect(destination_root).to(
        have_structure {
          directory("db") {
            directory("migrate") {
              migration("create_versions") {
                contains "t.#{expected_item_id_type}   :item_id,   null: false"
              }
            }
          }
        }
      )
    end

    it "generates a migration for creating the 'versions' table with primary key as uuid type" do
      expected_primary_key_type = "uuid"
      expect(destination_root).to(
        have_structure {
          directory("db") {
            directory("migrate") {
              migration("create_versions") {
                contains ", id: :#{expected_primary_key_type}"
              }
            }
          }
        }
      )
    end
  end
end
