#!/usr/bin/env ruby

require 'test/unit'
require 'fortranLine'
    

class TestFortranLine

  attr_accessor :fortranLine
  attr_reader :errorMsg

  def initialize(str, indx, to_s_output, strippedLine, 
                 unmaskedLine, 
                 gsubregexp, gsubrepl, gsubLine_OK, 
                 continued, prev_was_contd, 
                 string_delimiter_in, string_delimiter_out)
    @line = str.chomp
    @lineNumber = indx
    @to_s_out = to_s_output
    @stripped = strippedLine
    @unmasked = unmaskedLine
    @is_continued = continued
    @string_delimiter_in = string_delimiter_in
    @string_delimiter_out = string_delimiter_out
    @fortranLine = FortranLine.new(str, indx, 
                                   prev_was_contd, string_delimiter_in)
    @gsub_regexp = gsubregexp
    @gsub_repl = gsubrepl
    @gsub_line_OK = gsubLine_OK
    @errorMsg = ""
  end

  def line_correct?
    resultOK?(@line, @fortranLine.line, 
              "line")
  end

  def lineNumber_correct?
    resultOK?(@lineNumber,  @fortranLine.lineNumber, 
              "lineNumber")
  end

  def to_s_correct?
    resultOK?(@to_s_out, @fortranLine.to_s, 
              "to_s")
  end

  def stripped_correct?
    resultOK?(@stripped, @fortranLine.line_stripped, 
              "line_stripped")
  end

  def unmasked_correct?
    resultOK?(@unmasked, @fortranLine.get_unmasked, 
              "get_unmasked")
  end

  def gsub_correct?
    tmpFortranLine = @fortranLine.deepCopy
    tmpFortranLine.each_unmasked_op! do |substr|
      substr.gsub!(@gsub_regexp,@gsub_repl)
    end
    result = tmpFortranLine.line
    resultOK?(@gsub_line_OK, tmpFortranLine.line, 
              "gsub!(#{@gsub_regexp},#{@gsub_repl})")
  end

  def continued_correct?
    resultOK?(@is_continued, @fortranLine.is_continued?, 
              "is_continued?")
  end

  def contd_string_delimiter
    resultOK?(@string_delimiter_out, @fortranLine.contd_string_delimiter, 
              "contd_string_delimiter")
  end

  def deepCopy_correct?
    flCopy = @fortranLine.deepCopy
    @errorMsg = ""
    ret1 = resultOK?(@fortranLine, flCopy, "DEEP COPY")
    ret2 = resultOK?(true, (@fortranLine.object_id != flCopy.object_id), 
                     "OBJECT ID")
    ret = ret1 and ret2
  end

  def resultOK?(expected, actual, errorHeader)
    ret = (expected == actual)
    @errorMsg = "NO ERROR\n"
    unless ret then
      @errorMsg =  "#{errorHeader}\n"
      @errorMsg << "EXPECTED:  <#{expected}>\n"
      @errorMsg << "GOT:       <#{actual}>\n"
      @errorMsg << "LINE WAS:  <#{@line}>\n"
    end
    ret
  end

end   # class TestFortranLine



