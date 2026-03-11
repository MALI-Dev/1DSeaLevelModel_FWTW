program test_sh_backends

   use sh_backend_mod, only: sh_state, sh_initialize, sh_destroy, sh_spat2spec, sh_spec2spat

   implicit none

   integer, parameter :: nlat = 32
   integer, parameter :: nlon = 64
   integer, parameter :: ntrunc = 31
   real, parameter :: radius = 6371000.0

   integer :: i, j
   real :: pi, theta, phi
   real :: rel_spec_diff, rel_spat_diff
   real :: rel_rt_spharmt, rel_rt_ducc
   real :: t0, t1
   real :: t_spat2spec_spharmt, t_spat2spec_ducc
   real :: t_spec2spat_spharmt, t_spec2spat_ducc
   real :: ratio_spat2spec, ratio_spec2spat

   type(sh_state) :: sh_spharmt, sh_ducc
   real, dimension(nlat, nlon) :: z
   real, dimension(nlat, nlon) :: z_spharmt, z_ducc
   complex, dimension(0:ntrunc,0:ntrunc) :: u_spharmt, u_ducc

   pi = acos(-1.0)

   do j = 1, nlon
      phi = 2.0*pi*real(j-1)/real(nlon)
      do i = 1, nlat
         theta = pi*real(i-1)/real(nlat-1)
         z(i,j) = 0.8*sin(theta)*cos(2.0*phi) + 0.4*cos(3.0*theta) + 0.2*sin(2.0*theta + phi)
      enddo
   enddo

   call sh_initialize(sh_spharmt, 'spharmt', nlon, nlat, ntrunc, radius, 6)
   call sh_initialize(sh_ducc, 'ducc', nlon, nlat, ntrunc, radius, 6)

   call cpu_time(t0)
   call sh_spat2spec(z, u_spharmt, sh_spharmt)
   call cpu_time(t1)
   t_spat2spec_spharmt = t1 - t0

   call cpu_time(t0)
   call sh_spat2spec(z, u_ducc, sh_ducc)
   call cpu_time(t1)
   t_spat2spec_ducc = t1 - t0

   call cpu_time(t0)
   call sh_spec2spat(z_spharmt, u_spharmt, sh_spharmt)
   call cpu_time(t1)
   t_spec2spat_spharmt = t1 - t0

   call cpu_time(t0)
   call sh_spec2spat(z_ducc, u_ducc, sh_ducc)
   call cpu_time(t1)
   t_spec2spat_ducc = t1 - t0

   rel_spec_diff = l2_rel_complex(u_ducc, u_spharmt)
   rel_spat_diff = l2_rel_real(z_ducc, z_spharmt)
   rel_rt_spharmt = l2_rel_real(z_spharmt, z)
   rel_rt_ducc = l2_rel_real(z_ducc, z)

   ratio_spat2spec = safe_ratio(t_spat2spec_spharmt, t_spat2spec_ducc)
   ratio_spec2spat = safe_ratio(t_spec2spat_spharmt, t_spec2spat_ducc)

   write(*,'(A,I4,A,I4,A,I4)') 'Test grid nlat=', nlat, ', nlon=', nlon, ', ntrunc=', ntrunc
   write(*,'(A,ES12.4E2)') 'Relative spectral diff (DUCC vs spharmt): ', rel_spec_diff
   write(*,'(A,ES12.4E2)') 'Relative spatial diff   (DUCC vs spharmt): ', rel_spat_diff
   write(*,'(A,ES12.4E2)') 'Spharmt round-trip relative error:         ', rel_rt_spharmt
   write(*,'(A,ES12.4E2)') 'DUCC round-trip relative error:            ', rel_rt_ducc

   write(*,'(A)') '--- Timing (cpu_time, seconds) ---'
   write(*,'(A,ES12.4E2)') 'spharmt spat2spec: ', t_spat2spec_spharmt
   write(*,'(A,ES12.4E2)') 'DUCC    spat2spec: ', t_spat2spec_ducc
   write(*,'(A,ES12.4E2)') 'speedup (spharmt/DUCC) spat2spec: ', ratio_spat2spec
   write(*,'(A,ES12.4E2)') 'spharmt spec2spat: ', t_spec2spat_spharmt
   write(*,'(A,ES12.4E2)') 'DUCC    spec2spat: ', t_spec2spat_ducc
   write(*,'(A,ES12.4E2)') 'speedup (spharmt/DUCC) spec2spat: ', ratio_spec2spat

   call sh_destroy(sh_spharmt)
   call sh_destroy(sh_ducc)

contains

   real function l2_rel_real(a, b)
      real, dimension(:,:), intent(in) :: a, b
      real :: denom
      denom = sqrt(sum(b*b))
      if (denom <= epsilon(1.0)) then
         l2_rel_real = sqrt(sum((a-b)*(a-b)))
      else
         l2_rel_real = sqrt(sum((a-b)*(a-b)))/denom
      endif
   end function l2_rel_real


   real function l2_rel_complex(a, b)
      complex, dimension(:,:), intent(in) :: a, b
      real :: denom
      denom = sqrt(sum(abs(b)**2))
      if (denom <= epsilon(1.0)) then
         l2_rel_complex = sqrt(sum(abs(a-b)**2))
      else
         l2_rel_complex = sqrt(sum(abs(a-b)**2))/denom
      endif
   end function l2_rel_complex


   real function safe_ratio(a, b)
      real, intent(in) :: a, b
      if (abs(b) <= epsilon(1.0)) then
         safe_ratio = 0.0
      else
         safe_ratio = a/b
      endif
   end function safe_ratio

end program test_sh_backends
