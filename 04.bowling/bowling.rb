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

  def initialize(game_score)
    @frames = []
    throw_per_frame = 0
    score = game_score.split(',')
    score.each_with_index do |s, index|
      # 10フレーム目のスコアはまとめて挿入する
      return @frames << score[index...score.size].to_i if @frames.size == 9

      if s == STRIKE
        throw_per_frame = 0
        @frames << [MAX_PINS]
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
      next val.sum + get_additional_score(i, 2) if val[0] == MAX_PINS
      next val.sum + get_additional_score(i, 1) if val.sum == MAX_PINS

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
end
puts BowlingScore.new(ARGV[0]).calculate if __FILE__ == $PROGRAM_NAME
