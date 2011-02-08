require 'test_helper'

class PaperTrailTest < ActiveSupport::TestCase
  test 'Sanity test' do
    assert_kind_of Module, PaperTrail
  end
end
