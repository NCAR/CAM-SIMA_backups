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

end



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
    @mask = maskinfo
    # find Range's for unmasked substrings
    @unmask = self.get_unmask
  end

  # Returns an Array containing Range's for all unmasked substrings
  # Raises an exception iff any of the masked regions do not specify valid 
  # substrings of @baseString or iff any masked regions overlap.  Range's 
  # must be in ascending order and must not overlap.  
  def get_unmask
    ret = []  # store Ranges of unmasked substrings here
    startIndex = 0
    endIndex = @baseString.length - 1
    lastmaskEnd = -1
    lastunmaskStart = 0
    lastunmaskEnd = 0
    @mask.each do |rang|
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
      # extract Range for unmasked substring prior to this mask if present
      if ( ( maskStart - 1 ) >= (lastmaskEnd + 1) ) then
        ret << ((lastmaskEnd+1)..(maskStart-1))
      end
      # go on to next masked region
      lastmaskEnd = maskEnd
    end
    # extract Range for unmasked substring after all masks, if present
    # this also handles the case where @mask is empty
    if ( lastmaskEnd < endIndex ) then
      ret << ((lastmaskEnd+1)..(endIndex))
    end
    # set return value
    ret
  end

  # return @baseString with "U" in unmasked region for debugging
  def get_masked
    # String copy constructor
    ret = "" << @baseString
    @unmask.each do |rang|
      rang.each do |indx|
        ret[indx..indx] = "U"
      end
    end
#    print "MASKED REGIONS:  <<#{ret}>>\n"
    ret
  end

  # return @baseString with "M" in masked region for debugging
  def get_unmasked
    # String copy constructor
    ret = "" << @baseString
    @mask.each do |rang|
      rang.each do |indx|
        ret[indx..indx] = "M"
      end
    end
#    print "UNMASKED REGIONS:  <<#{ret}>>\n"
    ret
  end

  def to_s
    @baseString
  end

end  # class MaskedString


