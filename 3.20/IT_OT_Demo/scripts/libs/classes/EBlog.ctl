// $License: NOLICENSE

/**
 * @file scripts/libs/classes/EBlog.ctl
 * @brief Contains the EBlog class, which provides the log functionality for packages.
 * @author mtrummer
 */

// used libraries (#uses)
#uses "mp"                        // For dpCopy
#uses "classes/EBlogEntry"
#uses "EB_Package_Base/EB_const"

//constant for log entry types
const string LOG_TYPE_ALL           = "*";                  //!< Filter to get all log entries
const string LOG_TYPE_CONFIGURATION = "Configuration";     //!< Filter to get configuration logs
const string LOG_TYPE_RUNTIME       = "Runtime";           //!< Filter to get runtime logs
const string LOG_TYPE_INTERNET      = "Internet";          //!< Filter to get internet logs
const string LOG_TYPE_PERIPHERY     = "Periphery";         //!< Filter to get periphery logs
const string LOG_TYPE_UPDATE        = "Update";            //!< Filter to get update logs
const string LOG_TYPE_INTERNAL      = "Internal";          //!< Filter to get internal logs


enum LogSeverity
{
  All = -1,
  None = 0,
  First = 1,
  Information = First,
  Warning,
  Error,
  Last = Error
};

/**
 * @brief Class for logging or getting current logs
 */
class EBlog
{
//--------------------------------------------------------------------------------
//@private variables
//--------------------------------------------------------------------------------
  private static const int iADD_TEXT   = 2;
  private static const int iADD_TYPE   = 3;
  private static const int iADD_REASON = 4;
  private string sDpe;                                     //!< DPE of multi instance alarm
  private mapping mCurrentDriverLogs;                      //!< holds the current pending driver logs (so they can be combined with e.g. manager connection state)

  public static const string CONFIG_CHANGE_REQUEST  = "000120";  //!< Key for the configuration change requested
  public static const string CONFIG_CHANGE_SUCCESS  = "000121";  //!< Key for the configuration change executed successfully
  public static const string CONFIG_CHANGE_FAILED   = "000122";  //!< Key for the configuration change execution failure


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
  public string sAppName;                                  //!< Application name

  /**
   * @brief Default constructor
   * @author mtrummer
   * @param sLogAppName: name of the app (will be used as part of the log DP, for creating and filtering logs)
   */
  public EBlog(string sLogAppName = "")
  {
    if (sLogAppName != "")
    {
      setAppName(sLogAppName);
    }
  }

  /**
    @author mtrummer
    @param sLogAppName: name of the app (will be used as part of the log DP, for creating and filtering logs)
  */
  public void setAppName(const string &sLogAppName)
  {
    sAppName = sLogAppName;

    strreplace(sAppName, " ", "");

    string sDp = EB_PREFIX_PACKAGE + sAppName;

    if (!dpExists(sDp)) //check if log DP for app exists, otherwise create it
    {
      int iErr;
      dpCopy("_mp_" + EB_DPTYPE_PACKAGES, sDp, iErr);
    }

    sDpe = sDp + ".Alerts.";
  }

  /**
    @brief Save one log entry, if it is not already present
    @author mtrummer
    @param logEntry: the EBlogEntry which should be saved
    @param bPending: if false, the logs will set to CAME and WENT immediately
    @param bForceIfNewLog: if true, an possibly existing log with specific reason (but with different log text) will be removed (WENT) and a new log will be created
    @param bLogInAdditionInFile: if true, also wite into log file
  */
  public void doLog(const EBlogEntry &logEntry, bool bPending = FALSE, bool bForceIfNewLog = FALSE, bool bLogInAdditionInFile = TRUE)
  {
    //check if logentry already exists -> then ignore it
    EBlogEntry ebLogTmp;
    time tLogTime = logEntry.tTime;

    if (bPending && logEntryExist(logEntry, ebLogTmp))
    {
      if (bForceIfNewLog == FALSE)
      {
        return;
      }
      else //update if text has changed
      {
        if (logEntry.lsText != ebLogTmp.lsText) //log exists, but needs to be updated -> remove old log and creat a new one
        {
          dyn_atime dat = makeDynATime(makeATime(ebLogTmp.tTime, ebLogTmp.aCnt, sDpe + ebLogTmp.sType + ".log"));

          removePendingLogs(ebLogTmp.sType, dat);
        }
        else //log exist and does not need to be updated
        {
          return;
        }
      }
    }
    // Also do not write non-pending logs multiple times
    else if (!bPending && !bForceIfNewLog && tLogTime != 0)
    {
      dyn_dyn_anytype ddaData;
      string sQuery = "SELECT ALERT '_alert_hdl.._text'"
                      " FROM '" + sDpe + logEntry.sType + ".log'"
                      " WHERE '_alert_hdl.._add_value_" + iADD_REASON + "' LIKE \"" + logEntry.sReason + "\""
                      " TIMERANGE(\"" + (string)logEntry.tTime + "\",\"" + (string)logEntry.tTime + "\",1,0)";

      dpQuery(sQuery, ddaData);

      if (dynlen(ddaData) >= 2)
      {
        return;
      }
    }

    // Use the current time for new alerts if not specified
    if (tLogTime == 0)
    {
      tLogTime = getCurrentTime();
    }

    int iRet = alertSetTimedWait(tLogTime,
                                 tLogTime, 0, sDpe + logEntry.sType + ".log:_alert_hdl.._event", DPATTR_ALERTEVENT_CAME,
                                 tLogTime, 0, sDpe + logEntry.sType + ".log:_alert_hdl.._class", dpSubStr("EB_" + logEntry.sType + "_" + logEntry.iType + ".:_alert_class", DPSUB_SYS_DP_EL_CONF_DET_ATT),
                                 tLogTime, 0, sDpe + logEntry.sType + ".log:_alert_hdl.._add_value_" + iADD_TEXT, logEntry.lsText,
                                 tLogTime, 0, sDpe + logEntry.sType + ".log:_alert_hdl.._add_value_" + iADD_TYPE, logEntry.iType,
                                 tLogTime, 0, sDpe + logEntry.sType + ".log:_alert_hdl.._add_value_" + iADD_REASON, logEntry.sReason);

    DebugFTN("LOGS_CREATE", "log entry created", iRet, sDpe + logEntry.sType + ".log", logEntry.lsText, logEntry.iType, dpSubStr("EB_" + logEntry.sType + "_" + logEntry.iType + ".:_alert_class", DPSUB_SYS_DP_EL_CONF_DET_ATT));

    dyn_errClass deErrors = getLastError();

    if (dynlen(deErrors) > 0)
    {
      throwError(deErrors);
    }

    if (!bPending) //let message went
    {
      // Remove the just created alert again, its purpose is to get an entry in the history
      dyn_atime dat;
      removePendingLogs(logEntry.sType, dat, tLogTime, logEntry.sReason);
    }

    if (bLogInAdditionInFile)
    {
      // Also write logs in the log file
      throwError(makeError("", logEntry.iType >= EBlogEntry::iLOG_ENTRY_TYPE_PARAM ? PRIO_WARNING : PRIO_INFO, ERR_CONTROL, 54, logEntry.sReason, logEntry.lsText));
    }
  }

