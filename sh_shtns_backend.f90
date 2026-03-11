module sh_shtns_backend

   implicit none
   private

   real(kind=8), parameter :: SH_NORM_MATCH = 1.41421356d0

   type, public :: sh_shtns_state
      integer :: nlat = 0
      integer :: nphi = 0
      integer :: ntrunc = 0
      integer :: nlm = 0
      logical :: initialized = .false.
      complex(kind=8), allocatable :: qlm(:)
      real(kind=8), allocatable :: spat_phi_lat(:,:)
   end type sh_shtns_state

   public :: sh_shtns_init
   public :: sh_shtns_destroy
   public :: sh_shtns_spat2spec
   public :: sh_shtns_spec2spat

contains

   subroutine sh_shtns_init(state, nlon, nlat, ntrunc)

      include 'shtns.f'

      type(sh_shtns_state), intent(inout) :: state
      integer, intent(in) :: nlon, nlat, ntrunc

      integer :: layout
      integer :: norm
      real(kind=8) :: eps_polar

      call sh_shtns_destroy(state)

      state%nlat = nlat
      state%nphi = nlon
      state%ntrunc = ntrunc

      call shtns_calc_nlm(state%nlm, state%ntrunc, state%ntrunc, 1)

      norm = SHT_ORTHONORMAL + SHT_REAL_NORM
      call shtns_set_size(state%ntrunc, state%ntrunc, 1, norm)

      layout = SHT_PHI_CONTIGUOUS + SHT_SCALAR_ONLY
      eps_polar = 1.0d-10
      call shtns_precompute(SHT_GAUSS, layout, eps_polar, state%nlat, state%nphi)

      allocate(state%qlm(state%nlm))
      allocate(state%spat_phi_lat(state%nphi, state%nlat))

      state%qlm = (0.0d0, 0.0d0)
      state%spat_phi_lat = 0.0d0
      state%initialized = .true.

   end subroutine sh_shtns_init


   subroutine sh_shtns_destroy(state)

      include 'shtns.f'

      type(sh_shtns_state), intent(inout) :: state

      if (allocated(state%qlm)) deallocate(state%qlm)
      if (allocated(state%spat_phi_lat)) deallocate(state%spat_phi_lat)

      if (state%initialized) then
         call shtns_reset()
      endif

      state%nlat = 0
      state%nphi = 0
      state%ntrunc = 0
      state%nlm = 0
      state%initialized = .false.

   end subroutine sh_shtns_destroy


   subroutine sh_shtns_spat2spec(z_lat_phi, u_l_m, state)

      include 'shtns.f'

      type(sh_shtns_state), intent(inout) :: state
      real, dimension(:,:), intent(in) :: z_lat_phi
      complex, dimension(0:,0:), intent(out) :: u_l_m

      integer :: it, ip, l, m, lm

      if (.not. state%initialized) then
         write(*,*) 'SHTns backend not initialized before sh_shtns_spat2spec.'
         stop
      endif

      if (size(z_lat_phi,1) /= state%nlat .or. size(z_lat_phi,2) /= state%nphi) then
         write(*,*) 'Spatial field dimensions do not match SHTns configuration in sh_shtns_spat2spec.'
         stop
      endif

      do ip = 1, state%nphi
         do it = 1, state%nlat
            state%spat_phi_lat(ip,it) = z_lat_phi(it,ip)
         enddo
      enddo

      call spat_to_sh(state%spat_phi_lat, state%qlm)

      u_l_m(:,:) = (0.0, 0.0)
      do m = 0, state%ntrunc
         do l = m, state%ntrunc
            call shtns_lmidx(lm, l, m)
            u_l_m(l,m) = state%qlm(lm) / SH_NORM_MATCH
         enddo
      enddo

   end subroutine sh_shtns_spat2spec


   subroutine sh_shtns_spec2spat(z_lat_phi, u_l_m, state)

      include 'shtns.f'

      type(sh_shtns_state), intent(inout) :: state
      real, dimension(:,:), intent(out) :: z_lat_phi
      complex, dimension(0:,0:), intent(in) :: u_l_m

      integer :: it, ip, l, m, lm

      if (.not. state%initialized) then
         write(*,*) 'SHTns backend not initialized before sh_shtns_spec2spat.'
         stop
      endif

      if (size(z_lat_phi,1) /= state%nlat .or. size(z_lat_phi,2) /= state%nphi) then
         write(*,*) 'Spatial field dimensions do not match SHTns configuration in sh_shtns_spec2spat.'
         stop
      endif

      state%qlm(:) = (0.0d0, 0.0d0)
      do m = 0, state%ntrunc
         do l = m, state%ntrunc
            call shtns_lmidx(lm, l, m)
            state%qlm(lm) = u_l_m(l,m) * SH_NORM_MATCH
         enddo
      enddo

      call sh_to_spat(state%qlm, state%spat_phi_lat)

      do ip = 1, state%nphi
         do it = 1, state%nlat
            z_lat_phi(it,ip) = state%spat_phi_lat(ip,it)
         enddo
      enddo

   end subroutine sh_shtns_spec2spat

end module sh_shtns_backend