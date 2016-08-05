require_relative 'Translator'

if ARGV.size < 1 then
    puts "Please input the source file or directory name"
    exit
end

puts source = ARGV[0] #File.basename(ARGF.filename, ".vm")
#filename += "hack"
#f = File.open(filename, "w")

translator = Translator.new(source)
translator.exec