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
