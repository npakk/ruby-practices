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

  OutputData = Struct.new(:line_count, :word_count, :bytesize, :name)

  class Command
    require 'optparse'

    class << self
      def run
        option, filenames = parse_option_and_arguments

        if filenames.empty?
          output_stdin(option)
        else
          output_files(filenames, option)
        end
      end

      private

      def output_stdin(option)
        text_status = WC::TextStatus.new($stdin.readlines.join)
        max_length = get_max_length([text_status.line_count, text_status.word_count, text_status.bytesize])
        output_data = OutputData.new(text_status.line_count, text_status.word_count, text_status.bytesize)
        output(output_data, max_length, option)
      end

      def output_files(filenames, option)
        text_status_list = get_text_status_list(filenames)
        max_length = get_max_length_for_list(text_status_list)

        text_status_list.each do |status|
          next puts "wc: #{status.filename}: open: No such file or directory" if !status.file? && !status.directory?
          next puts "wc: #{status.filename}: read: Is a directory" if status.directory?

          output_data = OutputData.new(status.line_count, status.word_count, status.bytesize, status.filename)
          output(output_data, max_length, option)
        end

        line_count, word_count, bytesize = get_status_sum(text_status_list)
        output_data = OutputData.new(line_count, word_count, bytesize, 'total')
        output(output_data, max_length, option) if output_total?(text_status_list)
      end

      def parse_option_and_arguments
        option = {}
        OptionParser.new do |opt|
          opt.on(
            '-l',
            'The number of lines in each input file is written to the standard output.'
          ) { |v| option[:lines] = v }

          opt.parse!(ARGV)
        end
        [option, ARGV]
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

      def output(output_data, length, option)
        # Rubocopにより引数の個数5以下を求められたため、Structを採用
        text = format_value(output_data.line_count, length)
        text += format_value(output_data.word_count, length) + format_value(output_data.bytesize, length) unless option[:lines]
        text += "\s#{output_data.name}" unless output_data.name.nil?
        puts text
      end

      def format_value(value, max_length)
        value.to_s.rjust(max_length)
      end

      def get_max_length(max_status_list)
        # 本家wcコマンド同様に4文字分の余白を設け、最低8文字の長さにする
        [max_status_list.max.to_s.length + 4, 8].max
      end

      def get_max_length_for_list(status_list)
        max_status_list = [status_list.max_by(&:line_count).line_count,
                           status_list.max_by(&:word_count).word_count,
                           status_list.max_by(&:bytesize).bytesize]

        get_max_length(max_status_list)
      end

      def get_status_sum(status_list)
        [status_list.sum(&:line_count), status_list.sum(&:word_count), status_list.sum(&:bytesize)]
      end

      def output_total?(text_status_list)
        text_status_list.count(&:file?) > 1
      end
    end
  end
end

WC::Command.run
