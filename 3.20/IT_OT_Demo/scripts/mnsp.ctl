// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author atw121x7
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "Diagnostics"
#uses "dpGroups"
#uses "EB_Package_Base/EB_Api"
#uses "classes/GenericDriver/DriverApp"
#uses "classes/GenericDriver/DriverConst"
#uses "classes/Factory"
#uses "classes/wssServer/WssConst"
#uses "Logging"
#uses "mnspLib"
#uses "classes/emergencyMode"

//--------------------------------------------------------------------------------
// Constants
const string DBG_DEVICE           = DriverConst::DEBUG_DEVICE;            //!< defined debug flags "device"
const string DBG_TAG              = "tag";                                //!< defined debug flags
const string DBG_VALUEUPDATE      = "value";                              //!< defined debug flags
const string DBG_CONFIGURATION    = "config";                             //!< defined debug flags
const string DBG_COMMAND          = "command";                            //!< defined debug flags
const string DBG_BROWSE           = DriverConst::DEBUG_BROWSE;            //!< defined debug flags "browse"
const string DBG_BROWSE_KEEP_FILE = "browse2";                            //!< defined debug flags "browse2" keep browsing files (do not delete after upload success)
const string DBG_NO_ADD_REMOVE    = DriverConst::DEBUG_NO_ADD_REMOVE_MAN; //!< defined debug flags "no_add_remove";
const string DBG_LOG              = "log";                                //!< defined debug flags
const string DBG_EMERGENCY_MODE   = "EmergencyMode";                      //!< defined debug flags "EmergencyMode"


const string DBG_IGNORE_DOWNLOAD_FAILURE = "ignoreDownloadFailure";               //!< defined debug flags
const string DBG_IGNORE_PROTOCOL_FILTER  = "ignoreProtocolFilter";                //!< defined debug flags
const string DBG_LOCAL_SCD_FILE          = "localSCDFile";                        //!< defined debug flags

const string DPE_NEW_CONFIGURATION            = "MindSphereConnector.receiveData";                     //!< DPE to receive configuration changes from mindsphere
const string DPE_LAST_CONFIGURATION           = "MindSphereConnector.configuration";                   //!< DPE, which stores the last done configuration (device, addresses, DPEs) received from mindsphere
const string DPE_DATAPOINTIDMAPPING           = "MindSphereConnector.mapping_dataPointId";             //!< DPE for mapping mindsphere dataPointId to TagID
const string DPE_DIAGNOSTIC_NEW               = "MindSphereConnector.diagnostic.receivedData";         //!< DPE for trigger diagnostic via mindsphere
const string DPE_DIAGNOSTIC_CURRENT           = "MindSphereConnector.diagnostic.configuration";        //!< DPE, which diagnostic setting is currently used
const string DPE_DIAGNOSTIC_LOG_FILE_SWITCHED = "MindSphereConnector.diagnostic.logFileSwitched";      //!< DPE triggered on log file switch
const string DPE_DIAGNOSTIC_LOG_FILE_REQUEST  = "MindSphereConnector.diagnostic.logFileUploadRequest"; //!< DPE to tigger log file request via mindsphere
const string DPE_DIAGNOSTIC_COMMAND           = "MindSphereConnector.diagnostic.command";              //!< DPE to tigger command (manager/project restart, ...) via mindsphere
const string DPE_COMMANDRESPONSE              = "MindSphereConnector.commandValues.commandResponse";   //!< DPE for value change command response (feedback for mindsphere on commmand value change request)
const string DPE_BOXID                        = "MindSphereConnector.boxID";                           //!< DPE for
const string DPE_FILE_REQUEST                 = "MindSphereConnector.file.Request";                    //!< DPE to request a file from the mindsphere
const string DPE_FILE_RESPONSE                = "MindSphereConnector.file.Response";                   //!< DPE that has the reponse from the mindsphere when a filerequest was made
const string DPE_BROWSING_COMMNAD             = "MindSphereConnector.browsing.receiveData";            //!< DPE to trigger plc browsing via mindpshere
const string DPE_FILE_UPLOAD_REQUEST_BY_WCCOA = "MindSphereConnector.browsing.request_fileUpload";     //!< DPE to trigger mindpshere to upload file (used for sending browsing result to mindsphere)
const string DPE_FILE_UPLOAD_RESPONSE_BY_MNSP = "MindSphereConnector.browsing.response_fileUpload";    //!< DPE where mindpshere response about file upload SUCCESS


//json keys used by mindsphere
const string KEY_MAPPING_WCCOA_MNSP_DPID     = "DPE";
const string KEY_MAPPING_WCCOA_MNSP_DEVICEID = "DEVICEID";

const string MQTT_DEVICE_COMMUNICATION_DPT = "MNSP_MQTT_COMM";

const string DPGROUP_SEND_VALUES_TO_MNSP = "SEND_VALUES_TO_MNSP";
const int INDEX_DPE         = 1;
const int INDEX_VAL         = 2;
const int INDEX_ADDCHECKED  = 3;
const int INDEX_ADDOK       = 4;
const int INDEX_FROMSQ      = 5;
const int INDEX_BAD         = 6;
const int INDEX_TIMEBAD     = 7;
const int INDEX_STIME       = 8;
const int INDEX_DISCON      = 9;
const int INDEX_INACTCON    = 10;
const int INDEX_MANID       = 11;

const string KEY_MNSP_DATASOURCE       = "dataSourceId";
const string KEY_MNSP_DATAPOINTS       = "dataPoints";
const string KEY_MNSP_DP_DATA          = "dataPointData";
const string KEY_MNSP_PROTOCOL         = "protocol";
const string KEY_MNSP_PROTOCOL_DATA    = "protocolData";
const string KEY_MNSP_IP_ADDR          = "ipAddress";
const string KEY_MNSP_BACNET_NET_ID    = "bacnetNetworkId";
const string KEY_MNSP_BACNET_IP_ADDR   = "bacnetIpAddress";
const string KEY_MNSP_BACNET_PORT      = "bacnetPort";
const string KEY_MNSP_URL              = "url";
const string KEY_MNSP_POLLRATE         = "readCycleInSeconds";
const string KEY_MNSP_TIMESTAMP        = "timestamp";

const string KEY_MNSP_DATAPOINTID      = "dataPointId";
const string KEY_MNSP_DATATYPE         = "dataType";
const string KEY_MNSP_TRANSFORMATION   = "typeTransformation";
const string KEY_MNSP_UNIT             = "unit";
const string KEY_MNSP_ADDRESS          = "address";
const string KEY_MNSP_DIRECTION        = "acquisitionType"; //READ, READ&WRITE or WRITE
const string KEY_MNSP_ON_CHANGE        = "onDataChanged";   //what's that? spontanous?
const string KEY_MNSP_TIME_FROM_FIELD  = "timeFromField";
const string KEY_MNSP_CERTIFICATES     = "certificateFileContents";
const string KEY_MNSP_NAME             = "name";
const string KEY_ORIGINAL_NAME         = "originalName";
const string KEY_MNSP_DESC             = "description";
const string KEY_MNSP_SUBINDEX         = "subindex";
const string KEY_MNSP_SLOTNUMBER       = "slotNumber";
const string KEY_MNSP_HYSTERESIS       = "hysteresis";

const int BAD_DISCONNECT_USERBIT       = 4;
const int BAD_CONNECTION_USERBIT       = 5;
const bool DEFAULT_LOW_LEVEL_CMP       = FALSE; //if not specified on device or tag, low level comparison is not used

const int INVALID_INDEX                = 1;
const int BAD_DISCONNECT_INDEX         = 2;
const int BAD_CONNECTION_INDEX         = 3;
const int INVALID_STIME_INDEX          = 4;

const int BAD_DISCONNECT               = -2136145920;
const int BAD_CONNECTION               = -2136211456;
const int INVALID_ARGUMENT             = -2136276992;
const int GOOD_ARGUMENT                = 0;

const float MEMORY_EMERGENCY_FACTOR    = 0.90;              //Percentage of used memory as factor
const float DISKSPACE_EMERGENCY_FACTOR = 0.90;              //Percentage of used diskspace as factor
const float UPPER_FLOAT_THRESHOLD      = 1.002;             //Due to FLOAT Transformation a range must be taken into account in which the floatvalue is shown as valid
const float LOWER_FLOAT_THRESHOLD      = 0.998;             //Due to FLOAT Transformation a range must be taken into account in which the floatvalue is shown as valid

const string MAPPING_COMPARE_NOCHANGE = "NO_CHANGE";
const string MAPPING_COMPARE_DEFAULT  = "NEW_DEFAULT";


const string MNSP_LOG_UPLOAD_FOLDER = "";
const string PATH_DATA_SCD_DOWNLOAD = "SCD"; //SCD download path is data/SCD

//mapping from mindsphere json keys to IOT keys
const mapping mDeviceKEY_MNSP_MNSP_IOT = makeMapping(KEY_MNSP_NAME,            DriverConst::NAME,
                                                     KEY_MNSP_DESC,            DriverConst::DESCRIPTION,
                                                     KEY_MNSP_IP_ADDR,         DriverConst::IPADDRESS,
                                                     KEY_MNSP_URL,             DriverConst::IPADDRESS, //MTConnect URL will be mapped on driver ip field
                                                     KEY_MNSP_DATASOURCE,      DriverConst::LOCATION,  //mapping source id of Mindsphere to location e.g. "dataSourceId" : "bc07810a-fa2f-4109-9ec5-afc47cbbac84"
                                                     KEY_MNSP_DATAPOINTID,     DriverConst::EXTRADATA, //"dataPointId" : "406789eada6a4"
                                                     KEY_MNSP_DATATYPE,        DriverConst::DATATYPE,
                                                     KEY_MNSP_UNIT,            DriverConst::UNIT,
                                                     KEY_MNSP_ADDRESS,         DriverConst::ADDRESS,
                                                     KEY_MNSP_POLLRATE,        DriverConst::POLLRATE,
                                                     KEY_MNSP_ON_CHANGE,       DriverConst::LOW_LEVEL_FILTER,
                                                     KEY_MNSP_HYSTERESIS,      DriverConst::SMOOTHING_ABSOLUTE,
                                                     KEY_MNSP_TIME_FROM_FIELD, DriverConst::TIME_FROM_FIELD,
                                                     KEY_MNSP_CERTIFICATES,    DriverConst::CERTIFICATES,
                                                     KEY_MNSP_SLOTNUMBER,      DriverConst::SLOT);

const int TIMEOUT_COMMAND = 10; //!< Maximum time to wait for a command result (in seconds)
const int BROWSING_FILEUPLOAD_TIMEOUT = 900; //10 Minutes time for mindsphere to upload the requested browsing files
const string BROWSING_FOLDER = getBrowsingFolder(); //folder within data folder for browsing results to be located
const int TIMEOUT_DB_VERSIONUPGRADE = 120; //!< Maximum time to wait on first start up to update DB version (patch install)
const int FAILURE_EMERGENCYMODE = -1000; //conifiguration failure emergency mode happened

const string MINDSPHERE_CONNECTION_DP = "_MindsphereMQTT";
const dyn_string PROTOCOL_WHITELIST   = getProtocolWhiteList();           //!< Only handle devices defined in list of protcolls (because mindsphere has own driver which are not supported)
const int iMyManId = convManIdToInt(CTRL_MAN, myManNum(), getSystemId(), (char)myReduHostNum());

enum eLogLevel
{
  OFF,
  TRACE,
  DEBUG,
  INFO,
  WARNING,
  ERROR
};

eLogLevel eCurrentLogLevel = eLogLevel::TRACE;

enum eCommandState
{
  EXECUTING,
  FAILED,
  EXECUTED
};

//--------------------------------------------------------------------------------
// Variables
mapping myDriverApps;                //!< Instances of driver app classes

string sLastConfiguration;           //!< last configuration (read from and stored on DPE)
string sLastDiagnostic;              //!< last configuration (read from and stored on DPE)
string sLastLogFileUploadSetting;    //!< last log file names requested to be uploaded (read from and stored on DPE)
dyn_string dsLogFilesToUpload;       //!< log file filter for log upload after automatic log file switch

mapping mConnectionStates;           //!< Contains the current connection quality codes for comparison with new values
mapping mManagerStates;              //!< Contains the current manager states for comparison with new values
mapping mManagerPointers;            //!< Contains the manager instance pointers for the manager numbers
mapping mManagerViews;               //!< Contains the manager instance pointers for the manager views

///@todo Check if these mapping can be replaced by using aliases
mapping mWinccoaDpesToMnspIds;       //!< reverse mapping datapoint elements to datapointId
mapping mDeviceIdMqttDp;             //!< mapping MDSP device ID to MQTT communication DPE in WinCC OA
mapping mMnspIdToWinccoaId;          //!< mapping mindsphere DPE ID to WinCC OA tag ID

mapping mWinccoaDpToMnspId;          //!< dpe to mnsp id
mapping mWinccoaDpToMnspDeviceId;    //!< dpe to mnsp device id
mapping mMnspIdToWinccoaDeviceId;    //!< mindsphere device ID to WinCC OA device ID

mapping mDeviceTimeSettings;         //!< Stores the 'timeFromField' setting for each device and tag

mapping mMnspProtocolsToDriverNames; //!< mapping MNSP protcol names (capital letters) to WinCC OA IOT suite driver names

mapping mUsedProtocolsAndDevices;    //!< mapping protocols to list of device IDs

string sBrowsingDefaultUnit;         //config entry for default unit on in browsing result [mnsp] browsingDefaultUnit = "-"+ sConfig, dsRet);

bool bConfiurationUpdateLock;        //variable to synchronize configuration changes and browsing (if required)

time tLastConfigurationChangeDeadband;
bool bInConfigurationChange;


mapping mDummy;                      //reusable dummy mapping variable for TagStateCallBack::getData()

/**
 * @brief Class for the function pointers
 */
class MNSP_FunctionPointers
{
  /**
   * @brief Callback function for the driver connection quality
   * @details Only used in 'startConnectionMonitoring'
   * @param mData  Quality code, message and as key the device CNS node id
   */
  public static void connectionQualityCB(const mapping &mData)
  {
    dyn_string  dsDpes;
    dyn_string  dsDpTagList;
    dyn_string dsTags;
    dyn_anytype daValues;
    dyn_bool dbStatuses;

    DebugFTN(DBG_DEVICE, "device connection state: callback function connectionQualityCB", mData);

    synchronized(mConnectionStates)
    {
      for (int i = 1; i <= mappinglen(mData); i++)
      {
        string sNode  = mappingGetKey(mData, i);
        int    iState = mData[sNode][1];
        DebugFTN(DBG_DEVICE, "device connection state: state change for device: " + (!mappingHasKey(mConnectionStates, sNode) || mConnectionStates[sNode] != iState), mData, mappingHasKey(mConnectionStates, sNode), mConnectionStates, sNode, iState);

        // Check if the quality code has changed
        if (!mappingHasKey(mConnectionStates, sNode) || mConnectionStates[sNode] != iState)
        {
          // Get MindSphere id
          string sMindSphereId;

          for (int j = mappinglen(mMnspIdToWinccoaDeviceId); j > 0 && sMindSphereId == ""; j--)
          {
            if (mappingGetValue(mMnspIdToWinccoaDeviceId, j) == sNode)
            {
              sMindSphereId = mappingGetKey(mMnspIdToWinccoaDeviceId, j);
            }
          }

          // Get notification DP
          string sDp = mappingHasKey(mDeviceIdMqttDp, sMindSphereId) ? mDeviceIdMqttDp[sMindSphereId] : "";

          if (sDp != "")
          {
            if (!dpExists(sDp)) //workaround because communication dp will be created dynamically
            {
              for (int i = 30; !dpExists(sDp) && i > 0; i--)
              {
                //workaround because communication dp will be created dynamically
                delay(0, 100);

                if (i == 1)
                {
                  DebugTN("communication dp does notexist!", sDp);
                }
              }
            }

            dynAppend(dsDpes,   sDp + ".Diag");
            dynAppend(daValues, jsonEncode(makeDynAnytype(makeMapping("message", mData[sNode][2], "qualityCode", iState))));
          }

          string sView = cnsSubStr(sNode, CNSSUB_SYS | CNSSUB_VIEW, FALSE);

          // Do the log handling
          if (mappingHasKey(mManagerViews, sView))
          {
            string sDeviceId = mManagerViews[sView].getDeviceId(sNode);
            langString lsDevice;
            langString lsView;

            cnsGetDisplayNames(sNode, lsDevice);
            cnsGetViewDisplayNames(sView, lsView);

            if (iState == 0) //remove logs, because the connection is OK
            {
              Logging::clear(LogCategory::Runtime, mManagerViews[sView].logGetManagerKey() + Logging::DEVICE_CONNECTION_NOK, sDeviceId);
              Logging::write(LogCategory::Runtime, Logging::DEVICE_CONNECTION_OK, LogSeverity::Information, makeDynString((string)lsView, (string)lsDevice, sDeviceId), sDeviceId, TRUE, mManagerViews[sView].logGetManagerKey());
            }
            else // Log this connection error/warning
            {
              Logging::clear(LogCategory::Runtime, mManagerViews[sView].logGetManagerKey() + Logging::DEVICE_CONNECTION_OK, sDeviceId);
              Logging::write(LogCategory::Runtime, Logging::DEVICE_CONNECTION_NOK, LogSeverity::Warning, makeDynString((string)lsView, (string)lsDevice, sDeviceId), sDeviceId, TRUE, mManagerViews[sView].logGetManagerKey());
            }

            cnsGetIdSet(sNode + ".*", CNS_SEARCH_ALL_NAMES, CNS_SEARCH_ALL_LANGUAGES, CNS_SEARCH_ALL_TYPES, dsDpTagList);

            for (int i = 1; i <= dynlen(dsDpTagList); i++)
            {
              if (iState == -1) // Status "disconnected"
              {
                dynAppend(dsTags, dsDpTagList[i] + ":_original.._userbit" + BAD_DISCONNECT_USERBIT);
                dynAppend(dbStatuses, TRUE);
                dynAppend(dsTags, dsDpTagList[i] + GenericDriverTag::ADDRESS_CHECK_BIT); //if connection is gone, reset address check
                dynAppend(dbStatuses, FALSE);

                dynAppend(dsTags, dsDpTagList[i] + ":_original.._userbit" + BAD_CONNECTION_USERBIT);
                dynAppend(dbStatuses, FALSE);
              }
              else if (iState == 1 || iState == 2) // Status "inactive" OR "operation state warnings"
              {
                dynAppend(dsTags, dsDpTagList[i] + ":_original.._userbit" + BAD_DISCONNECT_USERBIT);
                dynAppend(dbStatuses, FALSE);

                dynAppend(dsTags, dsDpTagList[i] + ":_original.._userbit" + BAD_CONNECTION_USERBIT);
                dynAppend(dbStatuses, TRUE);
              }
              else // Reset status userbits because the connection is ok and the device is running
              {
                dynAppend(dsTags, dsDpTagList[i] + ":_original.._userbit" + BAD_DISCONNECT_USERBIT);
                dynAppend(dbStatuses, FALSE);

                dynAppend(dsTags, dsDpTagList[i] + ":_original.._userbit" + BAD_CONNECTION_USERBIT);
                dynAppend(dbStatuses, FALSE);
              }
            }

            dpSet(dsTags, dbStatuses);
            DebugFTN(DBG_DEVICE, "device connection state: do dpSet #1 ", dsTags, dbStatuses);
          }

          mConnectionStates[sNode] = iState;
        }
      }
    }

    if (dynlen(dsDpes) > 0)
    {
      dpSet(dsDpes, daValues);
      DebugFTN(DBG_DEVICE, "device connection state: do dpSet #2) ", dsDpes, daValues);
    }
  }

  /**
   * @brief Callback function for emergency mode change
   * @param currentState  current emergency mode state
   */
  public static synchronized void connectionEmergencyModeCB(const eEmgergencyMode currentState)
  {
    if (currentState == eEmgergencyMode::emergencyWaitForRestart)
    {
      Logging::write(LogCategory::Internal, Logging::PROJECT_EM_30SEC, LogSeverity::Error, makeDynString());

      DebugFTN(DBG_EMERGENCY_MODE, "EmergencyMode -> restart project in 30 sec!");
      delay(30); // wait 30 seconds (to avoid infinite loop restarts without chance to come back into good condition)

      //  before restarting project
      Diagnostics::restartProject();
    }
  }
};

/**
 * @brief Main function
 */
void main()
{
  deployConfigEntries(); //use config entries for setup of MQTT configuration

  mnsp_run(); //start mindphere connector - boarding info and log onboarding state

  myDriverApps = Factory::getPluginMapping();
  dyn_string dsDriverNames = mappingKeys(myDriverApps);

  for (int i = dynlen(dsDriverNames); i > 0; i--) //translation between internal driver names and mindspher driver keys
  {
    mMnspProtocolsToDriverNames[strtoupper(dsDriverNames[i])] = dsDriverNames[i];
  }

  // Set the connection/tag counters on start up without change
  Diagnostics::updateCounters();

  init();

  startConnectionMonitoring(); //requires data mapping from init function

  dpConnect("configurationChangedCB", TRUE, DPE_NEW_CONFIGURATION);
}

