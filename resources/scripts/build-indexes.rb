require_relative '../../lib/subway'

puts "Building index for jobs..."
Subway.connect(:jobs, Subway::CONNECTION_STRING, fscache: true).database
puts 'DONE.'
