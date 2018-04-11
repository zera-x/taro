require 'csv'
require_relative '../../app/subway.rb'

if (ARGV.length != 2)
  puts "USAGE: #$0 REPO FILE"
  exit 1
end

#txs = Subway::Transactor.read_json(IO.read(ARGV[1], encoding: 'utf-16le', mode: 'rb'))
txs = Subway::Transactor.read_json(IO.read(ARGV[1]))
p Subway::Database.make(ARGV[0]).transact(txs)
