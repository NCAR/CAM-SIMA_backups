#!/usr/bin/env ruby

require 'test/unit'
require 'maskedString'
    

class TestMaskedString

  attr_reader :errorMsg

  def initialize(in_str, in_mask, outstr_mask_OK, outstr_unmask_OK, 
                 gsubPattern, gsubReplace, gsubOut_OK, gsubOutunmask_OK, 
                 changedOK, gsubAppendUnmask_OK)
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
    @gsubappendunmask_OK = gsubAppendUnmask_OK
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
    resultOK?(@gsubout_OK, gsubout, 
              "gsub!(#{@gsubpattern},#{@gsubreplace})")
  end

  def gsub_changed_correct?
    self.gsub_init
    resultOK?(@changed_OK, @changed, 
              "changed = gsub!(#{@gsubpattern},#{@gsubreplace})")
  end

  def gsub_unmask_correct?
    self.gsub_init
    gsuboutunmask = @ms.get_unmasked
#print "DEBUG: gsuboutunmask = <<#{gsuboutunmask}>>\n"
    resultOK?(@gsuboutunmask_OK, gsuboutunmask, 
              "unmask gsub!(#{@gsubpattern},#{@gsubreplace})")
  end

  def gsub_appendunmask_correct?
    #here...  get rid of duplication!
    @ms = MaskedString.new(@instr, @inmask)
    sub = @ms.deepCopy
#    sub = MaskedString.new(@instr, @inmask)
    sub.each_unmasked do |str|
      str.gsub!(@gsubpattern,@gsubreplace)
    end
#print "DEBUG:  @ms.get_unmasked =  <<#{@ms.get_unmasked}>>\n"
#print "DEBUG:  sub.get_unmasked =  <<#{sub.get_unmasked}>>\n"
    @ms << sub
#print "DEBUG:  returned from @ms << sub ...\n"
    @errorMsg = ""
    resultOK?(@gsubappendunmask_OK, @ms.get_unmasked, 
              "append self << self.each_unmasked { gsub ... }")
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



class TestMaskedStringModifyAll

  attr_reader :errorMsg

  def initialize(in_str, in_mask, gsubPattern, gsubReplace, gsubOut_OK, changedOK)
    @instr = in_str
    @inmask = in_mask
    @gsubpattern = gsubPattern
    @gsubreplace = gsubReplace
    @gsubout_OK = gsubOut_OK
    @changed_OK = changedOK
    @changed = nil
    @ms = nil
  end

  def gsub_all_init
    @ms = MaskedString.new(@instr, @inmask)
#print "DEBUG: @ms.baseString = <<#{@ms.baseString}>>\n"
    @changed = @ms.modify_all do |str|
      str.gsub!(@gsubpattern,@gsubreplace)
    end
    @errorMsg = ""
  end

  def gsub_correct?
    self.gsub_all_init
    gsubout = @ms.baseString
#print "DEBUG: gsubout = <<#{gsubout}>>\n"
    resultOK?(@gsubout_OK, gsubout, 
              "gsub!(#{@gsubpattern},#{@gsubreplace})")
  end

  def gsub_changed_correct?
    self.gsub_all_init
    resultOK?(@changed_OK, @changed, 
              "changed = gsub!(#{@gsubpattern},#{@gsubreplace})")
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

