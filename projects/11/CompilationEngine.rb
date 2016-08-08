require 'cgi'
require_relative 'Types'
require_relative 'JackTokenizer'
require_relative 'SymbolTable'
require_relative 'VMWriter'

BINARY_OP = {"+"=>"add", "-"=>"sub", "="=>"eq", ">"=>"gt", "<"=>"lt", "&"=>"and", "|"=>"or"}
UNITARY_OP = {"-"=>"neg", "~"=>"not"}
MATH_FUNCTION = {"*"=>"Math.multiply", "/"=>"Math.divide"}

class CompilationEngine
    def initialize(jackfile)
        @key = "class"
        @type = nil
        @kind = nil
        @purpose = :none
        @function_name = ""
        @local_num = 0
        @expression_num = 0
        @loop_num = 0
        @if_num = [0]
        @if_num_next = 0

        xmlfile = jackfile.sub(/\.jack$/, ".xml")
        @fo = File.open(xmlfile, "w")

        vmfile = jackfile.sub(/\.jack$/, ".vm")
        @class_name = File.basename(jackfile, ".jack")
        #@fo = File.open(vmfile, "w")
        
        @tokenizer = JackTokenizer.new(jackfile)
        @symbol_table = SymbolTable.new
        @vmwriter = VMWriter.new(vmfile)
    end
    
    # 'class' className '{' classVarDec* subroutineDec* '}'
    def compile_class
        @tokenizer.has_more_tokens? ? @tokenizer.advance : exit - 1
        
        #@fo.puts "<class>"
        if accept?(TokenType::KEYWORD, ["class"])
            expect(TokenType::IDENTIFIER)
            expect(TokenType::SYMBOL, ["{"])
        end
        
        while apply?(TokenType::KEYWORD, ["static", "field"]) do
            compile_class_var_dec
        end
        
        while apply?(TokenType::KEYWORD, ["constructor", "function", "method"]) do
            compile_subroutine
        end
        
        if accept?(TokenType::SYMBOL, ["}"])
            if @tokenizer.has_more_tokens?
                STDERR.print "Parse Error: Unused tokens are left"
            else
                #@fo.puts "</class>"
                @vmwriter.close
            end
        end
    end
    
    private
    
    def compile_class_var_dec
        #@fo.puts "<classVarDec>"
        @purpose = :define
        @local_num = 0
        if accept?(TokenType::KEYWORD, ["static", "field"])
            @kind = @tokenizer.keyword
            expect_type
            expect(TokenType::IDENTIFIER)
            @local_num += 1
            while accept?(TokenType::SYMBOL, [","]) do
                expect(TokenType::IDENTIFIER)
                @local_num += 1
            end
            
            expect(TokenType::SYMBOL, [";"])
        end
        #@fo.puts "</classVarDec>"   
    end
    
    # ('constructor'|'function'|'method') ('void'|type) subroutinName
    # '(' parameterList ')' subroutineBody
    def compile_subroutine
        @symbol_table.start_subroutine
        @purpose = :define
        @loop_num = 0
        @if_num_next = 0

        #@fo.puts "<subroutineDec>"
        if accept?(TokenType::KEYWORD, ["constructor", "function", "method"])
            @kind = "subroutine"
            accept?(TokenType::KEYWORD, ["void"]) or accept_type?
            expect(TokenType::IDENTIFIER)
            @function_name = "#{@class_name}.#{@tokenizer.identifier}"
            expect(TokenType::SYMBOL, ["("])
            compile_parameter_list
            expect(TokenType::SYMBOL, [")"])
        end
        
        #@fo.puts "<subroutineBody>"
        if accept?(TokenType::SYMBOL, ["{"])
            while apply?(TokenType::KEYWORD, ["var"]) do 
                compile_var_dec
            end
            #@vmwriter.write_function(@function_name, @local_num)
            @vmwriter.write_function(@function_name, @symbol_table.var_count("var"))
            @purpose = :use
            compile_statements
            expect(TokenType::SYMBOL, ["}"])
        end
        @fo.puts "</subroutineBody>"
        @fo.puts "</subroutineDec>"
    end
    
    def compile_parameter_list
        #@fo.puts "<parameterList>"
        if accept_type?
            @kind = "argument"
            expect(TokenType::IDENTIFIER)
            #@symbol_table.define(@tokenizer.identifier, )
            while accept?(TokenType::SYMBOL, [","]) do
                expect_type
                expect(TokenType::IDENTIFIER)
            end
        end
        #@fo.puts "</parameterList>"
    end
    
    def compile_var_dec
        #@fo.puts "<varDec>"
        @local_num = 0
        if accept?(TokenType::KEYWORD, ["var"])
            @kind = @tokenizer.keyword
            expect_type
            expect(TokenType::IDENTIFIER)
            @local_num += 1
            while apply?(TokenType::SYMBOL, [","]) do
                if accept?(TokenType::SYMBOL, [","])
                    expect(TokenType::IDENTIFIER)
                    @local_num += 1
                end
            end
            expect(TokenType::SYMBOL, [";"])
        end
        #@fo.puts "</varDec>"   
    end
    
    def compile_statements
        #@fo.puts "<statements>"
        while apply?(TokenType::KEYWORD, ["let", "if", "while", "do", "return"]) do
            send("compile_#{@tokenizer.keyword}")
        end
        #@fo.puts "</statements>"
    end
    
    def compile_do
        #@fo.puts "<doStatement>"
        @function_name = ""    
        if accept?(TokenType::KEYWORD, ["do"])
            expect(TokenType::IDENTIFIER)
            @function_name = @tokenizer.identifier
            if accept?(TokenType::SYMBOL, ["."])
                expect(TokenType::IDENTIFIER)
                @function_name += ".#{@tokenizer.identifier}"
            end
            expect(TokenType::SYMBOL, ["("])
            compile_expression_list
            expect(TokenType::SYMBOL, [")"])
            expect(TokenType::SYMBOL, [";"])
        end
        # put arguments to the stack
        #@fo.puts "call #{function_name} #{@expression_num}"
        @vmwriter.write_call(@function_name, @expression_num)
        @vmwriter.write_pop(:temp, 0)    
        #@fo.puts "</doStatement>"
    end
    
    def compile_let
        #@fo.puts "<letStatement>"
        if accept?(TokenType::KEYWORD, ["let"])
            expect(TokenType::IDENTIFIER)
            symbol_name = @tokenizer.identifier
            if accept?(TokenType::SYMBOL, ["["])
                compile_expression
                expect(TokenType::SYMBOL, ["]"])
            end
            expect(TokenType::SYMBOL, ["="])
            compile_expression
            expect(TokenType::SYMBOL, [";"])
        end
        #@vmwriter.write_pop(:local, @symbol_table.index_of(symbol_name))
        case @symbol_table.kind_of(symbol_name)
        when /var/ 
            @vmwriter.write_pop("local", @symbol_table.index_of(symbol_name))
        when /argument/ 
            @vmwriter.write_pop("argument", @symbol_table.index_of(symbol_name))
        end
        #@fo.puts "</letStatement>"
    end
    
    def compile_while
        @fo.puts "<whileStatement>"
        @vmwriter.write_label("WHILE_EXP#{@loop_num}")
        if accept?(TokenType::KEYWORD, ["while"])
            expect(TokenType::SYMBOL, ["("])
            compile_expression
            @vmwriter.write_arithmetic(UNITARY_OP["~"])
            @vmwriter.write_if("WHILE_END#{@loop_num}")
            expect(TokenType::SYMBOL, [")"])
            expect(TokenType::SYMBOL, ["{"])
            compile_statements
            expect(TokenType::SYMBOL, ["}"])
        end
        @vmwriter.write_goto("WHILE_EXP#{@loop_num}")
        @vmwriter.write_label("WHILE_END#{@loop_num}")
        @loop_num += 1
        @fo.puts "</whileStatement>"
    end
    
    def compile_return
        @fo.puts "<returnStatement>"
        if accept?(TokenType::KEYWORD, ["return"])
            unless accept?(TokenType::SYMBOL, [";"])
                compile_expression
                expect(TokenType::SYMBOL, [";"])
            else
                @vmwriter.write_push(:constant, 0)
            end
        end
        @fo.puts "</returnStatement>"
        @vmwriter.write_return
    end
    
    def compile_if
        @fo.puts "<ifStatement>"
        @if_num.push(@if_num_next)
        @if_num_next += 1
        if accept?(TokenType::KEYWORD, ["if"])
            expect(TokenType::SYMBOL, ["("])
            compile_expression
            expect(TokenType::SYMBOL, [")"])
            #@vmwriter.write_arithmetic(UNITARY_OP["~"])
            @vmwriter.write_if("IF_TRUE#{@if_num[-1]}")
            @vmwriter.write_goto("IF_FALSE#{@if_num[-1]}")
            @vmwriter.write_label("IF_TRUE#{@if_num[-1]}")
            expect(TokenType::SYMBOL, ["{"])
            compile_statements
            @vmwriter.write_goto("IF_END#{@if_num[-1]}")
            expect(TokenType::SYMBOL, ["}"])
            @vmwriter.write_label("IF_FALSE#{@if_num[-1]}")
            if accept?(TokenType::KEYWORD, ["else"])
                expect(TokenType::SYMBOL, ["{"])
                compile_statements
                expect(TokenType::SYMBOL, ["}"])
            end
            @vmwriter.write_label("IF_END#{@if_num[-1]}")
            @if_num.pop
        end
        @fo.puts "</ifStatement>"
    end
    
    def compile_expression
        #@fo.puts "<expression>"
        compile_term
        while apply?(TokenType::SYMBOL, ["+", "-", "*", "/", "&", "|", "<", ">", "="]) do
            if accept?(TokenType::SYMBOL, ["+", "-", "*", "/", "&", "|", "<", ">", "="])
                if @tokenizer.symbol == "*" or @tokenizer.symbol == "/"
                    function = MATH_FUNCTION[@tokenizer.symbol]
                    compile_term
                    @vmwriter.write_call(function, 2)
                else
                    op = BINARY_OP[@tokenizer.symbol]
                    compile_term
                    @vmwriter.write_arithmetic(op)
                end
                #op = @tokenizer.symbol
                #compile_term
                #@vmwriter.write_arithmetic(op)
            end
        end
        #@fo.puts "</expression>"
    end
    
    def compile_term
        #@fo.puts "<term>"
        # integerConstant | stringConstant | keywordConstant
        if accept?(TokenType::INT_CONST) 
            @vmwriter.write_push(:constant, @tokenizer.int_val)
        elsif accept?(TokenType::STRING_CONST)

        elsif accept?(TokenType::KEYWORD, ["true", "false", "null", "this"])
            case @tokenizer.keyword
            when /true/
                @vmwriter.write_push("constant", 0)
                @vmwriter.write_arithmetic(UNITARY_OP["~"])
            when /false/
                @vmwriter.write_push("constant", 0)
            end
        # [var|class|subroutine]Name
        elsif accept?(TokenType::IDENTIFIER)
            case @symbol_table.kind_of(@tokenizer.identifier)
            when /var/ 
                @vmwriter.write_push("local", @symbol_table.index_of(@tokenizer.identifier))
            when /argument/ 
                @vmwriter.write_push("argument", @symbol_table.index_of(@tokenizer.identifier))
            end
            # varName [ expression ]
            if accept?(TokenType::SYMBOL, ["["])
                compile_expression
                expect(TokenType::SYMBOL, ["]"])
            # subroutineName ( expression )
            elsif accept?(TokenType::SYMBOL, ["("])
                compile_expression_list
                expect(TokenType::SYMBOL, [")"])
            # (className | varName) . subroutineName ( eprexxionList )
            elsif accept?(TokenType::SYMBOL, ["."])
                #@fo.print "call #{@tokenizer.identifier}." # className | varName
                receiver_name = @tokenizer.identifier
                expect(TokenType::IDENTIFIER)
                #@fo.print "#{@tokenizer.identifier} " # function name
                @function_name = @tokenizer.identifier
                accept?(TokenType::SYMBOL, ["("])
                compile_expression_list
                expect(TokenType::SYMBOL, [")"])
                # push aruments to the stack
                
                @vmwriter.write_call("#{receiver_name}.#{@function_name}", @expression_num)
            end
        # ( expression )
        elsif accept?(TokenType::SYMBOL, ["("])
            compile_expression
            expect(TokenType::SYMBOL, [")"])
        # unaryOp term
        elsif accept?(TokenType::SYMBOL, ["-", "~"])
            symbol = @tokenizer.symbol
            compile_term
            @vmwriter.write_arithmetic(UNITARY_OP[symbol])
        end
        #@fo.puts "</term>"
    end
    
    def compile_expression_list
        #@fo.puts "<expressionList>"
        @expression_num = 0
        if apply?(TokenType::SYMBOL, [")"])
            #@fo.puts "</expressionList>"
            return
        end
        
        compile_expression
        @expression_num += 1
        while accept?(TokenType::SYMBOL, [","]) do
            compile_expression
            @expression_num += 1
        end
        #@fo.puts "</expressionList>"
    end
    
    # original
    
    def accept?(token_type, token=nil)
        #puts "token_type: #{token_type} tokens:#{token}"
        if @tokenizer.token_type == token_type
            case @tokenizer.token_type
            when TokenType::KEYWORD
                if token.include?(@tokenizer.keyword)
                    #@fo.puts "<keyword> #{@tokenizer.keyword} </keyword>"
                    register_key
                else
                    return false
                end
            when TokenType::SYMBOL
                if token.include?(@tokenizer.symbol)
                    #@fo.puts "<symbol> #{CGI.escapeHTML(@tokenizer.symbol)} </symbol>"
                else
                    return false
                end
            when TokenType::IDENTIFIER
                #@fo.puts "<identifier> #{@tokenizer.identifier} </identifier>"
                #p caller_locations(1).first.label
                if @purpose == :define
                    @symbol_table.define(@tokenizer.identifier, @type, @kind)
                    type = @type
                    kind = @kind
                else
                    #type = @symbol_table.type_of(@tokenizer.identifier)
                    kind = @symbol_table.kind_of(@tokenizer.identifier)
                    if kind != :none
                        puts "identifier: #{@tokenizer.identifier}"
                        index = @symbol_table.index_of(@tokenizer.identifier)
                        #@vmwriter.write_push(kind, index)
                    end
                end
                #index = @symbol_table.index_of(@tokenizer.identifier)
                #@fo.puts "<identifier> #{kind} #{@tokenizer.identifier} #{@purpose} #{index}</identifier>"
            when TokenType::INT_CONST
                #@fo.puts "<integerConstant> #{@tokenizer.int_val} </integerConstant>"
            when TokenType::STRING_CONST
                #@fo.puts "<stringConstant> #{@tokenizer.string_val} </stringConstant>"
            end

            @vmwriter.write_comment("// #{@tokenizer.current_token}") if $debug
            @tokenizer.advance if @tokenizer.has_more_tokens?
            true
        else
            false
        end
    end
    
    def apply?(token_type, token=nil)
        return false unless @tokenizer.token_type == token_type
        
        case @tokenizer.token_type
        when TokenType::KEYWORD
            return token.include?(@tokenizer.keyword)
        when TokenType::SYMBOL
            return token.include?(@tokenizer.symbol)
        when TokenType::IDENTIFIER
        when TokenType::INT_CONST
        when TokenType::STRING_CONST
        else
            STDERR.print "Parse Error: Invalid Token Type"
        end
        true
    end
    
    def expect(token_type, token=nil)
        accept?(token_type, token) ? true : false
    end
    
    def accept_type?
        if accept?(TokenType::KEYWORD, ["int", "char", "boolean"])
            @type = @tokenizer.keyword
        elsif accept?(TokenType::IDENTIFIER)
            @type = @tokenizer.identifier
        end
    end
    
    def expect_type
        if accept?(TokenType::KEYWORD, ["int", "char", "boolean"])
            @type = @tokenizer.keyword
        elsif expect(TokenType::IDENTIFIER)
            @type = @tokenizer.identifier
        end
    end

    def register_key
        case @tokenizer.keyword
        when /var/
            @key = "var"
        end
    end
end