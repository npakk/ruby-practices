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

(start_of_day..end_of_day).each_with_object([]) do |date, week|
  # 今日の日付は色を変更
  if date == today
    week.push("\e[31m#{date.day.to_s.rjust(DAY_WIDTH)}\e[0m")
  else
    week.push(date.day.to_s.rjust(DAY_WIDTH))
  end

  # 土曜日もしくは月末なら改行し、それぞれ左または右に文字寄せ
  if date.saturday?
    puts week.pop(week.size).join("\s").to_s.rjust(WIDTH)
  elsif date == end_of_day
    puts week.pop(week.size).join("\s").to_s.ljust(WIDTH)
  end
end
