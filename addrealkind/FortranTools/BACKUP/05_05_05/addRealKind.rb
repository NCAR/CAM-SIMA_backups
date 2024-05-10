#!/usr/bin/env ruby

#==============================================================================
# Author:            Tom Henderson
# Acknowledgements:  
# Organization:      NCAR MMM
#
# Description:  
#
#   This is an application that adds a Fortran "kind" parameter to 
#   every REAL and COMPLEX declaration, literal constant, and cast (via 
#   intrinsic functions "REAL" and "CMPLX") where a kind parameter does
#   not already exist.  Source files are modified in-place.  
#
#   Type "ruby realKindDriver.rb -h" for command-line options.  
#
#
# Assumptions:  
#   Source code is in Fortran90/95 free form.  
#   Source code compiles.  
#
#
# History:  
#
#  Version 0.1  - Initial alpha-test version.  Supported by a large unit-test 
#                 suite.  
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
class RealKindApp

  attr_reader :fileName

  # RealKindApp.new
  def initialize
    # default settings
    @targetdir = nil
    @realKind = "fp"
    @verbose = false
    if (parse_command_line) then
      translate_source_files
    end
  end

  # returns true iff command line was successfully parsed
  def parse_command_line
    ret = true
    helpmsg = "\nType \"ruby #{$0} -h\" for help\n\n"
    # Use OptionParser from standard library
    opts = OptionParser.new do |opts|
      opts.banner = <<END_OF_BANNER

#{$0} is an application that adds a Fortran \"kind\" parameter to
every REAL and COMPLEX declaration, literal constant, and cast (via
intrinsic functions \"REAL\" and \"CMPLX\") where a kind parameter does
not already exist.  

NOTE:  Fortran source files are modified in-place, so make backup copies 
       before running this script, if needed.

Usage:  ruby #{$0} arguments [options]
END_OF_BANNER
      opts.separator ""
      opts.separator "Required arguments:"
      # Mandatory arguments.
      opts.on("-d", "--directory DIR",
              "Translate all files in the directory tree rooted at DIR") do |dir|
        absdir = dir.strip.sub("/$","")
        unless (FileTest.directory?(absdir)) then
          print "\nERROR:  \"#{absdir}\" is not a valid directory\n#{helpmsg}"
          raise
        end
        @targetdir = absdir
      end
      opts.separator ""
      opts.separator "Specific options:"
      opts.on("-r", "--realkind REAL_KIND",
              "Add Fortran kind REAL_KIND to REAL and COMPLEX data types where kind is not already specified") do |kind|
        @realKind = kind
      end
      # Optional argument with keyword completion.
      # Boolean switch.
      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        @verbose = v
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
      ret = false
    end
    unless (@targetdir) then
      print "\nERROR:  Must specify target directory on command line\n#{helpmsg}"
      ret = false
    end
    ret
  end

  def translate_source_files
    print "\n#{$0}:  Adding real kind = \"#{@realKind}\" to all Fortran source files in directory \"#{@targetdir}\"\n\n"
    foundfile = false
    Find.find(@targetdir) do |f|
      if (f =~ /\.(f$|f90$)/i) then
        foundfile = true
        if (@verbose) then
          print "#{$0}:  Translating Fortran source file \"#{f}\"...\n"
        end
        statements = FortranStatements.new(f)
        # temporary backup file
        backupfile = "#{f}.BACKUP.#{$$}"
        File.rename(f, backupfile)
        begin
          # overwrite input file
          File.open(f, "w") do |aFile|
            aFile.puts(statements.addRealKind(@realKind))
          end   # File.open
        rescue
          # restore original file on exception
          File.delete(f)
          File.rename(backupfile, f)
          raise
        end
        File.delete(backupfile)
      end
    end
    unless (foundfile) then
      print "\nWARNING:  Could not find any Fortran source files to translate in directory \"#{@targetdir}\""
    end
  end

end  # class RealKindApp


RealKindApp.new


