require 'test_helper'

class ProtectedAttrsTest < ActiveSupport::TestCase
  subject { ProtectedWidget.new }

  accessible_attrs = ProtectedWidget.accessible_attributes.to_a
  accessible_attrs.each do |attr_name|
    should allow_mass_assignment_of(attr_name.to_sym)
  end
  ProtectedWidget.column_names.reject { |column_name| accessible_attrs.include?(column_name) }.each do |attr_name|
    should_not allow_mass_assignment_of(attr_name.to_sym)
  end

  context 'A model with `attr_accessible` created' do
    setup do
      @widget = ProtectedWidget.create! :name => 'Henry'
      @initial_attributes = @widget.attributes
    end

    should 'be `nil` in its previous version' do
      assert_nil @widget.previous_version
    end

    context 'which is then updated' do
      setup do
        @widget.assign_attributes(:name => 'Jeff', :a_text => 'Short statement')
        @widget.an_integer = 42
        @widget.save!
      end

      should 'not be `nil` in its previous version' do
        assert_not_nil @widget.previous_version
      end

      should 'the previous version should contain right attributes' do
        assert_equal @widget.previous_version.attributes, @initial_attributes
      end
    end

  end
end
