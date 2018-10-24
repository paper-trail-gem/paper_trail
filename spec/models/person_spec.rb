# frozen_string_literal: true

require "spec_helper"

# The `Person` model:
#
# - has a dozen associations of various types
# - has a custom serializer, TimeZoneSerializer, for its `time_zone` attribute
RSpec.describe Person, type: :model, versioning: true do
  describe "#time_zone" do
    it "returns an ActiveSupport::TimeZone" do
      person = Person.new(time_zone: "Samoa")
      expect(person.time_zone.class).to(eq(ActiveSupport::TimeZone))
    end
  end

  context "when the model is saved" do
    it "version.object_changes should store long serialization of TimeZone object" do
      person = Person.new(time_zone: "Samoa")
      person.save!
      len = person.versions.last.object_changes.length
      expect((len < 105)).to(be_truthy)
    end

    it "version.object_changes attribute should have stored the value from serializer" do
      person = Person.new(time_zone: "Samoa")
      person.save!
      as_stored_in_version = HashWithIndifferentAccess[
        YAML.load(person.versions.last.object_changes)
      ]
      expect(as_stored_in_version[:time_zone]).to(eq([nil, "Samoa"]))
      serialized_value = Person::TimeZoneSerializer.dump(person.time_zone)
      expect(as_stored_in_version[:time_zone].last).to(eq(serialized_value))
    end

    it "version.changeset should convert attribute to original, unserialized value" do
      person = Person.new(time_zone: "Samoa")
      person.save!
      unserialized_value = Person::TimeZoneSerializer.load(person.time_zone)
      expect(person.versions.last.changeset[:time_zone].last).to(eq(unserialized_value))
    end

    it "record.changes (before save) returns the original, unserialized values" do
      person = Person.new(time_zone: "Samoa")
      changes_before_save = person.changes.dup
      person.save!
      expect(
        changes_before_save[:time_zone].map(&:class)
      ).to(eq([NilClass, ActiveSupport::TimeZone]))
    end

    it "version.changeset should be the same as record.changes was before the save" do
      person = Person.new(time_zone: "Samoa")
      changes_before_save = person.changes.dup
      person.save!
      actual = person.versions.last.changeset.delete_if { |k, _v| (k.to_sym == :id) }
      expect(actual).to(eq(changes_before_save))
      actual = person.versions.last.changeset[:time_zone].map(&:class)
      expect(actual).to(eq([NilClass, ActiveSupport::TimeZone]))
    end

    context "when that attribute is updated" do
      it "object should not store long serialization of TimeZone object" do
        person = Person.new(time_zone: "Samoa")
        person.save!
        person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
        person.save!
        len = person.versions.last.object.length
        expect((len < 105)).to(be_truthy)
      end

      it "object_changes should not store long serialization of TimeZone object" do
        person = Person.new(time_zone: "Samoa")
        person.save!
        person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
        person.save!
        max_len = ActiveRecord::VERSION::MAJOR < 4 ? 105 : 118
        len = person.versions.last.object_changes.length
        expect((len < max_len)).to(be_truthy)
      end

      it "version.object attribute should have stored value from serializer" do
        person = Person.new(time_zone: "Samoa")
        person.save!
        attribute_value_before_change = person.time_zone
        person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
        person.save!
        as_stored_in_version = HashWithIndifferentAccess[
          YAML.load(person.versions.last.object)
        ]
        expect(as_stored_in_version[:time_zone]).to(eq("Samoa"))
        serialized_value = Person::TimeZoneSerializer.dump(attribute_value_before_change)
        expect(as_stored_in_version[:time_zone]).to(eq(serialized_value))
      end

      it "version.object_changes attribute should have stored value from serializer" do
        person = Person.new(time_zone: "Samoa")
        person.save!
        person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
        person.save!
        as_stored_in_version = HashWithIndifferentAccess[
          YAML.load(person.versions.last.object_changes)
        ]
        expect(as_stored_in_version[:time_zone]).to(eq(["Samoa", "Pacific Time (US & Canada)"]))
        serialized_value = Person::TimeZoneSerializer.dump(person.time_zone)
        expect(as_stored_in_version[:time_zone].last).to(eq(serialized_value))
      end

      it "version.reify should convert attribute to original, unserialized value" do
        person = Person.new(time_zone: "Samoa")
        person.save!
        attribute_value_before_change = person.time_zone
        person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
        person.save!
        unserialized_value = Person::TimeZoneSerializer.load(attribute_value_before_change)
        expect(person.versions.last.reify.time_zone).to(eq(unserialized_value))
      end

      it "version.changeset should convert attribute to original, unserialized value" do
        person = Person.new(time_zone: "Samoa")
        person.save!
        person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
        person.save!
        unserialized_value = Person::TimeZoneSerializer.load(person.time_zone)
        expect(person.versions.last.changeset[:time_zone].last).to(eq(unserialized_value))
      end

      it "record.changes (before save) returns the original, unserialized values" do
        person = Person.new(time_zone: "Samoa")
        person.save!
        person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
        changes_before_save = person.changes.dup
        person.save!
        expect(
          changes_before_save[:time_zone].map(&:class)
        ).to(eq([ActiveSupport::TimeZone, ActiveSupport::TimeZone]))
      end

      it "version.changeset should be the same as record.changes was before the save" do
        person = Person.new(time_zone: "Samoa")
        person.save!
        person.assign_attributes(time_zone: "Pacific Time (US & Canada)")
        changes_before_save = person.changes.dup
        person.save!
        expect(person.versions.last.changeset).to(eq(changes_before_save))
        expect(
          person.versions.last.changeset[:time_zone].map(&:class)
        ).to(eq([ActiveSupport::TimeZone, ActiveSupport::TimeZone]))
      end
    end
  end

  describe "#cars and bicycles" do
    it "can be reified" do
      person = Person.create(name: "Frank")
      car = Car.create(name: "BMW 325")
      bicycle = Bicycle.create(name: "BMX 1.0")

      person.car = car
      person.bicycle = bicycle
      person.update(name: "Steve")

      car.update(name: "BMW 330")
      bicycle.update(name: "BMX 2.0")
      person.update(name: "Peter")

      expect(person.reload.versions.length).to(eq(3))

      # These will work when PT-AT adds support for the new `item_subtype` column
      #
      # - https://github.com/westonganger/paper_trail-association_tracking/pull/5
      # - https://github.com/paper-trail-gem/paper_trail/pull/1143
      # - https://github.com/paper-trail-gem/paper_trail/issues/594
      #
      # second_version = person.reload.versions.second.reify(has_one: true)
      # expect(second_version.car.name).to(eq("BMW 325"))
      # expect(second_version.bicycle.name).to(eq("BMX 1.0"))
    end
  end
end
