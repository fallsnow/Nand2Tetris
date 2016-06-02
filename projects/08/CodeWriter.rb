class CodeWriter
    def initialize(source)
        @io = File.open(source.sub(/.vm/, ".asm"), "w")
        @filename = File.basename(source, ".vm")
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
                M=M-D
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
                    // push constant #{index}
                    @#{index}
                    D=A
                    @SP
                    A=M
                    M=D
                    D=A+1
                    @SP
                    M=D  
                EOS
            when /local/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // push local #{index}
                    @LCL
                    D=M
                    @#{index}
                    A=D+A
                    D=M
                    @SP
                    A=M
                    M=D
                    D=A+1
                    @SP
                    M=D
                EOS
            when /argument/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // push argument #{index}
                    @ARG
                    D=M
                    @#{index}
                    A=D+A
                    D=M
                    @SP
                    A=M
                    M=D
                    D=A+1
                    @SP
                    M=D
                EOS
            when /this/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // push this #{index}
                    @THIS
                    D=M
                    @#{index}
                    A=D+A
                    D=M
                    @SP
                    A=M
                    M=D
                    D=A+1
                    @SP
                    M=D  
                EOS
            when /that/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // push that #{index}
                    @THAT
                    D=M
                    @#{index}
                    A=D+A
                    D=M
                    @SP
                    A=M
                    M=D
                    D=A+1
                    @SP
                    M=D  
                EOS
            when /temp/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // push temp #{index}
                    @R5
                    D=A
                    @#{index}
                    A=D+A
                    D=M
                    @SP
                    A=M
                    M=D
                    D=A+1
                    @SP
                    M=D  
                EOS
            when /pointer/
                pointer = index == "0" ? "THIS" : "THAT"
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // push pointer #{index}
                    @#{pointer}
                    D=M
                    @SP
                    A=M
                    M=D
                    D=A+1
                    @SP
                    M=D
                EOS
            when /static/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // push static #{index}
                    @#{@filename}.#{index}
                    D=M
                    @SP
                    A=M
                    M=D
                    D=A+1
                    @SP
                    M=D
                EOS
            end
        when CommandType::C_POP
            case segment
            when /local/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // pop local #{index}
                    @LCL
                    D=M
                    @#{index}
                    D=D+A
                    @SP
                    A=M
                    M=D
                    A=A-1
                    D=M
                    A=A+1
                    A=M
                    M=D
                    @SP
                    M=M-1
                EOS
            when /argument/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // pop argument #{index}
                    @ARG
                    D=M
                    @#{index}
                    D=D+A
                    @SP
                    A=M
                    M=D
                    A=A-1
                    D=M
                    A=A+1
                    A=M
                    M=D
                    @SP
                    M=M-1
                EOS
            when /this/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // pop this #{index}
                    @THIS
                    D=M
                    @#{index}
                    D=D+A
                    @SP
                    A=M
                    M=D
                    A=A-1
                    D=M
                    A=A+1
                    A=M
                    M=D
                    @SP
                    M=M-1
                EOS
            when /that/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // pop that #{index}
                    @THAT
                    D=M
                    @#{index}
                    D=D+A
                    @SP
                    A=M
                    M=D
                    A=A-1
                    D=M
                    A=A+1
                    A=M
                    M=D
                    @SP
                    M=M-1
                EOS
            when /temp/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // pop temp #{index}
                    @R5
                    D=A
                    @#{index}
                    D=D+A
                    @SP
                    A=M
                    M=D
                    A=A-1
                    D=M
                    A=A+1
                    A=M
                    M=D
                    @SP
                    M=M-1
                EOS
            when /pointer/
                pointer = index == "0" ? "THIS" : "THAT"
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // pop pointer #{index}
                    @SP
                    AM=M-1
                    D=M
                    @#{pointer}
                    M=D
                EOS
            when /static/
                @io.print <<-"EOS".gsub(/^\s+/, '')
                    // pop static #{index}
                    @SP
                    AM=M-1
                    D=M
                    @#{@filename}.#{index}
                    M=D
                EOS
            end
        end
            
    end
    
    def writeLabel(label)
        @io.write("(#{label})\n")
    end
    
    def writeIf(label)
        @io.printf <<-"EOS".gsub(/^\s+/, '')
            // if-goto #{label}
            @SP
            AM=M-1
            D=M
            @#{label}
            D;JNE
        EOS
    end
    
    def writeGoTo(label)
        @io.printf <<-"EOS".gsub(/^\s+/, '')
            // goto #{label}
            @#{label}
            0;JMP
        EOS
    end
    
    def writeReturn
        @io.printf <<-"EOS".gsub(/^\s+/, '')
            // return
            // 戻り値の設定
            @SP
            A=M-1
            D=M
            @ARG
            A=M
            M=D
            D=A+1
            @SP
            M=D
            // レジスタ値の復元
            @ARG
            D=M
            @6
            AD=D+A
            
            @R13
            AM=D
            D=M
            @THAT
            M=D
            
            @R13
            AM=M-1
            D=M
            @THIS
            M=D
            @R13
            AM=M-1
            D=M
            @ARG
            M=D
            @R13
            AM=M-1
            D=M
            @LCL
            M=D
        EOS
    end
    
    def close
        @io.close
    end
end