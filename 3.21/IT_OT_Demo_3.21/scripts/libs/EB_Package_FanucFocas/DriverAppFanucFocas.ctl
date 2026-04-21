// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author Schiefer Martin
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "classes/GenericDriver/DriverApp"

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/**
*/
class DriverAppFanucFocas: DriverApp
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  public static const string CONNECTION_DP_PREFIX     = "_FanucFocas_Plc_"; //_FocasConnection - _FanucFocas_Plc_1.
  public static const string DRIVER_NAME              = "FanucFocas";
  public static const int    DRIVER_NUMBER            = 11;
  public static const string DRIVER_IDENTIFIER        = "FOCAS";
  public static const string DRIVER_CONNECTION_DPTYPE = "_FocasConnection"; //_EB_DriverConnection - FanucFocas#1.

  public static const string BROWSE_DPE_REQUEST       = "-";          //!< Element for starting the browsing
//  use default: public static const dyn_string dsCsvHeaders = makeDynString("active", "tag", "address", "type", "rate","min", "max", "archive", "unit", "format", "desc");

  // For device panel
  public static const mapping mDeviceMetaData = makeMapping(
      );

  public static const mapping mDefaultDevice = makeMapping("name",           (langString)"",
                                                           "ipaddress",      "127.0.0.1:8193",
                                                           "location",       (langString)"",
                                                           "description",    (langString)"",
                                                           "LifebeatTimeout",      10,
                                                           "ReconnectTimeout",     10,
                                                           "EstablishmentMode",     1,
                                                           "connectionsAll", "");

  public static const mapping mDeviceDetailSource = makeMapping("ipaddress",         ".Config.Address", //_FanucFocas_Plc_1.Config.Address
                                                                "LifebeatTimeout",   ".Config.LifebeatTimeout",
                                                                "ReconnectTimeout",  ".Config.ReconnectTimeout",
                                                                "EstablishmentMode", ".Config.EstablishmentMode",
                                                                "location",          ".AddInfo[location]",                 //from type _EB_DriverConnection e.g. FanucFocas#1
                                                                "description",       ".AddInfo[description]");

  public static const dyn_string CONNECTION_EXCLUDES = makeDynString(".Time.SyncTime");                 //!< Prevent a time sync on a configuration change
  public static const mapping    CONNECTION_VALUES   = makeMapping(".Command.Enable",        TRUE,              //!< Activate this connection
                                                                   ".Config.DrvNumber",     DRIVER_NUMBER,     //!< Use the driver number from this class
                                                                   ".Config.SetInvalidBit", TRUE);             //!< Set the invalid bit in case of failure
  public static const dyn_string CONNECTION_STATE_ELEMENTS = makeDynString(".State.ConnState");         //!< Include the operating to provide a warning if the PLC program is stopped

  // For the tag table
  public static const mapping mTagMetaData =
            makeMapping();


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
  public DriverAppFanucFocas()
  {
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Creates a new shared pointer instance
   * @return New instance
   */
  public static shared_ptr<DriverAppFanucFocas> createPointer()
  {
    return new DriverAppFanucFocas();
  }


  public string setupReferenceString(const string &sDeviceKey, const string &sTagKey, const langString &lsDescription, const string &sAddress, const EBTagType &tagType, const string &sRefreshRate,
                           const bool &bActive, const bool &bArchive, const string &sFormat, const langString &lsUnit, const int &iTransformation,
                           const int &iDirection, const string &sConnectionAttributeOnAddress, const uint &uSubindex)
  {
    return sAddress;
  }

  public int getTransformation(const string &sReference, const string &sType)
  {
    int iResult;


    string sCorrectType;

    mapping mDefaultTypes = makeMapping("position.*", "INT32",
                                        "programblock.1", "STRING",
                                        "programblock.2", "INT32",
                                        "modal.*.1", "INT32",
                                        "modal.*.2", "UINT8",
                                        "modal.*.3", "UINT8",
                                        "statinfo.?", "INT16",
                                        "feedrate", "INT32",
                                        "spindlespeed", "INT32",
                                        "alarm", "ALARM",
                                        "alarmstring", "ALARM",
                                        "pmcdata.*.*", "*",
                                        "param.*.*", "*",
                                        "diag.*.*", "*",
                                        "sysinfo","STRING");

    dyn_string dsKeys = mappingKeys(mDefaultTypes);

    for (int i =1; sCorrectType == "" && i <= dynlen(dsKeys); i++)
    {
      if (patternMatch(dsKeys[i], sReference))
      {
        sCorrectType = mDefaultTypes[dsKeys[i]];
      }
    }

    if (sCorrectType == "*" || sCorrectType == "")
    {
      sCorrectType = sType;
    }

    switch (sCorrectType)
    {
      case "BOOL":
      case "BITINBYTE":
        iResult = 1001;       // bool transformation
        break;
      case "BITINWORD":
        iResult = 1011;       // bool transformation
        break;
      case "BITINDWORD":
        iResult = 1012;       // bool transformation
        break;
      case "INT8":
        iResult = 1002;
        break;
      case "INT16":
        iResult = 1003;
        break;
      case "INT32":
      case "INT":
        iResult = 1004;
        break;
      case "UINT8":
        iResult = 1005;
        break;
      case "UINT16":
        iResult = 1006;
        break;
      case "UINT32":
        iResult = 1007;
        break;
      case "FLOAT":
        iResult = 1008;       // float transformation
        break;
      case "DOUBLE":
        iResult = 1009;
        break;
      case "STRING":
        iResult = 1010;       // string transformation
        break;

      default:
        iResult = 560;
        break;
    }

    return iResult;
  }



  public string getConnectionattribute(const mapping &mTag)
  {
    return CONNECTION_DP_PREFIX+this.getDeviceId(mTag[DriverConst::DEVICE_KEY]);
  }

    /**
   * @brief function to modify datpoints, which is called at begin of updateDeviceDp()
   * @param sDeviceKey     device key
   * @param mParams        configuration mapping for the device
   */
  protected void beforeUpdateDeviceDP(const string &sDeviceKey, mapping &mParams)
  {
    string sIp = mParams[DriverConst::IPADDRESS];
    dyn_string dsIpV4Split = strsplit(sIp, ".");
    dyn_string dsIpV6Split = strsplit(sIp, ":");

    //add default port to IP address
    if ( ( dynlen(dsIpV4Split) == 4 && strpos(sIp, ":") < 1 ) //IPv4 without port
        || dynlen(dsIpV6Split) == 7) //IPv6 without port
    {
      mParams[DriverConst::IPADDRESS] += ":8193";
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
//@protected members
//--------------------------------------------------------------------------------
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

    //provide manual browsing result, real browsing is not supported, so we limit the Asterisk to 99
    /*
      "position.*" is a "INT32",  (0...99)
      "programblock.1" is a "STRING",
      "programblock.2" is a "INT32",
      "modal.*.1" is a "INT32"    (0...3)
      "modal.*.2" is a "UINT8",  (0...3)
      "modal.*.3" is a "UINT8",  (0...3)
      "statinfo.?" is a "INT16",   (1...9)
      "feedrate" is a "INT32",
      "spindlespeed" is a "INT32",
      "alarm" is a "ALARM",
      "alarmstring" is a "ALARM",
      "pmcdata.*.*" could be an Data type "*"     (0...99; 0...65535)
      "param.*.*" could be an Data type "*",        (0...32767;0...99 )
      "diag.*.*" could be an Data type "*"              (0...32767;0...99 )
      "sysinfo" is a "STRING"
    */
    //mapping with address pattern, type, (optioanl per Asterisk) min1 and max1, min2, max2
    mapping mAddressPatterns = makeMapping("position.*", makeDynAnytype("INT32", 0, 99),
                                           "programblock.1", makeDynAnytype("STRING"),
                                           "programblock.2", makeDynAnytype("INT32"),
                                           "modal.*.*", makeDynAnytype("3SET", 0, 3, 1, 3), //INT32, UINT8, UINT8
                                           "statinfo.*", makeDynAnytype("INT32", 1, 9),
                                           "feedrate", makeDynAnytype("INT32"),
                                           "spindlespeed", makeDynAnytype("INT32"),
                                           "alarm", makeDynAnytype("STRING"),
                                           "alarmstring", makeDynAnytype("STRING"),
                                           "pmcdata.*.*", makeDynAnytype("UINT16", 0, 99, 0, 99),
                                           "param.*.*", makeDynAnytype("UINT16", 0, 99, 0, 99), //default type is used
                                           "diag.*.*", makeDynAnytype("UINT16", 0, 99, 0, 99),  //default type is used
                                           "sysinfo", makeDynAnytype("STRING") );

  vector<BrowseItem> vResult;
  dyn_string dsKeys = mappingKeys(mAddressPatterns);
  dynSort(dsKeys);

  dyn_string dsResult, dsExist, dsType;

  for (int i = 1; i <= dynlen(dsKeys); i++)
  {
    getPossibleStrings(dsKeys[i], dsResult, dsType ,mAddressPatterns[dsKeys[i]], dsExist);
  }

  for (int i = 1; i <= dynlen(dsResult); i++)
  {
    BrowseItem stItem;
    stItem.name    = dsResult[i];
    stItem.address = dsResult[i];
    stItem.extras  = "browsing not available (static result)"; // NodeComments
    stItem.type    = convertType(dsType[i]);
    stItem.transformation = dsType[i];
    stItem.writeable = FALSE;   //can not be writte by mindsphere/IOT
    vResult.append(stItem);
  }

    return vResult;
  }


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  private static EBTagType convertType(const string &sPlcType)
  {
    EBTagType eResult = EBTagType::NONE;

    switch (strtoupper(sPlcType))
    {
      case "INT32":
      case "INT16":
                            eResult = EBTagType::INT;    break;
      case "UINT8":         eResult = EBTagType::UINT;    break;
      case "DOUBLE":        eResult = EBTagType::FLOAT;    break;
      case "":
      case "STRUCT":        eResult = EBTagType::NONE;    break;
      case "STRING":
      case "ALARM":
                            eResult = EBTagType::STRING;    break;
      default: //*
                            eResult = EBTagType::UINT;    break;
    }

    return eResult;
  }
  private void getPossibleStrings(const string &sPattern, dyn_string &dsResult, dyn_string &dsType, const dyn_anytype &daSetting, dyn_string &dsExist)
  {
    dyn_string dsSplit = strsplit(sPattern, ".");
    dyn_string ds3Types = makeDynString("INT32","UINT8","UINT8");

    dyn_string dsLastLevel = dsSplit[1];
    string sPath;

    int iLastLevel = dynlen(dsSplit);
    for(int i=2; i<=iLastLevel; i++)
    {
      dyn_string dsCurrentLevel, dsCurrentType;
      for (int j=1; j<=dynlen(dsLastLevel); j++)
      {
        if (dsSplit[i] != "*")
        {
          dynAppend(dsCurrentLevel, dsLastLevel[j] + "." +dsSplit[i]);
          dynAppend(dsCurrentType, i!=iLastLevel ? "" : daSetting[1]);
        }
        else
        {
          int k = daSetting[(i-1)*2];
          int iEnd = daSetting[(i-1)*2+1];

          for(; k <= iEnd; k++)
          {
            dynAppend(dsCurrentLevel, dsLastLevel[j] + "." + k);
            if (i!=iLastLevel)
              dynAppend(dsCurrentType, "");
            else
              dynAppend(dsCurrentType, daSetting[1] != "3SET" ? daSetting[1] : ds3Types[k]);
          }
        }
      }
      dsLastLevel = dsCurrentLevel;

      //remove duplicates
      for (int j=dynlen(dsCurrentLevel); j>0; j--)
      {
        if(dynContains(dsExist, dsCurrentLevel[j])>0)
        {
          dynRemove(dsCurrentLevel, j);
          dynRemove(dsCurrentType, j);
        }
        else
        {
          dynAppend(dsExist, dsCurrentLevel[j]);
        }
      }
      if (dynContains(dsExist, dsSplit[1]) < 1)
      {
        dynAppend(dsResult, dsSplit[1]); //add first node at first
        dynAppend(dsType, dynlen(dsCurrentLevel)>0 ? "" : daSetting[1]);
        dynAppend(dsExist, dsSplit[1]);
      }
      dynAppend(dsResult, dsCurrentLevel);
      dynAppend(dsType, dsCurrentType);
    }
  }

  private static bool bRegisteredDriver = Factory::registerPlugin(DRIVER_NAME, createPointer);  //!< Register this driver plugin
};
