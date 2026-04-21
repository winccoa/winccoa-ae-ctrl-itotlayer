// $License: NOLICENSE

/**
 * @file libs/EB_Package_Base/EB_Api.ctl
 * @brief Contains the API functions.
 */

// used libraries (#uses)
#uses "CtrlCNS"
#uses "CtrlHTTP"
#uses "cns"
#uses "classes/EBlog"
#uses "classes/EBCsv"
#uses "classes/EBTag"
#uses "classes/SymbolPreLoader"
#uses "EB_Package_Base/EB_Api_TagHandling"
#uses "EB_Package_Base/EB_const"
#uses "EB_Package_Base/EB_Dialog"
#uses "EB_Package_Base/PackageState"

// declare variables and constants
const string  sTmpColorRectangleFilePrefix    = "EB_Package/tmpColorRectangle/bar_";     //!< File name prefix for temporary svg files, used in 'EB_getColorRectangleSvg'
const string  sTmpColorRectangleFileExtension = ".svg";                                  //!< File name extension for temporary svg files, used in 'EB_getColorRectangleSvg'
global string sSvgTemplate;                                                              //!< Template file name for temporary svg files, used in 'EB_getColorRectangleSvg'

//----------------------------------------------------------------
/**
 * @brief Sets seconds and milliseconds to 0 for a given time
 * @author Martin Schiefer
 * @param tTime The given time.
 * @return The given time with seconds and milliseconds set to 0.
 */
public time makeT(time tTime)
{
  return makeTime(year(tTime), month(tTime), day(tTime), hour(tTime), minute(tTime), 0, 0);
}

//----------------------------------------------------------------

/**
 * @brief creates an new cns view.
 * @author Martin Schiefer
 * @param ViewId The ID path of the new view.
 * @param ViewName The display name of the new view.
 */
public void EB_createPackageView(string ViewId, langString ViewName)
{
  cnsCreateView(ViewId, ViewName);
}

//----------------------------------------------------------------

/**
 * @brief gets the list of childNodes.
 * @param sParentNodeId Node to get the children from
 * @return dyn_string the list childNodes.
 */
public dyn_string EB_getChildNodeIds(const string &sParentNodeId)
{
  dyn_string dsChildren;
  if (strpos(sParentNodeId, ":") + 1 == strlen(sParentNodeId))
  {
    cnsGetTrees(sParentNodeId, dsChildren);
  }
  else
  {
    cnsGetChildren(sParentNodeId, dsChildren);
  }
  for (int i = 1; i <= dynlen(dsChildren); i++)
  {
    dyn_string dsChilds = EB_getChildNodeIds(dsChildren[i]);
    dynAppend(dsChildren,dsChilds);
  }
  return dsChildren;
}

//----------------------------------------------------------------

/**
 * @brief Creates a node and adds it to the given parent element.
 * @author Martin Schiefer
 * @param ParentId Name of the parent node or tree.
 * @param NodeId ID of the node.
 * @param NodeName Display name of the node.
 */
public void EB_createPackageNode(string ParentId, string NodeId, langString NodeName )
{
  if (!EB_existsPackageNode(NodeId))
    cns_createTreeOrNode(ParentId, NodeId, NodeName, "", CNS_DATATYPE_EMPTY);
}

//----------------------------------------------------------------

/**
 * @brief Creates a tree and adds it to the given parent element.
 * @param sParentId  Name of the parent node or tree.
 * @param sNodeId    ID of the node.
 * @param lsNodeName Display name of the node.
 * @param sDpe       Data point (element) which shall be linked to the node.
 */
public void EB_createPackageDpNode(const string &sParentId, const string &sNodeId, const langString &lsNodeName, const string &sDpe)
{
  if (!EB_existsPackageNode(sNodeId))
    cns_createTreeOrNode(sParentId, sNodeId, lsNodeName, dpSubStr(sDpe, DPSUB_ALL), CNS_DATATYPE_DATAPOINT);
}

//----------------------------------------------------------------

/**
 * @brief Returns all children of a given node
 * @param sNodeId       ID of the node
 * @param bRecursive    TRUE to also return grandchildren, FALSE for only the children
 * @return Children of the specified node
 */
public dyn_string EB_getChildrenOfNode(const string &sNodeId, bool bRecursive = FALSE)
{
  return EB_getChildrenOfTag(sNodeId, bRecursive);
}

//----------------------------------------------------------------

/**
 * @brief Returns the linked datapoint for a given node
 * @param sNodeId ID of the node.
 * @return Linked datapoint element of the specified node
 */
public string EB_getDpFromNode(const string &sNodeId)
{
  string sDp;

  if (EB_existsPackageNode(sNodeId))
    cnsGetId(sNodeId, sDp);

  return sDp;
}

//----------------------------------------------------------------

/**
 * @brief Deletes the given view.
 * @param sViewId ID path of the view which shall be deleted.
 */
public void EB_deletePackageView(const string &sViewId)
{
  if (EB_existsPackageView(sViewId))
    cns_deleteView(sViewId);
}

//----------------------------------------------------------------

/**
 * @brief Deletes the given node.
 * @param sNodeId ID path of the node which shall be deleted.
 */
public void EB_deletePackageNode(const string &sNodeId)
{
  if (EB_existsPackageNode(sNodeId))
    cns_deleteTreeOrNode(sNodeId);
}

//----------------------------------------------------------------

/**
 * @brief Checks whether the given view exists or not.
 * @param sViewPath ID of the view that shall be checked.
 * @return Returns TRUE if the given view exists otherwise FALSE.
 */
public bool EB_existsPackageView(const string &sViewPath)
{
  return cns_viewExists(sViewPath);
}

//----------------------------------------------------------------

/**
  @brief Checks if the given node exists.
  @author Martin Schiefer
  @param sNodePath Id path of the node.
  @return Returns TRUE if the node exists and FALSE if there is no match.
*/
public bool EB_existsPackageNode(const string &sNodePath)
{
  return cns_nodeExists(sNodePath);
}

/**
 * @brief Converts a mapping contains a langString back
 * @details the keys of the mapping must be the language string used in the project
 *          All non-mapping variables will return an empty language string
 * @param m   Mapping containing a langString or an empty string
 * @return Converted langString
 */
langString EB_mappingToLangString(const anytype &m)
{
  langString text;
  if (getType(m) == MAPPING_VAR)
  {
    dyn_string dsKeys = mappingKeys(m);
    for (int i = 1; i <= dynlen(dsKeys); i++)
    {
      setLangString(text, getLangIdx(dsKeys[i]), m[dsKeys[i]]);
    }
  }
  else if (getType(m) == STRING_VAR)
  {
    text = m;
  }
  else if(getType(m)==LANGSTRING_VAR)
  {
    return m;
  }

  return text;
}

