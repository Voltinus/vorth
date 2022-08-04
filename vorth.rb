#!/usr/bin/env ruby

class Vorth
  def initialize(stdout_print: true, debug: false)
    @stack = []
    @words = {}
    @temp_word = nil

    # :normal, :word_name, :word_contents, :string
    @mode = :normal
    @debug = debug
    @buffer = ""
  end
  
  def call
    while input = gets
      parse(input)
      puts " ok"
      puts "#{@stack} #{@words}" if @debug
    end
  end

  def parse(words_str)
    parse_words_arr(words_str.split)
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
  
  private

  def output(value)
    @buffer += value.to_s
    print value if @stdout_print
  end

  def error(message)
    raise message
  end

  def stack_push(*args)
    @stack.push *args
  end

  def stack_pop
    if @stack.size > 0
      return @stack.pop
    else
      error "stack underflow"
    end
  end

  def stack_peek(position)
    value = @stack[position]
    return value if value
    
    error "stack underflow"
  end

  def stack_peek_top(index = -1)
    stack_peek index
  end

  def parse_number(number)
    number = number.to_s

    if number =~ /^-?0x/
      number = number.to_i(16)
    elsif number =~ /^-?0o/ 
      number = number.to_i(8)
    elsif number =~ /^-?0b/ 
      number = number.to_i(2)
    elsif number =~ /^-?[0-9]/ 
      number = number.to_i
    else
      error "can't find word \"#{number}\" or parse it as number"
    end

    stack_push number
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
    when :string
      if word == :'"'
        if @temp_word
          @mode = :word_contents
        else
          @mode = :normal
        end
      else
        output "#{word.to_s} "
      end
    when :normal
      if @words.keys.include? word
        @words[word].each { |w| parse_word(w) }
      else
        case word
        when :":"; @mode = :word_name
        when :"+"; stack_push(stack_pop + stack_pop)
        when :"-"
          a, b = stack_pop, stack_pop
          stack_push(b - a)
        when :"*"; stack_push(stack_pop * stack_pop)
        when :"/"
          a, b = stack_pop, stack_pop
          stack_push (b / a).to_i
        when :"%"
          a, b = stack_pop, stack_pop
          stack_push (b % a)
        when :swap
          a, b = stack_pop, stack_pop
          stack_push a, b
        when :dup; stack_push stack_peek_top
        when :over; stack_push stack_peek(-2)
        # TODO: :rot, :drop, :2swap, :2dup, :2over, :2drop
        when :"."; output stack_pop
        when :cr; puts
        when :space; output " "
        when :spaces; output " " * stack_pop
        when :emit; output stack_pop.chr
        when :'."'; @mode = :string
        when :".s"; output @stack
        else
          parse_number(word)
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
end
