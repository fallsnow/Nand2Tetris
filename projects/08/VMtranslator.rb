require_relative 'Translator'

if ARGV.size < 1 then
    puts "Please input the source file or directory name"
    exit
end

source = ARGV[0] #File.basename(ARGF.filename, ".vm")

translator = Translator.new(source)
translator.exec