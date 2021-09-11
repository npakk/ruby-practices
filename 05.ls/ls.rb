#!/usr/bin/env ruby
# frozen_string_literal: true

module LS
  class Options
    require 'optparse'

    ALL = :all
    LONG = :long
    REVERSE = :reverse

    attr_reader :files

    def initialize
      @options = {}
      OptionParser.new do |opt|
        opt.on(
          '-a',
          'Include directory entries whose names begin with a dot (.).'
        ) { |v| @options[ALL] = v }
        opt.on(
          '-l',
          "(The lowercase letter ``ell''.)  List in long format.  (See below.)  A total sum for all the file sizes is output on a line before the long listing."
        ) { |v| @options[LONG] = v }
        opt.on(
          '-r',
          'Reverse the order of the sort to get reverse lexicographical order or the oldest entries first (or largest files last, if combined with sort by size'
        ) { |v| @options[REVERSE] = v }

        opt.parse!(ARGV)

        break if ARGV.empty?

        @files = specified_files
      end
    end

    def has?(name)
      @options.include?(name)
    end

    def get(name)
      @options[name]
    end

    def file_match
      @options[ALL] ? File::FNM_DOTMATCH : 0
    end

    private

    def specified_files
      # ファイルを、存在しないもの < ファイル < ディレクトリの順に並べる
      not_exist = ARGV.reject { |v| File.exist?(v) }
      files = ARGV.select { |v| File.file?(v) }
      dirs = ARGV.select { |v| File.directory?(v) }

      not_exist.sort!
      files.sort! do |a, b|
        @options[REVERSE] ? b <=> a : a <=> b
      end
      @options[REVERSE] ? dirs.reverse! : dirs.sort!

      # ファイル指定されたものかどうか後続処理で区別するため、配列のまま返す
      [*not_exist, files, *dirs]
    end
  end

  class FileStatus
    require 'etc'

    FTYPES = {
      '01' => 'p',
      '02' => 'c',
      '04' => 'd',
      '06' => 'b',
      '10' => '-',
      '12' => 'l',
      '14' => 's'
    }.freeze

    PERMISSIONS = {
      '7' => 'rwx',
      '6' => 'rw-',
      '5' => 'r-x',
      '4' => 'r--',
      '3' => '-wx',
      '2' => '-w-',
      '1' => '--x'
    }.freeze

    S_PERMISSIONS = {
      '0' => '',
      '1' => 't',
      '2' => 's',
      '4' => 's'
    }.freeze

    def initialize(file)
      @file = file
      @file_stat = File.lstat(file)
    end

    def name
      if @file_stat.symlink?
        "#{File.basename(@file)} -> #{File.readlink(@file)}"
      else
        File.basename(@file)
      end
    end

    def mode
      mode = format('%06d', @file_stat.mode.to_s(8))
      ftype = mode[0..1]
      s_permission = mode[2]
      owner = mode[3]
      group = mode[4]
      other = mode[5]

      ftype = FTYPES[ftype]

      owner = PERMISSIONS[owner]
      group = PERMISSIONS[group]
      other = PERMISSIONS[other]

      other = s_permission != '1' ? other : format_special_permission(other, S_PERMISSIONS[s_permission])
      owner = s_permission != '2' ? owner : format_special_permission(owner, S_PERMISSIONS[s_permission])
      group = s_permission != '4' ? group : format_special_permission(group, S_PERMISSIONS[s_permission])

      ftype + owner + group + other
    end

    def nlink
      @file_stat.nlink
    end

    def user
      Etc.getpwuid(@file_stat.uid).name
    end

    def group
      Etc.getgrgid(@file_stat.gid).name
    end

    def size
      @file_stat.size
    end

    def time
      month = @file_stat.mtime.month
      day = @file_stat.mtime.day
      "#{month.to_s.rjust(2)} #{day.to_s.rjust(2)} #{@file_stat.mtime.strftime('%H:%M')}"
    end

    def blocks
      @file_stat.blocks
    end

    private

    def format_special_permission(value, s_permission)
      value[2] == 'x' ? value[0..1] + s_permission : value[0..1] + s_permission.upcase
    end
  end

  class Command
    class << self
      HORIZONTAL_COLUMN = 3

      def run
        options = Options.new
        files = options.files.nil? ? ['./'] : delete_no_such_file(options.files)

        files.each do |file|
          files = if file.instance_of?(Array)
                    file
                  else
                    # ディレクトリを明示されないかぎり、ディレクトリ名を出力しない
                    puts "\n#{file}:" unless options.files.nil?
                    glob = Dir.glob('*', options.file_match, base: file)
                    options.get(Options::REVERSE) ? glob.reverse : glob
                  end

          options.has?(Options::LONG) ? vertical_formatter(files, file) : horizontal_formatter(files)
        end
      end

      def vertical_formatter(files, file)
        file_stat = { mode: [], nlink: [], user: [], group: [], size: [], time: [], name: [], blocks: [] }
        files.each do |v|
          s = LS::FileStatus.new("#{file.instance_of?(Array) ? './' : file}#{v}")
          file_stat[:mode] << s.mode
          file_stat[:nlink] << s.nlink
          file_stat[:user] << s.user
          file_stat[:group] << s.group
          file_stat[:size] << s.size
          file_stat[:time] << s.time
          file_stat[:name] << s.name
          file_stat[:blocks] << s.blocks
        end

        # ファイル指定されたものは、ブロックサイズを表示しない
        puts "total #{file_stat[:blocks].sum}" unless file.instance_of?(Array)

        w_nlink, w_user, w_group, w_size = *get_max_length_file_stat(file_stat)

        file_stat[:mode].each_with_index do |v, i|
          puts "#{v}  #{file_stat[:nlink][i].rjust(w_nlink)} #{file_stat[:user][i].rjust(w_user)}  #{file_stat[:group][i].rjust(w_group)}  " \
          "#{file_stat[:size][i].rjust(w_size)} #{file_stat[:time][i]} #{file_stat[:name][i]}"
        end
      end

      def horizontal_formatter(files)
        files << '' while files.size % HORIZONTAL_COLUMN != 0
        files = files.each_slice(files.size / HORIZONTAL_COLUMN).to_a
        # 列ごとのファイル名長のギャップを空白で埋める
        files.map! do |i|
          max_length = i.max_by(&:length).size
          i.map do |j|
            j.ljust(max_length)
          end
        end
        files.transpose.each do |line|
          puts line.join("\t\t")
        end
      end

      private

      def delete_no_such_file(files)
        no_such_files = files.select { |v| v.instance_of?(String) && !File.exist?(v) }
        no_such_files.each { |v| puts "ls: #{v}: No such file or directory" }
        files - no_such_files
      end

      def get_max_length_file_stat(value)
        length = []
        length << get_max_length(value[:nlink])
        length << get_max_length(value[:user])
        length << get_max_length(value[:group])
        length << get_max_length(value[:size])
        length
      end

      def get_max_length(value)
        value.map!(&:to_s).max_by(&:length).size
      end
    end
  end
end

LS::Command.run
