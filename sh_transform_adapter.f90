module sh_transform_adapter

   use spharmt, only: sphere_spharmt => sphere, &
                      spharmt_init_impl => spharmt_init, &
                      spharmt_destroy_impl => spharmt_destroy, &
                      spat2spec_impl => spat2spec, &
                      spec2spat_impl => spec2spat

   implicit none
   private

   integer, parameter, public :: SH_BACKEND_SPHARMT = 1
   integer, parameter, public :: SH_BACKEND_SHTNS = 2

#ifdef USE_SHTNS_BACKEND
   integer, parameter :: DEFAULT_SH_BACKEND = SH_BACKEND_SHTNS
#else
   integer, parameter :: DEFAULT_SH_BACKEND = SH_BACKEND_SPHARMT
#endif

   type, public :: sh_transform
      integer :: backend = DEFAULT_SH_BACKEND
      type(sphere_spharmt) :: spharmt_state
   end type sh_transform

   public :: sh_set_backend
   public :: sh_init, sh_destroy
   public :: sh_spat2spec, sh_spec2spat

contains

   subroutine sh_set_backend(handle, backend)

      type(sh_transform), intent(inout) :: handle
      integer, intent(in) :: backend

      if (backend /= SH_BACKEND_SPHARMT .and. backend /= SH_BACKEND_SHTNS) then
         write(*,*) 'Unsupported spherical harmonic backend option:', backend
         stop
      endif

      handle%backend = backend

   end subroutine sh_set_backend


   subroutine sh_init(handle, nlon, nlat, ntrunc, re)

      type(sh_transform), intent(inout) :: handle
      integer, intent(in) :: nlon, nlat, ntrunc
      real, intent(in) :: re

      select case (handle%backend)
      case (SH_BACKEND_SPHARMT)
         call spharmt_init_impl(handle%spharmt_state, nlon, nlat, ntrunc, re)
      case (SH_BACKEND_SHTNS)
         write(*,*) 'SHTns backend is selected but not implemented yet in sh_transform_adapter.'
         stop
      end select

   end subroutine sh_init


   subroutine sh_destroy(handle)

      type(sh_transform), intent(inout) :: handle

      select case (handle%backend)
      case (SH_BACKEND_SPHARMT)
         call spharmt_destroy_impl(handle%spharmt_state)
      case (SH_BACKEND_SHTNS)
         ! Placeholder for future SHTns teardown.
      end select

   end subroutine sh_destroy


   subroutine sh_spat2spec(z, u, handle)

      type(sh_transform), intent(in) :: handle
      real, dimension(:,:), intent(in) :: z
      complex, dimension(0:,0:), intent(out) :: u

      select case (handle%backend)
      case (SH_BACKEND_SPHARMT)
         call spat2spec_impl(z, u, handle%spharmt_state)
      case (SH_BACKEND_SHTNS)
         write(*,*) 'SHTns backend is selected but sh_spat2spec is not implemented yet.'
         stop
      end select

   end subroutine sh_spat2spec


   subroutine sh_spec2spat(z, u, handle)

      type(sh_transform), intent(in) :: handle
      real, dimension(:,:), intent(out) :: z
      complex, dimension(0:,0:), intent(in) :: u

      select case (handle%backend)
      case (SH_BACKEND_SPHARMT)
         call spec2spat_impl(z, u, handle%spharmt_state)
      case (SH_BACKEND_SHTNS)
         write(*,*) 'SHTns backend is selected but sh_spec2spat is not implemented yet.'
         stop
      end select

   end subroutine sh_spec2spat

end module sh_transform_adapter