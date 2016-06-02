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
        when /^pop\s(\w+)\s(\d+)/
            @arg1 = $1
            @arg2 = $2
            CommandType::C_POP
        #when /^?!.(add|sub|neg|eq|gt|lt|and|or|not|push|pop|if-goto|go|function|call|return)$/
        when /^label\s((\w|_|\.|:)(\w|\d|_|\.|:)*)/
            @arg1 = $1
            @arg2 = nil
            CommandType::C_LABEL
        when /^if-goto\s((\w|_|\.|:)(\w|\d|_|\.|:)*)/
            @arg1 = $1
            @arg2 = nil
            CommandType::C_IF
        when /^goto\s((\w|_|\.|:)(\w|\d|_|\.|:)*)/
            @arg1 = $1
            @arg2 = nil
            CommandType::C_GOTO
        when /^return\s*/
            @arg1 = nil
            @arg2 = nil
            CommandType::C_RETURN
        else
            # フォーマットエラー?
        end
    end
end