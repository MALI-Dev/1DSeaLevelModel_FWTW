module shtns_backend_mod

   use iso_c_binding, only: c_int, c_double, c_double_complex, c_ptr, c_null_ptr, c_associated

   implicit none
   private

   real(c_double), parameter :: sh_norm = 1.41421356d0
   integer(c_int), parameter :: SHT_GAUSS = 0
   integer(c_int), parameter :: SHT_ORTHONORMAL = 0
   integer(c_int), parameter :: SHT_REAL_NORM = 2048
   integer(c_int), parameter :: SHT_PHI_CONTIGUOUS = 512
   integer(c_int), parameter :: SHT_SCALAR_ONLY = 4096

   type :: shtns_state
      type(c_ptr) :: cfg = c_null_ptr
      integer :: nlat = 0
      integer :: nphi = 0
      integer :: ntrunc = 0
      integer :: nlm = 0
      logical :: initialized = .false.
      complex(c_double_complex), allocatable :: qlm(:)
      real(c_double), allocatable :: spat_phi_lat(:,:)
   end type shtns_state

   public :: shtns_state
   public :: shtns_is_available, shtns_init, shtns_destroy
   public :: shtns_spat2spec, shtns_spec2spat, shtns_configure

   interface
      function shtns_create_c(lmax, mmax, mres, norm) bind(c, name='shtns_create') result(cfg)
         use iso_c_binding, only: c_int, c_ptr
         integer(c_int), value :: lmax, mmax, mres, norm
         type(c_ptr) :: cfg
      end function shtns_create_c

      subroutine shtns_set_grid_c(cfg, flags, eps, nlat, nphi) bind(c, name='shtns_set_grid')
         use iso_c_binding, only: c_int, c_double, c_ptr
         type(c_ptr), value :: cfg
         integer(c_int), value :: flags
         real(c_double), value :: eps
         integer(c_int), value :: nlat, nphi
      end subroutine shtns_set_grid_c

      integer(c_int) function shtns_use_threads_c(num_threads) bind(c, name='shtns_use_threads')
         use iso_c_binding, only: c_int
         integer(c_int), value :: num_threads
      end function shtns_use_threads_c

      subroutine shtns_unset_grid_c(cfg) bind(c, name='shtns_unset_grid')
         use iso_c_binding, only: c_ptr
         type(c_ptr), value :: cfg
      end subroutine shtns_unset_grid_c

      subroutine shtns_destroy_c(cfg) bind(c, name='shtns_destroy')
         use iso_c_binding, only: c_ptr
         type(c_ptr), value :: cfg
      end subroutine shtns_destroy_c

      subroutine spat_to_sh_c(cfg, vr, qlm) bind(c, name='spat_to_SH')
         use iso_c_binding, only: c_ptr, c_double, c_double_complex
         type(c_ptr), value :: cfg
         real(c_double), intent(inout) :: vr(*)
         complex(c_double_complex), intent(out) :: qlm(*)
      end subroutine spat_to_sh_c

      subroutine sh_to_spat_c(cfg, qlm, vr) bind(c, name='SH_to_spat')
         use iso_c_binding, only: c_ptr, c_double, c_double_complex
         type(c_ptr), value :: cfg
         complex(c_double_complex), intent(in) :: qlm(*)
         real(c_double), intent(out) :: vr(*)
      end subroutine sh_to_spat_c

      integer(c_int) function shtns_lmidx_c(cfg, l, m) bind(c, name='shtns_lmidx_fortran')
         use iso_c_binding, only: c_ptr, c_int
         type(c_ptr), value :: cfg
         integer(c_int), value :: l, m
      end function shtns_lmidx_c
   end interface

