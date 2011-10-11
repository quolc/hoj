# How to use:
#   $ruby example.rb field.in code.in
#

require './judge'

ff = open(ARGV[0])
filed = ff.read
ff.close

fc = open(ARGV[1])
code = fc.read
fc.close

hJudge = HJudge.new(filed, code)
result = hJudge.judge()

puts result.status
