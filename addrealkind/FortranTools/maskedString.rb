#!/usr/bin/env ruby

#==============================================================================
# Author:            Tom Henderson
# Acknowledgements:  
# Organization:      NCAR MMM
#
# History:  
#
#  Version 0.1  - Initial alpha-test version.  Only "gsub" method.  
#
#==============================================================================


#==============================================================================
# Responsible for:  
#   Simple extension to built-in Class Range that avoids repeated use of 
#   exclude_end?() to extract the last object included in the Range 
#==============================================================================
class Range

  # Returns nil iff Range contains nothing (like (2..1) ).  
  # Handles Ranges defined like (1...2) where Range.last returns "2" 
  # even though "2" is not included.  
  # There has GOT to be a better way!  
  def lastIncluded
    ret = nil  # for bad Ranges
    self.each { |obj| ret = obj }
    ret
  end

  # return number of objects in the Range
  def length
    ret = 0
    self.each { |obj| ret = ret + 1 }
    ret
  end

  # shift range by offset off
  def offset(off)
    rangestart = self.first + off
    rangeend = self.lastIncluded + off
    (rangestart..rangeend)
  end

end   # class Range



#==============================================================================
# Responsible for:  
#   Range of a masked or unmasked region.  
#   Knowing if the region is masked or not.  
#==============================================================================
class MaskUnmaskRange

  include Comparable

  attr_accessor :range
  attr_reader :mask_flag

  # MaskUnmaskRange.new(aRange, [true|false])
  # The first argument is a Range object that defines a substring 
  # that will be masked (ignored) or unmasked.  
  # The second argument is true iff the substring will be masked or false iff 
  # the substring will not be masked.  
  def initialize(srange, maskflag)
    @range = srange
    if (maskflag) then
      @mask_flag = true
    else
      @mask_flag = false
    end
  end

  # deep copy constructor (Orthodox canonical form)
  def deepCopy
    copyRange = @range
    copyMaskFlag = @mask_flag
    ret = MaskUnmaskRange.new(copyRange, copyMaskFlag)
  end

  # spaceship operator for sorting and comparison
  # note that @mask_flag is only used to break ties to get reasonable 
  # behavior from "==" via mixin of Comparable
  def <=>(other)
    ret = self.range.begin <=> other.range.begin
    if ( ret == 0 ) then
      ret = self.range.lastIncluded <=> other.range.lastIncluded
      if ( ret == 0 ) then
        unless (self.mask_flag == other.mask_flag) then
          if (self.mask_flag) then
            ret = 1
          else
            ret = -1
          end
        end
      end
    end
    ret
  end

  def masked?
    @mask_flag
  end

  def unmasked?
    not @mask_flag
  end

  def to_s
    s = ""
    if (self.unmasked?) then
      s = "UN"
    end
    s << "MASKED REGION:  #{@range}"
  end

end   # class MaskUnmaskRange



#==============================================================================
# Responsible for:  
#   A "masked" string and operations on it.  
#   A masked string is formed from a String and a list of Range objects that 
#   define substrings that will be ignored during string operations.  
#   Unmasked substrings will be processed in isolation.  
#$$$ TBH:  May want to support more than one type of "mask"...  
#==============================================================================
class MaskedString

  attr_reader :baseString, :maskUnmask, :mask_char

  # This default value is useful for Fortran source code, where "@" appears 
  # only in comments.  
  # Not yet tested using a character that has special meaning to Regexp!
  @@default_mask_char = "@"

  # MaskedString.new(aString, aArray of aRange)
  #  Standard constructor:  
  #    The second argument (maskinfo) is an array of Range objects
  #    Each Range defines a substring that will be ignored during any string 
  #    operations.  
  #    It is OK for maskinfo to be empty.  
  # OR
  # MaskedString.new(aString, aArray of aMaskUnmaskRange)
  #    Used by deep copy constructor (Orthodox canonical form)
  #    It is NOT OK for maskinfo to be empty unless @baseString 
  #    has zero-length.  
  #
  #  Note that @maskUnmask may only be empty iff @baseString.length==0
  #
  def initialize(str, maskinfo)
    @baseString = str
    @mask_char = @@default_mask_char     # not in "==()" yet...  
    unless (str.class == String) then
      raise "ERROR:  wrong class for 1st argument to MaskedString.new"
    end
    unless (maskinfo.class == Array) then
      raise "ERROR:  wrong class for 2nd argument to MaskedString.new"
    end
    unless (maskinfo.empty?) then
      if (maskinfo.first.class == MaskUnmaskRange) then
        @maskUnmask = []
        maskinfo.each { |mi| @maskUnmask << mi }
      elsif (maskinfo.first.class == Range) then
        # find masked and unmasked Range's
        @maskUnmask = self.get_mask_unmask(maskinfo)
      else
        raise "ERROR:  wrong class for elements of 2nd argument to MaskedString.new"
      end
    else
      # find masked and unmasked Range's (empty maskinfo)
      @maskUnmask = self.get_mask_unmask(maskinfo)
    end
