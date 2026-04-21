/// @cond ETM_Internal
global mapping mTypes;
global bool bDebugToLog = FALSE;


// bacnet application related global variables
global mapping gBnApp_mObjectTypesAndIds;
global mapping gBnApp_mapBACnetObjects;
global mapping gBnApp_mapBACnetProperties;
global mapping gBnApp_mapBACnetPropTypes;
global mapping gBnApp_mapBnToOaDt;
global mapping gBnApp_mapBACnetPropIsArray;
global mapping gBnApp_mObjPropType;
global mapping gBnApp_mObjectTypeConfig;
global dyn_int gBnApp_diObjDepPropTypes;

//======================================================================================================
// dyn_string BnGetPeriAddress(string sDP, string systemName)
// string sDP       ->  Name of DP
// string systemName
//
// this function is used to get all LEAF`s of a certain DP with PeriAddr
//
// returns a list of DPE
//
// HISTORY:
// 2008.08.26    base version            BL
// 2009.07.31    dist functionality      dfranken
// XXXX.XX.XX    ............            ..
//
//======================================================================================================
dyn_string BnGetPeriAddress(string sDP, string systemName)
{
  dyn_dyn_anytype ddaData;
  dyn_string dsResult, dsDataAddressType;
  string sQuery;
  dyn_int diAdrType;

  //dfranken July 31. 2009 remove old Version without remote System Call
  //sQuery = "SELECT '_original.._value' FROM '" + sDP + "' WHERE _LEAF";

  //new Version, to check remote Systems
  sQuery = "SELECT '_original.._value' FROM '" + sDP + "' REMOTE '" + systemName + "' WHERE _LEAF";
  dpQuery(sQuery, ddaData);

  /*                                                Old Version with one dpGet for each AddressConfig
    for ( int i = 2;i<= dynlen(ddaData);i++)
    {
      dpGet(ddaData[i][1]+":_address.._type",iAdrType);

      if (iAdrType == DPCONFIG_PERIPH_ADDR_MAIN)
      {
        dynAppend(dsResult,ddaData[i][1]);
      }
    }
  */

  for (int i = 2; i <= dynlen(ddaData); i++) //Preparing Data for dpGet
  {
    dsDataAddressType[i - 1] = ddaData[i][1] + ":_address.._type";
  }

  dpGet(dsDataAddressType, diAdrType);       //Get all AddressTypes in one dpGet

  for (int i = 2; i <= dynlen(ddaData); i++)
  {
    if (diAdrType[i - 1] == DPCONFIG_PERIPH_ADDR_MAIN)
    {
      dynAppend(dsResult, ddaData[i][1]);
    }
  }

  return dsResult;
}

//======================================================================================================
// int BnModifyAddressesForDevice(string sDeviceDPName, dyn_string dsAddresses,int iInstance, string systemName)
//
// string sDeviceDPName         ->  Name of DP for changes
// dyn_string dsAddresses       ->  List of DPE with per. Adr.
// int iInstance                ->  instance number for Object
//
// this function is used to Modify Device Addresses in objects created
//
// returns 0 on OK
//
// HISTORY:
// 2008.08.26    base version            BL
// XXXX.XX.XX    ............            ..
//
//======================================================================================================
int BnModifyAddressesForDevice(string sDeviceDPName, dyn_string dsAddresses, int iInstance, string systemName)
{
  if (strpos(sDeviceDPName, ":") != -1)
    sDeviceDPName = dpSubStr(sDeviceDPName, DPSUB_DP);

  int iSumErr, iRefLen;
  dyn_string dsSplitted, dsAddressReference, dsAddressesConfigs;
  iSumErr = 0;
  string driverNum;
  dyn_string splitDriver;
  int error, driverInt;

  //get Driver ID
  driverNum = BnGetFirstBACnetDP(systemName);
  splitDriver = strsplit(driverNum, "_");

  if (dynlen(splitDriver) > 1)
    driverInt = (int)splitDriver[dynlen(splitDriver)];
  else
    driverInt = 1;

  //DebugN("Dfranken Driver Num: ", driverInt);

  for (int j = 1; j <= dynlen(dsAddresses); j++)     //Prepare dsAddressesConfigs for dpGet Command
    dsAddressesConfigs[j] = dsAddresses[j] + ":_address.._reference";

  if (dynlen(dsAddressesConfigs) > 0)
    dpGet(dsAddressesConfigs, dsAddressReference);

  for (int i = 1; i <= dynlen(dsAddresses); i++)
  {
    // split Address-Reference in pieces
    dsSplitted = strsplit(dsAddressReference[i], ".");
    iRefLen = dynlen(dsSplitted);

    // replace old device with new one
    dsAddressReference[i] = sDeviceDPName + "." + dsSplitted[2] + "." + iInstance + "." + dsSplitted[4];

    if (iRefLen > 4)
      dsAddressReference[i] = dsAddressReference[i] + "." + dsSplitted[5];

    // write back
    //dpSetWait(dsAddresses[i] + ":_address.._reference",sAddressReference);

    //change Driver Number if the driver is operating with another number than "1"
    if (driverInt != 1)
      dpCopyConfig(dsAddresses[i], dsAddresses[i], makeDynString("_distrib", "_address", "_smooth", "_cmd_conv", "_msg_conv"), error, driverInt);

    //todo check error and set iSumErr = -1
  }

  dpSetWait(dsAddressesConfigs, dsAddressReference);

  return iSumErr;
}

