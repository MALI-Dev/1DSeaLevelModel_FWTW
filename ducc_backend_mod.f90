module ducc_backend_mod

   use iso_c_binding, only: c_int, c_ptr, c_null_ptr, c_associated, c_double, c_double_complex

   implicit none
   private

   real(c_double), parameter :: sh_norm = 1.41421356d0

   public :: ducc_is_available, ducc_init, ducc_destroy, ducc_spat2spec, ducc_spec2spat

   interface
      function ducc_sh_init_c(nlon, nlat, ntrunc, re) bind(c, name='ducc_sh_init') result(plan)
         use iso_c_binding, only: c_int, c_ptr, c_double
         integer(c_int), value :: nlon, nlat, ntrunc
         real(c_double), value :: re
         type(c_ptr) :: plan
      end function ducc_sh_init_c

      subroutine ducc_sh_destroy_c(plan) bind(c, name='ducc_sh_destroy')
         use iso_c_binding, only: c_ptr
         type(c_ptr), value :: plan
      end subroutine ducc_sh_destroy_c

      subroutine ducc_sh_spat2spec_c(plan, z, u, nlat, nlon, ntrunc) bind(c, name='ducc_sh_spat2spec')
         use iso_c_binding, only: c_ptr, c_int, c_double, c_double_complex
         type(c_ptr), value :: plan
         real(c_double), intent(in) :: z(*)
         complex(c_double_complex), intent(out) :: u(*)
         integer(c_int), value :: nlat, nlon, ntrunc
      end subroutine ducc_sh_spat2spec_c

      subroutine ducc_sh_spec2spat_c(plan, z, u, nlat, nlon, ntrunc) bind(c, name='ducc_sh_spec2spat')
         use iso_c_binding, only: c_ptr, c_int, c_double, c_double_complex
         type(c_ptr), value :: plan
         real(c_double), intent(out) :: z(*)
         complex(c_double_complex), intent(in) :: u(*)
         integer(c_int), value :: nlat, nlon, ntrunc
      end subroutine ducc_sh_spec2spat_c
   end interface

contains

   logical function ducc_is_available()
      ducc_is_available = .true.
   end function ducc_is_available


   subroutine ducc_init(plan, nlon, nlat, ntrunc, re)
      type(c_ptr), intent(out) :: plan
      integer, intent(in) :: nlon, nlat, ntrunc
      real, intent(in) :: re

      plan = ducc_sh_init_c(int(nlon, c_int), int(nlat, c_int), int(ntrunc, c_int), real(re, c_double))

      if (.not. c_associated(plan)) then
         write(*,*) 'DUCC initialization failed.'
         stop
      endif
   end subroutine ducc_init


   subroutine ducc_destroy(plan)
      type(c_ptr), intent(inout) :: plan

      if (c_associated(plan)) then
         call ducc_sh_destroy_c(plan)
      endif
      plan = c_null_ptr
   end subroutine ducc_destroy


   subroutine ducc_spat2spec(z, u, plan)
      type(c_ptr), intent(in) :: plan
      real, intent(in) :: z(:,:)
      complex, intent(out) :: u(0:,0:)
      real(c_double), allocatable :: zbuf(:)
      complex(c_double_complex), allocatable :: ubuf(:)
      integer :: nlat, nlon, ntrunc
      integer :: m, n, idx, nspec

      nlat = size(z, 1)
      nlon = size(z, 2)
      ntrunc = size(u, 1) - 1
      nspec = (ntrunc+1)*(ntrunc+2)/2

      allocate(zbuf(nlat*nlon))
      allocate(ubuf(nspec))

      zbuf = reshape(real(z, c_double), (/nlat*nlon/))
      call ducc_sh_spat2spec_c(plan, zbuf, ubuf, int(nlat, c_int), int(nlon, c_int), int(ntrunc, c_int))

      u = (0.0, 0.0)
      idx = 1
      do m = 0, ntrunc
         do n = m, ntrunc
            u(n,m) = cmplx(real(ubuf(idx)), aimag(ubuf(idx)), kind=kind(u(0,0))) / sh_norm
            idx = idx + 1
         enddo
      enddo

      deallocate(zbuf, ubuf)
   end subroutine ducc_spat2spec


   subroutine ducc_spec2spat(z, u, plan)
      type(c_ptr), intent(in) :: plan
      real, intent(out) :: z(:,:)
      complex, intent(in) :: u(0:,0:)
      real(c_double), allocatable :: zbuf(:)
      complex(c_double_complex), allocatable :: ubuf(:)
      integer :: nlat, nlon, ntrunc
      integer :: m, n, idx, nspec

      nlat = size(z, 1)
      nlon = size(z, 2)
      ntrunc = size(u, 1) - 1
      nspec = (ntrunc+1)*(ntrunc+2)/2

      allocate(zbuf(nlat*nlon))
      allocate(ubuf(nspec))

      idx = 1
      do m = 0, ntrunc
         do n = m, ntrunc
            ubuf(idx) = cmplx(real(u(n,m), c_double), aimag(u(n,m)), kind=kind(ubuf)) * sh_norm
            idx = idx + 1
         enddo
      enddo

      call ducc_sh_spec2spat_c(plan, zbuf, ubuf, int(nlat, c_int), int(nlon, c_int), int(ntrunc, c_int))
      z = reshape(real(zbuf, kind(z)), shape(z))

      deallocate(zbuf, ubuf)
   end subroutine ducc_spec2spat

end module ducc_backend_mod
