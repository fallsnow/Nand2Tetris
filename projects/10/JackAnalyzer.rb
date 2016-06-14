require 'cgi'
require_relative 'Types'
require_relative 'JackTokenizer'

class JackAnalyzer
    def initialize(source)
        @source = source
    end
    
    def exec
        jackfiles = Array.new
        if File::ftype(@source) == "directory"
            Dir::entries(@source).each {|entry|
                jackfiles.push("#{@source}\\#{entry}") if entry.include?(".jack")
            }
            vmfile = @source + "\\" + @source.split("\\").last + ".vm"
        else
            jackfiles.push(@source)
            vmfile = File.basename(@source, ".jack") + ".vm"
        end
        
        
        jackfiles.each{|jackfile|
            #p xmlfile = File.basename(jackfile, ".jack") + "T.xml"
            xmlfile = jackfile.sub(/\.jack$/, "T.xml")
            io = File.open(xmlfile, "w")
            io.printf("<tokens>\n")
            
            tokenizer = JackTokenizer.new(jackfile)
            while tokenizer.has_more_tokens?
                tokenizer.advance
                case tokenizer.token_type
                when TokenType::KEYWORD
                    io.printf("<keyword> #{tokenizer.keyword} </keyword>\n")
                when TokenType::SYMBOL
                    io.printf("<symbol> #{CGI.escapeHTML(tokenizer.symbol)} </symbol>\n")
                when TokenType::IDENTIFIER
                    io.printf("<identifier> #{tokenizer.identifier} </identifier>\n")
                when TokenType::INT_CONST
                    io.printf("<integerConstant> #{tokenizer.int_val} </integerConstant>\n")
                when TokenType::STRING_CONST
                    io.printf("<stringConstant> #{tokenizer.string_val} </stringConstant>\n")
                end
            end
            
            io.printf("</tokens>\n")
            io.close
        }
    end
end