#!/usr/bin/env ruby

require 'maskedString'
    

print "Testing <<0123456789>> with []\n"
ms = MaskedString.new("0123456789", [])
print "base STRING = <<#{ms}>>\n"
print "MASKED STRING = <<#{ms.get_masked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "UNMASKED STRING = <<#{ms.get_unmasked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "\n"

print "Testing <<0123456789>> with [ (0..9) ]\n"
ms = MaskedString.new("0123456789", [ (0..9) ])
print "base STRING = <<#{ms}>>\n"
print "MASKED STRING = <<#{ms.get_masked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "UNMASKED STRING = <<#{ms.get_unmasked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "\n"

print "Testing <<0123456789>> with [ (1..3), (6..8) ]\n"
ms = MaskedString.new("0123456789", [ (1..3), (6..8) ])
print "base STRING = <<#{ms}>>\n"
print "MASKED STRING = <<#{ms.get_masked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "UNMASKED STRING = <<#{ms.get_unmasked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "\n"

print "Testing <<0123456789>> with [ (1..3), (4..8) ]\n"
ms = MaskedString.new("0123456789", [ (1..3), (4..8) ])
print "base STRING = <<#{ms}>>\n"
print "MASKED STRING = <<#{ms.get_masked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "UNMASKED STRING = <<#{ms.get_unmasked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "\n"

print "Testing <<0123456789>> with [ (1..1), (3..5) ]\n"
ms = MaskedString.new("0123456789", [ (1..1), (3..5) ])
print "base STRING = <<#{ms}>>\n"
print "MASKED STRING = <<#{ms.get_masked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "UNMASKED STRING = <<#{ms.get_unmasked}>>\n"
print "base STRING = <<#{ms}>>\n"
print "\n"