/**
 * @brief Init function, read last configuration (is required to compare for differences) from DPE_LAST_CONFIGURATION
*/
private void init()
{


  addGlobal("g_fileRefeshNotificationDPE", STRING_VAR); //speed up file check
  g_fileRefeshNotificationDPE = "MindSphereConnector.packageUpdate";

  updateMnspConfigurationDP();

  //update emergency mode limits
  dpConnect("configureEmergencyModeCB", TRUE, "_ArchivDisk.TotalKB", "_MemoryCheck.TotalKB");

  string sDpMap;

  ///@todo Consider to store the last configuration in a file
  dpGet(DPE_LAST_CONFIGURATION, sLastConfiguration,
        DPE_DATAPOINTIDMAPPING, sDpMap,
        DPE_DIAGNOSTIC_CURRENT, sLastDiagnostic);

  if (sDpMap != "")
  {
    fillIdMappingFromJson(sDpMap);
  }

  string sDpGroupDP = dpSubStr(updateDatapointGroup(mappingKeys(mWinccoaDpesToMnspIds)), DPSUB_DP);

  DebugFTN(DBG_VALUEUPDATE, "value query:", mappinglen(mWinccoaDpesToMnspIds), "SELECT '_online.._value,_online.._userbit2,_online.._userbit3,_online.._from_SI,_online.._bad,_online.._stime' FROM 'DPGROUP(" + sDpGroupDP + ")'");

  dpQueryConnectSingle("sendDataToMNSP", FALSE, "", "SELECT '_online.._value,_online.._userbit2,_online.._userbit3,_online.._from_SI,_online.._bad,_online.._stime_inv,_online.._stime,_online.._userbit" + BAD_DISCONNECT_USERBIT + ",_online.._userbit" + BAD_CONNECTION_USERBIT + ",_online.._manager' FROM 'DPGROUP(" + sDpGroupDP + ")'", 100);

  //do not replay command, so start dpQueryConnect with FALSE (no answer)
  //exectue received command values from Mindsphere and send to PLC
  dpQueryConnectSingle("writeCommandFromMNSP", FALSE, "", "SELECT '_online.._value' FROM '*.Command' WHERE _DPT = \"MNSP_MQTT_COMM\"", 100);

  //if last browsing was not successfully and system has been restarted - try again
  time tCmd, tFileUpload;
  string sBrwosingCommand;
  dpGet("MindSphereConnector.browsing.receiveData:_original.._stime", tCmd,
        "MindSphereConnector.browsing.request_fileUpload:_original.._stime", tFileUpload);

  bool bCancelLastBrowsing = (tCmd > tFileUpload) && ((tCmd + BROWSING_FILEUPLOAD_TIMEOUT) > getCurrentTime());  //repeat browsing after project restart, if file upload was not successful

  dpQueryConnectSingle("browseCB", bCancelLastBrowsing, "", "SELECT '_online.._value' FROM '" + DPE_BROWSING_COMMNAD + "'", 100);

  sysConnect("dpCreatedCB", "dpCreated");

  //connnect to diagnostic/debugging trigger
  dpConnect("diagnosticRequestCB", TRUE, DPE_DIAGNOSTIC_NEW);
  dpConnect("diagnosticLogFileSwitchedCB", FALSE, DPE_DIAGNOSTIC_LOG_FILE_SWITCHED);
  dpConnect("diagnosticLogFileRequestCB", FALSE, DPE_DIAGNOSTIC_LOG_FILE_REQUEST);
  dpConnect("diagnosticCommandCB", FALSE, DPE_DIAGNOSTIC_COMMAND);

  startThread("autoLogUpload");

  waitForDbUpgrade();    //wait for possible db upgrade (should only effect first start)

  if (!isS7PlusDptUpdated())   //patch installation was not sucessfully
  {
    delay(30); //wait before retry to update DB
    dpSet("_DatabaseVersion.Sub", 0); //reset db verion, restart CTRL manager to import dp lists of patches
    Diagnostics::restartManager("WCCOActrl", "-f pvss_scripts.lst");
    waitForDbUpgrade();
  }
  delay(5);
  //connect to emergency mode state change - to restart project after leaving the emergency mode
  EmergencyMode::connectToStateChange(MNSP_FunctionPointers::connectionEmergencyModeCB);
}

/**
 * @brief read config entry [mnsp] protocolWhiteList from config file and config.level, default is "SINUMERIK|S7PLUS|FANUCFOCAS|IEC61850|MTCONNECT"
 */
dyn_string getProtocolWhiteList()
{
  dyn_string dsRet;
  string sConfig;
  dyn_string dsFiles = makeDynString(getPath(CONFIG_REL_PATH, "config"), getPath(CONFIG_REL_PATH, "config.level"));

  sConfig = paCfgReadValueDflt(dsFiles, "mnsp", "protocolWhiteList", "SINUMERIK|S7PLUS|FANUCFOCAS|IEC61850|MTCONNECT");

  strreplace(sConfig, " ", ""); //remove spaces

  dsRet = strsplit(strtoupper(sConfig), "|");

  DebugFTN(DBG_DEVICE, "mnsp protocol whitelist [mnsp] protocolWhitelist = " + sConfig, dsRet);

  return dsRet;
}

/**
 * @brief read config entries [mnsp] mqttHost, mqttPort, Certificate, ConnectionType, Username and Password from config file and config.level, default is {"Certificate": "","ConnectionString": "127.0.0.1:1883","ConnectionType": 1,"Password": "","Username": ""}
 */
void deployConfigEntries()
{
  dyn_string dsFiles = makeDynString(getPath(CONFIG_REL_PATH, "config"), getPath(CONFIG_REL_PATH, "config.level"));

  /* use MqttHost and MqttPort from Config file [mnsp] section */
  // default is {"Certificate": "","ConnectionString": "127.0.0.1:1883","ConnectionType": 1,"Password": "","Username": ""}

  string sMqttHost = paCfgReadValueDflt(dsFiles, "mnsp", "mqttHost", "127.0.0.1");

  if (sMqttHost == "")
  {
    sMqttHost = "127.0.0.1";
  }

  string sMqttPort = paCfgReadValueDflt(dsFiles, "mnsp", "mqttPort", "1883");

  string sCert = paCfgReadValueDflt(dsFiles, "mnsp", "mqttCertificate", "");
  int iConType = paCfgReadValueDflt(dsFiles, "mnsp", "mqttConnectionType", 1);
  string sPW =   paCfgReadValueDflt(dsFiles, "mnsp", "mqttPassword", "");
  string sUser = paCfgReadValueDflt(dsFiles, "mnsp", "mqttUsername", "");

  sBrowsingDefaultUnit = paCfgReadValueDflt(dsFiles, "mnsp", "browsingDefaultUnit", "");

  //read current configuration
  string sMqttConfigAddress;
  dpGet("_MindsphereMQTT.Config.Address", sMqttConfigAddress);

  mapping mCurrentMqttConfig = jsonDecode(sMqttConfigAddress);
  mapping mNewMqttConfig = makeMapping("Certificate", sCert, "ConnectionString", sMqttHost + ":" + sMqttPort,
                                       "ConnectionType", iConType, "Password", sPW, "Username", sUser);

  if (iConType == 4)
  {
    //optional keys to be set via ConnectionType 4
    mNewMqttConfig["SslVersion"] = paCfgReadValueDflt(dsFiles, "mnsp", "mqttSslVersion", 15);
    mNewMqttConfig["PSK"]        = paCfgReadValueDflt(dsFiles, "mnsp", "mqttPsk", "");
    mNewMqttConfig["Identity"]   = paCfgReadValueDflt(dsFiles, "mnsp", "mqttPskIdentity", "");
  }

  //if configuration via config file differs from datapoint configuration
  if (mCurrentMqttConfig != mNewMqttConfig) //update mqtt configuration on DP
  {
    Logging::write(LogCategory::Configuration, Logging::MQTT_CFG_CHANGE, LogSeverity::Information, makeDynString(sMqttHost + ":" + sMqttPort));

    dpSetWait("_MindsphereMQTT.Command.Enable", FALSE);
    dpSetWait("_MindsphereMQTT.Config.Address", jsonEncode(mNewMqttConfig));
    dpSetWait("_MindsphereMQTT.Command.Enable", TRUE);
  }
}

/**
 * @brief Starts the driver connection monitoring
 */
void startConnectionMonitoring()
{
  mManagerPointers[DRIVER_MAN] = makeMapping();
  mManagerStates[  DRIVER_MAN] = makeMapping();

  dyn_string dsDrivers = mappingKeys(myDriverApps);

  for (int i = 1; i <= dynlen(dsDrivers); i++)
  {
    shared_ptr<DriverApp> spDriverApp = myDriverApps[dsDrivers[i]];

    int iDriverNumber = spDriverApp.getDriverNumber();
    mManagerStates[  DRIVER_MAN][iDriverNumber] = FALSE;
    mManagerPointers[DRIVER_MAN][iDriverNumber] = spDriverApp;
    mManagerViews[spDriverApp.getView()]        = spDriverApp;
  }

  dpConnect("runningDriversCB", "_Connections.Driver.ManNums");

  // For each driver connect to the driver connection states
  for (int i = 1; i <= dynlen(dsDrivers); i++)
  {
    myDriverApps[dsDrivers[i]].logInit();   // Check if the driver is running on script start and (re)set the log
    DebugFTN(DBG_DEVICE, "device connection state: startConnectionStateLogging for protocol " + dsDrivers[i]);
    myDriverApps[dsDrivers[i]].startConnectionStateLogging(MNSP_FunctionPointers::connectionQualityCB);
  }
}

/**
 * @brief Callback function for the driver connections
 * @param sDpe          DPE of the driver connections (not used)
 * @param diManNums     Manager numbers
 */
void runningDriversCB(const string &sDpe, const dyn_int &diManNums) synchronized(mUsedProtocolsAndDevices)
{
  dyn_int diDriverNumbers = mappingKeys(mManagerStates[DRIVER_MAN]);

  for (int i = 1; i <= dynlen(diManNums); i++)
  {
    // Check if this driver is in our list
    int iIndex = dynContains(diDriverNumbers, diManNums[i]);

    if (iIndex > 0 && diManNums[i] != 0)
    {
      // Check if this running driver was not running before
      if (!mManagerStates[DRIVER_MAN][diManNums[i]])
      {
        mManagerStates[DRIVER_MAN][diManNums[i]] = TRUE;
        // Remove the 'manager is not running' logs
        Logging::clear(LogCategory::Runtime, mManagerPointers[DRIVER_MAN][diDriverNumbers[iIndex]].logGetManagerKey() + Logging::MANAGER_NOT_RUNNING);
      }

      dynRemove(diDriverNumbers, iIndex);
    }
  }

  // For the remaining (stopped/offline) drivers create a log
  for (int i = 1; i <= dynlen(diDriverNumbers); i++)
  {
    //check if devices are configured, if diDriverNumbers[i] < 0 checke if CTRL script is running for this protocoll (MTConnect)
    if (mappingHasKey(mUsedProtocolsAndDevices, mManagerPointers[DRIVER_MAN][diDriverNumbers[i]].DRIVER_NAME) &&
        dynlen(mUsedProtocolsAndDevices[mManagerPointers[DRIVER_MAN][diDriverNumbers[i]].DRIVER_NAME]) > 0)
    {
      mManagerStates[  DRIVER_MAN][diDriverNumbers[i]] = FALSE;
      Logging::write(LogCategory::Runtime, Logging::MANAGER_NOT_RUNNING, LogSeverity::Error, makeDynString(mManagerPointers[DRIVER_MAN][diDriverNumbers[i]].getDriverName(), mManagerPointers[DRIVER_MAN][diDriverNumbers[i]].getDriverNumber()), "", FALSE, mManagerPointers[DRIVER_MAN][diDriverNumbers[i]].logGetManagerKey());
    }
  }
}

/**
 * @brief On MQTT topic cloud/monitoring/datasources trigger from mindsphere, update the configuration in WinCC OA project
 * @param sDPE     dpe triggered via MQTT
 * @param sJson    json string comming from mindsphere
 */
void configurationChangedCB(const string &sDPE, const string &sJson)
{
  DebugFTN(DBG_CONFIGURATION, "command from mindsphere received" /*, jsonDecode(sJson), sDPE*/);

  updateConfiguration(sJson);

  /** @example:
  	   "readCycleInSeconds" : "60"
  	   "protocolData" : mapping 1 items
  		   "ipAddress" : "158.226.215.241"
  	   "dataSourceId" : "bc07810a-fa2f-4109-9ec5-afc47cbbac84"
  	   "description" : ""
  	   "protocol" : "S7"
  	   "name" : "mtS71"
  	   "dataPoints" : dyn_anytype 3 items
  		     1: mapping 6 items
  			   "unit" : "kg"
  			   "dataPointData" : mapping 3 items
  				   "onDataChanged" : FALSE
  				   "acquisitionType" : "READ"
  				   "address" : "DB1001.DBD60"
  			   "description" : ""
  			   "name" : "S7TagNr1"
  			   "dataType" : "INT"
  			   "dataPointId" : "406789eada6a4"
  		     2: mapping 6 items
  			   "unit" : "ms"
  			   "dataPointData" : mapping 3 items
  				   "onDataChanged" : FALSE
  				   "acquisitionType" : "READ"
  				   "address" : "T1"
  			   "description" : ""
  			   "name" : "SimulationData"
  			   "dataType" : "DOUBLE"
  			   "dataPointId" : "dae87da4f4af4"
    */

  Diagnostics::updateCounters();
}

/**
 * @brief Compare the new configuration with current configuration and update WinCC OA (devices and tags)
 * @param sNewConfiguration the new configuration
 */
void updateConfiguration(const string &sNewConfiguration)
{
  if (sNewConfiguration != sLastConfiguration && EmergencyMode::getCurrentState() == eEmgergencyMode::normalOperation)
  {
    Logging::write(LogCategory::Configuration, Logging::CONFIG_CHANGE_REQUEST, LogSeverity::Information, makeDynAnytype()); //Configuration change requested

    dyn_mapping dmLastCfg = sLastConfiguration != "" ? jsonDecode(sLastConfiguration) : makeDynMapping();
    dyn_mapping dmNewCfg  = sNewConfiguration != "" ?  jsonDecode(sNewConfiguration)  : makeDynMapping();

    for (int i = dynlen(dmNewCfg); i > 0; i--) //translate MNSP uppercase protocol names
    {
      string sPROT = strtoupper(dmNewCfg[i][KEY_MNSP_PROTOCOL]);

      if (mappingHasKey(mMnspProtocolsToDriverNames, sPROT)) //translate mindsphere protocol names to IOT suite protocol names
      {
        dmNewCfg[i][KEY_MNSP_PROTOCOL] = mMnspProtocolsToDriverNames[sPROT];
      }

      //workaround, because mindsphere has now (changeable) device name as part of data source id
      int iPos = strpos(dmNewCfg[i][KEY_MNSP_DATASOURCE], "/");

      if (iPos > -1)
      {
        dmNewCfg[i][KEY_MNSP_DATASOURCE] = substr(dmNewCfg[i][KEY_MNSP_DATASOURCE], iPos + 1);
      }

      //remove invalid chars from device name (will be used for CNS node)
      dmNewCfg[i][KEY_ORIGINAL_NAME] = dmNewCfg[i][KEY_MNSP_NAME];
      nameCheckAndReplace(dmNewCfg[i][KEY_MNSP_NAME], NAMETYPE_DP, "_");

      if (mappingHasKey(dmNewCfg[i], KEY_MNSP_PROTOCOL_DATA) &&
          mappingHasKey(dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_NET_ID) &&
          mappingHasKey(dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_IP_ADDR) &&
          mappingHasKey(dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_PORT)) //bacnet combine IP and Port
      {
        dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA][DriverConst::IPADDRESS] = dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_BACNET_NET_ID] + ":" +
                                                                      dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_BACNET_IP_ADDR] + ":" +
                                                                      dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_BACNET_PORT];
        mappingRemove(dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_NET_ID);
        mappingRemove(dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_IP_ADDR);
        mappingRemove(dmNewCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_PORT);
      }
    }

    for (int i = dynlen(dmLastCfg); i > 0; i--) //translate MNSP uppercase protocol names
    {
      string sPROT = strtoupper(dmLastCfg[i][KEY_MNSP_PROTOCOL]);

      if (mappingHasKey(mMnspProtocolsToDriverNames, sPROT)) //translate mindsphere protocol names to IOT suite protocol names
      {
        dmLastCfg[i][KEY_MNSP_PROTOCOL] = mMnspProtocolsToDriverNames[sPROT];
      }

      //workaround, because mindsphere has now (changeable) device name as part of data source id
      int iPos = strpos(dmLastCfg[i][KEY_MNSP_DATASOURCE], "/");

      if (iPos > -1)
      {
        dmLastCfg[i][KEY_MNSP_DATASOURCE] = substr(dmLastCfg[i][KEY_MNSP_DATASOURCE], iPos + 1);
      }

      //remove invalid chars from device name (will be used for CNS node)
      dmLastCfg[i][KEY_ORIGINAL_NAME] = dmLastCfg[i][KEY_MNSP_NAME];
      nameCheckAndReplace(dmLastCfg[i][KEY_MNSP_NAME], NAMETYPE_DP, "_");

      if (mappingHasKey(dmLastCfg[i], KEY_MNSP_PROTOCOL_DATA) &&
          mappingHasKey(dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_NET_ID) &&
          mappingHasKey(dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_IP_ADDR) &&
          mappingHasKey(dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_PORT)) //bacnet combine IP and Port
      {
        dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA][DriverConst::IPADDRESS] = dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_BACNET_NET_ID] + ":" +
                                                                      dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_BACNET_IP_ADDR] + ":" +
                                                                      dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_BACNET_PORT];
        mappingRemove(dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_NET_ID);
        mappingRemove(dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_IP_ADDR);
        mappingRemove(dmLastCfg[i][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_BACNET_PORT);
      }
    }

    bInConfigurationChange = TRUE;
    int iFailure = updateWCCOA_DeviceAndTags(dmLastCfg, dmNewCfg);

    /*
    WCCOAui4:["wss"][mapping 1 items
    WCCOAui4:   "data" : dyn_mapping 7 items
    WCCOAui4:	     1: mapping 4 items
    WCCOAui4:		   "state" : 3
    WCCOAui4:		   "tagcount" : 14
    WCCOAui4:		   "devicekey" : "EdgeBox.EB_Package_S7:Node_1575449746"
    WCCOAui4:		   "name" : mapping 3 items
    WCCOAui4:			   "ru_RU.utf8" : "abcd"
    WCCOAui4:			   "de_AT.utf8" : "abcd"
    WCCOAui4:			   "en_US.utf8" : "abcd"
    */

    //     mapping mOptions = EB_WssApi::call( g_sAppIdent + ".getOptions", makeMapping("data", "deviceDetails"));
    //
    //     EB_WssApi::call("getDeviceList", makeMapping());

    //   mapping mResultDevDetail;
    //   myS7DriverApp.getDeviceDetail(makeMapping("devicekey", mDeviceList[WssConst::DATA][1]["devicekey"]), mResult);
    //   DebugN("wss dev details", mResult);

    //update mapping, because of some possible changes
    mWinccoaDpesToMnspIds = makeMapping();
    getMappingReverse(mMnspIdToWinccoaId, mWinccoaDpesToMnspIds, TRUE);
    updateDatapointGroup(mappingKeys(mWinccoaDpesToMnspIds));

    //save last configuration on DPE
    string sJson;
    getIdMappingJson(sJson);

    if (EmergencyMode::getCurrentState() == eEmgergencyMode::normalOperation)
    {
      dpSet(DPE_LAST_CONFIGURATION, sNewConfiguration,
            DPE_DATAPOINTIDMAPPING, sJson);
    }
    else
    {
      iFailure += FAILURE_EMERGENCYMODE;
    }

    tLastConfigurationChangeDeadband = getCurrentTime() + 2; //dpQuerySingle blocking time
    bInConfigurationChange = FALSE;

    if (iFailure == 0)
    {
      Logging::write(LogCategory::Configuration, Logging::CONFIG_CHANGE_SUCCESS, LogSeverity::Information, makeDynAnytype());
      Logging::clear(LogCategory::Configuration, Logging::CONFIG_CHANGE_FAILED);
    }
    else
    {
      Logging::write(LogCategory::Configuration, Logging::CONFIG_CHANGE_FAILED, LogSeverity::Information, makeDynAnytype(), "failure: "+ iFailure +" emergency mode: "+EmergencyMode::getCurrentState(), TRUE);
    }
    if (EmergencyMode::getCurrentState() == eEmgergencyMode::normalOperation)
    {
      sLastConfiguration = sNewConfiguration;
    }

    sLastConfiguration = sNewConfiguration;
  }
  else
  {
    DebugFTN(DBG_CONFIGURATION, "no configuration change, just DPE value refresh");
  }
}

/**
 * @brief Get transformation and tag type for a given address and type
 * @param sType the tag type coming from mindsphere
 * @return tag type according IOT Suite
 */
string getIotType(const string &sType)
{
  string sResult;

  switch (sType)
  {
    case "BOOLEAN":
      sResult = "BOOL";
      break;

    case "INT":
      sResult = "INT";
      break;

    case "LONG":
      sResult = "LONG";
      break;

    case "STRING":
    case "BIG_STRING":
      sResult = "STRING";
      break;

    case "TIMESTAMP":
      sResult = "TIME";
      break;

    case "UINT":             // not used in Mindsphere
    case "UNSIGNED":         // not used in Mindsphere
      sResult = "UINT";
      break;

    case "DOUBLE":
    default:
      sResult = "FLOAT";
      break;
  }

  return sResult;
}

/**
 * @brief Get transformation and tag type for a given address and type
 * @param sAddress the address comming from mindsphere
 * @param sType the tag type comming from mindsphere
 * @return transformation for the given parameters
 */
int getTransformation(const string &sProtocol, const string &sAddress, const string &sType)
{
  int iResult;

  if (mappingHasKey(myDriverApps, sProtocol))
  {
    iResult = myDriverApps[sProtocol].getTransformation(sAddress, sType);
  }

  return iResult;
}

/**
 * @brief Get an empty tag for a devicekey
 * @param mEmptyTag result
 * @param sDeviceKey device key as input
 */
