#!/usr/bin/env ruby

require 'test/unit'
require 'maskedString'
    

class TestMaskedString

  attr_reader :errorMsg

  def initialize(in_str, in_mask, outstr_mask_OK, outstr_unmask_OK, 
                 gsubPattern, gsubReplace, gsubOut_OK, gsubOutunmask_OK, 
                 changedOK)
    @instr = in_str
    @inmask = in_mask
    @outstrmask_OK = outstr_mask_OK
    @outstrunmask_OK = outstr_unmask_OK
    @gsubpattern = gsubPattern
    @gsubreplace = gsubReplace
    @gsubout_OK = gsubOut_OK
    @gsuboutunmask_OK = gsubOutunmask_OK
    @changed_OK = changedOK
    @changed = nil
    @ms = nil
  end

  def gsub_init
    @ms = MaskedString.new(@instr, @inmask)
#print "DEBUG: @ms.baseString = <<#{@ms.baseString}>>\n"
    @changed = @ms.each_unmasked do |str|
      str.gsub!(@gsubpattern,@gsubreplace)
    end
    @errorMsg = ""
  end

  def gsub_correct?
    self.gsub_init
    gsubout = @ms.baseString
#print "DEBUG: gsubout = <<#{gsubout}>>\n"
    ret = resultOK?(@gsubout_OK, gsubout, 
                    "gsub!(#{@gsubpattern},#{@gsubreplace})")
  end

  def gsub_changed_correct?
    self.gsub_init
    ret = resultOK?(@changed_OK, @changed, 
                    "changed = gsub!(#{@gsubpattern},#{@gsubreplace})")
  end

  def gsub_unmask_correct?
    self.gsub_init
    gsuboutunmask = @ms.get_unmasked
#print "DEBUG: gsuboutunmask = <<#{gsuboutunmask}>>\n"
    ret = resultOK?(@gsuboutunmask_OK, gsuboutunmask, 
                    "unmask gsub!(#{@gsubpattern},#{@gsubreplace})")
  end

  def mask_correct?
    @ms = MaskedString.new(@instr, @inmask)
    outstrmask = @ms.get_masked
    @errorMsg = ""
    resultOK?(@outstrmask_OK, outstrmask, "MASKED STRINGS")
  end

  def unmask_correct?
    @ms = MaskedString.new(@instr, @inmask)
    outstrunmask = @ms.get_unmasked
    @errorMsg = ""
    resultOK?(@outstrunmask_OK, outstrunmask, "UNMASKED STRINGS")
  end

  def deepCopy_init
    @ms = MaskedString.new(@instr, @inmask)
    @msCopy = @ms.deepCopy
    @errorMsg = ""
  end

  def deepCopy_correct?
    self.deepCopy_init
    ret = resultOK?(@ms, @msCopy, "DEEP COPY")
  end

  def deepCopy_OBJID_correct?
    self.deepCopy_init
    ret = resultOK?(true, @ms.object_id != @msCopy.object_id, "DEEP COPY OBJECT ID")
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
                      "ABC3456789",
                      "ABC3456789",
                      true )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..9) ],
                      "0123456789",
                      "MMMMMMMMMM",
                      /012/, "ABC", 
                      "0123456789",
                      "MMMMMMMMMM",
                      false )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1..3), (6..8) ],
                      "U123UU678U",
                      "0MMM45MMM9",
                      /012/, "ABC", 
                      "0123456789",
                      "0MMM45MMM9",
                      false )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1..3), (4..8) ],
                      "U12345678U",
                      "0MMMMMMMM9",
                      /456/, "EFGhijk", 
                      "0123456789",
                      "0MMMMMMMM9",
                      false )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (3..5) ],
                      "01U345UUUU",
                      "MM2MMM6789",
                      /67/, "GHijklmn", 
                      "012345GHijklmn89",
                      "MM2MMMGHijklmn89",
                      true )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (3...6) ],
                      "01U345UUUU",
                      "MM2MMM6789",
                      /78/, "", 
                      "01234569",
                      "MM2MMM69",
                      true )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1...4), (4...9) ],
                      "U12345678U",
                      "0MMMMMMMM9",
                      /\d/, "d", 
                      "d12345678d",
                      "dMMMMMMMMd",
                      true )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (4..7) ],
                      "01UU4567UU",
                      "MM23MMMM89",
                      /23/, "blahblah", 
                      "01blahblah456789",
                      "MMblahblahMMMM89",
                      true )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (4..7) ],
                      "01UU4567UU",
                      "MM23MMMM89",
                      /\d/, "", 
                      "014567",
                      "MMMMMM",
                      true )
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

  def test_gsub_changed
    @masktests.each do |masktest|
      assert(masktest.gsub_changed_correct?, masktest.errorMsg)
    end
  end

  def test_gsub_unmask
    @masktests.each do |masktest|
      assert(masktest.gsub_unmask_correct?, masktest.errorMsg)
    end
  end

  def test_deepCopy
    @masktests.each do |masktest|
      assert(masktest.deepCopy_correct?, masktest.errorMsg)
    end
  end

  def test_deepCopy_OBJID
    @masktests.each do |masktest|
      assert(masktest.deepCopy_OBJID_correct?, masktest.errorMsg)
    end
  end


  def teardown
  end

end  # class TC_MaskedString


