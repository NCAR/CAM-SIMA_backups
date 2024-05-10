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

  # FortranLineReader.new(aString [, true|false])
  # first argument is the name of a Fortran source file
  # second (optional) argument is "verbose" flag to print lots of diagnostic 
  # messages
  def initialize(*args)
    @fileName = args.shift
    @verbose = false
    unless (args.empty?) then
      @verbose = args.shift
    end
    rawLines = IO.readlines(@fileName)
    @lines = []
    prev_was_contd = false
    contd_string_delimiter = nil
    rawLines.each_with_index do |line, indx| 
      if (@verbose) then
        print "#{self.class}.new:  parsing line #{indx} = <<#{line}>>\n"
      end
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
  attr_reader :verbose
  attr_accessor :in_module_name
  attr_reader :module_begin, :module_name, :module_end
  attr_reader :subroutine_begin, :subroutine_name, :subroutine_call
  attr_reader :function_begin, :function_type, :function_name
  attr_reader :format

  # FortranStatement.new(aFortranLineReader [, true|false])
  # second (optional) argument is "verbose" flag to print lots of diagnostic 
  # messages
  def initialize(*args)
    lines = args.shift
    @verbose = false
    unless (args.empty?) then
      # sets flag to print lots of diagnostic messages
      @verbose = args.shift
    end
    @myLines = []               # anArray of aFortranLine
    @firstLineNumber = nil      # line number of first FortranLine
    @statement = ""             # aString
#$$$ eventually compute @statement on-the-fly from @collapsed
    @collapsed = get_statement(lines)  # aMaskedString
#$$$here...  may need to separate masked character literals from masked "&" and comments!
    classify                    # what kind of Fortran is this?  
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

  # figure out what kind of Fortran statement this is
  # by looking at this statement only
  # (incomplete!)
  def classify
    @module_begin = false
    @module_end = false
    @module_name = nil
    if (@statement =~ /^\s*\d*\s*module\s+(\w+)\s*/i) then
      # is this the beginning of a module?
      # skip "module procedure xxx" statements
      modname = $1.dup
      unless (modname =~ /^procedure$/i) then
        @module_begin = true
        @module_name = modname
      end
#print "DEBUG:  found begin of module <<#{@module_name}>>\n"
    elsif (@statement =~ /^\s*\d*\s*end\s+module\s+(\w+)\s*$/i) then
      # is this the end of a module?
      @module_end = true
      @module_name = $1.dup
#print "DEBUG:  found end of module <<#{@module_name}>>\n"
    end
    # is this a subroutine definition?
