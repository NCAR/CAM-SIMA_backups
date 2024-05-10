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
  # There has GOT to be a better way!  
  def lastIncluded
    ret = nil  # for bad Ranges
    self.each { |obj| ret = obj }
    ret
  end

end   # class Range



#==============================================================================
# Responsible for:  
#   Range of a masked or unmasked region.  
#   Knowing if the region is masked or not.  
#==============================================================================
class MaskUnmaskRange

  attr_accessor :range

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

  # spaceship operator for sorting
  def <=>(other)
    self.range.begin <=> other.range.begin
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
#==============================================================================
class MaskedString

  # MaskedString.new(aString, aArray of aRange)
  # The second argument (maskinfo) is an array of Range objects
  # Each Range defines a substring that will be ignored during any string 
  # operations.  
  # It is OK for the maskinfo to be empty.  
  def initialize(str, maskinfo)
    @baseString = str
    # find masked and unmasked Range's
    @maskUnmask = self.get_mask_unmask(maskinfo)
  end

  # Returns an Array containing MaskUnmaskRange's for all unmasked substrings
  # Raises an exception iff any of the masked regions do not specify valid 
  # substrings of @baseString or iff any masked regions overlap.  Range's 
  # must be in ascending order and must not overlap.  
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

  # return @baseString with gsub executed on each unmasked substring
  # operations on each unmasked substring are done in isolation 
#$$$ can this be done in an operator-independent way to avoid duplication?  Yes
#$$$ how to handle block_given?() ?
  def gsub(*args)
    # String copy constructor
    ret = ""
    @maskUnmask.each do |murang|
      rang = murang.range
      if (murang.unmasked?) then
        substr = @baseString[rang]
        newstr = substr.gsub(*args)
        ret << newstr
      else
        ret << @baseString[rang]
      end
    end
    ret
  end

  # return @baseString with "U" in unmasked region for debugging
  def get_masked
    # String copy constructor
    ret = "" << @baseString
    # $$$ refactor to remove duplication
    @maskUnmask.each do |murang|
      if (murang.unmasked?) then
        rang = murang.range
        rang.each do |indx|
          ret[indx..indx] = "U"
        end
      end
    end
#    print "MASKED REGIONS:  <<#{ret}>>\n"
    ret
  end

  # return @baseString with "M" in masked region for debugging
  def get_unmasked
    # String copy constructor
    ret = "" << @baseString
    # $$$ refactor to remove duplication
    @maskUnmask.each do |murang|
      if (murang.masked?) then
        rang = murang.range
        rang.each do |indx|
          ret[indx..indx] = "M"
        end
      end
    end
#    print "UNMASKED REGIONS:  <<#{ret}>>\n"
    ret
  end

  def to_s
    @baseString
  end

end  # class MaskedString


