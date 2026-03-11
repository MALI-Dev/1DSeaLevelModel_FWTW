program test_sh_backends

   use sh_transform_adapter, only: sh_transform, sh_set_backend, sh_init, sh_destroy, &
                                   sh_spat2spec, sh_spec2spat, SH_BACKEND_SPHARMT, SH_BACKEND_SHTNS

   implicit none

   integer, parameter :: nlat = 32
   integer, parameter :: nlon = 64
   integer, parameter :: ntrunc = 31
   real, parameter :: radius = 6371000.0

   integer :: i, j
   real :: pi, theta, phi
   real :: rel_spec_diff, rel_spat_diff
   real :: rel_rt_spharmt, rel_rt_shtns
   real :: t0, t1
   real :: t_spat2spec_spharmt, t_spat2spec_shtns
   real :: t_spec2spat_spharmt, t_spec2spat_shtns
   real :: ratio_spat2spec, ratio_spec2spat

   type(sh_transform) :: sh_spharmt, sh_shtns

   real, allocatable :: z(:,:), z_rt_spharmt(:,:), z_rt_shtns(:,:)
   complex, allocatable :: u_spharmt(:,:), u_shtns(:,:)

   pi = acos(-1.0)

   allocate(z(nlat, nlon), z_rt_spharmt(nlat, nlon), z_rt_shtns(nlat, nlon))
   allocate(u_spharmt(0:ntrunc, 0:ntrunc), u_shtns(0:ntrunc, 0:ntrunc))

   ! Deterministic, smooth field with mixed zonal and non-zonal content.
   do j = 1, nlon
      phi = 2.0*pi*real(j-1)/real(nlon)
      do i = 1, nlat
         theta = pi*real(i-1)/real(nlat-1)
         z(i,j) = 0.50 + 0.20*cos(theta) + 0.15*sin(theta)*cos(phi) + &
                  0.08*sin(theta)*sin(2.0*phi) + 0.04*cos(3.0*theta)
      enddo
   enddo

   call sh_set_backend(sh_spharmt, SH_BACKEND_SPHARMT)
   call sh_init(sh_spharmt, nlon, nlat, ntrunc, radius)

   call sh_set_backend(sh_shtns, SH_BACKEND_SHTNS)
   call sh_init(sh_shtns, nlon, nlat, ntrunc, radius)

   call cpu_time(t0)
   call sh_spat2spec(z, u_spharmt, sh_spharmt)
   call cpu_time(t1)
   t_spat2spec_spharmt = t1 - t0

   call cpu_time(t0)
   call sh_spat2spec(z, u_shtns, sh_shtns)
   call cpu_time(t1)
   t_spat2spec_shtns = t1 - t0

   call cpu_time(t0)
   call sh_spec2spat(z_rt_spharmt, u_spharmt, sh_spharmt)
   call cpu_time(t1)
   t_spec2spat_spharmt = t1 - t0

   call cpu_time(t0)
   call sh_spec2spat(z_rt_shtns, u_shtns, sh_shtns)
   call cpu_time(t1)
   t_spec2spat_shtns = t1 - t0

   rel_spec_diff = l2_rel_complex(u_shtns, u_spharmt)
   rel_spat_diff = l2_rel_real(z_rt_shtns, z_rt_spharmt)
   rel_rt_spharmt = l2_rel_real(z_rt_spharmt, z)
   rel_rt_shtns = l2_rel_real(z_rt_shtns, z)

   ratio_spat2spec = safe_ratio(t_spat2spec_spharmt, t_spat2spec_shtns)
   ratio_spec2spat = safe_ratio(t_spec2spat_spharmt, t_spec2spat_shtns)

   write(*,'(A)') '=== SH backend comparison test ==='
   write(*,'(A,I0,A,I0,A,I0)') 'Grid: nlat=', nlat, ', nlon=', nlon, ', ntrunc=', ntrunc
   write(*,'(A,ES12.4E2)') 'Relative spectral diff (SHTns vs spharmt): ', rel_spec_diff
   write(*,'(A,ES12.4E2)') 'Relative spatial diff   (SHTns vs spharmt): ', rel_spat_diff
   write(*,'(A,ES12.4E2)') 'Spharmt round-trip relative error:          ', rel_rt_spharmt
   write(*,'(A,ES12.4E2)') 'SHTns round-trip relative error:            ', rel_rt_shtns
   write(*,'(A)') '--- Timing (cpu_time, seconds) ---'
   write(*,'(A,ES12.4E2)') 'spharmt spat2spec: ', t_spat2spec_spharmt
   write(*,'(A,ES12.4E2)') 'SHTns   spat2spec: ', t_spat2spec_shtns
   write(*,'(A,ES12.4E2)') 'speedup (spharmt/SHTns) spat2spec: ', ratio_spat2spec
   write(*,'(A,ES12.4E2)') 'spharmt spec2spat: ', t_spec2spat_spharmt
   write(*,'(A,ES12.4E2)') 'SHTns   spec2spat: ', t_spec2spat_shtns
   write(*,'(A,ES12.4E2)') 'speedup (spharmt/SHTns) spec2spat: ', ratio_spec2spat

   call sh_destroy(sh_spharmt)
   call sh_destroy(sh_shtns)

contains

   real function l2_rel_real(a, b)
      real, dimension(:,:), intent(in) :: a, b
      real :: denom
      denom = sqrt(sum(b*b))
      if (denom <= epsilon(1.0)) then
         l2_rel_real = sqrt(sum((a-b)*(a-b)))
      else
         l2_rel_real = sqrt(sum((a-b)*(a-b))) / denom
      endif
   end function l2_rel_real


   real function l2_rel_complex(a, b)
      complex, dimension(:,:), intent(in) :: a, b
      real :: num, denom
      num = sqrt(sum(abs(a-b)**2))
      denom = sqrt(sum(abs(b)**2))
      if (denom <= epsilon(1.0)) then
         l2_rel_complex = num
      else
         l2_rel_complex = num / denom
      endif
   end function l2_rel_complex


   real function safe_ratio(a, b)
      real, intent(in) :: a, b
      if (abs(b) <= epsilon(1.0)) then
         safe_ratio = 0.0
      else
         safe_ratio = a / b
      endif
   end function safe_ratio

end program test_sh_backends