private void getEmptyTag(mapping &mEmptyTag, const string &sDeviceKey)
{
  langString ls;
  mEmptyTag = makeMapping (DriverConst::NAME,                             ls,
                           DriverConst::DEVICE_KEY,                       sDeviceKey,
                           DriverConst::TAG_KEY,                          "",
                           DriverConst::DESCRIPTION,                      ls,
                           DriverConst::ADDRESS,                          "",
                           DriverConst::DATATYPE,                         "FLOAT",
                           DriverConst::POLLRATE,                         "1s",
                           DriverConst::ACTIVE,                           TRUE,
                           DriverConst::ARCHIVE,                          FALSE,
                           DriverConst::FORMAT,                           "",
                           DriverConst::UNIT,                             ls,
                           DriverConst::TRANSFORMATION,                   0,
                           DriverConst::DIRECTION,                        DPATTR_ADDR_MODE_INPUT_POLL, //??
                           DriverConst::SUBINDEX,                         0u,
                           DriverConst::LOW_LEVEL_FILTER,                 FALSE,
                           DriverConst::ALLOW_DUPLICATE_TAGNAMES,         TRUE);
/*
DriverConst::DEVICE_KEY
DriverConst::TAG_KEY
EB_mappingToLangString(mParams["data"][i][DriverConst::DESCRIPTION])
DriverConst::ADDRESS
(EBTagType) EB_getEnumValueForText("EBTagType", mParams["data"][i][DriverConst::DATATYPE])
DriverConst::POLLRATE
DriverConst::ACTIVE
DriverConst::ARCHIVE
DriverConst::FORMAT
EB_mappingToLangString(mParams["data"][i][DriverConst::UNIT])
DriverConst::TRANSFORMATION
DriverConst::DIRECTION  DPATTR_ADDR_MODE_INPUT_POLL
DriverConst::CONNECTION_ATTRIBUTES_ON_ADDRESS) ? mParams["data"][i][DriverConst::CONNECTION_ATTRIBUTES_ON_ADDRESS] : ""
mappingHasKey(mParams["data"][i], DriverConst::SUBINDEX) ? (uint)mParams["data"][i][DriverConst::SUBINDEX] : 0u);
  */
}

/**
 * @brief function synchronized old device and tags instances with requested configuration
 * @param dmOldSetting the currently used settings
 * @param dmNewSetting the new settings to be used
 * @return 0 ok, < 0 failure
 */
private int updateWCCOA_DeviceAndTags(const dyn_mapping &dmOldSetting, const dyn_mapping &dmNewSetting)
{
  dyn_string dsIdChecked;
  int iFailureAdd, iFailureUpdate;

  dyn_mapping dmDeleteForCleanup;
  bool bRequireCleanup;
  mapping mDeleteDevice;

  // delete Devices if removed
  for (int iOld = dynlen(dmOldSetting); iOld > 0; iOld--)
  {
    int iFound = 0;
    bool bUpdateTags = FALSE;
    bool bUpdateDevice = FALSE;

    if (dynContains(PROTOCOL_WHITELIST, strtoupper(dmOldSetting[iOld][KEY_MNSP_PROTOCOL])) <= 0 && !isDbgFlag(DBG_IGNORE_PROTOCOL_FILTER))
    {
      continue;
    }

    for (int iNew = dynlen(dmNewSetting); iNew > 0 && iFound == 0; iNew--)
    {
      if (dynContains(dsIdChecked, dmNewSetting[iNew][KEY_MNSP_DATASOURCE]) < 1 && //for performance optimization
          dmOldSetting[iOld][KEY_MNSP_DATASOURCE] == dmNewSetting[iNew][KEY_MNSP_DATASOURCE]) //same device
      {
        iFound = iNew;
        bool bUpdatePollrate    = dmOldSetting[iOld][KEY_MNSP_POLLRATE] != dmNewSetting[iNew][KEY_MNSP_POLLRATE];
        bool bUpdateLowLevelCmp = (mappingHasKey(dmOldSetting[iOld], KEY_MNSP_PROTOCOL_DATA) && mappingHasKey(dmOldSetting[iOld][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_ON_CHANGE) ? dmOldSetting[iOld][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_ON_CHANGE] : DEFAULT_LOW_LEVEL_CMP) !=
                                  (mappingHasKey(dmNewSetting[iNew], KEY_MNSP_PROTOCOL_DATA) && mappingHasKey(dmNewSetting[iNew][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_ON_CHANGE) ? dmNewSetting[iNew][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_ON_CHANGE] : DEFAULT_LOW_LEVEL_CMP);

        bUpdateTags = dmOldSetting[iOld][KEY_MNSP_PROTOCOL] == dmNewSetting[iNew][KEY_MNSP_PROTOCOL] &&  //different protocoll will lead to recreation of device including tags
                      (bUpdatePollrate || bUpdateLowLevelCmp || !isMappingPartEqual(dmOldSetting[iOld], dmNewSetting[iNew], KEY_MNSP_DATAPOINTS)); //pollrate change or low level comparison device setting need to update tags, or if datapoints have changed
        dynAppend(dsIdChecked, dmOldSetting[iOld][KEY_MNSP_DATASOURCE]); //for performance optimization

        if (myDriverApps[dmOldSetting[iOld][KEY_MNSP_PROTOCOL]].POLLRATE_VIA_TAG)
        {
          bUpdateDevice = !isMappingEqualExclude(dmOldSetting[iOld], dmNewSetting[iNew], makeDynString(KEY_MNSP_DATAPOINTS, KEY_MNSP_POLLRATE, KEY_MNSP_PROTOCOL_DATA + "@" + KEY_MNSP_ON_CHANGE));
        }
        else //polling is defined per device
        {
          bUpdateDevice = dmOldSetting[iOld] != dmNewSetting[iNew];
        }

        if (myDriverApps[dmOldSetting[iOld][KEY_MNSP_PROTOCOL]].isDriverRecoveryOnSourceChangeRequired())
        {
          if (mappingHasKey(dmOldSetting[iOld][KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_URL))
          {
            bRequireCleanup |= dmOldSetting[iOld][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_URL] != dmNewSetting[iNew][KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_URL];
          }

          dynAppend(dmDeleteForCleanup, dmOldSetting[iOld]);

          if (bRequireCleanup) //do not waste time
          {
            bUpdateDevice = FALSE;
            bUpdateTags = FALSE;
          }
        }
      }
    }

    if (iFound == 0) //delete Device
    {
      if (myDriverApps[dmOldSetting[iOld][KEY_MNSP_PROTOCOL]].isDriverRecoveryOnSourceChangeRequired())
      {
        bRequireCleanup = TRUE;
        mDeleteDevice[dmOldSetting[iOld][KEY_MNSP_DATASOURCE]] = TRUE;
        dynAppend(dmDeleteForCleanup, dmOldSetting[iOld]);
      }
      else
      {
        _deleteDevice(dmOldSetting[iOld]);
      }
    }
    else
    {
      if (bUpdateDevice)
      {
        iFailureUpdate += _updateDevice(dmOldSetting[iOld], dmNewSetting[iFound]);
      }

      if (bUpdateTags) //upate tags
      {
        iFailureUpdate += _updateTags(dmNewSetting[iFound]);
      }
    }
  }

  if (bRequireCleanup)
  {
    for (int i = dynlen(dmDeleteForCleanup); i > 0; i--)
    {
      _deleteDevice(dmDeleteForCleanup[i]);
    }

    //per driver/protocol run doDriverRecovery function once
    dyn_string dsUniqe;

    for (int i = dynlen(dmDeleteForCleanup); i > 0; i--)
    {
      if (dynContains(dsUniqe, dmDeleteForCleanup[i][KEY_MNSP_PROTOCOL]) < 1)
      {
        myDriverApps[dmDeleteForCleanup[i][KEY_MNSP_PROTOCOL]].doDriverRecovery();
        dynAppend(dsUniqe, dmDeleteForCleanup[i][KEY_MNSP_PROTOCOL]);
      }
    }

    for (int i = dynlen(dmDeleteForCleanup); i > 0; i--)
    {
      if (!mappingHasKey(mDeleteDevice, dmDeleteForCleanup[i][KEY_MNSP_DATASOURCE]) ||  mDeleteDevice[dmDeleteForCleanup[i][KEY_MNSP_DATASOURCE]] != TRUE)
      {
        iFailureAdd += _createDevice(dmDeleteForCleanup[i]);
      }
    }
  }

  // search for new devices
  for (int iNew = dynlen(dmNewSetting); iNew > 0; iNew--)
  {
    if (dynContains(PROTOCOL_WHITELIST, strtoupper(dmNewSetting[iNew][KEY_MNSP_PROTOCOL])) <= 0 && !isDbgFlag(DBG_IGNORE_PROTOCOL_FILTER))
    {
      DebugFTN(DBG_DEVICE, "Driver/Protocol is not supported. Unable to create device " + dmNewSetting[iNew][KEY_MNSP_NAME] + " of type: " + dmNewSetting[iNew][KEY_MNSP_PROTOCOL], PROTOCOL_WHITELIST, dynContains(PROTOCOL_WHITELIST, strtoupper(dmNewSetting[iNew][KEY_MNSP_PROTOCOL])));
      continue;
    }

    if (dynContains(dsIdChecked, dmNewSetting[iNew][KEY_MNSP_DATASOURCE]) < 1) //for performance optimization
    {
      bool bFound = FALSE;

      for (int iOld = dynlen(dmOldSetting); iOld > 0 && !bFound && dynContains(dsIdChecked, dmOldSetting[iOld][KEY_MNSP_DATASOURCE]) < 1; iOld--)
      {
        if (dmOldSetting[iOld][KEY_MNSP_DATASOURCE] == dmNewSetting[iNew][KEY_MNSP_DATASOURCE])
        {
          bFound = TRUE;
          dynAppend(dsIdChecked, dmOldSetting[iOld][KEY_MNSP_DATASOURCE]);  //for performance optimization
        }
      }

      if (!bFound) //create device and tags
      {
        iFailureAdd += _createDevice(dmNewSetting[iNew]);
      }
    }
  }

  return iFailureAdd + iFailureUpdate;
}

/**
 * @brief Creates a new device for the driver with IOT Suite conform device mapping
 * @param mDevice IOT Suite conform device mapping with new device settings
 * @return 0 ok, device created, -1 device could not be created, -2 driver is not supported
 */
private int _createDevice(const mapping &mDevice)  synchronized(mUsedProtocolsAndDevices)
{
  mapping mIn, mOut;

  getWccoaDevice(mIn, mDevice);

  //create device and call _updateTags function
  if (mappingHasKey(myDriverApps, mDevice[KEY_MNSP_PROTOCOL]))
  {
    // Save the time from field setting from the device
    if (!mappingHasKey(mDeviceTimeSettings, mDevice[KEY_MNSP_DATASOURCE]))
    {
      mDeviceTimeSettings[mDevice[KEY_MNSP_DATASOURCE]] = makeMapping();
    }

    mDeviceTimeSettings[mDevice[KEY_MNSP_DATASOURCE]][DriverConst::TIME_FROM_FIELD] = mappingHasKey(mIn, DriverConst::TIME_FROM_FIELD) ? mIn[DriverConst::TIME_FROM_FIELD] : FALSE;

    //use the given certificates
    if (mappingHasKey(mDevice, KEY_MNSP_CERTIFICATES) && dynlen(mDevice[KEY_MNSP_CERTIFICATES]) > 0)
    {
      mIn[DriverConst::CERTIFICATES] = mDevice[KEY_MNSP_CERTIFICATES];
    }

    //Download files for IEC if necessary
    if (mappingHasKey(mDevice["protocolData"], "scdFile") && mappingHasKey(mDevice["protocolData"]["scdFile"], "name"))
    {
      string sFileLocation;

      sFileLocation = downloadFile(mDevice[KEY_MNSP_PROTOCOL], "MindSphereConnector", mDevice["protocolData"]);

      if (sFileLocation != "null" && sFileLocation != "")
      {
        Logging::write(LogCategory::Configuration, Logging::CONFIG_SCDFILE_DWL_SUCC, LogSeverity::Information, makeDynAnytype(sFileLocation, mDevice[KEY_MNSP_NAME])); //Download of SCD File succeeded
        mIn["scdFile"] = sFileLocation;
      }
      else
      {
        Logging::write(LogCategory::Configuration, Logging::CONFIG_SCDFILE_DWL_FAIL, LogSeverity::Warning, makeDynAnytype(sFileLocation, mDevice[KEY_MNSP_NAME])); //Download of SCD File failed
      }
    }

    mIn[DriverConst::EXTRADATA] = mDevice[KEY_MNSP_DATASOURCE];

    myDriverApps[mDevice[KEY_MNSP_PROTOCOL]].addDevice(mIn, mOut);

    //new device for driver added, save it on mUsedProtocolsAndDevices[protocol][]
    if (!mappingHasKey(mUsedProtocolsAndDevices, mDevice[KEY_MNSP_PROTOCOL]))
    {
      mUsedProtocolsAndDevices[mDevice[KEY_MNSP_PROTOCOL]] = makeDynString(mDevice[KEY_MNSP_DATASOURCE]);
    }
    else if (dynContains(mUsedProtocolsAndDevices[mDevice[KEY_MNSP_PROTOCOL]], mDevice[KEY_MNSP_DATASOURCE]) < 1) //not added until now
    {
      dynAppend(mUsedProtocolsAndDevices[mDevice[KEY_MNSP_PROTOCOL]], mDevice[KEY_MNSP_DATASOURCE]);
    }

    if (!mappingHasKey(mOut, WssConst::DATA) || !mappingHasKey(mOut[WssConst::DATA], DriverConst::DEVICE_KEY))
    {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 54, "Unable to create device of type: " + mDevice[KEY_MNSP_PROTOCOL] + " due to missing " + (mappingHasKey(mOut, WssConst::DATA) ? "device key" : "data") + ". Data: " + mappingHasKey(mOut, WssConst::DATA) + " device key: " + (mappingHasKey(mOut, WssConst::DATA) ? mappingHasKey(mOut[WssConst::DATA], DriverConst::DEVICE_KEY) : "-?-"), mOut));
      return -1;
    }

    DebugFTN(DBG_DEVICE, "device add", mOut[WssConst::DATA][DriverConst::NAME], mOut[WssConst::DATA][DriverConst::DEVICE_KEY]);

    //save mapping of MNSP dataSourceId to WinCCOA cnsNodeId (deviceId)
    mMnspIdToWinccoaDeviceId[mDevice[KEY_MNSP_DATASOURCE]] = mOut[WssConst::DATA][DriverConst::DEVICE_KEY];

    //create MQTT communication DP for the device
    updateMnspMqttDP(mDevice[KEY_MNSP_PROTOCOL], mDevice[KEY_MNSP_DATASOURCE], mDevice[KEY_ORIGINAL_NAME]);

    //create/delete/udpate tags for the given device
    _updateTags(mDevice);
  }
  else if (dynContains(PROTOCOL_WHITELIST, mDevice[KEY_MNSP_PROTOCOL]) > 0)
  {
    throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 54, "Driver/Protocol is not supported. Unable to create device of type: " + mDevice[KEY_MNSP_PROTOCOL], mappingKeys(myDriverApps)));
    return -2;
  }

  return 0;
}

/**
 * @brief Get IOT conform device mapping from mindsphere device mapping
 * @param mWccoaDev result
 * @param mDevice mindsphere device mapping
 */
private void getWccoaDevice(mapping &mWccoaDev, mapping mDevice)
{
  dyn_string dsKeys = mappingKeys(mDevice);

  //get device default settings
  mapping mDefDev;

  if (mappingHasKey(myDriverApps, mDevice[KEY_MNSP_PROTOCOL]))
  {
    myDriverApps[mDevice[KEY_MNSP_PROTOCOL]].getDeviceMetaData(makeMapping(), mDefDev);

    mWccoaDev = mDefDev[DriverConst::DATA]["defaultDevice"];

    for (int i = dynlen(dsKeys); i > 0; i--)
    {
      if (dsKeys[i] == KEY_MNSP_PROTOCOL_DATA)
      {
        dyn_string dsSubKeys = mappingKeys(mDevice[KEY_MNSP_PROTOCOL_DATA]);

        myDriverApps[mDevice[KEY_MNSP_PROTOCOL]].convertMappingValues(mDevice[KEY_MNSP_PROTOCOL_DATA]);

        for (int j = dynlen(dsSubKeys); j > 0; j--)
        {
          mWccoaDev[getMindsphereToIotMappingKey(dsSubKeys[j])] = mDevice[KEY_MNSP_PROTOCOL_DATA][dsSubKeys[j]];
        }
      }
      else if (dsKeys[i] == KEY_MNSP_PROTOCOL)
      {
        // Do nothing, expect for preventing an 'Index out of range' error
      }
      else if (dsKeys[i] != KEY_MNSP_DATAPOINTS)
      {
        mWccoaDev[getMindsphereToIotMappingKey(dsKeys[i])] = mDevice[dsKeys[i]];
      }
    }
  }
}

/**
 * @brief delete a device
 * @param mDevice mindsphere conform device
 */
private void _deleteDevice(const mapping &mDevice) synchronized(mUsedProtocolsAndDevices)
{
  mapping mIn, mOut;

  if (mappingHasKey(mMnspIdToWinccoaDeviceId, mDevice[KEY_MNSP_DATASOURCE]))
  {
    mIn[DriverConst::DEVICE_KEY] = mMnspIdToWinccoaDeviceId[mDevice[KEY_MNSP_DATASOURCE]];
    mIn[DriverConst::EXTRADATA]   = mDevice[KEY_MNSP_DATASOURCE];
    //remove tags for the device
    mapping mDeviceWithoutTags = mDevice;

    if (mappingHasKey(mDeviceWithoutTags, KEY_MNSP_DATAPOINTS))
    {
      mDeviceWithoutTags[KEY_MNSP_DATAPOINTS] = makeDynMapping();
    }

    //delete all tags
    _updateTags(mDeviceWithoutTags);

    //delete device
    if (mappingHasKey(myDriverApps, mDevice[KEY_MNSP_PROTOCOL]))
    {
      myDriverApps[mDevice[KEY_MNSP_PROTOCOL]].deleteDevice(mIn, mOut);

      if (mappingHasKey(mUsedProtocolsAndDevices, mDevice[KEY_MNSP_PROTOCOL]))
      {
        int iPos = dynContains(mUsedProtocolsAndDevices[mDevice[KEY_MNSP_PROTOCOL]], mDevice[KEY_MNSP_DATASOURCE]);

        if (iPos > 0)
        {
          dynRemove(mUsedProtocolsAndDevices[mDevice[KEY_MNSP_PROTOCOL]], iPos);
        }
      }
    }

    DebugFTN(DBG_DEVICE, "device delete", mIn, mOut);

    //delete device MQTT mindsphere communication DP
    deleteMnspMqttDP(mDevice[KEY_MNSP_DATASOURCE]);

    //remove mapping entry
    mappingRemove(mMnspIdToWinccoaDeviceId, mDevice[KEY_MNSP_DATASOURCE]);

    if (mappingHasKey(mDeviceTimeSettings, mDevice[KEY_MNSP_DATASOURCE]))
    {
      mappingRemove(mDeviceTimeSettings, mDevice[KEY_MNSP_DATASOURCE]);
    }
  }
}

/**
 * @brief update device settings
 * @param mOldDevice old mindsphere device
 * @param mNewDevice new mindsphere device
 * @return 0 ok, device created, -1 device could not be created, -2 driver is not supported
 */
private int _updateDevice(const mapping &mOldDevice, const mapping &mNewDevice)
{
  int iRet;

  //protocoll change -> delete devices and create new device
  if (mOldDevice[KEY_MNSP_PROTOCOL] != mNewDevice[KEY_MNSP_PROTOCOL])
  {
    _deleteDevice(mOldDevice);
    iRet = _createDevice(mNewDevice);
  }
  else if (mappingHasKey(myDriverApps, mNewDevice[KEY_MNSP_PROTOCOL]))
  {
    mapping mIn, mOut;

    getWccoaDevice(mIn, mNewDevice);

    DebugFTN(DBG_DEVICE, "device update", mNewDevice, KEY_MNSP_DATASOURCE, mIn, "old:", mOldDevice, "new:", mNewDevice);

    // Save the time from field setting from the device
    if (!mappingHasKey(mDeviceTimeSettings, mNewDevice[KEY_MNSP_DATASOURCE]))
    {
      mDeviceTimeSettings[mNewDevice[KEY_MNSP_DATASOURCE]] = makeMapping();
    }

    mDeviceTimeSettings[mNewDevice[KEY_MNSP_DATASOURCE]][DriverConst::TIME_FROM_FIELD] = mappingHasKey(mIn, DriverConst::TIME_FROM_FIELD) ? mIn[DriverConst::TIME_FROM_FIELD] : FALSE;

    if (mappingHasKey(mNewDevice, KEY_MNSP_CERTIFICATES) && dynlen(mNewDevice[KEY_MNSP_CERTIFICATES]) > 0)
    {
      mIn[DriverConst::CERTIFICATES] = mDevice[KEY_MNSP_CERTIFICATES];
    }

    //Download files for IEC if necessary
    if (mappingHasKey(mNewDevice["protocolData"], "scdFile") && mNewDevice["protocolData"]["scdFile"] != mOldDevice["protocolData"]["scdFile"])
    {
      string sFileLocation;

      sFileLocation = downloadFile(mNewDevice[KEY_MNSP_PROTOCOL], "MindSphereConnector", mNewDevice["protocolData"]);

      if (sFileLocation != "null" && sFileLocation != "")
      {
        Logging::write(LogCategory::Configuration, Logging::CONFIG_SCDFILE_DWL_SUCC, LogSeverity::Information, makeDynAnytype(sFileLocation, mNewDevice[KEY_MNSP_NAME])); //Download of SCD File succeeded
        mIn["scdFile"] = sFileLocation;
      }
      else
      {
        Logging::write(LogCategory::Configuration, Logging::CONFIG_SCDFILE_DWL_FAIL, LogSeverity::Warning, makeDynAnytype(sFileLocation, mNewDevice[KEY_MNSP_NAME])); //Download of SCD File failed
      }
    }

    mIn[DriverConst::EXTRADATA] = mOldDevice[KEY_MNSP_DATASOURCE];
    mIn[DriverConst::DEVICE_KEY] = mMnspIdToWinccoaDeviceId[mNewDevice[KEY_MNSP_DATASOURCE]];

    if (mOldDevice[DriverConst::NAME] != mNewDevice[DriverConst::NAME])
    {
      //update MQTT communication DP for the device, because device name is part of MQTT topic
      updateMnspMqttDP(mNewDevice[KEY_MNSP_PROTOCOL], mNewDevice[KEY_MNSP_DATASOURCE], mNewDevice[KEY_ORIGINAL_NAME]);
    }

    myDriverApps[mNewDevice[KEY_MNSP_PROTOCOL]].modifyDevice(mIn, mOut);

    DebugFTN(DBG_DEVICE, "device updated", mOut[WssConst::DATA][DriverConst::NAME], mOut[WssConst::DATA][DriverConst::DEVICE_KEY]);
  }
  else if (dynContains(PROTOCOL_WHITELIST, mNewDevice[KEY_MNSP_PROTOCOL]) > 0)
  {
    throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 54, "Unable to modify device of type: " + mNewDevice[KEY_MNSP_PROTOCOL], mappingKeys(myDriverApps)));
    iRet = -2;
  }

  return iRet;
}

