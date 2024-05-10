
subroutine tst_fp
!-----------------------------------------------------------------------
   use shr_kind_mod, only: fp => shr_kind_r8
   use blah
   implicit none
   real(r8) :: already_got_kind, xr8
   real :: need_a_kind, xfp

   xfp = 1.0       ! need a kind
   xfp = .2        ! need a kind
   xfp = 3.        ! need a kind
   xfp = 4E0       ! need a kind
   xfp = 5E-1      ! need a kind
   xfp = 6.0E-2    ! need a kind
   xfp = .7E-3     ! need a kind
   xfp = 8.E-4     ! need a kind
   xfp = 9.0E5     ! need a kind
   xfp = .10E6     ! need a kind
   xfp = 11.E7     ! need a kind
   xfp = -1.0      ! need a kind
   xfp = -.2       ! need a kind
   xfp = -3.       ! need a kind
   xfp = -4e0      ! need a kind
   xfp = -5e-1     ! need a kind
   xfp = -6.0e-2   ! need a kind
   xfp = -.7e-3    ! need a kind
   xfp = -8.e-4    ! need a kind
   xfp = -9.0e5    ! need a kind
   xfp = -.10e6    ! need a kind
   xfp = -11.e7    ! need a kind

   xr8 = 1.0_r8    ! do not need a kind
   xr8 = .2_r8     ! do not need a kind
   xr8 = 3._r8     ! do not need a kind
   xr8 = 4E0_r8    ! do not need a kind
   xr8 = 5E-1_r8   ! do not need a kind
   xr8 = 6.0E-2_r8 ! do not need a kind
   xr8 = .7E-3_r8  ! do not need a kind
   xr8 = 8.E-4_r8  ! do not need a kind
   xr8 = 9.0E5_r8  ! do not need a kind
   xr8 = .10E6_r8  ! do not need a kind
   xr8 = 11.E7_r8  ! do not need a kind
   xr8 = -1.0_r8   ! do not need a kind
   xr8 = -.2_r8    ! do not need a kind
   xr8 = -3._r8    ! do not need a kind
   xr8 = -4e0_r8   ! do not need a kind
   xr8 = -5e-1_r8  ! do not need a kind
   xr8 = -6.0e-2_r8! do not need a kind
   xr8 = -.7e-3_r8 ! do not need a kind
   xr8 = -8.e-4_r8 ! do not need a kind
   xr8 = -9.0e5_r8 ! do not need a kind
   xr8 = -.10e6_r8 ! do not need a kind
   xr8 = -11.e7_r8 ! do not need a kind

   blahd = 1.0d0    ! kind specified in exponent, leave kind as-is
   blahd = -1.0D0   ! kind specified in exponent, leave kind as-is

   IF ( xfp.lt.1 ) THEN  ! leave as-is
     print 'xfp.lt.1'    ! leave as-is
   ENDIF
   IF ( xfp.lt.1. ) THEN  ! need a kind
     print 'xfp.lt.1.'    ! leave as-is
   ENDIF
   IF ( 1.lt.xfp ) THEN  ! leave as-is
     print '1.lt.xfp'    ! leave as-is
   ENDIF
   IF ( 1..lt.xfp ) THEN  ! need a kind
     print '1..lt.xfp.'   ! leave as-is
   ENDIF

   blahr = a3d0var  ! leave as-is
   blahr = a3e0var  ! leave as-is

800   format(' lat,lon = ',2i5,', zeps= ',e9.4)   ! do not need a kind

   blahr=a3d0var    ! leave as-is
   blahr=a3e0var    ! leave as-is

end subroutine tst_fp

