module PrescribedSoilMoisture

!-----------------------------------------------------------------------
!BOP
!
! !MODULE: PrescribedSoilMoisture
!
! !DESCRIPTION:
! Static Ecosystem dynamics: phenology, vegetation. This is for the CLM Satelitte Phenology 
! model (CLMSP). Allow some subroutines to be used by the CLM Carbon Nitrogen model (CLMCN) 
! so that DryDeposition code can get estimates of LAI differences between months.
!
! !USES:
  use shr_kind_mod,    only : r8 => shr_kind_r8
  use abortutils,      only : endrun
  use clm_varctl,      only : scmlat,scmlon,single_column
  use clm_varctl,      only : iulog
  use perf_mod,        only : t_startf, t_stopf
  use spmdMod,         only : masterproc
  use ncdio_pio   
!
! !PUBLIC TYPES:
  implicit none
  save
!
! !PUBLIC MEMBER FUNCTIONS:
  public :: prescribedSMini  ! Dynamically allocate memory
  public :: prescribedSM     ! interpolate monthly prescribed soil moisture data
!
! !REVISION HISTORY:
! Created by Mariana Vertenstein
! Modified by Ahmed B. Tawfik -- prescribed soil moisture
!
! !PRIVATE MEMBER FUNCTIONS:
  private :: readMonthlySoilMoisture   ! read monthly prescribed soil moisture data for two months
!
! !PRIVATE TYPES:
  integer , private :: InterpMonths1                       ! saved month index
  real(r8), private :: timwt(2)                            ! time weights for month 1 and month 2
  real(r8), private, allocatable :: soilice_2months(:,:,:) ! soil ice for interpolation (2 months)
  real(r8), private, allocatable :: soilliq_2months(:,:,:) ! soil liquid for interpolation (2 months)
  real(r8), private, allocatable :: soil_mask      (:,:  ) ! where to apply a mask of prescribed soil moisture (2 months)
!EOP
!-----------------------------------------------------------------------

contains

!-----------------------------------------------------------------------
!BOP
!
! !IROUTINE: prescribedSMini
!
! !INTERFACE:
  subroutine prescribedSMini ()
!
! !DESCRIPTION:
! Dynamically allocate memory and set to signaling NaN.
!
! !USES:
    !use nanMod
    !use nanMod     , only : nan, bigint
    use decompMod  , only : get_proc_bounds
    use clm_varpar , only : nlevsno, nlevgrnd
    use shr_kind_mod, only: r8 => shr_kind_r8
!
! !ARGUMENTS:
    implicit none
!
! !REVISION HISTORY:
!
!
! !LOCAL VARIABLES:
!EOP
    integer :: ier        ! error code
    integer :: begc,endc  ! local beg and end c index
    real(r8), parameter :: nan = O'0777700000000000000000'   !yangx2
!-----------------------------------------------------------------------

    InterpMonths1 = -999  ! saved month index
    call get_proc_bounds(begc=begc,endc=endc)

    ier = 0
    if(.not.allocated(soilliq_2months))  allocate (   &
              soilice_2months(begc:endc,-nlevsno+1:nlevgrnd,2), &
              soilliq_2months(begc:endc,-nlevsno+1:nlevgrnd,2), &
              soil_mask      (begc:endc,-nlevsno+1:nlevgrnd  ), &
              stat=ier)
    if (ier /= 0) then
       write(iulog,*) 'Initialize prescribed soil moisture allocation error'
       call endrun
    end if

    soilliq_2months(:,:,:) = nan
    soilice_2months(:,:,:) = nan
    soil_mask      (:,:  ) = nan

  end subroutine prescribedSMini



!-----------------------------------------------------------------------
!BOP
!
! !IROUTINE: prescribedSM
!
! !INTERFACE:
  subroutine prescribedSM(begc, endc)
!
! !DESCRIPTION:
! Ecosystem dynamics: phenology, vegetation
! Calculates leaf areas (tlai, elai),  stem areas (tsai, esai) and
! height (htop).
!
! !USES:
    use clmtype
    use clm_varpar      , only : nlevgrnd, nlevsno, nlevlak, nlevurb
    use clm_varcon      , only : istcrop
    use clm_varcon      , only : denice, denh2o, istdlak, istslak, isturb, &
                                 istsoil, pondmx, watmin, spval

!
! !ARGUMENTS:
    implicit none
    integer, intent(in) :: begc, endc                    ! column bounds

