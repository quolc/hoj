# judge.rb - most simple implementation of herbert judging script using logic.rb
# writte by quolc (quolc.i@gmail.com)

# How to use:
#   require "./judge"
#   field = …
#   code = ...
#   hjudge = HJudge.new(field, code)
#   result = hjudge.judge()
#   if result.cleared
#       print "Cleared!"
#   end

require './logic'

class HJudge
    def initialize(field, code)
        fieldInput = field.split("\n")
    
        # Field Initialize
        @field = Array.new()
        @pushed = Array.new()
        @buttons = 0
        for i in 0...25 do
            @pushed[i] = Array.new()
            @field[i] = Array.new()
        end
        
        for i in 0...25 do
            for j in 0...25 do
                @pushed[j][i] = false
                case fieldInput[i][j]
                    when "*"
                        @field[j][i] = -1
                    when "o"
                        @field[j][i] = 1
                        @buttons += 1
                    when "."
                        @field[j][i] = 0
                    when "x"
                        @field[j][i] = 2
                    when "u"
                        @field[j][i] = 0
                        @x = j
                        @y = i
                end
            end
        end
        @pushed[@x][@y] = true
        @left = @buttons
        
        # Limitation Initialize
        @limit = fieldInput[25].to_i

        # Code Initialize
        @hCode = HCode.parse(code)
        if !@hCode
            puts "Invalid Code."
            exit()
        end
        @hCode.init()
    end

    def judge
        d = 0
        directions = [[0,-1], [1,0], [0,1], [-1,0]]
        
        while true do
            instruction = @hCode.turn()
            case instruction
                when "s"
                    nx=@x+directions[d][0]
                    ny=@y+directions[d][1]
                    if 0<=nx && nx<=24 && 0<=ny && ny<=24 && @field[nx][ny]<2
                        @x=nx
                        @y=ny
                    end
                    case @field[@x][@y]
                        when -1
                            for i in 0...25
                                for j in 0...25
                                    @pushed[i][j]=false
                                end
                            end
                            @left=@buttons
                        when 0
                            @pushed[@x][@y]=true
                        when 1
                            @left-=1 if !@pushed[@x][@y]
                            if @left==0
                                break
                            end
                            @pushed[@x][@y] = true
                    end
                when "r"
                    d += 1
                    d %= 4
                when "l"
                    d += 3
                    d %= 4
            end
            
            if @hCode.issle
                return HResult.new("Step Limit Exceeded")
            end
            
            if @hCode.ismle
                return HResult.new("Memory Limit Exceeded")
            end
            
            if @hCode.isstop
                return HResult.new("Herbert Stopped")
                break
            end
        end
    
        return HResult.new("Passed System Test")
    end
end

class HResult
    attr_accessor :status
    
    def initialize(status)
        @status = status
    end
end

# methods
def CountSrc(code)
	count=0
	for i in 0...code.length do
		case code[i]
		when "("
		when ")"
		when ","
		when ":"
		when "+"
		when "-"
		when "\n"
		else
			unless "0"<=code[i] && code[i]<="9" && "0"<=code[i-1] && code[i-1]<="9" then
				count+=1
			end
		end
	end
	return count
end