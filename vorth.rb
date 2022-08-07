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

    def word?
      @type == :word
    end

    def int?
      @type == :int
    end

    def float?
      @type == :float
    end

    def string?
      @type == :string
    end

    def truthy?
      case @type
      when :int, :float
        @value != 0
      when :string
        @value.length != 0
      else
        raise "can't check truthiness of #{@type.to_s}"
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
      @arr.reverse
    end
  end

  class Vorth
    def initialize(stdout_print: true, debug: false)
      @stdout_print = stdout_print
      @debug = debug

      @tokens = []
      @stack = Stack.new
      @words = {}
      @temp_word = nil
      @vars = {
        PC: 0,
        # MODE: 0,
      }
      @mode = :normal
      @buffer = ""
    end
    
    def call
      while input = gets
        parse(input)
        puts "ok"
        puts "#{@stack} #{@words}" if @debug
      end
    end

    def parse(str)
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
      if @mode != :string
        word = word.downcase
      end

      case @mode
      when :word_name
        @temp_word = word
        @words[word] = []
        @mode = :word_contents
      when :word_contents
        if word == :";"
          @mode = :normal
          @temp_word = nil
        else
          @words[@temp_word].push word
        end
      when :normal
        if @words.keys.include? word
          @words[word].each { |w| parse_word(w) }
        else
          case word

          # words
          when :":"; @mode = :word_name
          
          # arithmetic
          when :"+"; @stack.push(@stack.pop + @stack.pop)
          when :"-"
            a, b = @stack.pop, @stack.pop
            @stack.push(b - a)
          when :"*"; @stack.push(@stack.pop * @stack.pop)
          when :"/"
            a, b = @stack.pop, @stack.pop
            @stack.push (b / a).to_i
          when :"%"
            a, b = @stack.pop, @stack.pop
            @stack.push (b % a)

          # staack manipulation
          when :swap
            a, b = @stack.pop, @stack.pop
            @stack.push a, b
          when :dup; @stack.push @stack.peek_top
          when :over; @stack.push @stack.peek(-2)
          when :drop; @stack.pop
          when :reverse; @stack = @stack.reverse

          # output
          when :"."; output @stack.pop
          when :cr; puts
          when :space; output " "
          when :spaces; output " " * @stack.pop
          when :emit; output @stack.pop.chr
          when :".stack"; output @stack
          when :".words"; output @words
          when :".vars"; output @vars
          else
            raise "can't find word \"#{word.to_s}\""
          end
        end
      end
    end

    def parse_words_arr(words_arr)
      words_arr
        .map(&:to_sym)
        .each { |word|
          if @exit_on_error && !@error.empty
            break
          end
          
          parse_word(word)
        }
    end

    def run
      @vars[:PC] = 0
      should_exit = false

      while !should_exit && @vars[:PC] < @tokens.length
        token = @tokens[@vars[:PC]]

        if [:int, :float, :string].include? token.type
          @stack.push token.value
        else
          parse_word token.value
        end

        @vars[:PC] += 1
      end
    end
  end
end