/**
 * @brief Converts a langString to a mapping
 * @details The keys of the mapping will be the language string used in the project
 * @param lsText   text to be converted
 * @return Converted langString
 */
mapping EB_LangStringToMapping(const langString &lsText)
{
  mapping mResult;

  for (int i = 0; i < getNoOfLangs(); i++)
  {
    mResult[getLocale(i)] = lsText[i];
  }

  return mResult;
}

/**
 * @brief Converts a dyn_mapping containing langStrings back
 * @details the keys of each mapping must be the language strings used in the project
 * @param m   DynMapping containing langStrings
 * @return Converted langStrings
 */
dyn_langString EB_dynMappingToDynLangString(const dyn_anytype &m)
{
  dyn_langString dText;
  for (int i = 1;  i <= dynlen(m); i++) // for all indexes of the dyn
  {
    dText[i] = EB_mappingToLangString(m[i]);
  }
  return(dText);
}

/**
  @brief Creates a EBlogEntry
  @author Martin Schiefer
  @param sEntryAppName: name of the package
  @param sEntryType: entry tpye -> DPE leaf for the log (Runtime, Configuration)
  @param sEntryReason: reason for the log (e.g. IP, Port, Device, ...)
  @param lsEntryText: multi lingual text of the log entry (or sEntryTextKey will be used to get text from message catalogue)
  @param iEntryType: type/priority of the log entry (1, 2, 3)
  @param tEntryTime: time of log entry (when has the the failure or status change appeared)
  @param sEntryColor: current color of an entry (defined by alarm class)
  @param sEntryTextKey: message catalog entry key of log message - will be searched in "EB_Package_<AppName>" and "EB_Package" cat file
  @param mReplacePlaceholders: mapping with keys to be replaced in text e.g. $1:15, $2:287
  @return The created EBlogEntry
  */
public EBlogEntry EB_createLogEntry(string sEntryAppName, string sEntryType, string sEntryReason, langString lsEntryText, int iEntryType, time tEntryTime = getCurrentTime(), string sEntryColor = "", string sEntryTextKey = "", mapping mReplacePlaceholders = makeMapping())
{
  //TODO check appName; check sEntryType; check iEntryType 1-3
  EBlogEntry myLogEntry;
  if (dpExists("EB_Package_" + sEntryAppName)) // appname check
  {
    myLogEntry.setLogEntry(sEntryType, sEntryReason, lsEntryText, iEntryType, tEntryTime, sEntryAppName, sEntryColor, sEntryTextKey, mReplacePlaceholders);
  }
  else
  {
    throwError(makeError("", PRIO_SEVERE, ERR_PARAM, 71, "Package DP does not exist for package: " + sEntryAppName + " for set log type: " + sEntryType + " reason: " + sEntryReason + " text: " + lsEntryText, getStackTrace()));
  }

  return myLogEntry;
}

/**
  @brief Saves one log entry, if it is not already present
  @author Martin Schiefer
  @param logEntry: the EBlogEntry which should be saved
  @param bPending: if false, the logs will set to CAME and WENT immediately
  @param bForceIfNewLog: if true, an existing log with (but with different log text) will be removed (WENT) and a new log will be created
*/
public void EB_logAdd(const EBlogEntry &logEntry, bool bPending = false, bool bForceIfNewLog = false)
{
  EBlog packageLog;
  packageLog.setAppName(logEntry.sAppName);
  packageLog.doLog(logEntry, bPending, bForceIfNewLog);
  DebugFN("LOG_ADD", "did create log entry for app: " + logEntry.sAppName);
}

/**
  @brief Removes one log entry, if it exists
  @author Martin Schiefer
  @param logEntry: the EBlogEntry which should be removed
*/
public void EB_logRemove(const EBlogEntry &logEntry)
{
  EBlog packageLog;
  packageLog.setAppName(logEntry.sAppName);
  dyn_atime dat;
  packageLog.removePendingLogs(logEntry.sType, dat, 0, logEntry.sReason);
}

/**
 * @brief Removes all log entries for one app (type and reason can be used for filtering)
 * @param sAppName: the app name e.g. "S7"
 * @param sEntryType: entry tpye e.g. LOG_TYPE_ALL or LOG_TYPE_RUNTIME, LOG_TYPE_INTERNET, LOG_TYPE_CONFIGURATION, LOG_TYPE_PERIPHERY, LOG_TYPE_UPDATE
 * @param sReason: pattern key of the the log entries
 */
public void EB_logRemoveAll(const string &sAppName, string sEntryType = LOG_TYPE_ALL, string sReason = "*")
{
  EBlog packageLog = new EBlog(sAppName);
  dyn_string dsEntryTypes;

  //collect entry types
  if (sEntryType == "*")
  {
    dyn_dyn_string ddsTmp = dpGetRefsToDpType(EBlogEntry::sDPT);
    for (int i = 1; i <= dynlen(ddsTmp); i++)
    {
      if (ddsTmp[i][1] != EB_DPTYPE_PACKAGES) //only log entries of EB_Packages DPT
        continue;

      string sType = ddsTmp[i][2]; //e.g. Alerts.Runtime
      strreplace(sType, "Alerts.", ""); //only leaf
      dynAppend(dsEntryTypes, sType);
    }
  }
  else
    dsEntryTypes[1] = sEntryType;

  //for given entry types, get pending logs
  for (int i = 1; i <= dynlen(dsEntryTypes); i++)
  {
    dyn_atime datAlerts;
    packageLog.getPendingLogs(dsEntryTypes[i], datAlerts);
    packageLog.removePendingLogs(dsEntryTypes[i], datAlerts, 0, sReason);
  }
}

/**
 * @brief Returns the specified float if available from the dialog result
 * @param mResult  Result from the dialog function
 * @param iIndex   Index of the value to return
 * @return Specified float from the dialog or 0.0 in case of an error
 */
public float EB_getDialogResultFloat(const mapping &mResult, int iIndex = 1)
{
  float fResult;

  throwError(makeError("", PRIO_WARNING, ERR_IMPL, 54, "This function is deprecated", "Use the new dialog framework"));

  // Check if the mapping contains float value(s)
  if (mappingHasKey(mResult, EB_RETURN_FLOAT) && dynlen(mResult[EB_RETURN_FLOAT]) >= iIndex)
  {
    // Return the specified float
    fResult = mResult[EB_RETURN_FLOAT][iIndex];
  }

  return fResult;
}

/**
 * @brief Returns the specified string if available from the dialog result
 * @param mResult  Result from the dialog function
 * @param iIndex   Index of the value to return
 * @return Specified string from the dialog or empty in case of an error
 */
public string EB_getDialogResultString(const mapping &mResult, int iIndex = 1)
{
  string sResult;

  throwError(makeError("", PRIO_WARNING, ERR_IMPL, 54, "This function is deprecated", "Use the new dialog framework"));

  // Check if the mapping contains string value(s)
  if (mappingHasKey(mResult, EB_RETURN_STRING) && dynlen(mResult[EB_RETURN_STRING]) >= iIndex)
  {
    // Return the specified string
    sResult = mResult[EB_RETURN_STRING][iIndex];
  }

  return sResult;
}

