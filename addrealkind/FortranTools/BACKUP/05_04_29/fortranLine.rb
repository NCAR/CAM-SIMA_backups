#!/usr/bin/env ruby

#==============================================================================
# Author:            Tom Henderson
# Acknowledgements:  
# Organization:      NCAR MMM
#
# Assumptions:  
#   Source code is in Fortran90/95 free form.  
#   Source code compiles.  
#
#
# History:  
#
#  Version 0.1  - Initial alpha-test version.  Just handles processing of 
#                 Fortran90 free-form comments and continuations.  
#                 Multiple statements on a single line (";") are not 
#                 supported yet.  
#
#==============================================================================

# TODO:
# - Support multiple statements on a single line (";")

require 'maskedString'


#==============================================================================
# Responsible for:  
#   A single line of raw Fortran source code.  
#   Original line number but NOT file name.  
#   Understanding comments and continuation lines.  
#   Keeping track of parts of the line that contain literal character strings 
#   or comments.  
#   Substitutions within parts of the line that do not contain literal 
#   character strings or constants.  
#==============================================================================
class FortranLine

  attr_reader :stringRegions, :nextStringStart, :lineNumber, 
    :prev_was_contd, :string_delimiter, :orig_string_delimiter, :continued, 
    :commentIndex, :contEndIndex, :contBeginIndex, :maskedLine
  attr_accessor :line

  # FortranLine.new(aString, aFixNum, true/false [, aString])
  #  Standard constructor:
  #    The last aString is an optional delimiter for use when prevwascontd 
  #    is true.  If (prevwascontd==true) and the previous line was in a 
  #    character context when it ended, then the last string is used as the 
  #    character* delimiter.  If the last string is nil or not present, then 
  #    the previous line did not end in a character context.  
  # OR
  # FortranLine.new(<<more than four args>>)
  #    Used by deep copy constructor (Orthodox canonical form)
  def initialize(*args)
    if (args.length <= 4) then
      str          = args.shift
      indx         = args.shift
      prevwascontd = args.shift
      # Default contructor
      # original line
      # @origLine = str
      # original line with any "\n" removed
      @line = str.chomp
      # line number
      @lineNumber = indx
      # was the previous line continued?
      @prev_was_contd = prevwascontd
      # string delimiter for a line that begins or ends in a character context.
      # If the previous line was continued and a string delimiter is present 
      # and not nil, then the previous line was a continued string.
      @string_delimiter = nil
      if (@prev_was_contd and (not args.empty?)) then
        @string_delimiter = args.shift
        unless (@string_delimiter.nil?) then
          unless ( ( @string_delimiter == "'"  ) or 
                   ( @string_delimiter == "\"" ) ) then
            raise "ERROR:  Attempted to used string delimiter <#{@string_delimiter}>.  String delimiter must either be <'> or <\">.\n"
          end
        end
      end
      @orig_string_delimiter = @string_delimiter
      self.init_finish
    else
      # for deep copy contructor
#$$$ replace this mess with a Hash!  
      @stringRegions         = args[0]
      @nextStringStart       = args[1]
      @line                  = args[2]
      @lineNumber            = args[3]
      @prev_was_contd        = args[4]
      @string_delimiter      = args[5]
      @orig_string_delimiter = args[6]
      @continued             = args[7]
      @commentIndex          = args[8]
      @contEndIndex          = args[9]
      @contBeginIndex        = args[10]
      @maskedLine            = args[11]
    end
  end

  # shared initialization bits
  def init_finish
    # This array tracks substrings that are literal character strings:  
    @stringRegions = []
    @nextStringStart = nil
    # is this line continued?  
    @continued = false
    # index of first comment
    @commentIndex = nil
    # index of trailing "&" continuation character
    @contEndIndex = nil
    # index of leading "&" continuation character
    @contBeginIndex = nil
    self.find_comment_continuation
    @maskedLine = MaskedString.new(@line, self.get_char_comment_ranges)
  end

  # deep copy constructor (Orthodox canonical form)
  def deepCopy
    copy_stringRegions = []
    @stringRegions.each { |rang| copy_stringRegions << rang }
    copy_nextStringStart = @nextStringStart
    copy_line = "" << @line
    copy_lineNumber = @lineNumber
    copy_prev_was_contd = @prev_was_contd
    copy_string_delimiter = nil
    if (@string_delimiter) then
      copy_string_delimiter = "" << @string_delimiter
    end
    copy_orig_string_delimiter = nil
    if (@orig_string_delimiter) then
      copy_orig_string_delimiter = "" << @orig_string_delimiter
    end
    copy_continued = @continued
    copy_commentIndex = @commentIndex
    copy_contEndIndex = @contEndIndex
    copy_contBeginIndex = @contBeginIndex
    copy_maskedLine = @maskedLine.deepCopy
