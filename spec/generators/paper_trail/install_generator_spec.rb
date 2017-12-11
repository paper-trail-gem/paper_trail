# frozen_string_literal: true

require "spec_helper"
require "generator_spec/test_case"
require File.expand_path("../../../../lib/generators/paper_trail/install_generator", __FILE__)

RSpec.describe PaperTrail::InstallGenerator, type: :generator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../tmp", __FILE__)

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
        if ar_version::MAJOR >= 5
          format("%s[%d.%d]", old_school, ar_version::MAJOR, ar_version::MINOR)
        else
          old_school
        end
      }.call
      expected_create_table_options = lambda {
        if described_class::MYSQL_ADAPTERS.include?(ActiveRecord::Base.connection.class.name)
          ', { options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" }'
        else
          ""
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
              }
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
end
