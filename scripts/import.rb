require 'csv'
require_relative '../../app/subway.rb'

if (ARGV.length != 2)
  puts "USAGE: #$0 REPO FILE"
  exit 1
end

table = CSV.table(ARGV[1])

txs = table.map do |row|
  [:'db.assert', [:id, row[:eid]*-1], row[:attr], row[:val]]
end

p Subway::Database.make(ARGV[0]).transact(txs)
