module Mf6CoreModule 
  use KindModule,             only: I4B, LGP
  use ListsModule,            only: basesolutionlist, solutiongrouplist,         &
                                    basemodellist, baseexchangelist,             &
                                    baseconnectionlist
  use BaseModelModule,        only: BaseModelType, GetBaseModelFromList
  use BaseExchangeModule,     only: BaseExchangeType, GetBaseExchangeFromList
  use SpatialModelConnectionModule, only: SpatialModelConnectionType,            &
                                          GetSpatialModelConnectionFromList
  use BaseSolutionModule,     only: BaseSolutionType, GetBaseSolutionFromList
  use SolutionGroupModule,    only: SolutionGroupType, GetSolutionGroupFromList
  implicit none  
contains
  
  subroutine Mf6Run
  ! ******************************************************************************
  ! Main MODFLOW Version 6 program.
  ! ******************************************************************************
  !
  !    SPECIFICATIONS:
  ! ------------------------------------------------------------------------------
    ! -- modules 
    use CommandArguments, only: GetCommandLineArguments
    use TdisModule, only: totim, totalsimtime  
    use KindModule, only: DP
    ! -- dummy
    ! -- local
    logical(LGP) :: hasConverged
    !
    ! -- parse any command line arguments
    call GetCommandLineArguments()
    !
    ! initialize simulation
    call Mf6Initialize()
    !
    ! -- time loop
    tsloop: do while (totim < totalsimtime)
      
      ! perform a time step
      hasConverged = Mf6Update()
      
      ! if not converged, break
      if(.not. hasConverged) exit tsloop   
      
    enddo tsloop
    !
    ! -- finalize simulation
    call Mf6Finalize()
    
  end subroutine Mf6Run
  
  subroutine Mf6Initialize()
    use SimulationCreateModule, only: simulation_cr, connections_cr
    ! -- dummy
    ! -- local
    
    ! -- print banner and info to screen
    call printInfo()
    
    ! -- create
    call simulation_cr()
    call connections_cr()
    
    ! -- define
    call simulation_df()
       
    ! -- allocate and read
    call simulation_ar()
    
  end subroutine Mf6Initialize
  
  function Mf6Update() result(hasConverged)
    ! -- dummy
    logical(LGP) :: hasConverged
    ! -- local
    !
    ! -- prepare timestep
    call Mf6PrepareTimestep()
    !
    ! -- do timestep
    call Mf6DoTimestep()      
    !
    ! -- after timestep
    hasConverged = Mf6FinalizeTimestep()
    !
  end function Mf6Update
  
  subroutine Mf6Finalize()
    use, intrinsic :: iso_fortran_env, only: output_unit
    use ListsModule,            only: lists_da
    use MemoryManagerModule,    only: mem_write_usage, mem_da
    use TimerModule,            only: elapsed_time   
    use SimVariablesModule,     only: iout
    use SimulationCreateModule, only: simulation_da  
    use TdisModule,             only: tdis_da
    use SimModule,              only: final_message
    ! -- dummy
    ! -- local
    integer(I4B) :: im
    integer(I4B) :: ic
    integer(I4B) :: is
    integer(I4B) :: isg
    class(SolutionGroupType), pointer :: sgp => null()
    class(BaseSolutionType), pointer :: sp => null()
    class(BaseModelType), pointer :: mp => null()
    class(BaseExchangeType), pointer :: ep => null()
    class(SpatialModelConnectionType), pointer :: mc => null()
    
    ! -- FINAL PROCESSING (FP)
    ! -- Final processing for each model
    do im = 1, basemodellist%Count()
      mp => GetBaseModelFromList(basemodellist, im)
      call mp%model_fp()
    enddo
    !
    ! -- Final processing for each exchange
    do ic = 1, baseexchangelist%Count()
      ep => GetBaseExchangeFromList(baseexchangelist, ic)
      call ep%exg_fp()
    enddo
    !
    ! -- Final processing for each solution
    do is=1,basesolutionlist%Count()
      sp => GetBaseSolutionFromList(basesolutionlist, is)
      call sp%sln_fp()
    enddo
    !
    ! -- DEALLOCATE (DA)
    ! -- Deallocate tdis
    call tdis_da()
    !
    ! -- Deallocate for each model
    do im = 1, basemodellist%Count()
      mp => GetBaseModelFromList(basemodellist, im)
      call mp%model_da()
      deallocate(mp)
    enddo
    !
    ! -- Deallocate for each exchange
    do ic = 1, baseexchangelist%Count()
      ep => GetBaseExchangeFromList(baseexchangelist, ic)
      call ep%exg_da()
      deallocate(ep)
    enddo
    !
    ! -- Deallocate for each connection
    do ic = 1, baseconnectionlist%Count()
      mc => GetSpatialModelConnectionFromList(baseconnectionlist, ic)
      call mc%exg_da()
      deallocate(mc)
    enddo
    !
    ! -- Deallocate for each solution
    do is=1,basesolutionlist%Count()
      sp => GetBaseSolutionFromList(basesolutionlist, is)
      call sp%sln_da()
      deallocate(sp)
    enddo
    !
    ! -- Deallocate solution group and simulation variables
    do isg = 1, solutiongrouplist%Count()
      sgp => GetSolutionGroupFromList(solutiongrouplist, isg)
      call sgp%sgp_da()
      deallocate(sgp)
    enddo
    call simulation_da()
    call lists_da()
    !
    ! -- Write memory usage, elapsed time and terminate
    call mem_write_usage(iout)
    call mem_da()
    call elapsed_time(iout, 1)
    call final_message()
    !        
  end subroutine Mf6Finalize
  
  subroutine printInfo()
    use SimModule, only: initial_message
    use TimerModule, only: start_time
    !
    ! -- print initial message
    call initial_message()
    !
    ! -- get start time
    call start_time()    
    return
  end subroutine printInfo
  
  subroutine simulation_df()
    ! -- dummy
    ! -- local
    integer(I4B) :: im
    integer(I4B) :: ic
    integer(I4B) :: is
    class(BaseSolutionType), pointer :: sp => null()
    class(BaseModelType), pointer :: mp => null()
    class(BaseExchangeType), pointer :: ep => null()
    class(SpatialModelConnectionType), pointer :: mc => null()
    
    ! -- Define each model
    do im = 1, basemodellist%Count()
      mp => GetBaseModelFromList(basemodellist, im)
      call mp%model_df()
    enddo
    !
    ! -- Define each exchange
    do ic = 1, baseexchangelist%Count()
      ep => GetBaseExchangeFromList(baseexchangelist, ic)
      call ep%exg_df()
    enddo
    !
    ! -- Define each connection
    do ic = 1, baseconnectionlist%Count()
      mc => GetSpatialModelConnectionFromList(baseconnectionlist, ic)
      call mc%exg_df()
    enddo
    !
    ! -- Define each solution
    do is = 1, basesolutionlist%Count()
      sp => GetBaseSolutionFromList(basesolutionlist, is)
      call sp%sln_df()
    enddo
  
  end subroutine simulation_df
  
  subroutine simulation_ar()  
    ! -- dummy
    ! -- local
    integer(I4B) :: im
    integer(I4B) :: ic
    integer(I4B) :: is
    class(BaseSolutionType), pointer :: sp => null()
    class(BaseModelType), pointer :: mp => null()
    class(BaseExchangeType), pointer :: ep => null()
    class(SpatialModelConnectionType), pointer :: mc => null()
    
    ! -- Allocate and read each model
    do im = 1, basemodellist%Count()
      mp => GetBaseModelFromList(basemodellist, im)
      call mp%model_ar()
    enddo
    !
    ! -- Allocate and read each exchange
    do ic = 1, baseexchangelist%Count()
      ep => GetBaseExchangeFromList(baseexchangelist, ic)
      call ep%exg_ar()
    enddo
    !
    ! -- Allocate and read all model connections
    do ic = 1, baseconnectionlist%Count()
      mc => GetSpatialModelConnectionFromList(baseconnectionlist, ic)
      call mc%exg_ar()
    enddo
    !
    ! -- Allocate and read each solution
    do is=1,basesolutionlist%Count()
      sp => GetBaseSolutionFromList(basesolutionlist, is)
      call sp%sln_ar()
    enddo
    !
  end subroutine simulation_ar
  
  subroutine Mf6PrepareTimestep()
    use KindModule,             only: I4B
    use ConstantsModule,        only: LINELENGTH, MNORMAL, MVALIDATE
    use TdisModule,             only: tdis_set_counters, tdis_set_timestep, &
                                      kstp, kper
    use ListsModule,            only: basemodellist, baseexchangelist
    use BaseModelModule,        only: BaseModelType, GetBaseModelFromList
    use BaseExchangeModule,     only: BaseExchangeType, GetBaseExchangeFromList
    use BaseSolutionModule,     only: BaseSolutionType, GetBaseSolutionFromList
    use SimModule,              only: converge_reset
    use SimVariablesModule,     only: isim_mode
    ! -- dummy
    ! -- local
    class(BaseModelType), pointer :: mp => null()
    class(BaseExchangeType), pointer :: ep => null()
    class(BaseSolutionType), pointer :: sp => null()
    character(len=LINELENGTH) :: line
    character(len=LINELENGTH) :: fmt
    integer(I4B) :: im
    integer(I4B) :: ic
    integer(I4B) :: is
    !
    ! -- initialize fmt
    fmt = "(/,a,/)"
    !
    ! -- period update
    call tdis_set_counters()
    !
    ! -- set base line
    write(line, '(a,i0,a,i0,a)')                                                 &
      'start timestep kper="', kper, '" kstp="', kstp, '" mode="'
    !
    ! -- evaluate simulation mode
    select case (isim_mode)
      case (MVALIDATE)
        line = trim(line) // 'validate"'
      case(MNORMAL)
        line = trim(line) // 'normal"'
    end select
    
    ! -- Read and prepare each model
    do im = 1, basemodellist%Count()
      mp => GetBaseModelFromList(basemodellist, im)
      call mp%model_message(line, fmt=fmt)
      call mp%model_rp()
    enddo
    !
    ! -- Read and prepare each exchange
    do ic = 1, baseexchangelist%Count()
      ep => GetBaseExchangeFromList(baseexchangelist, ic)
      call ep%exg_rp()
    enddo
    !
    ! -- reset simulation convergence flag
    call converge_reset()
    !
    ! -- time update for each model
    do im = 1, basemodellist%Count()
      mp => GetBaseModelFromList(basemodellist, im)
      call mp%model_calculate_delt()
    enddo
    !
    ! -- time update for each exchange
    do ic = 1, baseexchangelist%Count()
      ep => GetBaseExchangeFromList(baseexchangelist, ic)
      call ep%exg_calculate_delt()
    enddo
    !
    ! -- time update for each solution
    do is=1,basesolutionlist%Count()
      sp => GetBaseSolutionFromList(basesolutionlist, is)
      call sp%sln_calculate_delt()
    enddo
    !
    ! -- set time step
    call tdis_set_timestep()
    
  end subroutine Mf6PrepareTimestep
  
  subroutine Mf6DoTimestep()
    use KindModule,           only: I4B
    use ListsModule,          only: solutiongrouplist
    use SimVariablesModule,   only: iFailedStepRetry
    use SolutionGroupModule,  only: SolutionGroupType, GetSolutionGroupFromList
    class(SolutionGroupType), pointer :: sgp => null()
    integer(I4B) :: isg
    logical :: finishedTrying
    
    ! -- By default, the solution groups will be solved once, and
    !    may fail.  But if adaptive stepping is active, then
    !    the solution groups may be solved over and over with 
    !    progressively smaller time steps to see if convergence
    !    can be obtained.
    iFailedStepRetry = 0
    retryloop: do
      
      do isg = 1, solutiongrouplist%Count()
        sgp => GetSolutionGroupFromList(solutiongrouplist, isg)
        call sgp%sgp_ca()
      enddo
      
      call sim_step_retry(finishedTrying)
      if (finishedTrying) exit retryloop
      iFailedStepRetry = iFailedStepRetry + 1
      
    end do retryloop
      
  end subroutine Mf6DoTimestep
  
  subroutine sim_step_retry(finishedTrying)
    ! -- modules
    use KindModule, only: DP
    use SimVariablesModule, only: lastStepFailed
    use SimModule, only: converge_reset
    use TdisModule, only: kstp, kper, delt, tdis_delt_reset
    use AdaptiveTimeStepModule, only: ats_reset_delt
    ! -- dummy
    logical, intent(out) :: finishedTrying
    ! -- local
    !
    ! -- Check with ats to reset delt and keep trying
    finishedTrying = .true.
    call ats_reset_delt(kstp, kper, lastStepFailed, delt, finishedTrying)
    !
    if (.not. finishedTrying) then
      !
      ! -- Reset delt, which requires updating pertim, totim
      !    and end of period and simulation indicators        
      call tdis_delt_reset(delt)
      !
      ! -- Reset state of the simulation convergence flag
      call converge_reset()
      
    end if
    return
  end subroutine sim_step_retry
  
  function Mf6FinalizeTimestep() result(hasConverged)
    use KindModule,             only: I4B
    use ConstantsModule,        only: LINELENGTH, MNORMAL, MVALIDATE
    use ListsModule,            only: basesolutionlist, basemodellist, baseexchangelist    
    use BaseModelModule,        only: BaseModelType, GetBaseModelFromList
    use BaseExchangeModule,     only: BaseExchangeType, GetBaseExchangeFromList
    use BaseSolutionModule,     only: BaseSolutionType, GetBaseSolutionFromList
    use SimModule,              only: converge_check
    use SimVariablesModule,     only: isim_mode
    ! -- dummy
    logical(LGP) :: hasConverged    
    ! -- local
    class(BaseSolutionType), pointer :: sp => null()
    class(BaseModelType), pointer :: mp => null()
    class(BaseExchangeType), pointer :: ep => null()
    character(len=LINELENGTH) :: line
    character(len=LINELENGTH) :: fmt
    integer(I4B) :: im
    integer(I4B) :: ic
    integer(I4B) :: is
    ! -- code
    !
    ! -- initialize format and line
    fmt = "(/,a,/)"
    line = 'end timestep'
    !
    ! -- evaluate simulation mode
    select case (isim_mode)
      case(MVALIDATE)
        !
        ! -- Write final message for timestep for each model 
        do im = 1, basemodellist%Count()
          mp => GetBaseModelFromList(basemodellist, im)
          call mp%model_message(line, fmt=fmt)
        end do
      case(MNORMAL)
        !
        ! -- Write output and final message for timestep for each model 
        do im = 1, basemodellist%Count()
          mp => GetBaseModelFromList(basemodellist, im)
          call mp%model_ot()
          call mp%model_message(line, fmt=fmt)
        enddo
        !
        ! -- Write output for each exchange
        do ic = 1, baseexchangelist%Count()
          ep => GetBaseExchangeFromList(baseexchangelist, ic)
          call ep%exg_ot()
        enddo
        !
        ! -- Write output for each solution
        do is=1,basesolutionlist%Count()
          sp => GetBaseSolutionFromList(basesolutionlist, is)
          call sp%sln_ot()
        enddo
    end select
    !
    ! -- Check if we're done
    call converge_check(hasConverged)
    !
    ! -- return
    return    
    
  end function Mf6FinalizeTimestep
  
end module Mf6CoreModule