#$$$ here:  need to handle RECURSIVE, PURE, and ELEMENTAL keywords
#$$$ here:  and tie into start-of-line /^/
#    if (@statement =~ /^\s*\d*\s*subroutine\s*(\w+)\s*\(/i) then
    if (@statement =~ /\s*\d*\s*subroutine\s*(\w+)\s*\(/i) then
      @subroutine_begin = true
      @subroutine_name = $1.dup
    else
      @subroutine_begin = false
      @subroutine_name = nil
    end
    # is this a subroutine call?
    if (@statement =~ /\s+call\s+(\w+)\s*\(/i) then
      @subroutine_call = true
      @subroutine_name = $1.dup
    else
      @subroutine_call = false
      @subroutine_name = nil
    end
    # is this a function definition?
#$$$ here:  need to handle return TYPE, RECURSIVE, PURE, and ELEMENTAL keywords
#$$$ here:  and tie into start-of-line /^/
#    if (@statement =~ /^\s*\d*\s*(\w+)\s+function\s*(\w+)\s*\(/i) then
    if (@statement =~ /\s*\d*\s*(\w+)\s+function\s*(\w+)\s*\(/i) then
      @function_begin = true
      @function_type = $1.dup
      @function_name = $2.dup
    else
      @function_begin = false
      @function_type = nil
      @function_name = nil
    end
    # is this a format statement?
    if (@statement =~ /^\s*\d*\s*format/i) then
      @format = true
    else
      @format = false
    end
    # not inside another module until in_module_name is set by parent
    @in_module_name = nil
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

  # findSymbols(aString [, true | false])
  # Find all symbols matching the first argument.  Returns an Array of String.  
  # If second argument is present and true, then only symbols appearing in 
  # PUBLIC statements or whose declarations include the PUBLIC attribute 
  # will be included.  Duplicates are removed.  
  # If symbol is Fortran keyword "operator", then the following pair of 
  # parenthesis are also included in the returned Strings.  
#$$$ first arg should really be a Regexp !!  
  def findSymbols(*args)
    symbol = args.shift
    public = false
    unless (args.empty?) then
      public = args.shift
    end
    retall = []
    if (@verbose) then
      print "#{self.class}.findSymbols:  searching str = <<#{@statement}>>\n"
    end
    @collapsed.each_unmasked do |str|
      if ((not public) or (str =~ /public/i)) then
        if (str =~ /\w*#{symbol}\w*/i) then
          match = $&.dup
          extra = ""
          post_match = $'.dup
          # special behavior if symbol is Fortran keyword "operator"
#$$$ add unit tests!
          if (match =~ /^(assignment|operator)$/i) then
            match = $1.dup
#$$$here...  use my parenthesis matcher!!  
            if (post_match =~ /^\((.+)\)/) then
              extra = "(" + $1.dup + ")"
            end
          end
          retall << match + extra
        end
      end
    end
    retall.sort.uniq
  end

  # addRealKind(realKind [, usemod])
  # Returns a String with Fortran REAL declarations and literal 
  # constants replaced by declarations and literal constants that have 
  # kind specified by String argument realKind.  Kinds are only added if 
  # they are not already present.  Kinds are not added inside a KIND() 
  # intrinsic.  Also, REAL and COMPLEX casts via intrinsic 
  # functions REAL and CMPLX are also modified to add if it is not already 
  # present.  
  # If optional String argument usemod is present, then new USE statements 
  # for module "usemod" will also be added where appropriate.  
  # The returned String may contain one or more "\n".  
  # Skip lines that contain FORMAT statements.  
  def addRealKind(*args)
    realKind = args.shift
    usemod = nil
    unless (args.empty?) then
      usemod = args.shift
    end
    retall = nil
    unless (@format) then
      if (@verbose) then
        print "#{self.class}.addRealKind:  translating str = <<#{@collapsed}>>\n"
      end
      newcollapsed = @collapsed.deepCopy
      newcollapsed.modify_all do |str|
        # hide "dot" operators
        if (@verbose) then
          print "#{self.class}.addRealKind:  hide \"dot\" operators in str = <<#{str}>>\n"
        end
        str.gsub!(/\.(eq|ne|lt|le|gt|ge|and|or|eqv|neqv|not)\./i) do
          match = $1.dup
          ret = "{{DOT}}#{match}{{DOT}}"
        end
        # Handle REAL and COMPLEX casts via intrinsic functions
        if (@verbose) then
          print "#{self.class}.addRealKind:  translate casts in str = <<#{str}>>\n"
        end
        translate_casts!(realKind, str)
        if (@verbose) then
          print "#{self.class}.addRealKind:  translate declarations in str = <<#{str}>>\n"
        end
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
          # declaration must begin a Fortran statement
          if ( pre_match !~ /^\s*\d*\s*$/ ) then
            add_kind = false
          end
          # do not modify declaration with existing kind
          if ( post_match =~ /^\s*(\(|\*)/ ) then
            add_kind = false
          end
          # do not modify block construct name
          if ( post_match =~ /^\s*:\s+/ ) then
            add_kind = false
          end
          # do not modify variable name
          if ( post_match =~ /^\w/ ) then
            add_kind = false
          end
          if (add_kind) then
            ret = "#{match}(#{realKind})"
          end
          ret
        end
        # handle REAL and COMPLEX literal constants
        # three basic forms:  1.[0][e-5], [0].1[e+5], 1e2
        if (@verbose) then
          print "#{self.class}.addRealKind:  translate literal constants in str = <<#{str}>>\n"
        end
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
          # do not modify "kind(1.0)"
          if ( pre_match =~ /kind\s*\(\s*$/i ) then
            add_kind = false
          end
          if (add_kind) then
            ret = "#{match}_#{realKind}"
          end
          ret
        end
        # restore "dot" operators
        if (@verbose) then
          print "#{self.class}.addRealKind:  restore \"dot\" operators in str = <<#{str}>>\n"
        end
        str.gsub!(/\{\{DOT\}\}(eq|ne|lt|le|gt|ge|and|or|eqv|neqv|not)\{\{DOT\}\}/i) do
          match = $1.dup
          ret = ".#{match}."
        end
        # add use statement
        if (usemod) then
#$$$Here...  BUGFIX:  replace \w with  /[A-Za-z0-9_]+/
#$$$Here...  BUGFIX:  replace \W with  /[^A-Za-z0-9_]+/
          usemod =~ /[^A-Za-z0-9_]*([A-Za-z0-9_]+)[^A-Za-z0-9_]*/i
          usemodname = $1.dup
          # add use statement to beginning of module unless the module has 
          # the same name
          adduse = (@module_begin and (@module_name !~ /^#{usemodname}$/i))
          # add use statement to beginning of routines not contained in a module
          if (@in_module_name.nil?) then
            adduse = (@subroutine_begin or @function_begin)
          end
          if (adduse) then
            if (@verbose) then
              print "#{self.class}.addRealKind:  appending use statement to str = <<#{str}>>\n"
            end
            str << "      USE #{usemod}\n"
          end
        end
      end
      retall = newcollapsed.baseString
      if (@verbose) then
        print "#{self.class}.addRealKind:  returning str = <<#{retall}>>\n"
      end
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

  # FortranStatements.new(aString [, true|false])
  # first argument is the name of a Fortran source file
  # second (optional) argument is "verbose" flag to print lots of diagnostic 
  # messages
  def initialize(*args)
    @fileName = args.shift
    @statements = []
    @verbose = false
    @identify_modules_called = false
    unless (args.empty?) then
      @verbose = args.shift
    end
    tmpFortranLineReader = FortranLineReader.new(@fileName,@verbose)
    until (tmpFortranLineReader.empty?) do
      @statements << FortranStatement.new(tmpFortranLineReader,@verbose)
    end
  end

  # Find all Fortran modules and identify which statements are inside 
  # each of them.  
  def identify_modules
    unless (@identify_modules_called) then
      # find ranges of all modules and store keyed by module names
      @modules = find_modules
      # tell each statement if it is inside a module
      @modules.each do |key, value|
        @statements[value].each do |statement|
          statement.in_module_name = key
        end
      end
      @identify_modules_called = true
    end
  end

  # Find modules and via matching begin and end statements.  
  # Note:  "END MODULE xxx" is required by this method.  This method will 
  # raise an exception if module begin and end statements do not match.  
  # Returns a Hash of statement Ranges keyed by module name.  
#$$$here...  simplify this...  
  def find_modules
    last_module_name = nil
    module_begin_indx = nil
    ret = {}
    @statements.each_with_index do |statement, indx|
      # collect module begin and end statements
      if (statement.module_begin) then
        if (last_module_name) then
          raise "ERROR:  in file #{@fileName}, overlapping modules at line #{statement.firstLineNumber}"
        else
          last_module_name = statement.module_name
# bug here, statement.module_name not getting set!  
          module_begin_indx = indx
#print"DEBUG:  found beginning of module <<#{last_module_name}>> at line #{module_begin_indx}\n"
        end
      elsif (statement.module_end) then
        modname = statement.module_name
#print"DEBUG:  found end of module <<#{modname}>> at line #{indx}\n"
        if (last_module_name and (last_module_name.upcase == modname.upcase)) then
          ret[last_module_name] = (module_begin_indx..indx)
          last_module_name = nil
          module_begin_indx = nil
        else
          # fix up things for error print
          if (module_begin_indx.nil?) then
            module_begin_indx = "NIL_INDX"
          end
          if (last_module_name.nil?) then
            last_module_name = "NIL_STRING"
          end
          raise "ERROR:  in file #{@fileName}, \"end module #{modname}\" statement at line #{statement.firstLineNumber} does not match \"module #{last_module_name}\" statement at line #{module_begin_indx}\n  Module #{last_module_name} must end with \"END MODULE #{last_module_name}\""
        end
      end
    end
    if (last_module_name) then
      raise "ERROR:  in file #{@fileName}, module #{last_module_name} has no end statement\n  Module #{last_module_name} must end with \"END MODULE #{last_module_name}\""
    end
    ret
  end


  # addRealKind(realKind [, usemod])
  # Returns array of Strings with Fortran REAL declarations and literal 
  # constants replaced by declarations and literal constants that have 
  # kind specified by String argument realKind.  
  # If optional String argument usemod is present, then new USE statements 
  # for module "usemod" will also be added where appropriate.  
  def addRealKind(*args)
    ret = []
    self.identify_modules
    @statements.each do |statement|
      if (@verbose) then
        print "#{self.class}.addRealKind:  file #{@fileName}, line #{statement.firstLineNumber}, statement = <<#{statement}>>\n"
      end
      begin
        ret << statement.addRealKind(*args)
      rescue
        print "ERROR translating file #{@fileName} at line #{statement.firstLineNumber}\n"
        raise
      end
    end
    ret
  end

  # findSymbols(aString [, true | false])
  # Find all symbols matching the first argument.  Returns an Array of String.  
  # If second argument is present and true, then only symbols appearing in 
  # PUBLIC statements or whose declarations include the PUBLIC attribute 
  # will be included.  All symbols are converted to uppercase and then 
  # duplicates are removed (this is Fortran...).  
#$$$ first arg should really be a Regexp !!  
  def findSymbols(*args)
    ret = []
    @statements.each do |statement|
      if (@verbose) then
        print "#{self.class}.findSymbols:  file #{@fileName}, line #{statement.firstLineNumber}, statement = <<#{statement}>>\n"
      end
      begin
        ret = ret + statement.findSymbols(*args)
      rescue
        print "ERROR searching file #{@fileName} at line #{statement.firstLineNumber}\n"
        raise
      end
    end
    ret.collect! { |r| r.upcase }
    ret.sort.uniq
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

