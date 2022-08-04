#!/usr/bin/env ruby

require_relative "vorth"
require "minitest/autorun"


describe Vorth do
  before do
    @v = Vorth.new(debug: true)
  end

  def assert_error(error_expected, input)
    error = assert_raises { @v.parse(input) }
    assert_match Regexp.new(error_expected), error.message
  end

  describe "putting values on stack" do
    describe "numbers" do
      n = rand(1..100)

      describe "decimal" do
        it("zero")     { assert_equal "0 [] {}",     @v.parse("0 .") }
        it("positive") { assert_equal "#{n} [] {}",  @v.parse("#{n} .") }
        it("negative") { assert_equal "-#{n} [] {}", @v.parse("-#{n} .") }
      end

      describe "hexadecimal" do
        it("zero")     { assert_equal "0 [] {}",     @v.parse("0 .") }
        it("positive") { assert_equal "#{n} [] {}",  @v.parse("0x#{n.to_s(16)} .") }
        it("negative") { assert_equal "-#{n} [] {}", @v.parse("-0x#{n.to_s(16)} .") }
      end

      describe "octal" do
        it("zero")     { assert_equal "0 [] {}",     @v.parse("0 .") }
        it("positive") { assert_equal "#{n} [] {}",  @v.parse("0o#{n.to_s(8)} .") }
        it("negative") { assert_equal "-#{n} [] {}", @v.parse("-0o#{n.to_s(8)} .") }
      end

      describe "binary" do
        it("zero")     { assert_equal "0 [] {}",     @v.parse("0 .") }
        it("positive") { assert_equal "#{n} [] {}",  @v.parse("0b#{n.to_s(2)} .") }
        it("negative") { assert_equal "-#{n} [] {}", @v.parse("-0b#{n.to_s(2)} .") }
      end

      describe "invalid" do
        it("raises eror") { assert_error "can't find word \"asdf\" or parse it as number", "asdf ." }
      end
    end
  end

  describe "printing values" do
    n = rand(-100..100)
    n5_10 = rand(5..10)

    describe "dot" do
      it("works with at least one element on stack") { assert_equal "#{n} [] {}", @v.parse("#{n} .") }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "." }
    end

    describe "space" do
      it("works") { assert_equal "  [] {}", @v.parse("space") }
    end

    describe "spaces" do
      it("works with at least one element on stack") { assert_equal "#{' '*n5_10} [] {}", @v.parse("#{n5_10} spaces") }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "spaces" }
    end
  end

  describe "arithmetic" do
    n1 = rand(-100..100)
    n2 = rand(-100..100)
    
    describe "addition" do
      it("works with at least two elements on stack") { assert_equal "#{n1+n2} [] {}", @v.parse("#{n1} #{n2} + .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} +" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "+" }
    end
    
    describe "subtraction" do
      it("works with at least two elements on stack") { assert_equal "#{n1-n2} [] {}", @v.parse("#{n1} #{n2} - .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} -" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "-" }
    end
    
    describe "multiplication" do
      it("works with at least two elements on stack") { assert_equal "#{n1*n2} [] {}", @v.parse("#{n1} #{n2} * .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} *" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "*" }
    end
    
    describe "division" do
      it("works with at least two elements on stack") { assert_equal "#{(n1/n2).to_i} [] {}", @v.parse("#{n1} #{n2} / .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} /" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "/" }
    end
    
    describe "modulo" do
      it("works with at least two elements on stack") { assert_equal "#{n1%n2} [] {}", @v.parse("#{n1} #{n2} % .") }
      it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} %" }
      it("doesn't work with no elements on stack") { assert_error "stack underflow", "%" }
    end
  end

  describe "stack manipulation" do
    describe "singles" do
      n1 = rand(-100..100)
      n2 = rand(-100..100)

      describe "swap" do
        it("works with at least two elements on stack") { assert_equal "[#{n2}, #{n1}] {}", @v.parse("#{n1} #{n2} swap") }
        it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} swap" }
        it("doesn't work with no elements on stack") { assert_error "stack underflow", "swap" }
      end

      describe "dup" do
        it("works with at least one element on stack") { assert_equal "[#{n1}, #{n1}] {}", @v.parse("#{n1} dup") }
        it("doesn't work with no elements on stack") { assert_error "stack underflow", "dup" }
      end

      describe "over" do
        it("works with at least two elements on stack") { assert_equal "[#{n1}, #{n2}, #{n1}] {}", @v.parse("#{n1} #{n2} over") }
        it("doesn't work with one element on stack") { assert_error "stack underflow", "#{n1} over" }
        it("doesn't work with no elements on stack") { assert_error "stack underflow", "over" }
      end
    end

    describe "doubles" do
      
    end
  end
end
