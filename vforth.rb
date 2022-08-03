#!/usr/bin/env ruby

class VForth
  def initialize
    @stack = []
    @words = {}
    @temp_word = nil

    # :normal, :word_name, :word_contents, :string
    @mode = :normal
    @debug = false
  end
  
  def call
    while input = gets
      parse(input)
      puts ' ok'
      puts "#{@stack} #{@words}" if @debug
    end
  end

  def parse(words_str)
    parse_words_arr(words_str.split)
  end
  
  private

  def error(message)
    puts "error: #{message}"
    exit 1
  end

  def stack_push(var)
    @stack.push var
  end

  def stack_pop
    if @stack.size > 0
      return @stack.pop
    else
      error "stack underflow"
    end
  end

  def stack_peek(position)
    if @stack.size > position.abs
      return @stack[position]
    else
      error "stack underflow"
    end
  end

  def stack_peek_top(index = -1)
    stack_peek index
  end

  def parse_number(number)
    number = number.to_s

    if number =~ /^0x/
      number = number.to_i(16)
    elsif number =~ /^[0-9]/ 
      number = number.to_i
    else
      error "can't find word '#{number}' or parse it as number"
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
      if word == :';'
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
        print "#{word.to_s} "
      end
    when :normal
      if @words.keys.include? word
        @words[word].each { |w| parse_word(w) }
      else
        case word
        when :':'; @mode = :word_name
        when :'+'; stack_push(stack_pop + stack_pop)
        when :'-'
          a, b = stack_pop, stack_pop
          stack_push(b - a)
        when :'*'; stack_push(stack_pop * stack_pop)
        when :'/'
          a, b = stack_pop, stack_pop
          stack_push (b / a).to_i
        when :'/mod'
          a, b = stack_pop, stack_pop
          stack_push (b % a)
          stack_push (b / a).to_i
        when :mod
          a, b = stack_pop, stack_pop
          stack_push (b % a)
        when :swap
          a, b = stack_pop, stack_pop
          stack_push b, a
        when :dup; stack_push stack_peek_top
        when :over; stack_push stack_peek(-2)
        # TODO: :rot, :drop, :2swap, :2dup, :2over, :2drop
        when :'.'; print stack_pop
        when :cr; puts
        when :space; print ' '
        when :spaces; print ' ' * stack_pop
        when :emit; print stack_pop.chr
        when :'."'; @mode = :string
        when :'.s'; print @stack
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
