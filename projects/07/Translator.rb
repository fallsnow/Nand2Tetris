require_relative 'Parser'
require_relative 'CodeWriter'

class Translator
    def initialize(source)
        puts vmfile = source
        puts asmfile = source.sub(/.vm/, ".asm")
        @parser = Parser.new(vmfile)
        @coder = CodeWriter.new(asmfile)
    end
    
    def exec
        puts "Start Translation"
        while @parser.hasMoreCommands?
            @parser.advance()
            case @parser.commandType()
            when CommandType::C_ARITHMETIC
                puts "Arithmetic #{@parser.arg1}"
                @coder.writeArithmetic(@parser.arg1)
            when CommandType::C_PUSH
                puts "Push #{@parser.arg1} #{@parser.arg2}"
                @coder.writePushPop(CommandType::C_PUSH, @parser.arg1, @parser.arg2)
            when CommandType::C_POP
                puts "Pop"
            else
            
            end
        end
    end
end