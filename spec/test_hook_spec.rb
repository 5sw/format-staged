# frozen_string_literal: true

describe 'Test Hook' do
  it 'adds spaces around =' do
    out = run 'a=b'

    expect(out).to eq('a = b')
  end

  it 'returns empty output if it as a #clear line' do
    out = run "a=b\n#clear\nc = d"
    expect(out).to eq ''
  end

  def run(input)
    IO.popen ['ruby', "#{__dir__}/test_hook.rb"], mode: File::RDWR do |io|
      io.write input
      io.close_write
      io.read.chomp
    end
  end
end
