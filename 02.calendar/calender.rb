#!/usr/bin/env ruby

require 'date'
require 'optparse'

# 文字列出力幅
Width = 20
DayWidth = 2

# 日付
opts = ARGV.getopts('y:', 'm:')

today = Date.today
year = opts["y"] ? opts["y"].to_i : today.year
month = opts["m"] ? opts["m"].to_i : today.month
start_of_day = Date.new(year, month, 1)        # 月初
end_of_day = Date.new(year, month + 1, 1) - 1  # 月末

# カレンダー出力
puts %(#{month}月 #{year}).center(Width)
puts %(日 月 火 水 木 金 土)

(start_of_day..end_of_day).each_with_object(Array.new) do |date, week|
  if date == today
    week.push("\e[31m#{date.day.to_s.rjust(DayWidth)}\e[0m")
  else
    week.push(date.day.to_s.rjust(DayWidth))
  end

  case
  when date.saturday?
    puts %(#{week.pop(week.size).join("\s")}).rjust(Width)
  when date == end_of_day
    puts %(#{week.pop(week.size).join("\s")}).ljust(Width)
  end
end

