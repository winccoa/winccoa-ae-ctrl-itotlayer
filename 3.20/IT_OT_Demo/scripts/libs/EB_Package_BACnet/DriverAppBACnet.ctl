// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "classes/GenericDriver/DriverApp"
#uses "bacnetDrvPara"

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/**
*/
class DriverAppBACnet: DriverApp
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
  public static const string CONNECTION_PLC_NAME      = "BACnetPLC";
  public static const string CONNECTION_DP_PREFIX     = "_" + CONNECTION_PLC_NAME;
  public static const string DRIVER_NAME              = "BACnet";
  public static const int    DRIVER_NUMBER            = 13;
  public static const string DRIVER_IDENTIFIER        = "BACNET";
  public static const string DRIVER_CONNECTION_DPTYPE = "_BacnetDevice";
  public static const bool CONNECTION_TAG_NEEDED      = TRUE;
  public static const bool DRIVER_SUPPORT_HMICONNECTION = FALSE;
  public static const string BROWSE_DPE_REQUEST       = "-";          //!< Element for starting the browsing

  // For device panel
  public static const mapping mDeviceMetaData = makeMapping();

  public static const mapping mDefaultDevice = makeMapping("name",        (langString)"",
                                                           "ipaddress",               "",
                                                           "location",    (langString)"",
                                                           "description", (langString)"",
                                                           "ipAddressBBMD", "",
                                                           "portBBMD", "");

  public static const mapping mDeviceDetailSource = makeMapping("ipaddress",".ConnInfo",
                                                                "deviceId", ".DeviceId" );

  public static const dyn_string CONNECTION_EXCLUDES = makeDynString();                                                      //!<
  public static const string     CONNECTION_CHECK    = ".State.Online";                                                      //!< Add an address config to start the connection establishment to this element

  public static const mapping    CONNECTION_VALUES   = makeMapping(".Active",TRUE,                   //!< Activate this connection
                                                                   ".TimeSyncInterval",     300,                     //!< Use the default Synchronize time interval
                                                                   ".AliveInterval",        30,
                                                                   ".Browse.Devices.Range", "0-4000000");

  public static const dyn_string CONNECTION_STATE_ELEMENTS  = makeDynString(".State.Online");   //!< DP elements of the connection dp needed to determine the connection state
  public static const dyn_anytype CONNECTION_STATE_OK       = makeDynAnytype(TRUE);               //!< Connection state values, that indicate a connected state