  /**
    @brief Check if there is a pending log entry with specific reason exists
    @author mtrummer
    @param logEntry: entry with specific reason, which will be searched; if found the time of logEntry instance will be updated with timestamp of found pending log entry
    @param oldLogEntry: the found log entry
    @return TRUE if log entry does alreay exist and set update the time of given logEntry instance
  */
  public bool logEntryExist(const EBlogEntry &logEntry, EBlogEntry &oldLogEntry)
  {
    if (logEntry.sReason != "")
    {
      dyn_atime datAlerts;
      getPendingLogs(logEntry.sType, datAlerts);

      for (int i = dynlen(datAlerts); i > 0; i--)
      {
        string sItemReason;
        bit32 state32;



          int rc = alertGet(datAlerts[i], getACount(datAlerts[i]), sDpe + logEntry.sType + ".log:_alert_hdl.._add_value_" + iADD_REASON, sItemReason,
                            datAlerts[i], getACount(datAlerts[i]), sDpe + logEntry.sType + ".log:_alert_hdl.2._state", state32);

           if (rc != 0 || state32[1] == 1 /*obsolete*/ || state32[4] == 0 /* visible */ || state32[0] == 0 /* !came */)
        {
          continue;
        }



        if (logEntry.sReason == sItemReason)
        {
          oldLogEntry = logEntry;
          oldLogEntry.tTime = (time)datAlerts[i];
          oldLogEntry.aCnt = getACount(datAlerts[i]);
          langString ls;
          alertGet(oldLogEntry.tTime, oldLogEntry.aCnt, sDpe + logEntry.sType + ".log:_alert_hdl.._add_value_" + iADD_TEXT, ls);
          oldLogEntry.lsText = ls;

          return TRUE;
        }
      }
    }

    return FALSE;
  }

  /**
    @brief Get all pending logs for the application
    @author mtrummer
    @param sEntryType: entry type -> DPE leaf for the log (Runtime, Configuration, Internet, Periphery, Update)
    @param datAlerts: return list of pending logs
  */
  public void getPendingLogs(const string &sEntryType, dyn_atime &datAlerts)
  {
    if (dpExists(substr(sDpe, 0, strpos(sDpe, ".Alerts."))))
    {
      dpGet(sDpe + sEntryType + ".log:_alert_hdl.2._alerts", datAlerts);
    }

    DebugFTN("LOGS_PENDING", "pending alarms", dpExists(sDpe), sDpe + sEntryType + ".log", datAlerts);
  }

