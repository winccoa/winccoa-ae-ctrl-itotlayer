// $License: NOLICENSE

/**
 * @file scripts/libs/Diagnostics.ctl
 * @brief Contains various useful functions for diagnostics.
 */

// used libraries (#uses)
#uses "EB_Package_Base/EB_UtilsFile"
#uses "EB_Package_Base/EB_UtilsPmon"
#uses "classes/EBTag"
#uses "Logging"

const string sDBG_SIM = "sim"; //switch for simulation (read from ressource monitor DPEs) instead of calculation of CPU and memory
const int iCTRL_MANAGER_NUMMER_OFFSET = 300; ////ctrl manager have offset of iCTRL_MANAGER_NUMMER_OFFSET
const int iDATA_MANAGER_NUMMER_OFFSET = 400; ////data manager has offset of iDATA_MANAGER_NUMMER_OFFSET
const int iEVENT_MANAGER_NUMMER_OFFSET = 500; ////event manager has offset of iEVENT_MANAGER_NUMMER_OFFSET

enum Counters
{
  Connections,
  Tags
};

/**
 * @brief This is the utility class for diagnostics. It contains various useful functions for diagnostics.
 */
class Diagnostics
{
  /**
   * @brief Restarts the (first) manager with the specified name
   * @details Example S7+ driver:   'restartManager(getComponentName(S7PLUS_COMPONENT), "");'
   *          Example CTRL manager: 'restartManager(getComponentName(CTRL_COMPONENT),   "EB_Package_MTConnect/Service.ctl");'
   * @param sManager    Process name of the manager (for example: WCCOAs7)
   * @param sOptions    Empty to ignore the options OR exact option match (after removing debug flags from the pmon option)
   * @return Pmon index of the restarted manager OR -1 if manager was not found
   */
  public static int restartManager(const string &sManager, const string &sOptions)
  {
    // Determine the pmon index of the specified manager
    int iIndex = findPmonIndex(sManager, sOptions);

    // Check if the manager was found
    if (iIndex > 0)
    {
      ///@todo Check if the start mode is set to 'always'
      bool bAutoStart;
      iIndex--; //pmon index is index-1

      // Log this action
      Logging::write(LogCategory::Runtime, Logging::MANAGER_RESTART, (int)LogSeverity::Information, makeDynAnytype(sManager, sOptions));

      // Stop the manager
      EB_UtilsPmon::command("SINGLE_MGR:STOP " + iIndex);

      if (!bAutoStart)
      {
        // Give the manager some time to stop and for the pmon to detect the stopped manager
        delay(1);

        // Start the manager
        EB_UtilsPmon::command("SINGLE_MGR:START " + iIndex);
      }
    }

    return iIndex;
  }

  /**
   * @brief Restarts the whole project
   * @return Always 0
   */
  public static int restartProject()
  {
    // Log this action
    Logging::write(LogCategory::Runtime, Logging::PROJECT_RESTART, (int)LogSeverity::Information, makeDynAnytype());

    EB_UtilsPmon::command("RESTART_ALL");

    return 0;
  }

  /**
   * @brief Activates the flags on the (first) manager with the specified name
   * @param sManager    Process name of the manager
   * @param sOptions    Empty to ignore the options OR exact option match (after removing debug flags from the pmon option)
   * @param sFlags      Flags to activate (for example: '-dbg WORK -report ALL -rcv 2 -snd 2' OR empty to deactivate all flags)
   * @return Pmon index of the manager OR -1 if manager was not found
   */
  public static int activateFlags(const string &sManager, const string &sOptions, const string &sFlags)
  {
    // Determine the pmon index of the specified manager
    int iIndex = findPmonIndex(sManager, sOptions);

    if (iIndex > 0)
    {
      dyn_dyn_string ddsStati = EB_UtilsPmon::query("MGRLIST:STATI");

      // Determine the process id of the specified manager
      int iPid = ddsStati[iIndex][(int)PmonStatiFields::PID];

      // Write the debug/report flags to the debug file
      EB_UtilsFile::writeToFile(PROJ_PATH + LOG_REL_PATH + "dbg", sFlags != "" ? sFlags + " " : "-dbg NONE -rcv 0 -snd 0 ");

      // Activate the flags by sending signal 3
      system((_WIN32 ? "pkill.exe" : "kill") + " -3 " + iPid);
    }

    return iIndex;
  }

  /**
   * @brief Returns a list of running managers
   * @return List of running managers
   */
  public static dyn_mapping getRunningManagers()
  {
    dyn_mapping dmResult;
    dyn_dyn_string ddsList  = EB_UtilsPmon::query("MGRLIST:LIST");
    dyn_dyn_string ddsStati = EB_UtilsPmon::query("MGRLIST:STATI");

    for (int i = 1; i <= dynlen(ddsList) && i <= dynlen(ddsStati); i++)
    {
      // Check if this manager is running
      if (ddsStati[i][(int)PmonStatiFields::State] == 2)
      {
        dynAppend(dmResult, makeMapping("manager", ddsList[i][(int)PmonListFields::Manager], "startTime", ddsStati[i][(int)PmonStatiFields::StartTime]));
      }
    }

    return dmResult;
  }

