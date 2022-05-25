# frozen_string_literal: true

class FormatStaged
  class Entry
    PATTERN = /^:(?<src_mode>\d+) (?<dst_mode>\d+) (?<src_hash>[a-f0-9]+) (?<dst_hash>[a-f0-9]+) (?<status>[A-Z])(?<score>\d+)?\t(?<src_path>[^\t]+)(?:\t(?<dst_path>[^\t]+))?$/.freeze

    attr_reader :src_mode, :dst_mode, :src_hash, :dst_hash, :status, :score, :src_path, :dst_path, :path, :root

    def initialize(line, root:)
      matches = line.match(PATTERN) or raise "Cannot parse output #{line}"
      @src_mode = matches[:src_mode]
      @dst_mode = matches[:dst_mode]
      @src_hash = matches[:src_hash]
      @dst_hash = matches[:dst_hash]
      @status = matches[:status]
      @score = matches[:score]&.to_i
      @src_path = matches[:src_path]
      @dst_path = matches[:dst_path]
      @path = File.expand_path(@src_path, root)
      @root = root
    end

    def symlink?
      @dst_mode == '120000'
    end

    def matches?(patterns)
      result = false
      patterns.each do |pattern|
        result = true if File.fnmatch? pattern, path, File::FNM_EXTGLOB
      end
      result
    end
  end
end
