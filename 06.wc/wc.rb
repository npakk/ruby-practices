#!/usr/bin/env ruby
# frozen_string_literal: true

module WC
  class Options
    require 'optparse'

    LINES = :lines

    attr_reader :files

    def initialize
      @options = {}
      OptionParser.new do |opt|
        opt.on(
          '-l',
          'The number of lines in each input file is written to the standard output.'
        ) { |v| @options[LINES] = v }

        opt.parse!(ARGV)

        break if ARGV.empty?

        @files = ARGV
      end
    end

    def has?(name)
      @options.include?(name)
    end

    def get(name)
      @options[name]
    end
  end

  class FileStatus
    def initialize(file)
      @file = file
    end

    def line_count
      File.read(@file).lines.count
    end

    def word_count
      File.read(@file).split(/\s+/).size
    end

    def file_size
      File.size(@file)
    end
  end

  OutputData = Struct.new(:file, :max_length, :line_count, :word_count, :file_size)

  class Command
    class << self
      def run
        options = Options.new

        if options.files.nil?
          stdin = $stdin.readlines.join
          return output(OutputData.new(nil, 7, stdin.lines.count, stdin.split(/\s+/).size, stdin.size), options)
        end

        line_counts, word_counts, file_sizes = get_file_status(options)
        max_length = get_max_length([*line_counts, *word_counts, *file_sizes])

        options.files.zip(line_counts, word_counts, file_sizes).each do |v|
          file, line_count, word_count, file_size = v
          next puts "wc: #{file}: open: No such file or directory" unless File.exist?(file)
          next puts "wc: #{file}: read: Is a directory" if File.directory?(file)

          output(OutputData.new(file, max_length, line_count, word_count, file_size), options)
        end

        output(OutputData.new('total', max_length, line_counts.sum, word_counts.sum, file_sizes.sum), options) if options.files.size > 1
      end

      private

      def get_file_status(options)
        line_counts = []
        word_counts = []
        file_sizes = []
        options.files.each do |file|
          s = WC::FileStatus.new(file) if File.exist?(file) && !File.directory?(file)
          line_counts << (s&.line_count || 0)
          word_counts << (s&.word_count || 0)
          file_sizes << (s&.file_size || 0)
        end
        [line_counts, word_counts, file_sizes]
      end

      def output(data, options = nil)
        return puts " #{rjust_formatter(data.max_length, data.line_count)} #{data.file}" if options&.get(Options::LINES)

        str = " #{rjust_formatter(data.max_length, data.line_count)}"\
              " #{rjust_formatter(data.max_length, data.word_count)}"\
              " #{rjust_formatter(data.max_length, data.file_size)}"\
              " #{data.file}"
        puts str
      end

      def rjust_formatter(max_length, value)
        value.to_s.rjust(max_length)
      end

      def get_max_length(value)
        # 本家wcコマンド同様に3文字分の余白を設ける
        value.max.to_s.length + 3
      end
    end
  end
end

WC::Command.run
