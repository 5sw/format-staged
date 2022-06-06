# frozen_string_literal: true

require_relative 'git'

require 'format_staged'

describe FormatStaged do
  def repo
    @repo ||= Git.new_repo do |repo|
      repo.file_in_tree 'origin.test', 'x = y'
    end
  end

  after :each do
    @repo&.cleanup
    @repo = nil
  end

  it 'updates staged file and working copy' do
    repo.set_content 'test.test', 'a=b'
    repo.stage 'test.test'
    success = repo.run_formatter

    expect(success).to be_truthy
    expect(repo.get_staged('test.test')).to eq('a = b')
    expect(repo.get_content('test.test')).to eq('a = b')
  end

  it 'leaves other changes in working copy' do
    repo.set_content 'test.test', "x=y\na=b\n"
    repo.stage 'test.test'
    repo.set_content 'test.test', 'abc'
    success = repo.run_formatter

    expect(success).to be_truthy
    expect(repo.get_content('test.test')).to eq('abc')
    expect(repo.get_staged('test.test')).to eq("x = y\na = b")
  end

  it 'merges update to working copy' do
    repo.set_content 'test.test', "x=y\n#stuff\n"
    repo.stage 'test.test'
    repo.set_content 'test.test', "x=y\n#stuff\nmore stuff\n"
    success = repo.run_formatter

    expect(success).to be_truthy
    expect(repo.get_content('test.test')).to eq("x = y\n#stuff\nmore stuff")
    expect(repo.get_staged('test.test')).to eq("x = y\n#stuff")
  end

  it 'only touches files matching the given pattern' do
    repo.set_content 'test.other', 'x=y'
    repo.stage 'test.other'
    success = repo.run_formatter

    expect(success).to be_truthy
    expect(repo.get_content('test.other')).to eq('x=y')
  end

  it 'fails if files are changed to already comitted version' do
    repo.file_in_tree 'test.test', 'x = y'
    repo.set_content 'test.test', 'x=y'
    repo.stage 'test.test'

    success = repo.run_formatter

    expect(success).to be_falsy
    expect(repo.get_content('test.test')).to eq('x = y')
  end

  it 'succeeds if there are no staged files' do
    expect(repo.run_formatter).to be_truthy
  end
end
