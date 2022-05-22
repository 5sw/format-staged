class FormatStaged 
  def get_output(*args, lines: true)
    puts '> ' + args.join(' ') if @verbose
    
    output = IO.popen(args, err: :err) do |io|
      if lines
        io.readlines.map { |l| l.chomp }
      else
        io.read
      end
    end
    
    if @verbose and lines
      output.each do |line|
        puts "< #{line}"
      end
    end
    
    raise "Failed to run command" unless $?.success?
    
    output
  end
  
  def pipe_command(*args, source: nil)
    puts (source.nil? ? '> ' : '| ') + args.join(' ')  if @verbose
    r, w = IO.pipe
    
    opts = {}
    opts[:in] = source unless source.nil?
    opts[:out] = w
    opts[:err] = :err
    
    pid = spawn(*args, **opts)
    
    w.close
    source &.close
    
    return [pid, r]
  end  
end
