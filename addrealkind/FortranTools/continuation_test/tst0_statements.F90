subroutine tst0 (lchnk   ,ncol    ,                   q       )

   implicit none
   integer, intent(in) :: lchnk
   integer, intent(in) :: ncol
   real(r8), intent(inout) :: q(pcols,pver)
810   format(//,'DADADJ: Convergence criterion doubled to EPS=',E9.4,             ' for'/'        DRY CONVECTIVE ADJUSTMENT at Lat,Lon=',             2i5)
end subroutine tst0
