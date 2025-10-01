// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author z00229jf
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "Diagnostics"
#uses "Logging"

//--------------------------------------------------------------------------------
// Constants
const int    INTERVAL_CPU_MEM_MONITOR = 10;                              //!< Check the CPU and Memory consumption load every x seconds
const int    USERBIT_LOG              = 32;                              //!< This bit is used to indicate that there is already a pending log
const string APP_LOG                  = "Base";                          //!< Use the 'EB_Package_Base' dp for logging

// The following Pmon SNMP Object IDs should match the docu: Drivers -> SNMP -> Traps -> PMON
const string OID_MANAGER_START    = "1.3.6.1.4.1.13828.2.1.9.0.1";   //!< Object ID, that the pmon sends on a manager start
const string OID_MANAGER_STOP     = "1.3.6.1.4.1.13828.2.1.9.0.2";   //!< Object ID, that the pmon sends after it detected a stopped manager
const string OID_PROJECT_STOP     = "1.3.6.1.4.1.13828.2.1.9.0.5";   //!< Object ID, that the pmon sends on a project stop

//--------------------------------------------------------------------------------
// Variables
shared_ptr<EBlog> g_spLog     = new EBlog(APP_LOG);
mapping           g_mDrivers;

//--------------------------------------------------------------------------------
/**
 * @brief Logs various system events & data
 */
void main()
{
  mapping mConfig = readLogConfig();

  // Connect to the datapoints from the logging configuration file
  for (int i = 1; i <= mappinglen(mConfig); i++)
  {
    string sDpe = mappingGetKey(mConfig, i);

    dyn_string dsCaptures;

    // Check if a specific dpe has been specified or need to connect to all dps of a type
    // For example split the value '@_Ui.UserName,.DisplayName' into the dptype '_Ui' and the elements '.UserName,.DisplayName'
    regexpSplit("^@([^.]+)(\\S+)", sDpe, dsCaptures, makeMapping("caseSensitive", TRUE));

    if (dynlen(dsCaptures) >= 3)
    {
      // Split the elements into multiple values, for example: '.UserName,.DisplayName' into '.UserName' and '.DisplayName'
      dyn_string dsSplit = strsplit(dsCaptures[3], ",");
      string sSelect = dsSplit[1] + ":_online.._userbit" + USERBIT_LOG + "," + strjoin(dsSplit, ":_online.._value,") + ":_online.._value";
      string sDpType = dsCaptures[2];
      string sQuery  = "SELECT '" + sSelect + "' FROM '*' WHERE _DPT = \"" + sDpType + "\" AND _DP != \"_mp_" + sDpType + "\"";

      // Connect to all dps of a type
      dpQueryConnectSingle("cbLogQuery", TRUE, mappingGetValue(mConfig, i), sQuery, 50);
    }
    else if(!patternMatch(Diagnostics::sManagerCpuMemDpPrefix + "*.*", sDpe)) //cpu and memory logging is done directly in monitoring function
    {
      // Connect to a specific dpe
      dpConnectUserData("cbLog", mappingGetValue(mConfig, i), sDpe, dpSubStr(sDpe, DPSUB_DP_EL) + ":_online.._userbit" + USERBIT_LOG);
    }
  }

  // Connect to the driver names to create a map with their numbers, so the driver number can be determined from the '_EB_DriverConnection' dp
  dpQueryConnectSingle("cbDriverMapping", "", "SELECT '.DT:_online.._value' FROM '*' WHERE _DPT = \"_DriverCommon\"");

  // Connect to SNMP Manager trap elements for pmon updates (manager start/stop & project stop)
  dpConnect("cbTrap", "_1_SNMPManager.Trap.specificTrap", "_1_SNMPManager.Trap.PayloadValue");

  // Log the time of the project start
  time tProjectStart;

  dpGet("_DataManager.UseValueArchive:_online.._stime", tProjectStart);

  Diagnostics::changeLog(TRUE,  Logging::PROJECT_START, LogSeverity::Information, FALSE, makeDynAnytype(), "", tProjectStart);
  Diagnostics::changeLog(FALSE, Logging::PROJECT_STOP,  LogSeverity::Information, TRUE,  makeDynAnytype());     // This might be still active due to the project stop

  Diagnostics::startCpuMemMonitoring(INTERVAL_CPU_MEM_MONITOR, mConfig);
}

