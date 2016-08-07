class VMWriter
    def initialize(vmfile)
        @fo = File.open(vmfile, "w")
    end

    def write_push(segment, index)
        @fo.puts "push #{segment} #{index}"
    end

    def write_pop(segment, index)
        @fo.puts "pop #{segment} #{index}"
    end

    def write_arithmetic(command)
        puts "write arith #{command}"
        case command
        when /\+/
            @fo.puts "add"
        when /\*/
            @fo.puts "call Math.multiply 2"
        else
            puts "no match?"
        end
    end

    def write_lable(label)

    end

    def write_goto(label)

    end
    
    def write_if(label)

    end

    def write_call(function_name, argument_num)
        @fo.puts "call #{function_name} #{argument_num}"
    end

    def write_function(function_name, local_num)
        @fo.puts "function #{function_name} #{local_num}"
    end

    def write_return
        @fo.puts "return"
    end

    def close
        @fo.close
    end
end