#!/usr/bin/env ruby

require 'test/unit'
require 'fortranLine'
require 'maskedString'
    

class TestFortranLine

  attr_accessor :fortranLine
  attr_reader :errorMsg

  def initialize(str, indx, to_s_output, strippedLine, 
                 unmaskedLine, continued, prev_was_contd, 
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
    resultOK?(@unmasked, @fortranLine.get_masked_line.get_unmasked, 
              "get_masked_line.get_unmasked")
  end

  def continued_correct?
    resultOK?(@is_continued, @fortranLine.is_continued?, 
              "is_continued?")
  end

  def contd_string_delimiter
    resultOK?(@string_delimiter_out, @fortranLine.contd_string_delimiter, 
              "contd_string_delimiter")
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
                                  false, 
                                  false, 
                                  nil, nil)
    @lines << TestFortranLine.new("\n", 2,
                              "2:  ",
                                  "", 
                                  "", 
                                  false, 
                                  false, 
                                  nil, nil)
    @lines << TestFortranLine.new("  x = &\n", 3,
                              "3:    x = &",
                                  "  x =", 
                                  "  x = M", 
                                  true , 
                                  false, 
                                  nil, nil)
    @lines << TestFortranLine.new("  y\n", 4,
                              "4:    y",
                                  "  y", 
                                  "  y", 
                                  false, 
                                  true , 
                                  nil, nil)
    @lines << TestFortranLine.new("  x = &  ! a comment\n", 5,
                              "5:    x = &  ! a comment",
                                  "  x =", 
                                  "  x = MMMMMMMMMMMMMM", 
                                  true , 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  y\n", 6,
                              "6:    y",
                                  "  y", 
                                  "  y", 
                                  false, 
                                  true ,
                                  nil, nil)
    @lines << TestFortranLine.new("  x = y  !&  ! a comment\n", 7,
                              "7:    x = y  !&  ! a comment",
                                  "  x = y", 
                                  "  x = y  MMMMMMMMMMMMMMM", 
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  print *,' ! not a comment'\n", 8,
                              "8:    print *,' ! not a comment'",
                                  "  print *,' ! not a comment'", 
                                  "  print *,MMMMMMMMMMMMMMMMMM", 
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  print *,' & not a continuation'\n", 9,
                              "9:    print *,' & not a continuation'",
                                  "  print *,' & not a continuation'", 
                                  "  print *,MMMMMMMMMMMMMMMMMMMMMMM", 
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  print *,' & a continuation2', &  \n", 10,
                             "10:    print *,' & a continuation2', &  ",
                                  "  print *,' & a continuation2',", 
                                  "  print *,MMMMMMMMMMMMMMMMMMMM, MMM", 
                                  true , 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("' another',' continuation', &  \n", 11,
                             "11:  ' another',' continuation', &  ",
                                  "' another',' continuation',", 
                                  "MMMMMMMMMM,MMMMMMMMMMMMMMM, MMM", 
                                  true , 
                                  true ,
                                  nil, nil)
    @lines << TestFortranLine.new("&\n", 12,
                             "12:  &",
                                  "", 
                                  "M", 
                                  true , 
                                  true ,
                                  nil, nil)
    @lines << TestFortranLine.new("' not another continuation!'  ! hah!\n", 13,
                             "13:  ' not another continuation!'  ! hah!",
                                  "' not another continuation!'", 
                                  "MMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMM", 
                                  false, 
                                  true ,
                                  nil, nil)
    @lines << TestFortranLine.new("  !just a comment &\n", 14,
                             "14:    !just a comment &",
                                  "", 
                                  "  MMMMMMMMMMMMMMMMM",
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("\n", 15,
                             "15:  ",
                                  "", 
                                  "", 
                                  false, 
                                  false,
                                  nil, nil)
    @lines << TestFortranLine.new("  lawyers = 'Jones & Clay & &\n", 16,
                             "16:    lawyers = 'Jones & Clay & &",
                                  "  lawyers = 'Jones & Clay & ", 
                                  "  lawyers = MMMMMMMMMMMMMMMMM", 
                                  true , 
                                  false, 
                                  nil, "'")
    @lines << TestFortranLine.new("  &Davis'\n", 17,
                             "17:    &Davis'",
                                  "Davis'", 
                                  "MMMMMMMMM", 
                                  false, 
                                  true , 
                                  "'", nil )
    @lines << TestFortranLine.new("  lawyers = 'Jones! &! Clay! &! &\n", 18,
                             "18:    lawyers = 'Jones! &! Clay! &! &",
                                  "  lawyers = 'Jones! &! Clay! &! ", 
                                  "  lawyers = MMMMMMMMMMMMMMMMMMMMM", 
                                  true , 
                                  false, 
                                  nil, "'")
    @lines << TestFortranLine.new("  &Davis!'\n", 19,
                             "19:    &Davis!'",
                                  "Davis!'", 
                                  "MMMMMMMMMM", 
                                  false, 
                                  true , 
                                  "'", nil )
    @lines << TestFortranLine.new(
                "  print *,'LAWYERS_13 = <<',trim(lawyers),\">&  \n", 20,
           "20:    print *,'LAWYERS_13 = <<',trim(lawyers),\">&  ",
                "  print *,'LAWYERS_13 = <<',trim(lawyers),\">", 
                "  print *,MMMMMMMMMMMMMMMMM,trim(lawyers),MMMMM", 
                true , 
                false, 
                nil, "\"")
    @lines << TestFortranLine.new("  &>\"\n", 21,
                             "21:    &>\"",
                                  ">\"", 
                                  "MMMMM", 
                                  false, 
                                  true , 
                                  "\"", nil )
    @lines << TestFortranLine.new(
                "  lawyers = 'Jones & ''Clay'&  ! a comment\n", 22,
           "22:    lawyers = 'Jones & ''Clay'&  ! a comment",
                "  lawyers = 'Jones & ''Clay'", 
                "  lawyers = MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM", 
                true, 
                false, 
                nil, nil)
    @lines << TestFortranLine.new(
                "  &' & Davis'  ! another comment\n", 23,
           "23:    &' & Davis'  ! another comment",
                   "' & Davis'", 
                "MMMMMMMMMMMMM  MMMMMMMMMMMMMMMMM", 
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

