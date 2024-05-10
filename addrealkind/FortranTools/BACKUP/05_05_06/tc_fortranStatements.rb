#!/usr/bin/env ruby

require 'test/unit'
require 'fortranStatements'
    

class TestFortranStatements

  attr_reader :errorMsg

  def initialize(infname, outfname, outfname_OK, unmaskfname, unmaskfname_OK, 
                 fpfname, fpfname_OK)
    @infname = infname
    @outfname = outfname
    @outfname_OK = outfname_OK
    @unmaskfname = unmaskfname
    @unmaskfname_OK = unmaskfname_OK
    @fpfname = fpfname
    @fpfname_OK = fpfname_OK
    statements = FortranStatements.new(infname)
    File.open(outfname, "w") do |aFile|
      aFile.puts(statements)
    end   # File.open
    File.open(unmaskfname, "w") do |aFile|
      aFile.puts(statements.unmask)
    end   # File.open
    File.open(fpfname, "w") do |aFile|
      aFile.puts(statements.addRealKind("fp"))
    end   # File.open
    @errorMsg = ""
  end

  def statements_correct?
    statements_OK = IO.readlines(@outfname_OK)
    statements    = IO.readlines(@outfname)
    ret = resultOK?(statements_OK, statements, "statements")
    unless (ret) then
      `xxdiff #{@outfname_OK} #{@outfname}`
    end
    ret
  end

  def unmask_correct?
    unmask_OK = IO.readlines(@unmaskfname_OK)
    unmask    = IO.readlines(@unmaskfname)
    ret = resultOK?(unmask_OK, unmask, "unmask")
    unless (ret) then
      `xxdiff #{@unmaskfname_OK} #{@unmaskfname}`
    end
    ret
  end

  def fp_correct?
    fp_OK = IO.readlines(@fpfname_OK)
    fp    = IO.readlines(@fpfname)
    ret = resultOK?(fp_OK, fp, "fp")
#print "DEBUG:  <<#{@fpfname_OK}>> <<#{@fpfname}>> ret = #{ret}\n"
    unless (ret) then
      `xxdiff #{@fpfname_OK} #{@fpfname}`
    end
    ret
  end

  def resultOK?(expected, actual, errorHeader)
    ret = (expected == actual)
    @errorMsg = "NO ERROR\n"
    unless ret then
      expected.each_index do |indx|
#$$$here...  improve this to handle cases where array lengths differ
        if (expected[indx] != actual[indx]) then
          @errorMsg =  "#{errorHeader}\n"
          @errorMsg << "LINE #{indx} EXPECTED:  <#{expected[indx]}>\n"
          @errorMsg << "LINE #{indx} BUT GOT:   <#{actual[indx]}>\n"
        end
      end
    end
    ret
  end

end   # class TestFortranStatements



class TC_FortranStatements < Test::Unit::TestCase

  def setup
    @statementss = []
    @statementss << TestFortranStatements.new(
                      "continuation_test/c.f90", 
                      "continuation_test/c_statements.f90", 
                      "continuation_test/c_statements_OK.f90", 
                      "continuation_test/c_unmask.f90", 
                      "continuation_test/c_unmask_OK.f90", 
                      "continuation_test/c_fp.f90", 
                      "continuation_test/c_fp_OK.f90") 
    @statementss << TestFortranStatements.new(
                      "continuation_test/tst0.F90", 
                      "continuation_test/tst0_statements.F90", 
                      "continuation_test/tst0_statements_OK.F90", 
                      "continuation_test/tst0_unmask.F90", 
                      "continuation_test/tst0_unmask_OK.F90", 
                      "continuation_test/tst0_fp.F90", 
                      "continuation_test/tst0_fp_OK.F90") 
    @statementss << TestFortranStatements.new(
                      "continuation_test/tst1.F90", 
                      "continuation_test/tst1_statements.F90", 
                      "continuation_test/tst1_statements_OK.F90", 
                      "continuation_test/tst1_unmask.F90", 
                      "continuation_test/tst1_unmask_OK.F90", 
                      "continuation_test/tst1_fp.F90", 
                      "continuation_test/tst1_fp_OK.F90") 
    @statementss << TestFortranStatements.new(
                      "continuation_test/tst_fp.F90", 
                      "continuation_test/tst_fp_statements.F90", 
                      "continuation_test/tst_fp_statements_OK.F90", 
                      "continuation_test/tst_fp_unmask.F90", 
                      "continuation_test/tst_fp_unmask_OK.F90", 
                      "continuation_test/tst_fp_fp.F90", 
                      "continuation_test/tst_fp_fp_OK.F90") 
    @statementss << TestFortranStatements.new(
                      "continuation_test/dadadj.F90", 
                      "continuation_test/dadadj_statements.F90", 
                      "continuation_test/dadadj_statements_OK.F90", 
                      "continuation_test/dadadj_unmask.F90", 
                      "continuation_test/dadadj_unmask_OK.F90", 
                      "continuation_test/dadadj_fp.F90", 
                      "continuation_test/dadadj_fp_OK.F90") 
    @statementss << TestFortranStatements.new(
                      "continuation_test/dadadjnor8.F90", 
                      "continuation_test/dadadjnor8_statements.F90", 
                      "continuation_test/dadadjnor8_statements_OK.F90", 
                      "continuation_test/dadadjnor8_unmask.F90", 
                      "continuation_test/dadadjnor8_unmask_OK.F90", 
                      "continuation_test/dadadjnor8_fp.F90", 
                      "continuation_test/dadadjnor8_fp_OK.F90") 
  end

  def test_statements
    @statementss.each do |statements|
      assert(statements.statements_correct?, statements.errorMsg)
    end
  end

  def test_unmask
    @statementss.each do |statements|
      assert(statements.unmask_correct?, statements.errorMsg)
    end
  end

  def test_fp
    @statementss.each do |statements|
      assert(statements.fp_correct?, statements.errorMsg)
    end
  end

  def teardown
  end

end  # class TC_FortranStatements