//======================================================================================================
// string BnGetFirstBACnetDP(string systemName)
// string systemName       ->  requested Systemname
//
// this function returns the first BACnet Driver DP from the requested System
//
// HISTORY:
// 2009.11.08    base version            dfranken
// XXXX.XX.XX    ............            ..
//
//======================================================================================================
string BnGetFirstBACnetDP(string systemName)
{
  string sQuery;
  dyn_dyn_anytype resultData;
  string checkDP;
  string pattern = "BACNET";
  string DriverCommon = "_DriverCommon";
  bool rightActive;
  dyn_int connectedDriversLeft;
  dyn_int connectedDriversRight;
  dyn_int connectedDrivers;
  int rc;
  bool reduSystem;

  //take own System if systemName is empty
  if (systemName == "")
    systemName = getSystemName();

  //check if ":" is missing in SystemName and add it if necessary
  if (strpos(systemName, ":") < 0)
  {
    systemName = systemName + ":";
  }

  isRemoteSystemRedundant(reduSystem, systemName);

  dpGet(systemName + "_ReduManager_2.Status.Active", rightActive,
        systemName + "_Connections.Driver.ManNums", connectedDriversLeft,
        systemName + "_Connections_2.Driver.ManNums", connectedDriversRight);

  //connectedDrivers is the effective Variable
  if (reduSystem && rightActive)
    connectedDrivers = connectedDriversRight;
  else
    connectedDrivers = connectedDriversLeft;

  sQuery = "SELECT '_online.._value' FROM '_Driver*.DT' REMOTE '" + systemName + "' WHERE '_online.._value' == \"" + pattern + "\" AND _DPT = \"" + DriverCommon + "\"";
  dpQuery(sQuery, resultData);

  //dfranken toDo implement ReduCheck
  if (dynlen(resultData) > 1)
  {
    //parse through results to find first BACnet Driver
    for (int i = 2; i <= dynlen(resultData); i++)
    {
      checkDP = dpSubStr(resultData[i][1], DPSUB_DP);

      //DebugN("checkDP: ", checkDP);
      //DebugN(strpos(checkDP,"_2"));
      //check if current BACnet Driver is content of the connected Drivers and DP is no redu dp like: 2_2
      if (dynContains(connectedDrivers, strltrim(checkDP, "_Driver")) && (strpos(checkDP, "_2") < 0))
      {
        //found
        //DebugN("Found: _Bacnet_" + strltrim(checkDP, "_Driver"));
        if (dpExists("_Bacnet_" + strltrim(checkDP, "_Driver")))
        {
          return "_Bacnet_" + strltrim(checkDP, "_Driver"); //get Driver ID and return assambled Bacnet DP Name
        }
        else //DP don't exists create it
        {
          DebugN("Driver DP: " + "_Bacnet_" + strltrim(checkDP, "_Driver") + " don't exists, generating it");
          rc = dpCreate("_Bacnet_" + strltrim(checkDP, "_Driver"), "_Bacnet", getSystemId(systemName));

          if (!rc)
          {
            DebugN("DP Generation Succesful");
          }
          else
          {
            DebugN("DP Generation Failed, take Default DP");
            return "_Bacnet_1";
          }

          return "_Bacnet_" + strltrim(checkDP, "_Driver"); //get Driver ID and return assambled Bacnet DP Name
        }
      }
      else
      {
        //not found, check next Step
        //DebugN("Ignore: _Bacnet_" + strltrim(checkDP, "_Driver"));
        continue;
      }
    }

    //return _Bacnet_1 if no valid driver DP found
    //DebugN("found no Valid Driver DP, return _Bacnet_1");
    return "_Bacnet_1";
  }
  else
  {
    return "_Bacnet_1";
  }
}