/**
 * @brief Calculates the central position on the window contains the specified module
 * @param fileName    panel to calculate the central position for
 * @param moduleName  module on which to centrally place the specified panel
 * @return central position for the panel ([1] == x, [2] == y)
 */
private dyn_int EB_calculateCentralWindowPosition(const string &fileName, string moduleName = myModuleName())
{
  int x, y, width, height;
  shape panelShape = getShape(moduleName + "." + rootPanel(moduleName) + ":");

  // Check if the specified module is located in an embedded module
  getValue(panelShape.parentPanel != 0 ? panelShape.parentPanel : panelShape, "windowGeometry", x, y, width, height);

  dyn_int size = getPanelSize(fileName);

  // Calculate the central position for the specified panel
  return makeDynInt(x + (width - size[1]) / 2, y + (height - size[2]) / 2);
}

/**
 * @brief Sets the footer in the UI
 * @param sText    The text to show in the footer
 * @param sIcon    The icon to show in the footer
 */
void EB_setFooter(string sText, string sIcon = "")
{
  string _sIcon = "Apps/HUE.svg";
  if (sIcon != "")
  {
    _sIcon = sIcon;
  }
  dpSet("MyBox.Footer.Icon", _sIcon,
        "MyBox.Footer.Text", sText);
}

/**
 * @brief Resets the footer in the UI
 */
void EB_clearFooter()
{
  dpSet("MyBox.Footer.Icon", "",
        "MyBox.Footer.Text", "");
}

/**
  @brief Checks if a datapoint type exists
  @author Martin Schiefer
  @param sDpTypeName: the datapoint type
  @return true if the datapoint type exists
*/
bool EB_dpTypeExists(const string &sDpTypeName)
{
  return dynlen(dpTypes(sDpTypeName)) > 0;
}

/**
  @brief Creates a new DP or copy an existing master DP for creating a new DP
  @author Markus Trummer
  @param sDP: the datapoint name to be created
  @param sType: the datapoint type where to create a DP
  @return Returns: 0 for OK,
                  -100 for DP already exists,
                  -101 for DPT does not exist
                  -102 for dpCreate failure
                  -1 to -12 dpCopy failures
*/
int EB_dpCreateInstance(const string &sDP, const string &sType)
{
  int iError = 0;
  if (dpExists(sDP)) //dp already exists
    return -100;

  if (!EB_dpTypeExists(sType)) //dpt does not exist
    return -101;

  if (dpExists("_mp_" + sType)) //copy existing master dp
  {
    dpCopyBufferClear();
    dpCopy("_mp_" + sType, sDP, iError);
  }
  else
  {
    iError = dpCreate(sDP, sType);
    if (iError != 0) //failure = -1
      iError -= 101; //so failure will be -102
  }
  return iError;
}


/**
  @brief Collects all child elements of a given view and returns them as a json string
  @author Martin Schiefer
  @param sView: the view
  @return Returns: the json string
*/
string EB_cnsTreeToJson(string sView = "_Publish")
{
  string sJson;
  dyn_string dsChildren;
  langString lsDisplayNames;
  blob bUserData;
  cnsGetTrees("." + sView + ":", dsChildren);
  dyn_mapping dmChildren;
  for (int i = 1; i <= dynlen(dsChildren); i++)
  {
    EB_addNodeToDynMapping("." + sView + ":", dsChildren[i], dmChildren, "", "");
  }
  sJson = jsonEncode(dmChildren);
  return sJson;
}

/**
  @brief Creates a mapping for each node of a tree and append the mapping to a given dyn_mapping
  @author Martin Schiefer
  @param sParent: the parent node
  @param sNodeId: the current node
  @param dmChildren: the dyn_mapping
  @return void
*/
void EB_addNodeToDynMapping(const string &sParent, const string &sNodeId, dyn_mapping &dmChildren)
{
  dyn_string dsChildren;
  langString lsDisplayNames;
  string sDpName;
  int iType;
  blob bUserData;

  cnsGetId(sNodeId, sDpName, iType); //Datenpunkt
  cnsGetDisplayNames(sNodeId, lsDisplayNames);
  cnsGetChildren(sNodeId, dsChildren);
  cnsGetUserData(sNodeId, bUserData);

  string sPath = cnsSubStr(sParent, CNSSUB_VIEW | CNSSUB_PATH);
  langString lsDesc   = sDpName == "" ? "": dpGetDescription(sDpName);
  langString lsUnit   = sDpName == "" ? "": dpGetUnit(sDpName);
  langString lsFormat = sDpName == "" ? "": dpGetFormat(sDpName);

  mapping mTemp;
  mTemp["path"] = sPath;
  mTemp["name"] = cnsSubStr(sNodeId, CNSSUB_NODE);
  mTemp["displayNames"] = lsDisplayNames;
  mTemp["data"] = sDpName;
  mTemp["description"] = lsDesc;
  mTemp["unit"] = lsUnit;
  mTemp["format"] = lsFormat;
  mTemp["userData"] = bUserData;

  //append item to given mapping
  dynAppend(dmChildren, mTemp);

  //recursiv add all subnodes
  for (int i = 1; i <= dynlen(dsChildren); i++)
  {
    EB_addNodeToDynMapping(sNodeId, dsChildren[i], dmChildren);
  }
}

/**
  @brief Creates a view from a json string; replace the name of the old view with the name of the new view if the name are not the same
  @author Martin Schiefer
  @param sView: name of the new view
  @param sOldView: name of the old view
  @param sJson: the json string
  @return void
*/
void EB_cnsTreeFromJson(string sView, string sOldView, const string &sJson)
{
  dyn_string dsChildren;
  cnsGetTrees("."+sView+":", dsChildren);
  for (int i = 1; i <= dynlen(dsChildren); i++)
  {
    cns_deleteTreeOrNode(dsChildren[i]);
  }
  dyn_mapping dmTemp = jsonDecode(sJson);
  for (int i = 1; i <= dynlen(dmTemp); i++)
  {
    mapping mTemp = dmTemp[i];
    langString lsDisplayNames = EB_mappingToLangString(mTemp["displayNames"]);

    if (sOldView != sView)
    {
      //if last char of path is not : a . needs to bee added
      if (strlen(mTemp["path"]) - 1 != strpos(mTemp["path"], ":"))
      {
        strreplace(mTemp["path"], sOldView, sView + ".");
      }
      else
      {
        strreplace(mTemp["path"], sOldView, sView);
      }
    }

    string sNewNodeName = cnsSubStr(mTemp["path"], CNSSUB_VIEW | CNSSUB_PATH);
    dyn_string dsNewNodeParentParts = strsplit(mTemp["path"], ":");
    if (dynlen(dsNewNodeParentParts) > 1)
    {
      sNewNodeName += ".";
    }
    sNewNodeName +=  mTemp["name"];
    {

      if (mTemp["data"] != "")
      {
        cns_createTreeOrNode(mTemp["path"], mTemp["name"], lsDisplayNames, dpSubStr(mTemp["data"], DPSUB_ALL), CNS_DATATYPE_DATAPOINT);
      }
      else
      {
        cns_createTreeOrNode(mTemp["path"], mTemp["name"], lsDisplayNames, mTemp["data"], CNS_DATATYPE_EMPTY);
      }
    }

    if (mTemp["userData"] != "")
    {
      cnsSetUserData(sNewNodeName, mTemp["userData"]);
    }
  }
}

