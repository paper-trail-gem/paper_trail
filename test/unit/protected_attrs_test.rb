require "test_helper"

class ProtectedAttrsTest < ActiveSupport::TestCase
  subject { ProtectedWidget.new }

  # These ActiveModel matchers (provided by shoulda-matchers) only work for
  # Rails 3.
  if ActiveRecord::VERSION::MAJOR < 4
    accessible_attrs = ProtectedWidget.accessible_attributes.to_a
    accessible_attrs.each do |attr_name|
      should allow_mass_assignment_of(attr_name.to_sym)
    end
    inaccessible = ProtectedWidget.
      column_names.
      reject { |column_name| accessible_attrs.include?(column_name) }
    inaccessible.each do |attr_name|
      should_not allow_mass_assignment_of(attr_name.to_sym)
    end
  end

  context "A model with `attr_accessible` created" do
    setup do
      @widget = ProtectedWidget.create! name: "Henry"
      @initial_attributes = @widget.attributes
    end

    should "be `nil` in its previous version" do
      assert_nil @widget.paper_trail.previous_version
    end

    context "which is then updated" do
      setup do
        @widget.assign_attributes(name: "Jeff", a_text: "Short statement")
        @widget.an_integer = 42
        @widget.save!
      end

      should "not be `nil` in its previous version" do
        assert_not_nil @widget.paper_trail.previous_version
      end

      should "the previous version should contain right attributes" do
        # For some reason this test seems to be broken in JRuby 1.9 mode in the
        # test env even though it works in the console. WTF?
        unless ActiveRecord::VERSION::MAJOR >= 4 && defined?(JRUBY_VERSION)
          previous_attributes = @widget.paper_trail.previous_version.attributes
          assert_attributes_equal previous_attributes, @initial_attributes
        end
      end
    end
  end
end
