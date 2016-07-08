require_relative 'Types'

class JackTokenizer
    def initialize(jackfile)
        tokenize(jackfile)
        @current_token
    end
    
    def has_more_tokens?
        !@tokens.empty?    
    end
    
    def advance
        @current_token = @tokens.shift
    end
    
    def token_type
    puts @current_token
        case @current_token
        when /^class$|^constructor$|^function$|^method$|^field$|^static$|^var$|^int$|^char$|^boolean$|^void$|^true$|^false$|^null$|^this$|^let$|^do$|^if$|^else$|^while$|^return$/
            puts "key: #{@current_token}"
            TokenType::KEYWORD
        when /\{|\}|\(|\)|\[|\]|\.|,|;|\+|-|\*|\/|&|\||<|>|=|~/
            TokenType::SYMBOL
        when /"(.+)"/
            p $1
            @current_token = $1
            TokenType::STRING_CONST
        when /[a-zA-Z_][\w_]*/
            TokenType::IDENTIFIER
        when /\d+/
            TokenType::INT_CONST
        else
            puts "Illegal Token"
            puts @current_token
            exit -1
        end
    end
    
    def keyword
        @current_token
    end
    
    def symbol
        @current_token
    end
    
    def identifier
        @current_token
    end
    
    def int_val
        @current_token
    end
    
    def string_val
        @current_token
    end
    
    def peek
        @tokens[0]
    end
    def show
        @tokens
    end
    private
    
    def tokenize(jackfile)
        io = File.open(jackfile, "r")
        file = io.read
        file.gsub!(/\/\/.*\n/, '') # //コメント削除
        file.gsub!(/\/\*\/?([^\/]|[^*]\/|\n)*\*\//, '') # /* */コメント削除

        symbols = ["{", "}", "(", ")", "[", "]",
                   ".", ",", ";", "+", "-", "*", "/",
                   "&", "|", "<", ">", "=", "~"]
        symbols.each do |s|
            re = Regexp.new(Regexp.escape(s))
            file.gsub!(re, " #{s} ")
        end
        p @tokens = file.split(/(".*"|\s)/).select{|s| s =~ /[^\t\n\s]/}
    end
end