//======================================================================================================
// int BnActivateAddresses(dyn_string dsAddresses, bool bActivation)
// dyn_string dsAddresses       ->  List of DPE with per. Adr.
// bool bActivation             ->  0 = deactivate 1 = activate ...
// string sProperties = ""      -> List of Properties applicable for this object
//
// this function is used to Activate/Deactivate Addresses in a DP
//
// returns 0 on OK
//
// HISTORY:
// 2008.08.26    base version            BL
// XXXX.XX.XX    ............            ..
//
//======================================================================================================
int BnActivateAddresses(dyn_string dsAddresses, bool bActivation, string sProperties = "")
{
  int iSumErr;
  iSumErr = 0;
  string meldung, sErrorAddress, sCurrentDP;
  dyn_string dsProps, dsAll;
  int k;
  dyn_string dsAddressesToSetActive, dsAddressesForLog;
  dyn_bool dbActivation;

  if (!dynlen(dsAddresses))
    return iSumErr;

  for (int i = 1; i <= dynlen(dsAddresses); i++) //IM106140
    if (patternMatch("**.property.Active_COV_Subscriptions*", dsAddresses[i]))
    {
      dynRemove(dsAddresses, i);
      break;
    }

  meldung = getCatStr("BACnetGeneral", "BACnetObjekt") + dpSubStr(dsAddresses[1], DPSUB_DP) + getCatStr("BACnetGeneral", "ContainsProperties");
  BnEngineeringLog(meldung);

  if (bDebugToLog)
    DebugN(meldung);

  meldung = "";
  dpGet("_BACnetEng.Properties", dsAll);

  dsProps = strsplit(sProperties, ",");

  for (int i = 1; i <= dynlen(dsProps); i++)
  {
    k = (int)dsProps[i];

    if (k + 1 <= dynlen(dsAll))
      meldung += dsAll[k + 1] + ", ";
    else
      meldung += k + 1 + ", ";
  }

  if (meldung == "")
    meldung = getCatStr("BACnetGeneral", "NoProperties");

  BnEngineeringLog(meldung);

  if (bDebugToLog)
    DebugN(meldung);

  for (int i = 1; i <= dynlen(dsAddresses); i++)
  {
    if (BnHasObjectProperty(dsAddresses[i], sProperties, dsAll))
    {
      //dpSetWait(dsAddresses[i]+ ":_address.._active",bActivation);
      dynAppend(dsAddressesToSetActive, dsAddresses[i] + ":_address.._active");
      dynAppend(dsAddressesForLog, dsAddresses[i]);
      dynAppend(dbActivation, bActivation);
    }

    // maybe Deactivation if not
  }

  if (dynlen(dsAddresses) > 0)       // Activating the Address for the _Error DPE because this DPE is not in the
  {
    // List of Properties existing for the BACnet Type (Just Dummy DPE for the Driver)
    sCurrentDP = dpSubStr(dsAddresses[1], DPSUB_SYS_DP);
    sCurrentDP = strltrim(sCurrentDP, ".");
    sCurrentDP = strrtrim(sCurrentDP, ".");

    sErrorAddress = sCurrentDP + ".property._Error";

    if (dpExists(sErrorAddress))
    {
      //dpSetWait(sErrorAddress + ":_address.._active",bActivation);
      dynAppend(dsAddressesToSetActive, sErrorAddress + ":_address.._active");
      dynAppend(dsAddressesForLog, sErrorAddress);
      dynAppend(dbActivation, bActivation);
    }
  }

  dpSetWait(dsAddressesToSetActive, dbActivation);      //Setting all Addresses to active in one dpSet

  if (bDebugToLog)
    DebugN("BnActivateAddresses activates address for the following properties ", dsAddressesForLog);

  return iSumErr;
}

//======================================================================================================
// int BnEngineeringLog(string sAction)
// string sAction       ->  the action carried out as text
//
// this function is used to write actions to a DP and alogfile during the engineering process
// The DP is used the show progress information in the Engineering Explorer
//
// returns always 0
//
// HISTORY:
// 2008.08.26    base version            BL
// XXXX.XX.XX    ............            ..
//
//======================================================================================================
int BnEngineeringLog(string sAction)
{
  if (dpExists("_BACnetEng.Log"))
  {
    dpSet("_BACnetEng.Log", sAction);
    BnLogToFile(sAction);
  }
  else
  {
    // log if no viewer
    DebugTN(sAction);
  }

  return 0;
}

//======================================================================================================
// int BnLogToFile(string sAction)
// string sAction       ->  the action carried out as text
//
// this function is used to write actions to a logfile during the engineering process
// Date/Time and User will be automatically appended to an line
//
// returns always 0
//
// HISTORY:
// 2008.08.26    base version            BL
// XXXX.XX.XX    ............            ..
//
//======================================================================================================
int BnLogToFile(string sAction)
{
  int iCheck;
  file fLog;
  string sWrite, sPath, sTime;

  sPath = getPath(DATA_REL_PATH);
  iCheck = access(sPath + "/BACnet_Engineering.log", F_OK);

  if (iCheck != 0)
  {
    // create File
    fLog = fopen(sPath + "/BACnet_Engineering.log", "a+");
  }
  else
  {
    fLog = fopen(sPath + "/BACnet_Engineering.log", "a+");
  }

  sTime = getCurrentTime();
  sWrite = sTime + " : User : " + getUserName() + " : " + sAction;
  // write Entry
  fputs(sWrite + "\n", fLog);
  fclose(fLog);
  return 0;
}

