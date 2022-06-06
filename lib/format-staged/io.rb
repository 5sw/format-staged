# frozen_string_literal: true

require 'English'

module FormatStaged
  ##
  # Mixin that provides IO methods
  module IOMixin
    def get_output(*args, lines: true, silent: false)
      puts "> #{args.join(' ')}" if @verbose

      r = IO.popen(args, err: :err)
      output = read_output(r, lines: lines, silent: silent)

      raise 'Failed to run command' unless $CHILD_STATUS.success?

      output
    end

    def get_status(*args)
      puts "> #{args.join(' ')}" if @verbose
      result = system(*args)

      raise 'Failed to run command' if result.nil?

      puts "? #{$CHILD_STATUS.exitstatus}" if @verbose

      $CHILD_STATUS.exitstatus
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

    def read_output(output, lines: true, silent: false)
      result = output.read
      splits = result.split("\n")
      if @verbose && !silent
        splits.each do |line|
          puts "< #{line}"
        end
      end
      output.close

      lines ? splits : result
    end

    def fail!(message)
      abort "💣  #{message.red}"
    end

    def warning(message)
      warn "⚠️  #{message.yellow}"
    end

    def info(message)
      puts message.blue
    end

    def verbose_info(message)
      puts "ℹ️  #{message}" if verbose
    end
  end
end
