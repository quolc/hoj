require './judge'

ff = open(ARGV[0])
filed = ff.read
ff.close

fc = open(ARGV[1])
code = fc.read
fc.close

hjudge = HJudge.new(filed, code)
result = hjudge.judge()

puts result.status
