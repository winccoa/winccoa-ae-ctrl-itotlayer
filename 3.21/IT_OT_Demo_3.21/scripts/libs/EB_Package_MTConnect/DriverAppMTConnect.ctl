// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "EB_Package_MTConnect/MTClientLib"
#uses "classes/GenericDriver/DriverApp"

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/**
*/
class DriverAppMTConnect: DriverApp
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  public static const string CONNECTION_DP_PREFIX     = "_MTConnect";
  public static const string DRIVER_NAME              = "MTConnect";
  public static const int    DRIVER_NUMBER            = -1;
  public static const string DRIVER_IDENTIFIER        = "MTConnect";
  public static const string DRIVER_CONNECTION_DPTYPE = "_MTConnect";

  public static const string BROWSE_DPE_REQUEST       = "-";          //!< Element for starting the browsing "-" is not used, but broswsing feature is activated
  public static const bool   POLLRATE_VIA_TAG         = FALSE;        //!< define that polling is defined per device and not per tag

//  use default: public static const dyn_string dsCsvHeaders = makeDynString("active", "tag", "address", "type", "rate","min", "max", "archive", "unit", "format", "desc");

  // For device panel
  public static const mapping mDeviceMetaData = makeMapping();

  public static const mapping mDefaultDevice = makeMapping("name",           (langString)"",
                                                           "ipaddress",      "",
                                                           DriverConst::POLLRATE,     10,
                                                           "LastUpdate",     0,
                                                           "LastInstanceId",     1,
                                                           "location",       (langString)"",
                                                           "description",    (langString)"",
                                                           "connectionDpe",  "<ConnectionDPE>",
                                                           "polledDP",  "");

  public static const mapping mDeviceDetailSource = makeMapping("ipaddress",           "_MTDevices.URL[]",
                                                                DriverConst::POLLRATE, "_MTDevices.PollRate[]",
                                                                "LastUpdate",          "_MTDevices.LastUpdate[]",
                                                                "LastInstanceId",      "_MTDevices.LastInstanceId[]",
                                                                "description",         "_MTDevices.Description[]",
                                                                "connectionDpe",       "_MTDevices.ConnectionDpe[]",
                                                                "polledDP",            "_MTDevices.PolledDP[]");



  public static const dyn_string CONNECTION_EXCLUDES = makeDynString();                 //!< Prevent a time sync on a configuration change
  public static const mapping    CONNECTION_VALUES   = makeMapping(".DevNr",         "<DeviceId>",      //!< This place holder is replaced with the actual device number
                                                                   ".Active",        TRUE,              //!< Activate this connection
                                                                   ".DrvNumber",     DRIVER_NUMBER,     //!< Use the driver number from this class
                                                                   ".SetInvalidBit", TRUE);             //!< Set the invalid bit in case of failure
  public static const dyn_anytype CONNECTION_STATE_OK       = makeDynAnytype(1, 2);                     //!< Connection state values, that indicate a connected state
  public static const dyn_anytype CONNECTION_STATE_WARNING  = makeDynAnytype(3);                        //!< Connection state values, that indicate a connection warning


  // For the tag table
  public static const mapping mTagMetaData =
            makeMapping("active", makeMapping("type", "bool",
                                              "visible", false,
                                              "defaultValues", true),
                        "tagkey", makeMapping("type" , "text",
                                              "visible", true),
                        "name", makeMapping("type" , "langtext",
                                           "visible", true),
                        "desc", makeMapping("type","langtext",
                                                   "visible",true),
                        "address", makeMapping("type" , "text",
                                               "visible", true,
                                               "placeholder", "*.DB*.DB*",
                                               "visible", true),
                        "subindex", makeMapping("type", "number",
                                                "visible", true),
                        "datatype", makeMapping("type", "EBTagType",
                                                "visible", true,
                                                "validation", makeMapping("type", "text", "values", makeDynString("BOOL", "INT", "FLOAT", "STRING", "NONE")),
//                                                 "defaultValues", "NONE",
                                                "onChange", makeMapping("defaultValues", makeMapping("BOOL", makeMapping("format", ""),
                                                                                                     "INT", makeMapping("format", ""),
                                                                                                     "FLOAT", makeMapping("format", "%0.2"),
                                                                                                     "STRING", makeMapping("format", "")
                                                                                                     )
                                                                        )
                                                ),
                        "rate", makeMapping("type", "text",
                                                "visible", true,
                                                "defaultValues", "1s",
                                                "validation", makeMapping("type", "text", "values", makeDynString("1s", "5s", "10s"))
                                               ),
                        "value", makeMapping("type", "text",
                                             "visible", true),
                        "archive", makeMapping("type", "bool",
                                               "visible", false,
                                               "defaultValues", true),
                        "format", makeMapping("type", "text",
                                              "visible", false),
                        "unit", makeMapping("type", "text",
                                            "visible", false),
                        "columnOrder", makeDynString("active", "tagkey", "name", "desc", "address", "subindex", "datatype", "rate", "value", "archive", "format", "unit")
            );


  //todo delete und create in die allgemeine classe


  public static const mapping mTagDetailSource = makeMapping("Address", "_refstring",
                                                             "Pollrate", "_pollgroup"/*,
                                                             "direction", "_S7_Config.Rack[]"*/);
