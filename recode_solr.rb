#!/usr/bin/env ruby

puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
first = true
while line = gets
#  line.tr!("\u000b\u001a\u001c\u001f","")
  line.tr!("\u0001-\u001f","")
  first ? line.gsub!(/^(movie|person)_(\d+):<doc>/, '\1_\2:<add><doc>') : line.gsub!(/^(movie|person)_(\d+):<doc>/, '\1_\2:</doc><doc>')
  line.gsub!(/^(movie|person)_\d+:/,"")
  first = false
  puts line
end
puts "</doc></add>"
