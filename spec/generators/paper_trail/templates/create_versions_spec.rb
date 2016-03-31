require "rails_helper"
require "generators/paper_trail/templates/create_versions"

RSpec.describe CreateVersions do
  describe "#change", verify_stubs: false do
    let(:migration) { described_class.new }

    before do
      allow(migration).to receive(:add_index)
      allow(migration).to receive(:create_table)
    end

    it "creates the versions table" do
      migration.change
      expect(migration).to have_received(:create_table) do |arg1|
        expect(arg1).to eq(:versions)
      end
    end

    case ENV["DB"]
    when "mysql"
      it "uses InnoDB engine" do
        migration.change
        expect(migration).to have_received(:create_table) do |_, arg2|
          expect(arg2[:options]).to match(/ENGINE=InnoDB/)
        end
      end

      it "uses utf8mb4 character set" do
        migration.change
        expect(migration).to have_received(:create_table) do |_, arg2|
          expect(arg2[:options]).to match(/DEFAULT CHARSET=utf8mb4/)
        end
      end

      it "uses utf8mb4_col collation" do
        migration.change
        expect(migration).to have_received(:create_table) do |_, arg2|
          expect(arg2[:options]).to match(/COLLATE=utf8mb4_general_ci/)
        end
      end
    else
      it "passes an empty options hash to create_table" do
        migration.change
        expect(migration).to have_received(:create_table) do |_, arg2|
          expect(arg2).to eq({})
        end
      end
    end
  end
end
