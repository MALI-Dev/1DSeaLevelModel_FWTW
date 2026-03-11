module sh_backend_mod

   use iso_c_binding, only: c_ptr, c_null_ptr
   use spharmt, only: sphere, spharmt_init, spharmt_destroy, spat2spec, spec2spat
   use ducc_backend_mod, only: ducc_is_available, ducc_init, ducc_destroy, ducc_spat2spec, ducc_spec2spat, ducc_configure

   implicit none
   private

   public :: sh_state
   public :: sh_initialize, sh_destroy, sh_spat2spec, sh_spec2spat
   public :: sh_backend_available

   type :: sh_state
      type(sphere) :: spheredat
      type(c_ptr) :: ducc_plan = c_null_ptr
      character(16) :: backend = 'spharmt'
      logical :: initialized = .false.
   end type sh_state

contains

   function lower_string(input_str) result(output_str)
      character(*), intent(in) :: input_str
      character(len(input_str)) :: output_str
      integer :: i, code

      output_str = input_str
      do i = 1, len(input_str)
         code = iachar(output_str(i:i))
         if (code >= iachar('A') .and. code <= iachar('Z')) then
            output_str(i:i) = achar(code + 32)
         endif
      enddo
   end function lower_string


   logical function sh_backend_available(backend_name)
      character(*), intent(in) :: backend_name
      character(16) :: key

      key = trim(adjustl(lower_string(backend_name)))

      if (key == 'spharmt') then
         sh_backend_available = .true.
      elseif (key == 'ducc') then
         sh_backend_available = ducc_is_available()
      else
         sh_backend_available = .false.
      endif
   end function sh_backend_available


   subroutine sh_initialize(state, backend_name, nlon, nlat, ntrunc, re, unit_num, ducc_direct_map, ducc_sht_threads)
      type(sh_state), intent(inout) :: state
      character(*), intent(in) :: backend_name
      integer, intent(in) :: nlon, nlat, ntrunc
      real, intent(in) :: re
      integer, intent(in) :: unit_num
      logical, intent(in), optional :: ducc_direct_map
      integer, intent(in), optional :: ducc_sht_threads
      character(16) :: key
      integer :: direct_map_flag, thread_count

      key = trim(adjustl(lower_string(backend_name)))

      if (key == 'ducc') then
         if (.not. ducc_is_available()) then
            write(unit_num,*) 'DUCC backend was requested but this executable was built without DUCC support.'
            write(unit_num,*) 'Rebuild with USE_DUCC=1 and valid DUCC include/library paths.'
            stop
         endif
         call ducc_init(state%ducc_plan, nlon, nlat, ntrunc, re)

         direct_map_flag = -1
         if (present(ducc_direct_map)) then
            if (ducc_direct_map) then
               direct_map_flag = 1
            else
               direct_map_flag = 0
            endif
         endif

         thread_count = -1
         if (present(ducc_sht_threads)) then
            thread_count = ducc_sht_threads
         endif
         call ducc_configure(state%ducc_plan, direct_map_flag, thread_count)

         state%backend = 'ducc'
      elseif (key == 'spharmt') then
         call spharmt_init(state%spheredat, nlon, nlat, ntrunc, re)
         state%backend = 'spharmt'
      else
         write(unit_num,*) 'Unknown spherical harmonic backend: ', trim(backend_name)
         write(unit_num,*) 'Supported values are: spharmt, ducc'
         stop
      endif

      state%initialized = .true.
   end subroutine sh_initialize


   subroutine sh_destroy(state)
      type(sh_state), intent(inout) :: state

      if (.not. state%initialized) then
         return
      endif

      if (trim(state%backend) == 'ducc') then
         call ducc_destroy(state%ducc_plan)
      else
         call spharmt_destroy(state%spheredat)
      endif

      state%initialized = .false.
      state%backend = 'spharmt'
      state%ducc_plan = c_null_ptr
   end subroutine sh_destroy


   subroutine sh_spat2spec(z, u, state)
      type(sh_state), intent(in) :: state
      real, intent(in) :: z(:,:)
      complex, intent(out) :: u(0:,0:)

      if (trim(state%backend) == 'ducc') then
         call ducc_spat2spec(z, u, state%ducc_plan)
      else
         call spat2spec(z, u, state%spheredat)
      endif
   end subroutine sh_spat2spec


   subroutine sh_spec2spat(z, u, state)
      type(sh_state), intent(in) :: state
      real, intent(out) :: z(:,:)
      complex, intent(in) :: u(0:,0:)

      if (trim(state%backend) == 'ducc') then
         call ducc_spec2spat(z, u, state%ducc_plan)
      else
         call spec2spat(z, u, state%spheredat)
      endif
   end subroutine sh_spec2spat

end module sh_backend_mod
