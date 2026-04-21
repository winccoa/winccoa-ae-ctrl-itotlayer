// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author Schiefer Martin
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "CtrlZlib"                            //!< For decompressing the SCL file content with 'gunzip'
#uses "pa"                                  //!< For 'paCfgSetValue'
#uses "classes/GenericDriver/DriverApp"     //!< Base class
#uses "EB_Package_IEC61850/IEC61850Utils"   //!< For the 'IEC61850Utils' functions
#uses "iec61850_plugin"                     //!< For the 'IEC61850' constants

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/**
*/
class DriverAppIEC61850: DriverApp
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  public static const string CONNECTION_DP_PREFIX     = "_IEC61850_Plc";
  public static const string DRIVER_NAME              = "IEC61850";
  public static const int    DRIVER_NUMBER            = 12;
  public static const string DRIVER_IDENTIFIER        = IEC61850_DRIVER_IDENTITY;
  public static const string DRIVER_CONNECTION_DPTYPE = IEC61850_DPT_NAME;
//  use default: public static const dyn_string dsCsvHeaders = makeDynString("active", "tag", "address", "type", "rate","min", "max", "archive", "unit", "format", "desc");

  // For device panel
  public static const mapping mDeviceMetaData = makeMapping();

  public static const mapping mDefaultDevice = makeMapping("name",           (langString)"",
                                                           "ipaddress",      "127.0.0.1:8193",
                                                           "serverName",     "",
                                                           "accessPointName","",
                                                           "sclFile",        "",
                                                           "location",       (langString)"",
                                                           "description",    (langString)"",
                                                           "connectionsAll", "");

  public static const mapping mDeviceDetailSource = makeMapping("ipaddress",        IEC61850_DPE_IDP_IPADDRESS,
                                                                "serverName",       IEC61850_DPE_IDP_CONFIG_IEDNAME,
                                                                "accessPointName",  IEC61850_DPE_IDP_CONFIG_APNAME,
                                                                "sclFile",          IEC61850_DPE_IDP_SCLFILEPATH,
                                                                "connectionsAll",   IEC61850_CLIENT_DP_NAME + DRIVER_NUMBER + IEC61850_CLIENT_IDP_IEDLIST + "[]",
                                                                "location",         ".AddInfo[location]",
                                                                "description",      ".AddInfo[description]");

  public static const dyn_string CONNECTION_EXCLUDES = makeDynString();                                        //!< Prevent setting these dpes on a configuration change
  public static const mapping    CONNECTION_VALUES   = makeMapping(IEC61850_DPE_IDP_CONFIG_ACTIVE,          FALSE,                    //!< Do not activate this connection yet, first need to browse the scl file
                                                                   IEC61850_DPE_IDP_BROWSE_SOURCE,          1,                        //!< Set SCL file as browse source
                                                                   IEC61850_DPE_IDP_CONFIG_DRVNUM,          DRIVER_NUMBER,            //!< Use the driver number from this class
                                                                   IEC61850_DPE_IDP_CONFIG_CLIENT_PSEL,     IEC61850_DEFAULT_PSEL,    //!< Values from 'iec61850_DevicePnl_initAdvancedSettings'
                                                                   IEC61850_DPE_IDP_CONFIG_CLIENT_SSEL,     IEC61850_DEFAULT_SSEL,
                                                                   IEC61850_DPE_IDP_CONFIG_CLIENT_TSEL,     IEC61850_DEFAULT_TSEL,
                                                                   IEC61850_DPE_IDP_CONFIG_SERVER_PSEL,     IEC61850_DEFAULT_PSEL,
                                                                   IEC61850_DPE_IDP_CONFIG_SERVER_SSEL,     IEC61850_DEFAULT_SSEL,
                                                                   IEC61850_DPE_IDP_CONFIG_SERVER_TSEL,     IEC61850_DEFAULT_TSEL,
                                                                   IEC61850_DPE_IDP_CONFIG_CLIENT_APTITLE,  IEC61850_DEFAULT_APTITLE,
                                                                   IEC61850_DPE_IDP_CONFIG_SERVER_APTITLE,  IEC61850_DEFAULT_APTITLE,
                                                                   IEC61850_DPE_IDP_CONFIG_CLIENT_AEQUAL,   IEC61850_DEFAULT_AEQUALIFIER,
                                                                   IEC61850_DPE_IDP_CONFIG_SERVER_AEQUAL,   IEC61850_DEFAULT_AEQUALIFIER,
                                                                   IEC61850_DPE_IDP_CONFIG_CLIENT_APINVOKE, IEC61850_DEFAULT_APINVOKEID,
                                                                   IEC61850_DPE_IDP_CONFIG_SERVER_APINVOKE, IEC61850_DEFAULT_APINVOKEID,
                                                                   IEC61850_DPE_IDP_CONFIG_CLIENT_AEINVOKE, IEC61850_DEFAULT_AEINVOKEID,
                                                                   IEC61850_DPE_IDP_CONFIG_SERVER_AEINVOKE, IEC61850_DEFAULT_AEINVOKEID,
                                                                   IEC61850_DPE_IDP_CONFIG_CLIENT_USETQ,    IEC61850_DEFAULT_USETQ,
                                                                   IEC61850_DPE_IDP_CONFIG_CLIENT_USEINV,   IEC61850_DEFAULT_USEINV,
                                                                   IEC61850_DPE_IDP_CONFIG_SERVER_USETQ,    IEC61850_DEFAULT_USETQ,
                                                                   IEC61850_DPE_IDP_CONFIG_SERVER_USEINV,   IEC61850_DEFAULT_USEINV,
                                                                   IEC61850_DPE_IDP_CONFIG_BROWSETIMEOUT,   90,
                                                                   IEC61850_DPE_IDP_ENG_RCBCFG,             1,
                                                                   IEC61850_DPE_IDP_CONFIG_DEFAULTRESVTMS,  IEC61850_DEFAULT_RESVTMS,
                                                                   IEC61850_DPE_IDP_CONFIG_CONNPASSIVE,     1,
                                                                   IEC61850_DPE_IDP_DEVICEREDU_CONFIG_CONNECT_PRIMARY, 1,
                                                                   IEC61850_DPE_IDP_SECONDARY_CONFIG_SERVER_PSEL,     IEC61850_DEFAULT_PSEL,
                                                                   IEC61850_DPE_IDP_SECONDARY_CONFIG_SERVER_SSEL,     IEC61850_DEFAULT_SSEL,
                                                                   IEC61850_DPE_IDP_SECONDARY_CONFIG_SERVER_TSEL,     IEC61850_DEFAULT_TSEL,
                                                                   IEC61850_DPE_IDP_SECONDARY_CONFIG_SERVER_APTITLE,  IEC61850_DEFAULT_APTITLE,
                                                                   IEC61850_DPE_IDP_SECONDARY_CONFIG_SERVER_AEQUAL,   IEC61850_DEFAULT_AEQUALIFIER,
                                                                   IEC61850_DPE_IDP_SECONDARY_CONFIG_SERVER_APINVOKE, IEC61850_DEFAULT_APINVOKEID,
                                                                   IEC61850_DPE_IDP_SECONDARY_CONFIG_SERVER_AEINVOKE, IEC61850_DEFAULT_AEINVOKEID,
                                                                   IEC61850_DPE_IDP_SECONDARY_CONFIG_SERVER_USETQ,    IEC61850_DEFAULT_USETQ,
                                                                   IEC61850_DPE_IDP_SECONDARY_CONFIG_SERVER_USEINV,   IEC61850_DEFAULT_USEINV);             //!<

  public static const dyn_string CONNECTION_STATE_ELEMENTS = makeDynString(IEC61850_DPE_IDP_DEVICE_STATE);   //!< Include the operating to provide a warning if the PLC program is stopped
  public static const dyn_anytype CONNECTION_STATE_OK      = makeDynAnytype((uint)1);                        //!< Connection state values, that indicate a connected state
  public static const string     BROWSE_DPE_REQUEST        = "-";                                            //!< Element for starting the browsing "-" is not used, but browsing feature is activated

  // For the tag table
  public static const mapping mTagMetaData = makeMapping();

  //todo delete und create in die allgemeine classe

  public static const mapping mTagDetailSource = makeMapping("Address", "_refstring"/*,
                                                             "Pollrate", "_pollgroup",
                                                             "direction", "_S7_Config.Rack[]"*/);
