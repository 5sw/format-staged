# frozen_string_literal: true

require 'English'
class FormatStaged
  def get_output(*args, lines: true)
    puts "> #{args.join(' ')}" if @verbose

    output = IO.popen(args, err: :err) do |io|
      if lines
        io.readlines.map(&:chomp)
      else
        io.read
      end
    end

    if @verbose && lines
      output.each do |line|
        puts "< #{line}"
      end
    end

    raise 'Failed to run command' unless $CHILD_STATUS.success?

    output
  end

  def pipe_command(*args, source: nil)
    puts (source.nil? ? '> ' : '| ') + args.join(' ') if @verbose
    r, w = IO.pipe

    opts = {}
    opts[:in] = source unless source.nil?
    opts[:out] = w
    opts[:err] = :err

    pid = spawn(*args, **opts)

    w.close
    source&.close

    [pid, r]
  end
end
