// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author Schiefer Martin
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "pmon.ctl"
#uses "classes/EBCsv"
#uses "classes/EBXml"
#uses "EB_Package_Base/EB_Api"
#uses "classes/GenericDriver/BrowseItem"
#uses "classes/GenericDriver/DriverConst"
#uses "classes/GenericDriver/Tag"
#uses "classes/wssServer/WssConst"
#uses "classes/wssServer/WssClientConnectionContext"
#uses "classes/EBlog"
#uses "classes/ConnectionAlertState"
#uses "classes/Factory"
#uses "Logging"

//--------------------------------------------------------------------------------
// Variables and Constants
const int INVALID_INDEX                = 1; //do not change - performance improvement hard coded in getData()
const int BAD_DISCONNECT_INDEX         = 2; //do not change - performance improvement hard coded in getData()
const int BAD_CONNECTION_INDEX         = 3; //do not change - performance improvement hard coded in getData()
const int INVALID_STIME_INDEX          = 4; //do not change - performance improvement hard coded in getData()
//--------------------------------------------------------------------------------
/**
*/
class DeviceStateCallBack
{
  public static mapping getData(const mapping &mUserData, const dyn_string &dsDpes, const dyn_anytype &daValue)
  {
    return makeMapping("key", mUserData["keys"], "value", daValue);
  }
};

class TagStateCallBack
{
  /**
   * @brief    Prepare data for sending to MindSphere
   * @param  ddaData                      data array
   *          ddaData[i][1]               DP element name
   *          ddaData[i][2]               value
   *          ddaData[i][3]               status bit "address checked"     _userbit_2
   *          ddaData[i][4]               status bit "address ok"          _userbit_3
   *          ddaData[i][5]               status bit "from single query"   _from_SI
   *          ddaData[i][6]               status bit "invalid"             _bad
   *          ddaData[i][7]              status bit "invalid source time"  _stime_inv
   *          ddaData[i][8]               timestamp                        _online.._stime
   *          ddaData[i][9]               status bit "disconnected"        _userbit_4
   *          ddaData[i][10]               status bit "inactive connection" _userbit_5
   *          ddaData[i][11]              source manager                   _manager

   * @param  UserData                     user data mapping
   *          mUserData["dpes"]           data point elements
   *          mUserData["keys"]           keys
   *          mUserData["DRIVER_NUMBER"]  driver number
   * @return  mapping:
   *          ["key"]                     used keys                        dyn_string
   *          ["value"]                   value                            dyn_anytype
   *          ["state"]                   status bits                      dyn_dyn_bool
   *          ["time"]                    timestamp                        dyn_time
   *          ["dpe"]                     DP element name                  dyn_string
   */
  private static dyn_string dsSqAvoidRepeat;

