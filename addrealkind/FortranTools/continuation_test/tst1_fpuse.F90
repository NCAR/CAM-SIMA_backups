!#include <misc.h>
!#include <params.h>


module module_fp
  INTEGER, PARAMETER :: WRF_KIND_R8 = SELECTED_REAL_KIND(12) ! 8 byte real
  INTEGER, PARAMETER :: WRF_KIND_R4 = SELECTED_REAL_KIND( 6) ! 4 byte real
end module module_fp


module fakeo
      USE module_fp, only: r8 => wrf_kind_r4

private

  INTEGER, PARAMETER :: fp = SELECTED_REAL_KIND( 6) ! 4 byte real

public need_kind, fAKe1, leave_as_is, faKE11

public operator(.eq.), operator(+), assignment(=)

interface operator (.eq.)
 module procedure fake1
end interface

interface assignment (=)
 module procedure need_kind
end interface

interface operator (+)
 module procedure leave_as_is
end interface

contains

subroutine fake1 ( x, &
!
#include <x.h>
!
!
!
!
                 )
  INTEGER, INTENT(INOUT) :: x
  return
end subroutine fake1

subroutine fake11 ( &
#include <y.h>
                    y, &
#include <z.h>
#include <zz.h>
                    z  &
                  )
  INTEGER, INTENT(INOUT) :: y,z
  return
end subroutine fake11

real(fp) function need_kind   ! need a kind
  need_kind = 0._fp          ! need a kind
end function need_kind

real(r8) function leave_as_is   ! leave as-is
  leave_as_is = 0._r8           ! leave as-is
end function leave_as_is

end module fakeo


module FakE2  ! should match different case below
      USE module_fp, only: r8 => wrf_kind_r4

private
  INTEGER, PARAMETER :: fp = SELECTED_REAL_KIND( 6) ! 4 byte real
public NEED_KInd2

contains

subroutine fake21 ( &
                    a,b,c, &
#ifdef X21
                    d, &
#else
                    e, &
#endif
                  )
  INTEGER, INTENT(INOUT) :: a,b,c
#ifdef X21
  INTEGER, INTENT(INOUT) :: d
#else
  INTEGER, INTENT(INOUT) :: e
#endif
  return
end subroutine fake21

real(fp) function need_kind2   ! need a kind
  need_kind2 = 0._fp          ! need a kind
end function need_kind2

real(r8) function leave_as_is2   ! leave as-is
  leave_as_is2 = 0._r8           ! leave as-is
end function leave_as_is2

end module faKE2




subroutine tst1 (lchnk   ,ncol    , &
                   q       )
      USE module_fp, only: r8 => wrf_kind_r4
!----------------------------------------------------------------------- 
! 
! Purpose: 
! Method: 
! 
!-----------------------------------------------------------------------
   use module_fp, only: r8 => wrf_kind_r8
!   use ppgrid
!   use phys_grid,     only: get_lat_p, get_lon_p
!   use physconst, only: cappa

   implicit none

   integer fake_not_in_module  ! fake stuff for testing
   integer niter           ! number of iterations for convergence
   parameter (niter = 15)
   integer, parameter :: pcols = 1
   integer, parameter :: pver = 1
!#include <comadj.h>
!
! Arguments
!
   integer, intent(in) :: lchnk               ! chunk identifier
   integer, intent(in) :: ncol                ! number of atmospheric columns
   real(r8), intent(inout) :: q(pcols,pver)      ! specific humidity

        WRITE(wrf_err_message,*)                                       &
         'start_domain_nmm ims(',ims,' > -2 or ime (',ime,') > ',NMM_MAX_DIM,    &
         '. Increase NMM_MAX_DIM in configure.wrf, clean, and recompile.'

!
! Formats
!
800   format(' lat,lon = ',2i5,', zeps= ',e9.4)
810   format(//,'DADADJ: Convergence criterion doubled to EPS=',E9.4, &
             ' for'/'   FAKE DRY CONVECTIVE ADJUSTMENT at Lat,Lon=', &
             2i5)
end subroutine tst1
