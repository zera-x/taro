require_relative 'test_helper'
require_relative '../lib/subway/perl'

class PDNTest < Test::Unit::TestCase
  include Subway

  def test_encode_one
    assert_equal '1', PDN.encode(1)
  end
end
