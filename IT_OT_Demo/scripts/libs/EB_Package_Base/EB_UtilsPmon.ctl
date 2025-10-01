// $License: NOLICENSE

/**
 * @file scripts/libs/EB_Package_Base/EB_UtilsPmon.ctl
 * @brief Contains various useful functions for interfacing with the pmon.
 */

// used libraries (#uses)
#uses "pmon.ctl"
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
const string DEFAULT_PMON_MANAGER_START_MODE      = "always";                            //!< Pmon default start mode
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
    int i;
    int iNumber = pmonGetCount();
    for (i = 0; i <= iNumber; i++)
    {
      if (sManagerName == pmonGetName(i) && sOptions == "")
      {
        return (i);
      }
      if (sManagerName == pmonGetName(i) && strpos(pmonGetOptions(i),sOptions) >= 0 )
      {
        return (i);
      }
      if (sManagerName == "ANY" && pmonGetOptions(i) == sOptions)
      {
        return (i);
      }
    }
    //this return should only be given when nothing matching the parameters was found
    return (-1);
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

    // Stop the manager
    string sResult = command("SINGLE_MGR:STOP " + uIndex);

    if (sResult != PMON_RESULT_SUCCESS)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonStopManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonStopManagerById", makeMapping("$index",  uIndex, "$result", sResult)));
    }
  }

  /**
   * @brief Removes the specified index from the pmon list
   * @param uIndex   Index to remove
   */
  public static void removeManagerById(uint uIndex)
  {
    DebugFTN("PMON", __FUNCTION__ + "(" + uIndex + ") Removing manager");

    // Mark the manager for deletion
    string sResult = command("SINGLE_MGR:PROP_PUT " + uIndex + " manual 0 0 0 " + PACKAGE_REMOVE_TAG);

    if (sResult != PMON_RESULT_SUCCESS)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonRemoveManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonMarkManagerRemoveById", makeMapping("$index",  uIndex, "$result", sResult)));
    }

    // Stop the manager
    stopManagerById(uIndex);
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
      // First make sure there is a CTRLDebug dp for the new control manager
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
      // Make sure the driver dps exists for the new driver
      if (iManagerNumber > 0)
      {
        if (!dpExists("_Driver" + iManagerNumber))
        {
          dpCreate("_Driver" + iManagerNumber, "_DriverCommon");
        }
        if (!dpExists("_Stat_Configs_driver_" + iManagerNumber))
        {
          dpCreate("_Stat_Configs_driver_" + iManagerNumber, "_Statistics_DriverConfigs");
        }
      }
    }

    // Pass all manager options as a single argument
    string sManagerOptions = "\"" + sOptions + "\"";
    string sResult;

    int iManagerIndex = findManager(sManagerName, sOptions);
    DebugFTN("PMON", __FUNCTION__, "iManagerIndex", iManagerIndex);
    int iNewManagerIndex = -1;
    string sAction = "pmonAlreadyExists";
    if (iManagerIndex == -1)
    {
      iNewManagerIndex = findManager(sManagerName, PACKAGE_REMOVE_TAG);
      //iNewManagerIndex = findManager(getComponentName(CTRL_COMPONENT), PACKAGE_REMOVE_TAG);
      DebugFTN("PMON", __FUNCTION__, "iNewManagerIndex from remove", iNewManagerIndex);
      if (iNewManagerIndex != -1)
      {
        sAction = "pmonActionInsert";
        sResult = command("SINGLE_MGR:PROP_PUT " + iNewManagerIndex + " " + DEFAULT_PMON_MANAGER_START_MODE + " " + DEFAULT_PMON_MANAGER_SECONDS_TO_KILL
                                      + " " + DEFAULT_PMON_MANAGER_RESTART_COUNT + " " + DEFAULT_PMON_MANAGER_RESET_MINUTES + " " + sManagerOptions);
        // if manager was last manager it is removed from list
        if (sResult != PMON_RESULT_SUCCESS)
        {
          sAction = "pmonActionAppend";
          sResult = command("SINGLE_MGR:INS " + iNewManagerIndex + " " + sManagerName + " " + DEFAULT_PMON_MANAGER_START_MODE + " " + DEFAULT_PMON_MANAGER_SECONDS_TO_KILL
                                      + " " + DEFAULT_PMON_MANAGER_RESTART_COUNT + " " + DEFAULT_PMON_MANAGER_RESET_MINUTES + " " + sManagerOptions);
        }
      }
      else
      {
        dyn_bool dbRunning = getPmonStates();
        iNewManagerIndex = dynlen(dbRunning);
        DebugFTN("PMON", __FUNCTION__, "iNewManagerIndex from new", iNewManagerIndex);
        if (iNewManagerIndex > 0)
        {
          sAction = "pmonActionAppend";
          sResult = command("SINGLE_MGR:INS " + iNewManagerIndex + " " + sManagerName + " " + DEFAULT_PMON_MANAGER_START_MODE + " " + DEFAULT_PMON_MANAGER_SECONDS_TO_KILL
                                      + " " + DEFAULT_PMON_MANAGER_RESTART_COUNT + " " + DEFAULT_PMON_MANAGER_RESET_MINUTES + " " + sManagerOptions);
        }
      }
    }
    DebugFTN("PMON", __FUNCTION__, "sResult", sResult == PMON_RESULT_SUCCESS, "sAction", sAction, sResult);
    if (sResult != PMON_RESULT_SUCCESS)
    {
      EB_logAdd(EB_createLogEntry("Base", LOG_TYPE_RUNTIME, "pmonAddManager", "", EBlogEntry::iLOG_ENTRY_TYPE_ERROR, 0, "", "pmonAddManagerFailed",
                                  makeMapping("$action",  getCatStr("EB_Package_Base", sAction),
                                              "$index",   iNewManagerIndex,
                                              "$manager", sManagerName,
                                              "$options", sOptions,
                                              "$result",  sResult)));
    }

    return sResult == PMON_RESULT_SUCCESS;
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
    dyn_dyn_string ddsList = query("MGRLIST:STATI");

    for (int i = 1; i <= dynlen(ddsList); i++)
    {
      if (dynlen(ddsList[i]) >= 5)
      {
        dbResult[i] = ddsList[i][1] == PMON_STATE_RUNNING;
      }
    }

    return dbResult;
  }

  /**
   * @brief Deletes the managers that are marked for delete
   */
  public static void deleteManagers()
  {
    int iManagerIndex = findManager("ANY", PACKAGE_REMOVE_TAG);
    while (iManagerIndex != -1)
    {
      string sResult = command("SINGLE_MGR:DEL " + iManagerIndex);
      iManagerIndex = findManager("ANY", PACKAGE_REMOVE_TAG);
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
