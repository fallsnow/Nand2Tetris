require_relative 'Types'
require_relative 'JackTokenizer'

class CompilationEngine
    def initialize(xmlfile)
        @io = File.open(xmlfile, "w")
    end
    
    def compile_class
        #@io.printf("<tokens\n")
        @io.printf("<class>\n")

        tokenizer = JackTokenizer.new(jackfile)
        while tokenizer.has_more_tokens?
            tokenizer.advance
            case tokenizer.token_type
            when TokenType::KEYWORD
                @io.printf("<keyword> #{tokenizer.keyword} </keyword>\n")
            when TokenType::SYMBOL
                @io.printf("<symbol> #{CGI.escapeHTML(tokenizer.symbol)} </symbol>\n")
            when TokenType::IDENTIFIER
                @io.printf("<identifier> #{tokenizer.identifier} </identifier>\n")
            when TokenType::INT_CONST
                @io.printf("<integerConstant> #{tokenizer.int_val} </integerConstant>\n")
            when TokenType::STRING_CONST
                @io.printf("<stringConstant> #{tokenizer.string_val} </stringConstant>\n")
            end
        end
        
        #@io.printf("</tokens>\n")
        @io.printf("</class>\n")
        @io.close
    end
    
    private
    
    def compile_class_var_dec
    
    end
    
    def compile_subroutine
    
    end
    
    def compile_parameter_list
    
    end
    
    def compile_var_dec
    
    end
    
    def compile_statements
    
    end
    
    def compile_do
    
    end
    
    def compile_let
    
    end
    
    def compile_while
    
    end
    
    def compile_return
    
    end
    
    def compile_if
    
    end
    
    def compile_expression
    
    end
    
    def compile_term
    
    end
    
    def compile_expression_list
    
    end
end