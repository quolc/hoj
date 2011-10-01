# $ruby example.rb < test.in
#
# test.in
#	a(X):sa(X-1)
#	a(10)

require './logic'

code = ''
while line = STDIN.gets
	if line.length<2
		break
	end
	code = code+line
end
puts code

hcode = HCode.parse(code)
if !hcode
	puts "Invalid code."
	exit()
end
hcode.init()
while true do
	print hcode.turn()
	if hcode.isstop
		puts ' stopped.'
		break
	end
	if hcode.issle
		puts ' step limit exceeded.'
		break
	end
	if hcode.ismle
		puts ' memory limit exceeded.'
	end
end

