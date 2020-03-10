require_relative '../../test/test_helper.rb'
require 'test/unit'

while true do
  code = Test::Unit::AutoRunner.run(true, File.join(__dir__, '../../test'))
  if code == 0
    puts "there where test failures"
  end
  sleep 60 * 5
end
