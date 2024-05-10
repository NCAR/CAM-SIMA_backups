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
require 'argumentParser'



#==============================================================================
# Responsible for:  
#   Reading a file containing Fortran source code and converting it into 
#   an array of FortranLine.  
#   Passing elements of the FortranLine array to other objects.  
#   Original file name.  
#   Objects of this class are designed to be disposable.  They should be 
#   discarded after all of the elements of the FortranLine array have been 
#   extracted.  
#==============================================================================
class FortranLineReader

  attr_reader :fileName

  # FortranLineReader.new(aString)
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

  def shift
    @lines.shift
  end

  def empty?
    @lines.empty?
  end

  def to_s
    @lines.join("\n")
  end

end  # class FortranLineReader



#==============================================================================
# Responsible for:  
#   A single Fortran statement.  
#   Building a Fortran statement from one or more FortranLine(s).  
#   Classification of the Fortran statement.  
#   Translations of the Fortran source line(s) that were used to build the 
#   Fortran statement.  
#   Substitutions within parts of the Fortran Source line(s) that do not 
#   contain literal character strings or constants.
#   Enough understanding of Fortran syntax to make required substitutions 
#   correctly.  
#
#   LIMITATION:  
#   Only support free-format Fortran source code for now...  
#==============================================================================
class FortranStatement

  attr_reader :statement, :firstLineNumber

  # FortranStatement.new(aFortranLineReader)
  def initialize(lines)
    @myLines = []               # anArray of aFortranLine
    @firstLineNumber = nil      # line number of first FortranLine
    @statement = ""             # aString
#$$$ eventually compute @statement on-the-fly from @collapsed
    @collapsed = get_statement(lines)  # aMaskedString
#$$$here...  may need to separate masked character literals from masked "&" and comments!
  end

  # get_statement(aFortranLineReader)
  # returns MaskedString concatenated from the MaskedStrings in each FortranLine
