require_relative 'Parser'
require_relative 'CodeWriter'

class Translator
    def initialize(source)
        @source = source
    end
    
    def exec
        puts "Start Translation"
        
        vmfiles = Array.new
        if File::ftype(@source) == "directory"
            Dir::entries(@source).each {|entry|
                p vmfiles.push("#{@source}\\#{entry}") if entry.include?(".vm")
            }
            p asmfile = @source + "\\" + @source.split("\\").last + ".asm"
        else
            vmfiles.push(@source)
            p asmfile = File.basename(@source, ".vm") + ".asm"
        end
        
        @coder = CodeWriter.new(asmfile)
        @coder.writeInit
        
        vmfiles.each {|vmfile|
            @coder.setFileName(vmfile)
            @parser = Parser.new(vmfile)
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
                when CommandType::C_FUNCTION
                    @coder.writeFunction(@parser.arg1, @parser.arg2)
                when CommandType::C_CALL
                    @coder.writeCall(@parser.arg1, @parser.arg2)
                else
                            
                end
            end
            #@parser.destroy
        }
    end
end