# assertion
    if (@maskUnmask.empty? and (@baseString.length > 0)) then
      raise "ASSERTION ERROR:  @maskUnmask is empty with string length > 0"
    end
# end assertion
  end

  # deep copy constructor (Orthodox canonical form)
  def deepCopy
    copyBaseString = "" << @baseString
    copyMaskinfo = []
    @maskUnmask.each { |murang| copyMaskinfo << murang.deepCopy }
    ret = MaskedString.new(copyBaseString, copyMaskinfo)
  end

  # equivalence operator (Orthodox canonical form)
  def ==(other)
    ret = (@baseString == other.baseString)
    if (@maskUnmask.length != other.maskUnmask.length) then
      ret = false
    else
      @maskUnmask.each_with_index do |murang,indx| 
        unless (murang == other.maskUnmask[indx]) then
          ret = false
        end
      end
    end
    ret
  end

  # appends other to self
  def <<(other)
#print "DEBUG: calling self.<< ... \n"
#print "DEBUG: self = #{self}\n"
#print "DEBUG: other = #{other}\n"
    # if @baseString and other.baseString are both empty do nothing
    # if @baseString is empty and other.baseString is not, just use other
    if ((@baseString.length == 0) and (other.baseString.length > 0)) then
      @baseString = "" << other.baseString
      @maskUnmask = []
      other.maskUnmask.each { |omurang| @maskUnmask << omurang.deepCopy }
    # only append if other does not contain an empty String
    elsif (other.baseString.length > 0) then
      @baseString << other.baseString
      # offset other.maskUnmask and append to @maskUnmask
      # recall that @maskUnmask is never empty unless @baseString.length == 0
      offset = @maskUnmask.last.range.lastIncluded + 1
      first_time = true
      other.maskUnmask.each do |omurang|
        # If the last range in self and the first range in other are both 
        # unmasked, then combine them into one.  
#$$$here...  add a "gsub" unit test that validates this!  
        new_range = omurang.range.offset(offset)
        if (first_time) then
          if (@maskUnmask.last.unmasked? and omurang.unmasked?) then
            rstart = @maskUnmask.pop.range.first
            rend = new_range.lastIncluded
            new_range = (rstart..rend)
          end
          first_time = false
        end
        @maskUnmask << MaskUnmaskRange.new(new_range, omurang.mask_flag)
      end
    end
    self
  end

  # Returns an Array containing MaskUnmaskRange's for all masked and unmasked 
  # substrings.  Raises an exception iff any of the masked regions do not 
  # specify valid substrings of @baseString or iff any masked regions 
  # overlap.  Range's must be in ascending order and must not overlap.  
  def get_mask_unmask(maskinfo)
    ret = []  # store Ranges of masked and unmasked substrings here
    startIndex = 0
    endIndex = @baseString.length - 1
    lastmaskEnd = -1
    lastunmaskStart = 0
    lastunmaskEnd = 0
    maskinfo.each do |rang|
      # validate this mask
      maskStart = rang.first
      maskEnd = rang.lastIncluded
      unless (maskEnd) then
        raise "ERROR:  bad Range used for mask"
      end
      if ( ( maskStart < startIndex ) or 
           ( maskEnd   >   endIndex ) ) then
        raise "ERROR:  mask substring outside of string"
      end
      if ( maskStart <= lastmaskEnd ) then 
        raise "ERROR:  mask substrings must appear in order and may not overlap"
      end
      ret << MaskUnmaskRange.new(rang,true)
      # extract Range for unmasked substring prior to this mask if present
      if ( ( maskStart - 1 ) >= (lastmaskEnd + 1) ) then
        ret << MaskUnmaskRange.new(((lastmaskEnd+1)..(maskStart-1)),false)
      end
      # go on to next masked region
      lastmaskEnd = maskEnd
    end
    # extract Range for unmasked substring after all masks, if present
    # this also handles the case where maskinfo is empty
    if ( lastmaskEnd < endIndex ) then
      ret << MaskUnmaskRange.new(((lastmaskEnd+1)..(endIndex)),false)
    end
    # now sort the masked and unmasked Ranges...  
    ret.sort
  end

  # Performs operations in block on each unmasked substring.  
  # Operations on each unmasked substring are done in isolation.  
  # If block modifies its String argument in-place then @baseString 
  # is also modified in-place.  If changes to @baseString change 
  # substring lengths, then @maskUnmask is modified in a consistent 
  # manner.  If a modified string is removed, then its associated 
  # MaskUnmaskRange is deleted.  
  # Returns true iff self was changed, false otherwise.  
