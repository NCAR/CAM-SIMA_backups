#!/bin/csh
#
# Set up and run simple test of addRealKind.rb
#

set origdir = continuation_test
set testdir = TESTDIR_addRealKind
\rm -fR ${testdir}
mkdir ${testdir}
\cp ${origdir}/*.[fF]* ${testdir}
\rm -f ${testdir}/*unmask*
\rm -f ${testdir}/*statement*
\rm -f ${testdir}/*OK*
\rm -f ${testdir}/*_fp.*
\cp continuation_test/tst_fp.F90 ${testdir}

addRealKind.rb -d ${testdir}

mv ${testdir}/c.f90 ${testdir}/c_fp.f90
mv ${testdir}/dadadj.F90 ${testdir}/dadadj_fp.F90
mv ${testdir}/dadadjnor8.F90 ${testdir}/dadadjnor8_fp.F90
mv ${testdir}/tst0.F90 ${testdir}/tst0_fp.F90
mv ${testdir}/tst1.F90 ${testdir}/tst1_fp.F90
mv ${testdir}/tst_fp.F90 ${testdir}/tst_fp_fp.F90

diffcvs ${origdir} ${testdir}