  /**
   * @brief Returns a list of stopped managers, which should run
   * @return List of stopped managers, which should run
   */
  public static dyn_mapping getStoppedManagers()
  {
    dyn_mapping dmResult;
    dyn_dyn_string ddsList  = EB_UtilsPmon::query("MGRLIST:LIST");
    dyn_dyn_string ddsStati = EB_UtilsPmon::query("MGRLIST:STATI");

    for (int i = 1; i <= dynlen(ddsList) && i <= dynlen(ddsStati); i++)
    {
      // Check if this manager is stopped and should be running
      if (ddsStati[i][(int)PmonStatiFields::State]     == 0 &&  // 0 == stopped
          ddsStati[i][(int)PmonStatiFields::StartMode] == 2)    // 2 == always
      {
        dynAppend(dmResult, makeMapping("manager", ddsList[i][(int)PmonListFields::Manager]));
      }
    }

    return dmResult;
  }

  /**
   * @brief start thread for monitoring CPU and Memory usage of all managers
   * @param iInterval        interval in sec for checking the cpu consumption
   * @param mConfig          configuration (file content of config/logging.tsv)
   */
  public static void startCpuMemMonitoring(int iInterval, const mapping &mConfig)
  {
    startThread("threadCpuMemMonitor", iInterval, mConfig);
  }

  /**
   * @brief Updates the connections/tags counters
   */
  public static void updateCounters()
  {
    int iConnections = countConnections();
    int iTags        = countTags();

    if (g_mCounters[Counters::Connections] != iConnections)
    {
      g_mCounters[Counters::Connections] = iConnections;

      Logging::write(LogCategory::Internal, Logging::COUNT_CONNECTIONS, LogSeverity::Information, makeDynAnytype(iConnections));
    }

    if (g_mCounters[Counters::Tags] != iTags)
    {
      g_mCounters[Counters::Tags] = iTags;

      Logging::write(LogCategory::Internal, Logging::COUNT_TAGS, LogSeverity::Information, makeDynAnytype(iTags));
    }
  }

  /**
   * @brief Returns the number of configured connections
   * @return Number of connections
   */
  public static int countConnections()
  {
    dyn_string dsPaths;

    // Count the 'connections' (each device is a connection)
    cnsGetNodesByName("*." + EB_PREFIX_PACKAGE + "*:*", CNS_SEARCH_NAME, CNS_SEARCH_ALL_LANGUAGES, (int)EBNodeType::DEVICE, dsPaths);

    return dynlen(dsPaths);
  }

  /**
   * @brief Returns the number of active tags
   * @return Number of active tags
   */
  public static int countActiveTags()
  {
    int iResult;
    bool bExpired;
    dyn_string  dsDps = dpNames("*", "_DriverCommon");
    dyn_string  dsDpesToSet;
    dyn_string  dsDpesToGet;
    dyn_anytype daSetValues;
    dyn_anytype daGetValues;

    for (int i = 1; i <= dynlen(dsDps); i++)
    {
      dynAppend(dsDpesToSet, dsDps[i] + ".AD.HWMask");
      dynAppend(dsDpesToGet, dsDps[i] + ".AD.DPMatch:_online.._value");
      dynAppend(daSetValues, "*");
    }

    dpSetAndWaitForValue(dsDpesToSet, daSetValues, dsDpesToGet, daGetValues, dsDpesToGet, daGetValues, 5.0, bExpired);

    if (bExpired)
    {
      iResult = -1;
    }
    else
    {
      for (int i = 1; i <= dynlen(daGetValues); i++)
      {
        iResult += dynlen(daGetValues[i]);
      }
    }

    return iResult;
  }

  /**
   * @brief Returns the number of created tags
   * @return Number of tags
   */
  public static int countTags()
  {
    int iResult;
    dyn_string dsPaths;

    // Count the 'normal' tags
    cnsGetNodesByName("*." + EB_PREFIX_PACKAGE + "*:*", CNS_SEARCH_NAME, CNS_SEARCH_ALL_LANGUAGES, CNS_DATATYPE_DATAPOINT, dsPaths);

    iResult += dynlen(dsPaths);

    // Also count the tags from the subscribe app
    cnsGetNodesByName("*." + EB_PREFIX_PACKAGE + "*:*", CNS_SEARCH_NAME, CNS_SEARCH_ALL_LANGUAGES, (int)EBNodeType::SUBSCRIBED, dsPaths);

    iResult += dynlen(dsPaths);

    return iResult;
  }

