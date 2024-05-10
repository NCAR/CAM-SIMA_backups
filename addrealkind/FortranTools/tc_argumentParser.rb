#!/usr/bin/env ruby

require 'test/unit'
require 'argumentParser'
    

class TestArgumentParser

  attr_reader :errorMsg

  def initialize(in_str, offset, routine_OK, num_args_OK, args_OK, open_OK, close_OK)
    @instr = in_str
    @str_offset = offset
    @routineOK = routine_OK
    @numargsOK = num_args_OK
    @argsOK = args_OK
    @openOK = open_OK
    @closeOK = close_OK
    @ap = nil
  end

  def routine_correct?
    @ap = ArgumentParser.new(@instr, @str_offset)
    routine = @ap.routine_name
    @errorMsg = ""
    resultOK?(@routineOK, routine, "NAME OF ROUTINE")
  end

  def num_args_correct?
    @ap = ArgumentParser.new(@instr, @str_offset)
    numargs = @ap.num_args
    @errorMsg = ""
    resultOK?(@numargsOK, numargs, "NUMBER OF ARGUMENTS")
  end

  def args_correct?
    @ap = ArgumentParser.new(@instr, @str_offset)
    args = @ap.get_args.join(":")
#print "DEBUG:  args = <<#{@ap.get_args.join(":")}>>\n"
    @errorMsg = ""
    resultOK?(@argsOK, args, "ARGUMENTS")
  end

  def open_correct?
    @ap = ArgumentParser.new(@instr, @str_offset)
    open = @ap.open_parens_index
    @errorMsg = ""
    resultOK?(@openOK, open, "INDEX OF OPEN PARENTHESIS")
  end

  def close_correct?
    @ap = ArgumentParser.new(@instr, @str_offset)
    close = @ap.close_parens_index
    @errorMsg = ""
    resultOK?(@closeOK, close, "INDEX OF CLOSE PARENTHESIS")
  end

  def resultOK?(expected, actual, errorHeader)
    ret = (expected == actual)
    @errorMsg = "NO ERROR\n"
    unless ret then
      @errorMsg =  "ERROR IN #{errorHeader}:\n"
      @errorMsg << "EXPECTED:  <#{expected}>\n"
      @errorMsg << "BUT GOT:   <#{actual}>\n"
    end
    ret
  end

end   # class TestArgumentParser



class TC_ArgumentParser < Test::Unit::TestCase

  def setup
    @argtests = []
    @argtests << TestArgumentParser.new( 
                   "MIN(arg1)", 0, "MIN", 1, 
                   "arg1", 3, 8 )
    @argtests << TestArgumentParser.new( 
                   "MAX(arg1,arg2,arg3)", 0, "MAX", 3, 
                   "arg1:arg2:arg3", 3, 18 )
    @argtests << TestArgumentParser.new( 
                   "FOO (arg1,(arg2,arg3)), BAR(x,y,z)  ", 0, "FOO ", 2, 
                   "arg1:(arg2,arg3)", 4, 21 )
    @argtests << TestArgumentParser.new( 
                   "FOO (arg1,(arg2,arg3)), BAR(x,y,z)  ", 24, "BAR", 3, 
                   "x:y:z", 27, 33 )
    @argtests << TestArgumentParser.new( 
                   "  BAR  ((arg1,(arg2,arg3)),arg4)", 0, "  BAR  ", 2, 
                   "(arg1,(arg2,arg3)):arg4", 7, 31 )
    @argtests << TestArgumentParser.new( 
                   "BAH((a1,(a2,a3)),a4,(a5,(a6,a7),a8))", 0, "BAH", 3, 
                   "(a1,(a2,a3)):a4:(a5,(a6,a7),a8)", 3, 35 )
    @argtests << TestArgumentParser.new( 
                   "FAKE(PUBLIC operator(+), operator(-))", 0, "FAKE", 2, 
                   "PUBLIC operator(+): operator(-)", 4, 36 )
    @argtests << TestArgumentParser.new( 
                   "FAKE(REAL, PUBLIC, PARAMETER :: a1(:,:), a2(:))", 0, "FAKE", 4, 
                   "REAL: PUBLIC: PARAMETER :: a1(:,:): a2(:)", 4, 46 )
    @argtests << TestArgumentParser.new( 
                   "WOO(  )", 0, "WOO", 0, "", 3, 6 )
#$$$here...  add tests
  end

  def test_routine
    @argtests.each do |argtest|
      assert(argtest.routine_correct?, argtest.errorMsg)
    end
  end

  def test_num_args
    @argtests.each do |argtest|
      assert(argtest.num_args_correct?, argtest.errorMsg)
    end
  end

  def test_args
    @argtests.each do |argtest|
      assert(argtest.args_correct?, argtest.errorMsg)
    end
  end

  def test_open
    @argtests.each do |argtest|
      assert(argtest.open_correct?, argtest.errorMsg)
    end
  end

  def test_close
    @argtests.each do |argtest|
      assert(argtest.close_correct?, argtest.errorMsg)
    end
  end

  def teardown
  end

end  # class TC_ArgumentParser