  public static mapping getData(const mapping &mUserData, const dyn_anytype &ddaData)
  {
    mapping mResultData = makeMapping("key", makeDynString(), "value", makeDynAnytype(), "state", makeDynAnytype(),
                                      "time", makeDynTime(), "dpe", makeDynString());

    dyn_string dsDpeSQ;

    int iLen;

    for (int i = dynlen(ddaData); i > 1; i--) //iterate over the result
    {
      //formatDebug(dpid) -> "System1:EB_Int0032. (Type: 234 Sys: 1 Dp: 15205 El: 1 : 0..0)" or if can not convert to dp name "(Type: 234 Sys: 1 Dp: 15205 El: 1 : 0..0)"
      if ( strpos(formatDebug(ddaData[i][1]), "(") == 0 || !dpExists(ddaData[i][1]) ) //to avoid failure at moment of deleting the DPs
      {
        continue;
      }

      string sDpe             = dpSubStr(ddaData[i][1], DPSUB_SYS_DP_EL);

      bool bAddressChecked    = (bool)ddaData[i][3]; // _userbit_2
      bool bAddressOk         = (bool)ddaData[i][4]; // _userbit_3
      bool bDisconnected      = (bool)ddaData[i][9]; // _userbit_4


      string sKey;

      if (mappingHasKey(mUserData, "dpes") && mappingHasKey(mUserData, "keys")) //return also optional given keys
      {
        int iPos = dynContains(mUserData["dpes"], sDpe);
        if (iPos > 0)
        {
          sKey = mUserData["keys"][iPos];
        }
      }

      if ((int) ddaData[i][11] != iMyManId) //_manager != own manager - remove value changes done by own manager to filter out from timeseries
      {
        dynAppend(mResultData["key"], sKey);
        dynAppend(mResultData["value"], ddaData[i][2]);      // value
        dynAppend(mResultData["time"], (time)ddaData[i][8]); // _online.._stime
        dynAppend(mResultData["dpe"], sDpe);
//      performance improvement: create directly status with defined index INVALID_INDEX = 1, BAD_DISCONNECT_INDEX = 2, BAD_CONNECTION_INDEX = 3, INVALID_STIME_INDEX = 4 (_stime_inv)
        mResultData["state"][++iLen] = makeDynBool(bAddressChecked && bAddressOk && !(bool)ddaData[i][6] /*_bad*/, bDisconnected, (bool)ddaData[i][10] /*inactive or not running _userbit_5*/, (bool)ddaData[i][7]);
      }

      //do single query if required, to get a first value for the tag

      if (!bDisconnected && dynContains(dsDpeSQ, sDpe) < 1)
      {
        dynAppend(dsDpeSQ, sDpe); //avoid multiple single query request for same DPE

        // if address not checked yet -> check; if value comes from SQ -> update ok bit; if ok bit ok -> show value
        if ((!bAddressChecked || !bAddressOk)  /* && spTag.getAddress() != ""*/)
        {
          int iDriverNr;
          if (mappingHasKey(mUserData, "DRIVER_NUMBER"))
          {
            iDriverNr = mUserData["DRIVER_NUMBER"];
          }
          else
          {
            iDriverNr = getDriverNumberFromDPE(sDpe);
          }

          int iAvoidSqRepeatIndex = dynContains(dsSqAvoidRepeat, sDpe);
          if (iAvoidSqRepeatIndex > 0)
          {
            dynRemove(dsSqAvoidRepeat, iAvoidSqRepeatIndex);
          }
          else if (iDriverNr > 0)
          {
            if (!bAddressChecked) //to avoid infinite loop
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
        if (!bAddressOk && (bool)ddaData[i][5]) //from single query  _from_SI
        {
          dpSet(sDpe + GenericDriverTag::ADDRESS_OK_BIT, TRUE);
        }
      }
    }
    return mResultData;
  }
 /**
 * @brief get driver number for a DPE by reading from distrib config
 * @param sDPE the datapoint element to search for its related driver number
 * @return 0 if no distrib config found or the driver number
 */
  public static int getDriverNumberFromDPE(const string &sDPE)
  {
    int iNr;

    if (dpExists(sDPE)) //if repeated fast creation and deletion, the dp could have been already deleted
    {
      dpGet(sDPE + ":_distrib.._type", iNr);
      if (iNr != DPCONFIG_NONE)
      {
        dpGet(sDPE + ":_distrib.._driver", iNr);
      }
    }
    return iNr;
  }
};


class DriverApp
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  public static const string DRIVER_NAME           = "GenericDevice";
  public static const bool   CONNECTION_TAG_NEEDED = FALSE;
  public static const string DEVICE_TYPE           = "GenericDevice";

  public static const EBNodeType DEVICE_NODETYPE = EBNodeType::DEVICE;
  public static const EBNodeType TAG_NODETYPE    = EBNodeType::DP;

  public static const int    DRIVER_DEVICE_ID_OFFSET  = 0;                //!< Offset for the '<DeviceId>' setting of the driver config (can also be negative, the abs function is used to get a positive device number)
  public static const int    DRIVER_NUMBER            = 0;
  public static const string DRIVER_IDENTIFIER        = "GenericDevice";  //!< Used as value for '_address.._drv_ident'
  public static const string DRIVER_DEPENDENCY        = "";               //!< Used if a dependency to another driver exists. Examples: ("S7","Sinumerik")
  public static const string DRIVER_PACKAGE_ALTERNATIVE_INIFILE = "";     //!< Only used if .ini file is different from package name ("Sinumerik")
  public static const string CONNECTION_DP_PREFIX     = "_GenericPLC";
  public static const string DRIVER_CONNECTION_DPTYPE = "";
  public static const int    CHECK_DRIVER_DELAY       = 1;                //!< Delay for the checking if the driver is running
  public static const string DRIVER_CERT_PATH         = "";               //!< Path to the certificates of a driver

  public static const mapping mDeviceDetailSource; //e.g. "TYPE", ".ConnectionType" - mapping of property to DPE
  public static const mapping mTagDetailSource;    //e.g. "refreshrate", "_pollgroup", "address", "_refstring" - tag tabel colum vs. config attributes of address
  public static const mapping mTagMetaData;        //tag list column and option information

  public static const dyn_string dsCsvHeaders = makeDynString("active", "tag", "address", "type", "rate","min", "max", "archive", "unit", "format", "desc");

  public static const dyn_string  CONNECTION_STATE_ELEMENTS = makeDynString(".ConnState");    //!< DP elements of the connection dp needed to determine the connection state (in case of multiple element the function 'getConnectionQuality' must be overruled in the derived class)
  public static const dyn_anytype CONNECTION_STATE_OK       = makeDynAnytype((uint)3);               //!< Connection state values, that indicate a connected state
  public static const dyn_anytype CONNECTION_STATE_WARNING  = makeDynAnytype();               //!< Connection state values, that indicate a connection warning
  public static const dyn_string CONNECTION_EXCLUDES; //!< Elements of the driver connection dp, that must NOT be set (for example element for setting/syncing the clock)
  public static const mapping    CONNECTION_VALUES;   //!< Values for the driver connection dp, beside actual values also the place holder "<DeviceId>" can be used for the device number
  public static const string     CONNECTION_CHECK;    //!< Element for the driver connection check
  public static const bool       DRIVER_SUPPORT_HMICONNECTION = TRUE;

  public static const string BROWSE_DPE_REQUEST       = "";          //!< Element for starting the browsing
  public static const string BROWSE_DPE_RESULT_ID     = "";          //!< Element on which to wait for a specific value (request id)
  public static const string BROWSE_DPE_RESULT_STRUCT = ".Browse";   //!< Struct containing the browse result dpes (for example: '.BrowseResults')

  public static const bool   POLLRATE_VIA_TAG         = TRUE;        //!< define that polling is defined per tag and not only per device

  public static const mapping mSettingConversionUItoOA; //!< mapping of UI texts to dp values e.g. makeMapping("plcType", makeMapping("UI", makeDynString("Automatic", "S7 1200"), "OA", makeDynInt( 0, 272)));
  public static int BROWSE_TIMEOUT = 30;

  //------------------------------------------------------------------------------
  /**
   * @brief Default Constructor.
   */
  public DriverApp()
  {
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Creates a new shared pointer instance
   * @return New instance
   */
  public static shared_ptr<DriverApp> createPointer()
  {
    throw(makeError("", PRIO_SEVERE, ERR_IMPL, 54, "Unable to create an instance of the 'abstract' base class", "Implement this function in the derived class"));

    return nullptr;
  }

  public void connectDeviceState(const mapping &mParams, mapping &mResult, shared_ptr<WssClientConnectionContext> spContext, function_ptr fpCallback = nullptr)
  {
    dyn_string dsKeys = mParams[DriverConst::KEYS];
    dyn_string dsDpe;
    mapping mUserData = makeMapping("uuid", mResult[WssConst::UUID]);

    this.setupUserdataForDeviceState(dsKeys, mUserData, dsDpe);

    if (fpCallback != nullptr)
    {
      mUserData["directClientContact"] = fpCallback;
    }

    spContext.customDpConnect(DeviceStateCallBack::getData, mUserData, dsDpe);

    mResult[WssConst::DATA] = TRUE;
  }

  public void disconnectDeviceState(const mapping &mParams, mapping &mResult, shared_ptr<WssClientConnectionContext> spContext)
  {
    dyn_string dsKeys = mParams[DriverConst::KEYS];
    dyn_string dsDpe;
    mapping mUserData = makeMapping("uuid", mParams[WssConst::CONNECTED_UUID]);

    this.setupUserdataForDeviceState(dsKeys, mUserData, dsDpe);

    spContext.customDpDisconnect(DeviceStateCallBack::getData, mUserData, dsDpe);

    mResult[WssConst::DATA] = TRUE;
  }

  private void setupUserdataForDeviceState(const dyn_string &dsKeys, mapping &mUserData, dyn_string &dsDpe)
  {
    for (int i = 1; i <= dynlen(dsKeys); i++)
    {
      string sDpe = EB_getDatapointForTagId(dsKeys[i]);

      if (strpos(sDpe, ".") <= 0)
      {
        sDpe += DPE_DRIVER_STATE;
      }

      dynAppend(dsDpe, sDpe);
    }

    mUserData["keys"] = dsKeys;
  }

  public void connectTagState(const mapping &mParams, mapping &mResult, shared_ptr<WssClientConnectionContext> spContext, function_ptr fpCallback = nullptr)
  {
    dyn_string dsKeys = mParams[DriverConst::KEYS];
    dyn_string dsDpes;
    mapping mUserData = makeMapping("uuid",          mResult[WssConst::UUID],
                                    "dpes",          dsDpes,
                                    "DRIVER_NUMBER", DRIVER_NUMBER);

    if (fpCallback != nullptr)
    {
      mUserData["directClientContact"] = fpCallback;
    }

    spContext.customQueryConnect(TagStateCallBack::getData, mUserData, setupUserdataForTagState(dsKeys, mUserData, dsDpes));

    mResult[WssConst::DATA] = TRUE;
  }

  public void disconnectTagState(const mapping &mParams, mapping &mResult, shared_ptr<WssClientConnectionContext> spContext)
  {
    dyn_string dsKeys = mParams[DriverConst::KEYS];
    dyn_string dsDpe;
    mapping mUserData = makeMapping("uuid", mParams[WssConst::CONNECTED_UUID]);

    setupUserdataForTagState(dsKeys, mUserData, dsDpe);

    spContext.customQueryDisconnect(TagStateCallBack::getData, mUserData);

    mResult[WssConst::DATA] = TRUE;
  }

  private string setupUserdataForTagState(const dyn_string &dsKeys, mapping &mUserData, dyn_string &dsDpe)
  {
    for (int i = 1; i <= dynlen(dsKeys); i++)
    {
      string sDpe = EB_getDatapointForTagId(dsKeys[i]);

      dynAppend(dsDpe, sDpe);
    }
    mUserData["keys"] = dsKeys;
    mUserData["dpes"] = dsDpe;

    return "SELECT '_online.._value,_original.._userbit2,_original.._userbit3,_original.._from_SI,_original.._aut_inv' FROM '{" + dynStringToString(dsDpe, ",") + "}'";
  }

  public void getDeviceList(const mapping &mParams, mapping &mResult)
  {
    dyn_string dsTrees = this.getCnsForApp();
    mapping mUserData;
    dyn_string dsConnectDpe;
    dyn_mapping dmDevice;
    mapping mDevice;

    for (int i = 1; i <= dynlen(dsTrees); i++)
    {
      dyn_string dsChildren;
      langString lsDisplayName;

      cnsGetChildren(dsTrees[i], dsChildren);

      cnsGetDisplayNames(dsTrees[i], lsDisplayName);

      string sDpe = EB_getDatapointForTagId(dsTrees[i]);
      int iState;

      dpGet(sDpe, iState);

      dynAppend(dsConnectDpe, sDpe);

      mUserData[dsTrees[i]] = sDpe;

      mappingClear(mDevice);

      mDevice[DriverConst::DEVICE_KEY] = dsTrees[i];
      mDevice[DriverConst::NAME] = EB_LangStringToMapping(lsDisplayName);
      mDevice[DriverConst::STATE] = iState;
      mDevice[DriverConst::TAG_COUNT] = dynlen(dsChildren);
      anytype aExtra;
      if (cnsGetProperty(dsTrees[i], "extra", aExtra) )
      {
        mDevice[DriverConst::EXTRADATA] = aExtra;
      }

      dynAppend(dmDevice, mDevice);
    }

    mResult[WssConst::DATA] = dmDevice;
  }

  public void getDeviceMetaData(const mapping &mParams, mapping &mResult)
  {
    mResult[WssConst::DATA] = makeMapping("deviceMetaData", mDeviceMetaData, "defaultDevice", mDefaultDevice);
  }

  public void getDeviceTags(const mapping &mParams, mapping &mResult)
  {
    mResult[WssConst::DATA] = this.getTagsForDevice(mParams[DriverConst::DEVICE_KEY]);
  }

  public void getDeviceDetail(const mapping &mParams, mapping &mResult)
  {
    mResult[WssConst::DATA] = this.fillDeviceDetail(mParams[DriverConst::DEVICE_KEY]);
  }

  public void getDevice(const mapping &mParams, mapping &mResult)
  {
    string  sDeviceKey = mParams.value(DriverConst::DEVICE_KEY, "");
    mapping mIn, mOut;

    getDeviceList(mIn, mOut);
    for (int i=dynlen(mOut[WssConst::DATA]); i>0; i--)
    {
      if (mappingHasKey(mParams, DriverConst::EXTRADATA) && mappingHasKey(mOut[WssConst::DATA][i], DriverConst::EXTRADATA) &&
          (mParams[DriverConst::EXTRADATA] == mOut[WssConst::DATA][i][DriverConst::EXTRADATA]) ||
           sDeviceKey == mOut[WssConst::DATA][i][DriverConst::DEVICE_KEY])
      {
        mResult = mOut[WssConst::DATA][i];
        return;
      }
    }
    return;
  }

  public void addDevice(const mapping &mParams, mapping &mResult)
  {
    langString lsName        = getType(mParams[DriverConst::NAME]) == MAPPING_VAR ? EB_mappingToLangString(mParams[DriverConst::NAME]) : mParams[DriverConst::NAME];
    langString lsLocation    = EB_mappingToLangString(mParams[DriverConst::LOCATION]);
    langString lsDescription = EB_mappingToLangString(mParams[DriverConst::DESCRIPTION]);
    dyn_string dsCerts       = mappingHasKey(mParams, DriverConst::CERTIFICATES) ? mParams[DriverConst::CERTIFICATES] : makeDynString();
    string     sAddress      = mParams[DriverConst::IPADDRESS];
    string     sDeviceLogId  = mParams.value(DriverConst::DEVICE_KEY, "");
    bool bRunning            = FALSE;
    string sName, sManager   = getProcessName();
    int iState;
    int gTcpFileDescriptor, gTcpFileDescriptor2, tcpOpenRc, iPmonPort = paCfgReadValueDflt(getPath(CONFIG_REL_PATH, "config"), "general", "pmonPort", 4999);;
    dyn_string gParams;
    dyn_dyn_string ddsResult, ddsResult2;
    bool err, errList1, errList2;
    string sProjUser = "", sProjPassword = "", projectName = "project", gTcpFifo;


    mapping mFoundDevice;
    getDevice(mParams, mFoundDevice);
    bool bDevicExists = mappinglen(mFoundDevice);

    if (bDevicExists) //update device if it already exists
    {
      mapping mDeviceCopy = mParams;
      if (mappingHasKey(mFoundDevice, DriverConst::EXTRADATA))
        mDeviceCopy[DriverConst::EXTRADATA] = mFoundDevice[DriverConst::EXTRADATA];
      mDeviceCopy[DriverConst::DEVICE_KEY] = mFoundDevice[DriverConst::DEVICE_KEY];

      DebugFTN(DriverConst::DEBUG_DEVICE, "device addDevice -> device found -> modify device", lsName, "old:", mDeviceCopy, mParams);
      modifyDevice(mDeviceCopy, mResult);
    }
    else
    {
      DebugFTN(DriverConst::DEBUG_DEVICE, "device addDevice -> device nof found -> create device", lsName, mParams);
    }

    initHosts();

    if (mappingHasKey(mParams, DriverConst::EXTRADATA))
    {
      sDeviceLogId = mParams[DriverConst::EXTRADATA];
    }

    string sAppToInit = DRIVER_NAME;
    if (DRIVER_PACKAGE_ALTERNATIVE_INIFILE != "")
    {
      sAppToInit = DRIVER_PACKAGE_ALTERNATIVE_INIFILE;
    }

    bool bRunning = isDbgFlag(DriverConst::DEBUG_NO_ADD_REMOVE_MAN) || isManagerRunning(host1, sManager);

    if (!bRunning)
    {
      string sSourceDriverName      = getPath(SOURCE_REL_PATH, "packages" + "/" + "EB_Package_" + sAppToInit + ".ini");
      string sDestinationDriverName = getPath(DATA_REL_PATH, "packages/") + "EB_Package_" + sAppToInit + ".ini";

      //already exists, but driver has not been started - remove file and add again to trigger add driver script again
      if (isfile(sDestinationDriverName))
      {
        remove(sDestinationDriverName);

        if (globalExists("g_fileRefeshNotificationDPE"))
        {
          dpSet(g_fileRefeshNotificationDPE, TRUE);
        }
      }

      copyFile(sSourceDriverName, sDestinationDriverName);

      if (globalExists("g_fileRefeshNotificationDPE"))
      {
        dpSet(g_fileRefeshNotificationDPE, TRUE);
      }

      int iCount = 30;

      //Check if driver is in running state within 30 seconds
      while (!bRunning && iCount > 0)
      {
        delay(CHECK_DRIVER_DELAY);
        iCount--;
        if (bRunning = isManagerRunning(host1, sManager))
        {
          // The driver is running, so remove the installation failure log
          logClear(LogCategory::Update, Logging::DRIVER_INSTALL_FAILED);
        }
      }

      // wait with creation of tags
      delay(1);

      //If driver was not sucessfully started within 30seconds create a log entry
      if (!bRunning && iCount == 0)
      {
        mResult["errorReason"] = EB_UtilsCommon::getCatString(DRIVER_NAME, "driverNotRunning");
        mResult["errorCode"]   = 0;

        logWrite(LogCategory::Update, Logging::DRIVER_INSTALL_FAILED, LogSeverity::Error, makeDynAnytype(DRIVER_NAME));
        logWrite(LogCategory::Configuration, Logging::MANAGER_FAILURE_START, LogSeverity::Warning, makeDynAnytype(DRIVER_NAME));
      }
      else
      {
        logWrite(LogCategory::Update, Logging::DRIVER_INSTALL_SUCCESS, LogSeverity::Information, makeDynAnytype(DRIVER_NAME));
      }
    }

    if (bRunning)
    {
      //copy for safety in case of update of dpl
      string sSourceDriverName      = getPath(SOURCE_REL_PATH, "packages/" + "EB_Package_" + sAppToInit + ".ini");
      string sDestinationDriverName = getPath(DATA_REL_PATH, "packages/")  + "EB_Package_" + sAppToInit + ".ini";

      copyFile(sSourceDriverName, sDestinationDriverName);

      if (globalExists("g_fileRefeshNotificationDPE"))
      {
        dpSet(g_fileRefeshNotificationDPE, TRUE);
      }

      string sDeviceKey;
      if (!bDevicExists)
      {
        preCreateDeviceDp(lsName, lsLocation, lsDescription, sAddress, mParams);

        sDeviceKey = this.createDeviceDp(lsName, EBNodeType::DEVICE);

        if (mappingHasKey(mParams, DriverConst::EXTRADATA))
        {
          cnsSetProperty(sDeviceKey, "extra", mParams[DriverConst::EXTRADATA]);
        }

        postCreateDeviceDp(sDeviceKey, lsName, lsLocation, lsDescription, sAddress, mParams);

        updateDeviceDp(sDeviceKey, lsName, lsLocation, lsDescription, sAddress, mParams);
        postUpdateDeviceDp(sDeviceKey, lsName, lsLocation, lsDescription, sAddress, mParams);

        mResult[WssConst::DATA] = this.fillDeviceDetail(sDeviceKey);
      }
      else
      {
        sDeviceKey = mResult[WssConst::DATA][DriverConst::DEVICE_KEY];
      }

      //include certificates for drivers that support them
      if (dynlen(dsCerts) > 0)
      {
        string sDataSourceId = mappingHasKey(mParams, DriverConst::EXTRADATA) ? mParams[DriverConst::EXTRADATA] : sDeviceKey;
        this.certHandling(sDataSourceId, dsCerts);
      }

      logWrite(LogCategory::Configuration, Logging::DEVICE_CREATE_SUCCESS, LogSeverity::Information, makeDynAnytype(DRIVER_NAME, lsName, getDeviceId(sDeviceKey, FALSE)), getDeviceId(sDeviceKey, FALSE));
    }
    else
    {
      logWrite(LogCategory::Configuration, Logging::DEVICE_CREATE_FAILED, LogSeverity::Error, makeDynAnytype(DRIVER_NAME, lsName));
    }
  }

  public void modifyDevice(const mapping &mParams, mapping &mResult)
  {
    string     sDeviceKey    = mParams[DriverConst::DEVICE_KEY];
    langString lsName        = mParams[DriverConst::NAME];
    langString lsLocation    = mParams[DriverConst::LOCATION];
    langString lsDescription = mParams[DriverConst::DESCRIPTION];
    string     sAddress      = mParams[DriverConst::IPADDRESS];
    dyn_string dsCerts       = mappingHasKey(mParams, DriverConst::CERTIFICATES) ? mParams[DriverConst::CERTIFICATES] : makeDynString();


    //include certificates for drivers that support them - add/update/delete certificates
    string sDataSourceId = mappingHasKey(mParams, DriverConst::EXTRADATA) ? mParams[DriverConst::EXTRADATA] : sDeviceKey;
    this.certHandling(sDataSourceId, dsCerts);

    preUpdateDeviceDp(lsName, lsLocation, lsDescription, sAddress, mParams);
    changeDeviceName(sDeviceKey, lsName);
    updateDeviceDp(sDeviceKey, lsName, lsLocation, lsDescription, sAddress, mParams);
    postUpdateDeviceDp(sDeviceKey, lsName, lsLocation, lsDescription, sAddress, mParams);

    mResult[WssConst::DATA] = fillDeviceDetail(sDeviceKey);
  }

  public void deleteDevice(const mapping &mParams, mapping &mResult)
  {
    string  sDeviceKey    = mParams[DriverConst::DEVICE_KEY];
    string  sDeviceId     = getDeviceId(sDeviceKey, FALSE);
    string  sDataSourceId = mappingHasKey(mParams, DriverConst::EXTRADATA) ? mParams[DriverConst::EXTRADATA] : sDeviceKey;
    mapping mTmpParams    = updateParamsForDeviceDeletion(mParams);

    preDeleteDeviceDp(sDeviceKey, mTmpParams);
    deleteDeviceDp(sDeviceKey, mTmpParams);
    postDeleteDeviceDp(sDeviceKey, mTmpParams);

    // Clear all pending logs of the device
    logClearAll("*", sDeviceId);

    mResult[WssConst::DATA] = TRUE;

    //delete certificates for drivers
    this.certHandling(sDataSourceId, makeDynString());

    string sAppToRemove = DRIVER_NAME;

    if (DRIVER_PACKAGE_ALTERNATIVE_INIFILE != "")
    {
      sAppToRemove = DRIVER_PACKAGE_ALTERNATIVE_INIFILE;
    }

    //check if driver has dependend drivers remove both only if both cnsviews are empty
    if (dynlen(EB_getChildNodeIds(".EB_Package_" + DRIVER_NAME + ":")) <= 1 &&
       (DRIVER_DEPENDENCY == "" || dynlen(EB_getChildNodeIds(".EB_Package_" + DRIVER_DEPENDENCY + ":")) <= 1))
    {
      string sFileDriverName = getPath(DATA_REL_PATH, "packages/EB_Package_" + sAppToRemove + ".ini");

      remove(sFileDriverName);

      if (globalExists("g_fileRefeshNotificationDPE"))
      {
        dpSet(g_fileRefeshNotificationDPE, TRUE);
      }

      // Clear all pending logs of this driver
      logClearAll("*");

      string sManager = getProcessName();

      initHosts();

      // Try to stop manager within 30 sec (120 * 0.250)
      int i = 120;
      for (; !isDbgFlag(DriverConst::DEBUG_NO_ADD_REMOVE_MAN) && isManagerRunning(host1, sManager, FALSE) && i > 0; i--)
      {
        delay(0, 250);
      }
      if ( i == 0 ) //could not stop manager!
      {
        logWrite(LogCategory::Configuration, Logging::MANAGER_FAILURE_STOP, LogSeverity::Warning, makeDynAnytype(DRIVER_NAME));
      }
    }
  }

  public void addTag(const mapping &mParams, mapping &mResult)
  {
    string     sDeviceKey    = mParams[DriverConst::DEVICE_KEY];
    langString lsName        = EB_mappingToLangString(mParams[DriverConst::NAME]);
    langString lsDescription = EB_mappingToLangString(mParams[DriverConst::DESCRIPTION]);
    string     sAddress      = mParams[DriverConst::ADDRESS];
    EBTagType  tagType       = EB_getEnumValueForText("EBTagType", mParams[DriverConst::DATATYPE]);

    string     sRefreshRate    = mParams[DriverConst::POLLRATE];
    bool       bActive         = mParams[DriverConst::ACTIVE];
    bool       bArchive        = mParams[DriverConst::ARCHIVE];
    string     sFormat         = mParams[DriverConst::FORMAT];
    langString lsUnit          = EB_mappingToLangString(mParams[DriverConst::UNIT]);
    int        iTransformation = mParams[DriverConst::TRANSFORMATION];

    int    iDirection                    = mappingHasKey(mParams, DriverConst::DIRECTION)                        ? (int)mParams[DriverConst::DIRECTION]                   : DPATTR_ADDR_MODE_INPUT_POLL;
    string sConnectionAttributeOnAddress = mappingHasKey(mParams, DriverConst::CONNECTION_ATTRIBUTES_ON_ADDRESS) ? mParams[DriverConst::CONNECTION_ATTRIBUTES_ON_ADDRESS] : "";
    uint   uSubindex                     = mappingHasKey(mParams, DriverConst::SUBINDEX)                         ? (uint)mParams[DriverConst::SUBINDEX]                   : 0u;
    bool   bLowLevelFilter               = mappingHasKey(mParams, DriverConst::LOW_LEVEL_FILTER)                 ? (bool)mParams[DriverConst::LOW_LEVEL_FILTER]           : TRUE;
    float  fSmoothingAbsolute            = mappingHasKey(mParams, DriverConst::SMOOTHING_ABSOLUTE)               ? (float)mParams[DriverConst::SMOOTHING_ABSOLUTE]         : 0.0;
    bool   bAllowDuplicateTagNames       = mappingHasKey(mParams, DriverConst::ALLOW_DUPLICATE_TAGNAMES)         ? (bool)mParams[DriverConst::ALLOW_DUPLICATE_TAGNAMES]   : FALSE;

    // Correct the direction for subscribing drivers
    if (useSubscriptions())
    {
      switch (iDirection)
      {
        case DPATTR_ADDR_MODE_INPUT_POLL: iDirection = DPATTR_ADDR_MODE_INPUT_SPONT; break;
        case DPATTR_ADDR_MODE_IO_POLL:    iDirection = DPATTR_ADDR_MODE_IO_SPONT;    break;
      }
    }

    this.preCreateTagDp(sDeviceKey, lsDescription, sAddress, tagType, sRefreshRate, bActive, bArchive,
                        sFormat, lsUnit, iTransformation, iDirection, sConnectionAttributeOnAddress, uSubindex, mParams);

    string sTagKey = this.createTagDp(sDeviceKey, lsName, TAG_NODETYPE, tagType, bAllowDuplicateTagNames);

    if (sTagKey != "")
    {
      this.updateTagDp(sDeviceKey, sTagKey, lsDescription, sAddress, tagType, sRefreshRate, bActive, bArchive,
                       sFormat, lsUnit, iTransformation, iDirection, sConnectionAttributeOnAddress, uSubindex, bLowLevelFilter, fSmoothingAbsolute);

      this.postCreateTagDp(sDeviceKey, sTagKey, lsDescription, sAddress, tagType, sRefreshRate, bActive, bArchive,
                       sFormat, lsUnit, iTransformation, iDirection, sConnectionAttributeOnAddress, uSubindex, mParams);

      // Give the system some time to process the changes before reading the tag details from the system
      for (int i = 1; i <= 10 && !dpExists(sTagKey); i++)
      {
        delay(0, 100);
      }

      mResult[WssConst::DATA] = this.getTagDetail(sTagKey);
    }
    else
    {
      mResult[WssConst::DATA] = makeMapping();
    }
  }

  public void deleteTag(const mapping &mParams, mapping &mResult)
  {
    this.deleteTagDp(mParams[DriverConst::TAG_KEY]);
  }

  public void importTags(const mapping &mParams, mapping &mResult)
  {
    this.importTagsFromFileContent(mParams, mResult);
  }

  public void importTagsFromFileContent(const mapping &mParams, mapping &mResult)
  {
    dyn_mapping dmData;
    dyn_int diRc;

    if (mParams[DriverConst::FILETYPE] == "XML")
    {
      shared_ptr<EBXml> spEbXml = new EBXml("Tag");
      bool bRet = spEbXml.read(mParams[DriverConst::DEVICE_KEY], mParams[DriverConst::DATA], dmData, FALSE);
      if (!bRet)
      {
        diRc = makeDynInt(1);
      }
    }
    else
    {
      shared_ptr<EBCsv> spEbCsv = new EBCsv();
      spEbCsv.setNeededColumns(dsCsvHeaders);
      diRc = spEbCsv.read(mParams[DriverConst::DEVICE_KEY], mParams[DriverConst::DATA], dmData, FALSE);
    }

    if (dynlen(diRc) == 0 && dynlen(dmData) == 0)
    {
      mResult["errorReason"] = EB_UtilsCommon::getCatString(DRIVER_NAME, "importEmpty");
      mResult["errorCode"] = 0;
//       EB_openDialogWarning(EB_UtilsCommon::getCatString(g_spCommon.getAppName(), "importEmpty"), "", "close", "EB_Package_" + g_sAppName + "/ImportError" + dsReturnValues[2] + ".html");
      return;
    }
    else if (dynlen(diRc) != 0)
    {
      // Limit the number of lines with errors
      while (dynlen(diRc) > ERROR_LINES)
      {
        dynRemove(diRc, dynlen(diRc));
      }

//       EB_openDialogWarning(EB_UtilsCommon::getCatString(g_spCommon.getAppName(), "importFailed") + dynStringToString(diRc, ","), "", "close", "EB_Package_" + g_sAppName + "/ImportError" + dsReturnValues[2] + ".html");
      mResult["errorReason"] = EB_UtilsCommon::getCatString(DRIVER_NAME, "importFailed") + dynStringToString(diRc, ",");
      mResult["errorCode"] = 1;
      return;
    }

    string sTagPrefix  = mappingHasKey(mParams, DriverConst::TAGPREFIX)  ? mParams[DriverConst::TAGPREFIX]  : "";
    string sTagPostfix = mappingHasKey(mParams, DriverConst::TAGPOSTFIX) ? mParams[DriverConst::TAGPOSTFIX] : "";

    for (int i = 1; i <= dynlen(dmData); i++)
    {
      string sTagName = sTagPrefix + dmData[i]["name"] + sTagPostfix;
      int iPostfix;

      bool bOk = EBTag::isNameOk(sTagName, mParams[DriverConst::DEVICE_KEY]);

      if (!bOk)
      {
        for (; !bOk && iPostfix<100; iPostfix++)
        {
          bOk = EBTag::isNameOk(sTagName+iPostfix, mParams[DriverConst::DEVICE_KEY]);
        }

        sTagName += iPostfix;

        dyn_string dsFailure;

        if (mappingHasKey(dmData[i], "__failure__") ) //mark tag name was corrected
        {
          dynAppend(dmData[i]["__failure__"], "name");
        }
        else
        {
          dmData[i]["__failure__"] = makeDynString("name");
        }
      }

      if (dmData[i]["name"] != sTagName)
      {
        dmData[i]["name"] = sTagName;
      }
    }

    mResult[DriverConst::DATA] = dmData;
  }

  public void exportTags(const mapping &mParams, mapping &mResult)
  {
    DebugTN("tag export", mParams[DriverConst::TAG_KEY], mParams);
//     this.deleteTagDp(mParams[DriverConst::TAG_KEY]);
  }

  //add parameter for ignore delete
  public void modifyTags(const mapping &mParams, mapping &mResult)
  {
    dyn_mapping dmAddResult, dmDelResult, dmEditResult;
    mapping mDeviceDetails;

    if (dynlen(mParams[WssConst::DATA]) > 0)
    {
      mapping mDevice = makeMapping(DriverConst::DEVICE_KEY, mParams[WssConst::DATA][1][DriverConst::DEVICE_KEY]);
      bool bRemoveObsoleteTags = mappingHasKey(mParams[WssConst::DATA][1], DriverConst::OPTION_DELETEOBSOLETETAGS) && mParams[WssConst::DATA][1][DriverConst::OPTION_DELETEOBSOLETETAGS];
      bool bJustRemoveAllTags;

      if (bRemoveObsoleteTags && mappinglen(mParams[WssConst::DATA][1]) == 2) //only device key -> means delete all tags
      {
        bJustRemoveAllTags = TRUE;
      }

      mapping mSavedTags;
      getDeviceTags(mDevice, mSavedTags);

      int iNrSavedTags = dynlen(mSavedTags[WssConst::DATA]);

      dyn_string dsKeys;

      if (iNrSavedTags > 0)
      {
        dsKeys = mappingKeys(mSavedTags[WssConst::DATA][1]);

        // delete tags, which have been removed
        if (bRemoveObsoleteTags)
        {
          for (int i = dynlen(mSavedTags[WssConst::DATA]); i > 0; i--)
          {
            bool bFound = FALSE;

            for (int j=dynlen(mParams[WssConst::DATA]); j > 0 && !bFound && !bJustRemoveAllTags; j--)
            {
              if (mappingHasKey(mParams[WssConst::DATA][j], DriverConst::TAG_KEY) && mSavedTags[WssConst::DATA][i][DriverConst::TAG_KEY] == mParams[WssConst::DATA][j][DriverConst::TAG_KEY])
              {
                bFound = TRUE;
              }
            }
            if (!bFound) //delete tag
            {
              mapping mRes;

              this.deleteTag(mSavedTags[WssConst::DATA][i], mRes);

              mRes[DriverConst::TAG_KEY] = mSavedTags[WssConst::DATA][i][DriverConst::TAG_KEY];

              dynAppend(dmDelResult, mRes);
              dynRemove(mSavedTags[WssConst::DATA], i);
            }
          }
        }
      }
      for (int i = dynlen(mParams[WssConst::DATA]); i > 0 && !bJustRemoveAllTags; i--)
      {
        bool bTagFound;
        string sConnAttr = mappingHasKey(mParams[WssConst::DATA][i], DriverConst::CONNECTION_ATTRIBUTES_ON_ADDRESS) ? mParams[WssConst::DATA][i][DriverConst::CONNECTION_ATTRIBUTES_ON_ADDRESS] : getConnectionattribute(mParams[WssConst::DATA][i]);

        //check, what has been changed
        for (int j = dynlen(mSavedTags[WssConst::DATA]); j > 0; j--)
        {
          if (mSavedTags[WssConst::DATA][j][DriverConst::TAG_KEY] == mParams[WssConst::DATA][i][DriverConst::TAG_KEY])
          {
            bTagFound = TRUE;

            bool bTagTypChanged;
            bool bAnyChange;
            bool bTagNameChanged;
            int  iDirection = mappingHasKey(mParams[WssConst::DATA][i], DriverConst::DIRECTION) ? (int)mParams[WssConst::DATA][i][DriverConst::DIRECTION] : DPATTR_ADDR_MODE_INPUT_POLL;

            for (int k = dynlen(dsKeys); k > 0 && !bTagTypChanged; k--) //check where are the differences
            {
              if (dsKeys[k] == DriverConst::DATATYPE && mSavedTags[WssConst::DATA][j][DriverConst::DATATYPE] != mParams[WssConst::DATA][i][DriverConst::DATATYPE])
              {
                bTagTypChanged = TRUE;
              }
              else if (dsKeys[k] == DriverConst::NAME && mSavedTags[WssConst::DATA][j][DriverConst::NAME] != mParams[WssConst::DATA][i][DriverConst::NAME])
              {
                bTagNameChanged = TRUE;
              }
              else if (mSavedTags[WssConst::DATA][j][dsKeys[k]] != mParams[WssConst::DATA][i][dsKeys[k]])
              {
                bAnyChange = TRUE;
              }
            }

            bAnyChange = bAnyChange && bTagNameChanged;

            if (bTagTypChanged)
            {
              mapping mRes;
              mapping mAddRes;

              deleteTag(mSavedTags[WssConst::DATA][j], mRes);

              mRes[DriverConst::TAG_KEY] = mSavedTags[WssConst::DATA][j][DriverConst::TAG_KEY];

              dynAppend(dmDelResult, mRes);

              mapping mNewTag  = mParams[WssConst::DATA][i];
              mNewTag[DriverConst::DIRECTION] = iDirection;
              addTag(mNewTag, mAddRes);

              mAddRes[WssConst::DATA][DriverConst::TAG_KEY_REPLACED] = mSavedTags[WssConst::DATA][j][DriverConst::TAG_KEY]; //save old tag key

              if (mappingHasKey(mParams[WssConst::DATA][i], DriverConst::EXTRADATA))
              {
                //e.g for id mapping
                mAddRes[WssConst::DATA][DriverConst::EXTRADATA] = mParams[WssConst::DATA][i][DriverConst::EXTRADATA];
              }

              dynAppend(dmAddResult, mAddRes[WssConst::DATA]);
            }
            else
            {
              //if tag name has been changed
              if (bTagNameChanged)
              {
                this.changeTagName(mParams[WssConst::DATA][i][DriverConst::TAG_KEY], EB_mappingToLangString(mParams[WssConst::DATA][i][DriverConst::NAME]),
                                   mappingHasKey(mParams[WssConst::DATA][i], DriverConst::ALLOW_DUPLICATE_TAGNAMES) ? (bool)mParams[WssConst::DATA][i][DriverConst::ALLOW_DUPLICATE_TAGNAMES]  : FALSE);
              }

              if (bAnyChange)
              {
                this.updateTagDp(mParams[WssConst::DATA][i][DriverConst::DEVICE_KEY], mParams[WssConst::DATA][i][DriverConst::TAG_KEY], EB_mappingToLangString(mParams[WssConst::DATA][i][DriverConst::DESCRIPTION]),
                                 mParams[WssConst::DATA][i][DriverConst::ADDRESS], (EBTagType) EB_getEnumValueForText("EBTagType", mParams[WssConst::DATA][i][DriverConst::DATATYPE]),
                                 mParams[WssConst::DATA][i][DriverConst::POLLRATE], mParams[WssConst::DATA][i][DriverConst::ACTIVE], mParams[WssConst::DATA][i][DriverConst::ARCHIVE],
                                 mParams[WssConst::DATA][i][DriverConst::FORMAT], EB_mappingToLangString(mParams[WssConst::DATA][i][DriverConst::UNIT]), mParams[WssConst::DATA][i][DriverConst::TRANSFORMATION],
                                 iDirection,
                                 sConnAttr,
                                 mappingHasKey(mParams[WssConst::DATA][i], DriverConst::SUBINDEX)                         ? (uint)mParams[WssConst::DATA][i][DriverConst::SUBINDEX]                   : 0u,
                                 mappingHasKey(mParams[WssConst::DATA][i], DriverConst::LOW_LEVEL_FILTER)                 ? (bool)mParams[WssConst::DATA][i][DriverConst::LOW_LEVEL_FILTER]           : TRUE,
                                 mappingHasKey(mParams[WssConst::DATA][i], DriverConst::SMOOTHING_ABSOLUTE)               ? (float)mParams[WssConst::DATA][i][DriverConst::SMOOTHING_ABSOLUTE]        : 0.0);
       //toDo: +single query wenn refstring geändert
                dynAppend(dmEditResult, mParams[WssConst::DATA][i]);
              }
            }
            j = 0;
          }
        }

        if (!bTagFound) // create tag
        {
          mapping mAddRes;

          if (mappinglen(mDeviceDetails) == 0)
          {
            mDeviceDetails = fillDeviceDetail(mDevice[DriverConst::DEVICE_KEY]);
          }
          //if connection attribute comes from driver implementation
          if (sConnAttr != "" && !mappingHasKey(mParams[WssConst::DATA][i], DriverConst::CONNECTION_ATTRIBUTES_ON_ADDRESS))
          {
            mapping mNewTag  = mParams[WssConst::DATA][i];
            mNewTag[DriverConst::CONNECTION_ATTRIBUTES_ON_ADDRESS] = sConnAttr;
            addTag(mNewTag, mAddRes);
          }
          else
          {
            addTag(mParams[WssConst::DATA][i], mAddRes);
          }

          if (mappingHasKey(mParams[WssConst::DATA][i], DriverConst::EXTRADATA)) //e.g for id mapping
          {
            mAddRes[WssConst::DATA][DriverConst::EXTRADATA] = mParams[WssConst::DATA][i][DriverConst::EXTRADATA];
          }

          dynAppend(dmAddResult, mAddRes[WssConst::DATA]);
        }
      }
    }

    mResult[WssConst::DATA] = makeMapping("add", dmAddResult, "del", dmDelResult, "edit", dmEditResult);
  }

  public int getTransformation(const string &sReference, const string &sType)
  {
    return 0;
  }

  /**
   * @brief Starts the logging for this driver
   */
  public void logInit()
  {
    int gTcpFileDescriptor, gTcpFileDescriptor2;
    string gTcpFifo;

    initHosts();

    if (isManagerRunning(host1, getProcessName()))
    {
      logWrite(LogCategory::Update, Logging::DRIVER_INSTALL_SUCCESS, LogSeverity::Information, makeDynAnytype(DRIVER_NAME));
    }
  }

  /**
   * @brief Starts the connection state query connect
   * @param fpCallback  Function to call on updates
   * @return TRUE if started, otherwise FALSE
   */
  public bool startConnectionStateLogging(function_ptr fpCallback)
  {
    int iReturn = dpQueryConnectSingle(this.connectionStateCB, TRUE, fpCallback, getConnectionStateQuery(), 1000);
    DebugFTN(DriverConst::DEBUG_DEVICE, "device connection state: startConnectionStateLogging", fpCallback, getConnectionStateQuery(), iReturn);
    dyn_errClass deErrors = getLastError();

    if (iReturn != 0 || dynlen(deErrors) > 0)
    {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 54, __FUNCTION__ + "(...) Query connect failed for query:", getConnectionStateQuery(), iReturn));
    }

    return iReturn == 0;
  }

