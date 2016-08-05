class CodeWriter
    def initialize(source)
        puts "initialize #{source}"
        @io = File.open(source, "w")
        @neqcount = 0
        @eqcount = 0
        @gtcount = 0
        @ltcount = 0
        @callcount = 0
    end
    
    def setFileName(filename)
        @filename = File.basename(filename, ".vm")
    end
    
    def writeInit
        @io.printf <<-"EOS".gsub(/^\s+/, '')
            @256
            D=A
            @SP
            M=D
            @Sys.init
            0;JMP
        EOS
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
            // FRAME(R13) = LCL
            @LCL
            D=M
            @R13
            M=D
            
            // RET(R14) = *(FRAME - 5)
            @5
            A=D-A
            D=M
            @R14
            M=D
            
            // *ARG = pop()
            @SP
            A=M-1
            D=M
            @ARG
            A=M
            M=D
            
            // SP = ARG + 1
            D=A+1
            @SP
            M=D
            
            // THAT = *(FRAME - 1)
            @R13
            AM=M-1
            D=M
            @THAT
            M=D
            
            // THIS = *(FRAME - 2)
            @R13
            AM=M-1
            D=M
            @THIS
            M=D
                        
            // ARG = *(FRAME - 3)
            @R13
            AM=M-1
            D=M
            @ARG
            M=D
            
            // LCL = *(FRAME - 4)
            @R13
            AM=M-1
            D=M
            @LCL
            M=D
            
            // goto RET
            @R14
            A=M
            0;JMP
        EOS
=begin
        @io.printf <<-"EOS".gsub(/^\s+/, '')
            // return
            // RET = *(LCL - 5)
            @LCL
            D=M
            @5
            D=D-A
            @R13
            M=D
            
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
            
            @R14
            AM=D
            D=M
            @THAT
            M=D
            
            @R14
            AM=M-1
            D=M
            @THIS
            M=D
            @R14
            AM=M-1
            D=M
            @ARG
            M=D
            @R14
            AM=M-1
            D=M
            @LCL
            M=D
            
            @R13
            A=M
            0;JMP
        EOS
=end
    end
    
    def writeFunction(name, lclnum)
        @io.printf("// function #{name} #{lclnum}\n")
        @io.printf("(#{name})\n")
        lclnum.to_i.times do
            @io.printf <<-"EOS".gsub(/^\s+/, '')
                @SP
                A=M
                M=0
                @SP
                M=M+1
            EOS
        end
    end
    
    def writeCall(name, argnum)
        @io.printf <<-"EOS".gsub(/^\s+/, '')
            // call #{name} #{argnum}
            
            // リターンアドレス
            @RETURN_ADDRESS_CALL#{@callcount}
            D=A
            @SP
            A=M
            M=D
            @SP
            AM=M+1
            
            // LCL
            @LCL
            D=M
            @SP
            A=M
            M=D
            @SP
            AM=M+1
            
            // ARG
            @ARG
            D=M
            @SP
            A=M
            M=D
            @SP
            AM=M+1
            
            // THIS
            @THIS
            D=M
            @SP
            A=M
            M=D
            @SP
            AM=M+1
            
            // THAT
            @THAT
            D=M
            @SP
            A=M
            M=D
            @SP
            AM=M+1
            
            // LCL = SP
            // ARG = SP-n-5
            @SP
            D=M
            @LCL
            M=D
            @#{argnum.to_i + 5}
            D=D-A
            @ARG
            M=D
           
            // 関数呼び出し
            @#{name}
            0;JMP
             
            // リターンアドレスのためのラベルを宣言
            (RETURN_ADDRESS_CALL#{@callcount})
        EOS
        @callcount += 1
    end
    
    def close
        @io.close
    end
end