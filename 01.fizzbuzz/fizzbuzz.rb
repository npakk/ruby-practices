#!/usr/bin/env ruby

x = {Fizz: 3, Buzz: 5, FizzBuzz: 3*5}
(1..20).each do |n|
  case
  when n % x[:FizzBuzz] == 0
    puts :FizzBuzz.to_s
  when n % x[:Fizz] == 0
    puts :Fizz.to_s
  when n % x[:Buzz] == 0
    puts :Buzz.to_s
  else
    puts n
  end
end

