# frozen_string_literal: true

require 'English'

class FormatStaged
  def get_output(*args, lines: true, silent: false)
    puts "> #{args.join(' ')}" if @verbose

    r = IO.popen(args, err: :err)
    output = read_output(r, lines: lines, silent: silent)

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

  def read_output(r, lines: true, silent: false)
    result = r.read
    splits = result.split("\n")
    if @verbose && !silent
      splits.each do |line|
        puts "< #{line}"
      end
    end
    r.close

    lines ? splits : result
  end
end