/**
 * @brief update/create/delete tags in WinCC OA for given device, including pollgroup creation
 * @param mDevice mindesphere device
 * @return 0 ok, -1 tags could not be updated successfully
 */
private int _updateTags(const mapping &mDevice) synchronized(bConfiurationUpdateLock)
{
  //prepare tag list call modifyTags function
  string sType, sAddress, sTransformationType;
  string sDirection;
  bool bLowLevelFilter;
  float fHysteresisAbsolut;
  int iTransformation;
  dyn_uint duPollRates = makeDynUInt(1000 * (float)mDevice[KEY_MNSP_POLLRATE]);

  mapping mIn, mOut;
  mIn[WssConst::DATA] = makeDynMapping();

  bool bDeviceLowLevelFilter = (mappingHasKey(mDevice, KEY_MNSP_PROTOCOL_DATA) && mappingHasKey(mDevice[KEY_MNSP_PROTOCOL_DATA], KEY_MNSP_ON_CHANGE)) ? mDevice[KEY_MNSP_PROTOCOL_DATA][KEY_MNSP_ON_CHANGE] : DEFAULT_LOW_LEVEL_CMP;

  for (int i = dynlen(mDevice[KEY_MNSP_DATAPOINTS]); i > 0; i--)
  {
    uint uPollRate, uSubIndex;
    mapping mTag;

    getEmptyTag(mTag, mMnspIdToWinccoaDeviceId[mDevice[KEY_MNSP_DATASOURCE]]);

    dyn_string dsKeys = mappingKeys(mDevice[KEY_MNSP_DATAPOINTS][i]);

    for (int j = dynlen(dsKeys); j > 0; j--)
    {
      if (dsKeys[j] == KEY_MNSP_DP_DATA)
      {
        sAddress            = mappingHasKey(mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA], KEY_MNSP_ADDRESS)   ?  mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA][KEY_MNSP_ADDRESS]   : "";
        sDirection          = mappingHasKey(mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA], KEY_MNSP_DIRECTION) ?  mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA][KEY_MNSP_DIRECTION] : "";
        bLowLevelFilter     = mappingHasKey(mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA], KEY_MNSP_ON_CHANGE) ?  mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA][KEY_MNSP_ON_CHANGE] : bDeviceLowLevelFilter;
        fHysteresisAbsolut  = mappingHasKey(mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA], KEY_MNSP_HYSTERESIS) ?  mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA][KEY_MNSP_HYSTERESIS] : 0.0;
        uPollRate           = 1000 * (float)(mappingHasKey(mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA], KEY_MNSP_POLLRATE)  ?  mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA][KEY_MNSP_POLLRATE]  : mDevice[KEY_MNSP_POLLRATE]);
        sTransformationType = mappingHasKey(mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA], KEY_MNSP_TRANSFORMATION) ?  mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA][KEY_MNSP_TRANSFORMATION] : mTag[DriverConst::DATATYPE];
        uSubIndex           = mappingHasKey(mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA], KEY_MNSP_SUBINDEX)  ?  mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA][KEY_MNSP_SUBINDEX]  : mTag[DriverConst::SUBINDEX];

        // Check if this tag/datapoint has the optional 'time from field' setting
        if (mappingHasKey(mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA], KEY_MNSP_TIME_FROM_FIELD))
        {
          if (!mappingHasKey(mDeviceTimeSettings, mDevice[KEY_MNSP_DATASOURCE]))
          {
            mDeviceTimeSettings[mDevice[KEY_MNSP_DATASOURCE]] = makeMapping();
          }

          // Save the time from field setting from the tag
          mDeviceTimeSettings[mDevice[KEY_MNSP_DATASOURCE]][mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DATAPOINTID]] = mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DP_DATA][KEY_MNSP_TIME_FROM_FIELD];
        }
        // Check if an old setting must be removed
        else if (mappingHasKey(mDeviceTimeSettings, mDevice[KEY_MNSP_DATASOURCE]) && mappingHasKey(mDeviceTimeSettings[mDevice[KEY_MNSP_DATASOURCE]], mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DATAPOINTID]))
        {
          mappingRemove(mDeviceTimeSettings[mDevice[KEY_MNSP_DATASOURCE]], mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DATAPOINTID]);
        }
      }
      else if (dsKeys[j] == KEY_MNSP_DATATYPE)
      {
        sType = mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DATATYPE];
      }
      else //copy field to WinCC OA mapping for modifyTags function
      {
        if (dsKeys[j] == KEY_MNSP_NAME) //use lang sting (required for comparison in driver app modifyTags function to check if name has been changed)
        {
          langString ls;
          EB_setMultilingualText(mDevice[KEY_MNSP_DATAPOINTS][i][dsKeys[j]], ls);
          mTag[getMindsphereToIotMappingKey(dsKeys[j])] = ls;
        }
        else
        {
          mTag[getMindsphereToIotMappingKey(dsKeys[j])] = mDevice[KEY_MNSP_DATAPOINTS][i][dsKeys[j]];
        }
      }
    }

    mTag[DriverConst::ADDRESS]            = sAddress;
    mTag[DriverConst::DIRECTION]          = getDirectionFromString(sDirection);
    mTag[DriverConst::DATATYPE]           = getIotType(sType);
    mTag[DriverConst::TRANSFORMATION]     = getTransformation(mDevice[KEY_MNSP_PROTOCOL], sAddress, sTransformationType);
    mTag[DriverConst::POLLRATE]           = uPollRate + "ms";
    mTag[DriverConst::EXTRADATA]          = mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DATAPOINTID];
    mTag[DriverConst::LOW_LEVEL_FILTER]   = bLowLevelFilter;
    mTag[DriverConst::SMOOTHING_ABSOLUTE] = fHysteresisAbsolut;
    mTag[DriverConst::SUBINDEX]           = uSubIndex;

    if (mappingHasKey(mMnspIdToWinccoaId, mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DATAPOINTID]))  //on delete or modify - adding has no CNS ;-)
    {
      mTag[DriverConst::TAG_KEY] = mMnspIdToWinccoaId[ mDevice[KEY_MNSP_DATAPOINTS][i][KEY_MNSP_DATAPOINTID] ];
    }

    dynAppend(mIn[WssConst::DATA], mTag);
    dynAppend(duPollRates, uPollRate);
  }

  dynSort(duPollRates);
  dynUnique(duPollRates);

  for (int i = 1; i <= dynlen(duPollRates); i++)
  {
    if (!dpExists("_" + duPollRates[i] + "ms"))
    {
      dpCreate("_" + duPollRates[i] + "ms", "_PollGroup");
      dpSetWait("_" + duPollRates[i] + "ms" + ".PollInterval", duPollRates[i],
                "_" + duPollRates[i] + "ms" + ".Active", TRUE);
    }
  }

  if (dynlen(mIn[WssConst::DATA]) < 1 && mappingHasKey(mMnspIdToWinccoaDeviceId, mDevice[KEY_MNSP_DATASOURCE])) //delete all tags -> need device KEY
  {
    mIn[WssConst::DATA][1] = makeMapping(DriverConst::DEVICE_KEY, mMnspIdToWinccoaDeviceId[mDevice[KEY_MNSP_DATASOURCE]]);
  }

  mIn[WssConst::DATA][1][DriverConst::OPTION_DELETEOBSOLETETAGS] = TRUE; //modifyTags function will delete tags, which are not in new list

  if (mappingHasKey(myDriverApps, mDevice[KEY_MNSP_PROTOCOL]))
  {
    myDriverApps[mDevice[KEY_MNSP_PROTOCOL]].modifyTags(mIn, mOut);

    DebugFTN(DBG_TAG, "tag configuration modified", mIn, mOut);

    //update MNSP id to Tag mapping
    if (mappingHasKey(mOut[WssConst::DATA], "del"))
    {
      for (int i = dynlen(mOut[WssConst::DATA]["del"]); i > 0; i--)
      {
        removeTagFromIdMappings(mOut[WssConst::DATA]["del"][i][DriverConst::TAG_KEY]);

        // Remove the time setting of this removed tag
        if (mappingHasKey(mDeviceTimeSettings, mDevice[KEY_MNSP_DATASOURCE]) && mappingHasKey(mDeviceTimeSettings[mDevice[KEY_MNSP_DATASOURCE]], mOut[WssConst::DATA]["del"][i][DriverConst::TAG_KEY]))
        {
          mappingRemove(mDeviceTimeSettings[mDevice[KEY_MNSP_DATASOURCE]], mOut[WssConst::DATA]["del"][i][DriverConst::TAG_KEY]);
        }
      }
    }

    if (mappingHasKey(mOut[WssConst::DATA], "add"))
    {
      for (int i = dynlen(mOut[WssConst::DATA]["add"]); i > 0; i--)
      {
        if (mappingHasKey(mOut[WssConst::DATA]["add"][i], DriverConst::EXTRADATA) && mappingHasKey(mOut[WssConst::DATA]["add"][i], DriverConst::TAG_KEY))
        {
          addTagToIdMappings(mDevice[KEY_MNSP_DATASOURCE], mOut[WssConst::DATA]["add"][i][DriverConst::EXTRADATA], mOut[WssConst::DATA]["add"][i][DriverConst::TAG_KEY]);
        }
      }

      updateDriverConnectionStateForNewTag(mOut[DriverConst::DATA]["add"]);
    }
  }

  return 0; //toDo return -1 on failure
}

/**
 * @brief Converts the MindSphere direction string into a WinCC OA address direction value
 * @param sDirection    MindSphere direction string to convert
 * @return Direction value
 */
private int getDirectionFromString(const string &sDirection)
{
  int iResult;

  switch (sDirection)
  {

    case "WRITE":      iResult = DPATTR_ADDR_MODE_IO_SQUERY;  break;  // Fall through because the transition bit is needed to determine if the write has been executed (successfully)

    case "READ&WRITE": iResult = DPATTR_ADDR_MODE_IO_POLL;    break;

    case "READ":
    default:
      iResult = DPATTR_ADDR_MODE_INPUT_POLL; break;
  }

  return iResult;
}

/**
 * @brief add/update mapping mWinccoaDpToMnspId and mWinccoaDpToMnspDeviceId
 * @param sMnspDeviceId mindsphere devcie id
 * @param sMnspId mindssphere DPE id
 * @param sTagId WinCC OA tag id
 * @param sDPE WinCC OA datapoint element of the tag
 */
private void addTagToIdMappings(const string &sMnspDeviceId, const string &sMnspId, const string &sTagId, string sDPE = "")
{
  mMnspIdToWinccoaId[sMnspId] = sTagId;

  if (sDPE == "")
  {
    cnsGetId(sTagId, sDPE);
  }

  mWinccoaDpToMnspId[sDPE] = sMnspId;
  mWinccoaDpToMnspDeviceId[sDPE] = sMnspDeviceId;
}

/**
 * @brief Removes the tag from mapping variables
 * @param sTagId
 */
private void removeTagFromIdMappings(const string &sTagId)
{
  string sMnspId = mappingGetKeyByValue(mMnspIdToWinccoaId, sTagId);

  mappingRemove(mMnspIdToWinccoaId, sMnspId);

  string sDPE = mappingGetKeyByValue(mWinccoaDpToMnspId, sMnspId);

  mappingRemove(mWinccoaDpToMnspId,       sDPE);
  mappingRemove(mWinccoaDpToMnspDeviceId, sDPE);
}

/**
 * @brief Get mindsphere to WinCC OA id mapping in for of json string for storing on DPE
 * @param sJson result
 */
private getIdMappingJson(string &sJson)
{
  sJson = jsonEncode(makeDynMapping(mMnspIdToWinccoaId,
                                    mWinccoaDpToMnspId,
                                    mWinccoaDpToMnspDeviceId,
                                    mDeviceIdMqttDp,
                                    mMnspIdToWinccoaDeviceId,
                                    mDeviceTimeSettings,
                                    mUsedProtocolsAndDevices));
}

/**
 * @brief from given mapping json, fill the mindsphere to WinCC OA id mppings
 * @param sJson
 */
private void fillIdMappingFromJson(const string &sJson)
{
  dyn_mapping dm = jsonDecode(sJson);

  mMnspIdToWinccoaId       = dm[1]; // datapoint id in mnsp to tag id
  mWinccoaDpToMnspId       = dm[2]; // DPE to datapoind id in mnsp
  mWinccoaDpToMnspDeviceId = dm[3]; // DPE to device id in mnsp
  mDeviceIdMqttDp          = dm[4]; // device id to wincc oa MQTT DP
  mMnspIdToWinccoaDeviceId = dm[5]; // device id in mnsp to tag id
  mDeviceTimeSettings      = dm[6]; // Time from field settings
  mUsedProtocolsAndDevices = dm[7]; // list of protcols and it device IDs

  getMappingReverse(mMnspIdToWinccoaId, mWinccoaDpesToMnspIds, TRUE);
}

/**
 * @brief function to get the ("last") mapping key for a given mapping value
 * @param m mapping to be searched within
 * @param aValue the value to be searched
 * @return the key related to the value
 */
string mappingGetKeyByValue(const mapping &m, const anytype &aValue)
{
  string sResult;

  for (int i = mappinglen(m); i > 0 && sResult == ""; i--)
  {
    if (mappingGetValue(m, i) == aValue)
    {
      sResult = mappingGetKey(m, i);
    }
  }

  return sResult;
}

/**
 * @brief Compares two mapping values with a given key
 * @param m1   mapping one
 * @param m2   mapping two
 * @param sKey root node key to start comparision
 * @return
 */
bool isMappingPartEqual(const mapping &m1, const mapping &m2, const string &sKey)
{
  bool b1 = mappingHasKey(m1, sKey), b2 = mappingHasKey(m2, sKey);

  if (!b1 || !b2)
  {
    return b1 == b2;
  }

  return m1[sKey] == m2[sKey];
}

/**
 * @brief Compare two mappings, but ignore a set of keys to be compared
 * @param m1            mapping one
 * @param m2            mapping two
 * @param dsExcludeKeys list of keys to be ignored for comparison; two level key can be separated by "@"
 * @return true if the mapping are equal (but exclude the exclusion key list)
 */
bool isMappingEqualExclude(mapping m1, mapping m2, const dyn_string &dsExcludeKeys)
{
  for (int i = dynlen(dsExcludeKeys); i > 0; i--)
  {
    dyn_string dsSplit = strsplit(dsExcludeKeys[i], "@");

    if (dynlen(dsSplit) > 1)
    {
      if (mappingHasKey(m1[dsSplit[1]], dsSplit[2]))
      {
        mappingRemove(m1[dsSplit[1]], dsSplit[2]);
      }

      if (mappingHasKey(m2[dsSplit[1]], dsSplit[2]))
      {
        mappingRemove(m2[dsSplit[1]], dsSplit[2]);
      }
    }
    else
    {
      if (mappingHasKey(m1, dsExcludeKeys[i]))
      {
        mappingRemove(m1, dsExcludeKeys[i]);
      }

      if (mappingHasKey(m2, dsExcludeKeys[i]))
      {
        mappingRemove(m2, dsExcludeKeys[i]);
      }
    }
  }

  return m1 == m2;
}

/**
 * @brief work function for query connect to send value changes to mindspere
 * @param aUserData user data (not used)
 * @param ddaTab    value changes and timestamps of value changes
 */
void sendDataToMNSP(const anytype &aUserData, const dyn_dyn_anytype &ddaTab)
{
  //tansfer query result into "key", "value", "state", "time", "dpe"
//   mapping mData = TagStateCallBack::getData(mDummy, ddaTab);

  DebugFTN(DBG_VALUEUPDATE, "send values to mindsphere", dynlen(ddaTab) - 1/*, ddaTab, mData*/);

  mapping mTimes;
  dyn_time dtOrderedTimestamps;

  int iLen = dynlen(ddaTab);

  mapping mSet;  // key1: mqttDP, key2: sTimestamp
  time tTimestamp = getCurrentTime();

  string sLastMQTTDP;
  string sLastDeviceId;
  time tLastTimeStamp;
  bool bTimeFromField = FALSE;

  dyn_string dsDpeSQ;
  dyn_string dsSqAvoidRepeat;

  for (int i = 2; i <= iLen; i++)
  {
    //formatDebug(dpid) -> "System1:EB_Int0032. (Type: 234 Sys: 1 Dp: 15205 El: 1 : 0..0)" or if can not convert to dp name "(Type: 234 Sys: 1 Dp: 15205 El: 1 : 0..0)"
    if (((bInConfigurationChange || tLastConfigurationChangeDeadband > tTimestamp) && strpos(formatDebug(ddaTab[i][INDEX_DPE]), "(") == 0) || !dpExists(ddaTab[i][INDEX_DPE]))    //to avoid failure at moment of deleting the DPs
    {
      continue;
    }

    string sDPE = dpSubStr(ddaTab[i][INDEX_DPE], DPSUB_SYS_DP_EL);

    if (!mappingHasKey(mWinccoaDpToMnspDeviceId, sDPE)) //during configuration change, DPE could be removed already
    {
      continue;
    }

    if ((int) ddaTab[i][INDEX_MANID] == iMyManId) //_manager != own manager - remove value changes done by own manager to filter out from timeseries
    {
      if (!(bool)ddaTab[i][INDEX_DISCON])
      {
        doRequestSingleQuery(dsDpeSQ, dsSqAvoidRepeat, mDummy, ddaTab[i], sDPE);
      }

      continue;
    }

    string sDeviceId = mWinccoaDpToMnspDeviceId[sDPE];
    string sMQTTDP   = mDeviceIdMqttDp[sDeviceId];

    // Determine the time from field setting for this tag
    if (sLastDeviceId != sDeviceId)
    {
      sLastDeviceId = sDeviceId;

      if (mappingHasKey(mDeviceTimeSettings, sDeviceId))
      {
        bTimeFromField = mappingHasKey(mDeviceTimeSettings[sDeviceId], mWinccoaDpToMnspId[sDPE]) ? mDeviceTimeSettings[sDeviceId][mWinccoaDpToMnspId[sDPE]] :  mDeviceTimeSettings[sDeviceId][DriverConst::TIME_FROM_FIELD];

        // Check if the time from the field (driver/PLC) must be used
        if (bTimeFromField)
        {
          tTimestamp = (time)ddaTab[i][INDEX_STIME];
        }
      }
      else
      {
        bTimeFromField = FALSE;
      }
    }

    if (dynContains(dtOrderedTimestamps, tTimestamp) < 1)
    {
      dynAppend(dtOrderedTimestamps, tTimestamp);
    }

    if (sLastMQTTDP != sMQTTDP)
    {
      sLastMQTTDP = sMQTTDP;

      if (!mappingHasKey(mSet, sMQTTDP))
      {
        mSet[sMQTTDP] = makeMapping();// makeDynMapping(makeMapping("timestamp",sTimestamp), "values", makeDynMapping()));
      }
    }

    if (tLastTimeStamp != tTimestamp)
    {
      tLastTimeStamp = tTimestamp;

      if (!mappingHasKey(mSet[sMQTTDP], tTimestamp))
      {
        mSet[sMQTTDP][tTimestamp] = makeDynMapping();
      }
    }

    // collect for each timestamp the values, quality
      // please take care adding new drivers - quality values from driver should be activated and mapped according to Driverapp.ctl

      dynAppend(mSet[sMQTTDP][tTimestamp], makeMapping("qualityCode", getQualityInteger(ddaTab[i], bTimeFromField), "value", ddaTab[i][INDEX_VAL],
                                                     KEY_MNSP_DATAPOINTID, mWinccoaDpToMnspId[sDPE]));
    if (!(bool)ddaTab[i][INDEX_DISCON])
    {
      doRequestSingleQuery(dsDpeSQ, dsSqAvoidRepeat, mDummy, ddaTab[i], sDPE);
    }
  }

  //for each device (mqtt dp)
  for (int i = mappinglen(mSet); i > 0; i--)
  {
    dyn_mapping dmSetting;

    for (int j = 1; j <= dynlen(dtOrderedTimestamps); j++)
    {
      if (mappingHasKey(mSet[mappingGetKey(mSet, i)], dtOrderedTimestamps[j]))
      {
        dynAppend(dmSetting, makeMapping("timestamp", dtOrderedTimestamps[j], "values", mSet[mappingGetKey(mSet, i)][ dtOrderedTimestamps[j] ]));
      }
    }

    //per device, via MQTT, send the value time serie to mindsphere
    string sJson = jsonEncode(dmSetting);
    dpSet(mappingGetKey(mSet, i) + ".Data", sJson);

    DebugFTN(DBG_VALUEUPDATE, "sent value time serie to mindsphere", mappingGetKey(mSet, i), jsonEncode(dmSetting));
  }

  //MQTT topic: cloud/controlling/command/S7PLUS/DATA_POINT_WRITE/V_1_0
  /* example:
     1: mapping 2 items
     "values" : dyn_anytype 2 items
  	     1: mapping 3 items
  		   "qualityCode" : 0
  		   "value" : 90
  		   "dataPointId" : "dae87da4f4af4"
  	     2: mapping 3 items
  		   "qualityCode" : 0
  		   "value" : 90
  		   "dataPointId" : "d87a6f8dc4e04"
     "timestamp" : "2020-12-23T15:13:23.968Z"
     2: mapping 2 items
     "values" : dyn_anytype 2 items
  	     1: mapping 3 items
  		   "qualityCode" : 0
  		   "value" : 91
  		   "dataPointId" : "dae87da4f4af4"
  	     2: mapping 3 items
  		   "qualityCode" : 0
  		   "value" : 91
  		   "dataPointId" : "d87a6f8dc4e04"
     "timestamp" : "2020-12-23T15:13:24.968Z"

  {
  "commandId": "2b4381cb-9a2a-4a34-87dc-3ba48950cfdd",
  "createdAt": "2021-04-27T06:55:42.981Z",
  "data": {
    "type": "datapoint-write",
    "to": "S7",
    "version": "v1.0",
    "payload": {
      "desiredValue": "2",
      "dataSourceId": "76381057-b272-48b8-9dbb-c904cb103c9d",
      "dataPointId": "423acbb6f7514",
      "protocol": "S7"
    }
  }
  }
  */
}

