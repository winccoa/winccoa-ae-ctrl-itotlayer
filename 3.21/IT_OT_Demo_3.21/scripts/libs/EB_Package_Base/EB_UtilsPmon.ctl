// $License: NOLICENSE

/**
 * @file scripts/libs/EB_Package_Base/EB_UtilsPmon.ctl
 * @brief Contains various useful functions for interfacing with the pmon.
 */

// used libraries (#uses)
#uses "pmon.ctl"
#uses "pmonInterface"
#uses "pa.ctl"
#uses "classes/EBlog"

enum PmonListFields
{
  Manager = 1,
  StartMode,
  SecKill,
  RestartCount,
  ResetMin,
  CommandlineOptions,
  Last = CommandlineOptions
};
const string PMON_RESULT_SUCCESS                  = "OK";                                //!< Result of a successful pmon command
const string DEFAULT_PMON_MANAGER_START_MODE      = MAN_START_MODE_ALWAYS;               //!< Pmon default start mode
const int    DEFAULT_PMON_MANAGER_SECONDS_TO_KILL =  30;                                 //!< Pmon default seconds to kill
const int    DEFAULT_PMON_MANAGER_RESTART_COUNT   =  20;                                 //!< Pmon default number of manager restart attempts
const int    DEFAULT_PMON_MANAGER_RESET_MINUTES   =   1;                                 //!< Pmon default restart counter reset after x minutes

const string PACKAGE_REMOVE_TAG  = "***REMOVE***";                                       //!< Mark removed manager with this keyword

enum PmonStatiFields
{
  State = 1,
  PID,
  StartMode,
  StartTime,
  ManNum,
  Last = ManNum
};

// Wrapper functions avoid name collisions with the static methods of EB_UtilsPmon.
int EB_pmonInterfaceStopManager(int iManagerIndex)
{
  return stopManager(iManagerIndex);
}

int EB_pmonInterfaceStartManager(int iManagerIndex)
{
  return startManager(iManagerIndex);
}

int EB_pmonInterfaceDeleteManager(int iManagerIndex)
{
  return deleteManager(iManagerIndex);
}

int EB_pmonInterfaceGetManagerStatus(int iManagerIndex)
{
  return getManagerStatus(iManagerIndex);
}

int EB_pmonInterfaceSetManagerOptions(int iManagerIndex, const mapping &mOptions)
{
  return setManagerOptions(iManagerIndex, mOptions);
}

int EB_pmonInterfaceInsertManager(const mapping &mOptions, int iManagerIndex)
{
  return insertManager(mOptions, iManagerIndex);
}

dyn_mapping EB_pmonInterfaceGetManagerStates()
{
  return getListOfManagersStati();
}

/**
 * @brief This is the utility class for interfacing with the pmon. It contains various useful functions for interfacing with the pmon.
 */
class EB_UtilsPmon
{
  /**
   * @brief Executes a pmon command
   * @param sCommand Command to execute
   * @return Result of the command
   */
  public static string command(const string &sCommand)
  {
    string output;
    string error;
    string command = getPath(BIN_REL_PATH, getComponentName(PMON_COMPONENT) + (_WIN32 ? ".exe" : "")) + " -proj " + PROJ + " -log -file -log +stderr -command " + sCommand;

    system(command, output, error);

    DebugFN("PMON_COMMAND", __FUNCTION__ + "(" + sCommand + ") command: " + command + " error: " + error + " Returning: " + output);

    return strrtrim(output);
  }

  /**
   * @brief Returns the result from the pmon command
   * @details Result is splitted into multiple lines and values
   * @param sCommand Command to execute
   * @return Result of the command
   */
  public static dyn_dyn_string query(const string &sCommand)
  {
    dyn_dyn_string ddsResult;

    const string LIST_COUNT_HEADER = "LIST:";

    string sResult = command(sCommand);

    dyn_string dsLines = strsplit(sResult, "\n");

    // Check if the first line should be excluded from the result
    bool bSkipFirst = dynlen(dsLines) >= 1 ? substr(dsLines[1], 0, strlen(LIST_COUNT_HEADER)) == LIST_COUNT_HEADER : FALSE;

    for (int i = 1 + (int)bSkipFirst; i <= dynlen(dsLines); i++)
    {
      dsLines[i] = strrtrim(dsLines[i]);

      // Only process lines with values
      if (strrtrim(dsLines[i], ";") != "")
      {
        dyn_string dsValues = strsplit(dsLines[i], ";");

        for (int j = 1; j <= dynlen(dsValues); j++)
        {
          dsValues[j] = strltrim(dsValues[j]);
        }

        dynAppend(ddsResult, dsValues);
      }
    }

    return ddsResult;
  }