#$$$ pass in masked vs. unmasked flag to implement "each_masked"?  
  def each_unmasked
#print "DEBUG: enter each_unmasked, @baseString = #{@baseString}\n"
    changed = false
    changed_range = false
    newmaskUnmask = []
    offset = 0   # cumulative offset to deal with range changes
    @maskUnmask.each do |murang|
      rang = murang.range.offset(offset)
      maskflag = murang.mask_flag
      if (murang.unmasked?) then
        opstr = @baseString[rang]
#print "DEBUG: opstr = #{opstr}\n"
        yield(opstr)
#print "DEBUG: new opstr = #{opstr}\n"
        # modify string and range if needed
        if (opstr != @baseString[rang]) then
          changed = true
          # change string
          @baseString[rang] = opstr
          # change range
#print "DEBUG: opstr.length = #{opstr.length}\n"
#print "DEBUG: rang.length = #{rang.length}\n"
          thisoffset = opstr.length - rang.length
          if (thisoffset != 0) then
#print "DEBUG: offset = #{offset}\n"
#print "DEBUG: thisoffset = #{thisoffset}\n"
            changed_range = true
            rangestart = rang.first + thisoffset
            rangeend = rangestart + opstr.length - 1
            # discard zero-length ranges
            if (rangeend >= rangestart) then
              newmaskUnmask << 
                MaskUnmaskRange.new((rangestart..rangeend), maskflag)
            end
          else
            # handle changed unmasked substrings with unchanged ranges
            #$$$ optimize later, if needed
            newmaskUnmask << MaskUnmaskRange.new(rang, maskflag)
          end
          offset = offset + thisoffset
#print "DEBUG: new offset = #{offset}\n"
        else
          # handle unchanged unmasked substrings
          #$$$ optimize later, if needed
          newmaskUnmask << MaskUnmaskRange.new(rang, maskflag)
        end
      else
        # handle masked substrings
        #$$$ optimize later, if needed
        newmaskUnmask << MaskUnmaskRange.new(rang, maskflag)
      end
    end
    # if any range changed, use the new ones
    if (changed_range) then
      @maskUnmask = []
      newmaskUnmask.each { |murng| @maskUnmask << murng }
    end
    # optimization:  caller can know if anything changed
    changed
  end

  # Performs operations in block on entire string.  Prior to yield(), 
  # masked bits of @baseString are saved and then masked regions in 
  # base string are replaced with @mask_char.  In this way, operations 
  # that span all unmasked strings may be performed, provided the 
  # operations leave substrings containing @mask_char alone.  In 
  # particular, these substrings must not be re-ordered, their 
  # lengths must be preserved, and new occurrences of @mask_char must not 
  # be added anywhere.  It is OK to concatenate masked substrings via 
  # removal of an unmasked substring.  If changes to @baseString change
  # unmasked substring lengths, then @maskUnmask is modified in a 
  # consistent manner.  If a modified substring is removed, then its 
  # associated MaskUnmaskRange is deleted.  After yield, each masked region 
  # is restored in order replacing the substrings of @mask_char via simple 
  # substitution.  
  # WARNING:  this algorithm will FAIL if there are any occurrences of 
  # @mask_char in unmasked regions of @baseString!  Fortunately, this 
  # condition is easily detected and this method will raise an exception 
  # if it is encountered.  Note that it is OK for @mask_char to be 
  # present in masked regions.  
  # Returns true iff self was changed, false otherwise.  