/**
 * @brief check if single query is required and trigger SQ on driver
 * @param dsDpeSQ list of DPEs marked for SQ already
 * @param dsSqAvoidRepeat list of DPEs marked for SQ already
 * @param UserData                     user data mapping
 *         mUserData["dpes"]           data point elements
 *         mUserData["keys"]           keys
 *         mUserData["DRIVER_NUMBER"]  driver number
 * @param daTab one row of query result table
 * @param sDpe dapapoint element to be checked
 */
void doRequestSingleQuery(dyn_string &dsDpeSQ, dyn_string &dsSqAvoidRepeat, const mapping &mUserData, const dyn_anytype &daTab, const string &sDpe)
{
  //do single query if required, to get a first value for the tag

  if (!(bool)daTab[INDEX_DISCON] && dynContains(dsDpeSQ, sDpe) < 1)
  {
    dynAppend(dsDpeSQ, sDpe); //avoid multiple single query request for same DPE

    // if address not checked yet -> check; if value comes from SQ -> update ok bit; if ok bit ok -> show value
    if ((!(bool)daTab[INDEX_ADDCHECKED] || !(bool)daTab[INDEX_ADDOK])  /* && spTag.getAddress() != ""*/)
    {
      int iDriverNr;

      if (mappingHasKey(mUserData, "DRIVER_NUMBER"))
      {
        iDriverNr = mUserData["DRIVER_NUMBER"];
      }
      else
      {
        iDriverNr = TagStateCallBack::getDriverNumberFromDPE(sDpe);
      }

      int iAvoidSqRepeatIndex = dynContains(dsSqAvoidRepeat, sDpe);

      if (iAvoidSqRepeatIndex > 0)
      {
        dynRemove(dsSqAvoidRepeat, iAvoidSqRepeatIndex);
      }
      else if (iDriverNr > 0)
      {
        if (!(bool)daTab[INDEX_ADDCHECKED]) //!bAddressChecked - to avoid infinite loop
        {
          dpSet("_Driver" + iDriverNr + ".SQ", sDpe,
                sDpe + GenericDriverTag::ADDRESS_CHECK_BIT, TRUE);
        }
        else
        {
          dpSet("_Driver" + iDriverNr + ".SQ", sDpe);
        }

        DebugFTN(DriverConst::DEBUG_DEVICE, "tag validation via single query triggered", sDpe);
        dynAppend(dsSqAvoidRepeat, sDpe);
      }
    }

    if (!(bool)daTab[INDEX_ADDOK] && (bool)daTab[INDEX_FROMSQ]) //!bAddressOk && from single query  _from_SI
    {
      dpSet(sDpe + GenericDriverTag::ADDRESS_OK_BIT, TRUE);
    }
  }
}

/**
 * @brief work function for query connect to receive commands from mindspere
 * @param aUserData user data (not used)
 * @param ddaTab    value
 */
void writeCommandFromMNSP(const anytype &aUserData, const dyn_dyn_anytype &ddaTab)
{
  DebugFTN(DBG_COMMAND, __FUNCTION__ + "(..., ...) dynlen: " + dynlen(ddaTab), aUserData, ddaTab);

  for (int i = 2; i <= dynlen(ddaTab); i++)
  {
    if (ddaTab[i][2] != "")
    {
      string  sDp      = dpSubStr(ddaTab[i][1], DPSUB_DP);
      mapping mCommand = jsonDecode(ddaTab[i][2]);
      DebugFTN(DBG_COMMAND, "received", mCommand, "mDeviceIdMqttDp", mDeviceIdMqttDp);

      if (isDbgFlag(DBG_COMMAND) || eCurrentLogLevel == eLogLevel::DEBUG || eCurrentLogLevel == eLogLevel::TRACE)
      {
        Logging::write(LogCategory::Runtime, Logging::COMMAND_VALUE_RECEIVED, LogSeverity::Information,
                       makeDynString(mCommand["commandId"], (mappingHasKey(mCommand, "data") && mappingHasKey(mCommand["data"], "payload") && mappingHasKey(mCommand["data"]["payload"], "protocol") ? mCommand["data"]["payload"]["protocol"] : "")));
      }

      if (mappingHasKey(mCommand, "commandId") &&
          mappingHasKey(mCommand, "data") &&
          mappingHasKey(mCommand["data"], "to") &&
          mappingHasKey(mCommand["data"], "payload") &&
          mappingHasKey(mCommand["data"]["payload"], "desiredValue") &&
          (mappingHasKey(mCommand["data"]["payload"], "protocol") || mappingHasKey(mCommand["data"]["payload"], "to")) &&
          mappingHasKey(mCommand["data"]["payload"], "dataPointId") &&
          mappingHasKey(mCommand["data"]["payload"], "dataSourceId"))
      {
        dyn_string dsDataSourceSplit = strsplit(mCommand["data"]["payload"]["dataSourceId"], "/"); //use only id without device name
        string sDataSourceId = dsDataSourceSplit[dynlen(dsDataSourceSplit)];

        if (mDeviceIdMqttDp[sDataSourceId] == sDp) // Only execute write commands for our device
        {
          string sProtocol = mappingHasKey(mCommand["data"]["payload"], "protocol") ? mCommand["data"]["payload"]["protocol"] : mappingHasKey(mCommand["data"]["payload"], "to");

          DebugFTN(DBG_COMMAND, "Command value received for protocol " + sProtocol + " > " + mCommand, mDeviceIdMqttDp[sDataSourceId], mCommand["data"]["payload"]["dataPointId"]);
          string sDpeToWrite;
          cnsGetId(mMnspIdToWinccoaId[mCommand["data"]["payload"]["dataPointId"]], sDpeToWrite);
          Logging::write(LogCategory::Runtime, Logging::CMD_VAL_RECEIVED_BY_APP, LogSeverity::Information, makeDynString(sProtocol, mCommand["data"]["payload"]["dataPointId"] + " (" + sDpeToWrite + ")", mCommand["data"]["payload"]["desiredValue"], mCommand["commandId"], mCommand["createdAt"]), "", FALSE, myDriverApps[mMnspProtocolsToDriverNames[sProtocol]].logGetManagerKey());

          startThread("threadWriteCommand", mCommand["data"]["payload"]["dataPointId"],
                                            sDpeToWrite,
                                            mCommand["data"]["payload"]["desiredValue"],
                                            sProtocol,
                                            mCommand["commandId"]);
        }
      }
    }
  }
}

/**
 * @brief Executes the write command and checks its result
 * @param sMindsphereDpId   DPE to write
 * @param sDpeToWrite       DPE to write
 * @param aValue            Value to write
 * @param sProtocol         protocol name in upper case like "MTCONNECT"
 * @param sCommandId        Id of the command
 */
void threadWriteCommand(const string &sMindsphereDpId, const string &sDpeToWrite, mixed mValue, const string &sProtocol, const string &sCommandId)
{
  /* result on topic runtime/controlling/commandUpdate
    {
      "commandId": "12f3f77e-ec5e-43a8-bacb-f69101c41938",
      "commandType": "datapoint-write",
      "commandVersion": "v1",
      "from": "S7PLUS",
      "message": "Command executed successfully. (<VALUE>)", //free text will be displayed in the UI (max 150 chars)
      "state": "EXECUTING",  // "EXECUTING" "EXECUTED" "FAILED"
      "progress": 0.75, //used for “EXECUTING” or send 1 for EXECUTED
    }
    */
  //for boolean accept only 1 and every spelling of true as true

  if (dpElementType(sDpeToWrite) == DPEL_BOOL)
  {
    if (strtoupper(mValue) == "TRUE" || mValue == 1)
    {
      mValue = (bool) TRUE;
    }
    else
    {
      mValue = (bool) FALSE;
    }
  }


  mapping mResponse = makeMapping("commandId", sCommandId,
                                  "commandType", "datapoint-write",
                                  "commandVersion", "v1",
                                  "from", sProtocol, //S7PLUS or...
                                  "message", "Command received by connector. (" + mValue + ")",
                                  "state", "EXECUTING",
                                  "progress", 0,
                                  "details", makeMapping("value", (string) mValue));

  dyn_anytype daValues;
  bool bExpired;

  DebugFTN(DBG_COMMAND, __FUNCTION__ + "(" + sDpeToWrite + ", ..., " + sProtocol + ", " + sCommandId + ") value:", mValue);

  startThread("readValueOnce", sDpeToWrite); //trigger read value in 0,5 sec, because otherwise timeout could be larger than poll cylce

//wait for next SQ value chang (requested by readValueOnce thread)
  int iRet = dpSetAndWaitForValue(makeDynString(sDpeToWrite, DPE_COMMANDRESPONSE + ":_original.._value"), makeDynAnytype(mValue, jsonEncode(mResponse)),
                                  makeDynString(sDpeToWrite + ":_original.._from_SI"), makeDynAnytype(TRUE),
                                  makeDynString(sDpeToWrite + ":_original.._aut_inv", sDpeToWrite + ":_online.._value"), daValues, TIMEOUT_COMMAND, bExpired);

  DebugFTN(DBG_COMMAND, __FUNCTION__ + "(" + sDpeToWrite + ", ..., " + sProtocol + ", " + sCommandId + ") waited for SQ result:", mValue, daValues, bExpired);

  int iCode = bExpired || daValues[1] ? -1 : 0;

  anytype aSentValue;

  if (iCode == 0)
  {
    aSentValue = daValues[2]; //to get correct type
    aSentValue = mValue;
  }

  if ((iCode == 0 && daValues[2] == aSentValue) ||
      ((iCode == 0 && dpElementType(sDpeToWrite) == DPEL_FLOAT) && fabs(daValues[2]) <= fabs(aSentValue * UPPER_FLOAT_THRESHOLD) && fabs(daValues[2]) >= fabs(aSentValue * LOWER_FLOAT_THRESHOLD))) //scuccess :-)
  {
    mResponse["state"]    = "EXECUTED";
    mResponse["message"]  = "Command executed successfully. (" + mValue + ")";
    mResponse["progress"] = 1;

    Logging::write(LogCategory::Runtime, Logging::CMD_VAL_SUCCESS, LogSeverity::Information, makeDynString(sProtocol, sMindsphereDpId + " (" + sDpeToWrite + ")", mValue, sCommandId), "", FALSE, myDriverApps[mMnspProtocolsToDriverNames[sProtocol]].logGetManagerKey());
  }
  else //failure
  {
    mResponse["state"]    = "FAILED";
    mResponse["message"]  = iCode != 0 ? "Command execution failure. (" + mValue + ")" : "Command value not accepted (" + mValue + ")";
    mResponse["progress"] = 0;
    Logging::write(LogCategory::Runtime, Logging::CMD_VAL_FAILED, LogSeverity::Error, makeDynString(sProtocol, sMindsphereDpId + " ("+sDpeToWrite+")", mValue, daValues, sCommandId) , "", FALSE, myDriverApps[mMnspProtocolsToDriverNames[sProtocol]].logGetManagerKey());
  }

  DebugFTN(DBG_COMMAND, __FUNCTION__ + "(" + sDpeToWrite + ", ..., " + sProtocol + ", " + sCommandId + ") quality code: " + iCode + " expired: " + bExpired + (bExpired || dynlen(daValues) < 1 ? "" : " bad: " + daValues[1] + " command value received: " + aSentValue + " device value: " + daValues[2]));

  dpSet(DPE_COMMANDRESPONSE, jsonEncode(mResponse));
}

/**
 * @brief Returns the command result message for the specified quality code
 * @param iCode Quality code to get the text for
 * @return Human readable text of the quality code
 */
string getWriteMessage(int iCode)
{
  return iCode == 0 ? "OK" : "NOK";
}

/**
 * @brief Callback function for the browse requests from MindSphere
 * @param aUserData user data (not used)
 * @param ddaTab    value
 */
void browseCB(const anytype &aUserData, const dyn_dyn_anytype &ddaTab)
{
  /*
  {
    "commandId": "12f3f77e-ec5e-43a8-bacb-f69101c41938",
    "createdAt": "2020-01-01T12:00:00Z",
    "data": {
      "payload": {   //new sub node
        "datasourceId": "71de4797-70a7-74c7-7dc7-77a75d0e61c7",
        "encodings": [
          "plain",
          "gzip"
        ],
        "filePrefix": "/someMsPath/IotFolderName"
      }
    }
  }
  */

  DebugFTN(DBG_BROWSE, __FUNCTION__ + "(..., ...) dynlen: " + dynlen(ddaTab), aUserData, ddaTab, mDeviceIdMqttDp, mMnspIdToWinccoaDeviceId);

  for (int i = 2; i <= dynlen(ddaTab); i++)
  {
    if (ddaTab[i][2] != "") //no data -> ignore
    {
      DebugFTN(DBG_BROWSE, "browsing request from mindsphere", ddaTab[i][2]);
      startThread("threadBrowse", dpSubStr(ddaTab[i][1], DPSUB_DP), jsonDecode(ddaTab[i][2]), isAnswer());
    }
  }
}

/**
 * @brief Returns the CNS view name from a CNS node
 * @param sNodeId  CNS node id to get the CNS view name from
 * @return CNS view name
 */
string getCnsViewName(const string &sNodeId)
{
  langString lsResult;

  cnsGetViewDisplayNames(sNodeId, lsResult);

  return lsResult;
}

void threadBrowse(string sDp, mapping mData, bool bCancelLastUnfinishedBrowsing)
{
  string sCommandId    = mData["commandId"];
  string sDataSourceId = mData["data"]["payload"]["datasourceId"]; //mappingGetKeyByValue(mDeviceIdMqttDp, sDp);
  string sDeviceId;

  for (int i = 1; i < BROWSING_FILEUPLOAD_TIMEOUT && sDeviceId == ""; i++)
  {
    if (i > 1) //do not wait for first check
    {
      delay(1);
    }

    sDeviceId = mappingHasKey(mMnspIdToWinccoaDeviceId, sDataSourceId) ? mMnspIdToWinccoaDeviceId[sDataSourceId] : "";
  }

  if (sDeviceId != "")
  {
    string sProtocol        = getCnsViewName(sDeviceId);
    string sFilter          = mappingHasKey(mData["data"]["payload"], "filter") ? mData["data"]["payload"]["filter"] : "";
    int    iStart           = mappingHasKey(mData["data"]["payload"], "start")  ? mData["data"]["payload"]["start"]  : 1;
    int    iCount           = mappingHasKey(mData["data"]["payload"], "count")  ? mData["data"]["payload"]["count"]  : 0; // unlimited: <= 0
    string sParent          = mappingHasKey(mData["data"]["payload"], "parent") ? mData["data"]["payload"]["parent"] : "";
    string sFilePrefix      = mappingHasKey(mData["data"]["payload"], "filePrefix") ? mData["data"]["payload"]["filePrefix"] : DATA_PATH + "browse/" + sProtocol + "/";

    if (!patternMatch("*/", sFilePrefix)) //missing '/' at the end
    {
      sFilePrefix += "/";
    }

    bool bZip               = mappingHasKey(mData["data"]["payload"], "encodings") ? (mData["data"]["payload"]["encodings"] == "gzip") : FALSE;
    bool bBrowseAllSubNodes = mappingHasKey(mData["data"]["payload"], "browseall") ? mData["data"]["payload"]["browseall"] : FALSE;

    DebugFTN(DBG_BROWSE, __FUNCTION__ + "(..., ...) commandId: " + sCommandId + " dp: " + sDp + " id: " + sDataSourceId + " device: " + sDeviceId + " protocol: " + sProtocol);

    eEmgergencyMode eEmMode = EmergencyMode::getCurrentState();
    if (eEmMode != eEmgergencyMode::normalOperation/* || bCancelLastUnfinishedBrowsing*/)
    {
      /*
      if (bCancelLastUnfinishedBrowsing) // after project restart giver driver time before writing to MQTT broker
      {
        delay(2);
        string sFileName = "emptyBrowsing.json";
        string sFilePath = getBrowsingFolder() + sFileName;

        if (!isfile(sFilePath))
        {
          file f = fopen(sFilePath, "w");

          if (f != 0)
          {
            string sJson = jsonEncode(
                                      makeMapping("nodes",
                                                  makeDynAnytype(makeMapping("id",1, "type", "HIERARCHY", "name", "browsing not sucessfully -> aborted"))));
            int iBytes = fputs("[]", f);
            fclose(f);
          }
        }
        //{"replyTo":"WINCCOA","localPath":"/persistent_massdata/appData/browsing/BACnet_3c7b1e87-f67b-4287-bdd9-520ecf14e3db_bn1.json","id":"mnspConnect_11638","iotFilePath":"browsingdataFolder/WINCCOA/2024-05-15T08:01:12.031944337Z/BACnet_3c7b1e87-f67b-4287-bdd9-520ecf14e3db_bn1.json","encoding":"plain"}
        mapping mEmptyResult = makeMapping("replyTo","WINCCOA",
                                           "localPath",sFilePath,
                                           "id", "mnspConnect_"+rand(),
                                           "iotFilePath", sFilePrefix + sFileName,
                                           "encoding", "plain");
        dpSet(DPE_FILE_UPLOAD_REQUEST_BY_WCCOA, jsonEncode(mEmptyResult));

        DebugTN("empty browsing result file created", mEmptyResult);
      }
      */
      //browsing not possible
      float fCompletion = 1.0; // browsing is finished - but failed
      writeCommandResponse(sCommandId, "generate-browsing-data", "v1", "WINCCOA", "EMERGENCY MODE (" + eEmMode + ") - browse device '"+ sDeviceId +"' of protocol '"+ sProtocol +"' not possible to start", eCommandState::FAILED, fCompletion, makeMapping(), Logging::DEVICE_BROWSE_FAILED, sDeviceId);
      DebugFTN(DBG_BROWSE, __FUNCTION__ + "(" + sCommandId +",...) - Failure EMERGENCY MODE - before browsing started -> browsing not started", bCancelLastUnfinishedBrowsing);
      return;
    }
    if (bCancelLastUnfinishedBrowsing)
    {
      delay(10); //on system startup wait to have driver package loaded
    }
    browseDevice(sCommandId, sProtocol, sDeviceId, sDataSourceId, sFilter, iStart, iCount, sParent, sFilePrefix, bZip, bBrowseAllSubNodes, bCancelLastUnfinishedBrowsing);

    eEmMode = EmergencyMode::getCurrentState();
    if (eEmMode != eEmgergencyMode::normalOperation)
    {
      //browsing not possible
      float fCompletion = 1.0; // browsing is finished - but failed
      writeCommandResponse(sCommandId, "generate-browsing-data", "v1", "WINCCOA", "EMERGENCY MODE (" + eEmMode + ") - browse device '"+ sDeviceId +"' of protocol '"+ sProtocol +"' was not successful", eCommandState::FAILED, fCompletion, makeMapping(), Logging::DEVICE_BROWSE_FAILED, sDeviceId);
      DebugFTN(DBG_BROWSE, __FUNCTION__ + "(" + sCommandId +",...) - Failure EMERGENCY MODE - before browsing started -> canceled browsing");
      return;
    }
  }
}

/**
 * @brief Executes the browse request and returns its result
 * @param sCommandId:             command id comes from mindsphere
 * @param sProtocol               Driver to use
 * @param sDeviceNode             cns node of the device to browse
 * @param sFilter                 Address filter, only items matches this filter are returned
 * @param iStart                  Index of the first element
 * @param iCount                  Maximum number of elements to return
 * @param sParent                 parent start node
 * @param sFilePrefix             mindpshere file prefix (is folder information for mindsphere)
 * @param bBrowseAllSubNodes      brows all sub nodes, or just first level
 */
