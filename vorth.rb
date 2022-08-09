#!/usr/bin/env ruby

module Vorth
  class Token
    attr_accessor :type, :value

    ALLOWED_TYPES = {
      word: Symbol,
      int: Integer,
      float: Float,
      string: String,
    }

    def initialize(type, value)
      unless value.is_a? ALLOWED_TYPES[type]
        raise "value not of allowed type"
      end

      @type = type
      @value = value
    end

    def to_s
      "<#{@type}:#{@value}>"
    end
  end

  class Value
    attr_accessor :value

    ALLOWED_TYPES = {
      int: Integer,
      float: Float,
      string: String,
    }

    def initialize(value)
      unless ALLOWED_TYPES.values.include? value.class
        raise "incorrect value type"
      end

      @value = value
    end

    def to_s
      @value.to_s
    end

    def inspect
      @value.inspect
    end

    def type
      ALLOWED_TYPES.key(@value.class)
    end

    def ==(second); @value == second.value end
    def !=(second); @value != second.value end
    def <(second);  @value < second.value end
    def >(second);  @value > second.value end
    def <=(second); @value <= second.value end
    def >=(second); @value >= second.value end

    def +(second)
      if type == :string || second.type == :string
        "#{@value.to_s}#{second.value.to_s}"
      else
        @value + second.value
      end
    end

    def -(second)
      if type == :string
        @value.gsub(second.value.to_s, "")
      elsif second.type == :string
        raise "cant subtract string from number"
      else
        @value - second.value
      end
    end

    def *(second)
      if type == :string || second.type == :string
        if type == :int || second.type == :int
          @value * second.value
        else
          raise "string can only be multiplied by int"
        end
      else
        @value * second.value
      end
    end

    def /(second)
      if type == :string
        if second.type == :int
          @value.scan /.{1,#{second.value}}/
        else
          raise "string can only by divided by int"
        end
      elsif second.type == :string
        raise "can't divide by string"
      else
        @value.to_f / second.value
      end
    end

    def %(second)
      if type == :int && second.type == :int
        @value % second.value
      else
        raise "modulo can only be aplied to ints"
      end
    end

    def truthy?
      case type
      when :int, :float
        @value != 0
      when :string
        @value.length != 0
      else
        raise "can't check truthiness of #{type}"
      end
    end
  end

  class Stack
    def initialize
      @arr = []
    end

    def to_s
      @arr.to_s
    end

    def push(*args)
      @arr.push *args
    end

    def pop    
      raise "stack underflow" if @arr.size == 0
      @arr.pop
    end

    def peek(position)
      value = @arr[position]
      return value if value
      
      raise "stack underflow"
    end

    def peek_top(index = -1)
      peek index
    end

    def reverse
      @arr = @arr.reverse
    end
  end

  class Vorth
    def initialize(stdout_print: true, debug: false)
      @stdout_print = stdout_print

      @tokens = []
      @stack = Stack.new
      @words = {}
      @vars = {
        PC: 0,      # program counter (index of current instruction in @tokens)
        EXIT: 0,    # if 1 terminate the execution
        SKIP: 0,    # if 1 skip next instruction (or whole block)
        LAST_IF: 0, # last value checked by "if" instruction
      }

      @buffer = ""
    end
    
    def call(to_parse = nil)
      if to_parse
        parse(to_parse)
      else
        while @vars[:EXIT] == 0 && (input = gets)
          parse(input)
          puts((@buffer.length > 0 ? " ok" : "ok") + (@vars[:EXIT] == 1 ? ", bye!" : ""))
          @buffer = ""
          @tokens = []
        end
      end
    end

    def parse(str)
      str.gsub!(/#.*$/, "")

      tokenize(str)
      run

      if @debug
        if @buffer.empty?
          "#{@stack} #{@words}"
        else
          [@buffer, "#{@stack} #{@words}"].join(" ")
        end
      else
        @buffer
      end
    end

    def tokenize(str)
      while str.length > 0
        str = str.strip
        whitespace_pos = str =~ /\s/

        if whitespace_pos
          raw_token, str = str[0...whitespace_pos], str[whitespace_pos..-1]
        else
          raw_token, str = str, ""
        end

        if raw_token =~ /^-?0x[0-9a-fA-F]+$/
          type, value = :int, raw_token.to_i(16)
        elsif raw_token =~ /^-?0o[0-7]+$/ 
          type, value = :int, raw_token.to_i(8)
        elsif raw_token =~ /^-?0b[01]+$/
          type, value = :int, raw_token.to_i(2)
        elsif raw_token =~ /^-?[0-9]+$/ 
          type, value = :int, raw_token.to_i
        elsif raw_token =~ /^-?[0-9]+\.[0-9]+$/ 
          type, value = :float, raw_token.to_f
        elsif raw_token =~ /^"/
          if raw_token =~ /^".*"$/
            type, value = :string, raw_token[1...-1]
          else
            raise "string not closed" unless str =~ /[^\\]"/
            matching_quote_pos = (str =~ /[^\\]"/) + 1
            raw_token = raw_token[1..-1] + str[0...matching_quote_pos]
            raw_token.gsub!('\\"', '"')
            str = str[(matching_quote_pos+1)..-1]
            type, value = :string, raw_token
          end
        else
          type, value = :word, raw_token.to_sym
        end

        @tokens << Token.new(type, value)
      end

      return @tokens
    end
    
    private

    def output(value)
      @buffer += value.to_s
      print value if @stdout_print
    end

    def parse_word(word)
      if word == "{".to_sym
        level = 1
        while level > 0
          token = @tokens[@vars[:PC] += 1]
          level += 1 if token.value == "{".to_sym
          level -= 1 if token.value == "}".to_sym

          break if level == 0
          parse_token token if @vars[:SKIP] == 0
        end
        return
      end

      return if @vars[:SKIP] != 0

      case word
      
      # arithmetic
      when :"+"; @stack.push(@stack.pop + @stack.pop)
      when :"-"
        a, b = @stack.pop, @stack.pop
        @stack.push (b - a)
      when :"*"; @stack.push(@stack.pop * @stack.pop)
      when :"/"
        a, b = @stack.pop, @stack.pop
        @stack.push (b / a)
      when :"//"
        a, b = @stack.pop, @stack.pop
        @stack.push (b / a).to_i
      when :"%"
        a, b = @stack.pop, @stack.pop
        @stack.push (b % a)

      # comparison
      when :"="; @stack.push(@stack.pop == @stack.pop ? 1 : 0)
      when :"!="; @stack.push(@stack.pop != @stack.pop ? 1 : 0)
      when :">"
        a, b = @stack.pop, @stack.pop
        @stack.push(b > a ? 1 : 0)
      when :">="
        a, b = @stack.pop, @stack.pop
        @stack.push(b >= a ? 1 : 0)
      when :"<"
        a, b = @stack.pop, @stack.pop
        @stack.push(b < a ? 1 : 0)
      when :"<="
        a, b = @stack.pop, @stack.pop
        @stack.push(b <= a ? 1 : 0)

      # stack manipulation
      when :swap
        a, b = @stack.pop, @stack.pop
        @stack.push a, b
      when :dup; @stack.push @stack.peek_top
      when :over; @stack.push @stack.peek(-2)
      when :drop; @stack.pop
      when :reverse; @stack.reverse

      # stack values and conversion
      when :chr
        raise "incorrect argument type" unless @stack.peek_top.is_a? Token::ALLOWED_TYPES[:int]
        @stack.push @stack.pop.chr
      when :ord
        raise "incorrect argument type" unless @stack.peek_top.is_a? Token::ALLOWED_TYPES[:string]
        @stack.push @stack.pop.ord
      when :type
        @stack.push Token::ALLOWED_TYPES.key(@stack.pop.class).to_s

      # output
      when :"."; output @stack.pop
      when :br; output "\n"
      when :space; output " "
      when :spaces; output " " * @stack.pop
      when :".stack"; output @stack
      when :".words"
        output "["
        words = @words.map do |word_name, word_contents|
          tokens_string = word_contents.map { |t| t.value.to_s }.join(" ")
          "<#{word_name}: #{tokens_string}>"
        end
        output words.join(", ")
        output "]"
      when :".vars"; output @vars

      # flow control
      when :bye; @vars[:EXIT] = 1
      when :if
        value = @stack.pop
        @vars[:SKIP] = (value == 0 ? 2 : 0)
        @vars[:LAST_IF] = (value == 0 ? 0 : 1)
      when :else
        @vars[:SKIP] = (@vars[:LAST_IF] == 1 ? 2 : 0)
      when "}".to_sym
        raise 'found "}" without matching "{"'

      else
        raise "can't find word \"#{word.to_s}\""
      end
    end

    def parse_token(token)
      if [:int, :float, :string].include? token.type
        @stack.push Value.new(token.value)
      elsif token.type == :word
        if token.value == :":"
          word_name = @tokens[@vars[:PC] += 1].value
          @words[word_name] = []

          while @tokens[@vars[:PC] += 1].value != :";"
            @words[word_name] << @tokens[@vars[:PC]]
          end
        else
          parse_word token.value
        end
      else
        raise "invalid token type"
      end
    end

    def run
      @vars[:PC] = 0

      while @vars[:EXIT] == 0 && @vars[:PC] < @tokens.length
        token = @tokens[@vars[:PC]]

        if @words.keys.include? token.value
          @words[token.value].each { |t| parse_token t }
        else
          parse_token token
        end
        
        @vars[:SKIP] -= 1 if @vars[:SKIP] > 0
        @vars[:PC] += 1
      end
    end
  end
end

if __FILE__ == $0
  if ARGV.length == 1
    file = File.open(ARGV[0])
    Vorth::Vorth.new.call(file.read)
    file.close
  elsif ARGV.length == 0
    Vorth::Vorth.new.call
  else
    puts "Usage: vorth [file]"
  end
end