  /**
   * @brief Stops the connection state connect
   * @return TRUE if stopped, otherwise FALSE
   */
  public bool stopConnectionStateLogging()
  {
    return 0 == dpQueryDisconnect(this.connectionStateCB, TRUE, fpCallback);
  }

  /**
   * @brief Creates a new log for this driver
   * @param sEntryType            DPE leaf for the log (Runtime, Configuration, Internet, Periphery, Update)
   * @param sEntryReason          reason for the log (e.g. IP, Port, Device, ...)
   * @param lsEntryText           multi lingual text of the log entry (or sEntryTextKey will be used to get text from message catalogue)
   * @param iEntryType            type/priority of the log entry -> part of the alarm class
   * @param sMsgKey               message catalog entry key of log message - will be searched in "EB_Package_<AppName>" and "EB_Package" cat file
   * @param mReplacePlaceholders  keys to be replaced in text e.g. $1:15, $2:287
   * @param bPending              if false, the logs will set to CAME and WENT immediately
   * @param bForce                if true, a possibility existing log with specific reason (but with different log text) will be removed (WENT) and a new log will be created
   */
  public void logAdd(const string &sEntryType, const string &sReason, const langString &lsText, int iEntryType, const string &sMsgKey, const mapping &mReplacePlaceholders, bool bPending = FALSE, bool bForce = FALSE)
  {
    throwError(makeError("", PRIO_WARNING, ERR_SYSTEM, 54, "Using deprecated function: " + __FUNCTION__ + ", use 'Logging::write' instead", getStackTrace()));
  }

