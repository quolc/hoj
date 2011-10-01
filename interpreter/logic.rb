# Herbert Parser + Interpreter + Judge in Ruby
# This script judges submission of HJO after checking syntax and typing.
# 
# written by quolc (quolc.i@gmail.com)

# How to use:
#   require "./logic"
#   code = "ssss"
#   hcode = HCode.parse(code)
#   hcode.init()
#   while true do
#       print hcode.turn()
#       if hcode.isstop
#           print "stopped."
#           break
#       end
#   end

class HCode
  SLE = 1000000
  FunctionLimit = 100

  attr_accessor :instructions
  attr_accessor :functions
  attr_accessor :step

  #class methods
  def HCode.parse(str)
    hcode = HCode.new()
    funcs = Array.new()

    # get signatures
    lines = str.split("\n")
    lines.delete("")
    if lines.length==0
#      puts("No Code")
      return nil
    end
    if lines.length > HCode::FunctionLimit
      #puts("Too Many Funtions")
      return nil
    end
    for i in 0...lines.length-1 do
      temp = HFunc.parse(lines[i])
      if !temp
        #puts("Signature Error in line #{i+1}")
        return nil
      end
      funcs.push(temp)
    end
    funcs.push(HFunc.parse("@:"+lines[-1]))

    # signature collision check
    for i in 0...funcs.length-1 do
      for j in i+1...funcs.length do
        if funcs[i].name==funcs[j].name
          #puts("Signature Collision (\"#{funcs[i].name}\")")
          return nil
        end
      end
    end

    # symbol check
    former=10000
    while true do
      leftarg=0
      funcs.each do |f|
        return nil if !HFunc.check(f, funcs)
        f.args.each do |arg|
          leftarg+=1 if arg.type==-1
        end
      end
      break if leftarg==0
      if leftarg==former
        #puts "Type Inference Failed."
        return nil
      end
      former=leftarg
    end

    funcs.each do |func|
      hcode.functions[func.name]=func
    end

    return hcode
  end

  #instance methods
  def initialize()
    @functions = Hash.new()
  end

  def init
    @step=0
    @instructions=Array.new()
    start=@functions["@"]
    @instructions.concat(start.code)
  end
  
  def turn
    current = @instructions[0]
    @instructions.shift()
    @step+=1

    if current=="s" || current=="l" || current=="r"
      return current
    end

    depth=0
    args=Array.new()
    arg=Array.new()
    i=0
    if @functions[current].argsnum>0
      for i in 1...@instructions.length do
        case @instructions[i]
        when "("
          depth+=1
          arg<<@instructions[i]
        when ","
          if depth==0
            args<<arg
            arg=Array.new()
          else
            arg<<@instructions[i]
          end
        when ")"
          if depth == 0
            args<<arg
            break
          else
            depth-=1
            arg<<@instructions[i]
          end
        else
          arg<<@instructions[i]
        end
      end
      @instructions.shift(i+1)
    end
    for i in 0...args.length do
      isnumber=false
      for k in 0..9
        isnumber=true if (args[i].length>0 && args[i][0]==k.to_s)
      end
      if isnumber
#		p "number";
        cal= calcNumeric(args[i])
        return nil if cal<=0
        args[i]=cal.to_s.split(/\s*/)
      end
    end
	
    call=@functions[current]
    temp=call.code.clone
    i=0
    while i < temp.length do
      if a=call.arg_by_name(temp[i])
        temp[i]=args[a.index]
      end
      i+=1
    end
#	p temp
    temp.flatten!
#	p temp
    @instructions.unshift(temp)
    @instructions.flatten!
    return nil
  end

  def calcNumeric(code)
    sum=0
    temp=0

    state=1; # 1:+ 0:-
    for i in 0...code.length
      if code[i]=="+"
        case state
        when 1
            sum+=temp
        when 0
            sum-=temp
        end
        temp=0
        state=1
      elsif code[i]=="-"
        case state
        when 1
          sum+=temp
        when 0
          sum-=temp
        end
        temp=0
        state=0
      else
        temp*=10
        temp+=code[i].to_i
      end
    end
    case state
    when 1
      sum+=temp
    when 0
      sum-=temp
    end

    return sum
  end

  def ismle
    return @instructions.length >= HCode::SLE*2
  end

  def issle
    return @step >= HCode::SLE
  end
  
  def isstop
    return @instructions.length==0
  end

end