/**
 * @brief Callback function for filling the driver mapping to match names to numbers
 * @param aUserData     User data (not used)
 * @param ddaData       Data from the query
 */
void cbDriverMapping(const anytype &aUserData, const dyn_dyn_anytype &ddaData)
{
  for (int i = 2; i <= dynlen(ddaData); i++)
  {
    string sDriver = ddaData[i][2];

    if (sDriver != "")
    {
      dyn_string dsCaptures;

      regexpSplit("^\\D+(\\d+)", dpSubStr(ddaData[i][1], DPSUB_DP), dsCaptures);

      if (dynlen(dsCaptures) >= 2)
      {
        string sTemp;

        sprintf(sTemp, "%03d", (int)dsCaptures[2]);

        g_mDrivers[sDriver] = sTemp;
      }
    }
  }
}

/**
 * @brief Callback function for traps received by the SNMP manager
 * @details Creates logs for project stop and manager start/stop
 * @param sDpe1    Dpe of the trap (not used)
 * @param sOid     Object ID of the event
 * @param sDpe2    Dpe of the trap payload (not used)
 * @param dsValues Additional values from the trap
 */
void cbTrap(const string &sDpe1, const string &sOid,
            const string &sDpe2, const dyn_string &dsValues)
{
  if (sOid == OID_PROJECT_STOP)
  {
    Diagnostics::changeLog(TRUE, Logging::PROJECT_STOP, LogSeverity::Information, FALSE, makeDynAnytype());
  }
  else if (sOid == OID_MANAGER_START)
  {
    Diagnostics::changeLog(TRUE, Logging::MANAGER_START, LogSeverity::Information, FALSE, dsValues);
  }
  else if (sOid == OID_MANAGER_STOP)
  {
    Diagnostics::changeLog(TRUE, Logging::MANAGER_STOP, LogSeverity::Information, FALSE, dsValues);
  }
}

/**
 * @brief Callback function for logging events
 * @details Logs all dptype configuration entries
 * @param ddaConfig     User data from the configuration file
 * @param ddaData       Data from the query
 */
void cbLogQuery(const dyn_anytype &ddaConfig, const dyn_dyn_anytype &ddaData)
{
  string sElement;
  dyn_string dsCaptures;

  regexpSplit(getSystemName() + "([^:]+)\\S+", ddaData[1][2], dsCaptures, makeMapping("caseSensitive", TRUE));

  if (dynlen(dsCaptures) >= 2)
  {
    sElement = dsCaptures[2];
  }

  DebugFTN("CB_QUERY", __FUNCTION__ + "(..., ...) element: " + sElement);

  dyn_string dsProcessed;

  for (int i = dynlen(ddaData); i >= 2; i--)
  {
    string sId = dpSubStr(ddaData[i][1], DPSUB_DP);

    // Only process the last value(s) from a datapoint
    if (dynContains(dsProcessed, sId) <= 0)
    {
      dyn_dyn_anytype ddaUserData = ddaConfig;
      dyn_anytype     daArguments = ddaData[i];

      dynAppend(dsProcessed, sId);

      dynRemove(daArguments, 1); // Remove the dp
      dynRemove(daArguments, 1); // Remove the log flag

      for (int x = 1; x <= dynlen(ddaUserData); x++)
      {
        // Replace the '???' with the driver number in the log reason
        if (ddaUserData[x][1][0] == '?' && dpTypeName(sId) == "_EB_DriverConnection")
        {
          regexpSplit("([^#]+)(\\d+)", sId, dsCaptures, makeMapping("caseSensitive", TRUE));

          if (dynlen(dsCaptures) >= 3 && mappingHasKey(g_mDrivers, dsCaptures[2]))
          {
            dyn_string dsPaths;

            cnsGetNodesByData(sId + ".State", (int)EBNodeType::DEVICE, dsPaths);

            ddaUserData[x][1] = g_mDrivers[dsCaptures[2]];
            sId               = dsCaptures[3];

            dynAppend(daArguments, sId);

            if (dynlen(dsPaths) > 0)
            {
              dynAppend(daArguments, dsPaths[1]);
            }
          }
        }
      }

      DebugFTN("CB_QUERY", __FUNCTION__ + "(..., ...) i: " + i + " id : " + sId + " dp: " + ddaData[i][1] + " value: " + ddaData[i][3] + " log active: " + ddaData[i][2], daArguments);

      Diagnostics::checkLog(ddaUserData, ddaData[i][1] + sElement, ddaData[i][3], ddaData[i][2], daArguments, sId);
    }
  }
}