void browseDevice(const string &sCommandId, const string &sProtocol, const string &sDeviceNode, const string &sDataSourceId, const string &sFilter, int iStart, int iCount, const string &sParent, const string &sFilePrefix, bool bZip = FALSE, bool bBrowseAllSubNodes = TRUE, bool bCancelBrowsing = FALSE)
{
  string sCommandType = "generate-browsing-data";
  string sPLC, sVersion = "v1", sFrom = "WINCCOA";
  float fCompletion;
  mapping mDetails;

  writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "'", eCommandState::EXECUTING, fCompletion, mDetails, Logging::DEVICE_BROWSE_REQUEST, sDeviceNode);
  DebugFTN(DBG_BROWSE, __FUNCTION__ + "1(" + sCommandId + ", " + sProtocol + ", " + sDeviceNode + ", " + sFilter + ", " + iStart + ", " + iCount + ", " + sParent + ", " + sFilePrefix + ", " + bZip + ", " + bBrowseAllSubNodes + ")");
  int iFailure;

  DebugFTN(DBG_BROWSE, __FUNCTION__ + "2(" + sCommandId + ", " + sProtocol + ", " + sDeviceNode + ", " + sFilter + ", " + iStart + ", " + iCount + ", " + sParent + ", " + sFilePrefix + ", " + bZip + ", " + bBrowseAllSubNodes + ")");

  bool bProtocolSupportsBrowsing;

  if (mappingHasKey(myDriverApps, sProtocol) && myDriverApps[sProtocol].BROWSE_DPE_REQUEST != "")
  {
    bProtocolSupportsBrowsing = TRUE;
    langString lsName;

    cnsGetDisplayNames(sDeviceNode, lsName);

    mapping mBrowsingResult = makeMapping("nodes", makeDynMapping());

    if (bCancelBrowsing)
    {
      mBrowsingResult["nodes"] = makeMapping("id",1, "type", "HIERARCHY", "name", "browsing not sucessfully -> aborted");
    }
    else
    {
      mBrowsingResult["nodes"] = myDriverApps[sProtocol].getBrowseTree(sDeviceNode, sFilter, iStart, iCount, sParent, bBrowseAllSubNodes);
    }

    bool bFileCreated;
    string sFileName;
    string sLocalPath;

    if (dynlen(mBrowsingResult["nodes"]) > 0) //check if browsing has been successfully
    {
      fCompletion = 0.5; //50%
      dyn_string dsParameters = makeDynString(dynlen(mBrowsingResult["nodes"]));
      writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "'", eCommandState::EXECUTING, fCompletion, mDetails, Logging::DEVICE_BROWSE_PROGRESS, sDeviceNode,
                           LogCategory::Runtime, LogSeverity::Information, dsParameters);

      if (!bCancelBrowsing)
      {
        convertBrowseResultForMindsphere(mBrowsingResult["nodes"]);
      }

      fCompletion = 0.6; //60%
      writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "'", eCommandState::EXECUTING, fCompletion, mDetails);

      string sJson = jsonEncode(mBrowsingResult);

      string sJsonFileName = sProtocol + "_" + sDataSourceId + "_" + (string)lsName + ".json";

      sFileName =     sProtocol + "_" + sDataSourceId + "_" + (string)lsName + (bZip ? ".zip" : ".json");

      sLocalPath =    BROWSING_FOLDER + sFileName;

      DebugFTN(DBG_BROWSE, __FUNCTION__ + "(" + sCommandId + "...) start to create file " + sLocalPath);


      if (bZip) //zip, if requested
      {
        fCompletion = 0.7; //70%
        int iOk = gzwrite(BROWSING_FOLDER + sJsonFileName, sJson);

        if (iOk == 0)
        {
          int iBytes = getFileSize(BROWSING_FOLDER + sJsonFileName + ".gz");

          writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "' zip file created (" + iBytes + ")", eCommandState::EXECUTING, fCompletion, mDetails);
          DebugFTN(DBG_BROWSE, __FUNCTION__ + "(" + sProtocol + ", " + sDeviceNode + ", " + sFilter + ", " + iStart + ", " + iCount + ") zip file created " + iBytes + " bytes in file: " + sLocalPath + ".zip from: " + strlen(sJson));

          //rename *.json.gz to *.zip
          int iRet = rename(BROWSING_FOLDER + sJsonFileName + ".gz", BROWSING_FOLDER + sFileName);

          if (iRet == 0)
          {
            fCompletion = 0.8; //80%
            writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "' zip file renamed", eCommandState::EXECUTING, fCompletion, mDetails);

            mDetails["encoding"] = "gzip";
            mDetails["iotFilePath"] = sFilePrefix + sFileName;
            bFileCreated = TRUE;
          }
          else
          {
            bFileCreated = FALSE;
          }
        }
        else
        {
          bFileCreated = FALSE;
        }
      }
      else
      {
        file f = fopen(BROWSING_FOLDER + sFileName, "w");

        if (f != 0)
        {
          int iBytes = fputs(sJson, f);
          fclose(f);
          DebugFTN(DBG_BROWSE, __FUNCTION__ + "(" + sProtocol + ", " + sDeviceNode + ", " + sFilter + ", " + iStart + ", " + iCount + ") json file created " + iBytes + " bytes in file: " + sFileName + " from: " + strlen(sJson));

          mDetails["encoding"] = "plain";
          mDetails["iotFilePath"] = sFilePrefix + sFileName;
          bFileCreated = TRUE;
        }
        else
        {
          bFileCreated = FALSE;
        }
      }
    }

    if (bFileCreated)
    {
      string sReqId = "mnspConnect_" + rand();
      mDetails["id"] = sReqId;
      mDetails["localPath"] = sLocalPath;
      mDetails["replyTo"]   = "WINCCOA";

      mapping mExpectedResponse = makeMapping("requestId", sReqId,
                                              "status", "SUCCEEDED",
                                              "localPath", mDetails["localPath"]);

      fCompletion = 0.9; //90%
      writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "'", eCommandState::EXECUTING, fCompletion, mDetails);

      //inform mindsphere to take the file and wait until it has been uploaded to MS

      DebugFTN(DBG_BROWSE, "browsing expect respone by mindsphere, that file has been uploaded", DPE_FILE_UPLOAD_RESPONSE_BY_MNSP + ":_original.._value", jsonEncode(mExpectedResponse));

      bool bTimeout;
      dyn_anytype daVals;
      string sExpectedRsponse = jsonEncode(mExpectedResponse);

      for (int i = 10; i > 0; i--)
      {
        if (i == 10)
        {
          dpSetAndWaitForValue(makeDynString(DPE_FILE_UPLOAD_REQUEST_BY_WCCOA), makeDynAnytype(jsonEncode(mDetails)),
                               makeDynString(DPE_FILE_UPLOAD_RESPONSE_BY_MNSP + ":_original.._value_changed"), makeDynAnytype(), makeDynString(DPE_FILE_UPLOAD_RESPONSE_BY_MNSP + ":_original.._value"), daVals, BROWSING_FILEUPLOAD_TIMEOUT / 10, bTimeout);
        }
        else
        {
          dpWaitForValue(makeDynString(DPE_FILE_UPLOAD_RESPONSE_BY_MNSP + ":_original.._value_changed"), makeDynAnytype(), makeDynString(DPE_FILE_UPLOAD_RESPONSE_BY_MNSP + ":_original.._value"), daVals, BROWSING_FILEUPLOAD_TIMEOUT / 10, bTimeout);
        }

        string sRespJson;

        if (bTimeout)
        {
          string sRespJson;
          dpGet(DPE_FILE_UPLOAD_RESPONSE_BY_MNSP, sRespJson);
        }
        else if (dynlen(daVals) > 0)
        {
          sRespJson = daVals[1];
        }

        mapping mRes = jsonDecode(sRespJson);

        if (mappingHasKey(mRes, "requestId") && mRes["requestId"] == sReqId ||
            mappingHasKey(mRes, "status") && mRes["status"] == "SUCCEEDED" && mappingHasKey(mRes, "localPath") && mRes["localPath"] == mDetails["localPath"])
        {
          i = -1; //end loop
        }
      }

      if (!bTimeout)
      {
        DebugFTN(DBG_BROWSE, "browsing result file has been uploaded to mindsphere, we delete it locally (" + !isDbgFlag(DBG_BROWSE_KEEP_FILE) + ")", mDetails["localPath"]);

        if (!isDbgFlag(DBG_BROWSE_KEEP_FILE)) //by default, delete file after upload success
        {
          system("rm " + mDetails["localPath"]);
        }

        fCompletion = 1; //100%
        writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "'", eCommandState::EXECUTED, fCompletion, mDetails, Logging::DEVICE_BROWSE_SUCCESS, sDeviceNode);
      }
      else
      {
        writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "' browsing result file has not been uploaded by Mindsphere", eCommandState::FAILED, fCompletion, makeMapping(), Logging::DEVICE_BROWSE_FAILED, sDeviceNode);
        iFailure = -3;
        DebugFTN(DBG_BROWSE, __FUNCTION__ + "(" + sCommandId + ",...) - Failure 3 browsing result file has not been uploaded by Mindsphere '" + sProtocol + "' driver available: " + mappingHasKey(myDriverApps, sProtocol) + " browsing DPE: " + myDriverApps[sProtocol].BROWSE_DPE_REQUEST);
      }
    }
    else
    {
      fCompletion = 1.0; // browsing is finished - but failed
      writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "' export file could not be created", eCommandState::FAILED, fCompletion, makeMapping(), Logging::DEVICE_BROWSE_FAILED, sDeviceNode);
      iFailure = -1;
      DebugFTN(DBG_BROWSE, __FUNCTION__ + "(" + sCommandId + ",...) - Failure 1 cannot open file " + sLocalPath + ".json", BROWSING_FOLDER, sFileName);
    }
  }
  else
  {
    bProtocolSupportsBrowsing = FALSE;
  }

  if (fCompletion < 1.0) //problem - browsing not possible for this protocol
  {
    fCompletion = 1.0; // browsing is finished - but failed
    writeCommandResponse(sCommandId, sCommandType, sVersion, sFrom, "browse device '" + sPLC + "' of protocol '" + sProtocol + "'  is not possible, protocol supports browsing = " + bProtocolSupportsBrowsing, eCommandState::FAILED, fCompletion, makeMapping(), Logging::DEVICE_BROWSE_FAILED, sDeviceNode);
    iFailure = -2;
    DebugFTN(DBG_BROWSE, __FUNCTION__ + "(" + sCommandId + ",...) - Failure 2 missing browsing function for protocol '" + sProtocol + "' driver available: " + mappingHasKey(myDriverApps, sProtocol) + " browsing DPE: " + myDriverApps[sProtocol].BROWSE_DPE_REQUEST);
  }
}

/**
 * @brief Write command response and (optionally) log message
 * @param sCommandId        command id comes from mindsphere
 * @param sCommandType      type of command (defined by mindsphere) e.g. "generate-browsing-data" or "datapoint-write"
 * @param sCommandVersion   version as known by Mindsphere e.g. "v1"
 * @param sFrom             part of response topic e.g. WINCCOA or S7PLUS
 * @param sMessage          message text
 * @param eCmdState         current eCommandState
 * @param fProgress         finish state from 0.0 to 1.0
 * @param mDetails          message detail information
 * @param sLoggingKey       create a log entry with possilby given log key
 * @param sDeviceNode       cns device node to complete log entry
 * @param eLogCat           LogCategory e.g. LogCategory::Runtime
 * @param eLogServ          LogSeverity e.g. LogSeverity::Information
 * @param dsAddLogParams    additional log parameters (starting from $4 og log messages of _error.cat)
 */
writeCommandResponse(const string &sCommandId, const string &sCommandType, const string &sCommandVersion, const string &sFrom, const string &sMessage, const eCommandState &eCmdState,
                     float fProgress = 0.0, const mapping &mDetails, string sLoggingKey = "", string sDeviceNode = "", LogCategory eLogCat = LogCategory::Runtime, LogSeverity eLogServ = LogSeverity::Information,
                     dyn_string dsAddLogParams = makeDynString())
{
  mapping mEnum = enumValues("eCommandState");
  string sState;

  for (int i = mappinglen(mEnum); i > 0 && sState == ""; i--)
  {
    if (mappingGetValue(mEnum, i) == (int) eCmdState)
    {
      sState = mappingGetKey(mEnum, i);
      break;
    }
  }

  mapping mResponse = makeMapping("commandId", sCommandId,
                                  "commandType", sCommandType,
                                  "commandVersion", sCommandVersion,
                                  "from", sFrom, //S7PLUS or... WINCCOA
                                  "message", sMessage, //"Command received by connector. (" + mValue + ")",
                                  "state", sState,//"EXECUTING","FAILED","EXECUTED"
                                  "progress", fProgress == 1.0 ? 1 : (fProgress == 0.0 ? 0 : fProgress), //convert to int if possible
                                  "details", mDetails);
  dpSet(DPE_COMMANDRESPONSE, jsonEncode(mResponse));

  if (sLoggingKey != "")
  {
    string sDeviceId;

    for (int i = mappinglen(mMnspIdToWinccoaDeviceId); i > 0; i--)
    {
      if (mappingGetValue(mMnspIdToWinccoaDeviceId, i) == sDeviceNode)
      {
        sDeviceId = mappingGetKey(mMnspIdToWinccoaDeviceId, i);
        i = 0;
      }
    }


    langString lsDevice;
    langString lsView;

    cnsGetDisplayNames(sDeviceNode, lsDevice);
    string sView = cnsSubStr(sDeviceNode, CNSSUB_SYS | CNSSUB_VIEW, FALSE);
    cnsGetViewDisplayNames(sView, lsView);

    dyn_string dsParams = makeDynString((string)lsView, (string)lsDevice, sDeviceId);
    dynAppend(dsParams, dsAddLogParams);


    Logging::write(eLogCat, sLoggingKey, eLogServ, dsParams, sDeviceId, FALSE, mManagerViews[sView].logGetManagerKey());
  }
}

/**
 * @brief function for converting complete IOT browsing result to mindpshere format
 * @param dmBrowseResult   the complete browsing entries, which will be converted to mindsphere format
 */
public convertBrowseResultForMindsphere(dyn_mapping &dmBrowseResult)
{
  int iLen = dynlen(dmBrowseResult);

  int iLastId = 0;
  mapping mIds = makeMapping();

  for (int i = 1; i <= iLen; i++)
  {
    convertBrowesEntryForMindsphere(dmBrowseResult[i], iLastId, mIds);
  }
}

/**
 * @brief function for converting one IOT browsing result entry to mindpshere format
 * @param mBrowseEntry   one browsing entry, which will be modified to mindsphere format
 */
private convertBrowesEntryForMindsphere(mapping &mBrowseEntry, int &iLastId, mapping &mIds)
{
  /* in
    "address": "ModbusServer_DB_2",
    "children": {},
    "extras": "",
    "name": "ModbusServer_DB_2",
    "tagtype": "NONE",
    "type": 6
  */
  /* out
    "id": "<id of this node>", //generated by MNSP_Connect/WinCCOA/ETM
    "parentId": "<parent_of_this_node>"
    "type": "<type of the node>", // HIERARCHY | DATA
    "name": "<name_of_the_node>"
    "data": {
        "name": "<name_of_datapoint>",
        "description":"<description_of_datapoint>",
        "type": "DOUBLE | INT ...", //MS types
        "unit": "<unit>",                           //is not available, so we remove that element
        "dataPointData": {
          "acquisitionType":"READ&WRITE",           //OPC UA -> access modes
          "address": "MSC_SRV01CTRL/ATCC1$MX$CtlV$mag$f4",
          "typeTransformation": "FLOAT32"
        }
      }
    */


  mapping mNewEntry;

  mNewEntry["id"] = (string)(++iLastId);

  string sParentName = mBrowseEntry["name"];
  string sNodeName = mBrowseEntry["name"];
  int iPos = sParentName.lastIndexOf(".");
  int iParentId = 0;

  if (iPos > -1) //"." found
  {
    sParentName = substr(sParentName, 0, iPos);

    if (mappingHasKey(mIds, sParentName))
      iParentId = mIds[sParentName];

    sNodeName = substr(sNodeName, iPos + 1);
  }

  mIds[mBrowseEntry["name"]] = iLastId;

  if (iParentId != 0)
  {
    // do not set parent id of root element (not supported by MS)
    mNewEntry["parentId"] = (string)iParentId;
  }

  mNewEntry["type"] = (mBrowseEntry["type"] == (int)EBTagType::NONE) ? "HIERARCHY" : "DATA";
  mNewEntry["name"] = sNodeName; //for tree display, only own node name is required

  if (mBrowseEntry["type"] != (int)EBTagType::NONE) //not a structure
  {
    mapping mData;
    mData["name"] = sNodeName;
    mData["description"] = mBrowseEntry["extras"];
    mData["type"] = getMnspTypeFromTagType(mBrowseEntry["type"]);

    if (sBrowsingDefaultUnit != "")
    {
      mData["unit"] = sBrowsingDefaultUnit; //because unit does not come from PLC, but Mindshphere needs some unit
    }

    mapping mDatapointData;
    mDatapointData["acquisitionType"]    = mBrowseEntry["writeable"] ? "READ&WRITE" : "READ"; //only in OPC UA we can use AccessLevels DPE to differ
    mDatapointData["address"]            = mBrowseEntry["address"];

    if (mappingHasKey(mBrowseEntry, "transformation"))
    {
      mDatapointData["typeTransformation"] = mBrowseEntry["transformation"]; //type from browsing result
    }

    mData["dataPointData"] = mDatapointData;
    mNewEntry["data"] = mData;
  }

  if (iParentId == 0 && mappingHasKey(mBrowseEntry, "extras") && mBrowseEntry["extras"] != "")
  {
    mNewEntry["name"] += " - " + mBrowseEntry["extras"];
  }

  mBrowseEntry = mNewEntry;
}

/**
 * @brief get mindsphere datapoint type string from iot tag type number
 * @param iTagType   tag typ as integer
 * @return mindsphere dataoint type as string
 */
private string getMnspTypeFromTagType(int iTagType)
{
  if (!globalExists("mTagTypeNumberToMnspType"))
  {
    mapping mTagTypesToInt = enumValues("EBTagType");
    addGlobal("mTagTypeNumberToMnspType", MAPPING_VAR);

    for (int i = 1; i <= mappinglen(mTagTypesToInt); i++)
    {
      string sType;

      switch (mappingGetKey(mTagTypesToInt, i)) //BOOL, INT, ...
      {
        case "BOOL":   sType = "BOOLEAN"; break;

        case "INT":    sType = "INT"; break;

        case "LONG":   sType = "LONG"; break;

        case "STRING": sType = "STRING"; break;

        case "TIME":   sType = "STRING"; /* "TIMESTAMP" */ break; //as long as mindsphere does not support time stamp type

        case "UINT":   sType = "INT"; break;

        case "ULONG":  sType = "LONG"; break;

        default: //"FLOAT"
          sType = "DOUBLE"; break;
          break;
      }

      mTagTypeNumberToMnspType[mappingGetValue(mTagTypesToInt, i)] = sType;
    }
  }

  return mTagTypeNumberToMnspType[iTagType];
}


/**
 * @brief Get reverse mapping - key becomes value and value becomes key
 * @param mIn
 * @param mOut
 * @param bConvertCnsToDpe optional switch to use DPE names instead of (cns) tag names
 */
void getMappingReverse(const mapping &mIn, mapping &mOut, bool bConvertCnsToDpe = FALSE)
{
  for (int i = mappinglen(mIn); i > 0; i--)
  {
    if (!bConvertCnsToDpe)
    {
      mOut[mappingGetValue(mIn, i)] = mIn[mappingGetKey(mIn, i)];
    }
    else
    {
      string sDpe;
      cnsGetId(mappingGetValue(mIn, i), sDpe);
      mOut[sDpe] = mIn[mappingGetKey(mIn, i)];
    }
  }

//  DebugN(__FUNCTION__, mIn, mOut);
}

/**
 * @brief update/create WinCC OA datapoint group containing tag DPEs
 * @param dsDPEs the new tag dpe list
 * @return dpGroup datapoint
 */
private string updateDatapointGroup(const dyn_string &dsDPEs)
{
  string sDpGroupDp = groupNameToDpName(DPGROUP_SEND_VALUES_TO_MNSP);
  dyn_string dsGroupTypes;
  dyn_string dsGroupDPEs;

  //datapoint group does not exist
  if (sDpGroupDp == "")
  {
    int iError;
    langString lsGroupName;

    EB_setMultilingualText(DPGROUP_SEND_VALUES_TO_MNSP, lsGroupName);

    groupCreate(lsGroupName, FALSE, sDpGroupDp, FALSE, iError);
  }
  else
  {
    dpGet(sDpGroupDp + ".Types", dsGroupTypes,
          sDpGroupDp + ".Dps",   dsGroupDPEs);
  }

  if (dsDPEs != dsGroupDPEs)
  {
    //reset types
    dynClear(dsGroupTypes);

    //set all array elements to empty string, by setting last element to ""
    if (dynlen(dsDPEs) > 0)
    {
      dsGroupTypes[dynlen(dsDPEs)] = "";
    }

    dpSetWait(sDpGroupDp + ".Types", dsGroupTypes,
              sDpGroupDp + ".Dps",   dsDPEs);
  }

  return sDpGroupDp;
}

/**
 * @brief Remove mindsphere device DP for communication via MQTT to mindsphere
 * @param sDeviceId the device id
 */
void deleteMnspMqttDP(const string &sDeviceId)
{
  if (mappingHasKey(mDeviceIdMqttDp, sDeviceId))
  {
    if (dpExists(mDeviceIdMqttDp[sDeviceId]))
    {
      dpDelete(mDeviceIdMqttDp[sDeviceId]);
    }

    mappingRemove(mDeviceIdMqttDp, sDeviceId);
  }
}

/**
 * @brief create or update mindsphere device DP for communication via MQTT to mindsphere
 * @param sProtocol   the protocol/driver
 * @param sDeviceId   the device id
 * @param sDeviceName name of device
 */
void updateMnspMqttDP(string sProtocol, const string &sDeviceId, const string &sDeviceName)
{
  sProtocol = strtoupper(sProtocol); //Mindsphere will use all protocol names upper case
  string sDP;
  dyn_string dsDPs = dpNames(MQTT_DEVICE_COMMUNICATION_DPT + "_*", MQTT_DEVICE_COMMUNICATION_DPT);

  if (!mappingHasKey(mDeviceIdMqttDp, sDeviceId))
  {
    string sSystem = getSystemName();

    for (int i = 1; i <= dynlen(dsDPs) + 1 && sDP == ""; i++)
    {
      if (dynContains(dsDPs, sSystem + MQTT_DEVICE_COMMUNICATION_DPT + "_" + i) < 1)
      {
        sDP = MQTT_DEVICE_COMMUNICATION_DPT + "_" + i;
      }
    }

    mDeviceIdMqttDp[sDeviceId] = sDP;
    DebugFTN(DBG_DEVICE, "createDevice DP", dsDPs, sDP, sSystem, sDeviceId);
    int iRet = dpCreate(sDP, MQTT_DEVICE_COMMUNICATION_DPT);
    delay(0, 100);
  }
  else
  {
    sDP = mDeviceIdMqttDp[sDeviceId];
    //prepare for topic change
    dpSetTimed(0, sDP + ".Command:_address.._active",           FALSE,
               sDP + ".Data:_address.._active",              FALSE,
               sDP + ".Diag:_address.._active",              FALSE);
  }

  langString ls;
  EB_setMultilingualText(sDeviceName, ls);
  dpSetDescription(sDP + ".", ls);
  dpSetTimedWait(0, sDP + ".Command:_distrib.._type",             DPCONFIG_DISTRIBUTION_INFO,
                 sDP + ".Command:_distrib.._driver",           9,
                 sDP + ".Command:_address.._type",             DPCONFIG_PERIPH_ADDR_MAIN,
                 sDP + ".Command:_address.._reference",        "cloud/controlling/command/" + sProtocol + "/datapoint-write/v1.0",
                 sDP + ".Command:_address.._connection",       MINDSPHERE_CONNECTION_DP,
                 sDP + ".Command:_address.._direction",        DPATTR_ADDR_MODE_INPUT_SPONT,
                 sDP + ".Command:_address.._datatype",         1001,
                 sDP + ".Command:_address.._drv_ident",        "MQTT",
                 sDP + ".Command:_address.._active",           TRUE,
                 sDP + ".Data:_distrib.._type",                DPCONFIG_DISTRIBUTION_INFO,
                 sDP + ".Data:_distrib.._driver",              9,
                 sDP + ".Data:_address.._type",                DPCONFIG_PERIPH_ADDR_MAIN,
                 sDP + ".Data:_address.._reference",           "runtime/inject/data/timeseries/" + sProtocol + "/" + sDeviceName + "/" + sDeviceId,
                 sDP + ".Data:_address.._connection",          MINDSPHERE_CONNECTION_DP,
                 sDP + ".Data:_address.._direction",           DPATTR_ADDR_MODE_OUTPUT,
                 sDP + ".Data:_address.._datatype",            1001,
                 sDP + ".Data:_address.._drv_ident",           "MQTT",
                 sDP + ".Data:_address.._active",              TRUE,
                 sDP + ".Diag:_distrib.._type",                DPCONFIG_DISTRIBUTION_INFO,
                 sDP + ".Diag:_distrib.._driver",              9,
                 sDP + ".Diag:_address.._type",                DPCONFIG_PERIPH_ADDR_MAIN,
                 sDP + ".Diag:_address.._reference",           "runtime/inject/diag/timeseries/" + sProtocol + "/" + sDeviceName + "/" + sDeviceId,
                 sDP + ".Diag:_address.._connection",          MINDSPHERE_CONNECTION_DP,
                 sDP + ".Diag:_address.._direction",           DPATTR_ADDR_MODE_OUTPUT,
                 sDP + ".Diag:_address.._datatype",            1001,
                 sDP + ".Diag:_address.._drv_ident",           "MQTT",
                 sDP + ".Diag:_address.._active",              TRUE/*,
                    sDP + ".Browse:_distrib.._type",              DPCONFIG_DISTRIBUTION_INFO,
                    sDP + ".Browse:_distrib.._driver",            9,
                    sDP + ".Browse:_address.._type",              DPCONFIG_PERIPH_ADDR_MAIN,
                    sDP + ".Browse:_address.._reference",         "<command needs to be defined>",
                    sDP + ".Browse:_address.._connection",        MINDSPHERE_CONNECTION_DP,
                    sDP + ".Browse:_address.._direction",         DPATTR_ADDR_MODE_INPUT_SPONT,
                    sDP + ".Browse:_address.._datatype",          1001,
                    sDP + ".Browse:_address.._drv_ident",         "MQTT",
                    sDP + ".Browse:_address.._active",            TRUE*/);
}

