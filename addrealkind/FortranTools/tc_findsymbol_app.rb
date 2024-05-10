#!/usr/bin/env ruby

require 'test/unit'
require 'findSymbol'
require 'find'
    

# tests installation and operation of findsymbol application
class TC_FindSymbolApp < Test::Unit::TestCase

  def setup
    # verify that directories exist as expected and clean up
    @installdir = "install_test"
    @app = "#{@installdir}/findsymbol"
    check_dir("#{@installdir}")
    @sourcedir = "findsymbol_test"
    check_dir("#{@sourcedir}")
    @sourceoutdir = "findsymbol_out/findsymbol_source"
    check_dir("#{@sourceoutdir}")
    @sourceoutdir_OK = "findsymbol_out/findsymbol_source_OK"
    check_dir("#{@sourceoutdir_OK}")
    @stdoutdir = "findsymbol_out/findsymbol_stdout"
    check_dir("#{@stdoutdir}")
    @stdoutdir_OK = "findsymbol_out/findsymbol_stdout_OK"
    check_dir("#{@stdoutdir_OK}")
    # install findsymbol application in @installdir
    # clean up
    self.uninstall_app
    # install
    `install.rb -a #{@installdir}`
  end

  # "aaa" makes this test run first.  a hack for sure!
  # fix this so installation happens only once and make sure it is not here!!  
  def test_aaa_install
    assert(FileTest.executable?(@app), "installation")
    clean_dir(@stdoutdir)
    clean_dir(@sourceoutdir)
  end

  def test_find
    outfile    = "#{@stdoutdir}/find"
    outfile_OK = "#{@stdoutdir_OK}/find"
    `#{@app} -d #{@sourcedir} -S ESMF_ -w #{outfile}`
    out_OK = IO.readlines("#{outfile_OK}")
    out    = IO.readlines("#{outfile}")
    result = (out_OK == out)
    unless (result) then
      `xxdiff #{outfile_OK} #{outfile}`
    end
    assert(result, "find symbols")
  end

  def test_find_public_gen
    outfile    = "#{@stdoutdir}/module_comp.F"
    outfile_OK = "#{@stdoutdir_OK}/module_comp.F"
    `#{@app} -d #{@sourcedir} -S ESMF_ -p -g WRF_COMP_ -o ESMF_Mod -n module_comp -w #{outfile}`
    out_OK = IO.readlines("#{outfile_OK}")
    out    = IO.readlines("#{outfile}")
    result = (out_OK == out)
    unless (result) then
      `xxdiff #{outfile_OK} #{outfile}`
    end
    assert(result, "find public symbols and generate translation module")
#$$$here...  once findsymbol understands USE, ESMF_Test should no longer appear in 
#$$$here...  "#{@stdoutdir_OK}/module_comp.F"
  end

  def test_find_replace
    test_source_files = ["FESMF.f", "FESMF_Test.f"]
    test_source_files.each do |fname|
      testfile = "#{@sourceoutdir}/#{fname}"
      copy_file("#{@sourcedir}/#{fname}","#{testfile}")
    end
    `#{@app} -d #{@sourceoutdir} -S ESMF_ -R WRF_COMP_`
    test_source_files.each do |fname|
      testfile = "#{@sourceoutdir}/#{fname}"
      testfile_OK = "#{@sourceoutdir_OK}/#{fname}"
#$$$ remove duplication
      test_OK = IO.readlines("#{testfile_OK}")
      test    = IO.readlines("#{testfile}")
      result = (test_OK == test)
      unless (result) then
        `xxdiff #{testfile_OK} #{testfile}`
      end
      assert(result, "replace symbols")
    end
  end

  def teardown
    self.uninstall_app
  end

### a few utility routines from me ###

  # raise exception if dir is not a directory
  def check_dir(dir)
    raise "directory #{dir} does not exist" unless (FileTest.directory?(dir))
  end

  # uninstall the application
  def uninstall_app
    clean_dir(@installdir)
  end

  # removes all non-directories beneath dir
  def clean_dir(dir)
    Find.find(dir) do |f| 
      unless (FileTest.directory?(f)) then
        File.delete(f)
      end
    end
  end

  # copy file source overwriting destination
  def copy_file(source, destination)
    lines = IO.readlines("#{source}")
    File.open("#{destination}", "w") { |aFile| aFile.puts(lines) }
  end

end  # class TC_FindSymbolApp


