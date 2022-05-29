# frozen_string_literal: true

require_relative 'git'

require 'format_staged'

describe FormatStaged do
  def repo
    @repo ||= Git.new_repo do |r|
      r.file_in_tree 'index.js', <<~CONTENT
        function foo () {
          return 'foo'
        }
      CONTENT
    end
  end

  after :each do
    @repo&.cleanup
    @repo = nil
  end
end