/**
 * @brief configure MQTT address configs for configuration and response
 */
void updateMnspConfigurationDP()
{
  int iType;
  dpGet(DPE_NEW_CONFIGURATION + ":_address.._type", iType);

  if (iType == DPCONFIG_NONE) //address configs needs to be created
  {
    setMqttAddress(DPE_NEW_CONFIGURATION, "cloud/monitoring/datasources");
    setMqttAddress(DPE_BOXID, "boxmanager/monitoring/systeminformation/boxID");
    setMqttAddress(DPE_DIAGNOSTIC_NEW, "cloud/monitoring/update/configuration");
    setMqttAddress(DPE_DIAGNOSTIC_LOG_FILE_REQUEST, "cloud/controlling/command/$runtime/log-upload/v1.0");
    setMqttAddress(DPE_DIAGNOSTIC_COMMAND, "cloud/controlling/command/WINCCOA/diagnostic-command/v1.0", TRUE, TRUE);
    setMqttAddress(DPE_COMMANDRESPONSE, "runtime/controlling/commandUpdate", FALSE);
    setMqttAddress(DPE_FILE_REQUEST, "runtime/requests/configFiles", FALSE);
    setMqttAddress(DPE_FILE_RESPONSE, "agentruntime/responses/configFiles/WINCCOA");
    setMqttAddress(DPE_BROWSING_COMMNAD, "cloud/controlling/command/WINCCOA/generate-browsing-data/v1.0");
    setMqttAddress(DPE_FILE_UPLOAD_RESPONSE_BY_MNSP, "agentruntime/responses/iotFilesUpload/WINCCOA");
    setMqttAddress(DPE_FILE_UPLOAD_REQUEST_BY_WCCOA, "runtime/requests/iotFilesUpload", FALSE);
  }
}

/**
 * @brief confiure one MQTT address
 * @param sDPE             datapoint element
 * @param sTopic           topic for the address
 * @param bSubscribe       direction of address - subscribe (default is TRUE) or publish
 * @param bLowLevelCompar  lowLevelComparison (default is FALSE)
 */
setMqttAddress(string sDPE, string sTopic, bool bSubscribe = TRUE, bool bLowLevelCompar = FALSE)
{
  dpSetTimedWait(0, sDPE + ":_distrib.._type",             DPCONFIG_DISTRIBUTION_INFO,
                 sDPE + ":_distrib.._driver",           9,
                 sDPE + ":_address.._type",             DPCONFIG_PERIPH_ADDR_MAIN,
                 sDPE + ":_address.._reference",        sTopic,
                 sDPE + ":_address.._connection",       MINDSPHERE_CONNECTION_DP,
                 sDPE + ":_address.._direction",        bSubscribe ? DPATTR_ADDR_MODE_INPUT_SPONT : DPATTR_ADDR_MODE_OUTPUT,
                 sDPE + ":_address.._datatype",         1001,
                 sDPE + ":_address.._drv_ident",        "MQTT",
                 sDPE + ":_address.._lowlevel",         bSubscribe && bLowLevelCompar,
                 sDPE + ":_address.._active",           TRUE);
}

/**
 * @brief create a langstring from a given string by using the string for each language
 * @param sText the given text
 * @param lsText resulting langString
 */
void EB_setMultilingualText(const string &sText, langString &lsText)
{
  for (int i = 0; i < getNoOfLangs(); i++)
  {
    setLangString(lsText, i, sText);
  }
}

/**
 * @brief translation of mindsphere mapping keys to IOT suite mapping keys
 * @param sKey is the mindsphere mapping key, which should be translated to IOT suite mapping key
 * @return sKey (if not found) or the key for key name in IOT suite
 */
string getMindsphereToIotMappingKey(const string &sKey)
{
  string sIotKey = sKey;

  if (mappingHasKey(mDeviceKEY_MNSP_MNSP_IOT, sKey))
  {
    sIotKey = mDeviceKEY_MNSP_MNSP_IOT[sKey];
  }

  return sIotKey;
}

/**
 * @brief mapping of WinCC OA quality values to MindSphere quality codes
 * @param daQualityStates set of quality bits from WinCC OA
 * @param bTimeFromField defines if the timestamp is used from device or current time is used - if current time is used, ignore time invalid (and allow time change of WinCC OA)
 */
int getQualityInteger(const dyn_anytype &daQualityStates, const bool &bTimeFromField)
{
//   makeDynBool(, , (bool)ddaTab[i][10] /*inactive or not running _userbit_5*/, (bool)ddaTab[i][7])
  if (daQualityStates[INDEX_DISCON])
  {
    return BAD_DISCONNECT; //status "disconnected"
  }
  else if ((bool)daQualityStates[INDEX_INACTCON] /*inactive or not running _userbit_5*/)
  {
    return BAD_CONNECTION; //status "inactive" or "operation state warnings"
  } //bad quality if timestamp comes from field, or ignore timestamps quality (if timestamp comes from this manager)
  else if (!((bool)daQualityStates[INDEX_ADDCHECKED] && (bool)daQualityStates[INDEX_ADDOK] && !(bool)daQualityStates[INDEX_BAD] /*_bad*/) && (bTimeFromField || !(bool)daQualityStates[INDEX_TIMEBAD]))
  {
    return INVALID_ARGUMENT; //status "invalid"
  }
  else
  {
    return GOOD_ARGUMENT;
  }
}

/**
 * @brief get current or historical logs (optional filtered) and export to json file into log folder
 * @param sFileName:       the filename for json file
 * @param eLogSeverity:    severiy filter (LogSeverity: Information, Warning, Error, All) ignore
 * @param dsFilterAppName: app names (DPs) or "*" which should be included in the result
 * @param dsFilterType:    types (DPE nodes -> Runtime, Configuration, Internet, Periphery, Update) or "*" which should be included in the result
 * @param tFrom:           if != 0, timestamp for the begin of the query
 * @param tTo:             if != 0, timestamp for the end of the query
 * @return the file path and name if file could be created sucessfully, otherwise ""
 */
string exportLogsAsJson(const string &sFileName, LogSeverity eLogSeverity = LogSeverity::All, dyn_string dsFilterAppName = makeDynString("*"), dyn_string dsFilterType = makeDynString("*"), time tFrom = 0, time tTo = 0)
{
  return createLogFile(sFileName, EBlog::getLogAsJsonString(eLogSeverity, dsFilterAppName, dsFilterType, tFrom, tTo));
}

/**
 * @brief export to json file into log folder
 * @param sFileName: the filename for json file
 * @param sJson: json string content to be exported to file
 * @return the file path and name if file could be created sucessfully, otherwise ""
 */
string createLogFile(const string &sFileName, const string &sJson)
{
  if (sFileName != "")
  {
    string sTmpFile = getPath(LOG_REL_PATH) + sFileName;
    file f = fopen(sTmpFile, "w");

    if (!ferror(f))
    {
      fputs(sJson, f);
      fclose(f);
      DebugFTN(DBG_LOG, "log export file " + sFileName + " size: " + strlen(sJson));

      return sTmpFile;
    }
  }

  DebugFTN(DBG_LOG, "log export file " + sFileName + " error on file export!");
  return "";
}

dpCreatedCB(string sEvent, mapping mData)
{
  dyn_string dsBaseTypes = makeDynString("EB_Bool", "EB_Float", "EB_Int", "EB_Time", "EB_Uint", "EB_String");
  int iPos = dynContains(dsBaseTypes, mData["dpType"]);

  if (iPos > 0 && patternMatch(dsBaseTypes[iPos] + "*", dpSubStr(mData["dp"], DPSUB_DP)))
  {
//     DebugN("dpCreated",sEvent, mData, iPos,patternMatch(dsBaseTypes[iPos]+"*", dpSubStr(mData["dp"], DPSUB_DP)) );

  }
}

/**
 * @brief update tag quality of device connection state for newly created tags
 * @param dmAddedTags: list of new tags
 */
updateDriverConnectionStateForNewTag(const dyn_mapping &dmAddedTags)
{
  if (dynlen(dmAddedTags) > 0)
  {
    string sDeviceNode = substr((string)dmAddedTags[1]["tagkey"], 0, strpos((string)dmAddedTags[1]["tagkey"], ".Node"));
    synchronized(mConnectionStates)
    {
      // TEMP: prevent ctrl error when sDeviceNode unknown
      if (!mConnectionStates.contains(sDeviceNode))
        return;

      if (mappingHasKey(mConnectionStates, sDeviceNode) && mConnectionStates[sDeviceNode] != 0) //if device is not connect correctly, update the state user bit
      {
        dyn_string dsTags;
        dyn_bool dbState;

        for (int i = dynlen(dmAddedTags); i > 0; i--)
        {
          string sDpe;
          cnsGetId(dmAddedTags[i]["tagkey"], sDpe);
          dynAppend(dsTags, sDpe + ":_original.._userbit" + (mConnectionStates[sDeviceNode] == -1 ? BAD_DISCONNECT_USERBIT : BAD_CONNECTION_USERBIT));
          dynAppend(dbState, TRUE);
        }

        dpSet(dsTags, dbState);
        DebugFTN("DBG_CONFIGURATION", "update tag state for new tags", dsTags, dbState, sDeviceNode);
      }
    }
  }
}


/**
 * @brief update tag quality of device connection state for newly created tags
 * @param dmAddedTags: list of new tags
 */
/*
  {
  "header": {
    "version": "0.1",
    "generationTimeServer": "2015-08-01T05:39:00Z"
  },
  "device": {
    "deviceIdentifier": "321",
    "serialNumber": "someserialno",
    "deviceType": "NANO",
    "networkInterfaces": [
      {
        "name": "WebInterface",
        "DHCP": {
          "enabled": false
        },
        "static": {
        }
      },
      {
        "name": "ProductionInterface",
        "DHCP": {
          "enabled": false
        },
        "static": {
          "IPv4": "192.168.11.14",
          "SubnetMask": "255.255.255.0",
          "Gateway": "192.168.11.1",
          "DNS": [],
          "IPv6": ""
        }
      }
    ],
      "diagnostic": {
            "autoLogUploadEnabled": true | false,
            "logLevel": "TRACE | DEBUG | INFO | WARNING | ERROR"
      }
  }
}
  */
diagnosticRequestCB(string sDPE, string sJson) synchronized(eCurrentLogLevel)
{
  if (sJson != sLastDiagnostic && sJson != "")
  {
    //compare current diagnostic settings with new ones and execute the required basic functions

    mapping mNewDiagnosticSettings = jsonDecode(sJson);

    if (!mappingHasKey(mNewDiagnosticSettings, "device"))
    {
      mNewDiagnosticSettings["device"] = makeMapping("diagnostic", makeMapping());
    }
    else if (!mappingHasKey(mNewDiagnosticSettings["device"], "diagnostic") || mappinglen((mapping)mNewDiagnosticSettings["device"]["diagnostic"]) == 0)
    {
      mNewDiagnosticSettings["device"]["diagnostic"] = makeMapping();
    }

    mapping mLastDiagnosticSettings = jsonDecode(sLastDiagnostic);

    if (!mappingHasKey(mLastDiagnosticSettings, "device"))
    {
      mLastDiagnosticSettings["device"] = makeMapping("diagnostic", makeMapping());
    }
    else if (!mappingHasKey(mLastDiagnosticSettings["device"], "diagnostic") || mappinglen((mapping)mLastDiagnosticSettings["device"]["diagnostic"]) == 0)
    {
      mLastDiagnosticSettings["device"]["diagnostic"] = makeMapping();
    }

    if (mLastDiagnosticSettings["device"]["diagnostic"] != mNewDiagnosticSettings["device"]["diagnostic"])
    {
      anytype aNewAutoUploadLog = compareMappingValue(mLastDiagnosticSettings["device"]["diagnostic"], mNewDiagnosticSettings["device"]["diagnostic"], "autoLogUploadEnabled");
      anytype aNewLogLevel = compareMappingValue(mLastDiagnosticSettings["device"]["diagnostic"], mNewDiagnosticSettings["device"]["diagnostic"], "logLevel");
      synchronized(dsLogFilesToUpload)
      {
        if (aNewAutoUploadLog == MAPPING_COMPARE_DEFAULT || aNewAutoUploadLog == FALSE) //use default value for this setting
        {
          dynClear(dsLogFilesToUpload);  //no log files should be uploaded
        }
        else if (aNewAutoUploadLog != MAPPING_COMPARE_NOCHANGE) //use new setting
        {
          if (aNewAutoUploadLog == TRUE) //on switching log file upload on, do a log upload after 1 minute
          {
            dsLogFilesToUpload = makeDynString("*");
          }

//           else //on switching diagnostic log file upload off, upload the current logs a last time
//           {
//             exportLogsAsJson("logsCurrent.log");
//             time tNow = getCurrentTime();
//             exportLogsAsJson("logsLastHour.log", -1, "*", "*", tNow - (60*60), tNow);
//             diagnosticLogFileSwitchedCB("","*.log");
//           }
        }

        if (aNewLogLevel != MAPPING_COMPARE_NOCHANGE) //use new setting - special reactions of logLevels "TRACE | DEBUG | INFO | WARNING | ERROR"
        {
          if (isDbgFlag(DBG_LOG))
          {
            string sOldLogLevel = mappingHasKey(mLastDiagnosticSettings["device"]["diagnostic"], "logLevel") ? mLastDiagnosticSettings["device"]["diagnostic"]["logLevel"] : "";
            DebugFTN(DBG_LOG, "LOG: log level has been changed from '" + sOldLogLevel + "' to '" + aNewLogLevel + "'");
          }

          if (aNewLogLevel == "TRACE")
          {

            eCurrentLogLevel = eLogLevel::TRACE;

            //all user action related debug flags are activated
            setDbgFlag(DBG_DEVICE);
            setDbgFlag(DBG_TAG);
            setDbgFlag(DBG_VALUEUPDATE, FALSE);
            setDbgFlag(DBG_CONFIGURATION);
            setDbgFlag(DBG_COMMAND);
            setDbgFlag(DBG_BROWSE);
            DebugFTN(DBG_LOG, "LOG: only user action logs switched on");
//             setDbgFlag(DBG_LOG, FALSE);
          }
          else if (aNewLogLevel == "DEBUG")
          {
            eCurrentLogLevel = eLogLevel::DEBUG;

            //all debug flags activated
            setDbgFlag(DBG_DEVICE);
            setDbgFlag(DBG_TAG);
            setDbgFlag(DBG_VALUEUPDATE);
            setDbgFlag(DBG_CONFIGURATION);
            setDbgFlag(DBG_COMMAND);
            setDbgFlag(DBG_BROWSE);
//             setDbgFlag(DBG_LOG);
            DebugFTN(DBG_LOG, "LOG: all log levels switched on");
          }
          else
          {
            //all debug flags off
            setDbgFlag(DBG_DEVICE, FALSE);
            setDbgFlag(DBG_TAG, FALSE);
            setDbgFlag(DBG_VALUEUPDATE, FALSE);
            setDbgFlag(DBG_CONFIGURATION, FALSE);
            setDbgFlag(DBG_COMMAND, FALSE);
            setDbgFlag(DBG_BROWSE, FALSE);
            DebugFTN(DBG_LOG, "LOG: all log levels switched off");
//             setDbgFlag(DBG_LOG, FALSE);
          }

          if (aNewLogLevel == "INFO")
          {
            eCurrentLogLevel = eLogLevel::INFO;
          }
          else if (aNewLogLevel == "WARNING")
          {
            eCurrentLogLevel = eLogLevel::WARNING;
          }
          else if (aNewLogLevel == "ERROR")
          {
            eCurrentLogLevel = eLogLevel::ERROR;
          }

//           else
//           {
//             eCurrentLogLevel = eLogLevel::OFF;
//           }
        }
        else if (aNewLogLevel == MAPPING_COMPARE_DEFAULT)
        {
          eCurrentLogLevel = eLogLevel::OFF;
        }
      }
    }

    sLastDiagnostic = sJson;
    dpSet(DPE_DIAGNOSTIC_CURRENT, sLastDiagnostic);
  }
}

/**
 * @brief automatic log upload at midnight, if autoupload log files is activated (dsLogFilesToUpload is set)
 */
autoLogUpload()
{
  time tNow;

  while (true)
  {
    tNow = getCurrentTime();
    int iSecToWait = (60 - second(tNow)) + 60 * (59 - minute(tNow)) + 3600 * (23 - hour(tNow));
    DebugFTN(DBG_LOG, "next automatic log upload at:", tNow + iSecToWait);
    delay(iSecToWait); //auto matically log upload at 0:00

    if (dynlen(dsLogFilesToUpload) != 0)  //if auto upload log is activated
    {
      logUpload();
    }
  }
}

/**
 * @brief depending on active log level (eCurrentLogLevel), the required log files are exported and uploaded to mindsphere
 */
logUpload(string sCommandId = "")  synchronized(eCurrentLogLevel)
{
  if (eCurrentLogLevel != eLogLevel::OFF)
  {
    time tNow = getCurrentTime();
    mapping mContent;
    mContent["timeCurrent"] = tNow;
    mContent["managersRunning"] = Diagnostics::getRunningManagers();
    mContent["managersStopped"] = Diagnostics::getStoppedManagers();
    createLogFile("managerStates.log", jsonEncode(mContent, FALSE));
    LogSeverity eLogSeverity = LogSeverity::Information; //LogSeverity::Information


    if (eCurrentLogLevel == eLogLevel::WARNING)
    {
      eLogSeverity = LogSeverity::Warning;
    }
    else if (eCurrentLogLevel == eLogLevel::ERROR)
    {
      eLogSeverity = LogSeverity::Error;
    }

    exportLogsAsJson("logsCurrent.log", eLogSeverity); //export current logs
    exportLogsAsJson("logsHistory.log", eLogSeverity, "*", "*", tNow - (24 * 60 * 60), tNow); //export logs of last day

    //zip and upload log files
    diagnosticLogFileSwitchedCB("", "*.log", sCommandId);
  }
}

/**
 * @brief workfunciton to request log files via Mindsphere (MQTT topic: cloud/controlling/command/$runtime/log-upload/v1)
 * @param sDPE:       DPE from dpConnect
 * @param sJson:      json content for log file request
 *
  {
  "commandId": "12f3f77e-ec5e-43a8-bacb-f69101c41938",
  "createdAt": "2020-01-01T12:00:00Z",
    "data": {
    "type": "log-upload",
    "version": "v1",
    "to": "$runtime",
    }
  }
 */
diagnosticLogFileRequestCB(string sDPE, string sJson)
{
  mapping mContent = jsonDecode(sJson);
  logUpload(mContent["commandId"]);
}

/**
 * @brief workfunciton to upload log files from log folder to mindsphere, if file is in pattern list dsLogFilesToUpload or sDPE is empty (=direct call)
 * @param sDPE:       DPE from dpConnect, or if empty the execution was triggered via CTRL script and ignores file filtering
 * @param sFile:      file name to be copied to mindsphere - files will be filtered with dsLogFilesToUpload or sDPE needs to be emtpy
 * @param sCommandId: command id is part of file name (comes from mindsphere if user has requested the file upload via button)
 */
diagnosticLogFileSwitchedCB(string sDPE, string sFile, string sCommandId = "")
{
  DebugFTN(DBG_LOG, "log file switch", sFile, sCommandId, dsLogFilesToUpload);
  synchronized(dsLogFilesToUpload)
  {
    if (sFile != "")
    {
      bool bUpload = (sDPE == ""); //upload request via direct CTRL call

      for (int i = dynlen(dsLogFilesToUpload); i > 0 && !bUpload; i--)
      {
        if (patternMatch(dsLogFilesToUpload[i], sFile))
        {
          bUpload = TRUE;
        }
      }

      if (bUpload)
      {
        //on persistent_massdata shell scripts can not be executed
        string sCommand = getShellScriptPath("uploadLogFiles.sh") + " " + sCommandId + " " + sFile;
        system(sCommand);
        DebugFTN(DBG_LOG, "log file uploaded", sFile, sCommandId, sCommand);
      }
    }
  }
}