#$$$here...  why not just leave the "\n"s in to begin with and avoid all this crap?  
  def get_statement(lines)
    ret = MaskedString.new("",[])          # empty MaskedString
    cr = MaskedString.new("\n",[(0..0)])   # masked "\n"
    done = false
    # collect the FortranLine and continuation line(s) (if any) and remove 
    # comments and continuation characters
    until (done) do
      thisLine = lines.shift
      if (@firstLineNumber.nil?) then
        @firstLineNumber = thisLine.lineNumber
      end
      @myLines << thisLine
      stripped = thisLine.line_stripped
      @statement << stripped
      ret << thisLine.maskedLine
      ret << cr
      unless (thisLine.is_continued?) then
        done = true
      end
    end
    ret
  end

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

  # is this a the beginning of a module?
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

  # is this a subroutine call?
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

  # Returns a String with Fortran REAL declarations and literal 
  # constants replaced by declarations and literal constants that have 
  # kind specified by String argument realKind.  Kinds are only added if 
  # they are not already present.  Also, REAL and COMPLEX casts via intrinsic 
  # functions REAL and CMPLX are also modified to add if it is not already 
  # present.  
  # The returned String may contain one or more "\n".  
  # Skip lines that contain FORMAT statements.  
  def addRealKind(realKind)
    retall = nil
    unless (self.is_format?) then
      newcollapsed = @collapsed.deepCopy
      newcollapsed.modify_all do |str|
        # hide "dot" operators
        str.gsub!(/\.(eq|ne|lt|le|gt|ge|and|or|eqv|neqv|not)\./i) do
          match = $1.dup
          ret = "{{DOT}}#{match}{{DOT}}"
        end
        # Handle REAL and COMPLEX casts via intrinsic functions
        translate_casts!(realKind, str)
        # Handle REAL and COMPLEX declarations
        # Skip substitution if line already contains "real (" as this is
        # either an existing kind that should not be modified or it is a
        # call to an intrinsic function.
        str.gsub!(/REAL|COMPLEX/i) do
          match = $&.dup
          pre_match = $`.dup
          post_match = $'.dup
          ret = match
          add_kind = true
          # do not modify selected_real_kind
          if ( pre_match =~ /selected_$/i ) then
            add_kind = false
          end
          # do not modify declaration with existing kind
          if ( post_match =~ /^\s*\(/ ) then
            add_kind = false
          end
          if (add_kind) then
            ret = "#{match}(#{realKind})"
          end
          ret
        end
        # handle REAL and COMPLEX literal constants
        # three basic forms:  1.[0][e-5], [0].1[e+5], 1e2
        str.gsub!(/(((\d+\.\d*)|(\d*\.\d+))(((e|d)(-|\+*)(\d+))|\d*))|(\d+(e|d)(-|\+*)\d+)/i) do
          match = $&.dup
          pre_match = $`.dup
          post_match = $'.dup
          ret = match
          add_kind = true
          # only add kind if it is not already present
          if ( post_match =~ /^_/ ) then
            add_kind = false
          end
          # leave 1.0d0 alone -- it is always double-precision
          if ( ret =~ /d\d+$/i ) then
            add_kind = false
          end
          # do not modify names (like a3e4bz)
          if ( pre_match =~ /[[:alpha:]]+$/ ) then
            add_kind = false
          end
          if (add_kind) then
            ret = "#{match}_#{realKind}"
          end
          ret
        end
        # restore "dot" operators
        str.gsub!(/\{\{DOT\}\}(eq|ne|lt|le|gt|ge|and|or|eqv|neqv|not)\{\{DOT\}\}/i) do
          match = $1.dup
          ret = ".#{match}."
        end
      end
      retall = newcollapsed.baseString
    else
      retall = @collapsed.baseString
    end
    retall
  end

  # Find indices for insertion of new kind parameter in REAL and COMPLEX 
  # casts via intrinsic functions.  Does not modify str.  
  #
  # Flag startofline is used for recursion to avoid confusing 
  # substrings with declarations.  It is set to true at the top-level 
  # call and false otherwise.  
  # find_cast_insertion(aString, true|false)
  # returns array of sorted indices or empty array
  #
  # recursive
  #
  def find_cast_insertion(str, startofline)
    ret = []
    offset = 0
    while (possible_cast = str.index(/(REAL|CMPLX)(\s*)\(/, offset))
      pre_match = $`.dup
      args = ArgumentParser.new(str, possible_cast)
      add_kind_ok = true
      # do not modify type declarations
      unless ((startofline) and (pre_match =~ /^\s*\d*\s*$/)) then
        # single argument is a cast that does not already have an explicit kind
        if (args.num_args == 1) then
          ret << args.close_parens_index
        end
      end
      arg_str = args.get_arg_str
      arg_str_offset = args.open_parens_index + 1
      # recurse
#$$$here...  put limit on recursion depth?  
      # rescue ArgumentParserExceptions from recursive calls, correct offset, 
      # and re-raise
      begin
        argIndices = find_cast_insertion(arg_str, false)
      rescue ArgumentParserException => failure
        failure.str_offset = failure.str_offset + arg_str_offset
        raise
      end
      argIndices.collect! { |indx| indx = indx + arg_str_offset }
      ret = ret + argIndices
      offset = args.close_parens_index + 1
    end
    ret.sort
  end

  # Handle REAL and COMPLEX casts via intrinsic functions
  # New kind is realKind.  String to modify (in place) is str.  
  # translate_casts!(aString, aString)
  def translate_casts!(realKind, str)
    # first, find all insertion points for new realKind, if any
    begin
      insertIndices = find_cast_insertion(str, true)
    rescue ArgumentParserException => failure
      print "ERROR parsing string <<#{str}>> at offset #{failure.str_offset}\n"
      raise
    end
    # insert backwards to avoid changing insertion indices on-the-fly
    insertIndices.reverse_each { |indx| str.insert(indx,",#{realKind}") }
  end

  # returns array of Strings showing unmasked regions for testing
  def unmask
    ret = []
    @myLines.each do |myline|
      ret << myline.get_unmasked
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
    tmpFortranLineReader = FortranLineReader.new(@fileName)
    until (tmpFortranLineReader.empty?) do
      @statements << FortranStatement.new(tmpFortranLineReader)
    end
  end

  # Returns array of Strings with Fortran REAL declarations and literal 
  # constants replaced by declarations and literal constants that have 
  # kind specified by String argument realKind.  
  def addRealKind(realKind)
    ret = []
    @statements.each do |statement|
      begin
        ret << statement.addRealKind(realKind)
      rescue
        print "ERROR translating file #{@fileName} at line #{statement.firstLineNumber}\n"
        raise
      end
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


# simple tests
#infname = "continuation_test/tst_fp.F90"
#okfname = "continuation_test/tst_fp_fp_OK.F90"
#fpfname = "tst_fp_fp.F90"
#statements = FortranStatements.new(infname)
#File.open(fpfname, "w") do |aFile|
#  aFile.puts(statements.addRealKind("fp"))
#end   # File.open
#`xxdiff #{okfname} #{fpfname}`

##OK
## str = "x = REAL(blahd)"
## str = "x = REAL(blahd + REAL(blahd2))"
#print "#{str}\n"
#print "012345678901234567890123456789012345678901234567890123456789\n"
#indices = FortranStatement.find_cast_insertion(str, true)
#indices.each { |indx| print"#{indx}\n" }
#print "\n"


# more simple tests
#infname = "test.F"
#okfname = "test_fp_OK.F"
#fpfname = "test_fp.F90"
#statements = FortranStatements.new(infname)
#File.open(fpfname, "w") do |aFile|
#  aFile.puts(statements.addRealKind("fp"))
#end   # File.open
#`xxdiff #{okfname} #{fpfname}`

