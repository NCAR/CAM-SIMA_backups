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
#   Text substitutions in source code that excludes comments and 
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

  #$$$here...  bad design!  replace "shift" with "each"??  
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
##    @statement_lc = ""
    @lengths = []
    get_statement(lines)
  end

  # get_statement(aFortranLines)
  def get_statement(lines)
    done = false
    # collect the next raw line and continuation line(s) (if any) and remove 
    # comments and continuation characters
    until (done) do
      #$$$here...  bad design!  replace "shift" with "each"??  
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
##    @statement_lc = @statement.downcase
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
    if (@statement =~ /\s*\d*\s*module/i) then
      ret = true
    end
    ret
  end

  # is this a FORMAT statement?
  def is_format?
    ret = false
    if (@statement =~ /\s*\d*\s*format/i) then
      ret = true
    end
    ret
  end

#  def is_subroutine_def?
#$$$here...
#    ret = (@statement =~ /\s*\d*\s*subroutine/i)
#  end

  def is_subroutine_call?
    ret = false
    if (@statement =~ /\s*\d*\s*call/i) then
      ret = true
    end
    ret
  end

#  def subroutine_called?(subname)
#    if self.is_subroutine_call? then
#$$$here...  
#    end
#  end

  # Returns array of Strings with Fortran REAL declarations and literal 
  # constants replaced by declarations and literal constants that have 
  # kind specified by String argument realKind.  
  # Skip lines that contain FORMAT statements.  
  def addRealKind(realKind)
    ret = []
    skipLine = false
    if (self.is_format?) then
      skipLine = true
    end
    @myLines.each do |myline|
      ret << myline.addRealKind(realKind, skipLine)
    end
    ret
  end

  # returns array of Strings showing unmasked regions for testing
#$$$ change to avoid get_masked_line() to avoid dependence on maskedString!!
  def unmask
    ret = []
    @myLines.each do |myline|
      ret << myline.get_masked_line.get_unmasked
    end
    ret
  end

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
    tmpFortranLines = FortranLines.new(@fileName)
    until (tmpFortranLines.empty?) do
      @statements << FortranStatement.new(tmpFortranLines)
    end
  end

  # Returns array of Strings with Fortran REAL declarations and literal 
  # constants replaced by declarations and literal constants that have 
  # kind specified by String argument realKind.  
  def addRealKind(realKind)
    ret = []
    @statements.each do |statement|
      ret = ret + statement.addRealKind(realKind)
    end
    ret
  end

  # returns array of Strings showing unmasked regions for testing
  def unmask
    ret = []
    @statements.each do |statement|
      ret = ret + statement.unmask
    end
    ret
  end

  def to_s
    @statements.join("\n")
  end

end  # class FortranStatements


