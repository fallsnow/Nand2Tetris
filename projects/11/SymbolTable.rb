require_relative 'Types'

class SymbolTable
    def initialize
        @static_count = 0
        @field_count = 0
        @argument_count = 0
        @var_count = 0

        @class_table = Hash.new
        @subroutine_table = Hash.new
    end

    def start_subroutine
        @subroutine_table.clear
        @argument_count = 0
        @var_count = 0
    end

    def define(name, type, kind)
        case kind
        when /static/
            unless @class_table.include?(name)
                @class_table.store(name, [type, kind, @static_count])
                @static_count += 1
        #p @class_table
            end
        when /field/
            unless @class_table.include?(name)
                @class_table.store(name, [type, kind, @field_count])
                @field_count += 1
        #p @class_table
            end
        when /argument/
            unless @subroutine_table.include?(name)
                @subroutine_table.store(name, [type, kind, @argument_count])
                @argument_count += 1
        #p @subroutine_table
            end
        when /var/
            unless @subroutine_table.include?(name)
                @subroutine_table.store(name, [type, kind, @var_count])
                @var_count += 1
        #p @subroutine_table
            end
        else
            puts "ELSE?"
        end
    end

    def var_count(kind)
        eval("@#{kind}_count")    
    end

    def kind_of(symbol_name)
        if @subroutine_table.has_key?(symbol_name)
            value = @subroutine_table.fetch(symbol_name)
            puts "#{symbol_name}'s value = #{value}"
            kind = value[1]
        elsif @class_table.has_key?(symbol_name)
            value = @class_table.fetch(symbol_name)
            puts "#{symbol_name}'s value = #{value}"
            kind = value[1]
        else
            kind = :none
        end
        puts "retun kind: #{kind}"
        return kind
    end

    def type_of(symbol_name)
        if @subroutine_table.has_key?(symbol_name)
            value = @subroutine_table.fetch(symbol_name)
            type = value[0]
        elsif @class_table.has_key?(symbol_name)
            value = @class_table.fetch(symbol_name)
            type = value[0]
        else
            type = nil
        end
        return type
    end

    def index_of(symbol_name)
        if @subroutine_table.has_key?(symbol_name)
            value = @subroutine_table.fetch(symbol_name)
            count = value[2]
        elsif @class_table.has_key?(symbol_name)
            value = @class_table.fetch(symbol_name)
            count = value[2]
        else
            count = nil
        end
        return count
    end
end