/**
 * @brief search for shell script in WinCC OA installation /MNSP_Connect/bin folder or in own project/bin folder
 * @param sFile:      file name of the shell script
 * @return absolute path of the shell script
 */
string getShellScriptPath(const string &sFile)
{
  string sShellScriptPath = PVSS_PATH + PROJ + "/bin/" + sFile;

  if (!isfile(sShellScriptPath))
  {
    sShellScriptPath = getPath(BIN_REL_PATH, sFile);
  }

  return sShellScriptPath;
}

/**
 * @brief workfunction to trigger command like manger restart, project restart, log file upload
 * @details example json string:   cloud/controlling/command/WINCCOA/diagnostic-command/v1.0
 *                                 {
 *                                   "commandId": "ab7cb462-aa21-4111-ba4c-d78349936306",
 *                                   "createdAt": "2021-02-23T11:59:13.751Z",
 *                                   "data": {
 *                                     "type": <string>,
 *                                     "version": <string>,
 *                                     "payload": { <object> }
 *                                   }
 *                                 }
 * payload options: "restartManager": {"manager": "WCCOAs7", "options": ""},
 *                  "restartProject": "TRUE",
 *                  "getLogs": {"filterApp": "*", "filterType": "*", "minSeverity": -1, "from": "2021-02-23T10:30:13.751Z", "to": "2021-02-23T11:59:13.751Z", "files": ["PVSS_II.log", "other.log"]},
 *                  "setDbgFlag": {"manager": "WCCOActrl", "options":"EB_Package_MTConnect/Service.ctl", "dbgFlags": "-snd 2"},
 *                  "recoverProject": "TRUE"
 * manager could be: "WCCOAs7", ... or "WCCOActrl" with "options":"EB_Package_MTConnect/Service.ctl"
 * @param sCommandJson: command as json string
 */
diagnosticCommandCB(string sDPE, string sCommandJson)
{
  DebugFTN(DBG_LOG, "log command received", sCommandJson);

  if (sCommandJson != "")
  {
    mapping mCommand = jsonDecode(sCommandJson);
    string sCommandId = getMappingValueOrDefault(mCommand, "commandId", "cmdId_default");
    string sCreatedAt = getMappingValueOrDefault(mCommand, "createdAt", "createdAt_default");

    if (mappingHasKey(mCommand, "data") && mappingHasKey(mCommand["data"], "payload"))
    {
      Logging::write(LogCategory::Runtime, Logging::DIAG_COMMAND, LogSeverity::Information, makeDynString(sCommandId, sCreatedAt, mCommand["data"]["payload"]));

      if (mappingHasKey(mCommand["data"]["payload"], "setDbgFlag"))
      {
        string sManager  = getMappingValueOrDefault(mCommand["data"]["payload"]["setDbgFlag"], "manager", "");
        string sOptions  = getMappingValueOrDefault(mCommand["data"]["payload"]["setDbgFlag"], "options", "");
        string sDbgFlags = getMappingValueOrDefault(mCommand["data"]["payload"]["setDbgFlag"], "dbgFlags", "");

        int iManagerIndex = Diagnostics::activateFlags(sManager, sOptions, sDbgFlags);
        DebugFTN(DBG_LOG, "log command received - debug flags", sManager, sOptions, sDbgFlags, iManagerIndex);
      }

      // get log files
      if (mappingHasKey(mCommand["data"]["payload"], "getLogs"))
      {
        string sFilterApp  = getMappingValueOrDefault(mCommand["data"]["payload"]["getLogs"], "filterApp", "*");
        string sFilterType = getMappingValueOrDefault(mCommand["data"]["payload"]["getLogs"], "filterType", "*");
        int iMinSeverity   = getMappingValueOrDefault(mCommand["data"]["payload"]["getLogs"], "minSeverity", -1);
        time tFrom         = scanTimeUTC(getMappingValueOrDefault(mCommand["data"]["payload"]["getLogs"], "from", (time)0));
        time tTo           = scanTimeUTC(getMappingValueOrDefault(mCommand["data"]["payload"]["getLogs"], "to", (time)0));
        string sLogFile;



        if (year(tFrom) > 2020 && year(tTo) > 2020) //larger than 0 time incl. time diff to UTC
        {
          sLogFile = "logsHistory.log";
          exportLogsAsJson(sLogFile, iMinSeverity, sFilterApp, sFilterType, tFrom, tTo); //export logs of last day
        }
        else
        {
          sLogFile = "logsCurrent.log";
          exportLogsAsJson(sLogFile, iMinSeverity, sFilterApp, sFilterType); //export current logs
        }

        DebugFTN(DBG_LOG, "log export", sLogFile, iMinSeverity, sFilterApp, sFilterType, tFrom, tTo);

        dyn_string dsFiles = getMappingValueOrDefault(mCommand["data"]["payload"]["getLogs"], "files", makeDynString());

        for (int i = 1; i <= dynlen(dsFiles); i++)
        {
          sLogFile += "+" + dsFiles[i]; //+ is separator for file list
        }

        diagnosticLogFileSwitchedCB("", sLogFile, sCommandId);
      }

      //recover project
      if (mappingHasKey(mCommand["data"]["payload"], "recoverProject"))
      {
        string sCommand = "sudo nohup " + getShellScriptPath("recoverProject.sh");

        DebugTN(DBG_LOG, "recover project in 60 sec", sCommand);
        Logging::write(LogCategory::Runtime, Logging::DIAG_COMMAND, LogSeverity::Information, makeDynString(sCommandId, sCreatedAt, "recover project in 60 sec >> " + sCommand));
        delay(60);
        systemDetached(sCommand);
      }
      //restart project
      else if (mappingHasKey(mCommand["data"]["payload"], "restartProject"))
      {
        Diagnostics::restartProject();
      }
      //restart manager
      else if (mappingHasKey(mCommand["data"]["payload"], "restartManager") && mappingHasKey(mCommand["data"]["payload"]["restartManager"], "manager"))
      {
        Diagnostics::restartManager(mCommand["data"]["payload"]["restartManager"]["manager"],
                                    mappingHasKey(mCommand["data"]["payload"]["restartManager"], "options") ? mCommand["data"]["payload"]["restartManager"]["options"] : "");
      }
    }
  }
}

/**
 * @brief get value from mapping, or if not existing, return default value
 * @param m:             mapping wherer to search for key
 * @param sKey:          key to be searched
 * @param aDefaultValue: default value
 * @return value from mapping or default value (if key does not exist)
 */
anytype getMappingValueOrDefault(const mapping &m, const string &sKey, const anytype &aDefaultValue)
{
  if (mappingHasKey(m, sKey))
  {
    return m[sKey];
  }
  else
  {
    return aDefaultValue;
  }
}

/**
 * @brief compare one value element from two mappings and check if the value exists, has changed or is equal
 * @param mOld: first mapping to be source (old mapping)
 * @param mOld: second mapping to be compared (new Mapping)
 * @param sKey: the mapping key to be checked
 * @return the mapping value of mNew or MAPPING_COMPARE_NOCHANGE (if the values are equal) or MAPPING_COMPARE_DEFAULT (if the key does not exist in the new mapping)
 */
anytype compareMappingValue(const mapping &mOld, const mapping &mNew, const string &sKey)
{
  if (mappingHasKey(mOld, sKey))
  {
    if (mappingHasKey(mNew, sKey))
    {
      if (mOld[sKey] != mNew[sKey])
      {
        return mNew[sKey];
      }
      else
      {
        return MAPPING_COMPARE_NOCHANGE;
      }
    }
    else
    {
      return MAPPING_COMPARE_DEFAULT;
    }
  }
  else
  {
    if (mappingHasKey(mNew, sKey))
    {
      return mNew[sKey];
    }
  }

  return MAPPING_COMPARE_NOCHANGE; //no change
}

/**
 * @brief Downloads Files from the mindsphere
 * @param sProtocol The protocol of the device that is created
 * @param sDP       The DP of the device that is created (MNSP_MQTT_COMM)
 * @param mJson     The mapping from mindsphere
 */
string downloadFile(const string sProtocol, const string sDp, const mapping mJson)
{
  mapping mReturn;
  mapping mFile        = mJson["scdFile"];
  string sFileName     = mFile["name"];
  string sFileId       = mFile["fileId"];
  string sRevisionId   = mFile["revisionId"];
  string sTopic        = "WINCCOA";
  string sJsonRequest, sJsonResponse, sOut, sErr;
  dyn_anytype daReturnValues;
  int iTimeOut = 15;
  bool bExpired = FALSE;
  bool bStatus = FALSE;

  if (isDbgFlag(DBG_LOCAL_SCD_FILE))
  {
    dyn_string dsLocalSCD;
    string sFile;

    dsLocalSCD = getFileNames(DATA_REL_PATH + "/" + PATH_DATA_SCD_DOWNLOAD, "*.zip");
    sFile = getPath(DATA_REL_PATH) + "/" + PATH_DATA_SCD_DOWNLOAD + "/" + dsLocalSCD;

    DebugN("LOCAL", sFile);
    return sFile;
  }
  else
  {
    //create the mapping / Json that is used to send the Request to MQTT topic
    mapping mRequest = makeMapping("id",          sFileId,
                                   "fileId",      sFileId,
                                   "revisionId",  sRevisionId,
                                   "replyTo",     sTopic);

    sJsonRequest  = jsonEncode(mRequest);

    dyn_string  dsNamesSet    = sDp + ".file.Request:_original.._value";
    dyn_string  dsValuesSet   = sJsonRequest;
    dyn_string  dsNamesWait   = sDp + ".file.Response:_original.._value_changed";
    dyn_string  dsNamesReturn = sDp + ".file.Response:_online.._value";
    dyn_anytype daConditions  = makeDynAnytype();
    time tUntil = getCurrentTime() + 150;

    //Loop for downloading the file, the file has 10minutes maximum to be downloaded and does 10 retries
    while (tUntil > getCurrentTime() && !bStatus)
    {
      dpSetAndWaitForValue(dsNamesSet, dsValuesSet, dsNamesWait, daConditions, dsNamesReturn, daReturnValues, iTimeOut, bExpired);

      sJsonResponse = daReturnValues;
      mReturn = jsonDecode(sJsonResponse);

      //Success file was downloaded
      if (!bExpired && mReturn["status"] == "SUCCEEDED")
      {
        bStatus = TRUE;
      }
      //Failure file not found
      else if (!bExpired && mReturn["status"] != "SUCCEEDED")
      {
        //Exit immediately if Debugflag is set
        if (isDbgFlag(DBG_IGNORE_DOWNLOAD_FAILURE))
        {
          bStatus = TRUE;
        }
        else
        {
          delay(iTimeOut);
        }
      }
      //Failure Timeout waiting for response
      else if (bExpired && mReturn["status"] != "SUCCEEDED")
      {
        //Exit immediately if Debugflag is set
        if (isDbgFlag(DBG_IGNORE_DOWNLOAD_FAILURE))
        {
          bStatus = TRUE;
        }
        else
        {
          bExpired = FALSE;
          delay(iTimeOut);
        }
      }
    }

    if (!mappingHasKey(mReturn, "fileLocation"))
    {
      return "";
    }
    else
    {
      return mReturn["fileLocation"];
    }
  }
}

/**
 * @brief thread function to read dp value from PLC with 0,5 sec delay via single query
 * @param sDPE    Datapointelement to be read from PLC
 */
readValueOnce(string sDPE)
{
  string sDP = dpSubStr(sDPE, DPSUB_SYS_DP);
  int iDrvNr;
  dpGet(sDPE+":_distrib.._driver", iDrvNr);

  delay(0, 500); //wait before reading value from PLC
  if (dpExists(sDP)) //check if it is not aready deleted
  {
    DebugFTN(DBG_COMMAND, __FUNCTION__ + "(" + sDPE + ") request single query:", "_Driver"+ iDrvNr +".SQ", sDPE);
    dpSet("_Driver"+ iDrvNr +".SQ", sDPE); //single query
  }
}

/**
 * @brief workfunction to update emergencymode limits on change of total disk and main memory space
 * @param iTotalDiskSpace total dispace according to data manager
 * @param iTotalMemory    total availabel main memory according to data
 */
configureEmergencyModeCB(string sDPE1, int iTotalDiskSpace, string sDPE2, int iTotalMemory)
{
  int iEmergencyDiskSpace, iEmergencyMemory;

  iEmergencyDiskSpace = iTotalDiskSpace * (1.0 - MEMORY_EMERGENCY_FACTOR);

  if (iEmergencyDiskSpace > 50000) //max is 50 MB
  {
    iEmergencyDiskSpace = 50000;
  }

  iEmergencyMemory    = iTotalMemory * (1.0 - DISKSPACE_EMERGENCY_FACTOR);

  if (iEmergencyMemory > 50000) //max is 50 MB
  {
    iEmergencyMemory = 50000;
  }

  int iEmergencyDiskSpaceCurrent, iEmergencyMemoryCurrent;
  dpGet("_ArchivDisk.EmergencyKBLimit",  iEmergencyDiskSpaceCurrent,
        "_MemoryCheck.EmergencyKBLimit", iEmergencyMemoryCurrent);

  if (iEmergencyDiskSpace != iEmergencyDiskSpaceCurrent ||
      iEmergencyMemory != iEmergencyMemoryCurrent)
  {
    DebugTN("emerceny limits changed disk: " + iEmergencyDiskSpace + " KB (of " + iTotalDiskSpace + " KB)   main memory: " + iEmergencyMemory + " KB (of " + iTotalMemory + " KB)");
    dpSet("_ArchivDisk.EmergencyKBLimit",  iEmergencyDiskSpace,
          "_MemoryCheck.EmergencyKBLimit", iEmergencyMemory);
  }
}


string getBrowsingFolder()
{
  //folder within data folder for browsing results to be located
  string sFolder = "/persistent_massdata/appData/browsing/";
  string sFolderToCreate;

  if (_WIN32)
  {
    sFolder = getPath(DATA_REL_PATH, "browsing") + "/";

    if (sFolder == "/")
    {
      sFolderToCreate = getPath(DATA_REL_PATH) + "browsing/";
    }
  }
  else
  {
    if (!isdir(sFolder))
    {
      sFolderToCreate = sFolder;
    }
  }

  if (sFolderToCreate != "")
  {
    DebugFTN(DBG_BROWSE, "create browsing folder on startup");

    if (mkdir(sFolderToCreate, "750"))
      DebugFTN(DBG_BROWSE, "created browsing folder on startup", sFolderToCreate);
    else
      DebugFTN(DBG_BROWSE, "creating browsing folder on startup was not possible!", sFolderToCreate);
  }
  else
  {
    //remvoe possible old files at start up time
    dyn_string dsFiles = getFileNames(sFolder, "*.*");

    for (int i = dynlen(dsFiles); i > 0; i--)
    {
      remove(sFolder + dsFiles[i]);
    }

    DebugFTN(DBG_BROWSE, "empty browsing folder on startup", sFolder, dsFiles);
  }

  return sFolder;
}

/**
  @brief The function checks if the stated string contains only permitted characters for the respective use case.

  @details The function checks if the stated string contains only permitted characters for the respective use case.
  It also supports the checking of multibyte characters. A corrected string is returned via
  the in/out parameter dpName when the nameType parameter NAMETYPE_DP is used.

    | nametype     | Non permitted characters                                |
    |--------------|---------------------------------------------------------|
    |NAMETYPE_DP   | blank , . : ; ! ? [ ] { } / \ \\ \| * @ \\t $ # \\n  \" |
    |NAMETYPE_PROJ | blank \ / \" ? \< \> * \| : ; \\n                       |

  @note Replaces the dpNameCheck() and dpIsLegalName() functions which remain only for compatibility reasons!

  @param[in,out] dpName String to be checked for conformance to the respective nameType selection.
  @param nameType Constants that specify the check type:\n
    + NAMETYPE_DP (== 1; default): Checks whether the dpName string contains characters that are not allowed for data point (elements).
    + NAMETYPE_PROJ (== 2): Checks whether the dpName string contains characters that are not allowed for project names.
    + NAMETYPE_PATH (== 3): No check at the moment.
  @param sReplaceChar: define which char (string) should replace invalid chars

  @return The function returns:
    | Return Value | Description |
    |--------------|-------------|
    | 0 | The string only contains permitted characters.|
    |-1 | One or more characters within the string are not permitted for this nameType.
    |-2 | The specified project name is too long.
*/
int nameCheckAndReplace(string &dpName, int nameType = NAMETYPE_DP, string sReplaceChar = "")
{
  //code used from nameCheck() function
  if (dpName.isEmpty())
    return -1;

  const int NAMETYPE_PROJ_LEN = 64;
  int i, err;
  string s;
  string cp;

  // Use strwalk for the iterating to support also UTF-8 languages.
  // In case of an UTF-8 language, strwalk returns the next codepoint in UTF-8 encoding,
  // i.e. a string of 1 to 4 bytes.
  for (i = 0; (cp = strwalk(dpName, i)) != "";)
  {
    switch (nameType)
    {
      case NAMETYPE_DP:
        if (!dpIsLegalName(cp))
        {
          err = -1;
          s += sReplaceChar;
        }
        else
          s += cp;

        break;

      case NAMETYPE_PROJ:
        if ((strlen(cp) != 1) ||
            (cp[0] < ' ') ||
            (cp[0] > '~') ||
            (
              cp == " "  ||
              cp == "\\" ||
              cp == "/"  ||
              cp == "\"" ||
              cp == "?"  ||
              cp == "<"  ||
              cp == ">"  ||
              cp == "*"  ||
              cp == "|"  ||
              cp == ":"  ||
              cp == ";"  ||
              cp == "'"
            )
           )
        {
          err = -1;
          s += sReplaceChar;
        }
        else
          s += cp;

        break;
    }
  }

  if ((nameType == NAMETYPE_PROJ) && (strlen(s) > NAMETYPE_PROJ_LEN))
  {
    // project name too long
    dpName = "";
    err = -2;
  }
  else
  {
    dpName = s;
  }

  return err;
}

/**
  @brief The function checks current WinCC OA DB version (patch level) and available DB update files and waits for update
*/
waitForDbUpgrade()
{
  dyn_string dsUpdateFiles = getFileNames(getPath(DPLIST_REL_PATH, "", 1, SEARCH_PATH_LEN), "update_*.dpl");

  dynSort(dsUpdateFiles, false);

  if (dynlen(dsUpdateFiles) > 0)
  {
    int iExpectedDbVersionNr, iCurrentDbVersionNr;

    //check which db version is expected
    sscanf(dsUpdateFiles[1], "update_%d.dpl", iExpectedDbVersionNr);

    dpGet("_DatabaseVersion.Sub", iCurrentDbVersionNr);
    DebugTN("DB upgrade required", iCurrentDbVersionNr, iExpectedDbVersionNr);

    if (iCurrentDbVersionNr < iExpectedDbVersionNr)
    {
      DebugTN("DB upgrade required! update files", dsUpdateFiles[1], iExpectedDbVersionNr, iCurrentDbVersionNr);
      bool bExpired;
      dyn_string dsRet = makeDynString("_DatabaseVersion.Sub:_online.._value");
      dyn_anytype daRet;

      DebugTN("wait for Db version", iExpectedDbVersionNr, iCurrentDbVersionNr);

      if (!isDbgFlag(DBG_LOCAL_SCD_FILE)) //do not use in built pipeline tests
        dpWaitForValue(makeDynString("_DatabaseVersion.Sub:_online.._value"), makeDynAnytype(iExpectedDbVersionNr),
                       dsRet, daRet, TIMEOUT_DB_VERSIONUPGRADE, bExpired);

      if (!bExpired)
      {
        DebugTN("Db upgrade sucessfully, wait additional 10sec before startup");
        delay(10); //wait after last DB update before adding new protocolls and do additional ascii import
      }
      else
      {
        DebugTN("DB upgrade was not finished in time!");
      }
    }
  }
}


/**
  @brief The function checks current WinCC OA DB version patch level 3.19 P005 was sucessfully installed
*/
bool isS7PlusDptUpdated()
{
  dyn_dyn_string ddsElem;
  dyn_dyn_int ddiTypes;
  dpTypeGet("_S7PlusConnection", ddsElem, ddiTypes);

  for (int i = 1; i <= dynlen(ddsElem); i++) //search for node Diagnostics on level 3
  {
    if (dynlen(ddsElem[i]) == 3 && ddsElem[i][3] == "Diagnostics")
    {
      return TRUE;
    }
  }

  return FALSE;
}

/**
  @brief The function does a dpSetAndWaitForValue for a list of datapoint elements with default config attributes
  @param dsDpes: list of DPEs to be set
  @param daVals: list of values to be set
  @param dsDpesWait: list of DPEs to be waiten for cerain values
  @param daValsWait: list of values to be waiten for
  @param iTimeoutSec: timeout in seconds to wait for the given values
  @param bAcceptPersistingValue: optional parameter to check current result values on DPEs and if already coorect, do not perform the dpSet
  @return The function returns:
    | Return Value | Description |
    |--------------|-------------|
    | 1 | got result within timeout
    | 0 | timeout expired
    |-1 | value existed alread (only used if parameter bAcceptPersistingValue = TRUE is given)
*/
int dpSetAndWaitForValueSimple(dyn_string dsDpes, dyn_anytype daVals,
                               dyn_string dsDpesWait, dyn_anytype daValsWait, int iTimeoutSec, bool bAcceptPersistingValue = FALSE)
{
  dyn_anytype daRet;

  if (bAcceptPersistingValue)
  {
    dpGet(dsDpesWait, daRet);

    if (daRet == daValsWait)
      return -1;
  }

  for (int i = dynlen(dsDpes); i > 0; i--)
  {
    dsDpes[i] = dpSubStr(dsDpes[i], DPSUB_SYS_DP_EL) + ":_original.._value";
  }

  for (int i = dynlen(dsDpesWait); i > 0; i--)
  {
    dsDpesWait[i] = dpSubStr(dsDpesWait[i], DPSUB_SYS_DP_EL) + ":_original.._value";
  }

  bool bExp;
  dyn_string dsRet;

  dpSetAndWaitForValue(dsDpes, daVals, dsDpesWait, daValsWait, dsRet, daRet, iTimeoutSec, bExp);
  return !bExp;
}
