require 'test_helper'

class TimestampTest < ActiveSupport::TestCase

  setup do
    PaperTrail.timestamp_field = :custom_created_at
    change_schema
    Version.connection.schema_cache.clear!
    Version.reset_column_information

    Fluxor.instance_eval <<-END
      has_paper_trail
    END

    @fluxor = Fluxor.create :name => 'Some text.'
    @fluxor.update_attributes :name => 'Some more text.'
    @fluxor.update_attributes :name => 'Even more text.'
  end

  teardown do
    PaperTrail.timestamp_field = :created_at
  end

  test 'versions works with custom timestamp field' do
    # Normal behaviour
    assert_equal 3, @fluxor.versions.length
    assert_nil @fluxor.versions[0].reify
    assert_equal 'Some text.', @fluxor.versions[1].reify.name
    assert_equal 'Some more text.', @fluxor.versions[2].reify.name

    # Tinker with custom timestamps.
    now = Time.now.utc
    @fluxor.versions.reverse.each_with_index do |version, index|
      version.update_attribute :custom_created_at, (now + index.seconds)
    end

    # Test we are ordering by custom timestamps.
    @fluxor.versions true  # reload association
    assert_nil @fluxor.versions[2].reify
    assert_equal 'Some text.', @fluxor.versions[1].reify.name
    assert_equal 'Some more text.', @fluxor.versions[0].reify.name
  end

end
