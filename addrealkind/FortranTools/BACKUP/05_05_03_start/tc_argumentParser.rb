#!/usr/bin/env ruby

require 'test/unit'
require 'argumentParser'
    

class TestArgumentParser

  attr_reader :errorMsg

  def initialize(in_str, num_args_OK, args_OK)
    @instr = in_str
    @numargsOK = num_args_OK
    @argsOK = args_OK
    @ap = nil
  end

  def num_args_correct?
    @ap = ArgumentParser.new(@instr)
    numargs = @ap.num_args
    @errorMsg = ""
    resultOK?(@numargsOK, numargs, "NUMBER OF ARGUMENTS")
  end

  def args_correct?
    @ap = ArgumentParser.new(@instr)
    args = @ap.get_args.join(":")
#print "DEBUG:  args = <<#{@ap.get_args.join(":")}>>\n"
    @errorMsg = ""
    resultOK?(@argsOK, args, "ARGUMENTS")
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
                   "arg1", 1, 
                   "arg1" )
    @argtests << TestArgumentParser.new( 
                   "arg1,arg2,arg3", 3, 
                   "arg1:arg2:arg3" )
    @argtests << TestArgumentParser.new( 
                   "arg1,(arg2,arg3)", 2, 
                   "arg1:(arg2,arg3)" )
    @argtests << TestArgumentParser.new( 
                   "(arg1,(arg2,arg3)),arg4", 2, 
                   "(arg1,(arg2,arg3)):arg4" )
    @argtests << TestArgumentParser.new( 
                   "(a1,(a2,a3)),a4,(a5,(a6,a7),a8)", 3, 
                   "(a1,(a2,a3)):a4:(a5,(a6,a7),a8)" )
    @argtests << TestArgumentParser.new( 
                   "(a1,(a2,a3)", nil, 
                   "" )
    @argtests << TestArgumentParser.new( 
                   "", 0, "" )
#$$$here...  add tests
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

  def teardown
  end

end  # class TC_ArgumentParser


