



module module_fp
  INTEGER, PARAMETER :: WRF_KIND_R8 = SELECTED_REAL_KIND(12)
  INTEGER, PARAMETER :: WRF_KIND_R4 = SELECTED_REAL_KIND( 6)
end module module_fp


module fakeo

private

  INTEGER, PARAMETER :: fp = SELECTED_REAL_KIND( 6)

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

subroutine fake1 ( x,
#include <x.h>
                 )
  INTEGER, INTENT(INOUT) :: x
  return
end subroutine fake1

subroutine fake11 (
#include <y.h>
                    y,
#include <z.h>
#include <zz.h>
                    z                  )
  INTEGER, INTENT(INOUT) :: y,z
  return
end subroutine fake11

real function need_kind
  need_kind = 0.
end function need_kind

real(r8) function leave_as_is
  leave_as_is = 0._r8
end function leave_as_is

end module fakeo


module FakE2

private
  INTEGER, PARAMETER :: fp = SELECTED_REAL_KIND( 6)
public NEED_KInd2

contains

subroutine fake21 (                    a,b,c,
#ifdef X21
                    d,
#else
                    e,
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

real function need_kind2
  need_kind2 = 0.
end function need_kind2

real(r8) function leave_as_is2
  leave_as_is2 = 0._r8
end function leave_as_is2

end module faKE2




subroutine tst1 (lchnk   ,ncol    ,                   q       )






   use module_fp, only: r8 => wrf_kind_r8




   implicit none

   integer fake_not_in_module
   integer niter
   parameter (niter = 15)
   integer, parameter :: pcols = 1
   integer, parameter :: pver = 1




   integer, intent(in) :: lchnk
   integer, intent(in) :: ncol
   real(r8), intent(inout) :: q(pcols,pver)

        WRITE(wrf_err_message,*)         'start_domain_nmm ims(',ims,' > -2 or ime (',ime,') > ',NMM_MAX_DIM,         '. Increase NMM_MAX_DIM in configure.wrf, clean, and recompile.'




800   format(' lat,lon = ',2i5,', zeps= ',e9.4)
810   format(//,'DADADJ: Convergence criterion doubled to EPS=',E9.4,             ' for'/'   FAKE DRY CONVECTIVE ADJUSTMENT at Lat,Lon=',             2i5)
end subroutine tst1