  /**
    @brief Remove pending logs
    @author mtrummer
    @param sEntryType: entry type -> DPE leaf for the log (Runtime, Configuration, Internet, Periphery, Update)
    @param datAlerts: pending logs which should be removed - if empty, all pending logs of the application will be used
    @param tToRemove: timestamp of the log, which should be removed - if 0 time, all logs will be removed
    @param sReason: pattern key for the the log entry (also required for removing the log entry)
    @param bAddLogToFile  add log message to log file
  */
  public void removePendingLogs(const string &sEntryType, dyn_atime &datAlerts, time tToRemove = 0, string sReason = "*", bool bAddLogToFile = FALSE)
  {
    if (dynlen(datAlerts) == 0)
    {
      getPendingLogs(sEntryType, datAlerts);
    }

    for (int i = dynlen(datAlerts); i > 0; i--)
    {
      if (tToRemove != 0 && (time)datAlerts[i] != tToRemove)
      {
        continue;
      }
      else if (sReason != "" && sReason != "*")
      {
        string sItemReason;
        alertGet(datAlerts[i], getACount(datAlerts[i]), sDpe + sEntryType + ".log:_alert_hdl.._add_value_" + iADD_REASON, sItemReason);

        if (!patternMatch(sReason, sItemReason))
        {
          continue;
        }
      }

      bit32 state;
      DebugFN("LOGS_REMOVE", "remove pending", (time)datAlerts[i], getACount(datAlerts[i]), sDpe + sEntryType + ".log:_alert_hdl.1._event", DPATTR_ALERTEVENT_WENT);

      int rc = alertGet(datAlerts[i], getACount(datAlerts[i]), sDpe + sEntryType + ".log:_alert_hdl.2._state", state);

      if (rc != 0 || state[1] == 1 /*obsolete*/ || state[4] == 0 /* visible */ || state[0] == 0 /* !came */)
      {
        continue;
      }

      DebugFN("LOGS_REMOVE", "---pending alarms: ", rc, datAlerts[i], getACount(datAlerts[i]), sDpe + sEntryType + ".log:_alert_hdl.2._state", state, state[1], state[4], state[0]);

      if (bAddLogToFile)
      {
        string sText;
        alertGet((time)datAlerts[i], getACount(datAlerts[i]), sDpe + sEntryType + ".log:_alert_hdl.._add_value_" + iADD_TEXT, sText);

        throwError(makeError("", PRIO_INFO, ERR_SYSTEM, 54, sText + " -> gone now, remove old log entry " + sReason));
      }

      alertSet((time)datAlerts[i], getACount(datAlerts[i]), sDpe + sEntryType + ".log:_alert_hdl.._event", DPATTR_ALERTEVENT_WENT);
      dynRemove(datAlerts, i);
    }
  }

  /**
    @brief Connect to log list, workfuction will be called with list of logs to update and list of logs to remove
    @author mtrummer
    @param sWorkfunction: name of the workfunction to be executed with the list of changes
    @param bTableUsage: TRUE to get the results (update and remove list) as dyn_dyn_anytype to put into an table; FALSE to get the results results (update and remove list) as dyn_anytype of EBlogEntry(s)
    @param dsFilterAppName: app names (DP) or "*" which should be included in the result
    @param dsFilterType: types (DPE nodes -> Runtime, Configuration, Internet, Periphery, Update) or "*" which should be included in the result
    @param sShape: shape which will be used in callback fucntion for updating
  */
  public static void connectToLogs(string sWorkfunction, bool bTableUsage = TRUE, dyn_string dsFilterAppName = makeDynString("*"), dyn_string dsFilterType = makeDynString("*"), string sShape = "")
  {
    dpQueryConnectSingle("connectWorkLogs", TRUE, makeDynAnytype(sWorkfunction, bTableUsage, FALSE, sShape), getQuery(bTableUsage, dsFilterAppName, dsFilterType), 200);
  }

  /**
    @brief Connect to log list, workfuction will be called with list of logs to update and list of logs to remove
    @author Martin Schiefer
    @param fpWorkfunction: function pointer to the workfunction to be executed with the list of changes
    @param bTableUsage: TRUE to get the results (update and remove list) as dyn_dyn_anytype to put into an table; FALSE to get the results results (update and remove list) as dyn_anytype of EBlogEntry(s)
    @param dsFilterAppName: app names (DP) or "*" which should be included in the result
    @param dsFilterType: types (DPE nodes -> Runtime, Configuration, Internet, Periphery, Update) or "*" which should be included in the result
    @param sShape: shape which will be used in callback fucntion for updating
  */
  public static void connectToLogsWithFunctionPtr(function_ptr fpWorkfunction, bool bTableUsage = TRUE, dyn_string dsFilterAppName = makeDynString("*"), dyn_string dsFilterType = makeDynString("*"), string sShape = "")
  {
    dpQueryConnectSingle("connectWorkLogs", TRUE, makeDynAnytype(fpWorkfunction, bTableUsage, FALSE, sShape), getQuery(bTableUsage, dsFilterAppName, dsFilterType), 200);
  }

  /**
    @brief Disconnect from log list
    @author mtrummer
    @param sWorkfunction: name of the workfunction to be executed with the list of changes
    @param bTableUsage: TRUE to get the results (update and remove list) as dyn_dyn_anytype to put into an table; FALSE to get the results results (update and remove list) as dyn_anytype of EBlogEntry(s)
    @param sShape: shape which will be used in callback fucntion for updating
  */
  public static void disconnectFromLogs(const string &sWorkfunction, bool bTableUsage = TRUE, string sShape = "")
  {
    dpQueryDisconnect("connectWorkLogs", makeDynAnytype(sWorkfunction, bTableUsage, FALSE, sShape));
  }

