# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'format-staged/version'

Gem::Specification.new do |s|
  s.name        = 'format-staged'
  s.version     = FormatStaged::VERSION
  s.summary     = 'git format staged!'
  s.description = 'git format staged'
  s.authors     = ['Sven Weidauer']
  s.email       = 'sven@5sw.de'
  s.files       = Dir['lib/**/*.rb']
  s.executables << 'git-format-staged'
  s.homepage    = 'https://github.com/5sw/format-staged'
  s.license     = 'MIT'
  s.required_ruby_version = '~> 2.7'

  s.add_dependency 'colorize'

  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rubocop', '~> 1.29'
  s.add_development_dependency 'rubocop-rake', '~> 0.6'
  s.add_development_dependency 'rspec'

  s.metadata = {
    'rubygems_mfa_required' => 'true'
  }
end