#$$$ pass in masked vs. unmasked flag to implement "each_masked"?  
#$$$ change to use String.index() and remove some arithmetic
  def modify_all
#print "DEBUG: enter modify_all(), @baseString = <<#{@baseString}>>\n"
    changed = false
    # leave empty string alone
    unless (@maskUnmask.empty?) then
      baseStringSave = "" + @baseString
      # save masked substrings and overwrite with @mask_char
      saveMask = []
      @maskUnmask.each do |murang|
        rang = murang.range
        if (murang.masked?) then
          saveMask << @baseString[rang]
          @baseString[rang] = @mask_char * rang.length
        elsif (@baseString[rang].include?(@mask_char)) then
          # detect condition in which this algorithm will fail and whine
          raise "ERROR:  mask_char <<#{@mask_char}>> found in unmasked substring"
        end
      end
      baseStringMaskSave = "" + @baseString
      yield(@baseString)
#print "DEBUG:  after yield(), @baseString = <<#{@baseString}>>\n"
      # restore masked regions
      if (baseStringMaskSave == @baseString) then
        # if @baseString has not been modified restore it and return
        @baseString = baseStringSave
      else
        # if @baseString has been modified, put masked substrings back in and 
        # recompute ranges
        changed = true
        @maskUnmask = []
        # check each part of @baseString only once to allow @mask_char to be in masked regions
        offset = 0
        saveMask.each do |maskstr|   # ok for saveMask to be empty
#print "DEBUG:  =============================================\n"
#print "DEBUG:  offset = #{offset} , maskstr = <<#{maskstr}>>\n"
          match_str = @mask_char * maskstr.length
