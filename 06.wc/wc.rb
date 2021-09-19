#!/usr/bin/env ruby
# frozen_string_literal: true

module WC
  class Option
    require 'optparse'

    def initialize
      @option = {}
      OptionParser.new do |opt|
        opt.on(
          '-l',
          'The number of lines in each input file is written to the standard output.'
        ) { |v| @option[:lines] = v }

        opt.parse!(ARGV)
      end
    end

    def get(opt_name)
      @option[opt_name]
    end
  end

  class StringStatus
    attr_reader :filename

    def initialize(text)
      @text = if FileTest.file?(text)
                @filename = text
                File.read(text)
              elsif ARGV.empty? && !$stdin.tty?
                text
              else
                ''
              end
    end

    def linecount
      @text.lines.count
    end

    def wordcount
      @text.split(/\s+/).size
    end

    def bytesize
      @text.bytesize
    end
  end

  class Command
    class << self
      def run
        @option = Option.new
        @args = ARGV

        if @args.empty?
          stdin_status = WC::StringStatus.new($stdin.readlines.join)
          max_length = get_max_length(stdin_status)
          output(stdin_status, max_length)
        else
          file_status_list = get_file_status_list
          max_length = get_max_length(file_status_list)

          @args.each do |arg|
            next puts "wc: #{arg}: open: No such file or directory" unless File.exist?(arg)
            next puts "wc: #{arg}: read: Is a directory" if File.directory?(arg)

            file_status = file_status_list.find { |status| status.filename == arg }
            output(file_status, max_length, filename: file_status.filename)
          end

          # total
          output(file_status_list, max_length, filename: 'total') if output_total?
        end
      end

      private

      def get_file_status_list
        @args.map do |arg|
          WC::StringStatus.new(arg)
        end
      end

      def output(status_list, length, filename: '')
        line, word, size = get_total_status(status_list, sum: true)

        text = format_value(line, length)
        text += format_value(word, length) + format_value(size, length) unless @option.get(:lines)
        text += "\s#{filename}" unless filename.empty?
        puts text
      end

      def format_value(value, max_length)
        value.to_s.rjust(max_length)
      end

      def get_max_length(status_list)
        valiables = get_total_status(status_list, sum: false)

        # 本家wcコマンド同様に4文字分の余白を設ける
        valiables.max.to_s.length + 4
      end

      def get_total_status(status_list, sum:)
        unless status_list.instance_of?(Array)
          return [status_list.linecount,
                  status_list.wordcount,
                  status_list.bytesize]
        end

        if sum
          [status_list.sum(&:linecount),
           status_list.sum(&:wordcount),
           status_list.sum(&:bytesize)]
        else
          # linecount,wordcount,bytesizeそれぞれのmaxを取得してから、全体でみたときのmaxを取得する
          [status_list.max_by(&:linecount).linecount,
           status_list.max_by(&:wordcount).wordcount,
           status_list.max_by(&:bytesize).bytesize]
        end
      end

      def output_total?
        @args.find { |arg| FileTest.file?(arg) }
      end
    end
  end
end

WC::Command.run
