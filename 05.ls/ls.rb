#!/usr/bin/env ruby
# frozen_string_literal: true

module LS
  class Option
    require 'optparse'

    ALL = :all
    LONG = :long
    REVERSE = :reverse

    def initialize
      @option = {}
      OptionParser.new do |opt|
        opt.on(
          '-a',
          'Include directory entries whose names begin with a dot (.).'
        ) { |v| @option[ALL] = v }
        opt.on(
          '-l',
          "(The lowercase letter ``ell''.)  List in long format.  (See below.)  A total sum for all the file sizes is output on a line before the long listing."
        ) { |v| @option[LONG] = v }
        opt.on(
          '-r',
          'Reverse the order of the sort to get reverse lexicographical order or the oldest entries first (or largest files last, if combined with sort by size'
        ) { |v| @option[REVERSE] = v }

        opt.parse(ARGV)
      end
    end

    def all?
      !!@option[ALL]
    end

    def long?
      !!@option[LONG]
    end

    def reverse?
      !!@option[REVERSE]
    end
  end

  class Argument
    attr_reader :paths

    def initialize
      @paths = ARGV.reject { |arg| arg.start_with?('-') }
    end

    def path_empty?
      @paths.empty?
    end

    def path_dir_multiple?
      @paths.count { |path| FileTest.directory?(path) } > 1
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

    SPECIAL_PERMISSIONS = {
      '0' => '',
      '1' => 't',
      '2' => 's',
      '4' => 's'
    }.freeze

    def initialize(path, dir)
      @file = File.basename(path)
      @file_stat = File.lstat(dir + path)
    end

    def name
      if @file_stat.symlink?
        "#{@file} -> #{File.readlink(@file)}"
      else
        @file
      end
    end

    def mode
      mode = format('%06d', @file_stat.mode.to_s(8))
      ftype_number = mode[0..1]
      special_permission_number = mode[2]
      owner_number = mode[3]
      group_number = mode[4]
      other_number = mode[5]

      ftype = FTYPES[ftype_number]
      owner = get_permission_or_special(special_permission_number == '2', owner_number, special_permission_number)
      group = get_permission_or_special(special_permission_number == '4', group_number, special_permission_number)
      other = get_permission_or_special(special_permission_number == '1', other_number, special_permission_number)

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
      time = @file_stat.mtime.strftime('%H:%M')
      "#{month.to_s.rjust(2)} #{day.to_s.rjust(2)} #{time}"
    end

    def blocks
      @file_stat.blocks
    end

    private

    def get_permission_or_special(is_special, authority_number, special_permission_number)
      permission = PERMISSIONS[authority_number]

      if is_special
        special_permission = SPECIAL_PERMISSIONS[special_permission_number]
        special_permission.upcase unless permission[2] == 'x'
      else
        permission
      end
    end
  end

  class Command
    class << self
      HORIZONTAL_COLUMN = 3

      def run
        option = Option.new
        argument = Argument.new

        output_not_existance_path(argument.paths)
        files, dirs = get_existance_paths(argument.paths, option.reverse?)

        output_files(files, option)
        output_dirs(dirs, option, argument)
      end

      private

      def output_not_existance_path(paths)
        paths.sort!.each do |path|
          puts "ls: #{path}: No such file or directory" unless FileTest.exist?(path)
        end
      end

      def get_existance_paths(paths, is_reverse)
        # 本家lsコマンドと合わせるため、パスをファイル < ディレクトリの順に並べ、その中でsortを行う
        files = paths.select { |path| FileTest.file?(path) }
        dirs = paths.select { |path| FileTest.directory?(path) }

        files.sort! do |a, b|
          is_reverse ? b <=> a : a <=> b
        end
        is_reverse ? dirs.reverse! : dirs.sort!

        [files, dirs]
      end

      def glob_dir(dir, option)
        files = Dir.glob('*', option.all? ? File::FNM_DOTMATCH : 0, base: dir)

        if option.reverse?
          files.reverse
        else
          files
        end
      end

      def get_status(files, dir = '')
        files.map do |file|
          LS::FileStatus.new(file, dir)
        end
      end

      def output_dirs(dirs, option, argument)
        dirs << './' if argument.path_empty?
        dirs.each do |dir|
          output_dirname(dir) if argument.path_dir_multiple?

          files = glob_dir(dir, option)

          if option.long?
            files_status = get_status(files, dir)
            output_vertical(files_status, is_total_output: true)
          else
            output_horizontal(files)
          end
        end
      end

      def output_files(files, option)
        return if files.empty?

        if option.long?
          files_status = get_status(files)
          output_vertical(files_status)
        else
          output_horizontal(files)
        end
      end

      def output_dirname(dir)
        puts "\n#{dir}:"
      end

      def output_vertical(files_status, is_total_output: false)
        puts "total #{files_status.sum(&:blocks)}" if is_total_output

        max_length_nlink = get_max_length(files_status.map(&:nlink))
        max_length_user = get_max_length(files_status.map(&:user))
        max_length_group = get_max_length(files_status.map(&:group))
        max_length_size = get_max_length(files_status.map(&:size))

        files_status.each do |file_status|
          mode = file_status.mode.to_s
          nlink = file_status.nlink.to_s.rjust(max_length_nlink)
          user = file_status.user.rjust(max_length_user)
          group = file_status.group.rjust(max_length_group)
          size = file_status.size.to_s.rjust(max_length_size)
          time = file_status.time
          name = file_status.name

          puts "#{mode}  #{nlink} #{user}  #{group}  #{size} #{time} #{name}"
        end
      end

      def output_horizontal(files)
        max_length = get_max_length(files)

        files << '' while files.size % HORIZONTAL_COLUMN != 0
        row_count = files.size / HORIZONTAL_COLUMN
        sliced_files = files.each_slice(row_count).to_a

        sliced_files.transpose.each do |row|
          output_lists = row.map { |file| file.ljust(max_length) }
          puts output_lists.join("\t")
        end
      end

      def get_max_length(list)
        list.map(&:to_s).max_by(&:length).length
      end
    end
  end
end

LS::Command.run