end   # class TestMaskedStringModifyAll



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
                      true,
                      "0123456789ABC3456789" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..9) ],
                      "0123456789",
                      "MMMMMMMMMM",
                      /012/, "ABC", 
                      "0123456789",
                      "MMMMMMMMMM",
                      false,
                      "MMMMMMMMMMMMMMMMMMMM" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1..3), (6..8) ],
                      "U123UU678U",
                      "0MMM45MMM9",
                      /012/, "ABC", 
                      "0123456789",
                      "0MMM45MMM9",
                      false,
                      "0MMM45MMM90MMM45MMM9" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1..3), (4..8) ],
                      "U12345678U",
                      "0MMMMMMMM9",
                      /456/, "EFGhijk", 
                      "0123456789",
                      "0MMMMMMMM9",
                      false,
                      "0MMMMMMMM90MMMMMMMM9" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (3..5) ],
                      "01U345UUUU",
                      "MM2MMM6789",
                      /67/, "GHijklmn", 
                      "012345GHijklmn89",
                      "MM2MMMGHijklmn89",
                      true,
                      "MM2MMM6789MM2MMMGHijklmn89" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (3...6) ],
                      "01U345UUUU",
                      "MM2MMM6789",
                      /78/, "", 
                      "01234569",
                      "MM2MMM69",
                      true,
                      "MM2MMM6789MM2MMM69" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (1...4), (4...9) ],
                      "U12345678U",
                      "0MMMMMMMM9",
                      /\d/, "d", 
                      "d12345678d",
                      "dMMMMMMMMd",
                      true,
                      "0MMMMMMMM9dMMMMMMMMd" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (4..7) ],
                      "01UU4567UU",
                      "MM23MMMM89",
                      /23/, "blahblah", 
                      "01blahblah456789",
                      "MMblahblahMMMM89",
                      true,
                      "MM23MMMM89MMblahblahMMMM89" )
    @masktests << TestMaskedString.new(
                      "0123456789", 
                      [ (0..1), (4..7) ],
                      "01UU4567UU",
                      "MM23MMMM89",
                      /\d/, "", 
                      "014567",
                      "MMMMMM",
                      true,
                      "MM23MMMM89MMMMMM" )
    @masktests << TestMaskedString.new(
                      "", 
                      [],
                      "",
                      "",
                      /\d/, "", 
                      "",
                      "",
                      false,
                      "" )
#$$$here...  add tests to ensure that execeptions are raised when expected

#TestMaskedStringModifyAll.new(in_str, in_mask, gsubPattern, gsubReplace, gsubOut_OK, changedOK)
    @maskmodifyalltests = []
    @maskmodifyalltests << TestMaskedStringModifyAll.new(
                             "0123456789", 
                             [ (0..1), (4..7) ],
                             /\d/, "D", 
                             "01DD4567DD",
                             true )
    @maskmodifyalltests << TestMaskedStringModifyAll.new(
                             "0123456789", 
                             [ (2..3), (5..7) ],
                             /\d/, "D", 
                             "DD23D567DD",
                             true )
    @maskmodifyalltests << TestMaskedStringModifyAll.new(
                             "0123456789", 
                             [ (2..3), (5..7), (9..9) ],
                             /\d/, "D", 
                             "DD23D567D9",
                             true )
    @maskmodifyalltests << TestMaskedStringModifyAll.new(
                             "", 
                             [],
                             /\d/, "D", 
                             "",
                             false )
    # really want to use ms.mask_char instead of explicit "@"
    @maskmodifyalltests << TestMaskedStringModifyAll.new(
                             "\n", 
                             [ (0..0) ],
                             /[^@]/, "X", 
                             "\n",
                             false )
    # NOTE use of single quotes to make '\1' work!  
    @maskmodifyalltests << TestMaskedStringModifyAll.new(
                             "0123456789", 
                             [ (3..5) ],
                             /12(@*)67/, 'ab\1cd', 
                             "0ab345cd89",
                             true )

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
    @maskmodifyalltests.each do |maskmodifyalltest|
      assert(maskmodifyalltest.gsub_correct?, maskmodifyalltest.errorMsg)
    end
  end

  def test_gsub_changed
    @masktests.each do |masktest|
      assert(masktest.gsub_changed_correct?, masktest.errorMsg)
    end
    @maskmodifyalltests.each do |maskmodifyalltest|
      assert(maskmodifyalltest.gsub_changed_correct?, maskmodifyalltest.errorMsg)
    end
  end

  def test_gsub_unmask
    @masktests.each do |masktest|
      assert(masktest.gsub_unmask_correct?, masktest.errorMsg)
    end
  end

  def test_gsub_appendunmask
    @masktests.each do |masktest|
      assert(masktest.gsub_appendunmask_correct?, masktest.errorMsg)
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