  /**
   * @brief Removes all pending logs for this driver matching the specified reason
   * @param sEntryType  DPE leaf for the log (Runtime, Configuration, Internet, Periphery, Update)
   * @param sReason     pattern key for the the log entry (also required for removing the log entry)
   */
  public void logRemoveAllPending(const string &sEntryType, const string &sReason)
  {
    throwError(makeError("", PRIO_WARNING, ERR_SYSTEM, 54, "Using deprecated function: " + __FUNCTION__ + ", use 'Logging::clear' instead", getStackTrace()));
  }

  /**
   * @brief Returns the name of this driver
   * @return Driver name
   */
  public string getDriverName()
  {
    return DRIVER_NAME;
  }

  /**
   * @brief Returns the manager number of this driver
   * @return Driver number
   */
  public int getDriverNumber()
  {
    return DRIVER_NUMBER;
  }

  /**
   * @brief Returns the manager view of this driver
   * @return Driver CNS view
   */
  public string getView()
  {
    dyn_string dsTrees;
    dyn_string dsViews;
    string sSystemName = strrtrim(getSystemName(), ":");

    cnsGetViews(sSystemName, dsViews);

    int iPos = dynContains(dsViews, sSystemName + ".EB_Package_" + DRIVER_NAME + ":");

    if (iPos > 0)
    {
      return dsViews[iPos];
    }

    return "";
  }

  /**
   * @brief Returns the device number of the specified device node
   * @param sDeviceKey  CNS Node of the device
   * @return Device number of the specified device node OR the next deviceId if no dpe is linked
   */
  public string getDeviceId(const string &sDeviceKey, bool bNewId = TRUE)
  {
    string sOutput;

    cnsGetId(sDeviceKey, sOutput);
//DebugTN("sOutput",sOutput,"bNewId",bNewId,"sDeviceKey2",sDeviceKey);
    if (sOutput == "" && bNewId)
    {
      return (string)this.getNextDeviceId(sDeviceKey);
    }

    strreplace(sOutput, getSystemName() + DRIVER_NAME + this.SEPARATOR, "");
     // DebugTN("strreplace",sOutput, getSystemName() + DRIVER_NAME + this.SEPARATOR, "");
    int iPos = strpos(sOutput, ".");

    if (iPos > 0)
    {

      sOutput = substr(sOutput, 0, iPos);
    //  DebugTN("sOutput",sOutput,"iPos",iPos);
    }

    return sOutput;
  }

  /**
   * @brief Returns the value for the browse request
   * @param sDeviceKey                 device key
   * @param sFilter                    filter pattern
   * @param iStart                     result start index
   * @param iMaxResultRows             max number of lines before splitting browsing result
   * @param sParent                    parent start node
   * @param bBrowseAllSubNodes         brows all sub nodes, or just first level
   * @return Browse request value
   */
  public dyn_mapping getBrowseTree(const string &sDeviceId, const string &sFilter, int iStart, int iCount, const string &sParent, bool bBrowseAllSubNodes)
  {
    dyn_mapping dmRes;
    mapping mResult;
    this.browse(sDeviceId, sFilter, iStart, iCount, sParent, mResult);
    if (mappingHasKey(mResult, WssConst::DATA))
    {
      vector<BrowseItem> vBrowsItems = mResult[WssConst::DATA];

      for (int i = 0; i < vBrowsItems.count(); i++)
      {
        BrowseItem bi = vBrowsItems.at(i);
        mapping mData;// = dmData[i];
        mData["name"]=bi.name;
        mData["type"]=(int)bi.type;
        mData["address"]=bi.address;
        mData["extras"]=bi.extras;
        if (bi.transformation != "") //optional key (mtConnect does not support transformations)
        {
          mData["transformation"] = bi.transformation;
        }
        mData["writeable"]=bi.writeable;

        if(bi.type == EBTagType::NONE/* && strpos(bi["address"],"dbUN01_OMACPackTags") == 0*/)
        {
          if (bBrowseAllSubNodes)
          {
            string sNewParent = bi.address;
            mData["children"] = this.getBrowseTree(sDeviceId, sFilter, iStart, iCount, sNewParent, bBrowseAllSubNodes);
          }
          else
          {
            mData["children"] = makeMapping();
          }
        }
        mData["tagtype"] = EB_getEnumTextForValue("EBTagType", (int)bi.type);
        dmRes.append(mData);
      }
    }
    return dmRes;
  }