//======================================================================================================
// int BnCreateDeviceDP(int iInstance, string systemName = "", string ipAddress = "", bool activateAddress = TRUE)
//
// int iInstance                ->  instance number for the Device Object
// string systemName            ->  system Name
// string ipAddress		->  fix IP Address for Device, this parameter is used for static and dyn Browsong
// bool activateAddress		->  Activate Address at the End ( default is true )
// this function is used to create a new device DP
// returns 0 on OK
//
// HISTORY:
// 2008.08.26    base version            BL
// 2009.31.07    add remote func         DF
// XXXX.XX.XX    ............            ..
//
//======================================================================================================

int BnCreateDeviceDP(int iInstance, string dpSystemName = "", string ipAddress = "", bool activateAddress = TRUE)
{
  dyn_string dsAddressList;
  int iResult, iOID;
  int dpSystemID;
  bool isRemoteSystem;

  //take local System if Parameter is missing
  if (dpSystemName == "")
    dpSystemName = getSystemName();

  //add : to Systemname if missong
  if (strpos(dpSystemName, ":") == -1) //not found
    dpSystemName = dpSystemName + ":";

  //check if remote or local system
  if (dpSystemName == getSystemName())
    isRemoteSystem = FALSE;
  else
    isRemoteSystem = TRUE;

  dpSystemID = getSystemId(dpSystemName);


  // check if DP still here
  if ((dpExists(dpSystemName + "_Device_" + iInstance)) && (dpExists(dpSystemName + ":Device_" + iInstance)))
  {
    //dp is already existing cancel DP generation
    return -1;
  }

  //Check if Device Generation is allowed in external Hook Function
  if (!hook_checkController(getSystemName(dpSystemID) + "Device_" + iInstance))
  {
    BnEngineeringLog(getCatStr("BACnetGeneral", "UserAbortedDeviceGeneration") + "Device_" + iInstance);
    return -2;	//Aborted by User
  }

  // create internal DP
  if (isRemoteSystem)
  {
    iResult = dpCreate("_Device_" + iInstance, "_BacnetDevice", dpSystemID);
  }
  else
  {
    iResult = dpCreate("_Device_" + iInstance, "_BacnetDevice");
  }

  if (iResult != 0)
    return iResult;



  // create the  redundant one direct to avoid  problems
  if (isRemoteSystem)
  {
    iResult = dpCreate("_Device_" + iInstance + "_2", "_BacnetDevice", dpSystemID);
  }
  else
  {
    iResult = dpCreate("_Device_" + iInstance + "_2", "_BacnetDevice");
  }

  if (iResult != 0)
    return iResult + 30;



  // copy the Public DP (_MP)
  dpCopy(dpSystemName + "_mp_BACnet_Device", dpSystemName + "Device_" + iInstance, iResult);

  if (iResult != 0)
    return iResult + 20;

  // set the object type (fixed to 8) and OID of the device
  dpSet(dpSystemName + "Device_" + iInstance + ".property.Object_Type", 8);
  iOID = BnGenerateID(8, iInstance);
  dpSet(dpSystemName + "Device_" + iInstance + ".property.Object_Identifier", iOID);

  // Now Set the Device ID to the internal Device DP
  dpSet(dpSystemName + "_Device_" + iInstance + ".DeviceId", iInstance);
  dpSet(dpSystemName + "Device_" + iInstance + ".general.device", iInstance);

  //set ConnInfo Address if availble
  if (ipAddress != "")
  {
    //string networkID = "1";
    //string ipPort = "47808";
    //dpSet(dpSystemName + "_Device_" + iInstance + ".ConnInfo",networkID + ":" + ipAddress + ":" + ipPort);
    dpSet(dpSystemName + "_Device_" + iInstance + ".ConnInfo", ipAddress);
  }

  if (activateAddress)
  {
    // set the Addresses correct
    dsAddressList = BnGetPeriAddress("Device_" + iInstance, dpSystemName);
    //BnModifyAddressesForDevice(dpSystemName + "Device_" + iInstance, dsAddressList, iInstance, dpSystemName);
    BnModifyAddressesForDevice("Device_" + iInstance, dsAddressList, iInstance, dpSystemName);

    // activate all addr.
    BnActivateAddresses(dsAddressList, true);
    dpSet(dpSystemName + "_Device_" + iInstance + ".Active", 1);
  }

  // set the state of engineering to unengineered
  dpSet(dpSystemName + "Device_" + iInstance + ".general.engineering", 1);

  hook_afterDpCreate(dpSystemName + "Device_" + iInstance);

  return 0;
}

//======================================================================================================

unsigned paDecodeModeToPanel(unsigned mode, unsigned &lowlevel, unsigned &einaus, unsigned &imode)
{
  unsigned q;
  q = mode;

  if (q >= 64)
  {
    q -= 64;
    lowlevel = 1;
  }
  else
    lowlevel = 0;

  if (q <= 0 || q == 5) q = 1;

  if (q == 1)
    einaus = 0; // Output
  else if (q < 5 || q == 11)
    einaus = 1; // Input
  else
    einaus = 2; // I/O

  if (q == 2 || q == 6)
    imode = 0; // unsolicited
  else
  {
    if (q == 4 || q == 7)
      imode = 1; // poll
    else if (q == 11 || q == 13)
      imode = 3; // poll on use
    else if (q == 9)
      imode = 4; // alarm
    else
      imode = 2; // single query
  }

  return q;
}

