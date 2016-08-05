require_relative 'Types'

class JackTokenizer
    def initialize(jackfile)
        tokenize(jackfile)
        @current_token = nil
        @keyword = nil
        @symbol = nil
        @identifier = nil
        @int_val = nil
        @string_val = nil
    end
    
    def has_more_tokens?
        !@tokens.empty?    
    end
    
    def advance
        @current_token = @tokens.shift
    end
    
    def token_type
    #puts "current token: #{@current_token}"
        case @current_token
        when /^class$|^constructor$|^function$|^method$|^field$|^static$|^var$|^int$|^char$|^boolean$|^void$|^true$|^false$|^null$|^this$|^let$|^do$|^if$|^else$|^while$|^return$/
            #puts "key: #{@current_token}"
            @keyword = @current_token
            TokenType::KEYWORD
        when /\{|\}|\(|\)|\[|\]|\.|,|;|\+|-|\*|\/|&|\||<|>|=|~/
            @symbol = @current_token
            TokenType::SYMBOL
        when /"(.+)"/
            #@current_token = $1
            @string_val = @current_token
            TokenType::STRING_CONST
        when /^[a-zA-Z_][\w_]*$/
            @identifier = @current_token
            TokenType::IDENTIFIER
        when /\d+/
            @int_val = @current_token
            TokenType::INT_CONST
        else
            puts "Illegal Token"
            puts @current_token
            exit -1
        end
    end
    
    def keyword
        @keyword
    end
    
    def symbol
        @symbol
    end
    
    def identifier
        @identifier
    end
    
    def int_val
        @int_val
    end
    
    def string_val
        @string_val =~ /"(.+)"/
        $1
    end
=begin    
    def peek
        @tokens[0]
    end
    def show
        @tokens
    end
=end
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