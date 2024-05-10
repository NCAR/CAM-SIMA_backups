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

# classes used by this class
require 'fortranLine'
require 'maskedString'



#==============================================================================
# Responsible for:  
#   A raw Fortran source code listing, including possible cpp pre-processing.  
#   Original file name.  
#
#$$$here...  TBH:  Use MaskedString class to implement substitution.  
#$$$here...  TBH:  Determine Ranges to create MaskedString objects based 
#$$$here...  TBH:  upon location of string literal and/or comments.  
#$$$here...  TBH:  Probably need to extract string-literal Ranges from 
#$$$here...  TBH:  FileLine objects...  
#$$$here...  TBH:  Test FortranLine::get_char_comment_ranges
#
#   Text substitutions in source code that may exclude comments and 
#   character literals.   
#==============================================================================
class FortranLines

  attr_reader :fileName

  # FortranLines.new(aString)
  def initialize(*args)
    @fileName = args.shift
    rawLines = IO.readlines(@fileName)
    @lines = []
    prev_was_contd = false
    contd_string_delimiter = nil
    rawLines.each_with_index do |line, indx| 
      newLine = FortranLine.new(line, indx+1, prev_was_contd, 
                                contd_string_delimiter)
      prev_was_contd         = newLine.is_continued?
      contd_string_delimiter = newLine.contd_string_delimiter
      @lines << newLine
    end
  end

  # returns array of Strings showing unmasked regions for testing
  def unmask
    ret = []
    @lines.each do |line|
      ret << line.get_masked_line.get_unmasked
    end
    ret
  end

  #$$$here...  bad design!  replace "shift" with "each" to avoid modifying @lines!
  def shift
    @lines.shift
  end

  def empty?
    @lines.empty?
  end

  def to_s
    @lines.join("\n")
  end

end  # class FortranLines



#==============================================================================
# Responsible for:  
#   A single Fortran statement.  
#
#   LIMITATION:  
#   Only support free-format Fortran source code for now...  
#==============================================================================
class FortranStatement

  attr_reader :statement

  # FortranStatement.new(aFortranLines)
  def initialize(lines)
    @myLines = []
    @statement = ""
    @statement_lc = ""
    @lengths = []
    get_statement(lines)
  end

  # get_statement(aFortranLines)
  def get_statement(lines)
    done = false
    # collect the next raw line and continuation line(s) (if any) and remove 
    # comments and continuation characters
    until (done) do
      #$$$here...  bad design!  replace "shift" with "each" to avoid modifying @lines!
      thisLine = lines.shift
      @myLines << thisLine
      stripped = thisLine.line_stripped
      @statement << stripped
      # keep track of lengths of each line segment
      @lengths << stripped.length
      unless (thisLine.is_continued?) then
        done = true
      end
    end
    @statement_lc = @statement.downcase
  end

#$$$ Change to FortranRawStatements
#$$$ Build new FortranStatements that contains reference to a 
#$$$ FortranRawStatements along with a Range.  Use Composite.  
#$$$ FortranStatements is responsible for understanding Fortran, as much as 
#$$$ we need.  
#$$$ Handle ";" case now.  
#$$$ Brian:  cpp-only targer?  x.F90 -> x_cpp.F90
#$$$ Add test with a source file with a duplicate name that should NOT be 
#$$$ found.  
#$$$ Generate only one call tree per dycore.  This app should NOT understand 
#$$$ cpp stuff -- leave that to the existing experts!  

  # returns a object that inherits from StatementType
#  def get_statement_type
#$$$here...
#  end

#$$$here...  push all of these down into StatementType and its children...
#  def is_declaration?
#$$$here...
#  end

#  def is_executable?
#$$$here...
#  end

  def is_module_begin?
    ret = false
    if (@statement_lc =~ /\s*module/) then
      ret = true
    end
  end

#  def is_subroutine_def?
#$$$here...
#    ret = (@statement_lc =~ /\s*subroutine/)
#  end

  def is_subroutine_call?
    ret = (@statement_lc =~ /\s*call/)
  end

#  def subroutine_called?(subname)
#    if self.is_subroutine_call? then
#$$$here...  
#    end
#  end

  def to_s
    s = "#{@statement}"
  end

end  # class FortranStatement



#==============================================================================
# Responsible for:  
#   Understanding multiple FortranStatement's.  
#   All statements come from the same Fortran source file.  
#==============================================================================
class FortranStatements

  attr_reader :fileName

  # FortranStatements.new(aString)
  def initialize(*args)
    @fileName = args.shift
    @statements = []
    @fortranLines = FortranLines.new(@fileName)
    # make a copy due to consumption of FortranLines by FortranStatement.new
    # $$$ This is a bad design!  Replace the "shift" logic with "each" to 
    # $$$ avoid consumption!!  
    tmpFortranLines = FortranLines.new(@fileName)
    until (tmpFortranLines.empty?) do
      @statements << FortranStatement.new(tmpFortranLines)
    end
  end

  # returns array of Strings showing unmasked regions for testing
  def unmask
    @fortranLines.unmask
  end

  def to_s
    @statements.join("\n")
  end

end  # class FortranStatements