//======================================================================================================

unsigned paDecodePanelToMode(unsigned lowlevel, unsigned einaus, unsigned imode)
{
  unsigned q;

  if (einaus == 0)
    q = 1;               // output
  else
  {
    if (einaus == 1)
    {
      switch (imode)
      {
        case 0: q = 2; break;  // input spontaneous

        case 1: q = 4; break;  // input polling

        case 3: q = 11; break;  // input poll on use

        case 4: q = 9; break;  // input alarm

        default: q = 3;        // input single
      }

      if (lowlevel)
        q += 64; // input + LLV
    }
    else
    {
      if (einaus == 2)
      {
        switch (imode)
        {
          case 0: q = 6; break;  // input spontaneous

          case 1: q = 7; break;  // input polling

          case 3: q = 13; break;  // input poll on use

          case 4: q = 9; break;  // input alarm

          default: q = 8; // input single
        }

        if (lowlevel)
          q += 64; // input + LLV
      }
      else
        q = 1;                 // Ausgang Gruppe
    }
  }

  return q;
}

//======================================================================================================

void paBnUpdatePanelFromDpc(string dpe, int Id, anytype dpc)
{
  int i, j;
  dyn_string dsEqu;
  unsigned lowlevel, einaus, modus, q;
  dyn_string ds, dsObjectTypes, dsProperties;
  dyn_float  df;
  string equ;

  dsEqu = dpNames(dpSubStr(dpe, DPSUB_SYS) + "*", "_BacnetDevice");

  for (i = dynlen(dsEqu); i > 0; i--)
  {
    // don't display redundant datapoints
    if (isReduDp(dsEqu[i]))
    {
      dynRemove(dsEqu, i);
    }
  }

  if (dynlen(dsEqu) > 0)
  {
    for (i = 1; i <= dynlen(dsEqu); i++)
    {
      dsEqu[i] = dpSubStr(dsEqu[i], DPSUB_DP);
      dsEqu[i] = substr(dsEqu[i], 1, strlen(dsEqu[i]) - 1);
    }
  }
  else
  {
    ChildPanelOnCentralModalReturn("vision/MessageWarning",
                                   getCatStr("para", "warning"),
                                   makeDynString(getCatStr("para", "apc_noequipment")), df, ds);

    dpSetWait(myUiDpName() + ".Para.OpenConfig:_original.._value", "",
              myUiDpName() + ".Para.ModuleName:_original.._value", myModuleName());
    return;
  }

  q = paDecodeModeToPanel(dpc[3], lowlevel, einaus, modus);

  paSetPollingValues(q, 0L, lowlevel, 0);

  // <deviceName>.<objectType>.<objectId>.<propertyname>.arrayIndex
  if (dpc[1] != "0")
    ds = strsplit(dpc[1], ".");

  while (dynlen(ds) < 5)
    dynAppend(ds, "");

  getValue("cmbObjectType", "items", dsObjectTypes);
  //getValue("cmbProperty", "items", dsProperties);

  if (ds[1] == "")
    equ = dsEqu[1];
  else
    equ = ds[1];

  setMultiValue("cboAddressActive", "state", 0, dpc[12],
                "var_name", "text", dpc[1],
                "cmbEquipment", "items", dsEqu);

  j = dpc[7] - 800 + 1;

  if (j == 23) // we skip some bacnet types
    j -= 10;

  bool bEventState;

  if (ds[4] == "Event_State")
    bEventState = TRUE;

  setMultiValue("cmbEquipment", "selectedPos", dynContains(dsEqu, equ),
                "cmbObjectType", "selectedPos", dynContains(dsObjectTypes, ds[2]),
                "sbObjectId", "text", ds[3],
                "tfIndex", "text", ds[5],
                "einaus", "number", einaus,
                "lowlevel", "state", 0, lowlevel,
                "Treiber", "text", dpc[9],
                "modus", "number", modus,
                "modus", "itemEnabled", 4, bEventState,
                "cmbPollGroup", "text", dpc[11],
                "trans_art", "selectedPos", j);

  if (mappingHasKey(mTypes, cmbObjectType.text))
  {
    cmbProperty.deleteAllItems();
    cmbProperty.items = mTypes[cmbObjectType.text];
  }


  getValue("cmbProperty", "items", dsProperties);

  setValue("cmbProperty", "selectedPos", dynContains(dsProperties, ds[4]));

  if (dynContains(dsEqu, equ) < 1)
  {
    ChildPanelOnCentralModalReturn("vision/MessageWarning",
                                   getCatStr("para", "warning"),
                                   makeDynString(getCatStr("para", "apc_nousedequipment")), df, ds);
  }

  paBnSetIoMode(einaus);

}