  /**
    @brief Connect to log summary color, workfuction will be called with log summary color
    @author mtrummer
    @param sWorkfunction     name of the workfunction to be executed log summary color
    @param sEntryType        entry type -> DPE leaf for the log (Runtime, Configuration, Internet, Periphery, Update)
    @param sShape            Optional: shape name to pass as additional user data
  */
  public void connectToLogSumColor(const string &sWorkfunction, const string &sEntryType, string sShape = "")
  {
    dyn_string dsUserData = makeDynString(sWorkfunction);

    if (sShape != "")
    {
      dynAppend(dsUserData, sShape);
    }

    dpConnectUserData("connectWorkLogSumColor", dsUserData, EB_PREFIX_PACKAGE + sAppName + ".Alerts." + sEntryType + ":_alert_hdl.._act_state_color",
                      EB_PREFIX_PACKAGE + sAppName + ".Alerts." + sEntryType + ":_alert_hdl.._summed_alerts");
  }

  /**
    @brief Connect to reason pattern, workfuction will be called last iType
    @author mtrummer
    @param sWorkfunction     name of the workfunction to be executed with paramter of last iType
    @param sReasonPattern    for filtering to reason e.g. "plc13 *"
    @param sApp              for filtering on package(s) or the default: * for all packages
  */
  public static void connectToLastTypeOfReason(const string &sWorkfunction, const string &sReasonPattern, string sApp = "*")
  {
    dpQueryConnectSingle("connectToLastTypeOfReasonWork", TRUE, makeDynString(sWorkfunction, sReasonPattern), "SELECT ALERT '_alert_hdl.._visible', '_alert_hdl.._add_value_" + iADD_TYPE + "', '_alert_hdl.._add_value_" + iADD_REASON + "', "
                         "'_alert_hdl.._alert_color' FROM '" + EB_PREFIX_PACKAGE + sApp + "' WHERE '_alert_hdl.._add_value_" + iADD_REASON + "' LIKE \"" + sReasonPattern + "\"");
  }

  /**
    @brief Disconnect from reason pattern (workfuction has been called with last iType)
    @author mtrummer
    @param sWorkfunction: name of the workfunction to be executed with paramter of last iType
    @param sReasonPattern: for filtering to reason e.g. "plc13 *"
  */
  public void disconnectFromLastTypeOfReason(const string &sWorkfunction, const string &sReasonPattern)
  {
    dpQueryDisconnect("connectToLastTypeOfReasonWork", makeDynString(sWorkfunction, sReasonPattern));
  }

  /**
    @brief Connect to reason pattern, workfuction will be called last iType
    @author Martin Schiefer
    @param sWorkfunction     name of the workfunction to be executed with paramter of last iType
    @param sReasonPattern    for filtering to reason e.g. "plc13 *"
    @param iRow              additional int that will be send to the callback function
    @param sApp              for filtering on package(s)
  */
  public void connectToLastTypeOfReasonForGenericDriver(string sWorkfunction, string sReasonPattern, int iRow, string sApp)
  {
    string sQuery = "SELECT ALERT '_alert_hdl.._visible,_alert_hdl.._add_value_" + iADD_TYPE + ",_alert_hdl.._add_value_" + iADD_REASON + ",_alert_hdl.._alert_color'"
                    " FROM '" + EB_PREFIX_PACKAGE + sApp + "'"
                    " WHERE '_alert_hdl.._add_value_" + iADD_REASON + "' LIKE \"" + sReasonPattern + "*\"";

    dpQueryConnectSingle("connectToLastTypeOfReasonWorkForGenericDriver", TRUE, makeDynAnytype(sWorkfunction, sReasonPattern, iRow), sQuery);
  }

