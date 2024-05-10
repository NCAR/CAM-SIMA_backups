#!/usr/bin/env ruby

require 'test/unit'
require 'maskedString'
    

class TestMaskedString

  attr_reader :errorMsg

  def initialize(in_str, in_mask, outstr_mask_OK, outstr_unmask_OK, 
                 gsubPattern, gsubReplace, gsubOut_OK)
    @instr = in_str
    @inmask = in_mask
    @outstrmask_OK = outstr_mask_OK
    @outstrunmask_OK = outstr_unmask_OK
    @gsubpattern = gsubPattern
    @gsubreplace = gsubReplace
    @gsubout_OK = gsubOut_OK
  end

  def gsub_correct?
    ms = MaskedString.new(@instr, @inmask)
    @gsubout = ms.gsub(@gsubpattern,@gsubreplace)
    @errorMsg = ""
    resultOK?(@gsubout_OK, @gsubout, "gsub(#{@gsubpattern},#{@gsubreplace})")
  end

  def mask_correct?
    ms = MaskedString.new(@instr, @inmask)
    @outstrmask = ms.get_masked
    @errorMsg = ""
    resultOK?(@outstrmask_OK, @outstrmask, "MASKED STRINGS")
  end

  def unmask_correct?
    ms = MaskedString.new(@instr, @inmask)
    @outstrunmask = ms.get_unmasked
    @errorMsg = ""
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
                      "0123456789",
                      /012/, "ABC", 
                      "ABC3456789" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..9) ],
                      "0123456789",
                      "MMMMMMMMMM",
                      /012/, "ABC", 
                      "0123456789" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1..3), (6..8) ],
                      "U123UU678U",
                      "0MMM45MMM9",
                      /012/, "ABC", 
                      "0123456789" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1..3), (4..8) ],
                      "U12345678U",
                      "0MMMMMMMM9",
                      /456/, "EFGhijk", 
                      "0123456789" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (3..5) ],
                      "01U345UUUU",
                      "MM2MMM6789",
                      /67/, "GHijklmn", 
                      "012345GHijklmn89" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (3...6) ],
                      "01U345UUUU",
                      "MM2MMM6789",
                      /78/, "", 
                      "01234569" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1...4), (4...9) ],
                      "U12345678U",
                      "0MMMMMMMM9",
                      /\d/, "d", 
                      "d12345678d" )
#$$$here...  add tests to ensure that execeptions are raised when expected
  end

  def test_mask
    @masktests.each do |masktest|
      assert(masktest.mask_correct?, masktest.errorMsg)
    end
  end

  def test_unmask
    @masktests.each do |masktest|
      assert(masktest.unmask_correct?, masktest.errorMsg)
    end
  end

  def test_gsub
    @masktests.each do |masktest|
      assert(masktest.gsub_correct?, masktest.errorMsg)
    end
  end

  def teardown
  end

end  # class TC_MaskedString

