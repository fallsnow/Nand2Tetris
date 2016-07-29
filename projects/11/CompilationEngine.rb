require 'cgi'
require_relative 'Types'
require_relative 'JackTokenizer'
require_relative 'SymbolTable'
require_relative 'VMWriter'

class CompilationEngine
    def initialize(jackfile)
        @key = "class"
        @type = nil
        @kind = nil
        @purpose = :define

        @jackfile = jackfile
        xmlfile = jackfile.sub(/\.jack$/, ".xml")
        @fo = File.open(xmlfile, "w")
        
        @tokenizer = JackTokenizer.new(jackfile)
        @symbol_table = SymbolTable.new
        @vmwriter = VMWriter.new
    end
    
    # 'class' className '{' classVarDec* subroutineDec* '}'
    def compile_class
        @tokenizer.has_more_tokens? ? @tokenizer.advance : exit - 1
        
        @fo.puts "<class>"
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
                @fo.puts "</class>"
            end
        end
    end
    
    private
    
    def compile_class_var_dec
        @fo.puts "<classVarDec>"
        if accept?(TokenType::KEYWORD, ["static", "field"])
            @kind = @tokenizer.keyword
            expect_type
            expect(TokenType::IDENTIFIER)
            while accept?(TokenType::SYMBOL, [","]) do
                expect(TokenType::IDENTIFIER)
            end
            
            expect(TokenType::SYMBOL, [";"])
        end
        @fo.puts "</classVarDec>"   
    end
    
    # ('constructor'|'function'|'method') ('void'|type) subroutinName
    # '(' parameterList ')' subroutineBody
    def compile_subroutine
        @symbol_table.start_subroutine
        @purpose = :define

        @fo.puts "<subroutineDec>"
        if accept?(TokenType::KEYWORD, ["constructor", "function", "method"])
            @kind = "subroutine"
            accept?(TokenType::KEYWORD, ["void"]) or accept_type?
            expect(TokenType::IDENTIFIER)
            expect(TokenType::SYMBOL, ["("])
            compile_parameter_list
            expect(TokenType::SYMBOL, [")"])
        end
        
        @fo.puts "<subroutineBody>"
        if accept?(TokenType::SYMBOL, ["{"])
            while apply?(TokenType::KEYWORD, ["var"]) do 
                compile_var_dec
            end
            @purpose = :use
            compile_statements
            expect(TokenType::SYMBOL, ["}"])
        end
        @fo.puts "</subroutineBody>"
        @fo.puts "</subroutineDec>"
    end
    
    def compile_parameter_list
        @fo.puts "<parameterList>"
        if accept_type?
            @kind = "argument"
            expect(TokenType::IDENTIFIER)
            #@symbol_table.define(@tokenizer.identifier, )
            while accept?(TokenType::SYMBOL, [","]) do
                expect_type
                expect(TokenType::IDENTIFIER)
            end
        end
        @fo.puts "</parameterList>"
    end
    
    def compile_var_dec
        @fo.puts "<varDec>"
        if accept?(TokenType::KEYWORD, ["var"])
            @kind = @tokenizer.keyword
            expect_type
            expect(TokenType::IDENTIFIER)
            while apply?(TokenType::SYMBOL, [","]) do
                if accept?(TokenType::SYMBOL, [","])
                    expect(TokenType::IDENTIFIER)
                end
            end
            expect(TokenType::SYMBOL, [";"])
        end
        @fo.puts "</varDec>"   
    end
    
    def compile_statements
        @fo.puts "<statements>"
        while apply?(TokenType::KEYWORD, ["let", "if", "while", "do", "return"]) do
            send("compile_#{@tokenizer.keyword}")
        end
        @fo.puts "</statements>"
    end
    
    def compile_do
        @fo.puts "<doStatement>"    
        if accept?(TokenType::KEYWORD, ["do"])
            expect(TokenType::IDENTIFIER)
            if accept?(TokenType::SYMBOL, ["."])
                expect(TokenType::IDENTIFIER)
            end
            expect(TokenType::SYMBOL, ["("])
            compile_expression_list
            expect(TokenType::SYMBOL, [")"])
            expect(TokenType::SYMBOL, [";"])
        end    
        @fo.puts "</doStatement>"
    end
    
    def compile_let
        @fo.puts "<letStatement>"
        if accept?(TokenType::KEYWORD, ["let"])
            expect(TokenType::IDENTIFIER)
            if accept?(TokenType::SYMBOL, ["["])
                compile_expression
                expect(TokenType::SYMBOL, ["]"])
            end
            expect(TokenType::SYMBOL, ["="])
            compile_expression
            expect(TokenType::SYMBOL, [";"])
        end
        @fo.puts "</letStatement>"
    end
    
    def compile_while
        @fo.puts "<whileStatement>"
        if accept?(TokenType::KEYWORD, ["while"])
            expect(TokenType::SYMBOL, ["("])
            compile_expression
            expect(TokenType::SYMBOL, [")"])
            expect(TokenType::SYMBOL, ["{"])
            compile_statements
            expect(TokenType::SYMBOL, ["}"])
        end
        @fo.puts "</whileStatement>"
    end
    
    def compile_return
        @fo.puts "<returnStatement>"
        if accept?(TokenType::KEYWORD, ["return"])
            unless accept?(TokenType::SYMBOL, [";"])
                compile_expression
                expect(TokenType::SYMBOL, [";"])
            end
        end
        @fo.puts "</returnStatement>"
    end
    
    def compile_if
        @fo.puts "<ifStatement>"
        if accept?(TokenType::KEYWORD, ["if"])
            expect(TokenType::SYMBOL, ["("])
            compile_expression
            expect(TokenType::SYMBOL, [")"])
            expect(TokenType::SYMBOL, ["{"])
            compile_statements
            expect(TokenType::SYMBOL, ["}"])
            if accept?(TokenType::KEYWORD, ["else"])
                expect(TokenType::SYMBOL, ["{"])
                compile_statements
                expect(TokenType::SYMBOL, ["}"])
            end
        end
        @fo.puts "</ifStatement>"
    end
    
    def compile_expression
        @fo.puts "<expression>"
        compile_term
        while apply?(TokenType::SYMBOL, ["+", "-", "*", "/", "&", "|", "<", ">", "="]) do
            if accept?(TokenType::SYMBOL, ["+", "-", "*", "/", "&", "|", "<", ">", "="])
                compile_term
            end
        end
        @fo.puts "</expression>"
    end
    
    def compile_term
        @fo.puts "<term>"
        if accept?(TokenType::INT_CONST) or accept?(TokenType::STRING_CONST) or \
           accept?(TokenType::KEYWORD, ["true", "false", "null", "this"])
        elsif accept?(TokenType::IDENTIFIER)
            if accept?(TokenType::SYMBOL, ["["])
                compile_expression
                expect(TokenType::SYMBOL, ["]"])
            elsif accept?(TokenType::SYMBOL, ["("])
                compile_expression_list
                expect(TokenType::SYMBOL, [")"])
            elsif accept?(TokenType::SYMBOL, ["."])
                expect(TokenType::IDENTIFIER)
                accept?(TokenType::SYMBOL, ["("])
                compile_expression_list
                expect(TokenType::SYMBOL, [")"])
            end
        elsif accept?(TokenType::SYMBOL, ["("])
            compile_expression
            expect(TokenType::SYMBOL, [")"])
        elsif accept?(TokenType::SYMBOL, ["-", "~"])
            compile_term
        end
        @fo.puts "</term>"
    end
    
    def compile_expression_list
        @fo.puts "<expressionList>"
        if apply?(TokenType::SYMBOL, [")"])
            @fo.puts "</expressionList>"
            return
        end
        
        compile_expression
        while accept?(TokenType::SYMBOL, [","]) do
            compile_expression
        end
        @fo.puts "</expressionList>"
    end
    
    # original
    
    def accept?(token_type, token=nil)
        #puts "token_type: #{token_type} tokens:#{token}"
        if @tokenizer.token_type == token_type
            case @tokenizer.token_type
            when TokenType::KEYWORD
                if token.include?(@tokenizer.keyword)
                    @fo.puts "<keyword> #{@tokenizer.keyword} </keyword>"
                    register_key
                else
                    return false
                end
            when TokenType::SYMBOL
                if token.include?(@tokenizer.symbol)
                    @fo.puts "<symbol> #{CGI.escapeHTML(@tokenizer.symbol)} </symbol>"
                else
                    return false
                end
            when TokenType::IDENTIFIER
                #@fo.puts "<identifier> #{@tokenizer.identifier} </identifier>"
                #p caller_locations(1).first.label
                if @purpose == :define
                    puts "define"
                    @symbol_table.define(@tokenizer.identifier, @type, @kind)
                    type = @type
                    kind = @kind
                else
                    puts "use"
                    p type = @symbol_table.type_of(@tokenizer.identifier)
                    kind = @symbol_table.kind_of(@tokenizer.identifier)
                end
                index = @symbol_table.index_of(@tokenizer.identifier)
                @fo.puts "<identifier> #{kind} #{@tokenizer.identifier} #{@purpose} #{index}</identifier>"
            when TokenType::INT_CONST
                @fo.puts "<integerConstant> #{@tokenizer.int_val} </integerConstant>"
            when TokenType::STRING_CONST
                @fo.puts "<stringConstant> #{@tokenizer.string_val} </stringConstant>"
            end
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