  /**
    @brief Disconnect from reason pattern (workfuction has been called with last iType)
    @author Martin Schiefer
    @param sWorkfunction: name of the workfunction to be executed with paramter of last iType
    @param sReasonPattern: for filtering to reason e.g. "plc13 *"
    @param iRow: additional int that will be send to the callback function
  */
  public void disconnectFromLastTypeOfReasonForGenericDriver(string sWorkfunction, string sReasonPattern, int iRow)
  {
    dpQueryDisconnect("connectToLastTypeOfReasonWorkForGenericDriver", makeDynAnytype(sWorkfunction, sReasonPattern, iRow));
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  /**
    @brief Callback function for connecting to reason pattern, given workfuction will be called last iType
    @author mtrummer
    @param dsUserData[1] = sWorkfunction: name of the workfunction to be executed with paramter of last iType, dsUserData[2] =  sReasonPattern
  */
  private static void connectToLastTypeOfReasonWork(dyn_string dsUserData, dyn_dyn_anytype ddaTab)
  {
    int iHighestType = 0;
    int i = dynlen(ddaTab);

    if (i > 1)
    {
      //check last alarm state (if invisible, currently no alarm is pending)
      if (ddaTab[i][3] == TRUE) //visible
      {
        iHighestType = ddaTab[i][4];
      }
    }

    execScript("main(){" + dsUserData[1] + "(" + iHighestType + ");}", makeDynString());
  }

  /**
    @brief Callback function for connecting to reason pattern, given work function will be called last iType
    @author Martin Schiefer
    @param dsUserData[1] = sWorkfunction: name of the workfunction to be executed with parameter of last iType, dsUserData[2] = sReasonPattern
  */
  private void connectToLastTypeOfReasonWorkForGenericDriver(const dyn_anytype &daUserData, const dyn_dyn_anytype &ddaTab)
  {
    string sType;

    //update mCurrentDriverLogs variable with content of hotlink (so only pending alarms are in mapping variable)
    for (int i = dynlen(ddaTab); i > 1; i--)
    {
      //check last alarm state (if invisible, currently no alarm is pending)
      if (ddaTab[i][3] == TRUE) //visible
      {
        //update alarm in mapping
        mCurrentDriverLogs[ddaTab[i][2]] = ddaTab[i][4];

        if (sType == "") //is not set now
        {
          dyn_string dsParts = strsplit(dpSubStr(ddaTab[i][1], DPSUB_DP_EL), ".");

          if (dynlen(dsParts) >= 3)
          {
            sType = dsParts[3];
          }
        }
      }
      else //remove, because alarm is not visible anymore
      {
        if (mappingHasKey(mCurrentDriverLogs, ddaTab[i][2]))
        {
          mappingRemove(mCurrentDriverLogs, ddaTab[i][2]);
        }
      }
    }

    //search for highest pending alarm
    int iHighestType = -1;
    atime aHighest;

    //get highest state
    for (int i = 1; i <= mappinglen(mCurrentDriverLogs); i++)
    {
      if (mappingGetKey(mCurrentDriverLogs, i) != "id" && iHighestType < mappingGetValue(mCurrentDriverLogs, i))
      {
        iHighestType = mappingGetValue(mCurrentDriverLogs, i);
        aHighest = mappingGetKey(mCurrentDriverLogs, i);
      }
    }

    if (iHighestType >= 0)
    {
      dyn_string dsParts = strsplit(dpSubStr(getAIdentifier(aHighest), DPSUB_DP_EL), ".");

      if (dynlen(dsParts) >= 3)
      {
        sType = dsParts[3];
      }
    }
    else //set highest type at minimum to 0
    {
      iHighestType = 0;
    }

    mCurrentDriverLogs["id"] = daUserData[2];

    execScript("main(){" + daUserData[1] + "(" + iHighestType + ", " + daUserData[3] + ", \"" + sType + "\");}", makeDynString());
  }

  /**
    @brief Get log count with specific reasons
    @author mtrummer
    @param dsReason: list of reason patterns to be counted
    @param dsFilterAppName: app names (DPs) or "*" which should be included in the result
    @param dsFilterType: types (DPE nodes -> Runtime, Configuration, Internet, Periphery, Update) or "*" which should be included in the result
    @param tFrom: if != 0, timestamp for the begin of the query
    @param tTo: if != 0, timestamp for the end of the query
  */
  public static unsigned getLogCount(const dyn_string &dsReason, dyn_string dsFilterAppName = makeDynString("*"), dyn_string dsFilterType = makeDynString("*"), time tFrom = 0, time tTo = 0)
  {
    dyn_dyn_anytype ddaTab;
    unsigned uCnt;
    int iReasonCol;

    dpQuery(getQuery(FALSE, dsFilterAppName, dsFilterType, tFrom, tTo), ddaTab);

    for (int i = dynlen(ddaTab); i > 1; i--)
    {
      if (iReasonCol == 0)
      {
        for (int j = 1; j <= dynlen(ddaTab[1]) && iReasonCol == 0; j++)
        {
          if (ddaTab[1][j] == ":_alert_hdl.._add_value_" + iADD_REASON)
          {
            iReasonCol = j;
          }
        }
      }

      for (int j = dynlen(dsReason); j > 0; j--)
      {
        if (patternMatch(dsReason[j], ddaTab[i][iReasonCol]))
        {
          uCnt++;
        }
      }
    }

    return uCnt;
  }

  /**
    @brief Get log list, workfuction will be called with list of logs
    @author mtrummer
    @param aWorkfunction: name of the workfunction (string) or function pointer to workfunction to be executed with the list of changes
    @param bTableUsage: TRUE to get the results (update and remove list) as dyn_dyn_anytype to put into an table; FALSE to get the results results (update and remove list) as dyn_anytype of EBlogEntry(s)
    @param dsFilterAppName: app names (DPs) or "*" which should be included in the result
    @param dsFilterType: types (DPE nodes -> Runtime, Configuration, Internet, Periphery, Update) or "*" which should be included in the result
    @param tFrom: if != 0, timestamp for the begin of the query
    @param tTo: if != 0, timestamp for the end of the query
    @param sTabShape: result table shape, if not own object (this)
  */
  public static void getLogs(const anytype &aWorkfunction, bool bTableUsage = TRUE, dyn_string dsFilterAppName = makeDynString("*"), dyn_string dsFilterType = makeDynString("*"), time tFrom = 0, time tTo = 0, string sTabShape = "")
  {
    dyn_dyn_anytype ddaTab;

    dpQuery(getQuery(bTableUsage, dsFilterAppName, dsFilterType, tFrom, tTo), ddaTab);

    connectWorkLogs(makeDynAnytype(aWorkfunction, bTableUsage, TRUE, sTabShape), ddaTab);
  }

  /**
    @brief Get log list of active logs (current or time period) in form of json string
    @author mtrummer
    @param eLogSeverity:    severiy filter (LogSeverity: Information, Warning, Error, All) ignore
    @param dsFilterAppName: app names (DPs) or "*" which should be included in the result
    @param dsFilterType:    types (DPE nodes -> Runtime, Configuration, Internet, Periphery, Update) or "*" which should be included in the result
    @param tFrom:           if != 0, timestamp for the begin of the query
    @param tTo:             if != 0, timestamp for the end of the query
    @retun json string of filtered logs
  */
  public static string getLogAsJsonString(LogSeverity eLogSeverity = LogSeverity::All, dyn_string dsFilterAppName = makeDynString("*"), dyn_string dsFilterType = makeDynString("*"), time tFrom = 0, time tTo = 0)
  {
    dyn_dyn_anytype ddaTab;
    mapping mResult = makeMapping("filterApp", dsFilterAppName, "filterType", dsFilterType, "logs", makeDynMapping());

    dpQuery(getQuery(FALSE, dsFilterAppName, dsFilterType, tFrom, tTo, eLogSeverity), ddaTab);

    mResult["timeCurrent"] = getCurrentTime();
    mResult["serverityFilter"] = eLogSeverity;

    if (tFrom != 0) //historical alarms
    {
      mResult["timeFrom"]  = tFrom;
      mResult["timeTo"]    = tTo;
      mResult["timeRange"] = "history";
    }
    else //current alarms
    {
      mResult["timeFrom"]  = mResult["timeCurrent"];
      mResult["timeTo"]    = mResult["timeCurrent"];
      mResult["timeRange"] = "current";
    }

    dyn_string dsKey;
    mapping mColumns = makeMapping(":_alert_hdl.._add_value_" + iADD_TEXT,   "text",
                                   ":_alert_hdl.._add_value_" + iADD_TYPE,   "type",
                                   ":_alert_hdl.._add_value_" + iADD_REASON, "reason",
                                   ":_alert_hdl.._alert_color", "color",
                                   ":_alert_hdl.._text", "text",
                                   ":_alert_hdl.._visible", "visible",
                                   ":_alert_hdl.._prior", "severity",
                                   ":_alert_hdl.._partner", "went");


    dyn_int diPrioSum = makeDynInt(0, 0, 0);
    int iColumnPrio;
    int iColumnReason;

    // abort in case there is no query result
    if (dynlen(ddaTab) == 0)
    {
      return jsonEncode(mResult, FALSE);
    }

    //collect head (keys)
    for (int j = 2; j <= dynlen(ddaTab[1]); j++) //ignore DPE column
    {
      string sKey;

      if (j == 2)
      {
        sKey = "atime";
      }
      else if (mappingHasKey(mColumns, (string) ddaTab[1][j]))
      {
        sKey = mColumns[(string)ddaTab[1][j]];

        if (sKey == "severity")
        {
          iColumnPrio = j;
        }
        else if (sKey == "reason")
        {
          iColumnReason = j;
        }
      }
      else
      {
        sKey = ddaTab[1][j];
        strreplace(sKey, ":_alert_hdl.._", "");
      }

      dynAppend(dsKey, sKey);
    }

    int iConfigurationChangeRequests;
    int iConfigurationChangeSuccess;
    int iConfigurationChangeFailed;

    for (int i = 2; i <= dynlen(ddaTab); i++) //begin with row 2 to collect values
    {
      mapping mRow;

      for (int j = 2; j <= dynlen(ddaTab[i]); j++) //ignore DPE column
      {
        mRow[dsKey[j - 1]] = ddaTab[i][j];

        if (j == iColumnPrio)
        {
          diPrioSum[ddaTab[i][j]]++; //count for severity
        }

        if (j == iColumnReason) //configuration changes
        {
          switch (ddaTab[i][j])
          {
            case CONFIG_CHANGE_REQUEST: //Configuration change requested
              iConfigurationChangeRequests++;
              break;

            case CONFIG_CHANGE_SUCCESS: //Configuration change executed successfully
              iConfigurationChangeSuccess++;
              break;

            case CONFIG_CHANGE_FAILED: //Configuration change executed not successfully
              iConfigurationChangeFailed++;
              break;

            default:
              break;
          }
        }
      }

      dynAppend(mResult["logs"], mRow);
    }

    mapping mConclusio;

    mapping mSeverity = makeMapping(1, "Information", 2, "Warning", 3, "Error");

    int iSeverity = (int)eLogSeverity;

    if (iSeverity < (int) LogSeverity::First)
    {
      iSeverity = (int)LogSeverity::First;
    }

    for (; iSeverity <= (int)LogSeverity::Last; iSeverity++)
    {
      mConclusio[mSeverity[iSeverity]] = diPrioSum[iSeverity];
    }

    if (diPrioSum[3] == 0 && diPrioSum[2] == 0) //no errors, no warnings
    {
      mConclusio["state"] = "everything works fine with no erros and no warnings";
    }
    else if (diPrioSum[3] == 0) //no errors, but warnings
    {
      mConclusio["state"] = "box running with warings";
    }
    else   //some errors
    {
      mConclusio["state"] = "box running with errors";
    }

    mConclusio["configurationChangeRequest"] = iConfigurationChangeRequests;
    mConclusio["configurationChangeSuccess"] = iConfigurationChangeSuccess;
    mConclusio["configurationChangeFailed"]  = iConfigurationChangeFailed;

    mResult["conclusio"] = mConclusio;
    return jsonEncode(mResult, FALSE);
  }


  /**
    @author mtrummer
    @param strDPE: datapoint element
    @return returns appName (part of the DP name)
  */
  public static string getAppNameDPE(const string &sAppDpe)
  {
    string sResult = strrtrim(dpSubStr(sAppDpe, DPSUB_DP), ".");

    strreplace(sResult, EB_PREFIX_PACKAGE, "");

    return sResult;
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  /**
    @brief Generate query for queryConnect or dpQuery
    @author mtrummer
    @param bTableUsage: TRUE to get the results (update and remove list) as dyn_dyn_anytype to put into an table; FALSE to get the results results (update and remove list) as dyn_anytype of EBlogEntry(s)
    @param dsFilterAppName: app names (DPs) or "*" which should be included in the result
    @param dsFilterType: types (DPE nodes -> Runtime, Configuration, Internet, Periphery, Update) or "*" which should be included in the result
    @param tFrom: if != 0, timestamp for the begin of the query
    @param tTo: if != 0, timestamp for the end of the query
    @param eLogSeverity:    severiy filter (LogSeverity: Information, Warning, Error, All) ignore
  */
  private static string getQuery(bool bTableUsage, const dyn_string &dsFilterAppName, const dyn_string &dsFilterType, time tFrom = 0, time tTo = 0, LogSeverity eLogSeverity = LogSeverity::All)
  {
    string sConnectDPE;

    for (int i = 1; i <= dynlen(dsFilterAppName); i++) //DPs
    {
      for (int j = 1; j <= dynlen(dsFilterType); j++)//DPEs
      {
        if (sConnectDPE != "")
        {
          sConnectDPE += ",";
        }
        else
        {
          sConnectDPE = "{";
        }

        sConnectDPE += (dsFilterAppName[i] == "*" ? "*" : EB_PREFIX_PACKAGE + dsFilterAppName[i]) + ".Alerts." + dsFilterType[j] + ".log";
      }
    }

    sConnectDPE += "}";

    string sQuery = "SELECT ALERT '_alert_hdl.._visible,_alert_hdl.._text,_alert_hdl.._add_value_" + iADD_TYPE + ",_alert_hdl.._add_value_" + iADD_REASON + ",_alert_hdl.._alert_color','_alert_hdl.._prior','_alert_hdl.._partner'"
                    " FROM '" + sConnectDPE + "' WHERE _DPT = \"" + EB_DPTYPE_PACKAGES + "\"";

    if (eLogSeverity != LogSeverity::All)
    {
      sQuery += " AND '_alert_hdl.._prior' >= " + (int)eLogSeverity;
    }

    if (tFrom != 0 || tTo != 0)
    {
      sQuery += " TIMERANGE(\"" + (string)tFrom + "\",\"" + (string)tTo + "\",1,0)";
    }

    return sQuery;
  }

  /**
    @brief Callback function of connectToLogs, which prepares the result lists (update and remove list) and executes the workfunction
    @author mtrummer
    @param daWorkfunction: [1] name workfuntion as function pointer or string of the panel scopelib;
                           [2] bTableUsage: TRUE to get the results (update and remove list) as dyn_dyn_anytype to put into an table, FALSE to get the results results (update and remove list) as dyn_anytype of EBlogEntry(s)
                           [3] bHistQuery: FALSE to remove invisible alarms
    @param ddmTabUpdate: log list of dpQueryConnectSingle
    @param shTab: result table shape, if not own object (this)
  */
  private static void connectWorkLogs(const dyn_anytype &daWorkfunction, dyn_dyn_mixed ddmTabUpdate)
  {
    anytype aWorkfunction = daWorkfunction[1]; //callback function on panel
    bool bTableUsage = daWorkfunction[2]; //return dyn_dyn_anytypes for updateTable function
    bool bHistQuery = dynlen(daWorkfunction) >= 3 ? daWorkfunction[3] : FALSE;
    string sTab;

    if (dynlen(daWorkfunction) >= 4)
    {
      sTab = daWorkfunction[4];
    }

    dyn_dyn_anytype ddaTabRemove;
    getLogsUpdateRemoveList(ddmTabUpdate, ddaTabRemove, bHistQuery, bTableUsage);

    if (bTableUsage)    //return dyn_dyn_anytypes for updateTable function
    {
      dynDynTurn(ddmTabUpdate);
      dynDynTurn(ddaTabRemove);
      callFunction(aWorkfunction, ddmTabUpdate, ddaTabRemove, sTab);
    }
    else  //return dyn_anytypes of EBlogEntry(s)
    {
      if (getType(aWorkfunction) == STRING_VAR)
      {
        execScript("main(dyn_anytype u, dyn_anytype r, string sTab){" + aWorkfunction + "(u, r, sTab);}", makeDynString(), getLogEntryList(ddmTabUpdate), getLogEntryList(ddaTabRemove), sTab);
      }
      else
      {
        callFunction(fpWorkfunction, getLogEntryList(ddmTabUpdate), getLogEntryList(ddaTabRemove), sTab);
      }
    }
  }

  /**
    @brief get update and remove list of query result
    @author mtrummer
    @param daWorkfunction: [1] name workfuntion as function pointer or string of the panel scopelib;
                           [2] bTableUsage: TRUE to get the results (update and remove list) as dyn_dyn_anytype to put into an table, FALSE to get the results results (update and remove list) as dyn_anytype of EBlogEntry(s)
                           [3] bHistQuery: FALSE to remove invisible alarms
    @param ddmTabUpdate: log list of dpQueryConnectSingle
    @param shTab: result table shape, if not own object (this)
  */
  public static void getLogsUpdateRemoveList(dyn_dyn_mixed &ddmTabUpdate, dyn_dyn_anytype &ddaTabRemove, const bool bHistQuery, const bool bTableUsage = FALSE)
  {
    if (dynlen(ddmTabUpdate) < 1)
    {
      return;
    }

    dynRemove(ddmTabUpdate, 1); //remove header
    dyn_dyn_anytype ddaTabRemove;

    if (!bHistQuery) //only visible alarms
    {
      for (int i = dynlen(ddmTabUpdate); i > 0; i--)
      {
        if (ddmTabUpdate[i][3] == FALSE) //not visible anymore,
        {
          dynAppend(ddaTabRemove, ddmTabUpdate[i]);
          dynRemove(ddmTabUpdate, i);
          continue;
        }
        else if (bTableUsage) //set background color to reason column
        {
          ddmTabUpdate[i][6] = makeDynAnytype((langString)ddmTabUpdate[i][6], (string)ddmTabUpdate[i][7]);
        }
      }
    }
  }

  /**
    @brief Generate a list dyn_anytyp list of logentries from a dyn_dyn_anytype of dpQuery
    @author mtrummer
    @param ddaTab: dyn_dyn_anytype list of logs
    @return returns dyn_anytype list of EBlogEntry(s)
  */
  private static dyn_anytype getLogEntryList(const dyn_dyn_anytype &ddaTab)
  {
    dyn_anytype daLogEntries;

    for (int i = 1; i <= dynlen(ddaTab); i++)
    {
      EBlogEntry le;
      le.setLogEntry(getTypeFromDPE(ddaTab[i][1]), ddaTab[i][6], ddaTab[i][4], ddaTab[i][5], (time)ddaTab[i][2], getAppNameDPE(ddaTab[i][1]), ddaTab[i][7]);
      dynAppend(daLogEntries, le);
    }

    return daLogEntries;
  }

  /**
    @author mtrummer
    @param strDPE: datapoint element
    @return returns last leaf of DPE = sType of the log entry
  */
  private static string getTypeFromDPE(const string &strDPE)
  {
    string sRet = dpSubStr(strDPE, DPSUB_DP_EL);

    dyn_string dsSplit = strsplit(sRet, ".");

    if (dynlen(dsSplit) == 0)
    {
      strreplace(strDPE, ".", "");
      return sRet;
    }

    return dsSplit[dynlen(dsSplit) - 1]; //last element is ".log"
  }

  /**
    @brief Callback function of connectToLogs, which prepares the result lists (update and remove list) and executes the workfunction
    @author mtrummer
    @param daUserData[1] = sWorkfunction (name workfuntion of the panel scopelib), daUserData[2] if exists is the shape
    @param s: connected attribute
    @param sColor: color of the alarm
    @param datAlerts: pending alarms of summary alarm
  */
  private void connectWorkLogSumColor(const dyn_anytype &daUserData, const string &s, const string &sColor, const string &s2, const dyn_atime &datAlerts)
  {
    string sWorkfunction = daUserData[1];
    dyn_anytype daEntries;
    string sEntryReason;
    langString lsEntryText;
    string sAlarmDPE;
    int iEntryType;

    for (int i = 1; i <= dynlen(datAlerts); i++)
    {
      sAlarmDPE = dpSubStr(getAIdentifier(datAlerts[i]), DPSUB_DP_EL);
      alertGet(datAlerts[i], getACount(datAlerts[i]), sAlarmDPE + ":_alert_hdl.._add_value_" + iADD_REASON, sEntryReason,
               datAlerts[i], getACount(datAlerts[i]), sAlarmDPE + ":_alert_hdl.._add_value_" + iADD_TEXT, lsEntryText,
               datAlerts[i], getACount(datAlerts[i]), sAlarmDPE + ":_alert_hdl.._add_value_" + iADD_TYPE, iEntryType);

      EBlogEntry tmpLogEntry = EBlogEntry(getTypeFromDPE(sAlarmDPE), sEntryReason, lsEntryText, iEntryType, (time)datAlerts[i], getAppNameDPE(sAlarmDPE));
      dynAppend(daEntries, tmpLogEntry);
    }

    if (dynlen(daUserData) >= 2 && daUserData[2] != 0)
    {
      execScript("main(string s, dyn_anytype r, string sh){" + sWorkfunction + "(s,r,sh);}", makeDynString(), sColor, daEntries, daUserData[2]);
    }
    else
    {
      execScript("main(string s, dyn_anytype r){" + sWorkfunction + "(s,r);}", makeDynString(), sColor, daEntries);
    }
  }
};

