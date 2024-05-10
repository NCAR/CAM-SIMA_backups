
program tst_fp
!-----------------------------------------------------------------------
   implicit none

   integer,parameter :: R8 = selected_real_kind(12)   ! 8 byte real
   integer,parameter :: FP = selected_real_kind( 6)   ! 4 byte real
   INTEGER, PARAMETER :: WRF_COMP_KIND_RN = KIND(1.0)      ! native real, leave as-is
   INTEGER, PARAMETER :: WRF_COMP_KIND_R2 = kind (  2.0  )  ! native real, leave as-is


   REAL(r8) :: already_got_kind, xr8, blahd, blahd2
   real :: need_a_kind, xfp, blahr, a3d0var, a3e0var, a3d0, a3e0
   COMPLEX(r8) :: calready_got_kind, cxr8
   complex :: cneed_a_kind, cxfp
   integer :: testrealthing                 ! leave as-is
   integer :: testcomplexthing              ! leave as-is
   real*8 :: explicitr8                     ! leave as-is
   real*4 :: explicitr4                     ! leave as-is
   complex*16 :: explicitc16                ! leave as-is
   complex*8 :: explicitc8                  ! leave as-is
   integer :: WRF_COMP_real                      ! leave as-is
   integer :: WRF_COMP_complex                   ! leave as-is
   real::realvar                            ! add kind

   ! combination of REAL declaration and REAL intrinsic
   REAL, PARAMETER :: r1 = REAL(1)          ! need two kinds
   REAL(r8), PARAMETER :: r81 = REAL(1,r8)  ! leave as-is

   WRF_COMP_complex = 1                          ! leave as-is
   testcomplexthing = WRF_COMP_complex           ! leave as-is
   WRF_COMP_real = 1                             ! leave as-is
   testrealthing = WRF_COMP_real                 ! leave as-is
   WRF_COMP_real=testrealthing                   ! leave as-is
   WRF_COMP_complex=testcomplexthing             ! leave as-is
   realvar=realvar+realvar                  ! leave as-is

   print *,'r1 = ',r1
   print *,'r81 = ',r81

   xfp = 1.0       ! need a kind
   xfp = .2        ! need a kind
   xfp = 3.        ! need a kind
   xfp = 4E0       ! need a kind
   xfp = 5E-1      ! need a kind
   xfp = 6.0E+2    ! need a kind
   xfp = .7E-3     ! need a kind
   xfp = 8.E+4     ! need a kind
   xfp = 9.0E5     ! need a kind
   xfp = .10E6     ! need a kind
   xfp = 11.E7     ! need a kind
   xfp = -1.0      ! need a kind
   xfp = +.2       ! need a kind
   xfp = -3.       ! need a kind
   xfp = +4e0      ! need a kind
   xfp = -5e+1     ! need a kind
   xfp = -6.0e+2   ! need a kind
   xfp = -.7e+3    ! need a kind
   xfp = -8.e+4    ! need a kind
   xfp = -9.0e5    ! need a kind
   xfp = +.10e6    ! need a kind
   xfp = -11.e7    ! need a kind

   xr8 = 1.0_r8    ! do not need a kind
   xr8 = .2_r8     ! do not need a kind
   xr8 = 3._r8     ! do not need a kind
   xr8 = 4E0_r8    ! do not need a kind
   xr8 = 5E-1_r8   ! do not need a kind
   xr8 = 6.0E+2_r8 ! do not need a kind
   xr8 = .7E-3_r8  ! do not need a kind
   xr8 = 8.E+4_r8  ! do not need a kind
   xr8 = 9.0E5_r8  ! do not need a kind
   xr8 = .10E6_r8  ! do not need a kind
   xr8 = 11.E7_r8  ! do not need a kind
   xr8 = -1.0_r8   ! do not need a kind
   xr8 = +.2_r8    ! do not need a kind
   xr8 = -3._r8    ! do not need a kind
   xr8 = +4e0_r8   ! do not need a kind
   xr8 = -5e+1_r8  ! do not need a kind
   xr8 = -6.0e+2_r8! do not need a kind
   xr8 = -.7e+3_r8 ! do not need a kind
   xr8 = -8.e+4_r8 ! do not need a kind
   xr8 = -9.0e5_r8 ! do not need a kind
   xr8 = +.10e6_r8 ! do not need a kind
   xr8 = -11.e7_r8 ! do not need a kind

   blahd = 1.0d0    ! kind specified in exponent, leave kind as-is
   blahd2 = 2.0d0   ! kind specified in exponent, leave kind as-is
   blahd = -1.0D0   ! kind specified in exponent, leave kind as-is

 real: IF ( xfp.lt.1 ) THEN  ! leave as-is
     print *,'xfp.lt.1'  ! leave as-is
   ENDIF real
   IF ( xfp.lt.1. ) THEN  ! need a kind
     print *,'xfp.lt.1.'  ! leave as-is
   ENDIF
complex: IF ( 1.lt.xfp ) THEN  ! leave as-is
     print *,'1.lt.xfp'  ! leave as-is
   ENDIF complex
CMPLX: IF ( 1.lt.xfp ) THEN  ! leave as-is
     print *,'1.lt.xfp'  ! leave as-is
   ENDIF CMPLX
   IF ( 1..lt.xfp ) THEN  ! need a kind
     print *,'1..lt.xfp.' ! leave as-is
   ENDIF

   blahr = REAL(blahd) ! add kind as second argument to intrinsic cast function
   blahr = REAL( &
                 blahd) ! add kind as second argument to intrinsic cast function
   blahr = REAL( &
                 blahd, &
                 fp) ! leave as-is
   ! add kinds as second arguments to intrinsic cast functions to some of the following
   blahr = REAL(blahd + REAL(blahd2))
   blahr = REAL(blahd + REAL(blahd2)) + REAL(blahd + REAL(blahd2))
   blahr = 1.0 + REAL(blahd + REAL(blahd2)) + 2.0
   blahr = REAL(blahd + REAL(blahd2), r8)
   blahr = REAL(blahd + REAL(blahd2, r8))
   blahr = REAL(blahd + REAL(blahd2, r8), r8)
   blahr = REAL(blahd + &
                REAL(blahd2))
   blahr = REAL(blahd + &              ! this is just plain mean
             REAL(blahd2)) + &
               REAL(blahd + REAL(&
                 blahd2) &
                 )
   blahr = REAL(REAL(blahd + REAL(blahd2)) + &       ! OK enough already
             REAL(INT(REAL(blahd + REAL(blahd2)))))

   blahr = a3d0var  ! leave as-is
   blahr = a3e0var  ! leave as-is

800   format(' lat,lon = ',2i5,', zeps= ',e9.4)   ! do not need a kind

   blahr=a3d0var    ! leave as-is
   blahr=a3e0var    ! leave as-is

   blahr=a3d0    ! leave as-is
   blahr=a3e0    ! leave as-is

end program tst_fp

