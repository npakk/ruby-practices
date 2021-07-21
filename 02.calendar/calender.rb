#!/usr/bin/env ruby

require 'date'
require 'optparse'

# 文字列出力幅
Width = 20
DayWidth = 2

# オプション
opts = ARGV.getopts('y:', 'm:')

# 日付定義
today = Date.today
year = opts["y"] ? opts["y"].to_i : today.year
month = if opts["m"]
          raise "#{opts["m"]} is neither a month number (1..12) nor a name" unless (1..12) === opts["m"].to_i

          opts["m"].to_i
        else
          today.month
        end
start_of_day = Date.new(year, month, 1)          # 月初
end_of_day = Date.new(year, month, -1)           # 月末

# カレンダー出力
puts %(#{month}月 #{year}).center(Width)
puts %(日 月 火 水 木 金 土)

(start_of_day..end_of_day).each_with_object(Array.new) do |date, week|

  # 今日の日付は色を変更
  if date == today
    week.push("\e[31m#{date.day.to_s.rjust(DayWidth)}\e[0m")
  else
    week.push(date.day.to_s.rjust(DayWidth))
  end

  # 土曜日もしくは月末なら改行し、それぞれ左または右に文字寄せ
  case
  when date.saturday?
    puts %(#{week.pop(week.size).join("\s")}).rjust(Width)
  when date == end_of_day
    puts %(#{week.pop(week.size).join("\s")}).ljust(Width)
  end
end

