# frozen_string_literal: true

require_relative 'entry'
require_relative 'io'

require 'shellwords'
require 'colorize'
require 'English'

module FormatStaged
  ##
  # Runs staged changes through a formatting tool
  class Job
    include IOMixin

    attr_reader :formatter, :patterns, :update, :write, :verbose

    def initialize(formatter:, patterns:, **options)
      validate_patterns patterns

      @formatter = formatter
      @patterns = patterns
      @update = options.fetch(:update, true)
      @write = options.fetch(:write, true)
      @verbose = options.fetch(:verbose, true)

      String.disable_colorization = !options.fetch(:color_output, $stdout.isatty)
    end

    def run
      files = matching_files(repo_root)
      if files.empty?
        info 'No staged file matching pattern. Done'
        return true
      end

      formatted = files.filter { |file| format_file file }

      return false unless formatted.size == files.size

      quiet = @verbose ? [] : ['--quiet']
      return !write || get_status('git', 'diff-index', '--cached', '--exit-code', *quiet, 'HEAD') != 0
    end

    def repo_root
      verbose_info 'Finding repository root'
      root = get_output('git', 'rev-parse', '--show-toplevel', lines: false).chomp
      verbose_info "Repo at #{root}"

      root
    end

    def matching_files(root)
      verbose_info 'Listing staged files'

      get_output('git', 'diff-index', '--cached', '--diff-filter=AM', '--no-renames', 'HEAD')
        .map { |line| Entry.new(line, root: root) }
        .reject(&:symlink?)
        .filter { |entry| entry.matches?(@patterns) }
    end

    def format_file(file)
      new_hash = format_object file

      return true unless write

      if new_hash == file.dst_hash
        info "Unchanged #{file.src_path}"
        return true
      end

      if object_is_empty new_hash
        info "Skipping #{file.src_path}, formatted file is empty"
        return false
      end

      replace_file_in_index file, new_hash
      update_working_copy file, new_hash

      if new_hash == file.src_hash
        info "File #{file.src_path} equal to comitted"
        return true
      end

      true
    end

    def update_working_copy(file, new_hash)
      return unless update

      begin
        patch_working_file file, new_hash
      rescue StandardError => e
        warning "failed updating #{file.src_path} in working copy: #{e}"
      end
    end

    def format_object(file)
      info "Formatting #{file.src_path}"

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
      info 'Updating working copy'

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

    def validate_patterns(patterns)
      patterns.each do |pattern|
        fail! "Negative pattern '#{pattern}' is not yet supported" if pattern.start_with? '!'
      end
    end
  end
end