/**
 * @brief Callback function for logging events
 * @details Logs all specific dp configuration entries
 * @param ddaUserData   User data from the configuration file
 * @param sDpe1         Dpe of the value
 * @param aValue        Value of the dpe to log
 * @param sDpe2         Dpe of the log flag (not used)
 * @param bLogActive    Log flag to indicate if this value is already logged
 */
void cbLog(const dyn_dyn_anytype &ddaUserData, const string &sDpe1, const anytype &aValue,
                                          const string &sDpe2, bool bLogActive)
{
  Diagnostics::checkLog(ddaUserData, sDpe1, aValue, bLogActive, makeDynAnytype(aValue));
}





/**
 * @brief Callback function of the CNS observer
 * @details Is used to update the tag count on change
 * @param sWhere   CNS path that has changed
 * @param iWhat    Type of change
 */
void cnsObserverCB(const string &sWhere, int iWhat)
{
  string sApp = cnsSubStr(sWhere, CNSSUB_VIEW, FALSE);

  DebugFN("CNS_CB", __FUNCTION__ + "(" + sWhere + ", " + iWhat + ") app: " + sApp);

  // Check if a connection or tag is affected
  if (cnsSubStr(sWhere, CNSSUB_SYS | CNSSUB_VIEW, FALSE) != sWhere &&     // Not interested in changes at view level
      patternMatch(EB_PREFIX_PACKAGE + "*", sApp))                        // This is the wanted/tree/PLC level
  {
    Diagnostics::updateCounters();
  }
}

/**
 * @brief Reads the logging configuration file (tab separated values)
 * @details Each line of the configuration must have the format:
 *  '<Reason>\t<Severity>\t<Condition>\t<DPE|@dptype.element>[\t<Pending>]
 *  Reason: key value of the 'errors' message catalog
 *  Severity: must be a value of the enum 'LogSeverity'
 *  Condition: Log is written if this condition is met and removed if it is not the case anymore
 *  DPE: DPE to connect to
 *  @dptype.element: Connects to all instances of this dptype, additional elements can be specified as arguments for the log text
 *  Pending: Optional to make an information log pending
 * @return Logging configuration
 */
mapping readLogConfig()
{
  mapping mResult;
  string sFileName = getPath(CONFIG_REL_PATH, "logging.tsv");

  if (isfile(sFileName))
  {
    string sContent;

    fileToString(sFileName, sContent);

    dyn_string dsLines = strsplit(sContent, "\n");

    for (int i = 1; i <= dynlen(dsLines); i++)
    {
      dyn_string dsSplit = strsplit(dsLines[i], "\t");

      if (dynlen(dsSplit) >= 4)
      {
        string sDpe = dsSplit[4];

        dynRemove(dsSplit, 4);

        if (!mappingHasKey(mResult, sDpe))
        {
          mResult[sDpe] = makeDynAnytype();
        }

        dyn_anytype daValues = mResult[sDpe];

        daValues[dynlen(daValues) + 1] = dsSplit;

        mResult[sDpe] = daValues;
      }
    }
  }

  DebugFN("CONFIG", __FUNCTION__ + "() Returning:", mResult);

  return mResult;
}