!
! !CALLED FROM:
!
! !REVISION HISTORY:
! Author: Gordon Bonan
! 2/1/02, Peter Thornton: Migrated to new data structure.
! 2/29/08, David Lawrence: revised snow burial fraction for short vegetation   
! 2/3/17 , Ahmed B Tawfik: revised the LAI module to interpolate prescribed soil moisture
!
! !LOCAL VARIABLES:
!
! local pointers to implicit out arguments
!
    real(r8), pointer :: h2osoi_liq(:,:)     ! liquid water (kg/m2) (new) (-nlevsno+1:nlevgrnd)
    real(r8), pointer :: h2osoi_ice(:,:)     ! ice water    (kg/m2) (new) (-nlevsno+1:nlevgrnd)
    real(r8), pointer :: h2osoi_vol(:,:)     ! volumetric water (m3/m3)
    real(r8), pointer :: dz        (:,:)     ! depth of a given soil layer

    integer , pointer :: clandunit(:)     ! landunit of corresponding column
    integer , pointer :: ltype(:)         ! landunit type

!
!
! !OTHER LOCAL VARIABLES:
    integer    ::  c, l, j
    integer    ::  nlevs

!EOP
!-----------------------------------------------------------------------

    ! Assign local pointers to derived type scalar members (column-level)
    h2osoi_ice        => cws%h2osoi_ice
    h2osoi_liq        => cws%h2osoi_liq
    h2osoi_vol        => cws%h2osoi_vol

    dz                => cps%dz
    clandunit         => col%landunit
    ltype             => lun%itype
    !!yangx2 revised
    !h2osoi_liq  => clm3%g%l%c%cws%h2osoi_liq
    !h2osoi_ice  => clm3%g%l%c%cws%h2osoi_ice
    !h2osoi_vol  => clm3%g%l%c%cws%h2osoi_vol

    !dz          => clm3%g%l%c%cps%dz
    !clandunit   => clm3%g%l%c%landunit
    !ltype       => clm3%g%l%itype

  
    !
    ! The weights below (timwt(1) and timwt(2)) were obtained by a call to
    ! routine interpSoilMoisture.
    !                 Field   Monthly Values
    !                -------------------------
    where(  soil_mask.ge.1  )
        h2osoi_ice  =  timwt(1)*soilice_2months(:,:,1) + timwt(2)*soilice_2months(:,:,2)
        h2osoi_liq  =  timwt(1)*soilliq_2months(:,:,1) + timwt(2)*soilliq_2months(:,:,2)
    end where


    ! ------------------------------------------------------------
    ! Determine volumetric soil water (for read only)
    ! ------------------------------------------------------------
    do c = begc,endc
       l = clandunit(c)
       if ( ltype(l) == istdlak .or. ltype(l) == istslak )then
           nlevs = nlevlak
       else if ( ltype(l) == isturb )then
           nlevs = nlevurb
       else
           nlevs = nlevgrnd
       end if
       ! NOTE: THIS IS A MEMORY INEFFICIENT COPY
       do j = 1,nlevs
          if( soil_mask(c,j).ge.1 ) then
              h2osoi_vol(c,j) = h2osoi_liq(c,j)/(dz(c,j)*denh2o) +  &
                                h2osoi_ice(c,j)/(dz(c,j)*denice)
          end if
       end do
    end do

  end subroutine prescribedSM




!-----------------------------------------------------------------------
!BOP
!
! !IROUTINE: interpSoilMoisture
!
! !INTERFACE:
  subroutine interpSoilMoisture ()
!
! !Description:
! Determine if 2 new months of data are to be read.
!
! !USES:
    use clm_varctl      , only : fsoilprescribed
    use clm_time_manager, only : get_curr_date, get_step_size, &
                                 get_perp_date, is_perpetual, get_nstep
!
! !ARGUMENTS:
    implicit none
!
! !REVISION HISTORY:
! Created by Mariana Vertenstein
! Modified by Ahmed B. Tawfik -- prescribed soil moisture style
!
! !LOCAL VARIABLES:
!EOP
    integer :: kyr         ! year (0, ...) for nstep+1
    integer :: kmo         ! month (1, ..., 12)
    integer :: kda         ! day of month (1, ..., 31)
    integer :: ksec        ! seconds into current date for nstep+1
    real(r8):: dtime       ! land model time step (sec)
    real(r8):: t           ! a fraction: kda/ndaypm
    integer :: it(2)       ! month 1 and month 2 (step 1)
    integer :: months(2)   ! months to be interpolated (1 to 12)
    integer, dimension(12) :: ndaypm= &
         (/31,28,31,30,31,30,31,31,30,31,30,31/) !days per month
!-----------------------------------------------------------------------

    dtime = get_step_size()

    if ( is_perpetual() ) then
       call get_perp_date(kyr, kmo, kda, ksec, offset=int(dtime))
    else
       call get_curr_date(kyr, kmo, kda, ksec, offset=int(dtime))
    end if

    t = (kda-0.5_r8) / ndaypm(kmo)
    it(1) = t + 0.5_r8
    it(2) = it(1) + 1
    months(1) = kmo + it(1) - 1
    months(2) = kmo + it(2) - 1
    if (months(1) <  1) months(1) = 12
    if (months(2) > 12) months(2) = 1
    timwt(1) = (it(1)+0.5_r8) - t
    timwt(2) = 1._r8-timwt(1)

    if (InterpMonths1 /= months(1)) then
       if (masterproc) then
          write(iulog,*) 'Attempting to read monthly prescribed soil moisture data .....'
          write(iulog,*) 'nstep = ',get_nstep(),' month = ',kmo,' day = ',kda
       end if
       call t_startf('readMonthlySoilMoisture')
       call readMonthlySoilMoisture (fsoilprescribed, months)
       InterpMonths1 = months(1)
       call t_stopf('readMonthlySoilMoisture')
    end if

  end subroutine interpSoilMoisture