/**
  @brief Checks if the given string is an ip address.
  @author Martin Schiefer
  @param sIp       The ip address.
  @param iMaxHost  The highest last octet value to check.
  @returns true if the string is a valid ip address.
*/
bool EB_checkValidIp(const string &sIp, int iMaxHost = 254)
{
  // define, declare and initialite allowed chars
  string sAllowedChars = "1234567890.";

  // iterate all chars of IP string
  for (int i = 1; i <= strlen(sIp); ++i)
  {
    // check if there are unallowed chars in IP string
    if (strpos(sAllowedChars, sIp[i]) == -1)
    {
      return FALSE; //unallowed char in IP
    }
  }

  // split IP string into parts by dot separator
  dyn_string dsIpParts = strsplit(sIp, ".");

  // check number of parts (length of dyn string must be 4, otherwise return FALSE)
  if (dynlen(dsIpParts) != 4)
  {
    return FALSE;
  }

  // iterate all parts of IP string
  for (int i = 1; i <= 4; ++i)
  {
    // check if numbers were entered
    if (dsIpParts[i] == "")
    {
      return FALSE;
    }

    // cast part of IP string to integer
    int iIpPart = (int)dsIpParts[i];

    // check range of IP string, if it's bigger than max host or smaller than zero return FALSE
    if (iIpPart < 0 || iIpPart > iMaxHost)
    {
      return FALSE;
    }
  }

  // if all checks are passed --> return TRUE for a validated IP string
  return TRUE;
}

/**
  @brief Checks if the given string is a MAC address.
  @author Daniel Lomosits
  @param sMac      The MAC address.
  @returns true if the string is a valid MAC address.
*/
bool EB_checkValidMac(const string &sMac)
{
  // define, declare and initialite allowed chars
  string sAllowedChars = "1234567890abcdef:";

  // iterate all chars of MAC string
  for (int i = 1; i <= strlen(sMac); ++i)
  {
    // check if there are unallowed chars in MAC string
    if (strpos(sAllowedChars, sMac[i]) == -1)
    {
      return FALSE; //unallowed char in IP
    }
  }

  // split MAC string into parts by dot separator
  dyn_string dsMacParts = strsplit(sMac, ":");

  // check number of parts (length of dyn string must be 6, otherwise return FALSE)
  if (dynlen(dsMacParts) != 6)
  {
    return FALSE;
  }

  // iterate all parts of MAC string
  for (int i = 1; i <= dynlen(dsMacParts); ++i)
  {
    // check if numbers were entered
    if (dsMacParts[i] == "")
    {
      return FALSE;
    }


    // cast part of MAC string to integer
    int iMacPart = -1;
    int iRet = sscanf(dsMacParts[i], "%x", iMacPart);
    if (iRet <= 0)
    {
      return FALSE;
    }

    // check range of MAC string, if it's bigger than max host or smaller than zero return FALSE
    // cppcheck-suppress knownConditionTrueFalse
    if (iMacPart < 0 || 255 < iMacPart)
    {
      return FALSE;
    }
  }

  // if all checks are passed --> return TRUE for a validated IP string
  return TRUE;
}

/**
 * @brief Shows/hides the loading screen.
 * @param bShow     TRUE to show the loading screen, FALSE to hide it
 * @param sProgress Additional text to show to indicate the progress (optional)
 */
void EB_showLoadingScreen(bool bShow, string sProgress = "")
{
  // Events can only be triggered for the own panel (including panelrefs)
  invokeMethod("appModule." + rootPanel("appModule") + ":", "showLoadingScreen", bShow, sProgress);
}

/**
 * @brief Sets a flag that the app has unsaved changes so that a window is shown.
 * @author Martin Schiefer
 * @param bValue true if app has unsaved changes (default: true)
 */
void EB_setUnsavedChanges(bool bValue = true)
{
  // Unsaved changes can only be set for the currently running package
  if (globalExists("g_spTileProject") && g_spTileProject != nullptr)
  {
    g_spTileProject.setUnsavedChanges(bValue);
  }

  // Events can only be triggered for the own panel (including panelrefs)
  // So call this main panel function, which triggers the actual event
  invokeMethod(EB_MODULE_APP + "." + rootPanel(EB_MODULE_APP) + ":", "setUnsavedChanges", bValue);
}

/**
 * @brief Returns if the app has unsaved changes.
 * @return TRUE -> app has unsaved changes
 */
bool EB_hasUnsavedChanges()
{
  // Can only have unsaved changes in a currently running package
  return globalExists("g_spTileProject") && g_spTileProject != nullptr && g_spTileProject.hasUnsavedChanges();
}

/**
 * @brief Checks if the current configuration 'screen' can be left.
 * @details In case if unsaved changes asks the user to discard them.
 * @details 'screen' could also be configuration from another object in the same panel.
 * @author Martin Schiefer
 * @param sCat Message catalog to use (default: "Configuration")
 * @param sKey Message to use (default: "UnsavedChangesText")
 * @return FALSE -> app has unsaved changes, TRUE -> safe to change 'screen'
 */
bool EB_checkUnsavedChanges(string sCat = "Configuration", string sKey = "UnsavedChangesText")
{
  if (EB_hasUnsavedChanges())
  {
    bool bOk = EB_openDialogQuestion(getCatStr(sCat, sKey), "yes", "no");

    if (bOk)
    {
      EB_setUnsavedChanges(FALSE);
    }
    return bOk;
  }

  return TRUE;
}

/**
  @brief Opens a fileSelector.
  @author Martin Schiefer
  @param sFileName The file.
  @param sFilterPattern The pattern for filter the dialog.
  @param sDirectory The starting directory for the dialog.
  @returns -1 on error otherwise 0
*/
int EB_fileSelector(string &sFileName, const string &sFilterPattern, const string &sDirectory)
{
  return fileSelector(sFileName, sDirectory, FALSE, sFilterPattern);
}

