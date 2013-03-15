require 'test_helper'

class ProtectedAttrsTest < ActiveSupport::TestCase

  describe 'A model with `attr_accessible` created' do
    setup do
      @widget = ProtectedWidget.create! :name => 'Henry'
      @initial_attributes = @widget.attributes
    end

    should { assert !ProtectedWidget.accessible_attributes.empty? }

    should 'be `nil` in its previous version' do
      assert_nil @widget.previous_version
    end

    describe 'which is then updated' do
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
