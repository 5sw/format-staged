#!/usr/bin/env ruby
# frozen_string_literal: true

output = []
$stdin.readlines.each do |line|
  exit 0 if line.chomp == '#clear'
  output << line.gsub(/([^\s]*)\s*=\s*(.*)/, '\1 = \2')
end

output.each do |line|
  puts line
end
