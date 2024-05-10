#include <misc.h>
#include <params.h>

subroutine dadadj (lchnk   ,ncol    ,                   pmid    ,pint    ,pdel    ,t       ,                   q       )












   use shr_kind_mod, only: r8 => shr_kind_r8
   use ppgrid
   use phys_grid,     only: get_lat_p, get_lon_p
   use physconst, only: cappa

   implicit none

   integer niter
   parameter (niter = 15)

#include <comadj.h>



   integer, intent(in) :: lchnk
   integer, intent(in) :: ncol

   real(r8), intent(in) :: pmid(pcols,pver)
   real(r8), intent(in) :: pint(pcols,pverp)
   real(r8), intent(in) :: pdel(pcols,pver)




   real(r8), intent(inout) :: t(pcols,pver)
   real(r8), intent(inout) :: q(pcols,pver)



   integer i,k
   integer jiter

   real(r8) c1dad(pver)
   real(r8) c2dad(pver)
   real(r8) c3dad(pver)
   real(r8) c4dad(pver)
   real(r8) gammad
   real(r8) zeps
   real(r8) rdenom
   real(r8) dtdp
   real(r8) zepsdp
   real(r8) zgamma
   real(r8) qave

   logical ilconv
   logical dodad(pcols)



   zeps = 2.0e-5



   do i=1,ncol
      gammad = cappa*0.5*(t(i,2) + t(i,1))/pint(i,2)
      dtdp = (t(i,2) - t(i,1))/(pmid(i,2) - pmid(i,1))
      dodad(i) = (dtdp + zeps) .gt. gammad
   end do
   do k=2,nlvdry
      do i=1,ncol
         gammad = cappa*0.5*(t(i,k+1) + t(i,k))/pint(i,k+1)
         dtdp = (t(i,k+1) - t(i,k))/(pmid(i,k+1) - pmid(i,k))
         dodad(i) = dodad(i) .or. (dtdp + zeps).gt.gammad
      end do
   end do




   do 80 i=1,ncol
      if (dodad(i)) then
         zeps = 2.0e-5
         do k=1,nlvdry
            c1dad(k) = cappa*0.5*(pmid(i,k+1)-pmid(i,k))/pint(i,k+1)
            c2dad(k) = (1. - c1dad(k))/(1. + c1dad(k))
            rdenom = 1./(pdel(i,k)*c2dad(k) + pdel(i,k+1))
            c3dad(k) = rdenom*pdel(i,k)
            c4dad(k) = rdenom*pdel(i,k+1)
         end do
50       do jiter=1,niter
            ilconv = .true.
            do k=1,nlvdry
               zepsdp = zeps*(pmid(i,k+1) - pmid(i,k))
               zgamma = c1dad(k)*(t(i,k) + t(i,k+1))
               if ((t(i,k+1)-t(i,k)) >= (zgamma+zepsdp)) then
                  ilconv = .false.
                  t(i,k+1) = t(i,k)*c3dad(k) + t(i,k+1)*c4dad(k)
                  t(i,k) = c2dad(k)*t(i,k+1)
                  qave = (pdel(i,k+1)*q(i,k+1) + pdel(i,k)*q(i,k))/(pdel(i,k+1)+ pdel(i,k))
                  q(i,k+1) = qave
                  q(i,k) = qave
               end if
            end do
            if (ilconv) go to 80
         end do



         zeps = zeps + zeps
         if (zeps > 1.e-4) then
            write(6,*)'DADADJ: No convergence in dry adiabatic adjustment'
            write(6,800) get_lat_p(lchnk,i),get_lon_p(lchnk,i),zeps
            call endrun
         else
            write(6,810) zeps,get_lat_p(lchnk,i),get_lon_p(lchnk,i)
            go to 50
         end if
      end if
80    continue
      return



800   format(' lat,lon = ',2i5,', zeps= ',e9.4)
810   format(//,'DADADJ: Convergence criterion doubled to EPS=',E9.4,             ' for'/'        DRY CONVECTIVE ADJUSTMENT at Lat,Lon=',             2i5)
end subroutine dadadj
