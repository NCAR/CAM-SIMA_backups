module held_suarez_cam

  !-----------------------------------------------------------------------
  !
  ! Purpose: Implement idealized Held-Suarez forcings
  !    Held, I. M., and M. J. Suarez, 1994: 'A proposal for the
  !    intercomparison of the dynamical cores of atmospheric general
  !    circulation models.'
  !    Bulletin of the Amer. Meteor. Soc., vol. 75, pp. 1825-1830.
  !
  !-----------------------------------------------------------------------

  use shr_kind_mod, only: r8 => shr_kind_r8
  use ppgrid,       only: pcols, pver

  implicit none
  private
  save

  public :: held_suarez_init, held_suarez_tend

  real(r8), parameter :: efoldf  =  1._r8  ! efolding time for wind dissipation
  real(r8), parameter :: efolda  = 40._r8  ! efolding time for T dissipation
  real(r8), parameter :: efolds  =  4._r8  ! efolding time for T dissipation
  real(r8), parameter :: sigmab  =  0.7_r8 ! threshold sigma level
  real(r8), parameter :: t00     = 200._r8 ! minimum reference temperature
  real(r8), parameter :: kf      = 1._r8/(86400._r8*efoldf) ! 1./efolding_time for wind dissipation

  real(r8), parameter :: onemsig = 1._r8 - sigmab ! 1. - sigma_reference

  real(r8), parameter :: ka      = 1._r8/(86400._r8 * efolda) ! 1./efolding_time for temperature diss.
  real(r8), parameter :: ks      = 1._r8/(86400._r8 * efolds)

!=======================================================================
contains
!=======================================================================

  subroutine held_suarez_init()
    use physics_buffer,     only: physics_buffer_desc
    use cam_history,        only: addfld, add_default
    use ref_pres,           only: psurf_ref
    use held_suarez_1994,   only: held_suarez_1994_init

    ! Local variables
    character(len=512) :: errmsg
    integer            :: errflg

    ! Set model constant values
    call held_suarez_1994_init(psurf_ref, errmsg, errflg)

    ! This field is added by radiation when full physics is used
    call addfld('QRS', (/ 'lev' /), 'A', 'K/s', &
         'Temperature tendency associated with the relaxation toward the equilibrium temperature profile')
    call add_default('QRS', 1, ' ')
 end subroutine held_suarez_init

  subroutine held_suarez_tend(state, ptend, ztodt)
    use air_composition,    only: cappav, cpairv
    use ref_pres,           only: pref_mid_norm
    !use phys_grid,          only: get_rlat_all_p
    use phys_grid,          only: get_lat_all_p !DEBUG -JN
    use physics_types,      only: physics_state, physics_ptend
    use physics_types,      only: physics_ptend_init
    use cam_abortutils,     only: endrun
    use cam_history,        only: outfld
    use held_suarez_1994,   only: held_suarez_1994_run
    use time_manager,       only: get_nstep !DEBUG -JN
    use shr_const_mod,      only: SHR_CONST_PI !DEBUG -JN

    !
    ! Input arguments
    !
    type(physics_state), intent(inout) :: state
    real(r8),            intent(in)    :: ztodt            ! Two times model timestep (2 delta-t)
                                                           !
                                                           ! Output argument
                                                           !
    type(physics_ptend), intent(out)   :: ptend            ! Package tendencies
                                                           !
    !---------------------------Local workspace-----------------------------

    integer                            :: lchnk            ! chunk identifier
    integer                            :: ncol             ! number of atmospheric columns

    real(r8)                           :: clat(pcols)      ! latitudes(radians) for columns
    real(r8)                           :: pmid(pcols,pver) ! mid-point pressure
    integer                            :: i, k             ! Longitude, level indices

    character(len=64)                  :: scheme_name      ! CCPP-required variables (not used in CAM)
    character(len=512)                 :: errmsg
    integer                            :: errflg

    real(r8), parameter                :: degtorad = SHR_CONST_PI / 180.0_r8 !DEBUG -JN

    !
    !-----------------------------------------------------------------------
    !

    lchnk = state%lchnk
    ncol  = state%ncol

    !call get_rlat_all_p(lchnk, ncol, clat)
    !DEBUG -JN:
    !---------
    call get_lat_all_p(lchnk, ncol, clat)
    clat(:ncol) = clat(:ncol) * degtorad
    !---------
    do k = 1, pver
      do i = 1, ncol
        pmid(i,k) = state%pmid(i,k)
      end do
    end do

    ! initialize individual parameterization tendencies
    call physics_ptend_init(ptend, state%psetcols, 'held_suarez', ls=.true., lu=.true., lv=.true.)

    !Debug -JN:
    !write(*,*) 'DEBUG AIR TEMP pre-HS94:', clat(417), sum(state%t(:ncol,:)), sum(ptend%s(:ncol,:)), get_nstep()

    call held_suarez_1994_run(pver, ncol, pref_mid_norm, clat, cappav(:,:,lchnk), cpairv(:,:,lchnk), &
                              state%pmid, state%u, state%v, state%t, ptend%u, ptend%v, ptend%s,      &
                              scheme_name, errmsg, errflg)

    !Debug -JN:
    !write(*,*) 'DEBUG AIR TEMP post-HS94:', sum(state%t(:ncol,:)), sum(ptend%s(:ncol,:)), get_nstep()

    ! Note, we assume that there are no subcolumns in simple physics
    pmid(:ncol,:) = ptend%s(:ncol, :)/cpairv(:ncol,:,lchnk)
    if (pcols > ncol) then
      pmid(ncol+1:,:) = 0.0_r8
    end if
    call outfld('QRS', pmid, pcols, lchnk)

  end subroutine held_suarez_tend

end module held_suarez_cam
