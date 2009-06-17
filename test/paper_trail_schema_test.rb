require 'test_helper'

class PaperTrailTest < ActiveSupport::TestCase
  def setup
    load_schema
  end

  def test_schema_has_loaded_correctly
    assert_equal [], Widget.all
    assert_equal [], Version.all
  end
end