/**
  @brief Returns the langString with all langs for a given key in a given message cataloge.
  @author Martin Schiefer
  @param sCat The cataloge name.
  @param sKey The key in the cataloge.
  @returns The filled up langString
*/
langString EB_getLangStringFromCat(const string &sCat, const string &sKey)
{
  langString lsRetVal;
  for (int i = 0; i < getNoOfLangs(); i++)
  {
    setLangString(lsRetVal, i, getCatStr(sCat, sKey, i));
  }
  return lsRetVal;
}

/**
  @brief Sets the given text to the langtext.
  @author Martin Schiefer
  @details All langs are set to the given text.
  @param sText The text to set.
  @param lsText The langstring to set.
*/
void EB_setMultilingualText(string sText, langString &lsText)
{
  for (int i = 0; i < getNoOfLangs(); i++)
  {
    setLangString(lsText, i, sText);
  }
}

/**
  @brief Combine two lang strings
  @author Daniel Lomosits
  @param lsText1 The text to set.
  @param lsText2 The langstring to set.
  @return langString as combination of lsText1 + lsText2
*/
langString EB_addLangStrings(langString lsText1, langString lsText2)
{
  langString lsText;
  mapping mText;
  dyn_anytype daReturn = jsonDecode(jsonEncode(lsText1));
  mapping mText1 = daReturn[1];
  daReturn = jsonDecode(jsonEncode(lsText2));
  mapping mText2 = daReturn[1];
  for (int i = 0; i < getNoOfLangs(); i++)
  {
    mText[getLocale(i)] = mText1[getLocale(i)] + mText2[getLocale(i)];
  }
  return EB_mappingToLangString(mText);
}

/**
 * @brief Shows a popup with the contents of the specified help file.
 * @param sRelativePath Relative path of the help file.
 * @param sParameter    Parameter(s) of the help file.
 */
void EB_showWebHelp(const string &sRelativePath, const string &sParameter)
{
  // Also search this file in the fallback languages and open it with the relative path
  string sHelpFile = getPath(HELP_REL_PATH, sRelativePath);
  string sUrl      = getActiveHttpServerUrl() != "" ? getActiveHttpServerUrl() + "/" + EB_makePathRelative(sHelpFile) : "file:///" + sHelpFile;

  EB_openDialog(makeDynString("$Url:" + sUrl, "$param:" + sParameter), "EB_Package_Base/WebHelp.pnl", getCatStr("general", "help"), "", "close");
}

/**
  @brief Shows a popup with the contents of the specified help file.
  @param sRelativePath  The relative path of the help file.
*/
void EB_showHelp(const string &sRelativePath)
{
  // Also search this file in the fallback languages and open it with the relative path
  string sHelpFile = getPath(HELP_REL_PATH, sRelativePath);
  string sUrl      = getActiveHttpServerUrl() != "" ? getActiveHttpServerUrl() + "/" + EB_makePathRelative(sHelpFile) : "file:///" + sHelpFile;

  EB_openDialog(makeDynString("$Url:" + sUrl), "tools/Help", getCatStr("general", "help"), "", "close");
}
/**
  @brief Removes the project part of an absolute project path.
  @param absolutePath The absolute path to get a relative path from.
  @returns string The relative project path or original path if it is not located in a project path.
*/
string EB_makePathRelative(string absolutePath)
{
  string result = absolutePath;

  for (int i = 1; i <= SEARCH_PATH_LEN && result == absolutePath; i++)
  {
    strreplace(result, getPath("", "", getActiveLang(), i), "");
  }

  return result;
}

/**
  @brief Reads a csv file into a mapping.
  @details Reads in a flat tag structure from a given csv file and
  sets the values of the given dyn_mapping to the values of the file.
  each line represents one mapping of the dyn_mapping and is checked
  seperate. when one value of the line is not correct, the mapping is
  empty and the linenumber is added to the return value.
  @author Martin Schiefer
  @param sParentNode the nodeId of the parent node
  @param sFileName The csv file.
  @param dmData The dyn_mapping which is filled with the values.
  @returns dyn_int The lines which have errors.
*/
dyn_int EB_readFlatTagsFromCsv(string sParentNode, string sFileName, dyn_mapping &dmData)
{
  EBCsv csv;
  return csv.read(sParentNode, sFileName, dmData);
}

/**
  @brief Writes a flat tag structure as dyn_mapping to a given csv file.
  @author Martin Schiefer
  @param sFileName The csv file.
  @param dmData The dyn_mapping which is filled with the values.
  @return errCode
  \li 0 success
  \li -1 file does not exists
  \li -2 can nt open file in wb+ mode
  \li -3 content can not be writen to file
*/
int EB_writeFlatTagsToCsv(string sFileName, dyn_mapping dmData)
{
  EBCsv csv;
  return csv.write(sFileName, dmData);
}

/**
  @brief Reads a csv file into a mapping.
  @details Reads in a structure from a given csv file and
  sets the values of the given dyn_mapping to the values of the file.
  each line represents one mapping of the dyn_mapping and is checked
  seperate. when one value of the line is not correct, the mapping is
  empty and the linenumber is added to the return value.
  @author Martin Schiefer
  @param sParentNode the nodeId of the parent node
  @param sFileName The csv file.
  @param dmData The dyn_mapping which is filled with the values.
  @param spCsv The shared_ptr of the class with the checking functions.
  @returns dyn_int The lines which have errors.
*/
dyn_int EB_readDataFromCsv(string sParentNode, string sFileName, dyn_mapping &dmData, shared_ptr<EBCsv> spCsv)
{
  return spCsv.read(sParentNode, sFileName, dmData);
}

/**
  @brief opens file selector dialog with API function and return file information depending on selection
  @author Daniel Lomosits
  @param  sDownloadPath: The path where the selected file shall be saved. default = empty string
  @return Returning file name/path and file content
 */
public dyn_string EB_openFileSelectorDialog(string sDownloadPath = "")
{
  dyn_string dsResult;

  EB_openDialogRetVal(makeDynString(sDownloadPath), "vision/EB_FileSelectorDialog", getCatStr("EB_Package", "OfsSelectSource"), dsResult, "", "cancel");

  return dsResult;
}

/**
  @brief open file saving dialog with API function
  @author Daniel Lomosits
  @param sFileName: Optionally: The absolute path of the uploaded/saved file. If not given, FileSelectorDialog is used to select file.
  @param sFileContent Optionally: The content of the uploaded/saved file. If not given --> sFileName will be read out.
  @param bDelete Optionally: Boolean flag for delete after upload.
 */
