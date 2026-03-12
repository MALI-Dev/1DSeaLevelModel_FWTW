program sl_model_driver

   use sl_model_mod
   use sl_io_mod
   use user_specs_mod

   implicit none

   integer :: i, itersl, iter, dtime
   real :: starttime                        ! Start time of the simulation
   integer :: iargc, nargs                  ! Arguments read in from a bash script
   character(16) :: carg(20)                ! Arguments from a bash script
#ifdef PERF_TIMING
   real :: perf_start, perf_total
#endif

nargs = iargc()
do i=1,nargs
   call getarg(i, carg(i))
enddo

if (nargs == 4) then ! Check if namelist file is provided
   read (carg(1),*) itersl
   read (carg(2),*) iter      ! the coupling time step we are on (in years)
   read (carg(3),*) dtime     ! coupling time (in years)
   read (carg(4),*) starttime ! start time of the simulation (in years)
elseif (nargs == 5) then
   call sl_drive_readnl(itersl, dtime, starttime)
   read (carg(2),*) iter
   call sl_call_readnl
else
   write(6,*) 'The number of arguments need to be either 4 or 5'
   write(6,*) 'Terminating: program sl_model'
   stop
endif

! check point for time array and coupling
call sl_solver_checkpoint(itersl, dtime)

! set up the temporal resolution
#ifdef PERF_TIMING
call cpu_time(perf_start)
#endif
call sl_timewindow(iter)
#ifdef PERF_TIMING
call cpu_time(perf_total)
write(unit_num,'(A,F10.4,A)') 'PERF_TIMING sl_timewindow=', perf_total - perf_start, ' s'
#endif

! initialize arrays
#ifdef PERF_TIMING
call cpu_time(perf_start)
#endif
call sl_allocate_and_initialize_array
#ifdef PERF_TIMING
call cpu_time(perf_total)
write(unit_num,'(A,F10.4,A)') 'PERF_TIMING sl_allocate_and_initialize_array=', perf_total - perf_start, ' s'
#endif

! intialize and execute the sea-level solver
#ifdef PERF_TIMING
call cpu_time(perf_start)
#endif
if (iter .eq. 0) then
   call sl_solver_init(itersl, starttime)
elseif (iter .gt. 0) then
   call sl_solver(itersl, iter, dtime, starttime)
endif
#ifdef PERF_TIMING
call cpu_time(perf_total)
write(unit_num,'(A,F10.4,A)') 'PERF_TIMING solver_total=', perf_total - perf_start, ' s'
#endif

! deallocate arrays
#ifdef PERF_TIMING
call cpu_time(perf_start)
#endif
call sl_deallocate_array
#ifdef PERF_TIMING
call cpu_time(perf_total)
write(unit_num,'(A,F10.4,A)') 'PERF_TIMING sl_deallocate_array=', perf_total - perf_start, ' s'
#endif
end program sl_model_driver