  /**
   * @brief Returns the value for the browse request
   * @param sDeviceKey                 device key
   * @param sFilter                    filter pattern
   * @param iStart                     result start index
   * @param iMaxResultRows             max number of lines before splitting browsing result
   * @param sParent                    parent start node
   * @param mBrowsingResult            out parameter with Browse request value
   */
  private void browse(const string &sDeviceKey, const string &sFilter, int iStart, int iMaxResultRows, const string &sParent, mapping &mBrowsingResult)
  {
    string sDp = getDriverConnectionDp(sDeviceKey);

    if (BROWSE_DPE_REQUEST != "" && sDp != "")
    {
      prepareDeviceForBrowsing(sDeviceKey);

      DebugFTN(DriverConst::DEBUG_BROWSE, __FUNCTION__ + "(" + sDeviceKey + ", " + sFilter + ", " + iStart + ", " + iMaxResultRows + ")");

      dyn_string dsDpesResult = dpNames(sDp + BROWSE_DPE_RESULT_STRUCT + ".**");
      dyn_anytype daValues;
      bool bExpired;

      if (BROWSE_DPE_REQUEST != "-")
      {
        // Determine the start nodes
        dyn_string dsNodes = strsplit(sParent, ".");
        dyn_string dsStart = filterStart(dsNodes);

        DebugFTN(DriverConst::DEBUG_BROWSE, __FUNCTION__ + "(" + sDeviceKey + ", " + sFilter + ", " + iStart + ", " + iMaxResultRows + ") start nodes: " + dsStart);

        // Create an unique request id
        string  sRequestId = "MNSP+" + DRIVER_NAME + "=" + dynStringToString(dsStart, ".") + "@" + (string)getCurrentTime();


        for (int i = dynlen(dsDpesResult); i > 0; i--)
        {
          // Remove the struct elements from the result dpes
          if (dpElementType(dsDpesResult[i]) == DPEL_STRUCT)
          {
            dynRemove(dsDpesResult, i);
          }
          // Remove the elements of the request itself and the element containing the request id from the result dpes
          else if (regexpIndex("\\S+:" + sDp + "(" + regExpEscape(BROWSE_DPE_REQUEST) + "|" + regExpEscape(BROWSE_DPE_RESULT_ID) + ")", dsDpesResult[i], makeMapping("caseSensitive", TRUE)) >= 0)
          {
            dynRemove(dsDpesResult, i);
          }
          else
          {
            dsDpesResult[i] += ":_original.._value";
          }
        }

        DebugFTN(DriverConst::DEBUG_BROWSE, __FUNCTION__ + "(" + sDeviceKey + ", " + sFilter + ", " + iStart + ", " + iMaxResultRows + ") request id: " + sRequestId + " start nodes: " + dsStart, browseRequestValue(dsStart, sRequestId));

        // Execute the browse request and wait for the result
        dpSetAndWaitForValue(makeDynString(sDp + BROWSE_DPE_REQUEST   + ":_original.._value"), makeDynAnytype(browseRequestValue(dsStart, sRequestId)),
                             makeDynString(sDp + BROWSE_DPE_RESULT_ID + ":_original.._value"), makeDynAnytype(browseDoneValue(sRequestId)),
                             dsDpesResult, daValues, BROWSE_TIMEOUT, bExpired);
      }
      else
      {
        bExpired = manualBrowsing(sDeviceKey, sFilter, iStart, iMaxResultRows, sParent, dsDpesResult, daValues);
      }
      if (!bExpired)
      {
        vector<BrowseItem> vResult = browseResult(dsDpesResult, daValues, sParent);

        DebugFTN(DriverConst::DEBUG_BROWSE, __FUNCTION__ + "(" + sDeviceKey + ", " + sFilter + ", " + iStart + ", " + iMaxResultRows + ") item count: " + vResult.count() + " filter: " + sFilter);

        // First remove items that do not match the specified filter
        for (int i = vResult.count() - 1; sFilter != "" && i >= 0; i--)
        {
          BrowseItem stItem = vResult.at(i);

          if (!patternMatch(sFilter, stItem.name))
          {
            vResult.removeAt(i);
          }
        }

        DebugFTN(DriverConst::DEBUG_BROWSE, __FUNCTION__ + "(" + sDeviceKey + ", " + sFilter + ", " + iStart + ", " + iMaxResultRows + ") filtered count: " + vResult.count());

        // Determine the total count
        int iTotal = vResult.count();

        // Remove the items after the specified range
        for (int i = iTotal; iMaxResultRows > 0 && i > (iStart + iMaxResultRows - 1); i--)
        {
          vResult.removeAt(i - 1);
        }
        // Remove the items before the specified range
        for (int i = 0; i < iStart - 1; i++)
        {
          vResult.removeAt(0);
        }

        mBrowsingResult = makeMapping("start", iStart,
                                      "end",   iMaxResultRows > 0 && iStart + iMaxResultRows < iTotal ? iStart + iMaxResultRows : iTotal,
                                      "total", iTotal,
                                      WssConst::DATA,  vResult);
        DebugFTN(DriverConst::DEBUG_BROWSE, __FUNCTION__ + "(" + sDeviceKey + ", " + sFilter + ", " + iStart + ", " + iMaxResultRows + ") browsing result count: " + vResult.count());
      }
    }
  }
    /**
   * @brief prepare device for browsing (e.g. reconnect to PLC to get new browsing result, which is not cached)
   * @param sDeviceKey                 device key
   */
  protected prepareDeviceForBrowsing(const string &sDeviceKey)
  {
  }

  /**
   * @brief Deletes/Creates/Updates certificates for a device
   * @param sDevice      device id
   * @param dsCerts      Certificatecontent as dyn string, empty array deletes certificates, otherwise certificates will be saved or overwritten
   */
  public void certHandling(const string &sDevice, const dyn_string &dsCerts)
  {
    if (DRIVER_CERT_PATH != "")
    {
      //Check if the Directory for the certificate exists. If not create it (always in /data)
      if (!isdir(getPath(DATA_REL_PATH) + DRIVER_CERT_PATH))
      {
        dyn_string dsDirs = strsplit(DRIVER_CERT_PATH, "/");
        string sDir = getPath(DATA_REL_PATH);

        for (int i = 1; i <= dynlen(dsDirs); i++)
        {
          sDir = sDir + "/" + dsDirs[i];
          mkdir(sDir);
        }
      }

      //If an olddevice exists and shall be deleted or modified
      dyn_string dsCurrentFiles = getFileNames(getPath(DATA_REL_PATH + DRIVER_CERT_PATH), sDevice + "*");

      for (int i = dynlen(dsCerts)+1; i <= dynlen(dsCurrentFiles); i++)
      {
        string sFile = getPath(DATA_REL_PATH + DRIVER_CERT_PATH + "/", dsCurrentFiles[i]);
        remove(sFile);
      }

      //If a new device shall be created and the Json from Mindsphere includes certificates
      for (int i = 1; i <= dynlen(dsCerts); i++)
      {
        string sNewFile = getPath(DATA_REL_PATH + DRIVER_CERT_PATH) + "/" + sDevice + "_" + i + ".der";
        file f = fopen(sNewFile, "w");

        if (f != 0)
        {
          int iBytes = fputs(dsCerts[i], f);
          fclose(f);
        }
      }
    }
  }

  /**
   * @brief Returns the manager key for the log functions
   * @details The manager key is the manager number in '%03d' format
   * @return manager key for the log functions
   */
  public string logGetManagerKey()
  {
    string sResult;

    sprintf(sResult, "%03d", DRIVER_NUMBER);

    return sResult;
  }

  /**
   * @brief convert UI values in mapping to OA settings or opposite
   * @details converte mapping values from mSettingConversionUItoOA["UI"][...] to mSettingConversionUItoOA["OA"][...]
   * @param mParams      mapping, which will be modified
   * @param bFromUiToOA  defined direction of converting (deffault if from UI value to OA value)
   */
  public void convertMappingValues(mapping &mParams, bool bFromUiToOA = TRUE)
  {
    if (mappinglen(mSettingConversionUItoOA)>0)
    {
      dyn_string dsKeys = mappingKeys(mParams);
      for (int i=dynlen(dsKeys); i>0; i--)
      {
        string sKey = dsKeys[i];
        if (mappingHasKey(mSettingConversionUItoOA, sKey))
        {
          int iPos = dynContains(mSettingConversionUItoOA[sKey][bFromUiToOA ? "UI" : "OA"], mParams[sKey]);
          if (iPos > 0)
          {
            mappingRemove(mParams, sKey); //to allow type convertion
            mParams[sKey] = mSettingConversionUItoOA[sKey][bFromUiToOA ? "OA": "UI"][iPos];
          }
        }
      }
    }
  }

  /**
   * @brief defines if deleting or changing source requires reset of driver
   * @param sDeviceKey    the device key
   * @return TRUE for reset of driver is required on deleting devices or modify of data source address (IP / URL)
   */
  public bool isDriverRecoveryOnSourceChangeRequired()
  {
    return FALSE;
  }