//======================================================================================================

void paBnUpdateDpcFromPanel(dyn_anytype &dpc)
{
  unsigned einaus, imode, lowlevel, mode;
  int j, subindex, driver;
  bool active;
  string s, sPollGroup;

  getMultiValue("cboAddressActive", "state", 0, active,
                "trans_art", "selectedPos", j,
                "Treiber", "text", driver,
                "var_name", "text", s,
                "subindex", "text", subindex,
                "einaus", "number", einaus,
                "lowlevel", "state", 0, lowlevel,
                "cmbPollGroup", "text", sPollGroup,
                "modus", "number", imode);

  if (j == 13)
    j += 10;

  j = 800 + j - 1;

  mode = paDecodePanelToMode(lowlevel, einaus, imode);

  dpc[1] = s;
  dpc[2] = subindex;
  dpc[3] = mode;
  dpc[7] = j;
  dpc[8] = globalAddressDrivers[dynContains(globalAddressTypes, globalAddressNew[paMyModuleId()])];
  dpc[9] = driver;
  dpc[11] = sPollGroup;
  dpc[12] = active;
}

//======================================================================================================

void paBnSetOptions()
{
  paBnSetMapping();

  dyn_string dsItemsObjT;
  dynClear(dsItemsObjT);
  dsItemsObjT = mappingKeys(mTypes);
  dynSortAsc(dsItemsObjT);

  if (dynlen(dsItemsObjT) > 0)
  {
    cmbObjectType.deleteAllItems();
    cmbObjectType.text  = "";
    cmbObjectType.items = dsItemsObjT;
  }
}

//======================================================================================================

string paBnEncodeAddress()
{
  string ref;

  if (tfIndex.text == "")
    ref = cmbEquipment.text + "." + cmbObjectType.text + "." + sbObjectId.text + "." + cmbProperty.text;
  else
    ref = cmbEquipment.text + "." + cmbObjectType.text + "." + sbObjectId.text + "." + cmbProperty.text + "." + tfIndex.text;

  return ref;
}

//======================================================================================================

void paBnSetMapping()
{
  string sContent, sFilePath, sType;
  file fFile;
  dyn_string dsRows, dsProperties;
  int err;

  sFilePath = getPath(DATA_REL_PATH, "bacnet/BACNet_objecttype_mapping.cat");
  fFile = fopen(sFilePath, "r");

  if ((err = ferror(fFile)) != 0)
  {
    if (bDebugToLog)
      DebugN("Error " + err + " opening file " + sFilePath);

    return;
  }

  fileToString(sFilePath, sContent);
  dsRows = strsplit(sContent, "\n");

  for (int i = 1; i <= dynlen(dsRows); i++)
  {
    if (dsRows[i][0] != "-" && dsRows[i] != "")
    {
      sType = dsRows[i];
      dyn_string dsSplit = strsplit(sType, ",");
      sType = dsSplit[1];

      i++;
      dynClear(dsProperties);

      while ((dynlen(dsRows) >= i) && (dsRows[i][0] == "-"))
      {
        dynAppend(dsProperties, strltrim(dsRows[i], "-"));
        i++;
      }

      mTypes[sType] = dsProperties;
    }
  }

  fclose(fFile);
}

//======================================================================================================

paBnSetIoMode(int io)
{
  int im = modus.number;

  if (io == 1)
    einaus.number = io;

  io++;

  if (io == 2)
  {
    if (im == 0) io = 2;   // input unsolicited
    else if (im == 1) io = 4;  // input polling
    else if (im == 3) io = 11;  // input polling on use
    else if (im == 4) io = 9;  // alarm
    else           io = 3; // input single query
  }
  else if (io == 3)
  {
    if (im == 0) io = 6;   // in/out unsolicited
    else if (im == 1) io = 7;  // in/out polling
    else if (im == 3) io = 13;  // in/out polling on use
    else if (im == 4) io = 9;  // alarm
    else           io = 8; // in/out single query
  }

  paSetComDrv(io);
}

//======================================================================================================
//======================================================================================================
//======================================================================================================

// bacnet application related functions

