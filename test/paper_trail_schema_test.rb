require 'test_helper'

class PaperTrailSchemaTest < ActiveSupport::TestCase
  def setup
    load_schema
  end

  def test_schema_has_loaded_correctly
    assert_equal [], Widget.all
    assert_equal [], Version.all
    assert_equal [], Wotsit.all
    assert_equal [], Fluxor.all
    assert_equal [], Article.all
  end
end
