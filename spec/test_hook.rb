#!/usr/bin/env ruby
# frozen_string_literal: true

$stdin.readlines.each do |line|
  puts line.gsub(/([^\s]*)\s*=\s*(.*)/, '\1 = \2')
end
