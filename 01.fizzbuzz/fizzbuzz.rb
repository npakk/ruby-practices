#!/usr/bin/env ruby

x = { Fizz: 3, Buzz: 5, FizzBuzz: 3 * 5 }
(1..20).each do |n|
  if (n % x[:FizzBuzz]).zero?
    puts :FizzBuzz.to_s
  elsif n % x[:Fizz].zero?
    puts :Fizz.to_s
  elsif n % x[:Buzz].zero?
    puts :Buzz.to_s
  else
    puts n
  end
end
