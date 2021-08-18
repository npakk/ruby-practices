#!/usr/bin/env ruby
# frozen_string_literal: true

class Array
  # 配列にある値全てを数値に変換する
  def to_i
    map! do |val|
      if val == BowlingScore::STRIKE
        BowlingScore::MAX_PINS
      else
        val.to_i
      end
    end
  end
end

class BowlingScore
  STRIKE = 'X'
  MAX_PINS = 10

  attr_accessor :score

  def initialize(game_score)
    @score = []
    throw_per_frame = 0
    score = game_score.split(',')
    score.each_with_index do |s, index|
      # 10フレーム目のスコアはまとめて挿入する
      return @score << score[index...score.size].to_i if @score.size == 9

      if s == STRIKE
        throw_per_frame = 0
        @score << [MAX_PINS]
      elsif throw_per_frame.odd?
        throw_per_frame = 0
        @score << [score[index - 1].to_i, s.to_i]
      else
        throw_per_frame = 1
      end
    end
  end

  def calculate_score
    @score.each.with_index.inject(0) do |result, (val, index)|
      # 最終フレーム以外のストライク、スペアは次フレームの投球スコアを加算する
      if (0...9).cover?(index)
        if val[0] == MAX_PINS
          # ストライクの場合、2投
          result += get_additional_score(index, 2)
        elsif val.sum == MAX_PINS
          # スペアの場合、1投
          result += get_additional_score(index, 1)
        end
      end
      result + val.sum
    end
  end

  private

  def get_additional_score(current_frame, throw_count)
    # 加算対象の投球がフレームをまたぐ場合、次のフレームを参照する
    (0...throw_count).inject(0) do |result, i|
      result + (@score[current_frame + 1][i] || @score[current_frame + throw_count][0])
    end
  end
end

puts BowlingScore.new(ARGV[0]).calculate_score if __FILE__ == $PROGRAM_NAME