contains

   logical function shtns_is_available()
      shtns_is_available = .true.
   end function shtns_is_available


   subroutine shtns_init(state, nlon, nlat, ntrunc)
      type(shtns_state), intent(inout) :: state
      integer, intent(in) :: nlon, nlat, ntrunc
      integer(c_int) :: norm, layout
      real(c_double) :: eps_polar

      call shtns_destroy(state)

      norm = SHT_ORTHONORMAL + SHT_REAL_NORM
      state%cfg = shtns_create_c(int(ntrunc, c_int), int(ntrunc, c_int), int(1, c_int), norm)
      if (.not. c_associated(state%cfg)) then
         write(*,*) 'SHTns initialization failed in shtns_create.'
         stop
      endif

      layout = SHT_GAUSS + SHT_PHI_CONTIGUOUS + SHT_SCALAR_ONLY
      eps_polar = 1.0d-10
      call shtns_set_grid_c(state%cfg, layout, eps_polar, int(nlat, c_int), int(nlon, c_int))

      state%nlm = (ntrunc + 1)*(ntrunc + 2)/2
      state%nlat = nlat
      state%nphi = nlon
      state%ntrunc = ntrunc

      allocate(state%qlm(state%nlm))
      allocate(state%spat_phi_lat(state%nphi, state%nlat))
      state%qlm = (0.0d0, 0.0d0)
      state%spat_phi_lat = 0.0d0
      state%initialized = .true.
   end subroutine shtns_init


   subroutine shtns_configure(state, nthreads)
      type(shtns_state), intent(inout) :: state
      integer, intent(in) :: nthreads
      integer(c_int) :: configured

      if (.not. state%initialized) then
         return
      endif

      if (nthreads > 0) then
         configured = shtns_use_threads_c(int(nthreads, c_int))
      endif
   end subroutine shtns_configure


   subroutine shtns_destroy(state)
      type(shtns_state), intent(inout) :: state

      if (allocated(state%qlm)) then
         deallocate(state%qlm)
      endif
      if (allocated(state%spat_phi_lat)) then
         deallocate(state%spat_phi_lat)
      endif

      if (c_associated(state%cfg)) then
         call shtns_unset_grid_c(state%cfg)
         call shtns_destroy_c(state%cfg)
      endif

      state%cfg = c_null_ptr
      state%nlat = 0
      state%nphi = 0
      state%ntrunc = 0
      state%nlm = 0
      state%initialized = .false.
   end subroutine shtns_destroy


   subroutine shtns_spat2spec(z_lat_phi, u_l_m, state)
      type(shtns_state), intent(inout) :: state
      real, intent(in) :: z_lat_phi(:,:)
      complex, intent(out) :: u_l_m(0:,0:)
      integer :: it, ip, l, m, lm

      if (.not. state%initialized) then
         write(*,*) 'SHTns backend not initialized before shtns_spat2spec.'
         stop
      endif
      if (size(z_lat_phi, 1) /= state%nlat .or. size(z_lat_phi, 2) /= state%nphi) then
         write(*,*) 'Spatial dimensions mismatch in shtns_spat2spec.'
         stop
      endif

      do ip = 1, state%nphi
         do it = 1, state%nlat
            state%spat_phi_lat(ip,it) = real(z_lat_phi(it,ip), c_double)
         enddo
      enddo

      call spat_to_sh_c(state%cfg, state%spat_phi_lat, state%qlm)

      u_l_m = (0.0, 0.0)
      do m = 0, state%ntrunc
         do l = m, state%ntrunc
            lm = shtns_lmidx_c(state%cfg, int(l, c_int), int(m, c_int))
            u_l_m(l,m) = cmplx(real(state%qlm(lm), c_double), aimag(state%qlm(lm)), kind=kind(u_l_m)) / sh_norm
         enddo
      enddo
   end subroutine shtns_spat2spec


   subroutine shtns_spec2spat(z_lat_phi, u_l_m, state)
      type(shtns_state), intent(inout) :: state
      real, intent(out) :: z_lat_phi(:,:)
      complex, intent(in) :: u_l_m(0:,0:)
      integer :: it, ip, l, m, lm

      if (.not. state%initialized) then
         write(*,*) 'SHTns backend not initialized before shtns_spec2spat.'
         stop
      endif
      if (size(z_lat_phi, 1) /= state%nlat .or. size(z_lat_phi, 2) /= state%nphi) then
         write(*,*) 'Spatial dimensions mismatch in shtns_spec2spat.'
         stop
      endif

      state%qlm = (0.0d0, 0.0d0)
      do m = 0, state%ntrunc
         do l = m, state%ntrunc
            lm = shtns_lmidx_c(state%cfg, int(l, c_int), int(m, c_int))
            state%qlm(lm) = cmplx(real(u_l_m(l,m), c_double), aimag(u_l_m(l,m)), kind=kind(state%qlm)) * sh_norm
         enddo
      enddo

         call sh_to_spat_c(state%cfg, state%qlm, state%spat_phi_lat)

      do ip = 1, state%nphi
         do it = 1, state%nlat
            z_lat_phi(it,ip) = real(state%spat_phi_lat(ip,it), kind(z_lat_phi))
         enddo
      enddo
   end subroutine shtns_spec2spat

end module shtns_backend_mod
