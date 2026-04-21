// $License: NOLICENSE
//--------------------------------------------------------------------------------

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "classes/EBlog"

enum LogCategory
{
  All = -1,        //!< To clear all log entries
  Configuration,
  Runtime,
  Internet,
  Periphery,
  Update,
  Internal
};

class Logging
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  // The following constants must match the keys of 'errors.cat', the keys are prefixed with '???', which is replaced with the actual manager number
  public static const string PROJECT_START          = "000101";                      //!< Key for the project start message
  public static const string PROJECT_STOP           = "000102";                      //!< Key for the project stop message
  public static const string PROJECT_RESTART        = "000103";                      //!< Key for the project restart message
  public static const string PROJECT_EM_30SEC       = "000108";                      //!< Key for the emergency mode - restart in 30 seconds
  public static const string BOX_OFFBOARDED         = "000106";                      //!< Key for the device not onboarded
  public static const string BOX_ONBOARDED          = "000107";                      //!< Key for the device onboarded
  public static const string DIAG_COMMAND           = "000109";                      //!< Key for diagnostic command received
  public static const string MQTT_CFG_CHANGE        = "000123";                      //!< Key for MQTT configuration changed via config file
  public static const string CONFIG_CHANGE_REQUEST  = EBlog::CONFIG_CHANGE_REQUEST;  //!< Key for the configuration change requested
  public static const string CONFIG_CHANGE_SUCCESS  = EBlog::CONFIG_CHANGE_SUCCESS;  //!< Key for the configuration change executed successfully
  public static const string CONFIG_CHANGE_FAILED   = EBlog::CONFIG_CHANGE_FAILED;   //!< Key for the configuration change execution failure
  public static const string MANAGER_START          = "000401";                      //!< Key for the manager start message
  public static const string MANAGER_STOP           = "000402";                      //!< Key for the manager stop message
  public static const string MANAGER_RESTART        = "000403";                      //!< Key for the manager restart message
  public static const string MANAGER_NOT_RUNNING    = "404";                         //!< Key for the manager not running message
  public static const string DEVICE_CONNECTION_OK   = "406";                         //!< Key value for the device connection OK
  public static const string DEVICE_CONNECTION_NOK  = "407";                         //!< Key value for the device connection failure
  public static const string DEVICE_CREATE_SUCCESS  = "408";                         //!< Key value for the device created successfully message
  public static const string DEVICE_CREATE_FAILED   = "409";                         //!< Key value for the device creation failed message
  public static const string MANAGER_FAILURE_START  = "410";                         //!< Key for the manager start failure message
  public static const string MANAGER_FAILURE_STOP   = "000411";                      //!< Key for the manager stop failure message
  public static const string DEVICE_BROWSE_REQUEST  = "501";                         //!< Key value for the device browsing start message
  public static const string DEVICE_BROWSE_PROGRESS = "502";                         //!< Key value for the device browsing successfully progress
  public static const string DEVICE_BROWSE_SUCCESS  = "503";                         //!< Key value for the device browsing successfully completed message
  public static const string DEVICE_BROWSE_FAILED   = "504";                         //!< Key value for the device browsing failed message

  public static const string DRIVER_INSTALL_SUCCESS = "422";                         //!< Key value for the driver installed successfully message
  public static const string DRIVER_INSTALL_FAILED  = "423";                         //!< Key value for the driver installation failed message
  public static const string COUNT_TAGS              = "000428";                      //!< Key for the tag count message
  public static const string COUNT_CONNECTIONS       = "000430";                      //!< Key for the connection count message
  public static const string COMMAND_VALUE_RECEIVED  = "000125";                      //!< Key for command value received by WinCC OA
  public static const string CMD_VAL_RECEIVED_BY_APP = "450";                         //!< Key for command value received and protocoll found
  public static const string CMD_VAL_SUCCESS         = "451";                         //!< Key for command value sucessfully written to device
  public static const string CMD_VAL_FAILED          = "452";                         //!< Key for command value failed - value could not be written sucessfully
  public static const string CONFIG_SCDFILE_DWL_FAIL = "000130";                      //!< Key for the download of an SCD file from the Mindsphere failed
  public static const string CONFIG_SCDFILE_DWL_SUCC = "000131";                      //!< Key for the download of an SCD file from the Mindsphere succeeded


  public static const int FORCEPENDING_NO           = 0;          //not pending log
  public static const int FORCEPENDING_FORCEPENDING = 1;          //force new log + let it be pending
  public static const int FORCEPENDING_FORCE        = 2;          //force new log (update if already existing)
  public static const int FORCEPENDING_PENDING      = 3;          //let log pending

  /**
   * @brief Clears the specified log
   * @param eCategory   Category of the log
   * @param sKey        Message catalog key and the log reason
   * @param sId         Optional: extra id for the log reason
   * @param sManagerKey      Optional: Manager number in '%03d' format
   */
  public static void clear(LogCategory eCategory, const string &sKey, string sId = "", string sManagerKey = "")
  {
    DebugFTN("LOG_CLEAR", __FUNCTION__ + "(" + sKey + ", " + sId + ")");

    string sReason   = sManagerKey + sKey;
    string sCategory = mappingHasKey(CATEGORY_TEXTS, eCategory) ? CATEGORY_TEXTS[eCategory] : LOG_TYPE_INTERNAL;

    // Add the optional value to the reason
    if (sId != "")
    {
      sReason += " (" + sId + ")";
    }

    // Remove the log entries
    dyn_atime datDummy;
    time t;
    spLog.removePendingLogs(sCategory, datDummy, 0, sReason + "*", TRUE);
  }

  /**
   * @brief Clears all logs
   * @param sKey   Message catalog key and the log reason
   * @param sId    Optional: extra id for the log reason
   * @param sManagerKey      Optional: Manager number in '%03d' format
   */
  public static void clearAll(const string &sKey, string sId = "", string sManagerKey = "")
  {
    DebugFTN("LOG_CLEAR", __FUNCTION__ + "(" + sKey + ", " + sId + ")");
    string sReason  = sManagerKey + sKey;

    // Remove the log entries
    for (int i = 2; i <= mappinglen(CATEGORY_TEXTS); i++)
    {
      dyn_atime datDummy;
      spLog.removePendingLogs(mappingGetValue(CATEGORY_TEXTS, i), datDummy, 0, sReason + "*", TRUE);
    }
  }

  /**
   * @brief get number of logs with specific id
   * @param sKey   Message catalog key and the log reason
   * @param sId    Optional: extra id for the log reason
   * @param sManagerKey      Optional: Manager number in '%03d' format
   */
  public static unsigned getCount(const string &sKey, string sId = "", string sManagerKey = "")
  {
    DebugFTN("LOG_COUNT", __FUNCTION__ + "(" + sKey + ", " + sId + ", " + sManagerKey + ")");
    string sReason  = sKey;
    strreplace(sReason, "???", sManagerKey);

    // Add the optional value to the reason
    if (sId != "")
    {
      sReason += " (" + sId + ")";
    }
    return spLog.getLogCount(makeDynString(sReason));
  }

  /**
   * @brief Writes the specified log
   * @param eCategory        Category of the log
   * @param sKey             Message catalog key and the log reason
   * @param eSeverity        Severity of the log
   * @param daArguments      Additional arguments for the log text
   * @param sId              Optional: extra id for the log reason
   * @param iForcePending    Optional: option to set the pending flag and force flag for an information log
   * @param sManagerKey      Optional: Manager number in '%03d' format
   * @param tTime            Optional: Time for the log (default: current time)
   * @param bLogInFileAnyway Optional: write log entry int log file before sending to event manager
   */
  public static void write(LogCategory eCategory, const string &sKey, LogSeverity eSeverity, const dyn_anytype &daArguments, string sId = "", int iForcePending = FORCEPENDING_NO, string sManagerKey = "", time tTime = 0, bool bLogInFileAnyway = FALSE)
  {
    DebugFTN("LOG_WRITE", __FUNCTION__ + "(" + eCategory + ", " + sKey + ", " + eSeverity + ", ..., " + sId + ", " + bForcePending + ", " + sManagerKey + ")", daArguments);

    bool   bPending = (iForcePending == FORCEPENDING_FORCEPENDING || iForcePending == FORCEPENDING_PENDING) ? TRUE : eSeverity > LogSeverity::Information;
    bool   bForce   = (iForcePending == FORCEPENDING_FORCEPENDING || iForcePending == FORCEPENDING_FORCE)   ? TRUE : eSeverity > LogSeverity::Information;
    string sReason  = sManagerKey + sKey;
    string sText    = getCatStr("errors", (sManagerKey != "" ? "???" : "") + sKey);

    // Add the optional value to the reason
    if (sId != "")
    {
      sReason += " (" + sId + ")";
    }

    // Replace the placeholder(s) with the actual value(s)
    for (int i = 1; i <= dynlen(daArguments); i++)
    {
      strreplace(sText, "$" + i, daArguments[i]);
    }

    // Write the log entry before try to create log entry, which could potenialy be blocked
    if (bLogInFileAnyway)
    {
      throwError(makeError("", PRIO_WARNING, ERR_CONTROL, 54, sReason, sText)); //add to log file before creating the log
    }

    spLog.doLog(EBlogEntry(CATEGORY_TEXTS[eCategory], sReason, sText, (int)eSeverity, tTime, APP_LOG), bPending, bForce, !bLogInFileAnyway);
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
  private static       shared_ptr<EBlog> spLog          = new EBlog(APP_LOG);
  private static const string            APP_LOG        = "Base";
  private static const mapping           CATEGORY_TEXTS = makeMapping(LogCategory::All,           LOG_TYPE_ALL,
                                                                      LogCategory::Configuration, LOG_TYPE_CONFIGURATION,
                                                                      LogCategory::Runtime,       LOG_TYPE_RUNTIME,
                                                                      LogCategory::Internet,      LOG_TYPE_INTERNET,
                                                                      LogCategory::Periphery,     LOG_TYPE_PERIPHERY,
                                                                      LogCategory::Update,        LOG_TYPE_UPDATE,
                                                                      LogCategory::Internal,      LOG_TYPE_INTERNAL);
};
