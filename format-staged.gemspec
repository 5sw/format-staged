lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'format-staged/version'

Gem::Specification.new do |s|
  s.name        = 'format-staged'
  s.version     = FormatStaged::VERSION
  s.summary     = "git format staged!"
  s.description = "git format staged"
  s.authors     = ["Sven Weidauer"]
  s.email       = 'sven@5sw.de'
  s.files       = Dir['lib/**/*.rb']
  s.executables << 'git-format-staged'
  s.homepage    = 'https://github.com/5sw/format-staged'
  s.license     = 'MIT'
end
