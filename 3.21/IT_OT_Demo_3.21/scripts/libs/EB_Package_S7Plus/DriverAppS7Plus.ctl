// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "classes/GenericDriver/DriverApp"

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/**
*/
class DriverAppS7Plus: DriverApp
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  public static const string CONNECTION_DP_PREFIX     = "_S7PlusPLC";
  public static const string DRIVER_NAME              = "S7Plus";
  public static const int    DRIVER_NUMBER            = 10;
  public static const string DRIVER_IDENTIFIER        = "S7PLUS";
  public static const string DRIVER_CONNECTION_DPTYPE = "_S7PlusConnection";
//  use default: public static const dyn_string dsCsvHeaders = makeDynString("active", "tag", "address", "type", "rate","min", "max", "archive", "unit", "format", "desc");

  // For device panel
  public static const mapping mDeviceMetaData = makeMapping("name", makeMapping("type", "langtext",
                                                                              "visible", true,
                                                                              "validation", makeMapping("type", "tag", "allowed", "EBNodeType::STRUCT"),
                                                                              "placeholder", makeMapping("S7Plus", "newPlcIp")),
                                                          "ipaddress", makeMapping("type", "text",
                                                                              "visible", true,
                                                                              "validation", makeMapping("type", "ip", "validationOnApply", true)),
                                                          "plcType", makeMapping("type", "enum",
                                                                                 "visible", true,
                                                                                 "values", makeDynString("Automatic", "S7-1200", "S7-1500", "S7-1500 R/H", "S7-1500-SC", "ET200SP", "PLC-SIM")),
                                                          "location", makeMapping("type", "langtext",
                                                                              "visible", true,
                                                                              "placeholder", makeMapping("S7Plus", "newPlcLocation")),
                                                          "description", makeMapping("type", "langtext_multi",
                                                                              "visible", true,
                                                                              "placeholder", makeMapping("S7Plus", "newPlcDescription"))
      );

  public static const mapping mSettingConversionUItoOA = makeMapping("plcType", makeMapping(
                                                                                            "UI", makeDynString("Automatic", "S7-1200", "S7-1500", "S7-1500 R/H", "S7-1500-SC", "ET200SP", "PLC-SIM"),
                                                                                            "OA", makeDynInt(       0,          272,        16,           16,          528,        528,         768)));

  public static const mapping mDefaultDevice = makeMapping("name",           (langString)"",
                                                           "ipaddress",      "",
                                                           "location",       (langString)"",
                                                           "description",    (langString)"",
                                                           "plcType",        16); //!< 0 = Automatic, 272 (0x110) = S7-1200, 16 (0x10) = S7-1500, 528 (0x210) = S7-1500 SoftPLC, 768 (0x300) = PLCSim

  public static const mapping mDeviceDetailSource = makeMapping("ipaddress",      ".Config.Address",
                                                                "plcType",        ".Config.PLCType",
                                                                "location",       ".AddInfo[location]",
                                                                "description",    ".AddInfo[description]");

  public static const dyn_string CONNECTION_EXCLUDES = makeDynString("^(?!\\.Config\\.).+");                                 //!< Exclude all elements that do not start with '.Config.'
  public static const string     CONNECTION_CHECK    = ".Config.CheckConn";                                                  //!< Add an address config to start the connection establishment to this element
  public static const mapping    CONNECTION_VALUES   = makeMapping(".Config.Codepage",               4,                      //!< Codepage ISO88591
                                                                   ".Config.AccessPoint",            "S7ONLINE",             //!< Activate this connection
                                                                   ".Config.StationName",            "S7Plus$Online|Online", //!< Use online browsing
                                                                   ".Config.DrvNumber",              DRIVER_NUMBER,          //!< Use the driver number from this class
                                                                   ".Config.SetInvalidBit",          TRUE,                   //!< Set the invalid bit in case of failure
                                                                   ".Config.UseUTC",                 TRUE,                   //!< Use UTC as time zone
                                                                   ".Config.KeepAliveTimeout",       20,                     //!< Use the default keep alive interval
                                                                   ".Config.ReconnectTimeout",       20,                     //!< Use the default reconnect interval
                                                                   ".Config.EstablishmentMode",      1,                      //!< Establish the connection
                                                                   ".Config.AcquireValuesOnConnect", TRUE,                   //!< Get the values on connect
                                                                   ".Config.EnableStatistics",       TRUE,                   //!< Enable the statistics
                                                                   ".Config.ReadOpState",            TRUE,                   //!< Read the operating state
                                                                   ".Config.FullTextAlarms",         TRUE,                   //!< Use the full alarm texts
                                                                   ".Config.LegitimationLevel",      -1,                     //!< Do not use TLS
                                                                   ".Command.Enable",                TRUE);                  //!< Enable this connection
  public static const dyn_string CONNECTION_STATE_ELEMENTS = makeDynString(".State.ConnState");   //!< DP elements of the connection dp needed to determine the connection state

  public static const string BROWSE_DPE_REQUEST   = ".Browse.GetBranch";  //!< Element for starting the browsing
  public static const string BROWSE_DPE_RESULT_ID = ".Browse.RequestId";  //!< Element on which to wait for a specific value (request id)

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
  public DriverAppS7Plus()
  {
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Creates a new shared pointer instance
   * @return New instance
   */
  public static shared_ptr<DriverAppS7Plus> createPointer()
  {
    return new DriverAppS7Plus();
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
                           const int &iDirection, string &sConnectionAttributeOnAddress, const uint &uSubindex)
  {
    //connection.address -> add connection to address
    //remove leading "_"
    sConnectionAttributeOnAddress = getDriverConnectionDp(sDeviceKey);
    return sAddress;
  }

  public int getTransformation(const string &sReference, string sType)
  {
    int iResult = 1001;

    dyn_string dsTypes = makeDynString ("DEFAULT", //1001
                                        "BIT",
                                        "BYTE",
                                        "WORD",
                                        "DWORD",   //1005
                                        "LWORD",
                                        "USINT",
                                        "UINT",
                                        "UDINT",
                                        "ULINT",   //1010
                                        "SINT",
                                        "INT",
                                        "DINT",
                                        "LINT",
                                        "REAL",    //1015
                                        "LREAL",
                                        "DATE",
                                        "DT",
                                        "TIME",
                                        "TOD",     //1020
                                        "LDT",
                                        "LTIME",
                                        "LTOD",
                                        "DTL",
                                        "S5TIME",  //1025
                                        "STRING",
                                        "WSTRING");


    if (mappingHasKey(mTranslateTransformationUiToWCC, sType))
    {
      sType = mTranslateTransformationUiToWCC[sType];
    }

    int iPos = dynContains(dsTypes, sType);
    if (iPos > 0)
    {
      iResult = iPos + 1000;
    }

    return iResult;
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------

  protected anytype browseRequestValue(const dyn_string &dsStart, const string &sRequestId)
  {
    return makeDynString(sRequestId,                  // Request ID
                         // Start node: <TIAproj>|<station>|<type [blocks or tags]>|<item [block or tag]>|<block element>
                         "S7Plus$Online|Online|Blocks|" + dynStringToString(dsStart),
                         "1",                         // HMI filter TRUE/FALSE
                         "0");                        // Number of browse levels (0 == unlimited)
  }

  /**
   * @brief Converts the received values into a collection of browse items
   * @param dsDpes      Dpes of the browse result
   * @param daValues    Values from the browse result dpes
   * @return Browse items
   */
  protected vector<BrowseItem> browseResult(const dyn_string &dsDpes, const dyn_anytype &daValues, const string &sParent)
  {
    vector<BrowseItem> vResult;
    string sPrefixToRemove;

    if (dynlen(daValues) >= 5)
    {
      for (int i = 1; i <= dynlen(daValues[1]); i++)
      {
        // Check the 'SystemTypes' value
        if (daValues[4][i] == "Station")
        {
          sPrefixToRemove = daValues[3][i] + ".";
        }
        else if (daValues[4][i] == "Array" || daValues[4][i] == "Block")
        {
          BrowseItem stItem;
          string sPath = daValues[3][i]; // NodePaths
          // Remove the station name
          if (sPrefixToRemove != "" && sPath.startsWith(sPrefixToRemove))
          {
            sPath = sPath.mid(sPrefixToRemove.length());
          }
          stItem.name    = sPath;
          stItem.address = sParent == "" ? sPath : sParent + "." + sPath;
          stItem.extras  = daValues[2][i]; // NodeComments
          stItem.type    = EBTagType::NONE;
          stItem.transformation = "";
          stItem.writeable = FALSE;   //S7 plus arrays and blocks can not be writte by mindsphere/IOT
          vResult.append(stItem);
        }
        else // Variable or Tag
        {
          EBTagType eType = convertType(daValues[5][i]);

          if (eType != EBTagType::NONE)
          {
            BrowseItem stItem;

            string sPath = daValues[3][i]; // NodePaths

            // Remove the station name
            if (sPrefixToRemove != "" && sPath.startsWith(sPrefixToRemove))
            {
              sPath = sPath.mid(sPrefixToRemove.length());
            }

            stItem.name    = sPath;
            stItem.address = sParent == "" ? sPath : sParent + "." + sPath;
            stItem.extras  = daValues[2][i]; // NodeComments
            stItem.type    = eType;
            stItem.transformation = strtoupper(daValues[5][i]);

            if (mappingHasKey(mTranslateTransformationBrowsingToUI, stItem.transformation))
            {
              stItem.transformation = mTranslateTransformationBrowsingToUI[stItem.transformation];
            }

            stItem.writeable = FALSE;   //S7 plus does not inform us if this address is read or writeable, so default is now false

            vResult.append(stItem);
          }
        }
      }
    }

    return vResult;
  }

  static time tLastRestart;
  /**
   * @brief prepare device for browsing (e.g. reconnect to PLC to get new browsing result, which is not cached)
   * @param sDeviceKey                 device key
   */
  protected prepareDeviceForBrowsing(const string &sDeviceKey)
  {
    DebugFTN(DBG_BROWSE, "prepareDeviceForBrowsing: ", tLastRestart, tLastRestart < (getCurrentTime() - 120) );
    synchronized(bConfiurationUpdateLock)
    {
      if (tLastRestart == 0) //nothing to do on first start
      {
        tLastRestart = (getCurrentTime() - 121); //next browsing request, restart driver to ensure correct browsing result
        return;
      }

      if (tLastRestart < (getCurrentTime() - 120) )
      {
        tLastRestart = getCurrentTime();

        //required for S7+ to reset connection to PLC (if PLC programm has been updated)
        string sDp = getDriverConnectionDp(sDeviceKey);

        dyn_anytype daRet;
        bool bTimeout;
        DebugFTN(DBG_BROWSE, "browsing prepare device wait for reconnection");

        dpSetWait(sDp + ".Command.Enable:_original.._value", FALSE);

        dpSetAndWaitForValue(makeDynString(sDp + ".Command.Enable:_original.._value"), makeDynAnytype(TRUE),
                             makeDynString(sDp + ".State.ConnState:_original.._value"), makeDynAnytype((uint)3), //wait until reconnected
                             makeDynString(), daRet, PLC_CONNECTION_TIMEOUT, bTimeout);

        if (!bTimeout) //give device connection 1 sec time before browsing request
          delay(1);

        DebugFTN(DBG_BROWSE, "browsing prepare device reconnected = " + (!bTimeout), sDeviceKey, sDp);
      }
    }
  }

  /**
   * @brief if drivers requires reestablish connection, derived driver app can disconnect an reconnect on device change (e.g. IP address has been changed)
   * @param sDeviceKey           the device key
   * @param sDriverConnectionDP  connection DP for device
   * @return bConnect            trigger connect or disconnect
   */
  protected void connectDeviceOnDeviceChange(string sDeviceKey, string sDriverConnectionDP, bool bConnect=TRUE)
  {
    dpSetWait(sDriverConnectionDP + ".Config.EstablishmentMode", bConnect?1:0);
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
  private static EBTagType convertType(const string &sPlcType)
  {
    EBTagType eResult = EBTagType::NONE;

    switch (strtoupper(sPlcType))
    {
      case "BOOL":
      case "BOOLEAN":       eResult = EBTagType::BOOL;   break;
      case "BYTE":          eResult = EBTagType::UINT;   break;
      case "DATE":          eResult = EBTagType::TIME;   break;
      case "DATE_AND_TIME": eResult = EBTagType::TIME;   break;
      case "DINT":          eResult = EBTagType::INT;    break;
      case "DTL":           eResult = EBTagType::TIME;   break;
      case "DWORD":         eResult = EBTagType::UINT;   break;
      case "WORD":          eResult = EBTagType::UINT;   break;
      case "INT":           eResult = EBTagType::INT;    break;
      case "LDT":           eResult = EBTagType::TIME;   break;
      case "LINT":          eResult = EBTagType::LONG;   break;
      case "LREAL":         eResult = EBTagType::FLOAT;  break;
      case "LTIME":         eResult = EBTagType::TIME;   break;
      case "LTIME_OF_DAY":  eResult = EBTagType::TIME;   break;
      case "LWORD":         eResult = EBTagType::ULONG;  break;
      case "REAL":          eResult = EBTagType::FLOAT;  break;
      case "S5TIME":        eResult = EBTagType::TIME;   break;
      case "SINT":          eResult = EBTagType::INT;    break;
      case "STRING":        eResult = EBTagType::STRING; break;
      case "TIME":          eResult = EBTagType::TIME;   break;
      case "TIME_OF_DAY":   eResult = EBTagType::TIME;   break;
      case "UDINT":         eResult = EBTagType::UINT;   break;
      case "UINT":          eResult = EBTagType::UINT;   break;
      case "ULINT":         eResult = EBTagType::ULONG;  break;
      case "USINT":         eResult = EBTagType::UINT;   break;
      case "WORD":          eResult = EBTagType::UINT;   break;
      case "WSTRING":       eResult = EBTagType::STRING; break;
    }

    return eResult;
  }

  private static mapping mTranslateTransformationBrowsingToUI = makeMapping(//not implemented in S7+
                                                                            "CHAR", "USINT",
                                                                            "WCHAR", "UINT",
                                                                            //browsing result differs from address config settings
                                                                            "LTIME_OF_DAY", "LTOD",
                                                                            "LDT", "LDATETIME",
                                                                            "DATE_AND_TIME", "DATETIME");

  private static mapping mTranslateTransformationUiToWCC = makeMapping("DATETIME", "DT",
                                                                       "TIME_OF_DAY", "TOD",
                                                                       "LDATETIME", "LDT",
                                                                       "BOOL", "BIT");
  private static int PLC_CONNECTION_TIMEOUT = 30; //30 sec. for reconnect on browsing request
  private static bool bRegisteredDriver = Factory::registerPlugin(DRIVER_NAME, createPointer);  //!< Register this driver plugin
};
