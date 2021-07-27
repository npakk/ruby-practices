#!/usr/bin/env ruby

require 'date'
require 'optparse'

# 文字列出力幅
WIDTH = 20
DAY_WIDTH = 2

# オプション
opts = ARGV.getopts('y:', 'm:')

# 日付定義
today = Date.today
year = opts['y'] ? opts['y'].to_i : today.year
month = if opts['m']
          raise "#{opts['m']} is neither a month number (1..12) nor a name" unless (1..12).cover?(opts['m'].to_i)

          opts['m'].to_i
        else
          today.month
        end
start_of_day = Date.new(year, month, 1)          # 月初
end_of_day = Date.new(year, month, -1)           # 月末

# カレンダー出力
puts %(#{month}月 #{year}).center(WIDTH)
puts %(日 月 火 水 木 金 土)

(start_of_day..end_of_day).slice_after(&:saturday?).each do |week|
  # 今日の日付は色を変更
  week_line = (week.map do |date|
    date == today ? "\e[31m#{date.day.to_s.rjust(DAY_WIDTH)}\e[0m" : date.day.to_s.rjust(DAY_WIDTH)
  end).join("\s")

  print "\s\s\s" * week.first.wday if week.include?(start_of_day)
  puts week_line
end
