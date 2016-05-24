# -*- coding: utf-8 -*-

module CommandType
    A_COMMAND = 1
    C_COMMAND = 2
    L_COMMAND = 3
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
        # 空白をすべて取り除く
        @command.gsub!(/\s*/,"")
        
        case @command
        when /^\/\//
            # コメント行
        when /^@(.*)/
             @symbol = $1
            CommandType::A_COMMAND
        when /^\((.*)\)/
             @symbol = $1
            CommandType::L_COMMAND
        when /^(.+)=(.+)/
            @computation = $2
            @destination = $1
            @jump = nil
            CommandType::C_COMMAND
        when /^(\w);(JGT|JEQ|JGE|JLT|JNE|JLE|JMP)/
            @computation = $1
            @destination = nil
            @jump = $2
            CommandType::C_COMMAND
        else
            # 空白行、またはフォーマットエラー
        end
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
    
    def rewind
        @io.rewind
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

class SymbolTable
    def initialize
        @symbols = Hash.new
        @symbols.store("SP", 0)
        @symbols.store("LCL", 1)
        @symbols.store("ARG", 2)
        @symbols.store("THIS", 3)
        @symbols.store("THAT", 4)
        @symbols.store("R0",  0)
        @symbols.store("R1",  1)
        @symbols.store("R2",  2)
        @symbols.store("R3",  3)
        @symbols.store("R4",  4)
        @symbols.store("R5",  5)
        @symbols.store("R6",  6)
        @symbols.store("R7",  7)
        @symbols.store("R8",  8)
        @symbols.store("R9",  9)
        @symbols.store("R10", 10)
        @symbols.store("R11", 11) 
        @symbols.store("R12", 12)
        @symbols.store("R13", 13)
        @symbols.store("R14", 14)
        @symbols.store("R15", 15)
        @symbols.store("SCREEN", 16384)
        @symbols.store("KBD", 24576)
    end
    
    def addEntry(symbol, address)
        @symbols.store(symbol, address)
    end
    
    def contains?(symbol)
        @symbols.has_key?(symbol)
    end
    
    def getAddess(symbol)
        @symbols[symbol]
    end
    
    def show
        p @symbols
    end
end

# Main starts from here

if ARGV.size < 1 then
    puts "Please input the assembly fine name"
    exit
end

filename = File.basename(ARGF.filename, "asm")
filename += "hack"
f = File.open(filename, "w")

parser = Parser.new(ARGF.filename)
code = Code.new
symbol_table = SymbolTable.new

# シンボルテーブルの作成
address = 0
while parser.hasMoreCommands?
    parser.advance()
    case parser.commandType()
    when CommandType::A_COMMAND, CommandType::C_COMMAND
        address += 1
    when CommandType::L_COMMAND
        symbol_table.addEntry(parser.symbol(), address)
    end
end
parser.rewind()

# アセンブルの実行
ram_address = 16
while parser.hasMoreCommands?
    parser.advance()
    case parser.commandType()
    when CommandType::A_COMMAND
        symbol = parser.symbol()
        if symbol =~ /^[0-9]+$/
            address = symbol.to_i
        elsif symbol_table.contains?(symbol)
            address = symbol_table.getAddess(symbol)
        else
            address = ram_address
            symbol_table.addEntry(symbol, address)
            ram_address += 1
        end
        f.printf("0%015b\n", address)
    when CommandType::C_COMMAND
        comp = code.comp(parser.comp())
        dest = code.dest(parser.dest())
        jump = code.jump(parser.jump())
        f.write("111" + comp + dest + jump + "\n")
    when CommandType::L_COMMAND
        # 何もしない
    end
end
f.close()    