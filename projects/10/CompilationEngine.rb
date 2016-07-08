require_relative 'Types'
require_relative 'JackTokenizer'

class CompilationEngine
    #def initialize(xmlfile)
    def initialize(jackfile)
        @jackfile = jackfile
        xmlfile = jackfile.sub(/\.jack$/, "T.xml")
        @fo = File.open(xmlfile, "w")
        
        @tokenizer = JackTokenizer.new(jackfile)
    end
    
    # 'class' className '{' classVarDec* subroutineDec* '}'
    def compile_class
        @tokenizer.has_more_tokens? ? @tokenizer.advance : exit - 1
        
        @fo.puts "<class>"
        if accept?(TokenType::KEYWORD, ["class"])
            expect(TokenType::IDENTIFIER)
            expect(TokenType::SYMBOL, ["{"])
        end
        
        compile_class_var_dec
        compile_subroutine
        
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
        # TODO: whileを呼び出し側に移すか検討する
        while apply?(TokenType::KEYWORD, ["static", "field"]) do
            @fo.puts "<classVarDec>"
            if accept?(TokenType::KEYWORD, ["static", "field"])
                expect_type
                expect(TokenType::IDENTIFIER)
                
                while accept?(TokenType::SYMBOL, [","]) do
                    expect(TokenType::IDENTIFIER)
                end
                
                expect(TokenType::SYMBOL, [";"])
            end
            @fo.puts "</classVarDec>"   
        end    
    end
    
    # ('constructor'|'function'|'method') ('void'|type) subroutinName
    # '(' parameterList ')' subroutineBody
    def compile_subroutine
        # TODO: whileを呼び出し側に移すか検討する
        while apply?(TokenType::KEYWORD, ["constructor", "function", "method"]) do
            @fo.puts "<subroutineDec>"
            if accept?(TokenType::KEYWORD, ["constructor", "function", "method"])
                accept?(TokenType::KEYWORD, ["void"]) or accept_type?
                expect(TokenType::IDENTIFIER)
                expect(TokenType::SYMBOL, ["("])
                compile_parameter_list
                expect(TokenType::SYMBOL, [")"])
            end
            
            @fo.puts "<subroutineBody>"
            if accept?(TokenType::SYMBOL, ["{"])
                compile_var_dec
                compile_statements
                expect(TokenType::SYMBOL, ["}"])
            end
            @fo.puts "</subroutineBody>"
            @fo.puts "</subroutineDec>"
        end
    end
    
    def compile_parameter_list
        @fo.puts "<parameterList>"
        if accept_type?
            expect(TokenType::IDENTIFIER)
            while accept?(TokenType::SYMBOL, [","]) do
                expect_type
                expect(TokenType::IDENTIFIER)
            end
        end
        @fo.puts "</parameterList>"
    end
    
    def compile_var_dec
        #TODO: whileを呼び出し側に移すか検討する
        while apply?(TokenType::KEYWORD, ["var"]) do 
            @fo.puts "<varDec>"
            if accept?(TokenType::KEYWORD, ["var"])
                expect_type
                expect(TokenType::IDENTIFIER)
                
                expect(TokenType::SYMBOL, [";"])
            end
            @fo.puts "</varDec>"   
        end    
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
            2.times do
                if accept?(TokenType::SYMBOL, ["["])
                    compile_expression
                    expect(TokenType::SYMBOL, ["]"])
                end
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
                #2.times do
                #    compile_expression
                #end
                #expect(TokenType::SYMBOL, [";"])
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
        puts "token_type: #{token_type} tokens:#{token}"
        if @tokenizer.token_type == token_type
            case @tokenizer.token_type
            when TokenType::KEYWORD
                if token.include?(@tokenizer.keyword)
                    @fo.puts "<keyword> #{@tokenizer.keyword} </keyword>"
                else
                    return false
                end
            when TokenType::SYMBOL
                if token.include?(@tokenizer.symbol)
                    @fo.puts "<symbol> #{@tokenizer.symbol} </symbol>"
                else
                    return false
                end
            when TokenType::IDENTIFIER
                @fo.puts "<identifier> #{@tokenizer.identifier} </identifier>"
            when TokenType::INT_CONST
                @fo.puts "<intConst> #{@tokenizer.int_val} </intConst>"
            when TokenType::STRING_CONST
                @fo.puts "<stringConst> #{@tokenizer.string_val} </stringConst>"
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
        accept?(TokenType::KEYWORD, ["int", "char", "boolean"]) or accept?(TokenType::IDENTIFIER)
    end
    
    def expect_type
        accept?(TokenType::KEYWORD, ["int", "char", "boolean"]) or expect(TokenType::IDENTIFIER)
    end
end