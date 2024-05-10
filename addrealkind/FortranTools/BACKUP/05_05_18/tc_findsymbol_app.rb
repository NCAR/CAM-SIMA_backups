#!/usr/bin/env ruby

require 'test/unit'
require 'findSymbol'
require 'find'
    

class TC_FindSymbolApp < Test::Unit::TestCase

  def setup
    # install findsymbol application in @installdir
    @installdir = "install_test"
    @app = "#{@installdir}/findsymbol"
    raise "directory #{@installdir} does not exist" unless (FileTest.directory?(@installdir))
    # clean up
    self.uninstall_app
    # install
    `install.rb -d @installdir`
    @sourcedir = "findsymbol_test"
    raise "directory #{@sourcedir} does not exist" unless (FileTest.directory?(@sourcedir))
    @sourceoutdir = "findsymbol_out/findsymbol_source"
    raise "directory #{@sourceoutdir} does not exist" unless (FileTest.directory?(@sourceoutdir))
    @sourceoutdir_OK = "findsymbol_out/findsymbol_source_OK"
    raise "directory #{@sourceoutdir_OK} does not exist" unless (FileTest.directory?(@sourceoutdir_OK))
    @stdoutdir = "findsymbol_out/findsymbol_stdout"
    raise "directory #{@stdoutdir} does not exist" unless (FileTest.directory?(@stdoutdir))
    @stdoutdir_OK = "findsymbol_out/findsymbol_stdout_OK"
    raise "directory #{@stdoutdir_OK} does not exist" unless (FileTest.directory?(@stdoutdir_OK))
  end

  def test_install
    FileTest.executable?(@app)
    assert(FileTest.executable?(@app), "installation")
  end

  def test_find_public_op_gen

$$$here...  just run install.rb and put the output in ./install_test/ and execute the installation 
$$$here...  directly!!  

`#{@app} -d #{@sourcedir} -S ESMF_ -p -O -g WRF_COMP_ -o ESMF_Mod -n module_comp > & ! #{@stdoutdir_OK}/module_comp.F`

$$$here...  add option to write output to a named file for testing ("-w <filename>")
$$$here...  "good" output in findsymbol_test/module_comp.F_OK
$$$here...  once findsymbol understands USE, ESMF_Test should no longer appear in 
$$$here...  findsymbol_test/module_comp.F_OK

  end

  def teardown
    self.uninstall_app
  end

  def uninstall_app
    Find.find(@installdir) do |f| 
      unless (FileTest.directory?(f)) then
        File.delete(f)
      end
    end
  end

end  # class TC_FindSymbolApp