//   public static const mapping mDeviceDetailMeta =   makeMapping("DeviceType", makeMapping("S7 1500",makeMapping("RACK",1,"SLOT",4))), "Ipaddress", IP);

//"location", ".AddInfo[location]"
//   protected mapping mDeviceDetailSource = makeMapping("IP", ".IPAddress", "TYPE", ".ConnectionType", "RACK", ".Rack", "SLOT", ".Slot");

  //------------------------------------------------------------------------------
  /**
   * @brief Default constructor.
   */
  public DriverAppIEC61850()
  {
    string sBoxId;

    dpGet(DPE_BOXID, sBoxId);

    mapping mTemp = jsonDecode(sBoxId);

    if (mappingHasKey(mTemp, "boxid"))
    {
      sBoxId = mTemp["boxid"];
      sClientIedName = sBoxId;

      paCfgSetValue(PROJ_PATH + CONFIG_REL_PATH + "config", "iec61850_" + DRIVER_NUMBER, "clientIedName", sClientIedName);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Creates a new shared pointer instance
   * @return New instance
   */
  public static shared_ptr<DriverAppIEC61850> createPointer()
  {
    return new DriverAppIEC61850();
  }

  public string setupReferenceString(const string &sDeviceKey, const string &sTagKey, const langString &lsDescription, const string &sAddress, const EBTagType &tagType, const string &sRefreshRate,
                           const bool &bActive, const bool &bArchive, const string &sFormat, const langString &lsUnit, const int &iTransformation,
                           const int &iDirection, const string &sConnectionAttributeOnAddress, const uint &uSubindex)
  {
    // Include the driver connection in the address reference
    return strltrim(getDriverConnectionDp(sDeviceKey, FALSE), "_") + "." + sAddress;
  }

  /**
   * @brief Returns the transformation type for the driver
   * @details Result values are taken over from 'Exe/Driver/IEC61850Drv/IEC61850TransformationType.hxx'
   * @param sReference  Address reference
   * @param sType       Mindsphere type
   * @return Transformation type for the driver
   */
  public int getTransformation(const string &sReference, string sType)
  {
    int iResult;
    strreplace(sType, " ", ""); //remove possible spaces

    switch (sType)
    {
      case "INT8":
        iResult = 1;
        break;
      case "INT32":
      case "INT":
        iResult = 2;
        break;
      case "INT64":
        iResult = 3;
        break;
      case "UINT8":
        iResult = 4;
        break;
      case "UINT16":
        iResult = 5;
        break;
      case "UINT32":
      case "UINT":
        iResult = 6;
        break;
      case "FLOAT":
      case "FLOAT32":
        iResult = 7;
        break;
      case "BOOLEAN":
      case "BOOL":
        iResult = 8;
        break;
      case "BITSTRING":
        iResult = 9;
        break;
      case "OCTETSTRING":
      case "OCTETSTRING64":
        iResult = 10;
        break;
      case "VISIBLESTRING64":
        iResult = 11;
        break;
      case "VISIBLESTRING255":
      case "STRING":
        iResult = 12;
        break;
      case "UTCTIME":
      case "TIME":
      case "TIMESTAMP":
        iResult = 13;
        break;
      case "DOUBLE":
      case "FLOAT64":
        iResult = 14;
        break;
      case "INT16":
        iResult = 15;
        break;

      default:
        iResult = 0;
        break;
    }

    return iResult;
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------

  /**
   * @brief Returns the browsing result instead of getting browsing result via DPE
   * @param sDeviceKey                 device key
   * @param sFilter                    filter pattern
   * @param iStart                     result start index
   * @param iMaxResultRows             max number of results before splitting browsing result
   * @param sParent                    parent start node
   * @param dsNodeNames                browse result names
   * @param daNodeTypes                browse result types
   * @return 0 ok, no failure
   */
  protected bool manualBrowsing(const string &sDeviceKey, const string &sFilter, int iStart, int iMaxResultRows, const string &sParent, dyn_string &dsNodeNames, dyn_anytype &daNodeTypes)
  {
    string sDeviceDp = getDriverConnectionDp(sDeviceKey, FALSE);

    if (sDeviceDp != "")
    {
      daNodeTypes = IEC61850Utils::getBrowsingStucture(sDeviceDp);
    }

    return sDeviceDp == "";
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
    if (dynlen(daValues) > 0)
    {
      getBrowsingNodes(daValues[1], vResult);
    }
    return vResult;
  }
  private void getBrowsingNodes(const mapping &mNode, vector<BrowseItem> &vResult)
  {
    if (mappingHasKey(mNode, "type"))
    {
      EBTagType eType = _getEBType(mNode["type"]);

      BrowseItem stItem;
      stItem.name    = mNode["id"]; //absolute name
      stItem.address = mNode["address"];  //the address
      stItem.extras  = mNode["extra"];    // NodeComments
      stItem.type    = eType;
      stItem.transformation = strtoupper(mNode["type"]);
      stItem.writeable = FALSE;   //IEC plus does not inform us if this address is read or writeable, so default is not false
      vResult.append(stItem);

      if (mappingHasKey(mNode, "children"))
      {
        for (int i = 1; i <= dynlen(mNode["children"]); i++)
        {
          getBrowsingNodes(mNode["children"][i], vResult);
        }
      }
    }
  }

  /**
   * @brief  Checks if an SCL File is given for the configuration of the IEC Device
   * @param  sDeviceKey The DeviceKey of the Device that is to be deleted
   * @param  lsName The Name of the Device
   * @param  lsLocation The location of the Device
   * @param  lsDescription The description of the Device
   * @param  sAddress the IP Address of the device
   * @param  mParams Mapping used for deleting a driverdatapoint
   */
  protected void updateDeviceDp(const string &sDeviceKey, const langString &lsName, const langString &lsLocation, const langString &lsDescription, const string &sAddress, const mapping &mParams)
  {
    mapping mUpdatedParams  = mParams;
    string  sDeviceAddress  = sAddress;
    string  sDeviceDp       = getDriverConnectionDp(sDeviceKey, TRUE);
    string  sDownloadedFile = mappingHasKey(mUpdatedParams, "scdFile") ? mUpdatedParams["scdFile"] : "";
    string  sContent;
    langString  lsLocation  = mUpdatedParams["location"];
    langString  lsName      = mUpdatedParams["name"];
    string sLocation        = lsLocation;
    string sName            = lsName;

    strreplace(sLocation, sName + "/", "");

    if (sDownloadedFile != "")
    {
      sContent = extractContentFromFile(sDownloadedFile);

      // Check if a SCL file has been provided
      if (sContent != "")
      {
        string sFileName = IEC61850_SCL_FILE_PATH + sDeviceDp + "_" + mUpdatedParams["name"] + "_" + sLocation + ".scd";

        // Check if the content needs to be decompressed
        if (!xmlIsValid(sContent))
        {
          blob blCompressed;

          if (base64Decode(sContent, blCompressed) == 0)
          {
            gunzip(blCompressed, sContent);
          }
        }

        // Make sure the directory exists
        if (!isdir(IEC61850_SCL_FILE_PATH))
        {
          mkdir(IEC61850_SCL_FILE_PATH);
        }

        // Store the SCL file
        file f = fopen(sFileName, "w");

        if (f != 0)
        {
          // Replace the place holder client IED name with the actual box id
          strreplace(sContent, "iedName=\"MindsphereClient\"", "iedName=\"MindSphereClient\"");
          strreplace(sContent, "iedName=\"MindSphereClient\"", "iedName=\"" + sClientIedName + "\"");

          fputs(sContent, f);

          fclose(f);

          throwError(makeError("", PRIO_INFO, ERR_IMPL, 54, "Written file: " + sFileName));
        }

        // Read the device address from the SCL content
        sDeviceAddress = IEC61850Utils::readAddressFromScl(sContent, mUpdatedParams["accessPointName"], mUpdatedParams["serverName"]);

        mUpdatedParams["ipaddress"] = sDeviceAddress;
        mUpdatedParams["sclFile"]   = sFileName;

      }
    }

    //Execute base function to update the device DP with the content from the SCL file
    DriverApp::updateDeviceDp(sDeviceKey, lsName, lsLocation, lsDescription, sDeviceAddress, mUpdatedParams);

    if (sContent != "")
    {
      if (iec61850_browse_file(strltrim(sDeviceDp, IEC61850_INOA)) == 0)
      {
        dpSet(sDeviceDp + IEC61850_DPE_IDP_CONFIG_ACTIVE, TRUE);
      }

      // Read the blocks from the SCL content
      dyn_string dsRCBs = IEC61850Utils::readRCBsFromScl(sContent, mUpdatedParams["accessPointName"], mUpdatedParams["serverName"], sClientIedName);

      // Create the blocks
      IEC61850Utils::createRCBs(sDeviceDp, dsRCBs);
    }
  }

  /**
   * @brief  Before deleting the Device DP Delete RCB´s of the IEC Device and also delete any SCL/SCD Files that were used
   * @param  sDeviceKey The DeviceKey of the Device that is to be deleted
   * @param  mParams Mapping used for deleting a driverdatapoint
   * @return Updated Mapping for device
   */
  protected void preDeleteDeviceDp(const string &sDeviceKey, const mapping &mParams)
  {
    string sDeviceDpName = getDriverConnectionDp(sDeviceKey, FALSE);
    dyn_string dsRCBs = IEC61850Utils::getRcbsOfConnection(sDeviceDpName);

    //Remove RCB DPS of the device that is deleted
    for (int i = 1; i <= dynlen(dsRCBs); i++)
    {
      iec61850_deleteRcbDp(sDeviceDpName, dsRCBs[i]);
    }

    // Also remove the SCL file(s) of this device
    dyn_string dsFileNames = getFileNames(IEC61850_SCL_FILE_PATH, sDeviceDpName + "*" + mParams["extra_data"] + ".scd");

    for (int i = 1; i <= dynlen(dsFileNames); i++)
    {
      remove(IEC61850_SCL_FILE_PATH + dsFileNames[i]);
    }

    //Remove DeviceDP
    if (dpExists(sDeviceDpName))
    {
      dpDelete(sDeviceDpName);
    }
  }

  /**
   * @brief  Returns the updated mapping for the IEC specific IEC device
   * @param  mParams Mapping used for deleting a driverdatapoint
   * @return Updated Mapping for device
   */
  protected mapping updateParamsForDeviceDeletion(const mapping &mParams)
  {
    DriverApp::updateParamsForDeviceDeletion(mParams);

    string sDeviceKey= mParams["devicekey"];
    string sExtraData = mParams["extra_data"];
    string sDeviceId = getDriverConnectionDp(sDeviceKey, FALSE);
    mapping mTmpParams;

    mTmpParams["extra_data"] = sExtraData;
    mTmpParams["devicekey"] = sDeviceKey;
    mTmpParams["driverconnDP"] = sDeviceId;

    return mTmpParams;
  }

  /**
   * @brief Returns the device entry for the driver device list (driver depending)
   * @param sDriverConnDP    Driver connection DP
   * @return Device list entry
   */
  protected string getDeviceListEntry(const string &sDriverConnDP)
  {
    return sDriverConnDP;
  }

  /**
   * @brief Returns if this driver app uses subscriptions to read values
   * @return TRUE -> Using subscriptions to read values
   */
  protected bool useSubscriptions()
  {
    return TRUE;
  }

    /**
   * @brief if drivers requires reestablish connection, derived driver app can disconnect an reconnect on device change (e.g. IP address has been changed)
   * @param sDeviceKey           the device key
   * @param sDriverConnectionDP  connection DP for device
   * @return bConnect            trigger connect or disconnect
   */
  protected void connectDeviceOnDeviceChange(string sDeviceKey, string sDriverConnectionDP, bool bConnect=TRUE)
  {
    dpSetWait(sDriverConnectionDP + IEC61850_DPE_IDP_CONFIG_ACTIVE, bConnect);
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  /**
   * @brief Returns the internal type for the IEC61850 types
   * @param sIecType    IEC61850 type to convert
   * @return Internal type
   */
  private static EBTagType _getEBType(const string &sIecType)
  {
    EBTagType eResult = EBTagType::NONE;

    switch (sIecType)
    {
      case "BOOLEAN":      eResult = EBTagType::BOOL;   break;
      case "FLOAT32":
      case "FLOAT64":      eResult = EBTagType::FLOAT;  break;
      case "Enum":
      case "INT8":
      case "INT16":
      case "INT32":        eResult = EBTagType::INT;    break;
      case "INT8U":
      case "INT16U":
      case "INT32U":       eResult = EBTagType::UINT;   break;
      case "Timestamp":    eResult = EBTagType::TIME;   break;
      case "Unicode255":
      case "VisString64":
      case "VisString255": eResult = EBTagType::STRING; break;
    }

    return eResult;
  }

  /**
   * @brief Returns if the specified content is a valid xml document
   * @param sContent    Content to test
   * @return TRUE if the content is a valid xml document
   */
  private static bool xmlIsValid(const string &sContent)
  {
    bool bResult;
    string sError;
    int iLine;
    int iColumn;
    int iXmlDoc = xmlDocumentFromString(sContent, sError, iLine, iColumn);

    if (iXmlDoc != -1)
    {
      xmlCloseDocument(iXmlDoc);

      bResult = TRUE;
    }
    return bResult;
  }

   /**
   * @brief  Evaluates the compression application used and returns the content of the file uncompressed
   * @param  sFile Path to file
   * @return The content of the file uncompressed
   */
  private static string extractContentFromFile(const string &sFile)
  {
    string sCompressiontMethod, sContent, sOut, sCmd;

    string sConfigValue;
    dyn_string dsFiles = makeDynString(getPath(CONFIG_REL_PATH, "config"), getPath(CONFIG_REL_PATH, "config.level"));

    sConfigValue = paCfgReadValueDflt(dsFiles, "mnsp", "simpleFileCheckIEC61850", 0);

    strreplace(sConfigValue, " ", ""); //remove spaces

    if (sConfigValue == "1")
    {
      dyn_string dsSplit = strsplit(strtolower(sFile), ".");
      sCompressiontMethod = dsSplit[dynlen(dsSplit)];
      sCompressiontMethod = strtolower(sCompressiontMethod);

      if (dynlen(dsSplit) > 1)
      {
        if (dsSplit[dynlen(dsSplit)] == "zip")
        {
          sCompressiontMethod = "zip";
        }
        else if ( ( dsSplit[dynlen(dsSplit)-1] == "tar" && dsSplit[dynlen(dsSplit)] == "gz" ) || (dsSplit[dynlen(dsSplit)] == "gzip" ))
        {
          sCompressiontMethod = "gzip";
        }
        else if (dsSplit[dynlen(dsSplit)] == "xz" )
        {
          sCompressiontMethod = "x-tar";
        }
        else  //default will be zip
        {
          sCompressiontMethod = "zip";
        }
      }
      else  //default will be zip
      {
        sCompressiontMethod = "zip";
      }
    }
    else //file package needs to be installed
    {
      system("file --mime-type -b " + sFile, sOut);

      sCompressiontMethod = strltrim(sOut, "application/");
      sCompressiontMethod = strrtrim(sCompressiontMethod);
    }

    switch (sCompressiontMethod)
    {
      case "zip":      sCmd = "unzip -p ";     break;
      case "gzip":     sCmd = "tar -xOzf ";    break;
      case "x-tar":    sCmd = "tar -xOf ";     break;
      default:         sCmd = "cat ";          break;
    }

    system(sCmd + sFile, sContent);

    return sContent;
  }

  private static bool bRegisteredDriver = Factory::registerPlugin(DRIVER_NAME, createPointer);  //!< Register this driver plugin
  private string sClientIedName;                                                                //!< The MindSphere box id is used as client IED name
};
