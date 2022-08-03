#!/usr/bin/env ruby

require_relative 'vforth'
require 'minitest/autorun'

class TestVForth < Minitest::Test
  def setup
    @vf = VForth.new
  end

  def expect(input, output)
    original_stdout = $stdout
    $stdout = StringIO.new
    @vf.parse(input)
    assert_equal($stdout.string, output)
    $stdout = original_stdout
  end

  def expect_error(input, error)
    original_stdout = $stdout
    $stdout = StringIO.new
    assert_raises(SystemExit) { @vf.parse(input) }
    assert_equal($stdout.string, "error: #{error}")
    $stdout = original_stdout
  end

  def test_numbers
    expect '1 2 3 . . .', '321'
    expect_error '1 . .', 'stack underfloww'
  end
end
