#!/usr/bin/env ruby

#==============================================================================
# Author:            Tom Henderson
# Acknowledgements:  
# Organization:      NCAR MMM
#
# Description:  
#
#   This is an application that finds all symbols that match a specified 
#   String in all Fortran source files beneath a specified directory.  
#
#   Type "ruby findSymbol.rb -h" for command-line options.  
#
#
# Assumptions:  
#   Source code is in Fortran90/95 free form.  
#   Source code compiles.  
#
#
# History:  
#
#  Version 0.1  - Initial alpha-test version.  
#
#==============================================================================

# classes used by this class
require 'optparse'
require 'find'
require 'fortranStatements'


#==============================================================================
# Responsible for:  
#   Translating all files beneath a specified directory to use a specified 
#   kind.  
#   Parsing command-line arguments.  
#==============================================================================
class FindSymbols

  attr_reader :fileName

  @@verbose_off = 0
  @@verbose_min = 1
  @@verbose_max = 2

  # RealKindApp.new
  def initialize
    # default settings
    @targetdir = nil
    @symbol = nil
    @verbose = @@verbose_off
    @helpmsg = "\nType \"ruby #{$0} -h\" for help\n\n"
    @skip_directories = []
    if (parse_command_line) then
      search_source_files
    else
      print "ERROR:  could not parse arguments\n#{@helpmsg}"
      exit -1
    end
  end

  # returns true iff command line was successfully parsed
  def parse_command_line
    ret = true
    # Use OptionParser from standard library
    opts = OptionParser.new do |opts|
      opts.banner = <<END_OF_BANNER

#{$0} is an application that that finds all symbols that match a specified 
String in all Fortran source files beneath a specified directory.  All 
matching symbols are sorted and duplicates are removed.  

Fortran source files must contain valid free-form source code that is free 
from syntax errors.  #{$0} does not understand cpp directives and will ignore 
them, when possible.  

Usage:  ruby #{$0} arguments [options]
END_OF_BANNER
      opts.separator ""
      opts.separator "Required arguments:"
      # Mandatory arguments.
      opts.on("-d=DIR", "--directory=DIR",
              "Translate all files in the directory tree rooted at DIR") do |dir|
        absdir = dir.strip.sub("/$","")
        unless (FileTest.directory?(absdir)) then
          print "\nERROR:  \"#{absdir}\" is not a valid directory\n#{@helpmsg}"
          exit -1
        end
        @targetdir = absdir
      end
      opts.separator ""
      opts.separator "Specific options:"
      # real kind
      opts.on("-s=SYMBOL", "--symbol=SYMBOL",
              "Find all symbols that match SYMBOL") do |sym|
        @symbol = sym
      end
      # directories to skip
      opts.on("-s dir1,dir2,dir3", "--skip_directories dir1,dir2,dir3", Array, 
              "Skip directories specified in comma-separated list") do |dirlist|
        @skip_directories = dirlist
#        @skip_directories = dirlist.split(",")
      end
      # verbosity
      opts.on("-v=MESSAGE_LEVEL", "--verbose=MESSAGE_LEVEL", 
              "Run verbosely\n    MESSAGE_LEVEL=0 -> no-verbose (default)\n    MESSAGE_LEVEL=1 -> verbose\n    MESSAGE_LEVEL=2 -> loquacious") do |v|
        @verbose = v.to_i
      end
      # No argument, shows at tail.  This will print an options summary.
      opts.on_tail("-h", "--help", "Show this message\n") do
        puts opts
        exit
      end
    end
    begin
      opts.parse!(ARGV)
    rescue
#raise
      ret = false
    end
    unless (@targetdir) then
      print "\nERROR:  Must specify target directory on command line\n#{@helpmsg}"
      ret = false
    end
    ret
  end

  def search_source_files
    matching_symbols = []
    print "\n#{$0}:  Searching for all symbols matching \"#{@symbol}\" in all Fortran source files in directory \"#{@targetdir}\"\n\n"
    unless (@skip_directories.empty?) then
      print "\n#{$0}:  Skipping sub-directories that match the following strings:  \"#{@skip_directories.join("\" \"")}\"\n\n"
    end
    foundfile = false
    Find.find(@targetdir) do |f|
      # skip directories
      skipit = false
      @skip_directories.each do |skipdir|
        if (f =~ /\/#{skipdir}\//) then
          skipit = true
        end
      end
      Find.prune if skipit
      # search Fortran source files
      if (f =~ /\.(f$|f90$)/i) then
        foundfile = true
        if (@verbose >= @@verbose_min) then
          print "#{$0}:  Searching Fortran source file \"#{f}\"...\n"
        end
        statements = FortranStatements.new(f, @verbose == @@verbose_max)
        matching_symbols << statements.findSymbols(@symbol)
      end
    end
    unless (foundfile) then
      print "\nWARNING:  Could not find any Fortran source files to search in directory \"#{@targetdir}\""
    end
    matching_symbols.sort!
    matching_symbols.uniq!
    print "Found the following matching symbols:"
    print "#{matching_symbols.join("\n")}"
  end

end  # class FindSymbols


FindSymbols.new


