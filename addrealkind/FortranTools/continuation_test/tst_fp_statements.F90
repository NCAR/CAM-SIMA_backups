
program tst_fp

   implicit none

   integer,parameter :: R8 = selected_real_kind(12)
   integer,parameter :: FP = selected_real_kind( 6)
   INTEGER, PARAMETER :: WRF_KIND_RN = KIND(1.0)
   INTEGER, PARAMETER :: WRF_KIND_R2 = kind (  2.0  )


   REAL(r8) :: already_got_kind, xr8, blahd, blahd2
   real :: need_a_kind, xfp, blahr, a3d0var, a3e0var, a3d0, a3e0
   COMPLEX(r8) :: calready_got_kind, cxr8
   complex :: cneed_a_kind, cxfp
   integer :: testrealthing
   integer :: testcomplexthing
   real*8 :: explicitr8
   real*4 :: explicitr4
   complex*16 :: explicitc16
   complex*8 :: explicitc8
   integer :: wrf_real
   integer :: wrf_complex
   real::realvar


   REAL, PARAMETER :: r1 = REAL(1)
   REAL(r8), PARAMETER :: r81 = REAL(1,r8)

   wrf_complex = 1
   testcomplexthing = wrf_complex
   wrf_real = 1
   testrealthing = wrf_real
   wrf_real=testrealthing
   wrf_complex=testcomplexthing
   realvar=realvar+realvar

   print *,'r1 = ',r1
   print *,'r81 = ',r81

   xfp = 1.0
   xfp = .2
   xfp = 3.
   xfp = 4E0
   xfp = 5E-1
   xfp = 6.0E+2
   xfp = .7E-3
   xfp = 8.E+4
   xfp = 9.0E5
   xfp = .10E6
   xfp = 11.E7
   xfp = -1.0
   xfp = +.2
   xfp = -3.
   xfp = +4e0
   xfp = -5e+1
   xfp = -6.0e+2
   xfp = -.7e+3
   xfp = -8.e+4
   xfp = -9.0e5
   xfp = +.10e6
   xfp = -11.e7

   xr8 = 1.0_r8
   xr8 = .2_r8
   xr8 = 3._r8
   xr8 = 4E0_r8
   xr8 = 5E-1_r8
   xr8 = 6.0E+2_r8
   xr8 = .7E-3_r8
   xr8 = 8.E+4_r8
   xr8 = 9.0E5_r8
   xr8 = .10E6_r8
   xr8 = 11.E7_r8
   xr8 = -1.0_r8
   xr8 = +.2_r8
   xr8 = -3._r8
   xr8 = +4e0_r8
   xr8 = -5e+1_r8
   xr8 = -6.0e+2_r8
   xr8 = -.7e+3_r8
   xr8 = -8.e+4_r8
   xr8 = -9.0e5_r8
   xr8 = +.10e6_r8
   xr8 = -11.e7_r8

   blahd = 1.0d0
   blahd2 = 2.0d0
   blahd = -1.0D0

 real: IF ( xfp.lt.1 ) THEN
     print *,'xfp.lt.1'
   ENDIF real
   IF ( xfp.lt.1. ) THEN
     print *,'xfp.lt.1.'
   ENDIF
complex: IF ( 1.lt.xfp ) THEN
     print *,'1.lt.xfp'
   ENDIF complex
CMPLX: IF ( 1.lt.xfp ) THEN
     print *,'1.lt.xfp'
   ENDIF CMPLX
   IF ( 1..lt.xfp ) THEN
     print *,'1..lt.xfp.'
   ENDIF

   blahr = REAL(blahd)
   blahr = REAL(                 blahd)
   blahr = REAL(                 blahd,                 fp)

   blahr = REAL(blahd + REAL(blahd2))
   blahr = REAL(blahd + REAL(blahd2)) + REAL(blahd + REAL(blahd2))
   blahr = 1.0 + REAL(blahd + REAL(blahd2)) + 2.0
   blahr = REAL(blahd + REAL(blahd2), r8)
   blahr = REAL(blahd + REAL(blahd2, r8))
   blahr = REAL(blahd + REAL(blahd2, r8), r8)
   blahr = REAL(blahd +                REAL(blahd2))
   blahr = REAL(blahd +             REAL(blahd2)) +               REAL(blahd + REAL(                 blahd2)                 )
   blahr = REAL(REAL(blahd + REAL(blahd2)) +             REAL(INT(REAL(blahd + REAL(blahd2)))))

   blahr = a3d0var
   blahr = a3e0var

800   format(' lat,lon = ',2i5,', zeps= ',e9.4)

   blahr=a3d0var
   blahr=a3e0var

   blahr=a3d0
   blahr=a3e0

end program tst_fp
