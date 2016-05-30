class CodeWriter
    def initialize(asmfile)
        @io = File.open(asmfile, "w")
        @neqcount = 0
        @eqcount = 0
        @gtcount = 0
        @ltcount = 0
    end
    
    def setFileName
    
    end
        
    def writeArithmetic(command)
        case command
        when /add/
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                // add
                @SP
                A=M-1
                D=M
                A=A-1
                M=D+M
                D=A+1
                D=A+1
                @SP
                M=D
            EOS
        when /sub/
            puts "write sub"
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                // sub
                @SP
                A=M-1
                D=M
                A=A-1
                M=D-M
                D=A+1
                D=A+1
                @SP
                M=D
            EOS
        when /neq/
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                // neq
                @SP
                AM=M-1
                D=M
                A=A-1
                D=M-D
                M=0
                @END_EQ.#{@neqcount}
                D;JEQ
                @SP
                A=M-1
                M=-1
                (END_EQ.#{@neqcount})
            EOS
            @neqcount += 1
        when /eq/
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                // eq
                @SP
                AM=M-1
                D=M
                A=A-1
                D=M-D
                M=0
                @END_EQ.#{@eqcount}
                D;JNE
                @SP
                A=M-1
                M=-1
                (END_EQ.#{@eqcount})
            EOS
            @eqcount += 1
        when /gt/
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                // gt
                @SP
                AM=M-1
                D=M
                A=A-1
                D=M-D
                M=0
                @END_GT.#{@gtcount}
                D;JLE
                @SP
                A=M-1
                M=-1
                (END_GT.#{@gtcount})
            EOS
            @gtcount += 1
        when /lt/
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                // lt
                @SP
                AM=M-1
                D=M
                A=A-1
                D=M-D
                M=0
                @END_LT.#{@ltcount}
                D;JGE
                @SP
                A=M-1
                M=-1
                (END_LT.#{@ltcount})
            EOS
            @ltcount += 1
        when /and/
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                // and
                @SP
                A=M-1
                D=M
                A=A-1
                M=D&M
                D=A+1
                D=A+1
                @SP
                M=D
            EOS
        when /or/
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                // or
                @SP
                A=M-1
                D=M
                A=A-1
                M=D|M
                D=A+1
                D=A+1
                @SP
                M=D
            EOS
        when /not/
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                // not
                @SP
                A=M-1
                M=!M
            EOS
        else
            puts "Invalid arithmetic command"
        end
    end
    
    def writePushPop(command, segment, index)
        case command
        when CommandType::C_PUSH
            case segment
            when /constant/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // push segment index
                    @#{index}
                    D=A
                    @SP
                    A=M
                    M=D
                    D=A+1
                    @SP
                    M=D  
                EOS
            end
        end
            
    end
    
    def close
        @io.close
    end
end