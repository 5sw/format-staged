# frozen_string_literal: true

require 'English'

describe 'Test Hook' do
  it 'adds spaces around =' do
    out = run 'a=b'

    expect(out).to eq('a = b')
  end

  it 'returns empty output if it as a #clear line' do
    out = run "a=b\n#clear\nc = d"
    expect(out).to eq ''
  end

  it 'fails with a #fail line' do
    expect { run '#fail' }.to raise_error(RuntimeError) { |error|
      expect(error.message).to eq('Cannot run test_hook.rb')
    }
  end

  def run(input)
    result = IO.popen ['ruby', "#{__dir__}/test_hook.rb"], mode: File::RDWR do |io|
      io.write input
      io.close_write
      io.read.chomp
    end

    raise 'Cannot run test_hook.rb' unless $CHILD_STATUS.success?

    result
  end
end
