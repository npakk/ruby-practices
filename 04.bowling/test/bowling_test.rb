# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../bowling'

class BowlingTest < Minitest::Test
  def test_bowling_score
    assert_equal(139, BowlingScore.new('6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,6,4,5').calculate_score)
    assert_equal(164, BowlingScore.new('6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,X,X,X').calculate_score)
    assert_equal(107, BowlingScore.new('0,10,1,5,0,0,0,0,X,X,X,5,1,8,1,0,4').calculate_score)
    assert_equal(134, BowlingScore.new('6,3,9,0,0,3,8,2,7,3,X,9,1,8,0,X,X,0,0').calculate_score)
    assert_equal(300, BowlingScore.new('X,X,X,X,X,X,X,X,X,X,X,X').calculate_score)
  end
end
