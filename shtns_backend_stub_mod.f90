module shtns_backend_mod

   implicit none
   private

   type :: shtns_state
      logical :: initialized = .false.
   end type shtns_state

   public :: shtns_state
   public :: shtns_is_available, shtns_init, shtns_destroy
   public :: shtns_spat2spec, shtns_spec2spat, shtns_configure

contains

   logical function shtns_is_available()
      shtns_is_available = .false.
   end function shtns_is_available


   subroutine shtns_init(state, nlon, nlat, ntrunc, nthreads, eps, allow_padding, grid_type)
      type(shtns_state), intent(inout) :: state
      integer, intent(in) :: nlon, nlat, ntrunc
      integer, intent(in), optional :: nthreads
      real, intent(in), optional :: eps
      logical, intent(in), optional :: allow_padding
      character(*), intent(in), optional :: grid_type
      state%initialized = .false.
      write(*,*) 'SHTns backend not available. Rebuild with USE_SHTNS=1.'
      write(*,*) 'Requested grid nlon=', nlon, ' nlat=', nlat, ' ntrunc=', ntrunc
      if (present(nthreads)) then
         write(*,*) 'Requested shtns threads=', nthreads
      endif
      if (present(eps)) then
         write(*,*) 'Requested shtns eps=', eps
      endif
      if (present(allow_padding)) then
         write(*,*) 'Requested shtns allow_padding=', allow_padding
      endif
      if (present(grid_type)) then
         write(*,*) 'Requested shtns grid_type=', trim(grid_type)
      endif
      stop
   end subroutine shtns_init


   subroutine shtns_configure(state, nthreads)
      type(shtns_state), intent(inout) :: state
      integer, intent(in) :: nthreads
      state%initialized = state%initialized .or. (nthreads > 0)
   end subroutine shtns_configure


   subroutine shtns_destroy(state)
      type(shtns_state), intent(inout) :: state
      state%initialized = .false.
   end subroutine shtns_destroy


   subroutine shtns_spat2spec(z_lat_phi, u_l_m, state)
      type(shtns_state), intent(in) :: state
      real, intent(in) :: z_lat_phi(:,:)
      complex, intent(out) :: u_l_m(0:,0:)
      write(*,*) 'SHTns backend not available. Rebuild with USE_SHTNS=1.'
      u_l_m = (0.0, 0.0)
      if (state%initialized) then
         write(*,*) 'Unexpected call with initialized SHTns stub state.'
      endif
      if (size(z_lat_phi,1) < 0) then
         stop
      endif
      stop
   end subroutine shtns_spat2spec


   subroutine shtns_spec2spat(z_lat_phi, u_l_m, state)
      type(shtns_state), intent(in) :: state
      real, intent(out) :: z_lat_phi(:,:)
      complex, intent(in) :: u_l_m(0:,0:)
      write(*,*) 'SHTns backend not available. Rebuild with USE_SHTNS=1.'
      z_lat_phi = 0.0
      if (state%initialized) then
         write(*,*) 'Unexpected call with initialized SHTns stub state.'
      endif
      if (size(u_l_m,1) < 0) then
         stop
      endif
      stop
   end subroutine shtns_spec2spat

end module shtns_backend_mod
