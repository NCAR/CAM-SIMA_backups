#!/usr/bin/env ruby

#==============================================================================
# Author:            Tom Henderson
# Acknowledgements:  
# Organization:      NCAR MMM
#
# Description:  
#
#   This installs applications in this directory into a specified directory.  
#   Every file named <*_app> will be installed as <*> in the directory 
#   specified via the "-a" option.  The string "LIB___DIR" will be replaced 
#   with the application installation directory in the installed application.  
#   This allows useful things like $: << "LIB___DIR" .  
#
#   If it is also necessary to install a "library" of other Ruby source files 
#   to support the application(s) then the name of a directory that contains 
#   them can be optionally specified using the "-s" option.  These files will 
#   be copied to an installation directory specified via the "-l" option.  
#
#   Type "ruby install.rb -h" for command-line options.  
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


#==============================================================================
# Responsible for:  
#   Installing all files named *_app in a user-specified directory.  
#   Parsing command-line arguments.  
#==============================================================================
class InstallApps

  # InstallApps.new
  def initialize
    # default settings
    @targetdir = nil
    @libsrcdir = nil
    @libinstalldir = nil
    @quiet = false
    @helpmsg = "\nType \"ruby #{$0} -h\" for help\n\n"
    if (parse_command_line) then
      install_apps
    else
      print "#{@helpmsg}"
      exit -1
    end
  end

  # returns true iff command line was successfully parsed
  def parse_command_line
    ret = true
    # Use OptionParser from standard library
    opts = OptionParser.new do |opts|
      opts.banner = <<END_OF_BANNER

#{$0} is an application that installs applications in this directory into a 
specified directory.  Every file named <*_app> will be installed as <*> in 
the directory specified via the "-a" option.  

If it is also necessary to install a "library" of other Ruby source files 
to support the application(s) then the name of a directory that contains 
them can be optionally specified using the "-s" option.  These files will 
be copied to an installation directory specified via the "-l" option.  

Usage:  ruby #{$0} arguments [options]
END_OF_BANNER
      opts.separator ""
      opts.separator "Required arguments:"
      # Mandatory arguments.
      opts.on("-a=APPLICATION_DIR", "--application_install_directory=APPLICATION_DIR",
              "Target installation directory for application") do |dir|
        @targetdir = File.expand_path(dir.strip.sub("/$",""))
      end
      opts.separator ""
      opts.separator "Specific options:"
      # Optional arguments.
      opts.on("-l=LIB_INSTALL_DIR", "--library_install_directory=LIB_INSTALL_DIR",
              "Target installation directory for library") do |dir|
        @libinstalldir = File.expand_path(dir.strip.sub("/$",""))
      end
      opts.separator ""
      opts.on("-s=LIB_SRC_DIR", "--source_library_directory=LIB_SRC_DIR",
              "Source directory for library") do |dir|
        @libsrcdir = File.expand_path(dir.strip.sub("/$",""))
      end
      opts.separator ""
      # No argument, shows at tail.  This will print an options summary.
      opts.on("-q", "--quiet", "Do not print anything (except error messages)") do 
        @quiet = true
      end
      opts.separator ""
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
#$$$DEBUG
#print " after parse @targetdir.class = <<#{@targetdir.class}>>\n"
#print " after parse @libsrcdir.class = <<#{@libsrcdir.class}>>\n"
#print " after parse @libinstalldir.class = <<#{@libinstalldir.class}>>\n"
#$$$END DEBUG
    #
    # Command line error checks...  
    #
    # check for required and optional arguments
    unless (@targetdir) then
      # check for required arguments
      print "\nERROR:  Must specify application installation directory on command line\n"
      ret = false
    else
      unless (FileTest.directory?(@targetdir)) then
        print "\nERROR:  Application install directory \"#{@targetdir}\" is not a valid directory\n#{@helpmsg}"
        exit -1
      end
      # check for optional arguments
      # library source dir is "." if not specified in this case
      if (@libsrcdir) then
        unless (@libinstalldir) then
          print "\nERROR:  Must specify library installation directory on command line when library source directory is specified\n"
          ret = false
        end
        unless (FileTest.directory?(@libsrcdir)) then
          print "\nERROR:  Library source directory \"#{@libsrcdir}\" is not a valid directory\n#{@helpmsg}"
          exit -1
        end
      else
        @libsrcdir = Dir.getwd
      end
      if (@libinstalldir) then
        unless (FileTest.directory?(@libinstalldir)) then
          print "\nERROR:  Library install directory \"#{@libinstalldir}\" is not a valid directory\n#{@helpmsg}"
          exit -1
        end
      end
    end
#$$$DEBUG
#print "@targetdir = <<#{@targetdir}>>\n"
#print "@libsrcdir = <<#{@libsrcdir}>>\n"
#print "@libinstalldir = <<#{@libinstalldir}>>\n"
#$$$END DEBUG
    ret
  end

  def install_apps
    # install applications
    installfiles = Dir["*_app"]
    libdir = Dir.getwd
    if (@libinstalldir) then
      libdir = @libinstalldir
    end
    installfiles.each do |ifile|
      lines = IO.readlines(ifile)
      lines.collect! { |line| line.sub(/LIB___DIR/, "#{libdir}") }
      outfile = @targetdir + "/" + ifile.sub(/_app$/, "")
      unless (@quiet) then
        print "  installing application #{ifile} in #{outfile}...\n"
      end
      if (FileTest.exist?(outfile)) then
        raise "\n\nERROR:  target file #{outfile} already exists, please remove it before installing\n\n"
      end
      File.open(outfile, "w") do |aFile|
        aFile.puts(lines)
        aFile.chmod(0755)
      end   # File.open
    end
    # install library files, if requested
    libfiles = []
    libdirs = []
    if (@libinstalldir) then
      dirsave = Dir.getwd
      Dir.chdir(@libsrcdir)
      Find.find(".") do |f|
        # skip this script and unit test files
        Find.prune if ((f =~ /install\.rb$/) or (f =~ /tc_\w+\.rb$/) or (f =~ /ts_\w+\.rb$/))
        # collect names of Ruby "library" source files
        libfiles << f if (f =~ /\w+\.rb$/)
        # collect names of subdirectories
        if (FileTest.directory?(f))
          unless ((f == "#{Dir.getwd}") or (f == ".")) then
            # only retain directories that actually contain Ruby 
            # source files
            Find.find(f) do |ff| 
              if (ff =~ /\w+\.rb$/) then
                libdirs << f
                break
              end
            end
          end
        end
      end
      # create subdirectories 
      libdirs.each do |d|
        destdir = "#{@libinstalldir}" + "/#{d}"
        unless (@quiet) then
          print "  creating library subdirectory #{d} in #{destdir}...\n"
        end
        Dir.mkdir(destdir)
      end
      # copy library files in a separate loop to avoid recursion
      libfiles.each do |f|
        dest = "#{@libinstalldir}" + "/#{f}"
        unless (@quiet) then
          print "  installing library file #{f} in #{dest}...\n"
        end
        copy_file(f,dest)
      end
      Dir.chdir(dirsave)
    end
  end

  # copy file source overwriting destination
  def copy_file(source, destination)
    lines = IO.readlines("#{source}")
    File.open("#{destination}", "w") { |aFile| aFile.puts(lines) }
  end

end  # class InstallApps


InstallApps.new