#print "DEBUG:  offset = #{match_str} , maskstr = <<#{match_str}>>\n"
#print "DEBUG:  matching #{(offset..(@baseString.length-1))} = <<#{@baseString[(offset..(@baseString.length-1))]}>>\n"
          maskMatch = (@baseString[(offset..(@baseString.length-1))] =~ 
                       /#{match_str}/)
#print "DEBUG:  maskMatch = #{maskMatch}\n"
          if (maskMatch) then
            # if there is a gap between this region and the previous region,
            # then it is unmasked -- add it
            # maskMatch is relative to the current subrange of @baseString
            if (maskMatch > 0) then
              @maskUnmask << MaskUnmaskRange.new((offset..(offset+maskMatch-1)), false)
#print "DEBUG:  appending unmasked range \(#{(offset..(offset+maskMatch-1))}\)\n"
            end
            # restore saved masked substring
            # shift subrange so it is relative to entire @baseString
            maskMatch = maskMatch + offset
#print "DEBUG:  new maskMatch = #{maskMatch}\n"
            newrange = (maskMatch..(maskMatch+maskstr.length-1))
            @baseString[newrange] = maskstr
#print "DEBUG:  new @baseString = #{@baseString}\n"
            # add the masked region
            @maskUnmask << MaskUnmaskRange.new(newrange, true)
#print "DEBUG:  appending masked range \(#{newrange}\)\n"
            # compute new offset
            offset = maskMatch + maskstr.length
#print "DEBUG:  new offset = #{offset}\n"
          else
            raise "ERROR:  could not restore mask substring <<#{maskstr}>>"
          end
        end   # end of saveMask loop
        # if @baseString did not end in a masked region, the remainder must be 
        # unmasked-- add it.  This also handles the case where saveMask is empty
        if (offset < @baseString.length) then
          @maskUnmask << MaskUnmaskRange.new((offset..(@baseString.length-1)), false)
#print "DEBUG:  appending final unmasked range \(#{(offset..(@baseString.length-1))}\)\n"
        end
      end
    end
    # optimization:  caller can know if anything changed
    changed
  end

  # return @baseString with "U" in unmasked region for debugging
  # this is used to test self.each_unmasked
  def get_masked
    # String copy constructor
    ret = "" << @baseString
    # $$$ refactor to remove duplication
    @maskUnmask.each do |murang|
      if (murang.unmasked?) then
        rang = murang.range
        ret[rang] = "U" * rang.length
      end
    end
#    print "MASKED REGIONS:  <<#{ret}>>\n"
    ret
  end

  # return @baseString with @mask_char in masked region
  def get_unmasked
    # String copy constructor
    ret = "" << @baseString
    # $$$ refactor to remove duplication
    @maskUnmask.each do |murang|
#print "DEBUG: murang.class = #{murang.class}\n"
      if (murang.masked?) then
        rang = murang.range
        ret[rang] = @mask_char * rang.length
      end
    end
#    print "UNMASKED REGIONS:  <<#{ret}>>\n"
    ret
  end

  def to_s
    ar = []
    ar << "BASE STRING:  #{@baseString}\n"
    @maskUnmask.each { |murang| ar << "#{murang}" }
    s = ar.join("\n")
    s << "\n"
  end

end  # class MaskedString


#  print "================================================\n"
#  ms = MaskedString.new("a11bc", [1..2])
#  print "ms = <<#{ms}>>\n"
#  ms2 = MaskedString.new("wx22yz", [2..3])
#  print "ms2 = <<#{ms2}>>\n"
#  ms << ms2
#  print "AFTER ms << ms2 :\n"
#  print "ms = <<#{ms}>>\n"
#  print "ms.get_unmasked = <<#{ms.get_unmasked}>>\n"
#  print "================================================\n"
#  ms = MaskedString.new("0123456789", [(0..9)])
#  print "ms = <<#{ms}>>\n"
#  ms2 = MaskedString.new("0123456789", [(0..9)])
#  print "ms2 = <<#{ms2}>>\n"
#  ms << ms2
#  print "AFTER ms << ms2 :\n"
#  print "ms = <<#{ms}>>\n"
#  print "ms.get_unmasked = <<#{ms.get_unmasked}>>\n"
#  print "================================================\n"
#  ms = MaskedString.new("aaa", [])
#  print "ms = <<#{ms}>>\n"
#  ms2 = MaskedString.new("", [])
#  print "ms2 = <<#{ms2}>>\n"
#  ms << ms2
#  print "AFTER ms << ms2 :\n"
#  print "ms = <<#{ms}>>\n"
#  print "ms.get_unmasked = <<#{ms.get_unmasked}>>\n"
#  print "================================================\n"
#  ms = MaskedString.new("", [])
#  print "ms = <<#{ms}>>\n"
#  ms2 = MaskedString.new("aaa", [])
#  print "ms2 = <<#{ms2}>>\n"
#  ms << ms2
#  print "AFTER ms << ms2 :\n"
#  print "ms = <<#{ms}>>\n"
#  print "ms.get_unmasked = <<#{ms.get_unmasked}>>\n"
#  print "================================================\n"
#  ms = MaskedString.new("", [])
#  print "ms = <<#{ms}>>\n"
#  ms2 = MaskedString.new("", [])
#  print "ms2 = <<#{ms2}>>\n"
#  ms << ms2
#  print "AFTER ms << ms2 :\n"
#  print "ms = <<#{ms}>>\n"
#  print "ms.get_unmasked = <<#{ms.get_unmasked}>>\n"


#  print "================================================\n"
#  ms = MaskedString.new("0123456789", [ (0..1), (4..7) ])
#  print "ms = <<#{ms}>>\n"
#  print "ms.get_unmasked = <<#{ms.get_unmasked}>>\n"
#  changed = ms.modify_all do |str|
#    str.gsub!(/\d/,"D")
#  end
#  print "changed = <<#{changed}>>\n"
#  print "ms = <<#{ms}>>\n"
#  print "ms.get_unmasked = <<#{ms.get_unmasked}>>\n"

