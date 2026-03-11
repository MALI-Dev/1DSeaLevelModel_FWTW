module ducc_backend_mod

   use iso_c_binding, only: c_ptr, c_null_ptr, c_associated

   implicit none
   private

   public :: ducc_is_available, ducc_init, ducc_destroy, ducc_spat2spec, ducc_spec2spat, ducc_configure

contains

   logical function ducc_is_available()
      ducc_is_available = .false.
   end function ducc_is_available


   subroutine ducc_init(plan, nlon, nlat, ntrunc, re)
      type(c_ptr), intent(out) :: plan
      integer, intent(in) :: nlon, nlat, ntrunc
      real, intent(in) :: re

      plan = c_null_ptr
      if (nlon < 0 .or. nlat < 0 .or. ntrunc < 0 .or. re < 0.0) then
         plan = c_null_ptr
      endif
   end subroutine ducc_init


   subroutine ducc_destroy(plan)
      type(c_ptr), intent(inout) :: plan

      plan = c_null_ptr
   end subroutine ducc_destroy


   subroutine ducc_configure(plan, use_direct_map, nthreads)
      type(c_ptr), intent(in) :: plan
      integer, intent(in) :: use_direct_map
      integer, intent(in) :: nthreads

      if (c_associated(plan) .and. (use_direct_map < -1 .or. nthreads < -1)) then
         continue
      endif
   end subroutine ducc_configure


   subroutine ducc_spat2spec(z, u, plan)
      type(c_ptr), intent(in) :: plan
      real, intent(in) :: z(:,:)
      complex, intent(out) :: u(0:,0:)

      u = (0.0, 0.0)
      if (size(z,1) < 0 .or. c_associated(plan)) then
         u = (0.0, 0.0)
      endif
      write(*,*) 'DUCC backend is not available in this build.'
      stop
   end subroutine ducc_spat2spec


   subroutine ducc_spec2spat(z, u, plan)
      type(c_ptr), intent(in) :: plan
      real, intent(out) :: z(:,:)
      complex, intent(in) :: u(0:,0:)

      z = 0.0
      if (size(u,1) < 0 .or. c_associated(plan)) then
         z = 0.0
      endif
      write(*,*) 'DUCC backend is not available in this build.'
      stop
   end subroutine ducc_spec2spat

end module ducc_backend_mod