  /**
   * @brief recoery function after delting all devices before re adding devices
   */
  public bool doDriverRecovery()
  {
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------

  protected string               sConnectionAttributeOnAddress = "";               //!< Additional parameter for connection
  protected ConnectionAlertState connectionState = ConnectionAlertState::Disabled; //!< The connection state

  /**
   * @brief Place holder to make it easier to find the protected variables
   */
  protected void __firstProtectedFunction() {}

  /**
   * @brief Clears the pending logs with the specified key
   * @param eCategory   Category of the log
   * @param sKey        Message catalog key and the log reason
   * @param sDeviceId   Optional: Device to clear the logs from
   */
  protected void logClear(LogCategory eCategory, const string &sKey, string sDeviceId = "")
  {
    Logging::clear(eCategory, logGetManagerKey() + sKey, sDeviceId);
  }

  /**
   * @brief Clears the pending logs with the specified key
   * @param sDeviceId   Optional: Device to clear the logs from
   */
  protected void logClearAll(string sDeviceId = "")
  {
    Logging::clearAll(logGetManagerKey() + "???", sDeviceId);
  }

  /**
   * @brief Writes a new log entry with the specified values
   * @param eCategory        Category of the log
   * @param sKey             Message catalog key and the log reason
   * @param eSeverity        Severity of the log
   * @param daArguments      Additional arguments for the log text
   * @param sDeviceId        Optional: Device id for the log reason
   * @param bForcePending    Optional: Flag to set the pending flag for an information log
   */
  protected void logWrite(LogCategory eCategory, const string &sKey, LogSeverity eSeverity, const dyn_anytype &daArguments, string sDeviceId = "", bool bForcePending = FALSE)
  {
    Logging::write(eCategory, sKey, eSeverity, daArguments, sDeviceId, bForcePending, logGetManagerKey());
  }

  /**
   * @brief Returns the process name of this driver
   * @return Process name of the driver
   */
  protected string getProcessName()
  {
    // The WinCC OA managers names are limited in length,
    // so usually the shortest is the name of the process
    string sName = strlen(DRIVER_IDENTIFIER) < strlen(DRIVER_NAME) ? DRIVER_IDENTIFIER : DRIVER_NAME;

    return "WCCOA" + strtolower(sName);
  }

  /**
   * @brief Returns the device entry for the driver device list (driver depending)
   * @param sDriverConnDP    Driver connection DP
   * @return Device list entry
   */
  protected string getDeviceListEntry(const string &sDriverConnDP)
  {
    return strltrim(sDriverConnDP, "_") + " " + DRIVER_NUMBER;
  }

  /**
   * @brief function to modify datpoints, which is called at begin of updateDeviceDp()
   * @param sDeviceKey     device key
   * @param mParams        configuration mapping for the device
   */
  protected void beforeUpdateDeviceDP(const string &sDeviceKey, mapping &mParams)
  {
  }

  /**
   * @brief function to modify datpoints, which is called at begin of deleteDeviceDp()
   * @param sDeviceKey     device key
   * @param mParams        configuration mapping for the device
   */
  protected void beforeDeleteDeviceDP(const string &sDeviceKey, mapping &mParams)
  {
  }

  /**
   * @brief Returns optional connection attribute for address config (driver depending)
   * @param mTag
   * @return connection attribute
   */
  protected string getConnectionattribute(const mapping &mTag)
  {
    return "";
  }

  /**
   * @brief Returns the query for the connection states
   * @return Query to get the needed information to determine the connection state
   */
  protected string getConnectionStateQuery()
  {
    return "SELECT '" + dynStringToString(CONNECTION_STATE_ELEMENTS, ":_online.._value,") + ":_online.._value'"
           " FROM '" + CONNECTION_DP_PREFIX + "*'"
           " WHERE _DPT = \"" + DRIVER_CONNECTION_DPTYPE + "\" AND _DP != \"_mp_" + DRIVER_CONNECTION_DPTYPE + "\"";
  }

  /**
   * @brief Callback function for determining the connection state(s)
   * @param aUserData   Function pointer to call with the connection state(s)
   * @param ddaData     Data from the query
   */
  protected void connectionStateCB(const anytype &aUserData, const dyn_dyn_anytype &ddaData)
  {
    function_ptr fpCallback = aUserData;
    mapping mStates;

    DebugFTN(DriverConst::DEBUG_DEVICE, "device connection state: connectionStateCB", fpCallback, ddaData);
    // Skip the header
    for (int i = 2; i <= dynlen(ddaData); i++)
    {
      if ( strpos(formatDebug(ddaData[i][1]), "(") == 0 || !dpExists((string)ddaData[i][1]) ) //on moment of deleting device
      {
        continue;
      }

      string sDeviceNode = getDeviceNode(dpSubStr(ddaData[i][1], DPSUB_DP));
      int    iQuality    = getConnectionQuality(dynSub(ddaData[i], 2));   // Pass only the value from the element (remove the dpe item)
      string sMessage    = getConnectionText(iQuality);
      DebugFTN(DriverConst::DEBUG_DEVICE, "device connection state: connectionStateCB result for quality", iQuality, sMessage, ddaData[i], dynSub(ddaData[i], 2));

      if (sDeviceNode != "")
      {
        mStates[sDeviceNode] = makeDynAnytype(iQuality, sMessage);
      }
    }

    if (fpCallback != nullptr)
    {
      DebugFTN(DriverConst::DEBUG_DEVICE, "device connection state: connectionStateCB call function", fpCallback, mStates);
      callFunction(fpCallback, mStates);
    }
    else
    {
      DebugFTN(DriverConst::DEBUG_DEVICE, "device connection state: connectionStateCB no callback function found!", aUserData, mStates);
    }
  }

  /**
   * @brief Determines the device CNS node id from the driver dp
   * @param sDriverDp   Driver connection dp
   * @return Device CNS node id
   */
  protected string getDeviceNode(const string &sDriverDp)
  {
    string sResult;
    dyn_string dsCaptures;

    regexpSplit("\\S+(\\d+)$", sDriverDp, dsCaptures);

    if (dynlen(dsCaptures) >= 2)
    {
      dyn_string dsCnsPaths;

      //try for 6 seconds to translate the nodename - perhaps CNS is not updated so fast
      for (int i = 1; i <= 60 && dynlen(dsCnsPaths) == 0; i++)
      {
        cnsGetNodesByData(getSystemName() + DRIVER_NAME + SEPARATOR + dsCaptures[2] + DPE_DRIVER_STATE, CNS_SEARCH_ALL_TYPES, getView(), dsCnsPaths);
        if (dynlen(dsCnsPaths) == 0)
          delay(0,100);
      }

      if (dynlen(dsCnsPaths) > 0)
      {
        sResult = dsCnsPaths[1];
      }
      else
      {
        // Only provide a hint for development
        throwError( makeError("", PRIO_WARNING, ERR_CONTROL, 54, "Unable to find CNS tree for driver dp: " + sDriverDp + " -> " + getSystemName() + DRIVER_NAME + SEPARATOR + dsCaptures[2] + DPE_DRIVER_STATE, CNS_SEARCH_ALL_TYPES + " -- called by: " + (string) getStackTrace()));
      }
    }

    return sResult;
  }

  /**
   * @brief Returns the connection quality code for MindSphere
   * @details Quality codes indicating problems should be negative
   *          Function must be overruled if multiple elements are specified in 'CONNECTION_STATE_ELEMENTS'
   * @param aValue Value(s) from the connection state query
   * @return Quality code for MindSphere datasource connection
   */
  protected int getConnectionQuality(const anytype &aValue)
  {
    int iResult;

    // Need a non-dyn value for dynContains ('aValue' should be a dyn with only 1 value)
    anytype aState = strpos(getTypeName(aValue), "dyn_") == 0 && dynlen(aValue) > 0 ? aValue[1] : aValue;

    if (dynlen(CONNECTION_STATE_OK) > 0 && dynContains(CONNECTION_STATE_OK, aState) > 0)
    {
      iResult = 0;
    }
    else if (dynlen(CONNECTION_STATE_WARNING) > 0 && dynContains(CONNECTION_STATE_WARNING, aState) > 0)
    {
      iResult = 1;
    }
    else
    {
      iResult = -1;
    }
    DebugFTN(DriverConst::DEBUG_DEVICE, "device connection state: getConnectionQuality", aValue, aState, CONNECTION_STATE_OK, getTypeName(aValue), getTypeName(aState), getTypeName(CONNECTION_STATE_OK), "state foud in CONNECTION_STATE_OK = ", dynContains(CONNECTION_STATE_OK, aState), iResult, CONNECTION_STATE_OK);
    return iResult;
  }

  /**
   * @brief Returns the connection message for MindSphere
   * @param iQualityCode     Quality code to get the text for
   * @return Connection quality message
   */
  protected string getConnectionText(int iQualityCode)
  {
    string sResult;

    if (iQualityCode == 0)
    {
      sResult = "OK";
    }
    else if (iQualityCode < 0)
    {
      sResult = "Error";
    }
    else
    {
      sResult = "Warning";
    }

    return sResult;
  }

  protected void createConnectionTag(const string &sDeviceKey, const langString &sDeviceName)
  {
  }

  protected void deleteConnectionTag()
  {
  }

  protected string getTagAddress(const string &sTagKey)
  {
    return EB_getReferenceStringFromTag(sTagKey);
  }

  protected string getTagAddressRefstring(const string &sAddress, const string &sDeviceKey)
  {
    return sAddress;
  }

  public int getTagTransformation(const string &sTagKey)
  {
    int iResult;
    string sDpe;

    cnsGetId(sTagKey, sDpe);

    if (sDpe != "")
    {
      int iType;

      dpGet(sDpe + ":_address.._type", iType);

      if (iType == DPCONFIG_PERIPH_ADDR_MAIN)
      {
        dpGet(sDpe + ":_address.._datatype", iResult);
      }
    }

    return iResult;
  }

  protected string setupReferenceString(const string &sDeviceKey, const string &sTagKey, const langString &lsDescription, const string &sAddress, const EBTagType &tagType, const string &sRefreshRate,
                           const bool &bActive, const bool &bArchive, const string &sFormat, const langString &lsUnit, const int &iTransformation,
                           const int &iDirection, string &sConnectionAttributeOnAddress, const uint &uSubindex)
  {
    return "";
  }

  protected void updateDeviceMapping(mapping &mDevice)
  {
  }

  protected void updateTagMapping(mapping &mTag)
  {
  }

  protected void preCreateDeviceDp(const langString &lsName, const langString &lsLocation, const langString &lsDescription, const string &sAddress, const mapping &mAdditionalParams)
  {
  }

  protected void postCreateDeviceDp(const string &sDeviceKey, const langString &lsName, const langString &lsLocation, const langString &lsDescription, const string &sAddress, const mapping &mAdditionalParams)
  {
    string sDeviceDpName = getDriverConnectionDp(sDeviceKey, TRUE);
    string sDriverDpEB   = sDeviceDpName;

    strreplace(sDriverDpEB, CONNECTION_DP_PREFIX, DRIVER_NAME + SEPARATOR);

    if (!dpExists(sDeviceDpName))
    {
      dpCreate(sDeviceDpName, DRIVER_CONNECTION_DPTYPE);
    }

    // Link the CNS device node to the EB driver DP
    cnsChangeNodeData(sDeviceKey, sDriverDpEB + DPE_DRIVER_STATE, (int)DEVICE_NODETYPE);

    mapping mValues;

    for (int i = 1; i <= mappinglen(mDeviceDetailSource); i++)
    {
      // Store the relative elements without '[]' brackets with the values from the additional parameters
      if (regexpIndex("(\\.\\S+)\\[(\\S+)\\]", mappingGetValue(mDeviceDetailSource, i)) < 0)
      {
        mValues[mappingGetValue(mDeviceDetailSource, i)] = mAdditionalParams[mappingGetKey(mDeviceDetailSource, i)];
      }
    }

    anytype     aDummy;
    string      sDp    = dpSubStr(sDeviceDpName, DPSUB_SYS_DP);
    dyn_string  dsDpes = dpNames(sDeviceDpName + ".**");
    dyn_anytype daValues;

    // Make sure the value array matches the dpe array length
    daValues[dynlen(dsDpes)] = aDummy;

    for (int i = dynlen(dsDpes); i > 0; i--)
    {
      string sElement = dsDpes[i];

      strreplace(sElement, sDp, "");

      // No value to set for struct elements
      if (dpElementType(dsDpes[i]) == DPEL_STRUCT)
      {
        dynRemove(dsDpes,   i);
        dynRemove(daValues, i);
      }
      // Check if this element must NOT be set
      else if (dynContains(CONNECTION_EXCLUDES, sElement) > 0 || regExpMatch(CONNECTION_EXCLUDES, sElement))
      {
        dynRemove(dsDpes,   i);
        dynRemove(daValues, i);
      }
      // Check if a value has been set for this element
      else if (mappingHasKey(mValues, sElement))
      {
        daValues[i] = mValues[sElement];
      }
      // Check if a value has been (pre)defined for this element
      else if (mappingHasKey(CONNECTION_VALUES, sElement))
      {
        switch (CONNECTION_VALUES[sElement])
        {
          case "<DeviceId>": daValues[i] = abs(DRIVER_DEVICE_ID_OFFSET + (int)getDeviceId(sDeviceKey, TRUE)); break;
          default:
            daValues[i] = CONNECTION_VALUES[sElement];
            break;
        }
      }
      else
      {
        daValues[i] = getDefaultValueForDpe(dsDpes[i]);
      }
    }

    if (CONNECTION_CHECK != "")
    {
      dynAppend(dsDpes, makeDynString(sDeviceDpName + CONNECTION_CHECK + ":_distrib.._type",
                                      sDeviceDpName + CONNECTION_CHECK + ":_distrib.._driver",
                                      sDeviceDpName + CONNECTION_CHECK + ":_address.._type",
                                      sDeviceDpName + CONNECTION_CHECK + ":_address.._reference",
                                      sDeviceDpName + CONNECTION_CHECK + ":_address.._direction",
                                      sDeviceDpName + CONNECTION_CHECK + ":_address.._datatype",
                                      sDeviceDpName + CONNECTION_CHECK + ":_address.._drv_ident",
                                      sDeviceDpName + CONNECTION_CHECK + ":_address.._active"));

      dynAppend(daValues, makeDynAnytype(DPCONFIG_DISTRIBUTION_INFO,
                                         DRIVER_NUMBER,
                                         DPCONFIG_PERIPH_ADDR_MAIN,
                                         "__check__",
                                         DPATTR_ADDR_MODE_OUTPUT,
                                         0,
                                         DRIVER_NAME,
                                         TRUE));
	  if (DRIVER_SUPPORT_HMICONNECTION) //BACnet does not support this
	  {
		  dynAppend(dsDpes, sDeviceDpName + CONNECTION_CHECK + ":_address.._connection");
		  dynAppend(daValues, sDeviceDpName);
	  }
    }

    DebugFTN("SET_CONN_DP", __FUNCTION__ + "(" + sDeviceKey + ", " + lsName + ", " + lsLocation + ", " + lsDescription + ", " + sAddress + ", ...) Setting: " + dynlen(dsDpes));

    if (dynlen(dsDpes) > 0)
    {
      dpSetWait(dsDpes, daValues);
    }
  }

  protected void preUpdateDeviceDp(const langString &lsName, const langString &lsLocation, const langString &lsDescription, const string &sAddress, const mapping &mAdditionalParams)
  {
  }

  protected void postUpdateDeviceDp(const string &sDeviceKey, const langString &lsName, const langString &lsLocation, const langString &lsDescription, const string &sAddress, const mapping &mAdditionalParams)
  {
  }

  protected void preDeleteDeviceDp(const string &sDeviceKey, const mapping &mParams)
  {
    string sDeviceDpName = getDriverConnectionDp(sDeviceKey);

    if (dpExists(sDeviceDpName))
    {
      dpDelete(sDeviceDpName);
    }
  }

  protected void postDeleteDeviceDp(const string &sDeviceKey, const mapping &mParams)
  {
  }

  protected void preCreateTagDp(const string &sDeviceKey, const langString &lsDescription, const string &sAddress, const EBTagType &tagType, const string &sRefreshRate,
                           const bool &bActive, const bool &bArchive, const string &sFormat, const langString &lsUnit, const int &iTransformation,
                           const int &iDirection, const string &sConnectionAttributeOnAddress, const uint &uSubindex, const mapping &mAdditionalParams)
  {

  }

  protected void postCreateTagDp(const string &sDeviceKey, const string &sTagKey, const langString &lsDescription, const string &sAddress, const EBTagType &tagType, const string &sRefreshRate,
                           const bool &bActive, const bool &bArchive, const string &sFormat, const langString &lsUnit, const int &iTransformation,
                           const int &iDirection, const string &sConnectionAttributeOnAddress, const uint &uSubindex, const mapping &mAdditionalParams)
  {
  }

  protected void preUpdateTagDp(const string &sDeviceKey, const langString &lsDescription, const string &sAddress, const EBTagType &tagType, const string &sRefreshRate,
                           const bool &bActive, const bool &bArchive, const string &sFormat, const langString &lsUnit, const int &iTransformation,
                           const int &iDirection, const string &sConnectionAttributeOnAddress, const uint &uSubindex, const mapping &mAdditionalParams)
  {

  }

  protected void postUpdateTagDp(const string &sDeviceKey, const string &sTagKey, const langString &lsDescription, const string &sAddress, const EBTagType &tagType, const string &sRefreshRate,
                           const bool &bActive, const bool &bArchive, const string &sFormat, const langString &lsUnit, const int &iTransformation,
                           const int &iDirection, const string &sConnectionAttributeOnAddress, const uint &uSubindex, const mapping &mAdditionalParams)
  {
  }

  protected void preDeleteTagDp(const string &sTagKey)
  {
  }

  protected void postDeleteTagDp(const string &sTagKey)
  {
  }

  protected mapping updateParamsForDeviceDeletion(const mapping &mParams)
  {
    return mDefaultDevice;
  }

  protected string getDriverConnectionDp(const string &sDeviceKey, bool bNewId = FALSE)
  {
    return CONNECTION_DP_PREFIX + getDeviceId(sDeviceKey, bNewId);
  }

  /**
   * @brief Returns the next device id
   * @param sIgnore Devices to ignore
   * @return First free device id
   */
  protected int getNextDeviceId(string sIgnore = "")
  {
    int iNextDeviceId = -1;
    dyn_string dsTrees = this.getCnsForApp();

    //search for next device id
    dyn_int diDeviceIds;

    for (int i = dynlen(dsTrees); i > 0; i--)
    {
      if (dsTrees[i] != sIgnore)
      {
        dynAppend(diDeviceIds, (int)getDeviceId(dsTrees[i], FALSE));
      }
    }

    dynSort(diDeviceIds);

    for (int i = 1; i <= dynlen(diDeviceIds) && iNextDeviceId == -1; i++)
    {
      if (diDeviceIds[i] != i) //gap found
      {
        iNextDeviceId = i;
      }
    }

    if (iNextDeviceId == -1) //no gap found, next device id is count + 1
    {
      iNextDeviceId = dynlen(diDeviceIds) + 1;
    }

    return iNextDeviceId;
  }

  /**
   * @brief Returns if this driver app uses subscriptions to read values
   * @return TRUE -> Using subscriptions to read values
   */
  protected bool useSubscriptions()
  {
    return FALSE;
  }
  /**
 * @brief Creates an address and a distrib config for the given tag id
 * @param sNodeId            Tag id where the configs will be set
 * @param iDrvNr             Driver number
 * @param sDrvIdent          Protocol. e.g.: "S7", "OPCUA", ...
 * @param sRef               Reference string
 * @param sPollGroup         Pollgroup used
 * @param iTrans             Transformation
 * @param bActive            If the address is active or not (default: TRUE/active)
 * @param iDirection         Direction of the address (default: Input polling)
 * @param sDeviceId          Id of the device (Optional)
 * @param uSubindex          Subindex in the read value (Optional)
 * @param bLowLevelFilter    Only send value changes (Optional)
 * @return 0 in case of success, otherwise -1
 */
protected int createAddressForTag(const string &sNodeId, const int &iDrvNr, const string &sDrvIdent,
                                  const string &sRef, const string &sPollGroup,
                                  int iTrans, bool bActive = TRUE, int iDirection = DPATTR_ADDR_MODE_INPUT_POLL,
                                  string sDeviceId = "", uint uSubindex = 0u, bool bLowLevelFilter = TRUE)
{
  return EB_createAddressForTag(sNodeId, iDrvNr, sDrvIdent, sRef, sPollGroup,
                                iTrans, bActive, iDirection, sDeviceId, uSubindex, bLowLevelFilter);
}
/**
 * @brief Sets the tag address active/inactive
 * @param sNodeId  The tag id where the configs will be set
 * @param bActive  If the address is active or not
 * @return 0 in case of success, otherwise -1
 */
protected int setActiveForTag(const string &sNodeId, bool bActive)
{
  return EB_setActiveForTag(sNodeId, bActive);
}
  /**
   * @brief Returns the value for the browse request
   * @param sStart      Start node of the browse request
   * @param sRequestId  Request id of the browse request
   * @return Browse request value
   */
  protected dyn_anytype browseRequestValue(const dyn_string &dsStart, const string &sRequestId)
  {
    return makeDynString(sRequestId);
  }


  /**
   * @brief function to do manual browsing instead of getting browsing result via DPE
   * @param sDeviceKey                 device key
   * @param sFilter                    filter pattern
   * @param iStart                     result start index
   * @param iMaxResultRows             max number of lines before splitting browsing result
   * @param sParent                    parent start node
   * @param dsDpes                     array Dpes of the browse result
   * @param daValues                   array values from the browse result dpes
   * @return 0 ok, no failure
   */
  protected bool manualBrowsing(const string &sDeviceKey, const string &sFilter, int iStart, int iMaxResultRows, const string &sParent, string &dsDpes, dyn_anytype &daValues)
  {
    return FALSE;
  }

  /**
   * @brief Converts the received values into a collection of browse items
   * @param dsDpes      Dpes of the browse result
   * @param daValues    Values from the browse result dpes
   * @param sParent     parent start node
   * @return Browse items
   */
  protected vector<BrowseItem> browseResult(const string &dsDpes, const dyn_anytype &daValues, const string &sParent)
  {
    return makeVector();
  }

  /**
   * @brief Returns the value, which indicates that the browsing is done
   * @param sRequestId  Browsing request id
   * @return Value to wait for before reading the browse result
   */
  protected anytype browseDoneValue(const string &sRequestId)
  {
    return sRequestId;
  }

  protected dyn_string filterStart(const dyn_string &dsNodes)
  {
    dyn_string dsResult = dsNodes;

    // Keep only the first parts without wildcards
    for (int i = dynlen(dsResult); i > 0; i--)
    {
      // Check if this part contains a wildcard
      if (strtok(dsResult[i], "*?") >= 0)
      {
        // Remove this and the next parts
        for (int x = dynlen(dsResult); x >= i; x--)
        {
          dynRemove(dsResult, x);
        }
      }
    }

    return dsResult;
  }


  /**
   * @brief get device index nubmer for the used driver
   * @param sDeviceKey    the device key
   * @return device index nubmer
   */
  protected int getDeviceIndex(const string &sDeviceKey) // Search for device index by name
  {
   // DebugTN("DRIVER_DEVICE_ID_OFFSET + (int)getDeviceId(sDeviceKey)",DRIVER_DEVICE_ID_OFFSET , (int)getDeviceId(sDeviceKey), sDeviceKey);
    return abs(DRIVER_DEVICE_ID_OFFSET + (int)getDeviceId(sDeviceKey));
  }

  protected void updateDeviceDp(const string &sDeviceKey, const langString &lsName, const langString &lsLocation, const langString &lsDescription, const string &sAddress, mapping mParams)
  {
    beforeUpdateDeviceDP(sDeviceKey, mParams);

    string sEbDriverDP = getEbDriverDP(sDeviceKey);
    string sDriverConnectionDP = getDriverConnectionDp(sDeviceKey, TRUE);

    string sType;
    string sDpe;
    int iType;

//    spLog.doLog(EB_createLogEntry(DRIVER_NAME, LOG_TYPE_CONFIGURATION, this.getDeviceId(sDeviceKey) + " configuration", "", (int)ConfigurationState::Pending, getCurrentTime(), "", "configChanged", makeMapping("$device", lsName)), TRUE, TRUE);



    if (EB_getTileType(sDeviceKey) == "")
    {
      EB_setTileType(sDeviceKey, "at.etm.driver.device");
    }

    cnsGetProperty(sDeviceKey, "DeviceType", sType);

    if (sType != DEVICE_TYPE)
    {
      cnsSetProperty(sDeviceKey, "DeviceType", DEVICE_TYPE);
    }

    if (!dpExists(sEbDriverDP))
    {
      dpCreate(sEbDriverDP, this.DPT_DRIVER_CONNECTION);
    }
    if (!dpExists(sDriverConnectionDP))
    {
      dpCreate(sDriverConnectionDP, this.DRIVER_CONNECTION_DPTYPE);
    }

    if (CONNECTION_TAG_NEEDED)
    {
      this.createConnectionTag(sDeviceKey,lsName);
    }

    // Make sure our driver connection dp is linked to the CNS node (without changing the node type, so include the type)
    cnsGetId(sDeviceKey, sDpe, iType);

    if (sDpe != sEbDriverDP + this.DPE_DRIVER_STATE)
    {
      cnsChangeNodeData(sDeviceKey, sEbDriverDP + this.DPE_DRIVER_STATE, iType);
    }

    mapping mDevice;
    langString lsNames;

    cnsGetDisplayNames(sDeviceKey, lsNames);

    dyn_string dsDPEs, dsDPE2;
    dyn_anytype daValues, daValues2;

    dyn_bool dbArrayIndexItem;

    mapping mDeviceAttr = mDeviceDetailSource;
    mapping mAddInfo;

    int iLen = mappinglen(mDeviceAttr);
    int iDeviceIndex = abs(DRIVER_DEVICE_ID_OFFSET + (int)getDeviceId(sDeviceKey)); // Search for device index by name

    for (int i = 1; i <= iLen ; i++)
    {
      string sDPE = mDeviceAttr[mappingGetKey(mDeviceAttr, i)];

      if (strpos(sDPE, ".AddInfo[") == 0) //e.g. .AddInfo[location]
      {
        string sAttribute = strrtrim(substr(sDPE, strpos(sDPE, "[") + 1), "]");

        mAddInfo[sAttribute] = mParams[mappingGetKey(mDeviceAttr, i)];

        mappingRemove(mDeviceAttr, mappingGetKey(mDeviceAttr, i));

        i--;
        iLen--;
      }
      else
      {
        dbArrayIndexItem[i] = strpos(sDPE, "[]") > 0;

        if (dbArrayIndexItem[i])
        {
          strreplace(sDPE, "[]", "");
        }

        if (strpos(sDPE, ".AddInfo") == 0) //relative DPE
        {
          sDPE = sEbDriverDP + sDPE;
        }
        else if (strpos(sDPE, ".") == 0) //relative DPE
        {
          if (dpExists(sDriverConnectionDP + sDPE))
          {
            sDPE = sDriverConnectionDP + sDPE;
          }
          else if (dpExists(sDriverConnectionDP))
          {
            throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to read value for element: " + sDriverConnectionDP + sDPE, "Unable to determine DP for: " + lsName));
          }

          if (dpExists(sEbDriverDP + sDPE))
          {
            sDPE = sEbDriverDP + sDPE;
          }
          else if (!dpExists(sEbDriverDP))
          {
            throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to read value for element: "+ sEbDriverDP + sDPE, "Unable to determine DP for: " + lsName));
          }
        }

        if (dpExists(sDPE))
        {
          anytype aTmp;
          dpGet(sDPE, aTmp);
          if (dbArrayIndexItem[i])
          {
            if (mappingGetKey(mDeviceAttr, i) == "connectionsAll")
            {
              string sDeviceEntry = getDeviceListEntry(sDriverConnectionDP);

              if (dynContains(aTmp, sDeviceEntry) == 0)
              {
               string sConnectionsAddDPE = sDPE;

               if (strreplace(sConnectionsAddDPE, ".Connections.All", ".Connections.Add") > 0 && dpExists(sConnectionsAddDPE))
               {
                 // "S7_Config.Connection.All" needs to be set first, before setting connection DPEs
                 dpSet(sDPE, sDeviceEntry);

                 dynAppend(dsDPE2, sConnectionsAddDPE);
                 dynAppend(daValues2, sDeviceEntry);
               }

               dynAppend(aTmp, sDeviceEntry);
             }
           }
           else
           {
             if (getType(aTmp) == ANYTYPE_VAR)
             {
               aTmp = makeDynAnytype();
             }

             aTmp[iDeviceIndex] = mParams[mappingGetKey(mDeviceAttr, i)];
           }
          }
          else
          {
            aTmp = mParams[mappingGetKey(mDeviceAttr, i)];
          }

//           DebugTN(__FUNCTION__ + "() i: " + i + " adding: " + sDPE, aTmp);

          dynAppend(dsDPEs, sDPE);
          daValues[dynlen(daValues) + 1] = aTmp;
        }
      }
    }

    if (mappinglen(mAddInfo) > 0)
    {
      dynAppend(daValues, jsonEncode(mAddInfo));
      dynAppend(dsDPEs, sEbDriverDP + ".AddInfo");
    }

    //DebugTN(__FUNCTION__ + "() Setting dpes:", dsDPEs, daValues);
    connectDeviceOnDeviceChange(sDeviceKey, sDriverConnectionDP, FALSE);
    dpSetWait(dsDPEs, daValues);

    //Set The Add DP for S7/Sinumerik after everything to connect the PLC
    if (dynlen(dsDPE2) > 0)
    {
      dpSet(dsDPE2, daValues2);
    }
    connectDeviceOnDeviceChange(sDeviceKey, sDriverConnectionDP, TRUE);
  }

  /**
   * @brief if drivers requires reestablish connection, derived driver app can disconnect an reconnect on device change (e.g. IP address has been changed)
   * @param sDeviceKey           the device key
   * @param sDriverConnectionDP  connection DP for device
   * @return bConnect            trigger connect or disconnect
   */
  protected void connectDeviceOnDeviceChange(string sDeviceKey, string sDriverConnectionDP, bool bConnect=TRUE)
  {
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  protected bool isManagerRunning(const string &sHostname, const string &sManagerName, bool bCheckForRunning = TRUE)
  {
    if (isDbgFlag("TEST_NO_PMON"))
    {
      return TRUE;
    }

    dyn_dyn_string ddsNames, ddsState;
    int iPmonPort = paCfgReadValueDflt(getPath(CONFIG_REL_PATH, "config"), "general", "pmonPort", 4999);

    string sHostName = sHostname == getHostname() ? "localhost" : sHostname;
    int tcpOpenRc = tcpOpen(sHostName, iPmonPort);
    string  sProjUser = "", sProjPassword = "";

    bool errList1, errList2;
    errList1 = pmon_query(sProjUser + "#" + sProjPassword + "#MGRLIST:LIST",  sHostName, iPmonPort, ddsNames, 0, 1);
    errList2 = pmon_query(sProjUser + "#" + sProjPassword + "#MGRLIST:STATI", sHostName, iPmonPort, ddsState, 0, 1);

    tcpClose(tcpOpenRc);

    bool bRet;
    bool bManagerMatch;

    for (int i = 1; i <= dynlen(ddsNames) && i <= dynlen(ddsState) && !bManagerMatch; i++)
    {
      bManagerMatch = ddsNames[i][1] == sManagerName;
      if (ddsNames[i][1] == "WCCOActrl" && strpos(sManagerName, "WCCOActrl") == 0) //CTRL script
      {
        for (int j = dynlen(ddsNames[i]); j > 1 && !bManagerMatch; j--) //search for CTRL script
        {
          if (patternMatch("*.ctl", ddsNames[i][j]))
          {
            if (sManagerName == "WCCOActrl" + " " + ddsNames[i][j])
            {
              bManagerMatch = TRUE;
            }
            else
            {
              j = 1; //wrong CTRL script
            }
          }
        }
      }

      if(bManagerMatch)
      {
        bRet = ddsState[i][1] == (bCheckForRunning ? 2 : 0); //requested manager is in state 2 (running)
      }
    }
    if (!bRet)
    {
      touchPackageFiles(sManagerName);
    }

  	return bRet;
  }

  private void touchPackageFiles(string sManagerName="")
  {
    string sFile = getPath(DATA_REL_PATH, "packages/state.box");
    string sCmd = "touch " + sFile;
    DebugFTN(DriverConst::DEBUG_DEVICE, "isManagerRunning -> false; touch file", sManagerName, sCmd);
    system(sCmd);
  }

  private dyn_mapping getTagsForDevice(const string &sDeviceKey)
  {
    dyn_string dsTrees = this.getCnsForApp();
    dyn_mapping dmTag;

    for (int i = 1; i <= dynlen(dsTrees); i++)
    {
      if (dsTrees[i] == sDeviceKey)
      {
        dyn_string dsChildren;

        cnsGetChildren(sDeviceKey, dsChildren);

        for (int j = 1; j <= dynlen(dsChildren); j++)
        {
          dynAppend(dmTag, getTagDetail(dsChildren[j]));
        }
      }
    }

    return dmTag;
  }

  private mapping getTagDetail(const string &sTagKey)
  {
     mapping mTag;

     langString lsDisplayName = EB_getTagNames(sTagKey);
     langString lsDescription = EB_getTagDescription(sTagKey, TRUE);
     langString lsUnit        = EB_getTagUnit(sTagKey);

     mTag[DriverConst::TAG_KEY]        = sTagKey;
     mTag[DriverConst::NAME]           = EB_LangStringToMapping(lsDisplayName);
     mTag[DriverConst::DESCRIPTION]    = EB_LangStringToMapping(lsDescription);
     mTag[DriverConst::ADDRESS]        = this.getTagAddress(sTagKey);
     mTag[DriverConst::DATATYPE]       = EB_getEnumTextForValue("EBTagType", (int)EB_getTagType(sTagKey)); //instead of int value, type as string
     mTag[DriverConst::POLLRATE]       = EB_getTagRate(sTagKey);
     mTag[DriverConst::ACTIVE]         = EB_getTagActive(sTagKey);
     mTag[DriverConst::ARCHIVE]        = EB_getTagArchive(sTagKey);
     mTag[DriverConst::FORMAT]         = EB_getFormatForTag(sTagKey);
     mTag[DriverConst::UNIT]           = EB_LangStringToMapping(lsUnit);
     mTag[DriverConst::TRANSFORMATION] = this.getTagTransformation(sTagKey);

     this.updateTagMapping(mTag);

     return mTag;
  }

  private string createTagDp(const string &sDeviceKey, const langString &lsName, const EBNodeType &nodeType, const EBTagType &tagType, bool bAllowDuplicateTagNames = FALSE)
  {
    string sTagKey = "";

    if (sDeviceKey != "")
    {
      sTagKey = EB_createTag(sDeviceKey, lsName, nodeType, tagType, "", bAllowDuplicateTagNames);
    }
    else
    {
      throwError(makeError("", PRIO_WARNING, ERR_CONTROL, 54, "Device key is empty", "Skipping tag creation: " + lsName, getStackTrace()));
    }

    return sTagKey;
  }

  private void changeTagName(const string &sTagKey, const langString &lsName, bool bAllowDuplicateTagNames = FALSE)
  {
    EB_changeTagNames(sTagKey, lsName, bAllowDuplicateTagNames);
  }

  private void changeTagDatatype(const string &sTagKey, const EBTagType &tagType)
  {
  }

  //sTagKey, lsDescription, sAddress, tagType, sRefreshRate, bActive, bArchive, sFormat, lsUnit, iTransformation
  private void updateTagDp(const string &sDeviceKey, const string &sTagKey, const langString &lsDescription, const string &sAddress, const EBTagType &tagType, const string &sRefreshRate,
                           const bool &bActive, const bool &bArchive, const string &sFormat, const langString &lsUnit, const int &iTransformation,
                           int iDirection, string sConnectionAttributeOnAddress, const uint &uSubindex, const bool &bLowLevelFilter, const float &fSmoothingAbsolute)
  {
    // Correct the direction for subscribing drivers
    if (useSubscriptions())
    {
      switch (iDirection)
      {
        case DPATTR_ADDR_MODE_INPUT_POLL: iDirection = DPATTR_ADDR_MODE_INPUT_SPONT; break;
        case DPATTR_ADDR_MODE_IO_POLL:    iDirection = DPATTR_ADDR_MODE_IO_SPONT;    break;
      }
    }

    string sReference = this.setupReferenceString(sDeviceKey, sTagKey, lsDescription, sAddress, tagType, sRefreshRate, bActive, bArchive,
                                                  sFormat, lsUnit, iTransformation, iDirection, sConnectionAttributeOnAddress, uSubindex);
    EB_setDescriptionForTag(sTagKey, lsDescription);
//     driverident generic , refstr empty


    createAddressForTag(sTagKey, this.getDriverNumber(), DRIVER_IDENTIFIER, sReference, "_" + sRefreshRate,
                        iTransformation, bActive, iDirection, sConnectionAttributeOnAddress, uSubindex, bLowLevelFilter);
    EB_setSmoothingConfigForTag(sTagKey, fSmoothingAbsolute);
    setActiveForTag(sTagKey, bActive);

    EB_setUnitForTag(sTagKey, lsUnit);
    EB_setFormatForTag(sTagKey, sFormat);

    EB_setArchiveConfigForTag(sTagKey, sRefreshRate, bArchive);

    //trigger single query because address could have been changed
    string sDpe = EBTag::getDpForId(sTagKey);

    dpSet(sDpe + GenericDriverTag::ADDRESS_CHECK_BIT, FALSE,
          sDpe + GenericDriverTag::ADDRESS_OK_BIT, FALSE);
  }

  private dyn_string getCnsForApp()
  {
    string sView = this.getView();
    dyn_string dsTrees;

    if (sView != "")
    {
      cnsGetTrees(sView, dsTrees);
    }

    return dsTrees;
  }

  private mapping fillDeviceDetail(const string &sDeviceKey)
  {
    mapping mDevice;
    string sEbDriverDP = DRIVER_NAME + this.SEPARATOR + this.getDeviceId(sDeviceKey);
    string sDriverConnectionDP = CONNECTION_DP_PREFIX + this.getDeviceId(sDeviceKey);
    langString lsNames;

    dyn_string dsDPEs;
    dyn_anytype daValues;

    dyn_bool dbArrayIndexItem;
    dyn_string dsAddInfo, dsAddInfoKeys; //collect additional attributes

    mapping mDeviceAttr = mDeviceDetailSource;

    cnsGetDisplayNames(sDeviceKey, lsNames);

    int iLen = mappinglen(mDeviceAttr);

    for (int i = 1; i <= iLen; i++)
    {
      string sDPE = mDeviceAttr[mappingGetKey(mDeviceAttr, i)];

      if (strpos(sDPE, ".AddInfo[") == 0) //e.g. .AddInfo[location]
      {
        dynAppend(dsAddInfo, strrtrim(substr(sDPE, strpos(sDPE, "[") + 1), "]"));
        dynAppend(dsAddInfoKeys, mappingGetKey(mDeviceAttr, i));
        mappingRemove(mDeviceAttr, mappingGetKey(mDeviceAttr, i));

        i--;
        iLen--;
      }
      else
      {
        dbArrayIndexItem[i] = strpos( sDPE, "[]") > 0;

        if (dbArrayIndexItem[i])
        {
          strreplace(sDPE, "[]", "");
        }

        if (strpos(sDPE, ".AddInfo") == 0) //relative DPE
        {
          sDPE = sEbDriverDP + sDPE;
        }
        else if (strpos(sDPE, ".") == 0) //relative DPE
        {
          sDPE = sDriverConnectionDP + sDPE;
        }

        dynAppend(dsDPEs,sDPE);
      }
    }

    iLen = dynlen(dsDPEs);

    if (dynlen(dsAddInfo) > 0)
    {
      dynAppend(dsDPEs, sEbDriverDP + ".AddInfo");
    }

    dpGet(dsDPEs, daValues);

    mDevice[DriverConst::DEVICE_KEY] = sDeviceKey;
    mDevice[DriverConst::NAME] = EB_LangStringToMapping(lsNames);

    int iDeviceIndex = getDeviceIndex(sDeviceKey); // Search for device index by name

    for (int i = 1; i <= iLen; i++)
    {
      if (dbArrayIndexItem[i] && iDeviceIndex <= dynlen(daValues[i]))
      {
        mDevice[mappingGetKey(mDeviceAttr, i)] = daValues[i][iDeviceIndex];
      }
      else if (!dbArrayIndexItem[i])
      {
        mDevice[mappingGetKey(mDeviceAttr, i)] = daValues[i];
      }
      // The device index is not valid for the connection list, so ignore it for this list
      else if (mappingGetKey(mDeviceAttr, i) != "connectionsAll")
      {
        // This can only occur in case of a driver misconfiguration, so only provide a hint for development
        throw(makeError("", PRIO_WARNING, ERR_IMPL, 54, DRIVER_NAME, "Unable to find value for key: " + mappingGetKey(mDeviceAttr, i) + " index: " + iDeviceIndex + " length: " + dynlen(daValues[i])));
      }
    }

    //copy additional attributes to mapping
    mapping mAddInfo;

    if (dynlen(dsAddInfo) > 0)
    {
      mAddInfo = jsonDecode(daValues[iLen + 1]);
    }

    iLen = dynlen(dsAddInfo);

    dyn_string dsLangStrKeys = makeDynString("location", "description");

    for (int i = 1; i <= iLen; i++)
    {
      if (mappingHasKey( mAddInfo, dsAddInfo[i]))
      {
        if (dynContains(dsLangStrKeys, dsAddInfoKeys[i]) > 0)
        {
          langString lsInfo = EB_mappingToLangString(mAddInfo[dsAddInfo[i]]);
          mDevice[dsAddInfoKeys[i]] = EB_LangStringToMapping(lsInfo);
        }
        else
        {
          mDevice[dsAddInfoKeys[i]] = mAddInfo[dsAddInfo[i]];
        }
      }
      else
      {
        if (dynContains(dsLangStrKeys, dsAddInfoKeys[i]) > 0)
        {
          mDevice[dsAddInfoKeys[i]] = EB_LangStringToMapping("");
        }
        else
        {
          mDevice[dsAddInfoKeys[i]] = "";
        }
      }
    }

    this.updateDeviceMapping(mDevice);

    return mDevice;
  }

  private string createDeviceDp(const langString &lsName, const EBNodeType &nodeType)
  {
    string sDeviceKey = "";
    string sView      = this.getView();

    if (sView != "")
    {
      sDeviceKey = EB_createTag(sView, lsName, nodeType);
    }

    return sDeviceKey;
  }

  private void changeDeviceName(const string &sDeviceKey, const langString &lsName)
  {
    EB_changeTagNames(sDeviceKey, lsName);
  }

  private string getEbDriverDP(const string &sDeviceKey)
  {
    return DRIVER_NAME + this.SEPARATOR + this.getDeviceId(sDeviceKey);
  }

  private void deleteDeviceDp(const string &sDeviceKey, mapping mParams)
  {
    //delete all tags
    dyn_mapping dmTags = this.getTagsForDevice(sDeviceKey);
    dyn_string dsTagKeys;

    for (int i = 1; i <= dynlen(dmTags); i++)
    {
      this.deleteTagDp(dmTags[i][DriverConst::TAG_KEY]);
    }

    if (CONNECTION_TAG_NEEDED)
    {
      this.deleteConnectionTag(sDeviceKey,lsName);
    }

    beforeDeleteDeviceDP(sDeviceKey, mParams);

    string sEbDriverDP = getEbDriverDP(sDeviceKey);
    string sDriverConnectionDP = getDriverConnectionDp(sDeviceKey);

    dyn_string dsDPEs;
    dyn_anytype daValues;
    dyn_bool dbArrayIndexItem;
    mapping mDeviceAttr = mDeviceDetailSource;
    mapping mAddInfo;

    int iLen = mappinglen(mDeviceAttr);
    int iDeviceIndex = getDeviceIndex(sDeviceKey); // Search for device index by name

    for (int i = 1; i <= iLen ; i++)
    {
      string sDPE = mDeviceAttr[mappingGetKey(mDeviceAttr, i)];

      if (strpos( sDPE, ".AddInfo[") == 0) //e.g. .AddInfo[location]
      {
        mappingRemove(mDeviceAttr, mappingGetKey(mDeviceAttr, i));

        i--;
        iLen--;
      }
      else
      {
        dbArrayIndexItem[i] = strpos(sDPE, "[]") > 0;

        if (dbArrayIndexItem[i])
        {
          strreplace(sDPE, "[]", "");
        }

	      if (strpos(sDPE, ".AddInfo") == 0) //relative DPE
        {
          sDPE = sEbDriverDP + sDPE;
        }
        else if (strpos(sDPE, ".") == 0) //relative DPE
        {
          sDPE = sDriverConnectionDP + sDPE;
        }

        if (dbArrayIndexItem[i])
        {
          anytype aTmp;

          dpGet(sDPE, aTmp);

          if (mappingGetKey(mDeviceAttr, i) == "connectionsAll")
          {
            string sDeviceEntry = getDeviceListEntry(sDriverConnectionDP);

            int iIndex = dynContains(aTmp, sDeviceEntry);

            if (iIndex > 0)
            {
              dynRemove(aTmp, iIndex);
            }
          }
          else if(dynlen(aTmp) == 512 || dynlen(aTmp) == 256) //keep lenth
          {
            DebugTN("sDeviceKey",sDeviceKey);
            aTmp[iDeviceIndex] = mParams[mappingGetKey(mDeviceAttr, i)];
          }
          else
          {
            dynRemove(aTmp, iDeviceIndex);
          }

          dynAppend(dsDPEs, sDPE);
          daValues[dynlen(daValues) + 1] = aTmp;
        }
      }
    }

    dpSet(dsDPEs, daValues);

    EB_deleteTag(sDeviceKey);

    EB_logRemoveAll(DRIVER_NAME, LOG_TYPE_ALL, iDeviceIndex);
    EB_logRemoveAll(DRIVER_NAME, LOG_TYPE_ALL, iDeviceIndex + " *");
    EB_logRemoveAll(DRIVER_NAME, LOG_TYPE_CONFIGURATION, "TAG invalid"); //mt: this is not correct - do not remove all TAG logs for all devices
  }

  private void deleteTagDp(const string &sTagKey)
  {
    if (sTagKey != "")
    {
      EB_deleteTag(sTagKey);
    }
  }

  /**
   * @brief Returns the default/empty value for the specified dpe
   * @details The value is used to reset the driver connection dpes
   * @param sDpe   DPE to get the default value for (not used)
   * @return Default empty value
   */
  private static anytype getDefaultValueForDpe(const string &sDpe)
  {
    anytype aResult;

    return aResult;
  }

  /**
   * @brief Returns a subset from the dyn array
   * @details The argument 'iEnd' can be negative to specify that the last x value must not be in the subset
   * @param daValues    Dyn array to get a subset from
   * @param iStart      Start index of the subset
   * @param iEnd        Index of the last value for the subset (default: last element)
   * @return Subset of the dyn array
   */
  private static dyn_anytype dynSub(const dyn_anytype &daValues, int iStart, int iEnd = dynlen(daValues))
  {
    dyn_anytype daResult;
    int iLast = iEnd > 0 ? iEnd : dynlen(daValues) - iEnd;

    for (int i = iStart; i <= iLast; i++)
    {
      daResult[dynlen(daResult) + 1] = daValues[i];
    }

    return daResult;
  }

  private static bool regExpMatch(const dyn_string &dsPatterns, const string &sText)
  {
    bool bResult = FALSE;

    for (int i = 1; i <= dynlen(dsPatterns) && !bResult; i++)
    {
      bResult = regexpIndex(dsPatterns[i], sText, makeMapping("caseSensitive", TRUE)) >= 0;
    }

    return bResult;
  }

  private static string regExpEscape(const string &sLiteral)
  {
    string sResult = sLiteral;

    // For now only the point needs to be escaped, other special characters do not occur in DPEs
    strreplace(sResult, ".", "\\.");

    return sResult;
  }

  const string DPT_DRIVER_CONNECTION  = "_EB_DriverConnection"; //!< Dptype for our driver connection info
  const string SEPARATOR              = "#";                    //!< Separates the driver type from the device instance id in the driver status dp
  const string DPE_DRIVER_STATE       = ".State";               //!< Element holding our driver connection state
  const string DPE_DRIVER_LOCATION    = ".Location";            //!< Element holding our driver location
  const string DPE_DRIVER_DESCRIPTION = ".Description";         //!< Element holding our driver description
  const string DPE_DRIVER_ADDRESS     = ".Address";             //!< Element holding our driver address
};
