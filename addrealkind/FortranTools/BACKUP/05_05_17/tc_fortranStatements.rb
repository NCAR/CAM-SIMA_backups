#!/usr/bin/env ruby

require 'test/unit'
require 'fortranStatements'
    

class TestFortranStatements

  attr_reader :errorMsg

  def initialize(infname, outfname, outfname_OK, unmaskfname, unmaskfname_OK, 
                 fpfname, fpfname_OK, fpusefname, fpusefname_OK, symbol_in, 
                 symbols_OK, symbols_public_OK, sympubops_OK)
    @infname = infname
    @outfname = outfname
    @outfname_OK = outfname_OK
    @unmaskfname = unmaskfname
    @unmaskfname_OK = unmaskfname_OK
    @fpfname = fpfname
    @fpfname_OK = fpfname_OK
    @fpusefname = fpusefname
    @fpusefname_OK = fpusefname_OK
    @symbol = symbol_in
    @symbolsOK = symbols_OK
    @symbolspublicOK = symbols_public_OK
    @sympubopsOK = sympubops_OK
    @statements = FortranStatements.new(infname)
    @errorMsg = ""
  end

  def statements_correct?
    File.open(@outfname, "w") do |aFile|
      aFile.puts(@statements)
    end   # File.open
    statements_OK = IO.readlines(@outfname_OK)
    outstatements = IO.readlines(@outfname)
    ret = resultOK?(statements_OK, outstatements, "statements")
    unless (ret) then
      `xxdiff #{@outfname_OK} #{@outfname}`
    end
    ret
  end

  def unmask_correct?
    File.open(@unmaskfname, "w") do |aFile|
      aFile.puts(@statements.unmask)
    end   # File.open
    unmask_OK = IO.readlines(@unmaskfname_OK)
    unmask    = IO.readlines(@unmaskfname)
    ret = resultOK?(unmask_OK, unmask, "unmask")
    unless (ret) then
      `xxdiff #{@unmaskfname_OK} #{@unmaskfname}`
    end
    ret
  end

  def fp_correct?
    File.open(@fpfname, "w") do |aFile|
      aFile.puts(@statements.addRealKind("fp"))
    end   # File.open
    fp_OK = IO.readlines(@fpfname_OK)
    fp    = IO.readlines(@fpfname)
    ret = resultOK?(fp_OK, fp, "fp")
    unless (ret) then
      `xxdiff #{@fpfname_OK} #{@fpfname}`
    end
    ret
  end

  def fpuse_correct?
    File.open(@fpusefname, "w") do |aFile|
      aFile.puts(@statements.addRealKind("fp","module_fp, only: r8 => wrf_kind_r4"))
    end   # File.open
    fpuse_OK = IO.readlines(@fpusefname_OK)
    fpuse    = IO.readlines(@fpusefname)
    ret = resultOK?(fpuse_OK, fpuse, "fpuse")
    unless (ret) then
      `xxdiff #{@fpusefname_OK} #{@fpusefname}`
    end
    ret
  end

  def findsymbols_correct?
    ret = true
    if (@symbol) then
      symbols = @statements.findSymbols(@symbol, false, false)
      symbols.collect! { |sym| sym.upcase }
      ret = resultOK?(@symbolsOK, symbols.sort.uniq, "find symbols")
    end
    ret
  end

  def findsymbolspublic_correct?
    ret = true
    if (@symbol) then
      symbols = @statements.findSymbols(@symbol, true, false)
      symbols.collect! { |sym| sym.upcase }
      ret = resultOK?(@symbolspublicOK, symbols.sort.uniq, "find public symbols")
    end
    ret
  end

  def findsympubops_correct?
    ret = true
    if (@symbol) then
      symbols = @statements.findSymbols(@symbol, true, true)
      symbols.collect! { |sym| sym.upcase }
      ret = resultOK?(@sympubopsOK, symbols.sort.uniq, "find public symbols and operators")
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
#print "\nDEBUG:  BEGIN EXPECTED -----\n#{expected.join("\n")}\nEND EXPECTED -----\n"
#print "\nDEBUG:  BEGIN   ACTUAL -----\n#{actual.join("\n")}\nEND   ACTUAL -----\n"
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
                      "continuation_test/c_fp_OK.f90", 
                      "continuation_test/c_fpuse.f90", 
                      "continuation_test/c_fpuse_OK.f90", nil, nil, nil, nil) 
    @statementss << TestFortranStatements.new(
                      "continuation_test/tst0.F90", 
                      "continuation_test/tst0_statements.F90", 
                      "continuation_test/tst0_statements_OK.F90", 
                      "continuation_test/tst0_unmask.F90", 
                      "continuation_test/tst0_unmask_OK.F90", 
                      "continuation_test/tst0_fp.F90", 
                      "continuation_test/tst0_fp_OK.F90", 
                      "continuation_test/tst0_fpuse.F90", 
                      "continuation_test/tst0_fpuse_OK.F90", nil, nil, nil, nil) 
    @statementss << TestFortranStatements.new(
                      "continuation_test/tst1.F90", 
                      "continuation_test/tst1_statements.F90", 
                      "continuation_test/tst1_statements_OK.F90", 
                      "continuation_test/tst1_unmask.F90", 
                      "continuation_test/tst1_unmask_OK.F90", 
                      "continuation_test/tst1_fp.F90", 
                      "continuation_test/tst1_fp_OK.F90", 
                      "continuation_test/tst1_fpuse.F90", 
                      "continuation_test/tst1_fpuse_OK.F90", 
                      "fake", 
                      ["FAKE1", "FAKE11", "FAKE2", "FAKE21", "FAKEO", "FAKE_NOT_IN_MODULE"],
                      ["FAKE1", "FAKE11"],
                      ["ASSIGNMENT(=)", "FAKE1", "FAKE11", "OPERATOR(+)", "OPERATOR(.EQ.)"] )
    @statementss << TestFortranStatements.new(
                      "continuation_test/tst_fp.F90", 
                      "continuation_test/tst_fp_statements.F90", 
                      "continuation_test/tst_fp_statements_OK.F90", 
                      "continuation_test/tst_fp_unmask.F90", 
                      "continuation_test/tst_fp_unmask_OK.F90", 
                      "continuation_test/tst_fp_fp.F90", 
                      "continuation_test/tst_fp_fp_OK.F90", 
                      "continuation_test/tst_fp_fpuse.F90", 
                      "continuation_test/tst_fp_fpuse_OK.F90", 
                      "WRF_", 
                      ["WRF_COMPLEX", "WRF_KIND_R2", "WRF_KIND_RN", "WRF_REAL"],
                      [],
                      [] ) 
    @statementss << TestFortranStatements.new(
                      "continuation_test/dadadj.F90", 
                      "continuation_test/dadadj_statements.F90", 
                      "continuation_test/dadadj_statements_OK.F90", 
                      "continuation_test/dadadj_unmask.F90", 
                      "continuation_test/dadadj_unmask_OK.F90", 
                      "continuation_test/dadadj_fp.F90", 
                      "continuation_test/dadadj_fp_OK.F90", 
                      "continuation_test/dadadj_fpuse.F90", 
                      "continuation_test/dadadj_fpuse_OK.F90", nil, nil, nil, nil) 
    @statementss << TestFortranStatements.new(
                      "continuation_test/dadadjnor8.F90", 
                      "continuation_test/dadadjnor8_statements.F90", 
                      "continuation_test/dadadjnor8_statements_OK.F90", 
                      "continuation_test/dadadjnor8_unmask.F90", 
                      "continuation_test/dadadjnor8_unmask_OK.F90", 
                      "continuation_test/dadadjnor8_fp.F90", 
                      "continuation_test/dadadjnor8_fp_OK.F90", 
                      "continuation_test/dadadjnor8_fpuse.F90", 
                      "continuation_test/dadadjnor8_fpuse_OK.F90", nil, nil, nil, nil) 
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

  def test_fpuse
    @statementss.each do |statements|
      assert(statements.fpuse_correct?, statements.errorMsg)
    end
  end

  def test_findsymbols
    @statementss.each do |statements|
      assert(statements.findsymbols_correct?, statements.errorMsg)
      assert(statements.findsymbolspublic_correct?, statements.errorMsg)
      assert(statements.findsympubops_correct?, statements.errorMsg)
    end
  end

  def teardown
  end

end  # class TC_FortranStatements

