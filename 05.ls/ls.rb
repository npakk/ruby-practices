#!/usr/bin/env ruby
# frozen_string_literal: true

module LS
  class Options
    require 'optparse'

    def initialize
      @options = {}
      OptionParser.new do |opt|
        opt.on(
          '-a',
          'Include directory entries whose names begin with a dot (.).'
        ) { |v| @options[:a] = v }
        opt.on(
          '-l',
          "(The lowercase letter ``ell''.)  List in long format.  (See below.)  A total sum for all the file sizes is output on a line before the long listing."
        ) { |v| @options[:l] = v }
        opt.on(
          '-r',
          'Reverse the order of the sort to get reverse lexicographical order or the oldest entries first (or largest files last, if combined with sort by size'
        ) { |v| @options[:r] = v }

        opt.parse!(ARGV)

        # 存在しないファイルを警告するため、先頭に挿入
        @options[:base] = ARGV.sort
        @options[:base].prepend(*ARGV.sort.reject { |v| File.exist?(v) }).uniq!
      end
    end

    def has?(name)
      @options.include?(name)
    end

    def get(name)
      @options[name]
    end
  end

  class Command
    def self.run
      options = Options.new
      is_dot_match = options.has?(:a) ? File::FNM_DOTMATCH : 0
      if options.has?(:base)
        p options[:base]
        # options[:base].each do |base|
        #   p base
        #   # Dir.glob('*', is_dot_match, base: base)
        # end
      else
        # files = Dir.glob('*', is_dot_match)
      end
    end
  end
end

LS::Command.run
# files.map! { |f| File.new(f,"r") }
#       a = `tput cols`
#       v = 1+  files.join("\t").size.div(a.chomp.to_i)
# p files.join("\t").size
# p a.chomp.to_i
#       p v
#       while files.size % v != 0
#         files << ""
#       end
#       files = files.each_slice(v).to_a.transpose
#       p files
#       files.each do |line|
#         puts line.join("\t")
#       end
