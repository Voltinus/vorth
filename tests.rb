#!/usr/bin/env ruby

require_relative "vorth"
require "minitest/autorun"


describe Vorth::Vorth do
  before do
    @v = Vorth::Vorth.new(stdout_print: false)
  end

  def assert_error(error_expected, input)
    error = assert_raises { @v.parse(input) }
    assert_match Regexp.new(error_expected), error.message
  end

  describe "putting values on stack" do
    describe "numbers" do
      n = rand(1..100)

      describe "decimal" do
        it("zero")     { assert_equal "0",     @v.parse("0 .") }
        it("positive") { assert_equal "#{n}",  @v.parse("#{n} .") }
        it("negative") { assert_equal "-#{n}", @v.parse("-#{n} .") }
      end

      describe "hexadecimal" do
        it("zero")     { assert_equal "0",     @v.parse("0 .") }
        it("positive") { assert_equal "#{n}",  @v.parse("0x#{n.to_s(16)} .") }
        it("negative") { assert_equal "-#{n}", @v.parse("-0x#{n.to_s(16)} .") }
      end

      describe "octal" do
        it("zero")     { assert_equal "0",     @v.parse("0 .") }
        it("positive") { assert_equal "#{n}",  @v.parse("0o#{n.to_s(8)} .") }
        it("negative") { assert_equal "-#{n}", @v.parse("-0o#{n.to_s(8)} .") }
      end

      describe "binary" do
        it("zero")     { assert_equal "0",     @v.parse("0 .") }
        it("positive") { assert_equal "#{n}",  @v.parse("0b#{n.to_s(2)} .") }
        it("negative") { assert_equal "-#{n}", @v.parse("-0b#{n.to_s(2)} .") }
      end

      describe "invalid" do
        it("raises eror") { assert_error "can't find word \"asdf\"", "asdf ." }
      end
    end

    describe "strings" do
      it("works with regular strings") { assert_equal "Hello, world!", @v.parse('"Hello," " world!" reverse . .') }
      it("works with escaped double quotes") { assert_equal " \" ", @v.parse('" \\" " .') }
    end
  end

  describe "words" do
    describe "defining new words" do
      it { assert_equal "[<a: 1 .>]", @v.parse(": a 1 . ; .words") }
    end

    describe "executing defined words" do
      it { assert_equal "1", @v.parse(": a 1 . ; a") }
    end

    describe "overwriting existing words" do
      it { assert_equal "[<+: 1 .>]", @v.parse(": + 1 . ; .words") }
    end

    describe "executing overwritten words" do
      it { assert_equal "1", @v.parse(": + 1 . ; +") }
    end
  end

  describe "arithmetic" do
    n1 = rand(-100..100)
    n2 = rand(-100..100)
    
    describe "addition" do
      it("works with at least two elements on stack") { assert_equal "#{n1+n2}", @v.parse("#{n1} #{n2} + .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} +" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "+" }
    end
    
    describe "subtraction" do
      it("works with at least two elements on stack") { assert_equal "#{n1-n2}", @v.parse("#{n1} #{n2} - .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} -" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "-" }
    end
    
    describe "multiplication" do
      it("works with at least two elements on stack") { assert_equal "#{n1*n2}", @v.parse("#{n1} #{n2} * .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} *" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "*" }
    end
    
    describe "floating point division" do
      it("works with at least two elements on stack") { assert_equal "#{(n1.to_f/n2)}", @v.parse("#{n1} #{n2} / .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} /" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "/" }
    end
    
    describe "integer division" do
      it("works with at least two elements on stack") { assert_equal "#{(n1/n2).to_i}", @v.parse("#{n1} #{n2} // .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} //" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "//" }
    end
    
    describe "modulo" do
      it("works with at least two elements on stack") { assert_equal "#{n1%n2}", @v.parse("#{n1} #{n2} % .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} %" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "%" }
    end
  end

  describe "stack manipulation" do
    n1 = rand(-100..100)
    n2 = rand(-100..100)

    describe "swap" do
      it("works with at least two elements on stack") { assert_equal "[#{n2}, #{n1}]", @v.parse("#{n1} #{n2} swap .stack") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} swap" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "swap" }
    end

    describe "dup" do
      it("works with at least one element on stack") { assert_equal "[#{n1}, #{n1}]", @v.parse("#{n1} dup .stack") }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "dup" }
    end

    describe "over" do
      it("works with at least two elements on stack") { assert_equal "[#{n1}, #{n2}, #{n1}]", @v.parse("#{n1} #{n2} over .stack") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} over" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "over" }
    end

    describe "drop" do
      it("works with at least one element on stack") { assert_equal "[]", @v.parse("#{n1} drop .stack") }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "drop" }
    end

    describe "reverse" do
      it("works with two elements") { assert_equal "[#{n2}, #{n1}]", @v.parse("#{n1} #{n2} reverse .stack") }
      it("works with no elements") { assert_equal "", @v.parse("reverse") }
    end
  end

  describe "stack values and conversion" do
    describe "chr" do
      it("works with at least one element on stack of type int") { assert_equal "*", @v.parse("42 chr .") }
      it("doesn't work with element of type other than int") { assert_error "incorrect argument type", '"V" chr' }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "chr" }
    end

    describe "ord" do
      it("works with at least one element on stack of type string") { assert_equal "42", @v.parse('"*" ord .') }
      it("doesn't work with element of type other than string") { assert_error "incorrect argument type", "1 ord" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "ord" }
    end

    describe "type" do
      describe "works with at least one element on stack" do
        it("of type string") { assert_equal "string", @v.parse('"V" type .') }
        it("of type float") { assert_equal "float", @v.parse('3.14 type .') }
        it("of type int") { assert_equal "int", @v.parse('237 type .') }
      end

      it("doesn't work with no elements on stack") { assert_error "stack underflow", "type" }
    end
  end

  describe "output" do
    n = rand(-100..100)
    n5_10 = rand(5..10)

    describe "dot" do
      it("works with at least one element on stack") { assert_equal "#{n}", @v.parse("#{n} .") }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "." }
    end

    describe "br" do
      it { assert_equal "\n", @v.parse("br") }
    end

    describe "space" do
      it { assert_equal " ", @v.parse("space") }
    end

    describe "spaces" do
      it("works with at least one element on stack") { assert_equal "#{' '*n5_10}", @v.parse("#{n5_10} spaces") }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "spaces" }
    end

    describe ".stack" do
      it { assert_equal "[1, 2, 3]", @v.parse("1 2 3 .stack") }
    end

    describe ".words" do
      it { assert_equal "[<a: >, <b: 1 .>]", @v.parse(": a ; : b 1 . ; .words") }
    end
  end

  describe "flow control" do
    n1 = rand(-100..100)
    n2 = rand(-100..100)
    n3 = rand(-100..100)

    describe "bye" do
      it("exits the program unconditionally") { assert_equal "#{n3}#{n2}", @v.parse("#{n1} #{n2} #{n3} . . bye .") }
    end

    describe "comparison" do
      describe "equals" do
        it("works with at least two elements on stack") { assert_equal "1", @v.parse("#{n1} dup = .") }
        it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} =" }
        it("doesn't work with no elements on stack") { assert_error "stack underflow", "=" }
      end
    end

    describe "if" do
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "if" }

      describe "when value is truthy" do
        it("runs single command") { assert_equal "#{n1}", @v.parse("#{n1} 1 if .") }
        it("runs block") { assert_equal "#{n3}#{n2}#{n1}", @v.parse("#{n1} #{n2} #{n3} 1 if { . . . }") }
      end

      describe "when value is falsy" do
        it("doesn't run single command") { assert_equal "0", @v.parse("#{n1} 0 if . 0 .") }
        it("doesn't run block") { assert_equal "0", @v.parse("#{n1} #{n2} #{n3} 0 if { . . . } 0 .") }
      end
    end

    describe "else" do
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "else" }

      describe 'when previous "if" value was truthy' do
        it("doesn't run single command") { assert_equal "[#{n1}]", @v.parse("1 if #{n1} else #{n2} .stack") }
        it("doesn't runs block") { assert_equal "[#{n1}]", @v.parse("1 if { #{n1} } else { #{n2} } .stack") }
      end

      describe 'when previous "if" value was falsy' do
        it("runs single command") { assert_equal "[#{n2}]", @v.parse("0 if #{n1} else #{n2} .stack") }
        it("runs block") { assert_equal "[#{n2}]", @v.parse("0 if { #{n1} } else { #{n2} } .stack") }
      end
    end
  end
end
