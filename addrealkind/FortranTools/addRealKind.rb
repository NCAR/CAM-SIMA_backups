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
#   Type "ruby addRealKind.rb -h" for command-line options.  
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
class AddRealKind

  attr_reader :fileName

  $found_missing = 0

  @@verbose_off = 0
  @@verbose_min = 1
  @@verbose_max = 2

  @@log_only_off    = 0
  @@log_only_on     = 1

  # AddRealKind.new
  def initialize
    # default settings
    @targetdir = nil
    @realKind = "fp"
    @verbose = @@verbose_off
    @log_only    = @@log_only_off
    @appname = File.basename($0)
    @helpmsg = "\nType \"ruby #{@appname} -h\" for help\n\n"
    @skip_files = []
    @useMod = nil
    if (parse_command_line) then
#print "DEBUG:  @verbose.class = <<#{@verbose.class}>>\n"
#print "DEBUG:  @verbose = <<#{@verbose}>>\n"
#exit
#print "DEBUG:  @skip_files.class = <<#{@skip_files.class}>>\n"
#print "DEBUG:  @skip_files = <<#{@skip_files.join(":")}>>\n"
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

#{@appname} is an application that adds a Fortran \"kind\" parameter to
every REAL and COMPLEX declaration, literal constant, and cast (via
intrinsic functions \"REAL\" and \"CMPLX\") where a kind parameter does
not already exist.  

Fortran source files must contain valid free-form source code that is free 
from syntax errors.  #{@appname} does not understand cpp directives and will ignore 
them, when possible.  

NOTE:  Fortran source files are modified in-place, so make backup copies 
       before running this script, if needed.

Usage:  ruby #{@appname} arguments [options]
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
      # add "USE NEW_MODULE" statements
      opts.on("-u=NEW_MODULE", "--use_module=NEW_MODULE",
              "Add Fortran \"USE NEW_MODULE\" statements.  Does NOT check for pre-existing USE statements first!") do |newmod|
        @useMod = newmod
      end
      # directories and files to skip
      opts.on("-s dir1,dir2,dir3", "--skip_files dir1,file2,dir3", Array, 
              "Skip directories and files specified in comma-separated list") do |filelist|
        @skip_files = filelist
#        @skip_files = filelist.split(",")
      end
      # verbosity
      opts.on("-v=MESSAGE_LEVEL", "--verbose=MESSAGE_LEVEL", 
              "Run verbosely\n    MESSAGE_LEVEL=0 -> no-verbose (default)\n    MESSAGE_LEVEL=1 -> verbose\n    MESSAGE_LEVEL=2 -> loquacious\n") do |v|
        @verbose = v.to_i
      end
      # Report only
      opts.on("-l=LOG_LEVEL", "--log_only=LOG_LEVEL", 
              "Log generation \n    LOG_LEVEL=0 -> no log of changes, files are changed\n    LOG_LEVEL=1 -> Only generate log of changes, no files are altered\n") do |l|
        @log_only = l.to_i
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
      print "\nERROR:  Must specify target directory on command line\n"
      ret = false
    end
    ret
  end

  def translate_source_files
    if (@log_only == @@log_only_off) then
      print "\n#{@appname}:  Adding real kind = \"#{@realKind}\" to all Fortran source files in directory \"#{@targetdir}\"\n\n"
    else
      print "\n#{@appname}:  Checking real kind = \"#{@realKind}\" to all Fortran source files in directory \"#{@targetdir}\"\n\n"
    end
    unless (@skip_files.empty?) then
      print "\n#{@appname}:  Skipping these sub-directories and files:  \"#{@skip_files.join("\" \"")}\"\n\n"
    end
    foundfile = false
    Find.find(@targetdir) do |f|
      # skip directories and files
      skipit = false
      @skip_files.each do |skipfile|
        if ((f =~ /\/#{skipfile}\//) or (f =~ /\/#{skipfile}$/)) then
          skipit = true
        end
      end
      Find.prune if skipit
      # translate Fortran source files
      if (f =~ /\.(f$|f90$)/i) then
        foundfile = true
        if (@verbose >= @@verbose_min) then
          print "#{@appname}:  Extracting Fortran statements from source file \"#{f}\"...\n"
        end
        statements = FortranStatements.new(f, @verbose == @@verbose_max, @log_only == @@log_only_on)
        if (@verbose >= @@verbose_min) then
          print "#{@appname}:  Translating Fortran source file \"#{f}\"...\n"
        end
        # temporary backup file
        if (@log_only == @@log_only_off) then
          backupfile = "#{f}.BACKUP.#{$$}"
          File.rename(f, backupfile)
          begin
            # overwrite input file
            File.open(f, "w") do |aFile|
              if (@useMod) then
                aFile.puts(statements.addRealKind(@realKind, @useMod))
              else
                aFile.puts(statements.addRealKind(@realKind))
              end
            end   # File.open
          rescue
            # restore original file on exception
            File.delete(f)
            File.rename(backupfile, f)
            raise
          end
          File.delete(backupfile)
        else  #log_only = log_only_on
          begin
            # overwrite input file
            File.open(f, "r") do |aFile|
              if (@useMod) then
                statements.addRealKind(@realKind, @useMod)
              else
                statements.addRealKind(@realKind)
              end
            end   # File.open
          end
        end
      end
    end
    unless (foundfile) then
      print "\nWARNING:  Could not find any Fortran source files to translate in directory \"#{@targetdir}\""
    end
  end

end  # class AddRealKind


# AddRealKind.new


