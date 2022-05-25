# frozen_string_literal: true

require 'English'
require 'format-staged/version'
require 'format-staged/entry'
require 'format-staged/io'
require 'shellwords'

class FormatStaged
  attr_reader :formatter, :patterns, :update, :write, :verbose

  def initialize(formatter:, patterns:, update: true, write: true, verbose: true)
    @formatter = formatter
    @patterns = patterns
    @update = update
    @write = write
    @verbose = verbose
  end

  def run
    root = get_output('git', 'rev-parse', '--show-toplevel').first

    files = get_output('git', 'diff-index', '--cached', '--diff-filter=AM', '--no-renames', 'HEAD')
            .map { |line| Entry.new(line, root: root) }
            .reject(&:symlink?)
            .filter { |entry| entry.matches?(@patterns) }

    files.each do |file|
      format_file(file)
    end
  end

  def format_file(file)
    new_hash = format_object file

    return true unless write

    if new_hash == file.dst_hash
      puts "Unchanged #{file.src_path}"
      return false
    end

    if object_is_empty new_hash
      puts "Skipping #{file.src_path}, formatted file is empty"
      return false
    end

    replace_file_in_index file, new_hash

    if update
      begin
        patch_working_file file, new_hash
      rescue StandardError => e
        puts "Warning: failed updating #{file.src_path} in working copy: #{e}"
      end
    end

    true
  end

  def format_object(file)
    puts "Formatting #{file.src_path}"

    format_command = formatter.sub('{}', file.src_path.shellescape)

    pid1, r = pipe_command 'git', 'cat-file', '-p', file.dst_hash
    pid2, r = pipe_command format_command, source: r
    pid3, r = pipe_command 'git', 'hash-object', '-w', '--stdin', source: r

    result = read_output(r, lines: false).chomp

    Process.wait pid1
    raise "Cannot read #{file.dst_hash} from object database" unless $CHILD_STATUS.success?

    Process.wait pid2
    raise "Error formatting #{file.src_path}" unless $CHILD_STATUS.success?

    Process.wait pid3
    raise 'Error writing formatted file back to object database' unless $CHILD_STATUS.success? && !result.empty?

    result
  end

  def object_is_empty(hash)
    size = get_output('git', 'cat-file', '-s', hash).first.to_i
    size.zero?
  end

  def patch_working_file(file, new_hash)
    patch = get_output 'git', 'diff', file.dst_hash, new_hash, lines: false, silent: true
    patch.gsub! "a/#{file.dst_hash}", "a/#{file.src_path}"
    patch.gsub! "b/#{new_hash}", "b/#{file.src_path}"

    input, patch_out = IO.pipe
    pid, r = pipe_command 'git', 'apply', '-', source: input

    patch_out.write patch
    patch_out.close

    read_output r

    Process.wait pid
    raise 'Error applying patch' unless $CHILD_STATUS.success?
  end

  def replace_file_in_index(file, new_hash)
    get_output 'git', 'update-index', '--cacheinfo', "#{file.dst_mode},#{new_hash},#{file.src_path}"
  end
end
