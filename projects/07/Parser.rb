require_relative 'CommandType'

class Parser
    attr :arg1, :arg2
    
    def initialize(vmfile)
        @io = File.open(vmfile, "r")
    end
    
    def hasMoreCommands?
        pos = @io.pos
        @line = @io.gets
        @io.seek(pos, IO::SEEK_SET)
        @line != nil
    end
    
    def advance
        @command = @io.gets
    end
    
    def commandType
        puts @command
        case @command
        when /^\/\//
            # コメント行
        when /^(add|sub|neg|eq|gt|lt|and|or|not)$/
            @arg1 = $1
            @arg2 = nil
            CommandType::C_ARITHMETIC
        when /^push\s(\w+)\s(\d+)/
            @arg1 = $1
            @arg2 = $2
            CommandType::C_PUSH
        when /^pop\s(.*)\s(.*)/
            @arg1 = $1
            @arg2 = $2
            CommandType::C_POP
        else
            # フォーマットエラー?
        end
    end
end