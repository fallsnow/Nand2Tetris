# -*- coding: utf-8 -*-

module CommandType
    A_COMMAND = 1
    C_COMMAND = 2
    L_COMMAND = 3
end

module DestinationType
    NULL    = 0
    M       = 1
    D       = 2
    MD      = 3
    A       = 4
    AM      = 5
    AD      = 6
    AMD     = 7
end
    
class Parser
    def initialize(file)
        @asmfile = file
        @io = File.open(file, "r")
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
        # 空白をすべて取り除く
        @command.gsub!(/\s*/,"")
        
        case @command
        when /^\/\//
            puts "Comment Line"
        when /^@(.*)/
             @symbol = $1
            CommandType::A_COMMAND
        when /^\((.*)\)/
             @symbol = $1
            CommandType::L_COMMAND
        when /^(.+)=(.+)/
            puts "command: #{@command}"
            puts "dest: #{$1}, #{$2}"
            @computation = $2
            @destination = $1
            @jump = nil
            CommandType::C_COMMAND
        when /^(\w);(JGT|JEQ|JGE|JLT|JNE|JLE|JMP)/
            puts "command: #{@command}"
            puts "jump: #{$1}, #{$2}"
            @computation = $1
            @destination = nil
            @jump = $2
            CommandType::C_COMMAND
        else
            # 空白行、またはフォーマットエラー
        end
        #return CommandType::A_COMMAND if @command[0] == "@"
        #puts @command
    end
    
    def symbol
        @symbol
    end
    
    def dest
        @destination
    end
    
    def comp
        @computation
    end
    
    def jump
        @jump
    end
end

class Code
    COMPUTATION_ENCODING = {
        # C命令
        "0"     => "0101010",
        "1"     => "0111111",
        "-1"    => "0111010",
        "D"     => "0001100",
        "A"     => "0110000",
        "!D"    => "0001101",
        "!A"    => "0110001",
        "-D"    => "0001111",
        "-A"    => "0110011",
        "D+1"   => "0011111",
        "A+1"   => "0110111",
        "D-1"   => "0001110",
        "A-1"   => "0110010",
        "D+A"   => "0000010",
        "D-A"   => "0010011",
        "A-D"   => "0000111",
        "D&A"   => "0000000",
        "D|A"   => "0010101",
        # A命令
        "M"     => "1110000",
        "!M"    => "1110001",
        "-M"    => "1110011",
        "M+1"   => "1110111",
        "M-1"   => "1110010",
        "D+M"   => "1000010",
        "D-M"   => "1010011",
        "M-D"   => "1000111",
        "D&M"   => "1000000",
        "D|M"   => "1010101"    
    }
    
    DESTINATION_ENCODING = {
        "NULL"  => "000",
        "M"     => "001",
        "D"     => "010",
        "MD"    => "011",
        "A"     => "100",
        "AM"    => "101",
        "AD"    => "110",
        "AMD"   => "111"
    }
    DESTINATION_ENCODING.default = "000"
    
    JUMP_ENCODING = {
        "JGT"   => "001",
        "JEQ"   => "010",
        "JGE"   => "011",
        "JLT"   => "100",
        "JNE"   => "101",
        "JLE"   => "110",
        "JMP"   => "111"    
    }
    JUMP_ENCODING.default = "000"
    
    def initialize
    end
    
    def dest(mnemonic)
        DESTINATION_ENCODING[mnemonic]
    end
    
    def comp(mnemonic)
        COMPUTATION_ENCODING[mnemonic]
    end
    
    def jump(mnemonic)
        JUMP_ENCODING[mnemonic]
    end
end

# Main starts from here

if ARGV.size < 1 then
    puts "Please input the assembly fine name"
    exit
end

parser = Parser.new(ARGF.filename)
code = Code.new

filename = File.basename(ARGF.filename, "asm")
puts filename += "hack"
f = File.open(filename, "w")

while parser.hasMoreCommands?
    parser.advance()
    case parser.commandType()
    when CommandType::A_COMMAND, CommandType::L_COMMAND
        f.printf("0%015b\n", parser.symbol().to_i)
    when CommandType::C_COMMAND
        comp = code.comp(parser.comp())
        dest = code.dest(parser.dest())
        jump = code.jump(parser.jump())
        f.write("111" + comp + dest + jump + "\n")
    end
end
f.close()    