class HFunc
  LengthLimit=1024

  # Internal Class
  class Argument
    attr_accessor :index, :name, :type

    def initialize(index, name, type)
      @index=index
      @name=name
      @type=type
    end
  end

  attr_accessor :name, :argsnum, :code

  #class methods
  def HFunc.parse(str)
    if str.length > HFunc::LengthLimit
      #puts "Too Long Function"
      return nil
    end
    hfunc = HFunc.new()
    if(("a"<=str[0] && str[0]<="z"||str[0]=="@") && str[0]!="s" && str[0]!="r" && str[0]!="l")
      hfunc.name=str[0]
    else
      #puts "Invalid Function Name"
      return nil
    end

    #header check
    i=1
    if str[i]==":" then
      hfunc.argsnum=0
      i+=1
    elsif str[i]=="("
      i+=1
      while i < str.length do
        if "A"<=str[i] && str[i]<="Z" then
          hfunc.args.each do |a|
            if a.name==str[i]
              #puts "Argument Name Collision at #{i+1}"
              return nil
            end
          end
		  newarg=Argument.new(hfunc.argsnum,str[i],-1)
          hfunc.push_arg(newarg)
          hfunc.argsnum+=1
          if str[i+1]=="," then
            i+=2
          elsif str[i+1]==")" && str[i+2]==":"
            i+=3
            break
          else
            #puts "Function Syntax Error at #{i+1}"
            return nil
          end
        else
          #puts "Function Syntax Error at #{i+1}"
          return nil
        end
      end
    else
      #puts "Function Syntax Error at #{i+1}"
      return nil
    end

    (str[str.index(":")+1...str.length]).each_char do |c|
      hfunc.code<<c
    end
   
    return hfunc
  end

  def HFunc.check(func, funcs)
    symbols = Hash.new()
    symbols["s"]=0; symbols["r"]=0; symbols["l"]=0
    funcs.each do |f|
      symbols[f.name]=f.argsnum
    end
    func.args.each do |a|
      symbols[a.name]=0
    end

    expect=nil
    stack=Array.new()
    left=Array.new()
    newfunc=false
    func.code.push("(")
    #loop start
    for i in 0...func.code.length-1 do
      former=func.code[i-1]
      current=func.code[i]
#      print current
      formertype=HFunc.wordkind(former, func, symbols)
      currenttype=HFunc.wordkind(current, func, symbols)
      if currenttype=="INVALID"
        #puts "Invalid Character"
        return false
      end
      if expect && current!=expect
        #puts "Expect Error"
        return false
      end
      expect=nil

      case currenttype
      when "ARGUMENT"
        case formertype
        when "ARGUMENT"
          func.arg_by_name(current).type=0
        when "CONST"
          #puts "CA"
          return false
        when "NUMBER"
          #puts "NA"
          return false
        when "FUNCTION"
          func.arg_by_name(current).type=0
        when "OPERATOR"
          func.arg_by_name(current).type=1
        end
        if left.length==0
          func.arg_by_name(current).type=0
        end
      when "CONST"
        case formertype
        when "OPERATOR"
        when "SIGN"
          case former
          when "("
			curf=nil
			for f in funcs do
			  if f.name == stack[stack.length-1] then
			    curf=f
				break
			  end
			end
			if curf!=nil then
			  if curf.args[curf.argsnum-left[left.length-1]]==0 then
				return false
			  else
				curf.args[curf.argsnum-left[left.length-1]].type=1
			  end
			end
          when ","
			curf=nil
			for f in funcs do
			  if f.name == stack[stack.length-1] then
			    curf=f
				break
			  end
			end
			if curf!=nil then
			  if curf.args[curf.argsnum-left[left.length-1]]==0 then
				return false
			  else
				curf.args[curf.argsnum-left[left.length-1]].type=1
			  end
			end
          else
            #puts "SC"
            return false
          end
        else
          #puts "?C"
          return false
        end
      when "FUNCTION"
        case formertype
        when "CONST"
          #puts "CF"
          return false
        when "NUMBER"
          #puts "NF"
          return false
        when "OPERATOR"
          #puts "OF"
          return false
        when "ARGUMENT"
          func.arg_by_name(former).type=0
		when "SIGN"
		  if former=="(" || former=="," then
			curf=nil
			for f in funcs do
			  if f.name == stack[stack.length-1] then
			    curf=f
				break
			  end
			end
			if curf!=nil then
			  if curf.args[curf.argsnum-left[left.length-1]]==1 then
				return false
			  end
			end
		  end
        end
        if symbols[current]>0
          expect="("
          newfunc=true
          left.push(symbols[current])
          stack.push(current)
        end
      when "NUMBER"
        case formertype
        when "NUMBER"
        when "SIGN"
          case former
		  when "("
			curf=nil
			for f in funcs do
			  if f.name == stack[stack.length-1] then
			    curf=f
				break
			  end
			end
			if curf!=nil then
			  if curf.args[curf.argsnum-left[left.length-1]]==0 then
				return false
			  else
				curf.args[curf.argsnum-left[left.length-1]].type=1
			  end
			end
		  when ","
		  	curf=nil
			for f in funcs do
			  if f.name == stack[stack.length-1] then
			    curf=f
				break
			  end
			end
			if curf!=nil then
			  if curf.args[curf.argsnum-left[left.length-1]]==0 then
				return false
			  else
				curf.args[curf.argsnum-left[left.length-1]].type=1
			  end
			else
			  print "a"
			end
          when ")"
            #puts "SN"
            return false
          end