//   public static const string BROWSE_DPE_REQUEST   = ".Browse.GetBranch";  //!< Element for starting the browsing
  public static const string BROWSE_DPE_RESULT_ID = ".Browse.RequestId";  //!< Element on which to wait for a specific value (request id)

  // For the tag table
  public static const mapping mTagMetaData =
    makeMapping("active", makeMapping("type", "bool",
                                      "visible", false,
                                      "defaultValues", true),
                "tagkey", makeMapping("type", "text",
                                      "visible", true),
                "name", makeMapping("type", "langtext",
                                    "visible", true),
                "desc", makeMapping("type", "langtext",
                                    "visible", true),
                "address", makeMapping("type", "text",
                                       "visible", true,
                                       "placeholder", "*.DB*.DB*",
                                       "visible", true),
                "subindex", makeMapping("type", "number",
                                        "visible", true),
                "datatype", makeMapping("type", "EBTagType",
                                        "visible", true,
                                        "validation", makeMapping("type", "text", "values", makeDynString("BOOL", "INT", "FLOAT", "STRING", "NONE")),
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


  public static const mapping mTagDetailSource = makeMapping("Address", "_refstring", "Pollrate", "_pollgroup");


  //------------------------------------------------------------------------------
  /**
   * @brief Default constructor.
   */
  public DriverAppBACnet()
  {
    BnAppInitGlobals();
    // set entry in config file if not existe
    string sPath = getPath(CONFIG_REL_PATH, "config");
    if (isDbgFlag("bacnet"))
    {
      paCfgSetValue(sPath, "bacnet", "net", "NOQUOTE: 1 \"IP\" \"" + getProductionInterfaceIp() + "\" \"\" 50715 \"\" 0 120");
    }
    else
    {
      paCfgSetValue(sPath, "bacnet", "net", "NOQUOTE: 1 \"IP\" \"" + getProductionInterfaceIp() + "\" \"\" 47808 \"\" 0 120");
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Creates a new shared pointer instance
   * @return New instance
   */
  public static shared_ptr<DriverAppBACnet> createPointer()
  {
    return new DriverAppBACnet();
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

    return strltrim(getDriverConnectionDp(sDeviceKey), "_") + "." + sAddress;
  }

  public int getTransformation(const string &sReference, string sType)
  {
    int iResult = 800;

    // copie from the help the names and the default value
    dyn_string dsTypes = makeDynString("DEFAULT",           //800
                                       "BOOLEAN",
                                       "UNSIGNED INTEGER", //802
                                       "SIGNED INTEGER",
                                       "REAL",
                                       "DOUBLE",
                                       "OCTETS",
                                       "STRING",           //807
                                       "BITSTRING",
                                       "ENUMERATED",
                                       "DATE",             //810
                                       "TIME",             //811
                                       "DATETIME");        //822

    if (mappingHasKey(mTranslateTransformationUiToWCC, sType))
    {
      sType = mTranslateTransformationUiToWCC[sType];
    }

    int iPos = dynContains(dsTypes, sType);

    if (iPos > 0)
    {

      iResult = iPos + 799;

      if (iPos == 812)
      {
        iResult = 822;
      }
    }

    return iResult;
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------

  /**
   * @brief Converts the received values into a collection of browse items
   * @param dsDpes      Dpes of the browse result
   * @param daValues    Values from the browse result dpes
   * @return Browse items
   */
  protected vector<BrowseItem> browseResult(const dyn_string &dsDpes, const dyn_anytype &daValues, const string &sParent)
  {
    DebugFTN(DriverConst::DEBUG_BROWSE, "BACnet browsing #1 start - deviceKey:", daValues);
    bool bIsArray;
    bool bBrowseIsStatic;
    vector<BrowseItem> vResult;

    if (dynlen(daValues) < 1)   //device not found -> return empty result
    {
      return vResult;
    }

    string sDeviceKey = daValues[1];
    string sConnectionDP = getDriverConnectionDp(sDeviceKey); //with starting "_"
    string sConnectionDPName = substr(sConnectionDP, 1);
    int deviceID;
    dpSetTimed(0, ARRAY_LEN_REQUEST_DPE + ".:_address.._active", FALSE); //deactivation to be prepared for array len requests
    dpGet(sConnectionDP + ".DeviceId", deviceID); //in manualBrosing function we get out the device id for deviceKey and place in in adValues[1]

    DebugFTN(DriverConst::DEBUG_BROWSE, "BACnet browsing #2 for deviceId - deviceKey (" + deviceID + ")");

    dyn_mapping dmObjectTypePropertyNameAndTypeId;

    browsingFunction(deviceID, dmObjectTypePropertyNameAndTypeId, bBrowseIsStatic);

    DebugFTN(DriverConst::DEBUG_BROWSE, "BACnet browsing #3 for deviceId - deviceKey (" + deviceID + ") dmObjectTypePropertyNameAndTypeId len: " + dynlen(dmObjectTypePropertyNameAndTypeId));

    for (int i = 1; i <= dynlen(dmObjectTypePropertyNameAndTypeId); i++)
    {
      // check if we still in the same Object type
      if (!(i > 1 && (dmObjectTypePropertyNameAndTypeId[i]["name"] == dmObjectTypePropertyNameAndTypeId[i - 1]["name"])))
      {
        BrowseItem stItem;
        stItem.name = dmObjectTypePropertyNameAndTypeId[i]["name"];
        stItem.address = stItem.name;
        stItem.type    = EBTagType::NONE;
        stItem.writeable = FALSE;

        if (bBrowseIsStatic)
        {
          stItem.extras = "browsing not available (static result)";
        }

        vResult.append(stItem);
      }

      // Creating an Object type instance
      BrowseItem stItemInstance;
      string sInstanceName = dmObjectTypePropertyNameAndTypeId[i]["name"] + "." + dmObjectTypePropertyNameAndTypeId[i]["instance"]; //iInstanceNumber;
      stItemInstance.name = sInstanceName;
      stItemInstance.address = stItemInstance.name;
      stItemInstance.type    = EBTagType::NONE;
      stItemInstance.writeable = FALSE;

      if (bBrowseIsStatic && i == 1)
      {
        stItemInstance.extras = "browsing not available (static result)";
      }

      vResult.append(stItemInstance);

      for (int j = 1; j <= mappinglen(dmObjectTypePropertyNameAndTypeId[i]["properties"]) ; j++)
      {
        BrowseItem stItemProperty;
        stItemProperty.name = sInstanceName + "." + mappingGetKey(dmObjectTypePropertyNameAndTypeId[i]["properties"], j);
        stItemProperty.address = stItemProperty.name;

        EBTagType eType = convertType(dmObjectTypePropertyNameAndTypeId[i]["properties"][mappingGetKey(dmObjectTypePropertyNameAndTypeId[i]["properties"], j)], bIsArray);
        string sPropertyName = mappingGetKey(dmObjectTypePropertyNameAndTypeId[i]["properties"], j);

        if (gBnApp_mapBACnetPropIsArray[sPropertyName] == 1 && !bBrowseIsStatic)
        {
          stItemProperty.type = EBTagType::NONE;
          stItemProperty.transformation = "";
          stItemProperty.writeable = FALSE;
        }
        else
        {
          stItemProperty.type = eType;
          stItemProperty.transformation = "DEFAULT";
          string sDescription = stItemProperty.address;
          strreplace(sDescription, ".", "_"); //description is address without .
          stItemProperty.extras = sDescription;
        }

        vResult.append(stItemProperty);

        if (gBnApp_mapBACnetPropIsArray[sPropertyName] == 1 && !bBrowseIsStatic)
        {
          // change the address config of the array chek element
          dpSetTimedWait(0, ARRAY_LEN_REQUEST_DPE + ".:_address.._reference", sConnectionDPName + "." +  stItemProperty.address + ".0",
                         ARRAY_LEN_REQUEST_DPE + ".:_address.._active",           TRUE);
          int iArrayLen;
          bool bExpired;
          dyn_anytype daRet;
          dpSetAndWaitForValue(makeDynString("_Driver" + DRIVER_NUMBER + ".SQ:_original.._value"), makeDynString(ARRAY_LEN_REQUEST_DPE + "."),
                               makeDynString(ARRAY_LEN_REQUEST_DPE + ".:_original.._value_changed"), makeDynAnytype(),
                               makeDynString(ARRAY_LEN_REQUEST_DPE + ".:_original.._value"), daRet, ARRAY_LEN_REQUEST_TIMEOUT, bExpired);
          dpSetTimedWait(0, ARRAY_LEN_REQUEST_DPE + ".:_address.._active",           FALSE);

          if (!bExpired && dynlen(daRet) > 0)
          {
            iArrayLen = daRet[1];
          }

          if (iArrayLen > 0)
          {
            for (int k = 1; k <= iArrayLen; k++)
            {
              BrowseItem stItemIndex;
              stItemIndex.name = stItemProperty.name + "." + k;
              stItemIndex.address = stItemProperty.address + "." + k;
              string sDescription = stItemIndex.address;
              strreplace(sDescription, ".", "_"); //description is address without .
              stItemIndex.extras = sDescription;
              stItemIndex.type = eType;
              stItemIndex.transformation = "DEFAULT";
              vResult.append(stItemIndex);
            }
          }
        }
      }
    }

    DebugFTN(DriverConst::DEBUG_BROWSE, "BACnet browsing #6 for deviceId - deviceKey (" + deviceID + ") dmObjectTypePropertyNameAndTypeId len: " + dynlen(dmObjectTypePropertyNameAndTypeId) +
             "   result vector len: " + vResult.count());
    return vResult;
  }

  // tag creation for establishing the connection
  /**
   * @brief function to set connection tag, before device dp is created/updated
   * @param sDeviceKey     device key
   * @param mParams        configuration mapping for the device
   */
  protected void beforeUpdateDeviceDP(const string &sDeviceKey, mapping &mParams)
  {
    string sConnectionTag = DEVICE_CONNECTNION_TAG_PREFIX + getDeviceIndex(sDeviceKey);
    string sConnectionDP = getDriverConnectionDp(sDeviceKey); //with starting "_"
    string sCnsNodeDeviceID;
    int deviceID;

    sCnsNodeDeviceID = getDeviceId(sDeviceKey);
    dpGet(sConnectionDP + sCnsNodeDeviceID + ".DeviceId", deviceID);

    if (!dpExists(sConnectionTag))
    {
      dpCreate(sConnectionTag, "EB_String");
    }

    dpSetTimedWait(0, sConnectionTag + ".:_distrib.._type",          DPCONFIG_DISTRIBUTION_INFO,
                      sConnectionTag + ".:_distrib.._driver",           DRIVER_NUMBER,
                      sConnectionTag + ".:_address.._type",             DPCONFIG_PERIPH_ADDR_MAIN,
                      sConnectionTag + ".:_address.._reference",        CONNECTION_PLC_NAME + getDeviceIndex(sDeviceKey) + ".Device." + deviceID + ".System_Status",
                      sConnectionTag + ".:_address.._direction",        DPATTR_ADDR_MODE_INPUT_SPONT,
                      sConnectionTag + ".:_address.._datatype",         800,
                      sConnectionTag + ".:_address.._drv_ident",        DRIVER_IDENTIFIER,
                      sConnectionTag + ".:_address.._active",           TRUE);

    if (!dpExists(ARRAY_LEN_REQUEST_DPE))
    {
      dpCreate(ARRAY_LEN_REQUEST_DPE, "EB_Int");
      dpSetTimedWait(0, ARRAY_LEN_REQUEST_DPE + ".:_distrib.._type",             DPCONFIG_DISTRIBUTION_INFO,
                        ARRAY_LEN_REQUEST_DPE + ".:_distrib.._driver",           DRIVER_NUMBER,
                        ARRAY_LEN_REQUEST_DPE + ".:_address.._type",             DPCONFIG_PERIPH_ADDR_MAIN,
                        ARRAY_LEN_REQUEST_DPE + ".:_address.._reference",        "",
                        ARRAY_LEN_REQUEST_DPE + ".:_address.._direction",        DPATTR_ADDR_MODE_INPUT_SQUERY,
                        ARRAY_LEN_REQUEST_DPE + ".:_address.._datatype",         800,
                        ARRAY_LEN_REQUEST_DPE + ".:_address.._drv_ident",        DRIVER_IDENTIFIER,
                        ARRAY_LEN_REQUEST_DPE + ".:_address.._active",           FALSE);
    }
  }

    /**
   * @brief function to delete connection tag
   * @param sDeviceKey     device key
   */
  protected void deleteConnectionTag(const string &sDeviceKey)
  {
    string sConnectionTag = DEVICE_CONNECTNION_TAG_PREFIX + getDeviceIndex(sDeviceKey);
    dpDelete(sConnectionTag);
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
    daValues[1] = sDeviceKey; //save device key for browseResult function (required to get device id)
    return FALSE;
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

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  private static EBTagType convertType(const int &iDPEL_TYPE, bool &bIsArray)
  {
    EBTagType eResult = EBTagType::NONE;
    bIsArray = FALSE;

    switch (iDPEL_TYPE)
    {
      case DPEL_BOOL:                eResult = EBTagType::BOOL;     break;

      case DPEL_UINT:                eResult = EBTagType::UINT;     break;

      case DPEL_INT:                 eResult = EBTagType::INT;      break;

      case DPEL_STRING:              eResult = EBTagType::STRING;   break;

      case DPEL_FLOAT:               eResult = EBTagType::FLOAT;    break;

      case DPEL_BLOB:                eResult = EBTagType::STRING;    break;

      case DPEL_BIT32:               eResult = EBTagType::UINT;    break;

      case DPEL_LONG:               eResult = EBTagType::LONG;    break;


      case DPEL_DYN_STRING:          eResult = EBTagType::STRING;
        break;

      case DPEL_DYN_BOOL:            eResult = EBTagType::BOOL;
        break;

      case DPEL_DYN_UINT:            eResult = EBTagType::UINT;
        break;

      case DPEL_BLOB_STRUCT:         eResult = EBTagType::STRING;
        break;

    }

    return eResult;
  }

  private static mapping mTranslateTransformationBrowsingToUI = makeMapping(
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

  /**
  * @brief function to do static browsing ( fall back browsing, if online browsing not successful )
  * @param dmStaticObjectTypePropertyNameAndTypeId           Result of the static browsing
  */
  private void staticBrowsingFunction(dyn_mapping &dmStaticObjectTypePropertyNameAndTypeId)
  {
    dyn_dyn_string ddsPropertyIdsFromIDToName;
    dyn_string dsDeviceObjectTypeNames;

    // preparing the parameters for the getPropertyType() function
    for (int i = 1; i <= mappinglen(gBnApp_mObjPropType); i++)
    {
      dynAppend(dsDeviceObjectTypeNames, mappingGetKey(gBnApp_mObjPropType, i));
      dynAppend(ddsPropertyIdsFromIDToName, mappingGetValue(gBnApp_mObjPropType, i));
    }

    for (int i = 1; i <= dynlen(dsDeviceObjectTypeNames); i++)
    {
      dyn_string dsPropertyNames;
      dyn_int diPropertyTypeIds;
      int iDeviceObjectTypeIds; // just for the offline browsing
      mapping mPropertyNameAndTypeId, mObjectTypePropertyNameAndTypeId, mPropertyNameAndArrayType;

      BnAppGetProperyType(ddsPropertyIdsFromIDToName[i], dsPropertyNames, diPropertyTypeIds, dsDeviceObjectTypeNames[i], iDeviceObjectTypeIds);

      for (int j = 1; j <= dynlen(diPropertyTypeIds); j++)
      {
        mPropertyNameAndTypeId[dsPropertyNames[j] ] = diPropertyTypeIds[j] ;
      }

      mObjectTypePropertyNameAndTypeId = makeMapping("name", dsDeviceObjectTypeNames[i], "properties", mPropertyNameAndTypeId, "instance", 0);
      dynAppend(dmStaticObjectTypePropertyNameAndTypeId, mObjectTypePropertyNameAndTypeId);
    }
  }


  /**
  * @brief function to do manual browsing
  * @param uDeviceId                                   BACnet Device Id
  * @param dmObjectTypePropertyNameAndTypeId           Result of the browsing (for both modes: dynamic or static)
  * @param bBrowseIsStatic                             reference variable, indicates if static (file based) or dynamic (from real device) browsing result was generated
  */
  private void browsingFunction(uint uDeviceId, dyn_mapping &dmObjectTypePropertyNameAndTypeId, bool &bBrowseIsStatic)
  {
    dyn_dyn_string ddsDevicePropertyIds;
    dyn_int diDeviceObjectTypeIds;
    dyn_dyn_string ddsPropertyListSplit;
    dyn_dyn_string ddsPropertyIdsFromIDToName;
    dyn_string dsDeviceObjectTypeNames;
    dyn_anytype ddaReturnValues;
    dyn_int diDeviceInstanceNumber;
    bool bExpired;
    DebugFTN(DriverConst::DEBUG_BROWSE, "BACnet browsing function started !!! #1", uDeviceId);

    int iErr = dpSetAndWaitForValue(makeDynString("_Bacnet_" + DRIVER_NUMBER + ".Browse.Objects.DeviceId:_original.._value"), makeDynAnytype(uDeviceId),
                                    makeDynString("_Bacnet_" + DRIVER_NUMBER + ".Browse.Objects.DeviceIdReturn:_original.._value"), makeDynAnytype(uDeviceId),
                                    makeDynString("_Bacnet_" + DRIVER_NUMBER + ".Browse.Objects.PropertyId:_original.._value",
                                        "_Bacnet_" + DRIVER_NUMBER + ".Browse.Objects.ObjectType:_original.._value",
                                        "_Bacnet_" + DRIVER_NUMBER + ".Browse.Objects.Instance:_original.._value"),
                                    ddaReturnValues, BROWSING_REQUEST_TIMEOUT, bExpired);

    if (!bExpired && dynlen(ddaReturnValues) >= 3)  // online browsing possible
    {
      ddsDevicePropertyIds = ddaReturnValues[1];
      diDeviceObjectTypeIds = ddaReturnValues[2];
      diDeviceInstanceNumber = ddaReturnValues[3];

      if (dynlen(diDeviceInstanceNumber) >= 2)
      {
        bBrowseIsStatic = FALSE;

        for (int i = 1; i <= dynlen(ddsDevicePropertyIds); i++)
        {
          ddsPropertyListSplit[i] = strsplit(ddsDevicePropertyIds[i], ","); // preparing the property list of each instance of each objectType from the online device
        }

        dyn_string dsNames = mappingKeys(gBnApp_mapBACnetProperties);
        mapping mapBACnetProperties2;

        DebugFTN(DriverConst::DEBUG_BROWSE, "BACnet browsing started !!! #2.1 online browsing", dynlen(dsNames));

        // preparing the mapping wich contains the the ObjectType ID as a key and the name as Value.
        for (int i = 1; i <= dynlen(dsNames); i++)
        {
          mapBACnetProperties2[gBnApp_mapBACnetProperties[dsNames[i]]] = dsNames[i];
        }

        // check if the properties in the device existe in WinCC OA supported property types
        for (int i = 1; i <= dynlen(ddsPropertyListSplit); i++)
        {
          for (int j = 1; j <= dynlen(ddsPropertyListSplit[i]); j++)
          {
            if (mappingHasKey(mapBACnetProperties2, (int)ddsPropertyListSplit[i][j]))
            {
              dynAppend(ddsPropertyIdsFromIDToName[i], mapBACnetProperties2[(int)ddsPropertyListSplit[i][j]]); // dynamic array which contain only the supported properties for each instance
            }
          }
        }

        DebugFTN(DriverConst::DEBUG_BROWSE, "BACnet browsing started !!! #3", dynlen(ddsPropertyIdsFromIDToName));

        // get property data types
        for (int i = 1; i <= dynlen(diDeviceObjectTypeIds); i++)
        {
          if (mappingHasKey(gBnApp_mObjectTypesAndIds, diDeviceObjectTypeIds[i]))
          {
            dsDeviceObjectTypeNames[i] = gBnApp_mObjectTypesAndIds[diDeviceObjectTypeIds[i]];
            dyn_int diPropertyTypeIds;
            dyn_string dsPropertyNames;
            mapping mPropertyNameAndTypeId;
            mapping mObjectTypePropertyNameAndTypeId, mPropertyNameAndArrayType;

            BnAppGetProperyType(ddsPropertyIdsFromIDToName[i], dsPropertyNames, diPropertyTypeIds, dsDeviceObjectTypeNames[i], diDeviceObjectTypeIds[i]);

            for (int j = 1; j <= dynlen(diPropertyTypeIds); j++)
            {
              mPropertyNameAndTypeId[dsPropertyNames[j] ] = diPropertyTypeIds[j] ;
            }

            mObjectTypePropertyNameAndTypeId = makeMapping("name", dsDeviceObjectTypeNames[i], "properties", mPropertyNameAndTypeId, "instance", diDeviceInstanceNumber[i]);
            dynAppend(dmObjectTypePropertyNameAndTypeId, mObjectTypePropertyNameAndTypeId);
          }
          else
          {
            dsDeviceObjectTypeNames[i] = "unknown Object ID : " +  diDeviceObjectTypeIds[i];
          }
        }
      }
      else // online browsing unsuccessful, driver responds but fetch an empty list, it falls back to the default browsing ( static via text files)
      {
        staticBrowsingFunction(dmObjectTypePropertyNameAndTypeId);
        bBrowseIsStatic = TRUE;
      }
    }
    else //online browsing unsuccessful or driver does not respond in time for browsing this device, it falls back to the default browsing ( static via text files)
    {
      DebugFTN(DriverConst::DEBUG_BROWSE, "BACnet browsing started !!! #2.2 static browsing", dynlen(dmObjectTypePropertyNameAndTypeId));
      staticBrowsingFunction(dmObjectTypePropertyNameAndTypeId);
      bBrowseIsStatic = TRUE;
    }

    DebugFTN(DriverConst::DEBUG_BROWSE, "BACnet browsing finished !!! #4", dynlen(dsDeviceObjectTypeNames), dynlen(dmObjectTypePropertyNameAndTypeId));
  }

  /**
  * @brief function returns the IP address of eth1 (the production network interface)
  */
  private string getProductionInterfaceIp()
  {
    string sIP;
    system("ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1", sIP);

    if (sIP == "") //under docker
    {
      system("ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1", sIP);
    }

    if (sIP == "") //under docker
    {
      system("ip -o -4 addr list eno1 | awk '{print $4}' | cut -d/ -f1", sIP);
    }

    if (sIP == "") //under docker
    {
      system("ip -o -4 addr list eno2 | awk '{print $4}' | cut -d/ -f1", sIP);
    }

    strreplace(sIP, "\n", "");
   // DebugTN("BACnet network interface is", sIP);
    return sIP;
  }

  /**
  * @brief function to set foreignRegistrationAddress config entry for device (but unique)
  */
  private bool updateConfigForeignRegistrationAddressEntry(int iDeviceNumber, string sIpPort = "")
  {
    string sPath = getPath(CONFIG_REL_PATH, "config");
    string sSection = "bacnet", sKey = "foreignRegistrationAddress";


    dyn_string dsValues, dsComments, dsRow;
    paCfgReadValueListAndComment(sPath, sSection, sKey, dsValues, dsComments, dsRow);
    mapping mDevAddr, mAddrDev, mDevRow;

    // DebugTN("config entry - current vals read", dsValues, dsComments, dsRow);
    //get mapping
    for (int i = 1; i <= dynlen(dsValues); i++)
    {
      dyn_string dsDev = strsplit(dsComments[i], ",");

      mAddrDev[dsValues[i]] = (dyn_int)dsDev;


      for (int j = 1; j <= dynlen(dsDev); j++)
      {
        mDevAddr[(int)dsDev[j]] = dsValues[i];
        mDevRow[(int)dsDev[j]] =  dsValues[i];
      }
    }

    //remove (from) entry
    if (sIpPort == "")
    {
      if (mappingHasKey(mDevRow, iDeviceNumber))
      {
        dyn_string dsDevIds;

        if (mappingHasKey(mDevAddr, iDeviceNumber))
        {
          dsDevIds = mAddrDev[mDevAddr[iDeviceNumber]];
          int iPos = dynContains(dsDevIds, iDeviceNumber);

          if (iPos > 0) //remove device from entry
          {
            dynRemove(dsDevIds, iPos);
          }
        }

        return updateEntry(mDevRow[iDeviceNumber], mDevRow[iDeviceNumber], dsDevIds, sPath, sSection, sKey);
      }
      else
      {
        return FALSE; //entry not existing
      }
    }
    else if (!mappingHasKey(mDevAddr, iDeviceNumber) || //new device
             sIpPort != mDevAddr[iDeviceNumber]) //ip/port change
    {
      bool bRet;

      if (mappingHasKey(mDevAddr, iDeviceNumber)) //existing device
      {
        dyn_string dsOldDevIds = mAddrDev[mDevAddr[iDeviceNumber]];
        int iPos = dynContains(dsOldDevIds, iDeviceNumber);

        if (iPos > 0) //remove device from entry
        {
          dynRemove(dsOldDevIds, iPos);
          //update old line
          bRet = updateEntry(mDevRow[iDeviceNumber], mDevRow[iDeviceNumber], dsOldDevIds, sPath, sSection, sKey);
        }
      }

      dyn_string dsNewDevIds;

      if (mappingHasKey(mAddrDev, sIpPort))
      {
        dsNewDevIds = mAddrDev[sIpPort];
      }

      dynAppend(dsNewDevIds, iDeviceNumber);

      bRet |= updateEntry(mappingHasKey(mAddrDev, sIpPort) ? mDevRow[mAddrDev[sIpPort][1]] : "",
                          sIpPort, dsNewDevIds, sPath, sSection, sKey);

      return bRet;
    }

    return FALSE;
  }
  /**
   * @brief function create config entry for BACnet BBMD
   * @param sIP          the IP address and Port
   * @param diDeviceIds  the device IDs, which uses the given BBMD (will be added as comment #<deviceNumber1>,<deviceNumber2>)
   */
  private string createConfigEntry(const string &sIP, const dyn_int &diDeviceIds)
  {
    return "NOQUOTE:\"" + sIP + "\"\t#" + getListAsString(diDeviceIds);
  }

  /**
   * @brief function to update config entry
   * @param sOldIp              old IP address and port to be replaced
   * @param sNewIp              old IP address and port
   * @param dsNewDeviceNumbers  the device IDs, which uses the given BBMD (will be added as comment #<deviceNumber1>,<deviceNumber2>)
   * @param sPath               config file path + name
   * @param sSection            config file section
   * @param sKey                config file key
   */
  private bool updateEntry(string sOldIp, string sNewIP, dyn_string dsNewDeviceNumbers, const string &sPath,
                           const string &sSection, const string &sKey)
  {
    if (sOldIp == "") //addRow
    {
      paCfgInsertValue(sPath, sSection, sKey, createConfigEntry(sNewIP, dsNewDeviceNumbers));
      DebugFTN("BACNET", "bacnet config entry INSERT", createConfigEntry(sNewIP, dsNewDeviceNumbers));
      return TRUE;
    }
    else if (dynlen(dsNewDeviceNumbers) > 0) //update device list for existing entry
    {
      paCfgDeleteValue(sPath, sSection, sKey, sOldIp);
      paCfgInsertValue(sPath, sSection, sKey, createConfigEntry(sNewIP, dsNewDeviceNumbers));

      //     paCfgReplaceValue(sPath, sSection, sKey, sOldIp,
      //                                              createConfigEntry(sNewIP, dsNewDeviceNumbers));
      DebugFTN("BACNET", "bacnet config entry UPDATE", sOldIp, createConfigEntry(sNewIP, dsNewDeviceNumbers));
      return FALSE; //driver restart required
    }
    else //last one -> remove entry
    {
      paCfgDeleteValue(sPath, sSection, sKey, sOldIp);
      DebugFTN("BACNET", "bacnet config entry DELETE", sOldIp);
      return TRUE; //driver restart required
    }
  }

  /**
   * @brief function to read config entry list including comments
   * @param sPath               config file path + name
   * @param sSection            config file section
   * @param sKey                config file key
   * @param dsValues            values
   * @param dsComments          comments of the values rows
   * @param dsRows              rows with key, values and comments
   */
  private paCfgReadValueListAndComment(const string &sPath, const string &sSection, const string &sKey,
                                       dyn_string &dsValues, dyn_string &dsComments, dyn_string &dsRows)
  {
    string sContent;
    int iKeylen = strlen(sKey);
    fileToString(sPath, sContent);
    dyn_string dsLines = strsplit(sContent, "\n");

    for (int i = 1; i <= dynlen(dsLines); i++)
    {
      int iPos = strpos(dsLines[i], sKey);

      if (iPos >= 0)
      {
        int iStart = strpos(dsLines[i], "\"", iPos + iKeylen), iEnd = strpos(dsLines[i], "\"", iStart + iKeylen);
        string sValue = substr(dsLines[i], iStart);
        dynAppend(dsRows, sValue);

        int iCommentPos = strpos(sValue, "#");
        string sComment = substr(sValue, iCommentPos + 1);
        sValue = substr(sValue, 0, iCommentPos - 1);
        strreplace(sValue, "\"", "");
        strreplace(sValue, " ", "");
        strreplace(sComment, " ", "");
        dynAppend(dsValues, sValue);
        dynAppend(dsComments, sComment);
      }
    }
  }

  /**
   * @brief function to converte an array into comma separated string
   * @param daVals   the array to be converted to a comma separated string
   * @return string  comma separated string
   */
  private string getListAsString(const dyn_anytype &daVals)
  {
    string sRet = daVals;
    strreplace(sRet, " | ", ",");
    return sRet;
  }

  /**
  * @brief restart the driver if
  * @param sDeviceKey     device key
  */
  private restartDriver(string sDeviceKey)
  {
    //required for S7+ to restart driver to get new browsing result (if PLC programm has been updated)
    string sDp = getDriverConnectionDp(sDeviceKey);

    int iManNum = convManIdToInt(DRIVER_MAN, DRIVER_NUMBER);

    DebugTN("BACnet restart driver, because of config file change...", sDeviceKey, sDp, iManNum);

    dpSetWait("_Managers.Exit:_original.._value", iManNum);

    string sManager = getProcessName();
    delay(1);

    do
    {
      delay(0, 100);
    }
    while (!isManagerRunning(host1, sManager));


    dpSetWait("_Managers.Exit", -1); //reset

    DebugTN("BACnet driver restarted", sDeviceKey, sDp);
  }

  /**
  * @brief function to modify datpoints, which is called at begin of updateDeviceDp()
  * @param sDeviceKey     device key
  * @param mParams        configuration mapping for the device
  */
  protected void postUpdateDeviceDp(const string &sDeviceKey, const langString &lsName, const langString &lsLocation, const langString &lsDescription, const string &sAddress, const mapping &mParams)
  {
    string sBBMD = mappingHasKey(mParams, "ipAddressBBMD") ? mParams["ipAddressBBMD"] : "";

    if (sBBMD != "") // port is only possible if ip address is given
    {
      sBBMD += (mappingHasKey(mParams, "portBBMD") && mParams["portBBMD"] != "") ? ":" + mParams["portBBMD"] : "";
    }

    bool bRestartDriver = updateConfigForeignRegistrationAddressEntry(getDeviceId(sDeviceKey, FALSE), sBBMD);

    if (bRestartDriver)
    {
      restartDriver(sDeviceKey);
    }
    else //reset connection, because sometime bacnet driver does not detect correct connection state
    {
      string sDp = getDriverConnectionDp(sDeviceKey);
      dpSetWait(sDp + ".Active", FALSE);
      dpSetWait(sDp + ".Active", TRUE);
    }
  }
  /**
  * @brief function of base class, delete config entry on device remove
  * @param sDeviceKey     device key
  * @param mParams        configuration mapping for the device
  */
  protected void preDeleteDeviceDp(const string &sDeviceKey, const mapping &mParams)
  {
    bool bRestartDriver = updateConfigForeignRegistrationAddressEntry(getDeviceId(sDeviceKey, FALSE), "");

    DriverApp::preDeleteDeviceDp(sDeviceKey, mParams);

    if (bRestartDriver)
    {
      restartDriver(sDeviceKey);
    }
  }

  private const string DEVICE_CONNECTNION_TAG_PREFIX = "BACnet_ConnectionTag_";
  private const string ARRAY_LEN_REQUEST_DPE  = "_bacnet_arraylenth_request_element";
  private const int ARRAY_LEN_REQUEST_TIMEOUT = 3;  //seconds to wait for answer of array lenth from driver
  private const int BROWSING_REQUEST_TIMEOUT  = 60; //seconds to wait for browsing respons from driver for one device
};
