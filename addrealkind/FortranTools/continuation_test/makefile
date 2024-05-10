
COMP=pgf90

all:  c.exe c_statements.exe tst_fp.exe tst_fp_fp.exe tst1_fpuse.o

c.exe: c.f90
	$(COMP) -o c.exe c.f90

c_statements.exe: c_statements.f90
	$(COMP) -o c_statements.exe c_statements.f90

tst_fp.exe: tst_fp.F90
	$(COMP) -o tst_fp.exe tst_fp.F90

tst_fp_fp.exe: tst_fp_fp.F90
	$(COMP) -o tst_fp_fp.exe tst_fp_fp.F90

tst1_fpuse.o: tst1_fpuse.F90
	$(COMP) -c tst1_fpuse.F90

clean:
	\rm -f *.exe *.o *.mod

