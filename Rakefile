# frozen_string_literal: true

require 'bundler/gem_tasks'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'rubocop/rake_task'

desc 'Run RuboCop'
RuboCop::RakeTask.new(:lint)

desc 'Run RuboCop for GitHub'
RuboCop::RakeTask.new(:lint_github) do |t|
  t.requires << 'code_scanning'
  t.formatters << 'CodeScanning::SarifFormatter'
  t.options << '-o' << 'rubocop.sarif'
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
