! $Id: ESMF_TimeType.F90,v 1.2 2004/03/19 18:22:32 eschwab Exp $
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
!     ESMF TimeType Module
      module ESMF_TimeTypeMod
!
!==============================================================================
!
! This file contains the Time class definition.  The Time class methods
! are defined in ESMF_Time.F90.  This split is to resolve mutual 
! dependency with ESMF_TimeInterval.
!
!------------------------------------------------------------------------------
! INCLUDES

















































 








 











!===============================================================================
!BOPI
!
! !MODULE: ESMF_TimeTypeMod
!
! !DESCRIPTION:
! Part of Time Manager Fortran API wrapper of C++ implemenation.
!
! Defines Fortran types for corresponding C++ class {\tt ESMC\_Time}.
!
! See {\tt ../include/ESMC\_Time.h} for complete description.
!
!------------------------------------------------------------------------------
! !USES:
      ! inherit from base time class
      use ESMF_BaseTimeMod

      ! associated derived types
      use ESMF_CalendarMod

      implicit none

!------------------------------------------------------------------------------
! !PRIVATE TYPES:
!     None: all types defined in this file are public and propagated up
!     via ESMF_TimeMod in ESMF_Time.F90

!------------------------------------------------------------------------------
!     ! ESMF_Time
!
!     ! Fortran class type to match C++ Time class in size only;
!     !  all dereferencing within class is performed by C++ implementation

!     ! Equivalent sequence and kind to C++:

      type ESMF_Time
      sequence                              ! match C++ storage order
      private                               !  (members opaque on Fortran side)
      type(ESMF_BaseTime)          :: baseTime  ! inherit base class
      type(ESMF_Calendar), pointer :: calendar => NULL() ! associated calendar
      integer                      :: timeZone = 0 ! local timezone
      integer                      :: pad      = 0 ! to satisfy halem compiler
     end type

!------------------------------------------------------------------------------
! !PUBLIC TYPES:
!     The types defined in this file are public and propagated up via 
!     ESMF_TimeMod in ESMF_Time.F90      

!EOPI

!------------------------------------------------------------------------------
! The following line turns the CVS identifier string into a printable variable.
      character(*), parameter, private :: version = &
      '$Id: ESMF_TimeType.F90,v 1.2 2004/03/19 18:22:32 eschwab Exp $'
!------------------------------------------------------------------------------

      end module ESMF_TimeTypeMod
