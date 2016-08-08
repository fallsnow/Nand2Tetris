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
        @fo.puts command
    end

    def write_label(label)
        @fo.puts "label #{label}"
    end

    def write_goto(label)
        @fo.puts "goto #{label}"
    end
    
    def write_if(label)
        @fo.puts "if-goto #{label}"
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

    # original

    def write_comment(string)
        @fo.puts string
    end
end