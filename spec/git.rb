# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'English'

##
# Test helpers for managing a git repository
module Git
  ##
  # A git repository
  class Repo
    attr_reader :path

    def initialize
      @path = Dir.mktmpdir

      git 'init'
      git 'branch', '-m', 'main'
      git 'config', 'user.name', 'Test User'
      git 'config', 'user.email', 'test@example.com'
    end

    def file_in_tree(name, content)
      set_content name, content
      stage name
      commit "Add #{name}"
    end

    def set_content(name, content)
      absolute = Pathname.new(path) + name

      FileUtils.mkdir_p absolute.dirname
      File.write absolute, content.end_with?("\n") ? content : "#{content}\n"
    end

    def get_content(name)
      File.read(Pathname.new(path) + name).chomp
    end

    def get_staged(name)
      git 'show', ":#{name}"
    end

    def stage(file)
      git 'add', file
    end

    def commit(message)
      git 'commit', '-m', message
    end

    def content(file)
      git 'show', ":#{file}"
    end

    def cleanup
      FileUtils.remove_entry path
    end

    def git(*cmd)
      in_repo do
        output = IO.popen(['git'] + cmd) do |io|
          io.read.chomp
        end

        raise 'Failed to run git' unless $CHILD_STATUS.success?

        output
      end
    end

    def in_repo(&block)
      Dir.chdir path, &block
    end

    def run_formatter
      in_repo do
        FormatStaged.run formatter: "#{__dir__}/test_hook.rb {}", patterns: ['*.test']
      end
    end
  end

  def self.new_repo
    repo = Repo.new
    yield repo if block_given?
    repo
  end
end
