#!/usr/bin/env ruby

require 'test/unit'
require 'maskedString'
    

class TestMaskedString

  attr_reader :errorMsg

  def initialize(in_str, in_mask, outstr_mask_OK, outstr_unmask_OK)
    @instr = in_str
    @inmask = in_mask
    @outstrmask_OK = outstr_mask_OK
    @outstrunmask_OK = outstr_unmask_OK
  end

  def mask_unmask_correct?
    ms = MaskedString.new(@instr, @inmask)
    @outstrmask = ms.get_masked
    @outstrunmask = ms.get_unmasked
    @errorMsg = ""
    resultOK?(@outstrmask_OK, @outstrmask, "MASKED STRINGS")
    resultOK?(@outstrunmask_OK, @outstrunmask, "UNMASKED STRINGS")
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

end   # class TestMaskedString



class TC_MaskedString < Test::Unit::TestCase

  def setup
    @masktests = []
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [],
                      "UUUUUUUUUU",
                      "0123456789" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..9) ],
                      "0123456789",
                      "MMMMMMMMMM" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1..3), (6..8) ],
                      "U123UU678U",
                      "0MMM45MMM9" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1..3), (4..8) ],
                      "U12345678U",
                      "0MMMMMMMM9" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (3..5) ],
                      "01U345UUUU",
                      "MM2MMM6789" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (3...6) ],
                      "01U345UUUU",
                      "MM2MMM6789" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1...4), (4...9) ],
                      "U12345678U",
                      "0MMMMMMMM9" )
#$$$here...  add tests to ensure that execeptions are raised when expected
  end

  def test_masks
    @masktests.each do |masktest|
      assert(masktest.mask_unmask_correct?, masktest.errorMsg)
    end
  end

  def teardown
  end

end  # class TC_MaskedString