  /**
 * @brief Checks the log conditions and logs this event on change
 * @param ddaUserData      User data from the configuration file
 * @param sDpe1            Dpe of the value
 * @param aValue           Value of the dpe to log
 * @param iLogActive       Log flag to indicate if this value is already logged (-1 is unknown -> autodetect)
 * @param daArguments      Additional arguments for the log text (replaces the $1, $2, etc of the log text)
 * @param sId              Optional: extra id for the log reason (for example: device id or dp)
 * @param bLogInFileFirst  Optional: write log entry int log file before sending to event manager
 * @param sManagerKey      Optional: Manager number in '%03d' format
 */
  public static void checkLog(const dyn_dyn_anytype &ddaUserData, const string &sDpe, const anytype &aValue, int iLogActive=-1, const dyn_anytype &daArguments, string sId = "", bool bLogInFileFirst = FALSE, string sManagerKey = "")
  {
    dyn_bool dbConditionsMet;
    string sDpeClean = dpSubStr(sDpe, DPSUB_SYS_DP_EL); //withoutConfig

    int iLogActiveCurrently;
    if (iLogActive == -1) //autodetect log state
    {
      if (!mappingHasKey(g_mLogDpeLogState, sDpeClean))
      {
        dpGet(sDpeClean + ":_original.._userbit" + USERBIT_LOG, iLogActiveCurrently);

        if (iLogActiveCurrently == 1) //flag only indicates at minimum 1 log, so we have to count the logs for that DPE
        {
          iLogActiveCurrently = 0;
          for(int i = dynlen(ddaUserData); i > 0; i--)
          {
            iLogActiveCurrently += Logging::getCount(ddaUserData[i][1], sId, sManagerKey);
          }
        }
        else
        {
          g_mLogDpeLogState[sDpeClean] = iLogActiveCurrently;
        }
      }
      else
      {
        iLogActiveCurrently = g_mLogDpeLogState[sDpeClean];
      }
    }
    else
    {
      iLogActiveCurrently = iLogActive;
    }

    // First check which conditions meet the condition to write a log message
    for (int i = 1; i <= dynlen(ddaUserData); i++)
    {
      dbConditionsMet[i] = isConditionMet(aValue, ddaUserData[i][3]);
    }

    if (dynCount(dbConditionsMet, TRUE) == iLogActiveCurrently)
    {
      // Do nothing, logging condition has not changed
      DebugFTN("LOG_CHECK", __FUNCTION__ + "(..., " + sDpe + ", " + aValue + ", " + iLogActiveCurrently + ", ..., " + sId + ") Log condition has NOT changed", getDynString(ddaUserData, 3), dbConditionsMet);
    }
    else
    {
      bool bSetFlag;
      bool bSetLogActive;

      for (int i = 1; i <= dynlen(dbConditionsMet); i++)
      {
        string sLogId    = ddaUserData[i][1];
        strreplace(sLogId, "???", "");
        int    iSeverity = ddaUserData[i][2];
        bool   bPending  = iSeverity > (int)LogSeverity::Information;

        // Make sure the severity value is inside the valid range
        if (iSeverity < (int)LogSeverity::First || (int)LogSeverity::Last < iSeverity)
        {
          iSeverity = (int)LogSeverity::Information;
        }

        // Check if the optional pending flag has been specified
        if (dynlen(ddaUserData) >= 4)
        {
          bPending = ddaUserData[4];
        }

        // (Re)set the log
        changeLog(dbConditionsMet[i], sLogId, (LogSeverity)iSeverity, bPending, daArguments, sId, 0, bLogInFileFirst, sManagerKey);
        DebugFTN("LOG_CHECK", __FUNCTION__ + "(..., " + sDpe + ", " + aValue + ", " + iLogActiveCurrently + ", ..., " + sId + ") Log condition changed", getDynString(ddaUserData, 3), dbConditionsMet[i]);
        bSetFlag |= bPending;
        bSetLogActive |= dbConditionsMet[i];
      }
      iLogActiveCurrently = dynCount(dbConditionsMet, TRUE);
      setLogUserBitOnDpe(sDpe, bSetFlag, iLogActiveCurrently);
    }
  }

 /**
 * @brief Returns if the value meets the specified condition
 * @param aValue        Value to check
 * @param sCondition    Condition from the configuration
 * @return TRUE if the condition is met
 */
  public static bool isConditionMet(const anytype &aValue, const string &sCondition)
  {
    bool bResult;

    switch (sCondition[0])
    {
      case '=': bResult = aValue == substr(sCondition, 1); break;
      case '!': bResult = aValue != substr(sCondition, 1); break;
      case '<': bResult = aValue <  substr(sCondition, 1); break;
      case '>': bResult = aValue >  substr(sCondition, 1); break;
    }

    return bResult;
  }