=begin
          if current=="0"
            #puts "ZeroStart"
            return false

          end
=end
        when "OPERATOR"
        else
          #puts "?N"
          return false
        end
      when "SIGN"
        case formertype
        when "ARGUMENT"
          if current=="("
            #puts "AS"
            return false
          end
        when "CONST"
          if current=="("
            #puts "CS"
            return false
          end
        when "NUMBER"
          if current=="("
            #puts "NS"
            return false
          end
        when "SIGN"
          dw=former+current
          if dw=="((" ||  dw==",(" || dw==")(" #|| dw==",,"
            #puts "BAD SIGN"
            return false
          end
        when "OPERATOR"
          #puts "OS"
          return false
        end
        
        case current
        when "("
          if !newfunc
            return false
          end
          newfunc=false
        when ","
          if left.length==0
            #puts "radical \",\""
            return false
          end
          #type check
          f = funcs.find do |x|
            x.name==stack[-1]
          end
          case f.arg_by_index(f.argsnum-left[-1]).type
          when 0
            if formertype=="NUMBER" || formertype=="CONST"
              #puts "Type Error"
              return false
            end
          when 1
            if formertype=="FUNCTION" || former=="(" || former==","
              #puts "Type Error"
              return false
            end
          end
          if formertype=="ARGUMENT"
            func.arg_by_name(former).type = f.arg_by_index(f.argsnum-left[-1]).type
          end
          #stack operate
          left[-1]-=1;
          if left[-1] < 1
            return false
          end

        when ")"
          if left.length==0
            #puts "radical \")\""
            return false
          end

          #type check
          f = funcs.find do |x|
            x.name==stack[-1]
          end
          case f.arg_by_index(f.argsnum-left[-1]).type
          when 0
            if formertype=="NUMBER" || formertype=="CONST"
              #puts "Type Error"
              return false
            end
          when 1
            if formertype=="FUNCTION" || former=="(" || former==","
              #puts "Type Error"
              return false
            end
          end
          if formertype=="ARGUMENT"
            func.arg_by_name(former).type = f.arg_by_index(f.argsnum-left[-1]).type
          end

          left[-1]-=1;
          if left[-1]!=0
            #puts "Arguments Error"
            return false
          end
          left.delete_at(-1)
          stack.delete_at(-1)
        end
      when "OPERATOR"
        case formertype
        when "ARGUMENT"
          func.arg_by_name(former).type=1
        when "FUNCTION"
          #puts "FO"
          return false
        when "SIGN"
          #puts "SO"
          return false
        when "OPERATOR"
          #puts "OO"
          return false
        end
      end
    end
    func.code=func.code[0...-1]
    if left.length!=0
      #puts "No \")\""
      return false
    end

    return true;
  end

  def HFunc.wordkind(word, func, symbols)
    symbols.each do |symbol|
      if symbol[0] == word
        if "A"<=symbol[0] && symbol[0]<="Z"
          case func.arg_by_name(symbol[0]).type
          when -1
            return "ARGUMENT"
          when 0
            return "FUNCTION"
          when 1
            return "CONST"
          end
        else
          return "FUNCTION"
        end
      end
    end
    if "0"<=word && word<="9"
      return "NUMBER"
    end
    if word=="(" || word==")" || word==","
      return "SIGN"
    end
    if word=="+" || word=="-"
      return "OPERATOR"
    end
    return "INVALID"
  end

  #instance methods

  def initialize()
    @code=Array.new()
    @name=""
    @argsnum=0
    @args=Array.new()
  end

  def arg_by_name(name)
    @args.each do |arg|
      if arg.name==name
        return arg
      end
    end
    return nil
  end
  def arg_by_index(index)
    return @args[index]
  end
  def args
    return @args
  end
  def push_arg(arg)
    @args.push(arg)
  end
  public :arg_by_name, :arg_by_index, :args, :push_arg
end