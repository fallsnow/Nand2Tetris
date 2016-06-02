require_relative 'Parser'
require_relative 'CodeWriter'

class Translator
    def initialize(source)
        puts vmfile = source
        #puts asmfile = source.sub(/.vm/, ".asm")
        @parser = Parser.new(vmfile)
        @coder = CodeWriter.new(vmfile)
    end
    
    def exec
        puts "Start Translation"
        while @parser.hasMoreCommands?
            @parser.advance
            case @parser.commandType
            when CommandType::C_ARITHMETIC
                puts "Arithmetic #{@parser.arg1}"
                @coder.writeArithmetic(@parser.arg1)
            when CommandType::C_PUSH, CommandType::C_POP
                puts "Push/Pop #{@parser.arg1} #{@parser.arg2}"
                @coder.writePushPop(@parser.commandType, @parser.arg1, @parser.arg2)
            when CommandType::C_LABEL
                puts "C_LABEL"
                @coder.writeLabel(@parser.arg1)
            when CommandType::C_IF
                @coder.writeIf(@parser.arg1)
            when CommandType::C_GOTO
                @coder.writeGoTo(@parser.arg1)
            when CommandType::C_RETURN
                @coder.writeReturn
            else
                        
            end
        end
    end
end