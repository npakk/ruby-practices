#!/usr/bin/env ruby
# frozen_string_literal: true

module WC
  class TextStatus
    attr_reader :filename

    def initialize(text, filename = '', is_file: false, is_directory: false)
      @text = text
      @filename = filename
      @is_file = is_file
      @is_directory = is_directory
    end

    def line_count
      @text.lines.count
    end

    def word_count
      @text.split(/\s+/).size
    end

    def bytesize
      @text.bytesize
    end

    def file?
      @is_file
    end

    def directory?
      @is_directory
    end
  end

  class Command
    require 'optparse'

    class << self
      def run
        filenames = parse_option_and_arguments!

        if filenames.empty?
          output_stdin
        else
          output_files(filenames)
        end
      end

      private

      def output_stdin
        text_status = WC::TextStatus.new($stdin.readlines.join)
        max_counts = get_max_counts([text_status.line_count, text_status.word_count, text_status.bytesize])
        max_length = get_max_length(max_counts)
        output(text_status.line_count, text_status.word_count, text_status.bytesize, max_length)
      end

      def output_files(filenames)
        text_status_list = get_text_status_list(filenames)
        max_counts = get_max_counts(text_status_list)
        max_length = get_max_length(max_counts)

        text_status_list.each do |status|
          next puts "wc: #{status.filename}: open: No such file or directory" if !status.file? && !status.directory?
          next puts "wc: #{status.filename}: read: Is a directory" if status.directory?

          output(status.line_count, status.word_count, status.bytesize, max_length, filename: status.filename)
        end

        line_count, word_count, bytesize = get_status_sum(text_status_list)
        output(line_count, word_count, bytesize, max_length, filename: 'total') if output_total?(text_status_list)
      end

      def parse_option_and_arguments!
        @option = {}
        OptionParser.new do |opt|
          opt.on(
            '-l',
            'The number of lines in each input file is written to the standard output.'
          ) { |v| @option[:lines] = v }

          opt.parse!(ARGV)
        end
        ARGV
      end

      def get_text_status_list(filenames)
        filenames.map do |filename|
          if FileTest.file?(filename)
            WC::TextStatus.new(File.read(filename), filename, is_file: true)
          else
            is_directory = FileTest.directory?(filename)
            WC::TextStatus.new('', filename, is_file: false, is_directory: is_directory)
          end
        end
      end

      def output(line_count, word_count, bytesize, length, filename: '')
        text = format_value(line_count, length)
        text += format_value(word_count, length) + format_value(bytesize, length) unless @option[:lines]
        text += "\s#{filename}" unless filename.empty?
        puts text
      end

      def format_value(value, max_length)
        value.to_s.rjust(max_length)
      end

      def get_max_counts(status_or_status_list)
        get_status_max(status_or_status_list)
      end

      def get_max_length(max_counts)
        # 本家wcコマンド同様に4文字分の余白を設け、最低8文字の長さにする
        [max_counts.max.to_s.length + 4, 8].max
      end

      def get_status_sum(status_list)
        [status_list.sum(&:line_count), status_list.sum(&:word_count), status_list.sum(&:bytesize)]
      end

      def get_status_max(status_list)
        [status_list.max_by(&:line_count).line_count,
         status_list.max_by(&:word_count).word_count,
         status_list.max_by(&:bytesize).bytesize]
      end

      def output_total?(text_status_list)
        text_status_list.count(&:file?) > 1
      end
    end
  end
end

WC::Command.run