void BnAppInitGlobals()
{
  if (mappinglen(gBnApp_mObjectTypesAndIds) == 0 || mappinglen(gBnApp_mapBACnetObjects) == 0 || mappinglen(gBnApp_mapBACnetProperties) == 0)
  {
    string sline;
    file fFile;
    dyn_string dsItems, dsline;
    dyn_string dsFiles;
    int i, err;

    dynAppend(dsFiles, getPath(DATA_REL_PATH, "bacnet/BACNet_objecttype_mapping.cat"));
    dynAppend(dsFiles, getPath(DATA_REL_PATH, "bacnet/BACNet_properties_mapping.cat"));

    for (i = 1; i <= dynlen(dsFiles); i++)
    {
      fFile = fopen(dsFiles[i], "r");

      if ((err = ferror(fFile)) != 0)
      {
        DebugN("Error " + err + " opening file " + dsFiles[i]);
        return;
      }

      dynClear(dsItems);

      while (!feof(fFile))
      {
        fgets(sline, 255, fFile);

        if (sline != "" && sline[0] != "-")
        {
          dsline = strsplit(sline, ",");

          if (i == 1) //Objecttypes
          {
            if (dynlen(dsline) != 2)
              continue;

            //throw away the screwing "\n" by parsing to int
            gBnApp_mapBACnetObjects[dsline[1]] = (int)dsline[2];
            gBnApp_mObjectTypesAndIds[(int)dsline[2]] = dsline[1];
          }
          else       //Properties
          {
            //throw away the screwing "\n" by parsing to int
            gBnApp_mapBACnetProperties[dsline[1]] = (int)dsline[2];
            gBnApp_mapBACnetPropTypes[dsline[1]] = (int)dsline[3];
            gBnApp_mapBnToOaDt[dsline[1]] = BnAppGetDataTypeToOa((uint)dsline[3]);

            gBnApp_mapBACnetPropIsArray[dsline[1]] = dynlen(dsline) > 3; //differ if it is an array (can be addressed via index) or a list (used as dyn)
          }
        }
      }

      fclose(fFile);
    }
  }

  BnAppSetObjPropMapping();
  BnAppListObjDepPropTypes();
  BnAppObjectTypeConfig();
}

//==================================================================================================

void BnAppListObjDepPropTypes()
{
  // feedback value, high limit, low limit, max pres value, present value,
  // relinquish default, log buffer, fault high limit, fault low limit
  gBnApp_diObjDepPropTypes = makeDynInt(40, 45, 59, 65, 85, 104, 131, 388, 389);
}
//==================================================================================================

void BnAppObjectTypeConfig()
{
  string sContent, sFilePath, sType, sProp, sDpet, sPg;
  file fFile;
  dyn_string dsRows, dsProperties;
  int iErr, iMode, iDpet, iArrayLen;

  sFilePath = getPath(DATA_REL_PATH, "BACnet_objectTypeConfig.dat");
  fFile = fopen(sFilePath, "r");

  if ((iErr = ferror(fFile)) != 0)
    return;

  fileToString(sFilePath, sContent);
  dsRows = strsplit(sContent, "\n");

  for (int i = 1; i <= dynlen(dsRows); i++)
  {
    sPg = "";
    iMode = DPATTR_ADDR_MODE_INPUT_CYCLIC_ON_USE;
    iDpet = -1;
    iArrayLen = -1;

    if (dsRows[i] != "")
    {
      if (strpos(dsRows[i], "#") == 0)
        continue;

      dyn_string dsSplit = strsplit(dsRows[i], ".");

      sType = dsSplit[1];

      string sTemp = dsSplit[2];

      dsSplit = strsplit(sTemp, ",");

      if (dynlen(dsSplit) > 3)
        sPg = dsSplit[4];

      if (dynlen(dsSplit) > 2)
        iMode = (int)dsSplit[3];

      if (dynlen(dsSplit) > 1)
        sDpet = dsSplit[2];

      sProp = dsSplit[1];

      if (sDpet != "")
      {
        dynClear(dsSplit);
        dsSplit = strsplit(sDpet, ":");

        if (dynlen(dsSplit) > 1)
          iArrayLen = dsSplit[2];

        iDpet = dsSplit[1];
      }

      string sData = (string)iDpet + "," + (string)iMode + "," + sPg + "," + (string)iArrayLen;

      gBnApp_mObjectTypeConfig[sType + "." + sProp] = sData;
    }
  }

  fclose(fFile);
}

//==================================================================================================
anytype BnAppCheckPropData(string sProp, int iOpt)
{
  anytype aReturn = -1;

  if (mappingHasKey(gBnApp_mObjectTypeConfig, sProp))
  {
    string sConfig = gBnApp_mObjectTypeConfig[sProp];

    dyn_string dsSplit = strsplit(sConfig, ",");

    if (dynlen(dsSplit) >= iOpt)
      aReturn = strsplit(sConfig, ",")[iOpt];
  }

  return aReturn;
}

//==================================================================================================
// int BnAppGetDataTypeToOa(uint uiBnDt)
// int uiBnDt  -> BACnet data type
//
// Return value:
// int -> OA DP EL type
//
// this function converts a BACnet data type into a OA DP EL type
//
// HISTORY:
// 2022-03 / mjeidler
//==================================================================================================

int BnAppGetDataTypeToOa(uint uiBnDt)
{
  int iRet;

  switch (uiBnDt)
  {
    case  0: iRet = 0;           break;

    case  1: iRet = DPEL_BOOL;   break;

    case  2:
    case  9:
    case 12: iRet = DPEL_UINT;   break;

    case  3: iRet = DPEL_INT;    break;

    case  4:
    case  5: iRet = DPEL_FLOAT;  break;

    case  6: iRet = DPEL_BLOB;   break;

    case  8: iRet = DPEL_BIT32;  break;

    case 20: iRet = DPEL_LONG;   break;

    // array of characterstring
    case 64:

    // array of BACnetTimestamp
    case 84: iRet = DPEL_DYN_STRING;   break;

    // array of unsigned
    case 75:

    // array of enumerated
    case 111:
      iRet = DPEL_DYN_UINT;   break;


    default: iRet = DPEL_STRING; break;
  }

  return iRet;
}