public void EB_uploadFileToOFS(string sFileName = "", string sFileContent = "", bool bDelete = FALSE)
{
  // check given file parameters, if both equal to empty string, a file has to be selected before uploading/saving
  if (sFileName == "" && sFileContent == "")
  {
    // open file selector if function is called with default parameter
    dyn_string dsReturnValues = EB_openFileSelectorDialog();

    // overwrite default strings for file name and file content
    if (dynlen(dsReturnValues) > 0)
    {
      sFileName = dynlen(dsReturnValues) >= 1 ? dsReturnValues[1] : "";
      sFileContent = dynlen(dsReturnValues) >= 2 ? dsReturnValues[2] : "";
    }
    else
    {
      return;
    }

    // check if file name doesn't equal to empty string
    if (sFileName != "")
    {
      bDelete = TRUE;
    }
  }
  // Check if the file needs to be read
  else if (sFileContent == "" && access(sFileName, R_OK) == 0)
  {
    fileToString(sFileName, sFileContent);
  }

  dyn_string dsReturnValues;

  // open file saving dialog depending on file name and file content
  int iReturnCode = EB_openDialogRetVal(makeDynString(sFileName, sFileContent, bDelete), "vision/EB_FileSavingDialog", getCatStr("EB_Package", "OfsSelectDirectory"), dsReturnValues, "", "cancel");

  // check boolean delete flag
  if (bDelete && (iReturnCode == 0 || (dynlen(dsReturnValues) > 0 && dsReturnValues[1] != sFileName)))
  {
    // delete file
    remove(sFileName);
  }
}

/**
  @brief  replaces unallowed chars of given lists in string variable
  @author Daniel Lomosits
  @param  sText: The original string variable.
  @param  dsSearch: The list of unallowed chars.
  @param  dsReplace: The list of replacing chars.
 */
public void EB_replaceUnallowedChars(string &sText, const dyn_string &dsSearch, const dyn_string &dsReplace)
{
  if (dynlen(dsSearch) != dynlen(dsReplace))
  {
    return;
  }

  for (int i = 1; i <= dynlen(dsSearch); i++)
  {
    strreplace(sText, dsSearch[i], dsReplace[i]);
  }
}

/**
  @brief  get data directory by app and create if it doesn't exist
  @author Daniel Lomosits
  @param  sAppName The given App name e.g. "S7", "OPCUA". Default = data dir
  @return The absolute path to data directory of given app.
 */
public string EB_getDataDirectory(string sAppName = "")
{
  // check if app name equals to default or not
  if (sAppName != "")
  {
    sAppName = "EB_Package_" + sAppName + "/";
  }

  // try to sync import file, if file exist
  string sSyncPath = getPath(DATA_REL_PATH, sAppName + "empty.txt");

  // check if give sync path doesn't equal to empty string, in case of success: return sync path
  if (sSyncPath != "")
  {
    strreplace(sSyncPath, "empty.txt", "");
    return sSyncPath;
  }

  // get data relative path
  string sDirectory = getPath(DATA_REL_PATH);

  // try to access data folder of given app
  int iRet = access(sDirectory + sAppName, F_OK);

  // check if data folder of given app exists
  if (iRet != 0)
  {
    // create data folder of given app and set directory string
    mkdir(sDirectory + sAppName, "777");
  }

  sDirectory = getPath(DATA_REL_PATH, sAppName);

  return sDirectory;
}

/**
  @brief  get a temporary filename based on specific app and current time stamp
  @author Daniel Lomosits
  @param  sAppname: The given App name e.g. "S7", "OPCUA".
  @param  sFileextension: The file extension e.g. ".txt", ".csv". Default: ".txt".
  @return The temporary file name.
 */
public string EB_getTemporaryFilenameByApp(string sAppname, string sFileextension = ".txt")
{
  // define, declare and initialize file name string ase on current time stamp
  string sFilename = (string)getCurrentTime();

  // replace unallowed chars of filename
  EB_replaceUnallowedChars(sFilename, makeDynString(".", ":", " "), makeDynString("", "-", "_"));

  // define, declare and initialize filepath string
  string sFilepath = EB_getDataDirectory(sAppname);

  // create path of export file
  string sExportFile = sFilepath + sAppname + "_Tags_" + sFilename;

  // if file extension is not part of the string add it
  if (strpos(sExportFile, sFileextension) == -1)
  {
    sExportFile = sExportFile + sFileextension;
  }

  return sExportFile;
}

/**
  @brief Checks if the string contains other chars than allowed.
  @author Daniel Lomosits
  @param sAllowedChars The list holding all allowed chars.
  @param sText The string which should be checked.
  @return bool True if the string contains unallowed chars.
 */
public bool EB_unallowedCharInString(string sAllowedChars, string sText)
{
  // iterate over all chars of given text
  for (int i = 0; i < strlen(sText); ++i)
  {
    // check if there are unallowed chars in given string
    if (strpos(sAllowedChars, sText[i]) == -1)
    {
      return TRUE; //unallowed char in string
    }
  }

  return FALSE;
}

/**
  @brief Checks if the string contains other chars than allowed.
  @author Daniel Lomosits
  @param sUnallowedChars The list holding all unallowed chars.
  @param sText The string which should be checked.
  @return bool True if the string contains unallowed chars.
 */
public bool EB_charInString(string sUnallowedChars, string sText)
{
  // iterate over all chars of given text
  for (int i = 0; i < strlen(sText); ++i)
  {
    // check if there are unallowed chars in given string
    if (strpos(sUnallowedChars, sText[i]) >= 0)
    {
      return TRUE; //unallowed char in string
    }
  }

  return FALSE;
}

/**
  @brief (Un)locks an app for configuration.
  @param sName The package to (un)lock
  @param bLock TRUE -> lock, FALSE -> unlock
  @return TRUE -> lock has been set, FALSE -> failed to acquire lock
 */
public bool EB_lockApp(const string &sName, bool bLock)
{
  bool bResult = FALSE;
  uint uByManager;

  if (EB_isAppLocked(sName, uByManager) != bLock)
  {
    if (uByManager == 0 || uByManager == myManNum())//only the origin manager can lock/unlock app
    {
      dpSetWait("EB_Package_" + sName + ".:_lock._common._locked", bLock);
      dyn_errClass deErrors = getLastError();
      bResult = dynlen(deErrors) == 0;
    }
  }

  return bResult;
}

/**
 * @brief Checks if the specified app is locked for configuration
 * @param sName         Package to check
 * @param uByManager    Manager number holding the lock
 * @return TRUE -> app configuration is locked
 */
public bool EB_isAppLocked(const string &sName, uint &uByManager)
{
  bool bResult;

  // Do not try to read if a non-existing datapoint is locked
  if (dpExists("EB_Package_" + sName + "."))
  {
    dpGet("EB_Package_" + sName + ".:_lock._common._locked", bResult,
          "EB_Package_" + sName + ".:_lock._common._man_nr", uByManager);
  }

  DebugFN("LOCK_APP", __FUNCTION__ + "(" + sName + ") Returning: " + bResult);

  return bResult;
}

/**
  @brief Connects the specified app locked configuration state
  @param aCallback Callback function to call (function_ptr or string)
  @param sName     The package of to which state to connect to
  @return TRUE -> connect succeeded
 */
