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

  it 'fails if all files are changed to already comitted version' do
    repo.file_in_tree 'test.test', 'x = y'
    repo.set_content 'test.test', 'x=y'
    repo.stage 'test.test'

    success = repo.run_formatter

    expect(success).to be_falsy
    expect(repo.get_content('test.test')).to eq('x = y')
  end

  it 'succeeds if there are excluded files to commit' do
    repo.file_in_tree 'test.test', 'x = y'
    repo.set_content 'test.test', 'x=y'
    repo.stage 'test.test'
    repo.set_content 'test.other', 'abc'
    repo.stage 'test.other'

    success = repo.run_formatter

    expect(success).to be_truthy
    expect(repo.get_content('test.test')).to eq('x = y')
  end

  it 'succeeds if there are no staged files' do
    expect(repo.run_formatter).to be_truthy
  end

  it 'succeeds if only excluded files are changed' do
    repo.set_content 'test.other', 'abc'
    repo.stage 'test.other'

    expect(repo.run_formatter).to be_truthy
  end

  it 'succeeds if one file is changed' do
    repo.file_in_tree 'test.test', 'x = y'
    repo.set_content 'test.test', 'x=y'
    repo.stage 'test.test'
    repo.set_content 'other.test', 'a=b'
    repo.stage 'other.test'

    success = repo.run_formatter

    expect(success).to be_truthy
    expect(repo.get_content('test.test')).to eq('x = y')
    expect(repo.get_content('other.test')).to eq('a = b')
  end

  it 'fails if a single file becomes empty' do
    repo.file_in_tree 'test.test', 'x = y'
    repo.set_content 'test.test', '#clear'
    repo.stage 'test.test'
    repo.set_content 'other.test', 'a=b'
    repo.stage 'other.test'

    success = repo.run_formatter

    expect(success).to be_falsy
    expect(repo.get_content('test.test')).to eq('#clear')
    expect(repo.get_content('other.test')).to eq('a = b')
  end

  it 'fails if the hook returns a nonzero status' do
    repo.set_content 'test.test', '#fail'
    repo.stage 'test.test'
    expect { repo.run_formatter }.to raise_error(RuntimeError) { |error|
      expect(error.message).to eq 'Error formatting test.test'
    }
  end

  it 'leaves files alone when write is false' do
    repo.set_content 'test.test', 'a=b'
    repo.stage 'test.test'

    expect(repo.run_formatter write: false).to be_truthy
    expect(repo.get_content('test.test')).to eq 'a=b'
    expect(repo.get_staged('test.test')).to eq 'a=b'
  end
end