  /**
   * @brief Writes/clears the specified log
   * @param bSet             Set or reset the log
   * @param sKey             Message catalog key and the log reason
   * @param eSeverity        Severity of the log
   * @param bPending         Set to keep the log active
   * @param daArguments      Additional arguments for the log text (replaces the $1, $2, etc of the log text)
   * @param sId              Optional: extra id for the log reason (for example: device id or dp)
   * @param tTime            Optional: Time for the log (default: current time)
   * @param bLogInFileFirst  Optional: write log entry int log file before sending to event manager
   * @param sManagerKey      Optional: Manager number in '%03d' format
   */
  public static void changeLog(bool bSet, const string &sKey, LogSeverity eSeverity, bool bPending, const dyn_anytype &daArguments, string sId = "", time tTime = 0, bool bLogInFileFirst = FALSE, string sManagerKey = "")
  {
    string sReason = sKey;

    // Add the optional value to the reason
    if (sId != "")
    {
      sReason += " (" + sId + ")";
    }

    DebugFTN("LOG_CHANGE", __FUNCTION__ + "(" + bSet + ", " + sKey + ", " + eSeverity + ", " + bPending + ", ..., " + sId + ", " + (string)tTime + ") Changing log with reason: " + sReason, daArguments);

    // Check if a new log entry must be created
    if (bSet)
    {
      // Write the log entry
      Logging::write(LogCategory::Runtime, sKey, eSeverity, daArguments, sId, bPending, sManagerKey, tTime, bLogInFileFirst);
    }
    else if (bPending)
    {
      // Remove the log entry
      Logging::clear(LogCategory::Runtime, sKey, sId, sManagerKey);
    }
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
 /**
 * @brief function to set log flag or ack alarm on DPE
 * @param sDpe            set falg to active or remove the flag from DPE
 * @param bChangeLogFlag  change flag or ack alarm
 * @param iSetLogActive   set falg to active or remove the flag from DPE (default is true - is not used for alarm ack)
 */
  private static void setLogUserBitOnDpe(string sDpe, bool bChangeLogFlag, int iSetLogActive = 1)
  {
    if (bChangeLogFlag)
    {
      // Set the log flag to keep track across restarts if the change is already written
      dpSet(dpSubStr(sDpe, DPSUB_SYS_DP_EL) + ":_original.._userbit" + USERBIT_LOG, iSetLogActive);
      g_mLogDpeLogState[dpSubStr(sDpe, DPSUB_SYS_DP_EL)] = iSetLogActive;
    }
    else if (dpSubStr(sDpe, DPSUB_CONF) == ":_alert_hdl")
    {
      // Acknowledge the alert, so leaving the alert range again can be detected (used to generate the 'emergency mode solved' log)
      dpSet(dpSubStr(sDpe, DPSUB_SYS_DP_EL) + ":_alert_hdl.._ack", DPATTR_ACKTYPE_SINGLE);
    }
  }

  /**
   * @brief remove log enties for reason pattern
   * @param sReason        reason pattern (will be extended with "*")
   * @param bAddLogToFile  add log message to log file
   */
  private static void doRemoveLog(const string &sReason, bool bAddLogToFile = TRUE)
  {
    // Remove log entry
    dyn_atime datDummy;
    g_spLog.removePendingLogs(LOG_TYPE_RUNTIME, datDummy, 0, sReason + "*", bAddLogToFile);
  }

  /**
   * @brief worker thread to check CPU and memory consumption of managers regularely, logs of not existing managers will be removed on startup
   * @param iInterval        interval in sec for checking the cpu consumption
   * @param mConfig          configuration (file content of config/logging.tsv)
   */
  private static void threadCpuMemMonitor(int iInterval, const mapping &mConfig)
  {
    dyn_ulong dulSystemTicks = makeDynULong(0ul, 0ul);
    dyn_ulong dulTicks;

    // Determine the pmon index of the event manager this cannot
    // change in a running project, so it is safe to do this only once
    int iPmonIndexEvent = findPmonIndex(getComponentName(EVENT_COMPONENT), "");

    mapping mLastTicksPerPid;
    dyn_string dsOriginalListOfManagers = dpNames(sManagerCpuMemDpPrefix + "*", sManagerCpuMemDpt);
    for (int i=dynlen(dsOriginalListOfManagers); i>0; i--)
    {
      dsOriginalListOfManagers[i] = dpSubStr(dsOriginalListOfManagers[i], DPSUB_DP);
    }
    int iRun = 0;
    for (; TRUE; delay(iInterval))
    {
      iRun++;
      bSimulate = isDbgFlag(sDBG_SIM); //switch for simulation (read from ressource monitor DPEs) instead of calculation of CPU and memory

      mapping mPidTicksMem;
      getPidTicksMappping(mPidTicksMem);

      dyn_ulong dulUsedTicks  = readUsedCpuTicks();
      dyn_ulong dulMemory = readAvailableVirtualMemory();
      ulong ulTotalMemory = dulMemory[1];
      ulong ulIdelMemory = dulMemory[2];

      ulong ulUsedCpu = dulUsedTicks[1] - dulSystemTicks[1];    //idle CPU

      if (bSimulate)
      {
        ulUsedCpu = 9999;
        ulTotalMemory = 9999;
      }

      ulong ulUsedCpuPerCore = ulUsedCpu / iNrOfCpuCores;       //each process uses one core
      ulong ulIdleCpu = dulUsedTicks[2] - dulSystemTicks[2];    //project consumption
      ulong ulPrjSumCpu;
      ulong ulPrjSumMemory;



      // Store the cpu tick count, so the next time we can use it to determine the total tick count and calculate the CPU usage percentages
      dulSystemTicks = dulUsedTicks;

      dyn_int diPids = mappingKeys(mPidTicksMem);
      dyn_int diLastPids = mappingKeys(mLastTicksPerPid);
      dyn_string dsDPEs = makeDynString(sManagerCpuMemDpPrefix + "Idle.cpu", sManagerCpuMemDpPrefix + "Idle.memory");
      dyn_float dfVals = makeDynFloat(ulIdleCpu * 100.0 / ulUsedCpu, ulIdelMemory * 100.0/ulTotalMemory);



      //remove last saved ticks for stopped processes
      for(int i = dynlen(diLastPids); i > 0; i--)
      {
        if (dynContains(diPids, diLastPids[i])<1)
        {
          doRemoveLog(mLastTicksPerPid[diLastPids[i]]["man"]);
          mappingRemove(mLastTicksPerPid, diLastPids[i]);
          dynRemove(diLastPids, i);
        }
      }

      // The last line does not contain the status of a manager,
      // so skip the last line (with the pmon, emergency and demo mode)
      for (int i = dynlen(diPids); i > 0; i--)
      {
        int iPid = diPids[i];
        if (dynContains(diLastPids, iPid)>0) //last ticks exist
        {
          string sDP = sManagerCpuMemDpPrefix + mPidTicksMem[iPid]["man"];
          if (!dpExists(sDP))
          {
            dpCreate(sDP, sManagerCpuMemDpt);
          }
          ulong ulCpuTicksDiff = mPidTicksMem[iPid]["ticks"] - mLastTicksPerPid[iPid]["ticks"];
          float fCpu = ulCpuTicksDiff * 100.0 / ulUsedCpuPerCore;
          dynAppend(dfVals, fCpu);
          ulPrjSumCpu += ulCpuTicksDiff;
          dynAppend(dsDPEs, sDP + ".cpu");
          doCheckLogWithRule(mConfig, sDP + ".cpu", fCpu, mPidTicksMem[iPid]["man"], mPidTicksMem[iPid]["ManagerKey"]);

          float fMem =  100.0 * mPidTicksMem[iPid]["mem"] / ulTotalMemory;
          dynAppend(dfVals, fMem);
          ulPrjSumMemory += fMem;
          dynAppend(dsDPEs, sDP + ".memory");

          doCheckLogWithRule(mConfig, sDP + ".memory", fMem, mPidTicksMem[iPid]["man"], mPidTicksMem[iPid]["ManagerKey"]);
        }
        if(!mappingHasKey(mLastTicksPerPid, iPid))
        {
          mLastTicksPerPid[iPid] = mPidTicksMem[iPid];
        }
        else
        {
          mLastTicksPerPid[iPid]["ticks"] = mPidTicksMem[iPid]["ticks"];
        }
      }
      if (dynlen(dsDPEs)>1)
      {
        dynAppend(dsDPEs, sManagerCpuMemDpPrefix + "Project.cpu");
        dynAppend(dfVals, ulPrjSumCpu * 100.0 / ulUsedCpu);
        doCheckLogWithRule(mConfig, dsDPEs[dynlen(dsDPEs)], dfVals[dynlen(dfVals)], "Project", "000");

        dynAppend(dsDPEs, sManagerCpuMemDpPrefix + "Project.memory");
        dynAppend(dfVals, ulPrjSumMemory);
        doCheckLogWithRule(mConfig, dsDPEs[dynlen(dsDPEs)], dfVals[dynlen(dfVals)], "Project", "000");
      }
      doCheckLogWithRule(mConfig, dsDPEs[1], dfVals[1], "Idle"); //idle

      if (!bSimulate)
      {
        dpSet(dsDPEs, dfVals);
      }
      DebugFTN("CPU_TICKS", "cpu check set datapoints", dsDPEs, dfVals, iRun);

      if (iRun == 2) //remove old logs from project start time (fist calculation is on second loop - because to get diff), if no manager exists anymore
      {
        for (int i = dynlen(dsOriginalListOfManagers); i > 0; i--)
        {
          if (dynContains(dsDPEs, dsOriginalListOfManagers[i]) < 1) //value has not been updated this (first) run
          {
            DebugFTN("CPU_TICKS", "cpu check - remove logs on startup for not existing managers", dsOriginalListOfManagers[i], substr(dsOriginalListOfManagers[i], strlen(sManagerCpuMemDpPrefix), strlen(dsOriginalListOfManagers[i])-strlen(sManagerCpuMemDpPrefix)+-1));
            doRemoveLog("* (" + substr(dsOriginalListOfManagers[i]+".cpu", strlen(sManagerCpuMemDpPrefix), strlen(dsOriginalListOfManagers[i])-strlen(sManagerCpuMemDpPrefix)+-1) +")");
            setLogUserBitOnDpe(dsOriginalListOfManagers[i] +".cpu", TRUE, FALSE); //reset datapoint flag
          }
        }
        dynClear(dsOriginalListOfManagers); //clean up is only requred once on start up for removed managers
      }
    }
  }

  /**
   * @brief function to evaluate rule for certain manager or generic one and executes checkLog function with fittein rule, if there is one
   * @param mConfig          configuration (file content of config/logging.tsv)
   * @param sDPE             cpu consumtion datapoint element, where to save the consumption value
   * @param iVal             cpu usage in %
   * @param sId              reason id to be used (required for update and delete correct logs later)
   * @param sManagerKey      Optional: Manager number in '%03d' format
   */
  private static void doCheckLogWithRule(const mapping &mConfig, const string &sDPE, int iVal, string sId="", string sManagerKey = "")
  {
    //log or remove log - if dedicated manager rule or generic rule has been found
    string sElement = substr(sDPE, strpos(sDPE, "."));
    string sKey = mappingHasKey(mConfig, sDPE) ? sDPE : (mappingHasKey(mConfig, sManagerCpuMemDpPrefix + "*" + sElement) ? sManagerCpuMemDpPrefix + "*" + sElement : "");
    if (sKey != "")
    {
      if (bSimulate)
      {
        dpGet(sDPE, iVal); //simulate - just read from DPE
      }
      checkLog(mConfig[sKey], sDPE, iVal, -1, makeDynAnytype(sId, iVal), sId, TRUE, sManagerKey);
    }
  }

  /**
   * @brief function to read total and idle CPU ticks
   * @return array: [1]: ulTotal [2]: ulIdle
   */
  private static dyn_ulong readUsedCpuTicks()
  {
    ulong ulTotal = -1;
    ulong ulIdle  = -1;

    if (!bSimulate)
    {
      if (isfile("/proc/stat"))
      {
        file f = fopen("/proc/stat", "r");

        if (f != 0)
        {
          string sLine;
          dyn_string dsCaptures;

          // Only need the first line with the total cpu usage
          fgets(sLine, 4096, f);

          regexpSplit("cpu\\s+(\\d+)"    //  (1) user
                         "\\s+(\\d+)"    //  (2) nice
                         "\\s+(\\d+)"    //  (3) system
                         "\\s+(\\d+)"    //  (4) idle
                         "\\s+\\d+"      //  (5) iowait (is not reliable)
                         "\\s+(\\d+)"    //  (6) irq
                         "\\s+(\\d+)"    //  (7) softirq
                         "\\s+(\\d+)"    //  (8) steal
                         "\\s+(\\d+)"    //  (9) guest
                         "\\s+(\\d+)",   // (10) guest_nice
                         sLine, dsCaptures, makeMapping("caseSensitive", TRUE));

          ulTotal = 0;

          for (int i = 2; i <= dynlen(dsCaptures); i++)
          {
            ulTotal += (ulong)dsCaptures[i];
          }

          if (dynlen(dsCaptures) >= 5)
          {
            ulIdle = (ulong)dsCaptures[5];
          }
          if (iNrOfCpuCores==0)
          {
            while(!feof(f))
            {
              fgets(sLine, 4096, f);
              if (patternMatch("cpu*", sLine))
                iNrOfCpuCores++;
              else
                break;
            }
          }

          fclose(f);
        }
      }
    }
    else if(iNrOfCpuCores == 0) //in simulation, we set cores to 2, and define some defaults
    {
      iNrOfCpuCores = 2;
      ulTotal = 9999;
      ulIdle  = 999;
    }

    return makeDynULong(ulTotal, ulIdle);
  }

  private static dyn_ulong readAvailableVirtualMemory()
  {
    ulong ulTotalVirtualMemory = -1;
    ulong ulFreeVirtualMemory = -1;

    if (!bSimulate)
    {
      string sFileName = "/proc/meminfo";

      if (isfile(sFileName))
      {
        file f = fopen(sFileName, "r");

        if (f != 0)
        {
          string sLine;
          while(!feof(f))
          {
            fgets(sLine, 4096, f);
            strreplace(sLine, " ", ""); //remove spaces
            if (patternMatch("MemTotal:*", sLine))
            {
              sscanf(strrtrim( strltrim(sLine, "MemTotal: "), " kB"), "%lu",ulTotalVirtualMemory);
            }
            else if (patternMatch("MemFree:*", sLine))
            {
              sscanf(strrtrim( strltrim(sLine, "MemFree: "), " kB"), "%lu",ulFreeVirtualMemory);
            }
            if(ulTotalVirtualMemory != -1 && ulFreeVirtualMemory != -1)
            {
              break;
            }
          }
          fclose(f);
        }
      }
    }
    else
    {
      ulTotalVirtualMemory = maxULONG();
      ulFreeVirtualMemory  = maxULONG();
    }

    return makeDynULong(ulTotalVirtualMemory, ulFreeVirtualMemory);
  }

  /**
   * @brief function to read current CPU ticks for a given process id
   * @param iPid    process id
   * @return dulong  [1]: current CPU ticks for the process, [2]: current memory consumption in kB
   */
  private static dyn_ulong readUsedProcessTicksAndMem(int iPid)
  {
    dyn_ulong dulResult = -1;

    string sFileName = "/proc/" + iPid + "/stat";

    if (isfile(sFileName))
    {
      file f = fopen(sFileName, "r");

      if (f != 0)
      {
        string sLine;
        dyn_string dsCaptures, dsCaptures2;

        // Only need the first line with the total cpu usage
        int iBytes = fgets(sLine, 4096, f);

        regexpSplit("^\\d+"            //  (1) pid     process ID
                    "\\s+\\S+"         //  (2) comm    filename of the executable, in parentheses
                    "\\s+\\S+"         //  (3) state   process state
                    "\\s+\\d+"         //  (4) ppid    PID of the parent
                    "\\s+\\d+"         //  (5) pgrp    process group ID
                    "\\s+\\d+"         //  (6) session session ID
                    "\\s+\\d+"         //  (7) tty_nr  controlling terminal of the process
                    "\\s+[-\\d]+"      //  (8) tpgid   ID of the foreground process group of the controlling terminal of the process
                    "\\s+\\d+"         //  (9) flags   kernel flags word
                    "\\s+\\d+"         // (10) minflt  number of minor faults the process has made which have not required loading a memory page from disk
                    "\\s+\\d+"         // (11) cminflt number of minor faults that the process's waited-for children have made
                    "\\s+\\d+"         // (12) majflt  number of major faults the process has made which have required loading a memory page from disk
                    "\\s+\\d+"         // (13) cmajflt number of major faults that the process's waited-for children have made
                    "\\s+(\\d+)"       // (14) utime   time that this process has been scheduled in user mode
                    "\\s+(\\d+)",       // (15) stime   time that this process has been scheduled in kernel mode
//                     "\\s+\\d+"       // (16) cutime
//                     "\\s+\\d+"       // (17) cstime
//                     "\\s+\\d+"       // (18) priority
//                     "\\s+\\d+"       // (19) nice
//                     "\\s+\\d+"       // (20) num_trheads
//                     "\\s+\\d+"       // (21) itrealvalue
//                     "\\s+\\d+"       // (22) starttime
//                     "\\s+(\\d+)",    // (23) vsize
                    sLine, dsCaptures, makeMapping("caseSensitive", TRUE));

        if (dynlen(dsCaptures) >= 3)
        {
          dulResult = makeDynULong((ulong)dsCaptures[2] + (ulong)dsCaptures[3]);
        }

        fclose(f);


      }
    }

    string sFileName = "/proc/" + iPid + "/status";
    if (isfile(sFileName))
    {
      file f = fopen(sFileName, "r");

      if (f != 0)
      {
        while(!feof(f))
        {
          string sLine;
          fgets(sLine, 4096, f);
          strreplace(sLine, " ", ""); //remove spaces
          if (patternMatch("VmRSS:*", sLine))
          {
            ulong ulVmData;
            sscanf(sLine, "VmRSS: %lu kB", ulVmData);
            dulResult[2] = ulVmData;
            break;
          }
        }
        fclose(f);
      }
    }
    DebugFTN("CPU_TICKS", __FUNCTION__ + "(" + iPid + ") Returning: " + dulResult + " bytes: " + iBytes + " captures:", dsCaptures);
    return dulResult;
  }

  /**
   * @brief Finds the (first) manager with the specified name and optional options
   * @param sManager    Process name of the manager
   * @param sOptions    Empty to ignore the options OR exact option match (after removing debug flags from the pmon option)
   * @return Pmon index of the manager OR -1 if manager was not found
   */
  private static int findPmonIndex(const string &sManager, const string &sOptions)
  {
    int iResult = -1;
    dyn_dyn_string ddsPmonList = EB_UtilsPmon::query("MGRLIST:LIST");

    for (int i = 1; i <= dynlen(ddsPmonList) && iResult == -1; i++)
    {
      // Only check the manager name if no options are specified
      if (ddsPmonList[i][(int)PmonListFields::Manager] == sManager && sOptions == "")
      {
        iResult = i;
      }
      // Check if the manager name matches and the options are an exact match
      else if (ddsPmonList[i][(int)PmonListFields::Manager] == sManager && ddsPmonList[i][(int)PmonListFields::CommandlineOptions] == sOptions)
      {
        iResult = i;
      }
      // Check if the manager name matches and the options match without possible debug flags
      else if (ddsPmonList[i][(int)PmonListFields::Manager] == sManager && removeDebugFlags(ddsPmonList[i][(int)PmonListFields::CommandlineOptions]) == sOptions)
      {
        iResult = i;
      }
    }

    return iResult;
  }

  /**
   * @brief create mapping manager name and number, ticks and memory usage per WinCC OA manager PID
   * @param mResult     Result mapping [pid]{[man],[ticks],[mem]}
   */
  private static void getPidTicksMappping(mapping &mResult)
  {
    dyn_dyn_string ddsPmonList = EB_UtilsPmon::query("MGRLIST:LIST");
    dyn_dyn_string ddsStati = EB_UtilsPmon::query("MGRLIST:STATI");

    // so skip the last line (with the pmon, emergency and demo mode)
    for (int i = 1; i <= dynlen(ddsPmonList) && i < dynlen(ddsStati); i++)
    {
      if (ddsStati[i][(int)PmonStatiFields::PID] != -1) //has a pid (running process)
      {
        string sManagerKey = "000";
        int iNum = 1;
        int iPos;
        if (dynlen(ddsPmonList[i])>5 && (iPos = strpos(ddsPmonList[i][6], "-num "))>-1)
        {
          iPos += 5; //len of "-num "
          int iEnd = strpos(ddsPmonList[i][6], " ", iPos);
          if (iEnd > 0)
            iNum = substr(ddsPmonList[i][6], iPos, iEnd-iPos);
          else
            iNum = substr(ddsPmonList[i][6], iPos);
          sprintf(sManagerKey, "%03d", ddsPmonList[i][(int)PmonListFields::Manager] == "WCCOActrl" ? (iNum + iCTRL_MANAGER_NUMMER_OFFSET) : iNum); //ctrl manager have offset of iCTRL_MANAGER_NUMMER_OFFSET
        }
        else
        {
          if (ddsPmonList[i][(int)PmonListFields::Manager] == "WCCILdata")
            sprintf(sManagerKey, "%03d", iDATA_MANAGER_NUMMER_OFFSET); //data manager has offset of iDATA_MANAGER_NUMMER_OFFSET
          else if (ddsPmonList[i][(int)PmonListFields::Manager] == "WCCILevent")
            sprintf(sManagerKey, "%03d", iEVENT_MANAGER_NUMMER_OFFSET); //event manager has offset of iEVENT_MANAGER_NUMMER_OFFSET
        }

        dyn_ulong du;
        if (bSimulate)
        {
          du[1] = 1;
          du[2] = 1;
        }
        else
        {
          du = readUsedProcessTicksAndMem(ddsStati[i][(int)PmonStatiFields::PID]);
        }
        if (dynlen(du) < 2)
        {
          du[2] = 0;
        }
        mResult[(int)ddsStati[i][(int)PmonStatiFields::PID]] = makeMapping("man", ddsPmonList[i][(int)PmonListFields::Manager] + "_" + iNum, "ticks", du[1], "mem", du[2], "ManagerKey", sManagerKey);
      }
    }
  }

  /**
   * @brief Returns the specified command line options without the debug flags
   * @details Removes the '-dbg', '-rcv', '-report' & '-snd' options including the argument
   * @param sCommandLineOptions   Command line to remove the debug flags from
   * @return Command line options without the debug flags
   */
  private static string removeDebugFlags(const string &sCommandLineOptions)
  {
    dyn_string dsSplit = strsplit(sCommandLineOptions, " ");

    for (int i = dynlen(dsSplit) - 1; i > 0; i--)
    {
      switch (dsSplit[i])
      {
        case "-dbg":
        case "-rcv":
        case "-report":
        case "-snd": dynRemove(dsSplit, i + 1);
                     dynRemove(dsSplit, i);
          break;
      }
    }

    return strjoin(dsSplit, " ");
  }

  private static mapping g_mCounters = makeMapping(Counters::Connections, -1, Counters::Tags, -1);
  private static mapping g_mLogDpeLogState;
  public static string sManagerCpuMemDpPrefix = "_RessourceMonitor_";
  public static bool   bSimulate; //switch for simulation (read from ressource monitor DPEs) instead of calculation of CPU and memory
  private static string sManagerCpuMemDpt = "_RessourceMonitor";
  private static int iNrOfCpuCores; //number of CPU cores, used for calculation of project and process CPU consumption
};