public bool EB_LockAppConnect(anytype aCallback, const string &sName)
{
  return dpConnect(aCallback, "EB_Package_" + sName + ".:_lock._common._locked") == 0;
}

/**
  @brief Returns the locked error text for the specified app
  @param sName     The package to get the error text for
  @return Empty in case the app is not locked, otherwise an error text
 */
public string EB_getLockedAppText(const string &sName)
{
  string sResult;

  bool bLocked;
  int  iManId;
  uint uUserId;
  dyn_int    diManNums;
  dyn_string dsHosts;

  // Retrieve the needed information for the message
  dpGet("EB_Package_" + sName + ".:_lock._common._locked",  bLocked,
        "EB_Package_" + sName + ".:_lock._common._man_id",  iManId,
        "EB_Package_" + sName + ".:_lock._common._user_id", uUserId,
        "_Connections.Ui.ManNums",         diManNums,
        "_Connections.Ui.HostNames",       dsHosts);

  // Check if the package is actually (still) locked
  if (bLocked)
  {
    sResult = getCatStr("EB_Package_Base", "AppLockedErrorText");

    char   cManType;
    char   cManNum;
    int    iSysNum;
    string sHost = "?"; // In case the actual could not be determined
    string sUser = "?"; // In case the actual could not be determined

    getManIdFromInt(iManId, cManType, cManNum, iSysNum);

    // Only local UIs should be able to lock a package,
    // but just check to make sure this is the case
    if (iSysNum == getSystemId() && cManType == UI_MAN)
    {
      // Figure out the host name of the manager holding the lock
      int iIndex = dynContains(diManNums, cManNum);

      if (iIndex > 0)
      {
        sHost = dsHosts[iIndex];
      }

      // Simply convert the user id to a name
      sUser = getUserName(uUserId);
    }

    // Replace the place holders with values
    strreplace(sResult, "$host", sHost);
    strreplace(sResult, "$user", sUser);
  }

  return sResult;
}

/**
 * @brief Performs a name check and shows a popup if the check fails or close the panel
 * and return a dynfloat with one and a dynstring with the name.
 * @author Martin Schiefer
 * @param sText The name to check.
 * @param dsExistingNames The dynstring with used names.
 * @param sParentNodeId The id of the parent tag.
 * @param ebNodeType The tag node type of the name.
 * @param dfRet The dynfloat to return.
 * @param dsRet The dynstring to return extended with the name.
 */
void EB_checkNameAndReturn(string sText, dyn_string dsExistingNames = makeDynString(),
                           string sParentNodeId = "", EBNodeType ebNodeType = EBNodeType::DP,
                           dyn_float dfRet = makeDynFloat(1), dyn_string dsRet = makeDynString())
{
  throwError(makeError("", PRIO_WARNING, ERR_IMPL, 54, "This function is deprecated", "Use 'EB_checkNameWithPopup' and 'EB_closeDialog' functions"));

  if (EB_checkNameWithPopup(sText, dsExistingNames, sParentNodeId , ebNodeType))
  {
    dynAppend(dsRet, sText);
    PanelOffReturn(dfRet, dsRet);
  }
}

/**
 * @brief Performs a name check and return false
 * @author Daniel Lomosits
 * @param sText The name to check.
 * @param dsExistingNames The dynstring with used names.
 * @param sParentNodeId The id of the parent tag.
 * @param ebNodeType The tag node type of the name.
 * @return bool True if the name is ok.
 */
bool EB_checkName(const string &sText, dyn_string dsExistingNames = makeDynString(),
                  string sParentNodeId = "", EBNodeType ebNodeType = EBNodeType::DP)
{
  string sMessage;

  if (sText == "")
  {
    sMessage = getCatStr("EB_Package", "nameEmpty");
  }
  else if (EB_tagNameHasUnallowedCharacters(sText))
  {
    sMessage = getCatStr("EB_Package", "nameNotAllowed");
  }
  else if (dynContains(dsExistingNames, sText) > 0)
  {
    sMessage = getCatStr("EB_Package", "nameUsed");
  }
  else if (!EB_isTagNameValid(sText, sParentNodeId, ebNodeType))
  {
    sMessage = getCatStr("EB_Package", "nameUsed");
  }

  return sMessage == "";
}

/**
 * @brief Performs a name check and shows a popup if the check fails and return false
 * and return a dynfloat with one and a dynstring with the name.
 * @author Martin Schiefer
 * @param sText The name to check.
 * @param dsExistingNames The dynstring with used names.
 * @param sParentNodeId The id of the parent tag.
 * @param ebNodeType The tag node type of the name.
 * @return bool True if the name is ok.
 */
bool EB_checkNameWithPopup(const string &sText, dyn_string dsExistingNames = makeDynString(),
                           string sParentNodeId = "", EBNodeType ebNodeType = EBNodeType::DP)
{
  string sMessage;

  if (sText == "")
  {
    sMessage = getCatStr("EB_Package", "nameEmpty");
  }
  else if (EB_tagNameHasUnallowedCharacters(sText))
  {
    sMessage = getCatStr("EB_Package", "nameNotAllowed");
  }
  else if (dynContains(dsExistingNames, sText) > 0)
  {
    sMessage = getCatStr("EB_Package", "nameUsed");
  }
  else if (!EB_isTagNameValid(sText, sParentNodeId, ebNodeType))
  {
    sMessage = getCatStr("EB_Package", "nameUsed");
  }

  if (sMessage != "")
  {
    EB_openDialogWarning(sMessage);
  }

  return sMessage == "";
}

/**
 * @brief Converts the content of a tree shape into JSON format
 * @author Daniel Lomosits
 * @param shTree The tree shape to convert.
 * @param diColumns The columns which should be added to JSON structure (are added with prefix "col").
 * @param bSelected Defines if state of the item in the tree should also be added (TRUE) or not (FALSE; default).
 * @return string The converted JSON string.
 */
string EB_convertTreeToJson(shape shTree, dyn_int diColumns, bool bSelected = FALSE)
{
  mapping mTree = shTree.getItemsCheckState(TREE_LEAVES|TREE_NODES);

  dyn_string dsIds = mappingKeys(mTree);

  mapping mBuff;
  dyn_mapping dmTree;
  for (int i = 1; i <= dynlen(dsIds); i++)
  {
    mappingClear(mBuff);

    mBuff["id"] = dsIds[i];

    for (int j = 1; j <= dynlen(diColumns); j++)
    {
      mBuff["col" + (string)j] = shTree.getText(dsIds[i], diColumns[j]);
    }

    if (bSelected)
    {
      int iSelected = shTree.getCheckState(dsIds[i]);
      mBuff["selected"] = iSelected;
    }

    dynAppend(dmTree, mBuff);
  }

  return jsonEncode(dmTree);
}