//==================================================================================================
// void BnAppSetObjPropMapping()
//
// get mapping of types and properties - copied from bacnetDrvPara lib
//
// HISTORY:
// 2022-03 / mjeidler
//==================================================================================================

void BnAppSetObjPropMapping()
{
  string sContent, sFilePath, sType;
  file fFile;
  dyn_string dsRows, dsProperties;
  int err;

  sFilePath = getPath(DATA_REL_PATH, "bacnet/BACNet_objecttype_mapping.cat");
  fFile = fopen(sFilePath, "r");

  if ((err = ferror(fFile)) != 0)
  {
    return;
  }

  fileToString(sFilePath, sContent);
  dsRows = strsplit(sContent, "\n");

  for (int i = 1; i <= dynlen(dsRows); i++)
  {
    if (dsRows[i][0] != "-" && dsRows[i] != "")
    {
      sType = dsRows[i];
      dyn_string dsSplit = strsplit(sType, ",");
      sType = dsSplit[1];

      i++;
      dynClear(dsProperties);

      while ((dynlen(dsRows) >= i) && (dsRows[i][0] == "-"))
      {
        dynAppend(dsProperties, strltrim(dsRows[i], "-"));
        i++;
      }

      gBnApp_mObjPropType[sType] = dsProperties;
    }
  }

  fclose(fFile);
}
//==================================================================================================

int BnAppGetObjectDependingPropType(int iObj)
{
  int iRet;

  switch (iObj)
  {
    case  0: // analog input
    case  1: // analog output
    case  2: // analog value
    case 12: // loop
    case 20: // trend log
    case 24: // pulse converter
    case 25: // event log
    case 27: // trend log multiple
    case 46: // large analog value
      iRet = DPEL_FLOAT;
      break;

    case  3: // binary input
    case  4: // binary output
    case  5: // binary value
    case  7: // command
    case 13: // multi state input
    case 14: // multi state output
    case 19: // multi state value
    case 21: // life safety point
    case 22: // life safety zone
    case 23: // accumulator
    case 28: // load control
    case 48: // positive integer value
      iRet = DPEL_UINT;
      break;

    case  6: // calendar
      iRet = DPEL_BOOL;
      break;

    case 45: // integer value
      iRet = DPEL_INT;
      break;

    case 39: // bit string value
      iRet = DPEL_BIT32;
      break;

    case  8: // device
    case  9: // event enrollment

    //case ??: // file
    //case ??: // group
    case 15: // notification class
    case 16: // program
    case 18: // averaging
      iRet = -1; // property not available for this object type --> mapping file incorrect
      break;

    default:
      iRet = DPEL_STRING;
      break;
  }

  return iRet;
}

//==================================================================================================
// void BnGetProperyType(const dyn_string &dsPropE, dyn_string &dsBnPropE, dyn_int &diBnPropT, const string &sBnObjType, const int &iBnObjTypeId)
// dyn_string
// dyn_dyn_string
// dyn_int
// string
// int
// get property type (separated from BnCreateObjectPropData() for MNSP_Connect team)
//
// HISTORY:
// 2023-03 / sboukhezzar
//======================================================================================================
void BnAppGetProperyType(const dyn_string &dsPropE, dyn_string &dsBnPropE, dyn_int &diBnPropT, const string &sBnObjType, const int &iBnObjTypeId)
{
  for (int i = 1; i <= dynlen(dsPropE); i++)
  {
    string sPropE = dsPropE[i];
    int iPropT = gBnApp_mapBnToOaDt[sPropE];
    int iBnPropT = gBnApp_mapBACnetProperties[sPropE];

    int iPropTypeSpcObject = BnAppCheckPropData(sBnObjType + "." + sPropE, 1);
    int iPropTypeAllObject = BnAppCheckPropData("*." + sPropE, 1);

    if (iPropTypeSpcObject == -2 || iPropTypeAllObject == -2)
      continue;

    if (iPropTypeSpcObject >= 0)
      iPropT = iPropTypeSpcObject;
    else if (iPropTypeAllObject >= 0)
      iPropT = iPropTypeAllObject;
    else if (dynContains(gBnApp_diObjDepPropTypes, iBnPropT) > 0)
      iPropT = BnAppGetObjectDependingPropType(iBnObjTypeId);

    if (iPropT == 0)
      iPropT = DPEL_STRING;

    dynAppend(dsBnPropE, sPropE);
    dynAppend(diBnPropT, iPropT);
  }
}

//======================================================================================================

/// @endcond
