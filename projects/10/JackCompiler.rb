require_relative 'JackAnalyzer'

if ARGV.size < 1 then
    puts "Please input the source file or directory name"
    exit
end

source = ARGV[0] #File.basename(ARGF.filename, ".vm")

analyzer = JackAnalyzer.new(source)
analyzer.exec