//   public static const mapping mDeviceDetailMeta =   makeMapping("DeviceType", makeMapping("S7 1500",makeMapping("RACK",1,"SLOT",4))), "Ipaddress", IP);

//"location", ".AddInfo[location]"
//   protected mapping mDeviceDetailSource = makeMapping("IP", ".IPAddress", "TYPE", ".ConnectionType", "RACK", ".Rack", "SLOT", ".Slot");

  //------------------------------------------------------------------------------
  /**
   * @brief Default constructor.
   */
  public DriverAppMTConnect()
  {
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Creates a new shared pointer instance
   * @return New instance
   */
  public static shared_ptr<DriverAppMTConnect> createPointer()
  {
    return new DriverAppMTConnect();
  }

  public string getTagAddress(const string &sTagKey)
  {
    string sRef = DriverApp::getTagAddress(sTagKey); //connection.address -> remove connection
    int    iPos = strpos(sRef, ".");

    if (iPos > 0)
    {
      sRef = substr(sRef, iPos + 1);
    }

    return sRef;
  }

  public string getTagAddressRefstring(const string &sAddress, const string &sDeviceKey)
  {

  }

  public string setupReferenceString(const string &sDeviceKey, const string &sTagKey, const langString &lsDescription, const string &sAddress, const EBTagType &tagType, const string &sRefreshRate,
                                     const bool &bActive, const bool &bArchive, const string &sFormat, const langString &lsUnit, const int &iTransformation,
                                     const int &iDirection, const string &sConnectionAttributeOnAddress, const uint &uSubindex)
  {
    //connection.address -> add connection to address
    //remove leading "_"
    //MTConnect does not have address config, service.ctl need to get this information via DPE


    int iDeviceIndex = getDeviceIndex(sDeviceKey); // Search for device index by name

    //search for device and tag
    int iDevice = 0;
    int iTag = 0;

    if (dynlen(dmDeviceTagList) == 0)
    {
      dmDeviceTagList = initFromJson();
    }

    for(int i = 1; i <= dynlen(dmDeviceTagList) && iDevice == 0; i++)
    {
      if (dmDeviceTagList[i]["NodeId"] == iDeviceIndex)
      {
        iDevice = i;
      }
    }
    if (iDevice == 0)
    {
      iDevice = 1;
      dmDeviceTagList[iDevice] = makeMapping("NodeId", iDeviceIndex, "TagList", makeDynMapping());
    }
    else
    {
      //search for tag

      for(int i = 1; i <= dynlen(dmDeviceTagList[iDevice]["TagList"]) && iTag == 0; i++)
      {
        if (dmDeviceTagList[iDevice]["TagList"][i]["NodeId"] == sTagKey)
        {
          iTag = i;
          dmDeviceTagList[iDevice]["TagList"][iTag]["Address"] = strpos(sAddress, dmDeviceTagList[iDevice]["DP"]) == 0 ? sAddress : dmDeviceTagList[iDevice]["DP"] + "." + sAddress;
        }
      }
    }

    if (iTag == 0)
    {
      iTag = dynlen(dmDeviceTagList[iDevice]["TagList"])+1;
      dmDeviceTagList[iDevice]["TagList"][iTag] = makeMapping("NodeId", sTagKey, "Address", strpos(sAddress, dmDeviceTagList[iDevice]["DP"]) == 0 ? sAddress : dmDeviceTagList[iDevice]["DP"] + "." + sAddress);
    }

    dpSet("EB_MTConnect.DeviceList", jsonEncode(dmDeviceTagList));

    return strpos(sAddress, dmDeviceTagList[iDevice]["DP"]) == 0 ? sAddress : dmDeviceTagList[iDevice]["DP"] + "." + sAddress;
  }

  public void deleteTag(const mapping &mParams, mapping &mResult)
  {
    string sTagKey = mParams[DriverConst::TAG_KEY];
    string sDeviceKey;
    cnsGetParent(sTagKey, sDeviceKey);

    int iDeviceIndex = getDeviceIndex(sDeviceKey); // Search for device index by name

    //remove tag from DeviceList dp
    //search for device and tag
    int iDevice = 0;
    int iTag = 0;

    if (dynlen(dmDeviceTagList) == 0)
    {
      dmDeviceTagList = initFromJson();
    }

    for(int i = 1; i <= dynlen(dmDeviceTagList) && iDevice == 0; i++)
    {
      if (dmDeviceTagList[i]["NodeId"] == iDeviceIndex)
      {
        iDevice = i;
      }
    }
    if (iDevice != 0)
    {
      //search for tag

      for(int i = dynlen(dmDeviceTagList[iDevice]["TagList"]); i > 0  && iTag == 0; i--)
      {
        if (dmDeviceTagList[iDevice]["TagList"][i]["NodeId"] == sTagKey)
        {
          iTag = i;
          dynRemove(dmDeviceTagList[iDevice]["TagList"], iTag);
        }
      }
    }

  // deleteTag
    dpSet("EB_MTConnect.DeviceList", jsonEncode(dmDeviceTagList));

    DriverApp::deleteTag( mParams, mResult);
  }

  /**
   * @brief defines if deleting or changing source requires reset of driver
   * @param sDeviceKey    the device key
   * @return TRUE for reset of driver is required on deleting devices or modify of data source address (IP / URL)
   */
  public bool isDriverRecoveryOnSourceChangeRequired()
  {
    dpGet("_MTDevices.PolledDP", dsDPsToRemove);
    return TRUE;
  }


  /**
   * @brief recoery function after delting all devices before re adding devices
   */
  public bool doDriverRecovery()
  {
    for (int i = dynlen(dsDPsToRemove); i > 0; i--)
    {
      if (dpExists(dsDPsToRemove[i]))
      {
        dpDelete(dsDPsToRemove[i]);
        if (dpTypeExists("MTC_"+dsDPsToRemove[i]))
        {
          dpTypeDelete("MTC_"+dsDPsToRemove[i]);
        }
      }
    }
  }

  protected void postUpdateDeviceDp(const string &sDeviceKey, const langString &lsName, const langString &lsLocation, const langString &lsDescription, const string &sAddress, const mapping &mAdditionalParams)
  {
    //run base code and update DeviceList json
    DriverApp::postCreateDeviceDp(sDeviceKey, lsName, lsLocation, lsDescription, sAddress, mAdditionalParams);

    int iDeviceIndex = getDeviceIndex(sDeviceKey); // Search for device index by name

    //search for device and tag
    int iDevice = 0;

    if (dynlen(dmDeviceTagList) == 0)
    {
      dmDeviceTagList = initFromJson();
    }

    dyn_string dsDPs;
    dpGet("_MTDevices.PolledDP", dsDPs);

    for(int i = 1; i <= dynlen(dmDeviceTagList) && iDevice == 0; i++)
    {
      if (dmDeviceTagList[i]["NodeId"] == iDeviceIndex)
      {
        iDevice = i;
        dmDeviceTagList[i]["DP"] = dsDPs[iDeviceIndex];
      }
    }
    if (iDevice == 0)
    {
      iDevice = dynlen(dmDeviceTagList) + 1;

      dmDeviceTagList[iDevice] = makeMapping("NodeId", iDeviceIndex, "TagList", makeDynMapping(), "DP", dsDPs[iDeviceIndex]);
    }

    dpSet("EB_MTConnect.DeviceList", jsonEncode(dmDeviceTagList));
  }

  protected void preDeleteDeviceDp(const string &sDeviceKey, const mapping &mParams)
  {
    //remove device from DeviceList json

    int iDeviceIndex = getDeviceIndex(sDeviceKey); // Search for device index by name

    //remove tag from DeviceList dp
    //search for device and tag
    int iDevice = 0;

    if (dynlen(dmDeviceTagList) == 0)
    {
      dmDeviceTagList = initFromJson();
    }

    for(int i = 1; i <= dynlen(dmDeviceTagList) && iDevice == 0; i++)
    {
      if (dmDeviceTagList[i]["NodeId"] == iDeviceIndex)
      {
        iDevice = i;
      }
    }
    if (iDevice != 0)
    {
      //remove device
      dynRemove(dmDeviceTagList, iDevice);
    }

// deleteTag
    dpSet("EB_MTConnect.DeviceList", jsonEncode(dmDeviceTagList));
    //delete connection dp and run standard code
    DriverApp::preDeleteDeviceDp(sDeviceKey, mParams);
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
    return 0;
  }

  /**
   * @brief Sets the tag address active/inactive
   * @param sNodeId  The tag id where the configs will be set
   * @param bActive  If the address is active or not
   * @return 0 in case of success, otherwise -1
   */
  protected int setActiveForTag(const string &sNodeId, bool bActive)
  {
    return 0;
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------

  /**
   * @brief function to do manual browsing instead of getting browsing result via DPE
   * @param sDeviceKey                 device key
   * @param sFilter                    filter pattern
   * @param iStart                     result start index
   * @param iMaxResultRows             max number of lines before splitting browsing result
   * @param sParent                    parent start node
   * @param dsDpeNodeName              array Dpes of the browse result
   * @param daDpeNodeType              array values from the browse result dpes
   * @return 0 ok, no failure
   */
  protected bool manualBrowsing(const string &sDeviceKey, const string &sFilter, int iStart, int iMaxResultRows, const string &sParent, dyn_string &dsDpeNodeName, dyn_anytype &daDpeNodeType)
  {
    int iDeviceIndex = getDeviceIndex(sDeviceKey); // Search for device index by name

    //get device number
    dyn_string dsDpes;
    dpGet("_MTDevices.PolledDP", dsDpes);
    int iDevId = getDeviceId(sDeviceKey);
    string sDpt = "MTC_" + dsDpes[iDevId];


    dyn_dyn_string ddsElements;
    dyn_dyn_int ddiTypes;

    //read type strcture
    dpTypeGet(sDpt, ddsElements, ddiTypes);

    dyn_string dsLevelsElement;

    if ( dynlen(ddsElements) > 0) //remvoe "MTC_" from root node
    {
      ddsElements[1][1] = substr( ddsElements[1][1], 4);
    }

    //collect arrays of names and DPE types
    for (int i = 1; i <= dynlen(ddsElements); i++)
    {
      int iLevel = dynlen(ddsElements[i]);
      dsLevelsElement[iLevel] = ddsElements[i][iLevel];
      string sName;
      for (int j = 1; j <= iLevel; j++) //first level is onl the root element
      {
        sName += (j != 1 ? "." : "") + dsLevelsElement[j];
      }

      dynAppend(daDpeNodeType, ddiTypes[i][iLevel]);
      dynAppend(dsDpeNodeName, sName);
    }

    return FALSE;
  }

  /**
   * @brief Converts the received values into a collection of browse items
   * @param dsDpes      dpe names
   * @param daValues    dpe types
   * @param sParent     parent start node
   * @return Browse items
   */
  protected vector<BrowseItem> browseResult(const dyn_string &dsDpeNodeName, const dyn_anytype &daLevelsElement, const string &sParent)
  {
    vector<BrowseItem> vResult;

    for (int i = 1; i <= dynlen(dsDpeNodeName); i++)
    {
      EBTagType eType;
      //get type from DPE TYPE (int)
      switch(daLevelsElement[i]) //allowed MTConnect types
      {
        case DPEL_STRING: eType = EBTagType::STRING; break;
        case DPEL_FLOAT:  eType = EBTagType::FLOAT; break;
        case DPEL_UINT:   eType = EBTagType::UINT; break;
        case DPEL_INT:    eType = EBTagType::INT; break;
        case DPEL_TIME:   eType = EBTagType::TIME; break;
        case DPEL_BOOL:   eType = EBTagType::BOOL; break;
        default:          eType = EBTagType::NONE; break;
      }

      BrowseItem stItem;
      dyn_string dsDpeNodeNameSplit = strsplit(dsDpeNodeName[i], ".");
      string sDpeNodeName;

      if(dsDpeNodeNameSplit.count() > 1)
      {
        dsDpeNodeNameSplit.removeAt(0);
        sDpeNodeName = strjoin(dsDpeNodeNameSplit, ".");
      }
      else
      {
        sDpeNodeName = dsDpeNodeNameSplit.first();
      }

      stItem.name    = sDpeNodeName;
      stItem.address = sDpeNodeName;
      stItem.extras  = ""; // NodeComments
      stItem.type    = eType;
      stItem.transformation = ""; //there is no tranformation suppored by MTConnect ctrl script
      stItem.writeable = FALSE;   //MTConnect does not support writeable addresses

      vResult.append(stItem);
    }

    return vResult;
  }

  /**
   * @brief function to modify datpoints, which is called at begin of updateDeviceDp()
   * @param sDeviceKey     device key
   * @param mParams        configuration mapping for the device
   */
  protected void beforeUpdateDeviceDP(const string &sDeviceKey, mapping &mParams)
  {
    if (mParams["connectionDpe"] == "<ConnectionDPE>")
      mParams["connectionDpe"] = getDriverConnectionDp(sDeviceKey, true) +".ConnState";
    //do probe
    //update timestamp
    string sStatus;
    string sLastInstance;
    shared_ptr<MTClientLib> spMTClientLib = new MTClientLib();

    int iError = spMTClientLib.getConfig(mParams[DriverConst::IPADDRESS], sStatus, sLastInstance, getDeviceIndex(sDeviceKey));
    string sPolledDP = spMTClientLib.getDeviceDp();

    mParams["polledDP"]       = sPolledDP;
    mParams["LastUpdate"]     = getCurrentTime();
    mParams["LastInstanceId"] = sLastInstance;
  }

  /**
   * @brief Returns the process name of this driver
   * @return Process name of the driver
   */

  protected string getProcessName()
  {
    return "WCCOActrl EB_Package_MTConnect/Service.ctl";
  }


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  private static dyn_mapping initFromJson()
  {
    string sJson;
    dpGet("EB_MTConnect.DeviceList", sJson);
    dyn_mapping dmTmp;
    if (sJson != "")
    {
      dmDeviceTagList = jsonDecode(sJson);
    }
    return dmTmp;
  }
  private static dyn_mapping dmDeviceTagList;
  private static bool bRegisteredDriver = Factory::registerPlugin(DRIVER_NAME, createPointer);  //!< Register this driver plugin
  private static dyn_string dsDPsToRemove;
};
