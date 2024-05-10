! $Id: ESMF_BaseTime.F90,v 1.15 2004/06/08 09:27:20 nscollins Exp $
!
! Earth System Modeling Framework
! Copyright 2002-2003, University Corporation for Atmospheric Research,
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics
! Laboratory, University of Michigan, National Centers for Environmental
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
! NASA Goddard Space Flight Center.
! Licensed under the GPL.
!
!==============================================================================
!
!     ESMF BaseTime Module
      module ESMF_BaseTimeMod
!
!==============================================================================
!
! This file contains the BaseTime class definition and all BaseTime class
! methods.
!
!------------------------------------------------------------------------------
! INCLUDES


















































 








 










!
!===============================================================================
!BOPI
! !MODULE: ESMF_BaseTimeMod - Base ESMF time definition 
!
! !DESCRIPTION:
! Part of Time Manager Fortran API wrapper of C++ implemenation.
!
! This module serves only as the common Time definition inherited
! by {\tt ESMF\_TimeInterval} and {\tt ESMF\_Time}.
!
! See {\tt ../include/ESMC\_BaseTime.h} for complete description.
!
!------------------------------------------------------------------------------
! !USES:
      use ESMF_BaseTypesMod
      use ESMF_BaseMod    ! ESMF Base class
      implicit none
!
!------------------------------------------------------------------------------
! !PRIVATE TYPES:
      private
!------------------------------------------------------------------------------
!     ! ESMF_BaseTime
!
!     ! Base class type to match C++ BaseTime class in size only;
!     !  all dereferencing within class is performed by C++ implementation

!     ! Equivalent sequence and kind to C++:

      type ESMF_BaseTime
      sequence                         ! for C++ interoperability
      private
        integer(ESMF_KIND_I8) :: s    = 0  ! whole seconds
        integer(ESMF_KIND_I4) :: sN   = 0  ! fractional seconds, numerator
        integer(ESMF_KIND_I4) :: sD   = 0  ! fractional seconds, denominator
        integer               :: pad1 = 0  ! to match halem C++ <vtbl> long[4]*
        integer               :: pad2 = 0  ! to match halem C++ <vtbl> long[6]*
      end type

!------------------------------------------------------------------------------
! !PUBLIC TYPES:
      public ESMF_BaseTime
!------------------------------------------------------------------------------
!
! !PUBLIC MEMBER FUNCTIONS:
!
! None exposed at Fortran API layer; inherited through
! ESMF_TimeInterval and ESMF_Time
!
!EOPI

!------------------------------------------------------------------------------
! The following line turns the CVS identifier string into a printable variable.
      character(*), parameter, private :: version = &
      '$Id: ESMF_BaseTime.F90,v 1.15 2004/06/08 09:27:20 nscollins Exp $'

!------------------------------------------------------------------------------

      end module ESMF_BaseTimeMod
