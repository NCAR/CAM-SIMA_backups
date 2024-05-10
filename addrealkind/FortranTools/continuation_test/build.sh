#!/bin/sh
echo "pgf90 -o c.exe c.f90"
pgf90 -o c.exe c.f90

echo "pgf90 -o c_statements.exe c_statements.f90"
pgf90 -o c_statements.exe c_statements.f90

echo "pgf90 -o tst_fp.exe tst_fp.F90"
pgf90 -o tst_fp.exe tst_fp.F90

echo "pgf90 -o tst_fp_fp.exe tst_fp_fp.F90"
pgf90 -o tst_fp_fp.exe tst_fp_fp.F90

echo "pgf90 -c tst1_fpuse.F90"
pgf90 -c tst1_fpuse.F90

