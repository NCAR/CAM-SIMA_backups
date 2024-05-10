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

  @@verbose_off = 0
  @@verbose_min = 1
  @@verbose_max = 2

  # RealKindApp.new
  def initialize
    # default settings
    @targetdir = nil
    @realKind = "fp"
    @verbose = @@verbose_off
    @helpmsg = "\nType \"ruby #{$0} -h\" for help\n\n"
    @skip_directories = []
    if (parse_command_line) then
#print "DEBUG:  @verbose.class = <<#{@verbose.class}>>\n"
#print "DEBUG:  @verbose = <<#{@verbose}>>\n"
#exit
#print "DEBUG:  @skip_directories.class = <<#{@skip_directories.class}>>\n"
#print "DEBUG:  @skip_directories = <<#{@skip_directories.join(":")}>>\n"
#exit
      translate_source_files
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

#{$0} is an application that adds a Fortran \"kind\" parameter to
every REAL and COMPLEX declaration, literal constant, and cast (via
intrinsic functions \"REAL\" and \"CMPLX\") where a kind parameter does
not already exist.  

Fortran source files must contain valid source code that is free from 
syntax errors.  #{$0} does not understand cpp directives and will ignore 
them, when possible.  

NOTE:  Fortran source files are modified in-place, so make backup copies 
       before running this script, if needed.

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
      opts.on("-r=REAL_KIND", "--realkind=REAL_KIND",
              "Add Fortran kind REAL_KIND to REAL and COMPLEX data types where kind is not already specified") do |kind|
        @realKind = kind
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

  def translate_source_files
    print "\n#{$0}:  Adding real kind = \"#{@realKind}\" to all Fortran source files in directory \"#{@targetdir}\"\n\n"
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
      # translate Fortran source files
      if (f =~ /\.(f$|f90$)/i) then
        foundfile = true
        if (@verbose >= @@verbose_min) then
          print "#{$0}:  Extracting Fortran statements from source file \"#{f}\"...\n"
        end
        statements = FortranStatements.new(f, @verbose == @@verbose_max)
        if (@verbose >= @@verbose_min) then
          print "#{$0}:  Translating Fortran source file \"#{f}\"...\n"
        end
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


