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
class DriverAppSinumerik: DriverApp
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  public static const string CONNECTION_DP_PREFIX     = "_SinumerikPLC";
  public static const string DRIVER_NAME              = "Sinumerik";
  public static const int    DRIVER_DEVICE_ID_OFFSET  = -257;             //!< Offset for the '<DeviceId>' setting of the driver config (can also be negative, the abs function is used to get a positive device number)
  public static const int    DRIVER_NUMBER            = 2;
  public static const string DRIVER_IDENTIFIER        = "S7";
  public static const string DRIVER_CONNECTION_DPTYPE = "_S7_Conn";
  public static const string DRIVER_DEPENDENCY        = "S7";             //!< Used for Add/Remove Driver - functionality(For example "Sinumerik" depends on "S7" and vice versa)
  public static const string DRIVER_PACKAGE_ALTERNATIVE_INIFILE = "S7";

//  use default: public static const dyn_string dsCsvHeaders = makeDynString("active", "tag", "address", "type", "rate","min", "max", "archive", "unit", "format", "desc");

  // For the device panel
  public static const mapping mDeviceMetaData = makeMapping("name", makeMapping("type", "langtext",
                                                                              "visible", true,
                                                                              "validation", makeMapping("type", "tag", "allowed", "EBNodeType::STRUCT"),
                                                                              "placeholder", makeMapping("Sinumerik", "newPlcIp")),
                                                          "ipaddress", makeMapping("type", "text",
                                                                              "visible", true,
                                                                              "validation", makeMapping("type", "ip", "validationOnApply", TRUE)),
                                                          "plcType", makeMapping("type", "enum",
                                                                                 "visible", true,
                                                                                 "values", makeDynString("Sinumerik"),
                                                                                 "onChange", makeMapping("defaultValues", makeMapping("Sinumerik", makeDynMapping(makeMapping(DriverConst::SLOT, 2), makeMapping("deviceRack", 0))),
                                                                                                         "visible", makeMapping("Sinumerik", makeDynMapping(makeMapping("tsapPc", FALSE), makeMapping("tsapPlc", FALSE), makeMapping(DriverConst::SLOT, TRUE), makeMapping("deviceRack", FALSE)))
                                                                                                         )
                                                                                 ),
                                                          "tsapPc", makeMapping("type", "text",
                                                                              "visible", false,
                                                                              "validation", makeMapping("type", "string", "pattern", "*.*")),
                                                          "tsapPlc", makeMapping("type", "text",
                                                                              "visible", false,
                                                                              "validation", makeMapping("type", "string", "pattern", "*.*")),
                                                          DriverConst::SLOT, makeMapping("type", "text",
                                                                              "visible", true,
                                                                              "validation", makeMapping("type", "int", "values", makeDynInt(1, 2, 3, 4, 5, 6))),
                                                          "location", makeMapping("type", "langtext",
                                                                              "visible", true,
                                                                              "placeholder", makeMapping("Sinumerik", "newPlcLocation")),
                                                          "description", makeMapping("type", "langtext_multi",
                                                                              "visible", true,
                                                                              "placeholder", makeMapping("Sinumerik", "newPlcDescription"))
      );

  public static const mapping mDefaultDevice = makeMapping("name",           (langString)"",
                                                           "ipaddress",      "",
                                                           "deviceType",     768,          // 0 = PG (Programming device) 1 = OP (Operator/HMI), 2 = Other
                                                           "deviceRack",     0,
                                                           DriverConst::SLOT,     3,
                                                           "location",       (langString)"",
                                                           "description",    (langString)"",
                                                           "plcType",        "Sinumerik 840D",  // TODO confirm the default sinumerik name
                                                           "tsapPc",         "",
                                                           "tsapPlc",        "",
                                                           "timeout",        5000,
                                                           "tsppExtras",     "",
                                                           "protocolExtras", "",
                                                           "connectionsAll", "");

  public static const mapping mDeviceDetailSource = makeMapping("ipaddress",      "_S7_Config.IPAddress[]",
                                                                "deviceType",     "_S7_Config.ConnectionType[]",
                                                                "deviceRack",     "_S7_Config.Rack[]",
                                                                DriverConst::SLOT,     "_S7_Config.Slot[]",
                                                                "timeout",        "_S7_Config.Timeout[]",
                                                                "tsppExtras",     "_S7_Config.TSPPExtras[]",
                                                                "protocolExtras", "_S7_Config.ProtocolExtras[]",
                                                                "connectionsAll", "_S7_Config.Connections.All[]",
                                                                "location",       ".AddInfo[location]",
                                                                "description",    ".AddInfo[description]",
                                                                "plcType",        ".AddInfo[plcType]",
                                                                "tsapPc",         ".AddInfo[tsapPc]",
                                                                "tsapPlc",        ".AddInfo[tsapPlc]");

  public static const dyn_string CONNECTION_EXCLUDES = makeDynString(".Time.SyncTime");            //!< Prevent a time sync on a configuration change
  public static const mapping    CONNECTION_VALUES   = makeMapping(".DevNr",         "<DeviceId>", //!< This place holder is replaced with the actual device number
                                                                   ".Active",        TRUE,         //!< Activate this connection
                                                                   ".DrvNumber",     DRIVER_NUMBER,//!< Use the driver number from this class
                                                                   ".SetInvalidBit", TRUE);        //!< Set the invalid bit in case of failure
  public static const dyn_anytype CONNECTION_STATE_OK       = makeDynAnytype(1);                   //!< Connection state values, that indicate a connected state
  public static const dyn_anytype CONNECTION_STATE_WARNING  = makeDynAnytype(3);                   //!< Connection state values, that indicate a connection warning
  public static const dyn_string CONNECTION_STATE_ELEMENTS = makeDynString(".ConnState");          //!< Include the operating to provide a warning if the PLC program is stopped

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
  public DriverAppSinumerik()
  {
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Creates a new shared pointer instance
   * @return New instance
   */
  public static shared_ptr<DriverAppSinumerik> createPointer()
  {
    return new DriverAppSinumerik();
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

    return strltrim(getDriverConnectionDp(sDeviceKey), "_") + "." + sAddress;
  }

  public int getTransformation(const string &sReference, string sType)
  {
    int iResult;

    dyn_string dsTypes = makeDynString ("INT16", //701
                                        "INT32",
                                        "UINT16",
                                        "BYTE",
                                        "FLOAT", //705
                                        "BIT",
                                        "STRING",
                                        "UINT32",
                                        "DATEANDTIME",
                                        "BLOB",  //710
                                        "BITSTRING",
                                        "TIMESPAN",
                                        "TIMEOFDAY",
                                        "S5TIME",
                                        "TIMER",  //715
                                        "COUNTER",
                                        "DATE",
                                        "DTL"); //DATETIMELONG

    mapping mTranslate = makeMapping("DATETIMELONG", "DTL");
    if (mappingHasKey(mTranslate, sType))
    {
      sType = mTranslate[sType];
    }

    int iPos = dynContains(dsTypes, sType);
    if (iPos > 0)
    {
      iResult = iPos + 700;
    }
    else
    {
      dyn_string dsCaptures;

      if (sType == "INT" || sType == "UINT")
      {
        regexpSplit("(A|E|M|DB\\d+\\.DB)(B|D|W)\\d+", sReference, dsCaptures);
      }
      switch (sType)
      {
        case "BOOL":
          iResult = 706;       // bool transformation
          break;
        case "INT":
          iResult = 702;       // int32 transformation

          if (dynlen(dsCaptures) >= 3 && strtoupper(dsCaptures[3]) == "W")
          {
            iResult = 701;     // int16 transformation
          }
          else if (dynlen(dsCaptures) >= 3 && strtoupper(dsCaptures[3]) == "B")
          {
            iResult = 704;     // byte transformation
          }
          break;
        case "TIME":
          iResult = 709;       // time transformation
          break;
        case "UINT":           // not used in Mindsphere
          iResult = 708;       // uint32 transformation

          if (dynlen(dsCaptures) >= 3 && strtoupper(dsCaptures[3]) == "W")
          {
            iResult = 703;     // uint16 transformation
          }
          else if (dynlen(dsCaptures) >= 3 && strtoupper(dsCaptures[3]) == "B")
          {
            iResult = 704;     // byte transformation
          }
          break;
      }
    }
    return iResult;
  }

  /**
   * @brief if drivers requires reestablish connection, derived driver app can disconnect an reconnect on device change (e.g. IP address has been changed)
   * @param sDeviceKey           the device key
   * @param sDriverConnectionDP  connection DP for device
   * @return bConnect            trigger connect or disconnect
   */
  protected void connectDeviceOnDeviceChange(string sDeviceKey, string sDriverConnectionDP, bool bConnect=TRUE)
  {
    dpSetWait(sDriverConnectionDP + ".Active", bConnect);
  }
  protected void postUpdateDeviceDp(const string &sDeviceKey, const langString &lsName, const langString &lsLocation, const langString &lsDescription, const string &sAddress, const mapping &mAdditionalParams)
  {
  //  DebugN("adddddd", getDriverConnectionDp(sDeviceKey) + ".Address"); //[_S7_Con]System1:_SinumerikPLC1.Address
    dpSet(getDriverConnectionDp(sDeviceKey) + ".Address",
          jsonEncode(makeMapping("TSPPExtras","","ConnectionType",mAdditionalParams["deviceType"],"TimeOut",mAdditionalParams["timeout"],"Slot",mAdditionalParams["deviceSlot"],"ProtocolExtras","","Rack",mAdditionalParams["deviceRack"],"IPAddress",sAddress)));
    // DRIVER_CONNECTION_DPTYPE
    //{"TSPPExtras":"","ConnectionType":768,"TimeOut":5000,"Slot":2,"ProtocolExtras":"","Rack":0,"IPAddress":"12.23.12.23"}
  }
//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
  private static bool bRegisteredDriver = Factory::registerPlugin(DRIVER_NAME, createPointer);  //!< Register this driver plugin
};