!-----------------------------------------------------------------------
!BOP
!
! !IROUTINE: readMonthlySoilMoisture
!
! !INTERFACE:
  subroutine readMonthlySoilMoisture (fsoil, months)
!
! !DESCRIPTION:
! Read monthly soil moisture data for two consec. months.
!
! !USES:
    use clmtype
    use decompMod   , only : get_proc_bounds
    use clm_varpar  , only : nlevsno, nlevgrnd
    use fileutils   , only : getfil
    use spmdMod     , only : masterproc, mpicom, MPI_REAL8, MPI_INTEGER
    use clm_time_manager, only : get_nstep
    use netcdf
!
! !ARGUMENTS:
    implicit none

    character(len=*), intent(in) :: fsoil       ! file with monthly vegetation data
    integer         , intent(in) :: months(2)   ! months to be interpolated (1 to 12)
!
! !REVISION HISTORY:
! Created by Ahmed B. Tawfik
!
!
! !LOCAL VARIABLES:
!EOP
    character(len=256) :: locfn           ! local file name
    type(file_desc_t)  :: ncid            ! netcdf id
    integer :: g,k                        ! indices
    integer :: dimid,varid                ! input netCDF id's
    integer :: begc,endc                  ! beg and end local p index
    integer :: ier                        ! error code
    logical :: readvar
    real(r8), pointer :: soil_liquid   (:,:)   ! volumetric soil moisture read from input files
    real(r8), pointer :: soil_ice      (:,:)   ! volumetric soil ice read from input files
    real(r8), pointer :: prescribe_mask(:,:)   ! mask where prescribed soil moisture is applied: 1=apply 0=don't prescribe
    character(len=32) :: subname = 'readMonthlySoilMoisture'
!-----------------------------------------------------------------------

    ! Determine necessary indices

    call get_proc_bounds(begc=begc,endc=endc)

    allocate(soil_liquid   (begc:endc,-nlevsno+1:nlevgrnd) , &
             soil_ice      (begc:endc,-nlevsno+1:nlevgrnd) , &
             prescribe_mask(begc:endc,-nlevsno+1:nlevgrnd) , &
             stat=ier)
    if (ier /= 0) then
       write(iulog,*)subname, 'allocation big error '; call endrun()
    end if

    ! ----------------------------------------------------------------------
    ! Open monthly soil moisture (liq and ice) file
    ! Read data and store 
    ! ----------------------------------------------------------------------
    call getfil(fsoil, locfn, 0)
    call ncd_pio_openfile (ncid, trim(locfn), 0)


    !
    ! Read in the soil moisture mask to be applied.  Used for prescribed soil
    ! moisture experiments where soil moisture climatology is only applied to a 
    ! Specified region/area
    !
    call ncd_io(ncid=ncid, varname='PRESCRIBE_MASK', flag='read', data=prescribe_mask, dim1name=namec, &
                readvar=readvar)
    soil_mask  =  prescribe_mask


    !
    !loop over months and read prescribe soil moisture data 
    !(note: will interpolate between months for smooth transitions)
    !
    do k=1,2   

       call ncd_io(ncid=ncid, varname='H2OSOI_LIQ'    , flag='read', data=soil_liquid, dim1name=namec, &
            nt=months(k), readvar=readvar)

       call ncd_io(ncid=ncid, varname='H2OSOI_ICE'    , flag='read', data=soil_ice, dim1name=namec, &
            nt=months(k), readvar=readvar)
       if (.not. readvar) call endrun( trim(subname)//' ERROR: MONTHLY_SOIL MOISTURE not in fsoil file' )

       ! Store data in local module to perform 2-month gradual interpolation later
       where( prescribe_mask.ge.1 ) 
          soilliq_2months(:,:,k)  =  soil_liquid(:,:)
          soilice_2months(:,:,k)  =  soil_ice   (:,:)
       end where

    end do   ! end of loop over months

    ! Close the file
    call ncd_pio_closefile(ncid)


    if (masterproc) then
       k = 2
       write(iulog,*) 'Successfully read monthly soil moisture data for'
       write(iulog,*) 'month ', months(k)
       write(iulog,*)
    end if

    deallocate(soil_liquid, soil_ice, prescribe_mask)

  end subroutine readMonthlySoilMoisture



end module PrescribedSoilMoisture