/**
 * @brief Get colored bar as svg image (temporary svg file will be created - containing RGB filled rectangle)
 * @param sColorName    colors name
 * @return file name of the svg file
 */
public string EB_getColorRectangleSvg(const string &sColorName)
{
  int r, g, b, a;
  colorToRgb(sColorName, r, g, b, a);
  //for each color, a svg with the rgb code will be generated
  string sFileName = sTmpColorRectangleFilePrefix + r + "_" + b + "_" + g + sTmpColorRectangleFileExtension;

  //file does not exist
  if (getPath(PICTURES_REL_PATH, sFileName) ==  "")
  {
    //create file by reading template, replacing color and saving the new file
    if (sSvgTemplate == "")
    {
      //read template
      fileToString(getPath(PICTURES_REL_PATH, sTmpColorRectangleFilePrefix + "template" + sTmpColorRectangleFileExtension), sSvgTemplate);
    }
    string sNewFileContent = sSvgTemplate;

    // %COLOR%
    strreplace(sNewFileContent, "%COLOR%", "rgb("+r+","+g+","+b+")");

    // Make sure the directory exists before creating the file
    if (!isdir(dirName(PICTURES_REL_PATH + sFileName)))
    {
      mkdir(dirName(PICTURES_REL_PATH + sFileName));
    }

    file fNew = fopen(PICTURES_REL_PATH + sFileName, "w+");
    fputs(sNewFileContent, fNew);
    fclose(fNew);
  }
  //file exists -> OK
  return sFileName;
}

/**
 * @brief Returns the text of the last error
 * @details It removes the panel information from the location part
 * @param deErrors      List of errors
 * @param iLineOffset   Value for line number correction
 * @return error info as string
 */
string EB_getErrorInfo(const dyn_errClass &deErrors, int iLineOffset = 0)
{
  if (dynlen(deErrors) <= 0)
  {
    return "";
  }

  const string LOCATION = "Line: ";
  string sErrorText = getErrorText(deErrors);
  string sErrorLocation;

  // Remove the possible 'Unexpected state,' part
  if (getErrorCode(deErrors) == 54)
  {
    sErrorText = uniSubStr(sErrorText, uniStrLen(getCatStr("_errors", "00054", getLangIdx("en_US.utf8"))) + 1); // Error texts are always English
  }

  int iIndex = strpos(sErrorText, LOCATION);

  // Remove the part before 'Line:' (in which panel/library it occurred)
  if (iIndex > 0)
  {
    sErrorLocation = substr(sErrorText, iIndex);

    if (iLineOffset != 0)
    {
      dyn_string dsCaptures;

      regexpSplit(LOCATION + "(\\d+)", sErrorLocation, dsCaptures, makeMapping("minimal", FALSE));

      if (dynlen(dsCaptures) >= 2)
      {
        // The value could be multiple times in the text,
        // so make sure to only replace the line number
        strreplace(sErrorLocation, dsCaptures[1], LOCATION + ((int)dsCaptures[2] - iLineOffset));
      }
    }
  }

  iIndex = strpos(sErrorText, ",");

  // Extract the error text
  if (iIndex > 0)
  {
    sErrorText = substr(sErrorText, 0, iIndex);
  }

  sErrorText = strltrim(strrtrim(sErrorText));

  // Recombine the error with the location (without module/panel/object/script)
  if (sErrorLocation != "")
  {
    sErrorText += ", " + sErrorLocation;
  }

  return sErrorText;
}

/**
 * @brief Returns the result whether file saving is possible or not
 * @author Daniel Lomosits
 * @return TRUE = file saving possible, FALSE = file saving not possible
 */
bool EB_isFileSavingPossible()
{
  // get OPA connection state from DPE and save it on variable
  int iOpaConnectionState = 0;
  dpGet("MyBox.UpdateCenter.State", iOpaConnectionState);

  return ((!isUltralight() || iOpaConnectionState == 1) && !isMobileDevice());
}

/**
 * @brief Returns the result whether the url is reachable
 * @param sUrl          URL to check
 * @param bShowWaiting  TRUE if the wait indicator should be shown during the test
 * @param iTimeOut      Maximum time to check reachability
 * @return TRUE = url is reachable, FALSE = url is not reachable
 */
bool EB_isUrlReachable(const string &sUrl, bool bShowWaiting = FALSE, int iTimeOut = 10)
{
  dyn_string dsUrlParts = strsplit(sUrl, ":");
  dyn_string dsAllowedUrlBeginnings = makeDynString("http", "https", "ftp", "file");
  if (dynlen(dsUrlParts) <= 1 || dynContains(dsAllowedUrlBeginnings, dsUrlParts[1]) <= 0)
  {
    return FALSE;
  }
  string sResult;
  mapping mOptions;
  mOptions["ignoreSslErrors"] = "";  //All SSL errors are ignored
  mOptions["timeout"] = iTimeOut;
  if (bShowWaiting)
  {
    EB_showLoadingScreen(TRUE);
  }
  int iErrStat = netGet(sUrl, sResult, mOptions);
  if (bShowWaiting)
  {
    EB_showLoadingScreen(FALSE);
  }
  return iErrStat == 0;
}

/**
 * @brief Returns the enum key for an given enum value
 * @author Markus Trummer
 * @param enumVar the enum value for searching its key
 * @return the enum key for the given enum value
 */
string EB_enumGetKey(const anytype &enumVar)
{
  mapping mEnum = enumValues(getTypeName(enumVar));
  for (int i=mappinglen(mEnum); i > 0; i--)
  {
    if (mappingGetValue(mEnum, i) == (int)enumVar)
      return mappingGetKey(mEnum, i);
  }
  return "";
}

/**
 * @brief get enum with specific value for given enum key
 * @author Markus Trummer
 * @param sEnumKey the selected enum key
 * @param enumVar the enum instance to be set
 */
void EB_enumGetValue(string sEnumKey, anytype &enumVar)
{
  if (sEnumKey != "")
  {
    mapping mEnum = enumValues(getTypeName(enumVar));

    if(!mappingHasKey(mEnum, sEnumKey))
    {
      sEnumKey = strtoupper(sEnumKey);
    }
    int iVal = mEnum[sEnumKey];

    enumVar = iVal;
  }
}


string EB_getEnumTextForValue(const string &sEnumType, const int &iValue)
{
  mapping mEnum = enumValues(sEnumType);
  int iLen = mappinglen(mEnum);

  for (int i=mappinglen(mEnum); i>0; i--)
  {
    if(mappingGetValue(mEnum, i)==iValue)
    {
      return mappingGetKey(mEnum, i);
    }
  }

  return iValue;
}

int EB_getEnumValueForText(const string &sEnumType, const string &sKey)
{
  mapping mEnum = enumValues(sEnumType);
  if (mappingHasKey(mEnum, sKey))
    return mEnum[sKey];
  else
    return -1;
}
