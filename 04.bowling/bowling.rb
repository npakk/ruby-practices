#!/usr/bin/env ruby
# frozen_string_literal: true

class BowlingScore
  STRIKE = 'X'
  MAX_PINS = '10'

  def initialize(game_score)
    @frames = []
    throw_per_frame = 0
    score = game_score.split(',')
    score.each_with_index do |s, index|
      # 10フレーム目のスコアはまとめて挿入する
      return @frames << to_p(score[index...score.size]) if @frames.size == 9

      if s == STRIKE
        throw_per_frame = 0
        @frames << [MAX_PINS.to_i]
      elsif throw_per_frame.odd?
        throw_per_frame = 0
        @frames << [score[index - 1].to_i, s.to_i]
      else
        throw_per_frame = 1
      end
    end
  end

  def calculate
    @frames.each.with_index.sum do |val, i|
      # 最終フレーム以外のストライク、スペアは次フレームの投球スコアを加算する
      next val.sum unless (0...9).cover?(i)
      next val.sum + get_additional_score(i, 2) if val[0] == MAX_PINS.to_i
      next val.sum + get_additional_score(i, 1) if val.sum == MAX_PINS.to_i

      val.sum
    end
  end

  private

  def get_additional_score(current_frame_index, throw_count)
    # 加算対象の投球がフレームをまたぐ場合、次のフレームを参照する
    (0...throw_count).sum do |i|
      (@frames[current_frame_index + 1][i] || @frames[current_frame_index + throw_count][0])
    end
  end

  def to_p(scores)
    scores.map do |score|
      score.gsub(STRIKE, MAX_PINS).to_i
    end
  end
end
puts BowlingScore.new(ARGV[0]).calculate if __FILE__ == $PROGRAM_NAME
