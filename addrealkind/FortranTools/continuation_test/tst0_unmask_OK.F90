subroutine tst0 (lchnk   ,ncol    , @
                   q       )
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   implicit none
   integer, intent(in) :: lchnk               @@@@@@@@@@@@@@@@@@
   integer, intent(in) :: ncol                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   real(r8), intent(inout) :: q(pcols,pver)      @@@@@@@@@@@@@@@@@@@
810   format(//,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,E9.4, @
             @@@@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@, @
             2i5)
end subroutine tst0