  /**
   * @brief Returns the pmonIndex of the manager
   * @param sManagerName The manager name
   * @param sOptions The options of the manager
   * @return PmonIndex of the manager or -1 if not found
   */
  public static int findManager(const string &sManagerName, const string &sOptions)
{
  dyn_mapping dmManagers = getListOfManagerOptions();

  for (int i = 1; i <= dynlen(dmManagers); i++)
  {
    string sCurrentManager = dmManagers[i].value("Component", "");

    string sCurrentOptions = dmManagers[i].value("StartOptions", "");

    sCurrentManager = strrtrim(strltrim(sCurrentManager));
    sCurrentOptions = strrtrim(strltrim(sCurrentOptions));

    // PMON list is one-based in the dyn_mapping,
    // but PMON manager indexes begin with zero.
    int iManagerIndex = i - 1;

    if (sManagerName == sCurrentManager &&
        sOptions == "")
    {
      return iManagerIndex;
    }

    if (sManagerName == sCurrentManager &&
        strpos(sCurrentOptions, sOptions) >= 0)
    {
      return iManagerIndex;
    }

    if (sManagerName == "ANY" &&
        sCurrentOptions == sOptions)
    {
      return iManagerIndex;
    }
  }

  return -1;
}

  /**
   * @brief Stops the manager
   * @param sManagerName The manager name
   * @param sOptions The options of the manager
   * @return PmonIndex of the manager or -1 if not found
   */
  public static int stopManager(const string &sManagerName, const string &sOptions)
  {
    DebugFTN("PMON", __FUNCTION__, sManagerName, sOptions);
    int iManagerNumber = findManager(sManagerName, sOptions);
    if (iManagerNumber != -1)
    {
      stopManagerById(iManagerNumber);
      return 0;
    }
    else
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonStopManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonStopManager", makeMapping("$name",  sManagerName, "$options", sOptions)));
      return -1;
    }
  }

  /**
   * @brief Removes the manager
   * @param sManagerName The manager name
   * @param sOptions The options of the manager
   * @return PmonIndex of the manager or -1 if not found
   */
  public static int removeManager(const string &sManagerName, const string &sOptions)
  {
    DebugFTN("PMON", __FUNCTION__, sManagerName, sOptions);
    int iManagerNumber = findManager(sManagerName, sOptions);
    if (iManagerNumber != -1)
    {
      removeManagerById(iManagerNumber);
      return 0;
    }
    else
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonRemoveManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonStopManager", makeMapping("$name",  sManagerName, "$options", sOptions)));
      return -1;
    }
  }

  /**
   * @brief Stops the specified index from the pmon list
   * @param uIndex   Index to remove
   */
  public static void stopManagerById(uint uIndex)
  {
    DebugFTN("PMON", __FUNCTION__ + "(" + uIndex + ") Stopping manager");

    int iResult = EB_pmonInterfaceStopManager(uIndex);

    if (iResult != 0)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonStopManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonStopManagerById",
                                  makeMapping("$index", uIndex, "$result", iResult)));
    }
  }

  /**
   * @brief Removes the specified index from the pmon list
   * @param uIndex   Index to remove
   */
  public static void removeManagerById(uint uIndex)
  {
    DebugFTN("PMON", __FUNCTION__ + "(" + uIndex + ") Removing manager");

    mapping mOptions = makeMapping("StartMode",         MAN_START_MODE_MANUAL,
                                   "SecondToKill",      0,
                                   "Restart",           0,
                                   "ResetStartCounter", 0,
                                   "StartOptions",      PACKAGE_REMOVE_TAG);

    int iResult = EB_pmonInterfaceSetManagerOptions(uIndex, mOptions);

    if (iResult != 0)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonRemoveManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonMarkManagerRemoveById",
                                  makeMapping("$index", uIndex, "$result", iResult)));
      return;
    }

    int iWaitCount = 30;
    int iState = EB_pmonInterfaceGetManagerStatus(uIndex);

    // A previous interrupted attempt can leave the manager stopped and marked
    // with ***REMOVE***. Do not fail recovery by sending STOP a second time.
    if (iState != MAN_STATE_NOT_RUNNING && iState != MAN_STATE_UNKNOWN)
    {
      int iStopResult = EB_pmonInterfaceStopManager(uIndex);

      if (iStopResult != 0)
      {
        EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonStopManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonStopManagerById",
                                    makeMapping("$index", uIndex, "$result", iStopResult)));
        return;
      }
    }

    // Do not depend on managersCB for the delete. Wait until PMON confirms
    // that the process stopped and then delete it in the same operation.

    while (iState != MAN_STATE_NOT_RUNNING &&
           iState != MAN_STATE_UNKNOWN &&
           iWaitCount > 0)
    {
      delay(1);
      iWaitCount--;
      iState = EB_pmonInterfaceGetManagerStatus(uIndex);
    }

    if (iWaitCount == 0)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonRemoveManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonRemoveManager",
                                  makeMapping("$index", uIndex, "$result", "Timeout waiting for manager to stop")));
      return;
    }

    int iDeleteResult = EB_pmonInterfaceDeleteManager(uIndex);

    if (iDeleteResult != 0)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonRemoveManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonRemoveManager",
                                  makeMapping("$index", uIndex, "$result", iDeleteResult)));
      return;
    }

    // PMON updates its list asynchronously. Waiting here keeps the next
    // manager operation from using an index from the old list.
    delay(1);
  }

  /**
   * @brief Adds the manager
   * @param sManagerName The manager name
   * @param sOptions The options of the manager
   * @return True if manager was added
   */
  public static bool addManager(const string &sManagerName, const string &sOptions)
  {
    DebugFTN("PMON", __FUNCTION__, sManagerName, sOptions);

  int iManagerNumber = getManNumFromOptions(sOptions);

  if (sManagerName == getComponentName(CTRL_COMPONENT))
  {
    if (iManagerNumber > 0)
    {
      if (!dpExists("_CtrlDebug_CTRL_" + iManagerNumber))
      {
        dpCreate("_CtrlDebug_CTRL_" + iManagerNumber, "_CtrlDebug");
      }
    }
  }
  else
  {
    if (iManagerNumber > 0)
    {
      if (!dpExists("_Driver" + iManagerNumber))
      {
        dpCreate("_Driver" + iManagerNumber, "_DriverCommon");
      }

      if (!dpExists("_Stat_Configs_driver_" + iManagerNumber))
      {
        dpCreate(
          "_Stat_Configs_driver_" + iManagerNumber,
          "_Statistics_DriverConfigs"
        );
      }
    }
  }

  int iManagerIndex = findManager(sManagerName, sOptions);

  DebugFTN(
    "PMON",
    __FUNCTION__,
    "iManagerIndex",
    iManagerIndex
  );

  // Manager already exists with the same options.
if (iManagerIndex != -1)
{
  if (pmonGetState(iManagerIndex) != PMON_STATE_RUNNING)
  {
    delay(1);

    int iStartResult = EB_pmonInterfaceStartManager(iManagerIndex);

    if (iStartResult != 0)
    {
      EB_logAdd(
        EB_createLogEntry(
          "Base",
          LOG_TYPE_RUNTIME,
          "pmonAddManager",
          "",
          EBlogEntry::iLOG_ENTRY_TYPE_ERROR,
          0,
          "",
          "pmonAddManagerFailed",
          makeMapping(
            "$action", "PMON start existing manager",
            "$index", iManagerIndex,
            "$manager", sManagerName,
            "$options", sOptions,
            "$result", iStartResult
          )
        )
      );

      return FALSE;
    }
  }

  return TRUE;
}

  // Check whether the same manager was previously marked for deletion.
  int iNewManagerIndex = findManager(
    sManagerName,
    PACKAGE_REMOVE_TAG
  );

  if (iNewManagerIndex != -1)
  {
    mapping mOptions = makeMapping("StartMode",         DEFAULT_PMON_MANAGER_START_MODE,
                                   "SecondToKill",      DEFAULT_PMON_MANAGER_SECONDS_TO_KILL,
                                   "Restart",           DEFAULT_PMON_MANAGER_RESTART_COUNT,
                                   "ResetStartCounter", DEFAULT_PMON_MANAGER_RESET_MINUTES,
                                   "StartOptions",      sOptions);

    int iResult = EB_pmonInterfaceSetManagerOptions(iNewManagerIndex, mOptions);

    if (iResult != 0)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonAddManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonAddManagerFailed",
                                  makeMapping("$action", "PMON property update", "$index", iNewManagerIndex, "$manager", sManagerName,
                                              "$options", sOptions, "$result", iResult)));
      return FALSE;
    }
  }
  else
  {
    iNewManagerIndex = pmonGetCount();

    mapping mOptions = makeMapping("Component",         sManagerName,
                                   "StartMode",         DEFAULT_PMON_MANAGER_START_MODE,
                                   "SecondToKill",      DEFAULT_PMON_MANAGER_SECONDS_TO_KILL,
                                   "Restart",           DEFAULT_PMON_MANAGER_RESTART_COUNT,
                                   "ResetStartCounter", DEFAULT_PMON_MANAGER_RESET_MINUTES,
                                   "StartOptions",      sOptions);

    int iResult = EB_pmonInterfaceInsertManager(mOptions, iNewManagerIndex);

    if (iResult < 0)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonAddManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonAddManagerFailed",
                                  makeMapping("$action", "PMON insert", "$index", iNewManagerIndex, "$manager", sManagerName,
                                              "$options", sOptions, "$result", iResult)));
      return FALSE;
    }
  }

    // An inserted manager with start mode "always" is not guaranteed to start
    // immediately. Start it explicitly after PMON has updated its manager list.
    delay(1);

    int iStartResult = EB_pmonInterfaceStartManager(iNewManagerIndex);

    if (iStartResult != 0)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonAddManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonAddManagerFailed",
                                  makeMapping("$action", "PMON start", "$index", iNewManagerIndex, "$manager", sManagerName,
                                              "$options", sOptions, "$result", iStartResult)));
      return FALSE;
    }

    return TRUE;
  }
  /**
   * @brief Gets the manager number from options
   * @param sOptions The options of the manager
   * @return number of the manager or -1 if not found
   */
  public static int getManNumFromOptions(const string &sOptions)
  {
    int iResult = -1;
    dyn_string dsSplit = strsplit(sOptions, " ");

    int iIndex = dynContains(dsSplit, "-num");

    // Check if the index is valid (index cannot be the last one, because of the number itself)
    if (0 < iIndex && iIndex < dynlen(dsSplit))
    {
      iResult = dsSplit[iIndex + 1];
    }

    return iResult;
  }

  /**
   * @brief Returns the running state for all (pmon) managers
   * @return List of running states
   */
  public static dyn_bool getPmonStates()
  {
    dyn_bool dbResult;
    dyn_mapping dmStates = EB_pmonInterfaceGetManagerStates();

    for (int i = 1; i <= dynlen(dmStates); i++)
    {
      dbResult[i] = dmStates[i].value("State", PMON_STATE_NOT_RUNNING) == PMON_STATE_RUNNING;
    }

    return dbResult;
  }

  /**
   * @brief Deletes the managers that are marked for delete
   */
  public static void deleteManagers()
  {
    // Take one snapshot and delete from the highest index downwards. PMON 3.21
    // applies DEL asynchronously, so immediately searching again can return the
    // same manager and create an endless loop. Descending indexes also prevent
    // index shifts from affecting managers that still have to be deleted.
    dyn_mapping dmManagers = getListOfManagerOptions();

    for (int i = dynlen(dmManagers); i >= 1; i--)
    {
      string sOptions = dmManagers[i].value("StartOptions", "");
      sOptions = strrtrim(strltrim(sOptions));

      if (sOptions != PACKAGE_REMOVE_TAG)
      {
        continue;
      }

      removeManagerById(i - 1);
    }
  }
  /**
   * @brief Gets the state of the manager
   * @param sManagerName The manager name
   * @param sOptions The options of the manager
   * @return The state of the manager: 0 for stopped, 1 for starting, 2 for running or -1 if not found
   */
  public static int getPmonState(const string &sManagerName, const string &sOptions)
  {
    int iManagerNumber = findManager(sManagerName, sOptions);
    if (iManagerNumber != -1)
    {
      return pmonGetState(iManagerNumber);
    }
    else
    {
      return -1;
    }
  }
};
