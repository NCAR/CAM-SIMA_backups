#!/usr/bin/env ruby

#==============================================================================
# Author:            Tom Henderson
# Acknowledgements:
# Organization:      NCAR MMM
#
# History:
#
#  Version 0.1  - Initial alpha-test version.  Simple parsing, etc.  
#
#==============================================================================


#==============================================================================
# Responsible for:
#   Simple extension to built-in Class String that finds a matching 
#   close-parenthesis starting after a specified index.  
#==============================================================================
class String

  # Returns index of matching close-parenthesis starting *after* index 
  # "open_parens_index".  The open-parenthesis is assumed to occur at or 
  # before self[open_parens_index], though this is NOT checked.  Raises an 
  # exception if no match is found.  Caller is expected to add useful 
  # information to the raised exception.  
  def find_close_parenthesis(open_parens_index)
    ret = nil
    found = 1
    offset = open_parens_index + 1
    while (found > 0)
      next_parens = self.index(/\(|\)/, offset)
      if ($& == "(") then
        found = found + 1
      else
        found = found - 1
        ret = next_parens
      end
      offset = next_parens + 1
      if (offset > self.length) then
        raise
      end
    end
    ret
  end

end


#==============================================================================
# Responsible for:
#   Exceptions returned from this class.  
#==============================================================================
class ArgumentParserException < RuntimeError

  attr_accessor :str_offset
  def initialize(stroffset)
    @str_offset = stroffset
  end

end


#==============================================================================
# Responsible for:
#   Parsing a string as if it consisted of a name of a Fortran routine followed 
#   by an open-parenthesis followed by zero or more arguments followed by a 
#   close-parenthesis.  Any characters following the close-parenthesis are 
#   ignored.  
#   Identifying and counting arguments between the parenthesis.  
#
#   Takes parenthesis and commas into account.  
#   Assumes that "(" and ")" and "," in string literals have already been 
#   masked out.  
#   Argument count is set to nil if parenthesis do not balance or do 
#   not appear in the expected order.  
#   String is assumed to contain Fortran source code that compiles, with the
#   possible addition of characters not recognized by Fortran.  
#   Not responsible for detecting syntax errors.  
#==============================================================================
class ArgumentParser

  attr_reader :num_args, :routine_name

  # Optional second argument is an offset into the string to begin parsing.  
  # ArgumentParser.new(aString [, aFixnum ])
  def initialize(*args)
    tmp_str = "" + args.shift
    @num_args = nil
    @arg_ranges = []
    @routine_name = nil
    @open_parens_idx = nil
    @close_parens_idx = nil
    @str_offset = 0
    unless (args.empty?) then
      @str_offset = args.shift
    end
    @in_str = tmp_str[(@str_offset..(tmp_str.length-1))]
    find_args
  end

  # Finds routine name and all arguments, stores argument Ranges, and counts 
  # arguments.  
  # Raises exceptions if first open-parenthesis cannot be matched, 
  # if parenthesis are out of order, or if there are no parenthesis.  
  # Sets @num_args to zero if substring between "( )" consists of only 
  # whitespace.  
  # 
  # Note:  since this is assumed to be compilable Fortran code, strings like 
  # the following will not be parsed properly:  
  #   "max(,)" "min(,x)" "___(_,x)" (etc.)
  def find_args
    if ((@in_str.count("(") > 0) and (@in_str.count(")") > 0) and
        (@in_str.index(/\(/) < @in_str.index(/\)/))) then
      # find routine name and outer open and close parenthesis
      @open_parens_idx = @in_str.index(/\(/)
      @routine_name = "" + @in_str[0..(@open_parens_idx-1)]
      begin
        @close_parens_idx = @in_str.find_close_parenthesis(@open_parens_idx)
      rescue
        raise ArgumentParserException.new(@str_offset + @open_parens_idx), 
          "ERROR:  ran past end of string trying to find first matching \")\""
      end
      arg_str = self.get_arg_str
      # if there is only whitespace between "( )" then there are no arguments
      if (arg_str =~ /^\s*$/) then
        @num_args = 0
      else
        # otherwise, find the arguments
        arg_str_offset = @open_parens_idx + 1
        if (arg_str.count("(") != arg_str.count(")")) then
          raise ArgumentParserException.new(@str_offset + arg_str_offset),
            "ERROR:  mismatched parenthesis in argument substring"
        end
        # first pass, match parenthesis in argument list, if any, and erase 
        # them 
        offset = 0
        while (next_open_parens = arg_str.index(/\(/, offset))
          begin
            match_close_parens = arg_str.find_close_parenthesis(next_open_parens)
          rescue
            raise ArgumentParserException.new(
              @str_offset + arg_str_offset + next_open_parens), 
              "ERROR:  ran past end of string trying to find matching \")\""
          end
          # clear everything enclosed by parenthesis including parenthesis
          arg_str[(next_open_parens..match_close_parens)] = 
            " "*(match_close_parens-next_open_parens+1)
          offset = match_close_parens + 1
          if (offset > arg_str.length) then
            raise ArgumentParserException.new(
              @str_offset + arg_str_offset + next_open_parens),
              "ERROR:  ran past end of string in find_args"
          end
        end
        # now any remaining commas should not be enclosed by parenthesis
        # second pass, find commas not enclosed by parenthesis
        offset = 0
        while (next_comma = arg_str.index(/,/, offset))
          @arg_ranges << 
            ((offset+arg_str_offset)..(next_comma-1+arg_str_offset))
          offset = next_comma + 1
          # ASSERTION (remove later)
          if (offset > arg_str.length) then
            raise ArgumentParserException.new(@str_offset + arg_str_offset),
              "ERROR:  ran past end of string trying to find \",\""
          end
        end
        # grab trailing argument, if any
        if (offset < arg_str.length) then
          @arg_ranges << 
            ((offset+arg_str_offset)..(arg_str.length-1+arg_str_offset))
        end
        @num_args = @arg_ranges.length
      end
    else
      raise ArgumentParserException.new(@str_offset),
        "ERROR:  could not find/parse argument list"
    end
  end

  def open_parens_index
    @open_parens_idx + @str_offset
  end

  def close_parens_index
    @close_parens_idx + @str_offset
  end

  def get_arg_str
    ret = "" + @in_str[((@open_parens_idx+1)..(@close_parens_idx-1))]
  end

  def get_args
    ret = []
    @arg_ranges.each do |range|
      ret << @in_str[range]
    end
    ret
  end

  def to_s
    @in_str
  end

end  # class ArgumentParser