#$$$ replace this mess with a Hash!  
    ret = FortranLine.new(copy_stringRegions, copy_nextStringStart, 
                          copy_line, copy_lineNumber, copy_prev_was_contd, 
                          copy_string_delimiter, copy_orig_string_delimiter, 
                          copy_continued, copy_commentIndex, copy_contEndIndex, 
                          copy_contBeginIndex, copy_maskedLine)
  end

  # equivalence operator (Orthodox canonical form)
  def ==(other)
    ret0 = true
    @stringRegions.each_with_index do |sreg,indx|
      unless (sreg == other.stringRegions[indx]) then
        ret0 = false
      end
    end
#$$$ put this mess in an Array
    ret1 = (@nextStringStart       == other.nextStringStart)
    ret2 = (@line                  == other.line)
    ret3 = (@lineNumber            == other.lineNumber)
    ret4 = (@prev_was_contd        == other.prev_was_contd)
    ret5 = (@string_delimiter      == other.string_delimiter)
    ret6 = (@orig_string_delimiter == other.orig_string_delimiter)
    ret7 = (@continued             == other.continued)
    ret8 = (@commentIndex          == other.commentIndex)
    ret9 = (@contEndIndex          == other.contEndIndex)
    ret10 = (@contBeginIndex       == other.contBeginIndex)
    ret11 = (@maskedLine           == other.maskedLine)
    ret = (ret0 and ret1 and ret2 and ret3 and ret4  and ret5 and 
           ret6 and ret7 and ret8 and ret9 and ret10 and ret11)
  end

  # Returns @line with all comments, trailing whitespace, and continuation 
  # characters removed.  When appropriate, leading whitespace may also be 
  # removed.  Note that white space that comes before the trailing "&" in 
  # a line that is continued in a character context will not be removed.  
  # Note that a leading '&' following a continued line overrides 
  # character context per Fortran90 standard (i.e. character context does 
  # not begin until after the leading '&').  
  def line_stripped
    endIndex = @line.length - 1
    if @commentIndex then
      endIndex = [endIndex, @commentIndex - 1].min
    end
    if @contEndIndex then
      endIndex = [endIndex, @contEndIndex - 1].min
    end
    startIndex = 0
    if @contBeginIndex then
      startIndex = @contBeginIndex + 1
    end
    if (startIndex <= endIndex) then
      str = @line[startIndex..endIndex]
      ret = str
      # strip off any trailing white space if this line is not continued 
      # in a character context
      if (@string_delimiter.nil?) then
        ret = str.strip
        # if there is any non-white space left...  
        if (ret.length > 0) then
          # restore any leading whitespace removed by String::strip
          if (str =~ /^\s+/) then
            ret = str.slice(/^\s+/) + ret
          end
        end
      end
    else
      ret = ""
    end
    ret
  end

  # returns @line with any comments and trailing whitespace removed
  def strip_comment
    if (@line.length == 0) then
      ret = ""
    else
      if @commentIndex then
        # remove comments
        if (@commentIndex == 0) then
          str = ""
        else
          str = @line[0..(@commentIndex-1)]
        end
      else
        str = @line
      end
      # strip off any trailing white space
      ret = str.strip
      # restore any leading whitespace removed by String::strip
      if (str =~ /^\s+/) then
        ret = str.slice(/^\s+/) + ret
      end
    end
    ret
  end

  # find comment and/or continuation character(s)
  def find_comment_continuation
    self.find_leading_continuation
    self.find_comment
    self.find_trailing_continuation
    self.comment_line
    if (@nextStringStart) then
      raise "ASSERTION ERROR:  invalid state for @nextStringStart at end of find_comment_continuation()\n"
    end
  end

  # find index of comment, if present
  # free format
  def find_comment
    # if line begins in character context...
    if (@string_delimiter) then
      unless (@line.length==0) then
        if (@contBeginIndex) then
          unless (@contBeginIndex >= (@line.length - 1)) then
            @nextStringStart = @contBeginIndex + 1
          end
        else
          @nextStringStart = 0
        end
      end
    end
    # find first "!" not inside ''
    loc = 0
    @line.each_byte do |c|
      s = "" << c
      if (s == "!") then
        if (@string_delimiter.nil?) then
          @commentIndex = loc
          break
        end
      elsif ((s == "'") or (s == "\"")) then
        # NOTE:  This logic works with "" and '', but not due to clever 
        #        design...  
        if (@string_delimiter.nil?) then   # if not in a character context...
          @string_delimiter = s              # start of string, set delimiter
          if (@nextStringStart) then
            raise "ASSERTION ERROR:  invalid state for @nextStringStart\n"
          else
            @nextStringStart = loc
          end
        else                               # if in a character context...
          if (s == @string_delimiter) then   # if at end of string
            @string_delimiter = nil          # clear string delimiter
            if (@nextStringStart) then     # store character context Range
              @stringRegions << (@nextStringStart..loc)
              @nextStringStart = nil
            else
              raise "ASSERTION ERROR:  invalid state for @nextStringStart\n"
            end
          end
        end
      end
      loc = loc + 1
    end
    # Note:  Terminate any remaining character context Range after finding 
    #        continuation character.  Do this in find_trailing_continuation()
  end

  # find index of trailing continuation, if present
  # free format
  def find_trailing_continuation
    s = self.strip_comment
    @continued = (s[s.length-1,1] == "&")
    if (self.is_continued?) then
      @contEndIndex = s.rindex("&") 
      if (@nextStringStart) then    # character context ends before "&"
        # if we cannot make a valid Range then skip this one
        # some valid odd cases like '  &&' can cause this
        if (@contEndIndex > @nextStringStart) then
          @stringRegions << (@nextStringStart..(@contEndIndex-1))
        end
        @nextStringStart = nil
      end
    end
  end

  # find index of leading continuation, if present
  # free format
  # Note that a leading '&' following a continued line overrides 
  # character context per Fortran90 standard.  
  def find_leading_continuation
    if (@prev_was_contd) then
      if (@line =~ /^\s+&/) then
        @contBeginIndex = @line.index("&") 
      end
    end
  end

  # if this is a comment line, then retain "continued" state from 
  # previous line
  def comment_line
    if (self.line_stripped.length == 0) then
      @continued = @prev_was_contd
      # ... and empty character contexts
      @stringRegions = []
      @nextStringStart = nil
    end
  end

  # returns all Ranges of substrings in character context or following 
  # the '&' continuation character (including the '&') or following 
  # a comment OR preceeding a leading '&' on a continued line.  
  # If a line ends with a continuation '&' followed by a 
  # comment, the last Range will be from the '&' to the end, inclusive.  
  def get_char_comment_ranges
    ret = []
    # leading '&'
    if (@contBeginIndex) then
      ret << (0..@contBeginIndex)
    end
    # character contexts
    @stringRegions.each do |reg|
      ret << reg
    end
    # ending '&' or '!'
    if (@contEndIndex) then  # mask off ending '&'
      ret << (@contEndIndex..(@line.length - 1))
    elsif (@commentIndex) then   # only use this if no ending '&'
      ret << (@commentIndex..(@line.length - 1))
    end
    ret
  end

  # get masked line
  def get_unmasked
    @maskedLine.get_unmasked
  end

  # get unmasked line
  def get_masked
    @maskedLine.get_masked
  end

  # free-format
  def is_continued?
    @continued
  end

  def prev_was_contd?
    @prev_was_contd
  end

  # free-format
  def contd_string_delimiter
    @string_delimiter
  end

  def to_s
    s = "#{@lineNumber}:  #{@line}"
  end

end  # class FortranLine