class TC_FortranLine < Test::Unit::TestCase

  def setup
    @lines = []
    @lines << TestFortranLine.new("  program xyz\n", 1,
                              "1:    program xyz",
                                  "  program xyz", 
                                  "  program xyz", 
                /rogra/, "ROGRA", "  pROGRAm xyz", 
                                  false, 
                                  false, 
                                  nil, nil)
    @lines << TestFortranLine.new("\n", 2,
                              "2:  ",
                                  "", 
                                  "", 
                /rogra/, "ROGRA", "", 
                                  false, 
                                  false, 
                                  nil, nil)
    @lines << TestFortranLine.new("  x = &\n", 3,
                              "3:    x = &",
                                  "  x =", 
                                  "  x = M", 
                        /x/, "X", "  X = &", 
                                  true , 
                                  false, 
                                  nil, nil)
    @lines << TestFortranLine.new("  y\n", 4,
                              "4:    y",
                                  "  y", 
                                  "  y", 
                    /abc/, "xyz", "  y", 
                                  false, 
                                  true , 
                                  nil, nil)
    @lines << TestFortranLine.new("  x = &  ! a comment\n", 5,
                              "5:    x = &  ! a comment",
                                  "  x =", 
                                  "  x = MMMMMMMMMMMMMM", 
             /comment/, "COMMENT","  x = &  ! a comment", 
                                  true , 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  y\n", 6,
                              "6:    y",
                                  "  y", 
                                  "  y", 
                    /abc/, "xyz", "  y", 
                                  false, 
                                  true ,
                                  nil, nil)
    @lines << TestFortranLine.new("  x = y  !&  ! a comment\n", 7,
                              "7:    x = y  !&  ! a comment",
                                  "  x = y", 
                                  "  x = y  MMMMMMMMMMMMMMM", 
                      /x|y/, "XY","  XY = XY  !&  ! a comment", 
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  print *,' ! not a comment'\n", 8,
                              "8:    print *,' ! not a comment'",
                                  "  print *,' ! not a comment'", 
                                  "  print *,MMMMMMMMMMMMMMMMMM", 
                    /not/, "NOT", "  print *,' ! not a comment'", 
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  print *,' & not a continuation'\n", 9,
                              "9:    print *,' & not a continuation'",
                                  "  print *,' & not a continuation'", 
                                  "  print *,MMMMMMMMMMMMMMMMMMMMMMM", 
              /contin/, "CONTIN", "  print *,' & not a continuation'", 
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  print *,' & a continuation2', &  \n", 10,
                             "10:    print *,' & a continuation2', &  ",
                                  "  print *,' & a continuation2',", 
                                  "  print *,MMMMMMMMMMMMMMMMMMMM, MMM", 
              /contin/, "CONTIN", "  print *,' & a continuation2', &  ", 
                                  true , 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("' another',' continuation', &  \n", 11,
                             "11:  ' another',' continuation', &  ",
                                  "' another',' continuation',", 
                                  "MMMMMMMMMM,MMMMMMMMMMMMMMM, MMM", 
            /another/, "ANOTHER", "' another',' continuation', &  ", 
                                  true , 
                                  true ,
                                  nil, nil)
    @lines << TestFortranLine.new("&\n", 12,
                             "12:  &",
                                  "", 
                                  "M", 
                        /x/, "y", "&", 
                                  true , 
                                  true ,
                                  nil, nil)
    @lines << TestFortranLine.new("' not another continuation!'  ! hah!\n", 13,
                             "13:  ' not another continuation!'  ! hah!",
                                  "' not another continuation!'", 
                                  "MMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMM", 
                    /hah/, "HAH", "' not another continuation!'  ! hah!", 
                                  false, 
                                  true ,
                                  nil, nil)
    @lines << TestFortranLine.new("  !just a comment &\n", 14,
                             "14:    !just a comment &",
                                  "", 
                                  "  MMMMMMMMMMMMMMMMM",
                  /just/, "JUST", "  !just a comment &", 
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("\n", 15,
                             "15:  ",
                                  "", 
                                  "", 
               /nada/, "nothing", "", 
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  lawyers = 'Jones & Clay & &\n", 16,
                             "16:    lawyers = 'Jones & Clay & &",
                                  "  lawyers = 'Jones & Clay & ", 
                                  "  lawyers = MMMMMMMMMMMMMMMMM", 
              /lawyers/, "STOOB", "  STOOB = 'Jones & Clay & &", 
                                  true , 
                                  false, 
                                  nil, "'")
    @lines << TestFortranLine.new("  &Davis'\n", 17,
                             "17:    &Davis'",
                                  "Davis'", 
                                  "MMMMMMMMM", 
                /Davis/, "Davey", "  &Davis'", 
                                  false, 
                                  true , 
                                  "'", nil )
    @lines << TestFortranLine.new("  lawyers = 'Jones! &! Clay! &! &\n", 18,
                             "18:    lawyers = 'Jones! &! Clay! &! &",
                                  "  lawyers = 'Jones! &! Clay! &! ", 
                                  "  lawyers = MMMMMMMMMMMMMMMMMMMMM", 
                   /Clay/, "rib", "  lawyers = 'Jones! &! Clay! &! &", 
                                  true , 
                                  false, 
                                  nil, "'")
    @lines << TestFortranLine.new("  &Davis!'\n", 19,
                             "19:    &Davis!'",
                                  "Davis!'", 
                                  "MMMMMMMMMM", 
            /Davis/, "Jefferson", "  &Davis!'", 
                                  false, 
                                  true , 
                                  "'", nil )
    @lines << TestFortranLine.new(
                "  print *,'LAWYERS_13 = <<',trim(lawyers),\">&  \n", 20,
           "20:    print *,'LAWYERS_13 = <<',trim(lawyers),\">&  ",
                "  print *,'LAWYERS_13 = <<',trim(lawyers),\">", 
                "  print *,MMMMMMMMMMMMMMMMM,trim(lawyers),MMMMM", 
/trim/, "TRIM", "  print *,'LAWYERS_13 = <<',TRIM(lawyers),\">&  ", 
                true , 
                false, 
                nil, "\"")
    @lines << TestFortranLine.new("  &>\"\n", 21,
                             "21:    &>\"",
                                  ">\"", 
                                  "MMMMM", 
                      /  /, "AA", "  &>\"", 
                                  false, 
                                  true , 
                                  "\"", nil )
    @lines << TestFortranLine.new(
                "  lawyers = 'Jones & ''Clay'&  ! a comment\n", 22,
           "22:    lawyers = 'Jones & ''Clay'&  ! a comment",
                "  lawyers = 'Jones & ''Clay'", 
                "  lawyers = MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM", 
/lawyers/, "Larry, Moe, and Curley", "  Larry, Moe, and Curley = 'Jones & ''Clay'&  ! a comment", 
                true, 
                false, 
                nil, nil)
    @lines << TestFortranLine.new(
                "  &' & Davis'  ! another comment\n", 23,
           "23:    &' & Davis'  ! another comment",
                   "' & Davis'", 
                "MMMMMMMMMMMMM  MMMMMMMMMMMMMMMMM", 
/another/, "X", "  &' & Davis'  ! another comment", 
                false, 
                true , 
                nil, nil )
# $$$here...  add "&&\n"
# $$$here...  add "& &' &\n"
# $$$here...  add " x = &\n!blah\n y\n"
# $$$here...  add "  !just a comment &\n"
# $$$here...  add " &  !just a comment &\n"
# $$$here...  add " !just 'comment's'\n"
# $$$here...  add "'Jones & ''Clay'& ! comment\n  &' & Davis' ! comment\n"
    @lines << TestFortranLine.new("  end\n", 100,
                                  "100:    end",
                                  "  end", 
                                  "  end", 
           /(END)/i, "THE END", "  THE END", 
                                  false, 
                                  false, 
                                  nil, nil)
  end

  def test_line
    @lines.each do |line|
      assert(line.line_correct?, line.errorMsg)
    end
  end

  def test_lineNumber
    @lines.each do |line|
      assert(line.lineNumber_correct?, line.errorMsg)
    end
  end

  def test_to_s
    @lines.each do |line|
      assert(line.to_s_correct?, line.errorMsg)
    end
  end

  def test_line_stripped
    @lines.each do |line|
      assert(line.stripped_correct?, line.errorMsg)
    end
  end

  def test_line_unmasked
    @lines.each do |line|
      assert(line.unmasked_correct?, line.errorMsg)
    end
  end

  def test_line_gsub
    @lines.each do |line|
      assert(line.gsub_correct?, line.errorMsg)
    end
  end

  def test_line_deepCopy
    @lines.each do |line|
      assert(line.deepCopy_correct?, line.errorMsg)
    end
  end

  def test_is_continued
    @lines.each do |line|
      assert(line.continued_correct?, line.errorMsg)
    end
  end

  def test_contd_string_delimiter
    @lines.each do |line|
      assert(line.contd_string_delimiter, line.errorMsg)
    end
  end

  def teardown
  end

end  # class TC_FortranLine

