
#==============================================================================
# Responsible for:
#   Parsing a string as if it were one or more arguments to a Fortran routine
#   and figuring out how many arguments there are.  Takes parenthesis and
#   commas into account.  nil is returned for argument count if parenthesis 
#   do not balance.  
#   String is assumed to contain Fortran source code that compiles, with the
#   possible addition of characters not recognized by Fortran.  
#   Not responsible for detecting syntax errors.  
#==============================================================================
class ArgumentParser
                                                                                                    
  attr_reader :num_args
                                                                                                    
  # ArgumentParser.new(aString)
  def initialize(args_str)
    @arg_str = "" + args_str
    @num_args = nil
    @arg_ranges = []
    find_args
  end
                                                                                                    
  # Finds all arguments, stores their Ranges, and counts them.  
  # Sets @num_args to nil if the string contains unbalanced parenthesis.
  # Sets @num_args to zero if the string is empty.  
  def find_args
    if (@arg_str.length == 0) then
      @num_args = 0
    elsif (@arg_str.count("(") != @arg_str.count(")")) then
      @num_args = nil
    else
      # first pass, match parenthesis
      tmp_arg_str = "" + @arg_str
      offset = 0
      while (next_open_parens = tmp_arg_str.index(/\(/, offset))
        newoffset = next_open_parens + 1
        next_parens = newoffset
        found = 1
        while (found > 0)
          next_parens = tmp_arg_str.index(/\(|\)/, newoffset)
          if ($& == "(") then
            found = found + 1
          else
            found = found - 1
          end
          newoffset = next_parens + 1
          if (newoffset > tmp_arg_str.length) then
            raise "ERROR:  ran past end of string trying to find \")\""
          end
        end
        # clear everything enclosed by parenthesis including parenthesis
        tmp_arg_str[(next_open_parens..next_parens)] = 
          " "*(next_parens-next_open_parens+1)
        offset = newoffset
        if (offset > tmp_arg_str.length) then
          raise "ERROR:  ran past end of string in find_args"
        end
      end
      # now any remaining commas should not be enclosed by parenthesis
      # second pass, find commas not enclosed by parenthesis
      offset = 0
      while (next_comma = tmp_arg_str.index(/,/, offset))
        @arg_ranges << (offset..(next_comma-1))
        offset = next_comma + 1
        if (offset > tmp_arg_str.length) then
          raise "ERROR:  ran past end of string trying to find \",\""
        end
      end
      # grab trailing argument, if any
      if (offset < tmp_arg_str.length) then
        @arg_ranges << (offset..(tmp_arg_str.length-1))
      end
      @num_args = @arg_ranges.length
    end
  end
                                                                                                    
  def get_args
    ret = []
    @arg_ranges.each do |range|
      ret << @arg_str[range]
    end
    ret
  end
                                                                                                    
  def to_s
    @arg_str
  end
                                                                                                    
end  # class ArgumentParser
                                                                                                    

