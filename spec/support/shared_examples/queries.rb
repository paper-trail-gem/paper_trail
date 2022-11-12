# frozen_string_literal: true

RSpec.shared_examples "queries" do |column_type, model, name_of_integer_column|
  let(:record) { model.new }
  let(:name) { FFaker::Name.first_name }
  let(:int) { column_type == :text ? 1 : rand(2..6) }

  after do
    PaperTrail.serializer = PaperTrail::Serializers::YAML
  end

  describe "#where_attribute_changes", versioning: true do
    it "requires its argument to be a string or a symbol" do
      expect {
        model.paper_trail.version_class.where_attribute_changes({})
      }.to raise_error(ArgumentError)
      expect {
        model.paper_trail.version_class.where_attribute_changes([])
      }.to raise_error(ArgumentError)
    end

    context "with object_changes_adapter configured" do
      after do
        PaperTrail.config.object_changes_adapter = nil
      end

      it "calls the adapter's where_attribute_changes method" do
        adapter = instance_spy("CustomObjectChangesAdapter")
        bicycle = model.create!(name: "abc")
        bicycle.update!(name: "xyz")

        allow(adapter).to(
          receive(:where_attribute_changes).with(model.paper_trail.version_class, :name)
        ).and_return([bicycle.versions[0], bicycle.versions[1]])

        PaperTrail.config.object_changes_adapter = adapter
        expect(
          bicycle.versions.where_attribute_changes(:name)
        ).to match_array([bicycle.versions[0], bicycle.versions[1]])
        expect(adapter).to have_received(:where_attribute_changes)
      end

      it "defaults to the original behavior" do
        adapter = Class.new.new
        PaperTrail.config.object_changes_adapter = adapter
        bicycle = model.create!(name: "abc")
        bicycle.update!(name: "xyz")

        if column_type == :text
          expect {
            bicycle.versions.where_attribute_changes(:name)
          }.to raise_error(
            ::PaperTrail::UnsupportedColumnType,
            "where_attribute_changes expected json or jsonb column, got text"
          )
        else
          expect(
            bicycle.versions.where_attribute_changes(:name)
          ).to match_array([bicycle.versions[0], bicycle.versions[1]])
        end
      end
    end

    if column_type == :text
      it "raises error" do
        expect {
          record.versions.where_attribute_changes(:name).to_a
        }.to raise_error(
          ::PaperTrail::UnsupportedColumnType,
          "where_attribute_changes expected json or jsonb column, got text"
        )
      end
    else
      it "locates versions according to their object_changes contents" do
        record.update!(name: "foobar", name_of_integer_column => 100)
        record.update!(name_of_integer_column => 17)

        expect(
          record.versions.where_attribute_changes(:name)
        ).to eq([record.versions[0]])
        expect(
          record.versions.where_attribute_changes(name_of_integer_column.to_s)
        ).to eq([record.versions[0], record.versions[1]])
        expect(record.class.column_names).to include("color")
        expect(
          record.versions.where_attribute_changes(:color)
        ).to eq([])
      end
    end
  end

  describe "#where_object", versioning: true do
    it "requires its argument to be a Hash" do
      record.update!(name: name, name_of_integer_column => int)
      record.update!(name: "foobar", name_of_integer_column => 100)
      record.update!(name: FFaker::Name.last_name, name_of_integer_column => 15)
      expect {
        model.paper_trail.version_class.where_object(:foo)
      }.to raise_error(ArgumentError)
      expect {
        model.paper_trail.version_class.where_object([])
      }.to raise_error(ArgumentError)
    end

    context "with YAML serializer" do
      it "locates versions according to their `object` contents" do
        expect(PaperTrail.serializer).to be PaperTrail::Serializers::YAML
        record.update!(name: name, name_of_integer_column => int)
        record.update!(name: "foobar", name_of_integer_column => 100)
        record.update!(name: FFaker::Name.last_name, name_of_integer_column => 15)
        expect(
          model.paper_trail.version_class.where_object(name_of_integer_column => int)
        ).to eq([record.versions[1]])
        expect(
          model.paper_trail.version_class.where_object(name: name)
        ).to eq([record.versions[1]])
        expect(
          model.paper_trail.version_class.where_object(name_of_integer_column => 100)
        ).to eq([record.versions[2]])
      end
    end

    context "with JSON serializer" do
      it "locates versions according to their `object` contents" do
        PaperTrail.serializer = PaperTrail::Serializers::JSON
        expect(PaperTrail.serializer).to be PaperTrail::Serializers::JSON
        record.update!(name: name, name_of_integer_column => int)
        record.update!(name: "foobar", name_of_integer_column => 100)
        record.update!(name: FFaker::Name.last_name, name_of_integer_column => 15)
        expect(
          model.paper_trail.version_class.where_object(name_of_integer_column => int)
        ).to eq([record.versions[1]])
        expect(
          model.paper_trail.version_class.where_object(name: name)
        ).to eq([record.versions[1]])
        expect(
          model.paper_trail.version_class.where_object(name_of_integer_column => 100)
        ).to eq([record.versions[2]])
      end
    end
  end

  describe "#where_object_changes", versioning: true do
    it "requires its argument to be a Hash" do
      expect {
        model.paper_trail.version_class.where_object_changes(:foo)
      }.to raise_error(ArgumentError)
      expect {
        model.paper_trail.version_class.where_object_changes([])
      }.to raise_error(ArgumentError)
    end

    context "with object_changes_adapter configured" do
      after do
        PaperTrail.config.object_changes_adapter = nil
      end

      it "calls the adapter's where_object_changes method" do
        adapter = instance_spy("CustomObjectChangesAdapter")
        bicycle = model.create!(name: "abc")
        allow(adapter).to(
          receive(:where_object_changes).with(model.paper_trail.version_class, { name: "abc" })
        ).and_return(bicycle.versions[0..1])
        PaperTrail.config.object_changes_adapter = adapter
        expect(
          bicycle.versions.where_object_changes(name: "abc")
        ).to match_array(bicycle.versions[0..1])
        expect(adapter).to have_received(:where_object_changes)
      end

      it "defaults to the original behavior" do
        adapter = Class.new.new
        PaperTrail.config.object_changes_adapter = adapter
        bicycle = model.create!(name: "abc")
        if column_type == :text
          expect {
            bicycle.versions.where_object_changes(name: "abc")
          }.to raise_error(
            ::PaperTrail::UnsupportedColumnType,
            "where_object_changes expected json or jsonb column, got text"
          )
        else
          expect(
            bicycle.versions.where_object_changes(name: "abc")
          ).to match_array(bicycle.versions[0..1])
        end
      end
    end

    if column_type == :text
      it "raises error" do
        expect {
          record.versions.where_object_changes(name: "foo").to_a
        }.to raise_error(
          ::PaperTrail::UnsupportedColumnType,
          "where_object_changes expected json or jsonb column, got text"
        )
      end
    else
      it "locates versions according to their object_changes contents" do
        record.update!(name: name, name_of_integer_column => 0)
        record.update!(name: "foobar", name_of_integer_column => 100)
        record.update!(name: FFaker::Name.last_name, name_of_integer_column => int)
        expect(
          record.versions.where_object_changes(name: name)
        ).to eq(record.versions[0..1])
        expect(
          record.versions.where_object_changes(name_of_integer_column => 100)
        ).to eq(record.versions[1..2])
        expect(
          record.versions.where_object_changes(name_of_integer_column => int)
        ).to eq([record.versions.last])
        expect(
          record.versions.where_object_changes(name_of_integer_column => 100, name: "foobar")
        ).to eq(record.versions[1..2])
      end
    end
  end

  describe "#where_object_changes_from", versioning: true do
    it "requires its argument to be a Hash" do
      expect {
        model.paper_trail.version_class.where_object_changes_from(:foo)
      }.to raise_error(ArgumentError)
      expect {
        model.paper_trail.version_class.where_object_changes_from([])
      }.to raise_error(ArgumentError)
    end

    context "with object_changes_adapter configured" do
      after do
        PaperTrail.config.object_changes_adapter = nil
      end

      it "calls the adapter's where_object_changes_from method" do
        adapter = instance_spy("CustomObjectChangesAdapter")
        bicycle = model.create!(name: "abc")
        bicycle.update!(name: "xyz")

        allow(adapter).to(
          receive(:where_object_changes_from).with(model.paper_trail.version_class, { name: "abc" })
        ).and_return([bicycle.versions[1]])

        PaperTrail.config.object_changes_adapter = adapter
        expect(
          bicycle.versions.where_object_changes_from(name: "abc")
        ).to match_array([bicycle.versions[1]])
        expect(adapter).to have_received(:where_object_changes_from)
      end

      it "defaults to the original behavior" do
        adapter = Class.new.new
        PaperTrail.config.object_changes_adapter = adapter
        bicycle = model.create!(name: "abc")
        bicycle.update!(name: "xyz")

        if column_type == :text
          expect {
            bicycle.versions.where_object_changes_from(name: "abc")
          }.to raise_error(
            ::PaperTrail::UnsupportedColumnType,
            "where_object_changes_from expected json or jsonb column, got text"
          )
        else
          expect(
            bicycle.versions.where_object_changes_from(name: "abc")
          ).to match_array([bicycle.versions[1]])
        end
      end
    end

    if column_type == :text
      it "raises error" do
        expect {
          record.versions.where_object_changes_from(name: "foo").to_a
        }.to raise_error(
          ::PaperTrail::UnsupportedColumnType,
          "where_object_changes_from expected json or jsonb column, got text"
        )
      end
    else
      it "locates versions according to their object_changes contents" do
        record.update!(name: name, name_of_integer_column => 0)
        record.update!(name: "foobar", name_of_integer_column => 100)
        record.update!(name: FFaker::Name.last_name, name_of_integer_column => int)

        expect(
          record.versions.where_object_changes_from(name: name)
        ).to eq([record.versions[1]])
        expect(
          record.versions.where_object_changes_from(name_of_integer_column => 100)
        ).to eq([record.versions[2]])
        expect(
          record.versions.where_object_changes_from(name_of_integer_column => int)
        ).to eq([])
        expect(
          record.versions.where_object_changes_from(name_of_integer_column => 100, name: "foobar")
        ).to eq([record.versions[2]])
      end
    end
  end

  describe "#where_object_changes_to", versioning: true do
    it "requires its argument to be a Hash" do
      expect {
        model.paper_trail.version_class.where_object_changes_to(:foo)
      }.to raise_error(ArgumentError)
      expect {
        model.paper_trail.version_class.where_object_changes_to([])
      }.to raise_error(ArgumentError)
    end

    context "with object_changes_adapter configured" do
      after do
        PaperTrail.config.object_changes_adapter = nil
      end

      it "calls the adapter's where_object_changes_to method" do
        adapter = instance_spy("CustomObjectChangesAdapter")
        bicycle = model.create!(name: "abc")
        bicycle.update!(name: "xyz")

        allow(adapter).to(
          receive(:where_object_changes_to).with(model.paper_trail.version_class, { name: "xyz" })
        ).and_return([bicycle.versions[1]])

        PaperTrail.config.object_changes_adapter = adapter
        expect(
          bicycle.versions.where_object_changes_to(name: "xyz")
        ).to match_array([bicycle.versions[1]])
        expect(adapter).to have_received(:where_object_changes_to)
      end

      it "defaults to the original behavior" do
        adapter = Class.new.new
        PaperTrail.config.object_changes_adapter = adapter
        bicycle = model.create!(name: "abc")
        bicycle.update!(name: "xyz")

        if column_type == :text
          expect {
            bicycle.versions.where_object_changes_to(name: "xyz")
          }.to raise_error(
            ::PaperTrail::UnsupportedColumnType,
            "where_object_changes_to expected json or jsonb column, got text"
          )
        else
          expect(
            bicycle.versions.where_object_changes_to(name: "xyz")
          ).to match_array([bicycle.versions[1]])
        end
      end
    end

    if column_type == :text
      it "raises error" do
        expect {
          record.versions.where_object_changes_to(name: "foo").to_a
        }.to raise_error(
          ::PaperTrail::UnsupportedColumnType,
          "where_object_changes_to expected json or jsonb column, got text"
        )
      end
    else
      it "locates versions according to their object_changes contents" do
        record.update!(name: name, name_of_integer_column => 0)
        record.update!(name: "foobar", name_of_integer_column => 100)
        record.update!(name: FFaker::Name.last_name, name_of_integer_column => int)

        expect(
          record.versions.where_object_changes_to(name: name)
        ).to eq([record.versions[0]])
        expect(
          record.versions.where_object_changes_to(name_of_integer_column => 100)
        ).to eq([record.versions[1]])
        expect(
          record.versions.where_object_changes_to(name_of_integer_column => int)
        ).to eq([record.versions[2]])
        expect(
          record.versions.where_object_changes_to(name_of_integer_column => 100, name: "foobar")
        ).to eq([record.versions[1]])
        expect(
          record.versions.where_object_changes_to(name_of_integer_column => -1)
        ).to eq([])
      end
    end
  end
end
