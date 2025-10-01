// $License: NOLICENSE

/**
 * @file scripts/libs/EB_Package_Base/EB_Api_TagHandling.ctl
 * @brief Contains the API functions for Tags.
 */

// used libraries (#uses)
#uses "cns"
#uses "CtrlCNS"
#uses "classes/EBlog"
#uses "EB_Package_Base/EB_const"
#uses "classes/EBCsv"
#uses "classes/EBTag"
#uses "classes/SymbolPreLoader"

/**
 * @brief Set the tile type of a tag
 * @param sNodeId  Tag id
 * @param sType    Value to set
 */
public void EB_setTileType(const string &sNodeId, const string &sType)
{
  cnsSetProperty(sNodeId, "tileType", sType);
}

/**
 * @brief Returns the tile type of a tag
 * @param sNodeId  Tag id
 * @return Tile type of the specified tag
 */
public string EB_getTileType(const string &sNodeId)
{
  string sType;
  cnsGetProperty(sNodeId, "tileType", sType);
  return sType;
}

/**
 * @brief Set the tile dpe of a tag
 * @param sNodeId  Tag id
 * @param sDpe     Value to set
 */
public void EB_setTileDp(const string &sNodeId, const string &sDpe)
{
  cnsSetProperty(sNodeId, "tileDp", sDpe);
}

/**
 * @brief Returns the tile dpe of a tag
 * @param sNodeId  Tag id
 * @return Tile dpe of the specified tag
 */
public string EB_getTileDp(const string &sNodeId)
{
  string sDp;
  cnsGetProperty(sNodeId, "tileDp", sDp);
  return sDp;
}

/**
 * @brief gets the list of supported tag types.
 * @author Martin Schiefer
 * @return dyn_string the list.
 */
public dyn_string EB_getTagTypes()
{
  return makeDynString("FALSE", "bool", "int", "uint", "float", "string", "time");
}

/**
 * @brief gets the list of supported tag units.
 * @author Martin Schiefer
 * @return dyn_string the list.
 */
public dyn_string EB_getTagUnits()
{
  return makeDynString("FALSE", "", "m", "kg", "oC", "m/s", "1/s");
}

/**
 * @brief gets the list of supported tag rates.
 * @author Martin Schiefer
 * @return dyn_string the list.
 */
public dyn_string EB_getTagRates()
{
  return makeDynString("FALSE", "100ms", "1s", "5s");
}

/**
 * @brief sets a value of an tag.
 * @author Martin Schiefer
 * @param sNodeId The tag id.
 * @param aValue value to set.
 * @return int 0, in the event of a failure returns -1.
 */
public bool EB_setTag(string sNodeId, anytype aValue)
{
  return EBTag::setTagValue(sNodeId, aValue);
}

/**
 * @brief sets a tag active or deactivates it.
 * @author Daniel Lomosits
 * @param sNodeId The tag id.
 * @param bValue value to set (active or not).
 * @return int 0, in the event of a failure returns -1.
 */
public bool EB_setTagActive(string sNodeId, bool bValue)
{
  return EBTag::setTagValueActive(sNodeId, bValue);
}

/**
 * @brief sets a value of an tag and waits for the answer from the eventmanager.
 * @author Martin Schiefer
 * @param sNodeId The tag id.
 * @param aValue value to set.
 * @return int 0, in the event of a failure returns -1.
 */
public int EB_setTagValueAndWait(string sNodeId, anytype aValue)
{
  return EBTag::setTagValueAndWait(sNodeId, aValue);
}

/**
 * @brief sets a value of an tag to a specific point in time.
 * @author Martin Schiefer
 * @param tSource The source time.
 * @param sNodeId The tag id.
 * @param aValue value to set.
 * @return int 0, in the event of a failure returns -1.
 */
public int EB_setTagValueTimed(time tSource, string sNodeId, anytype aValue)
{
  return EBTag::setTagValueTimed(tSource, sNodeId, aValue);
}

/**
 * @brief sets a value of an tag to a specific point in time and waits for the answer from the eventmanager.
 * @author Martin Schiefer
 * @param tSource The source time.
 * @param sNodeId The tag id.
 * @param aValue value to set.
 * @return int 0, in the event of a failure returns -1.
 */
public int EB_setTagValueTimedAndWait(time tSource, string sNodeId, anytype aValue)
{
  return EBTag::setTagValueTimedAndWait(tSource, sNodeId, aValue);
}

/**
 * @brief gets the value of an tag.
 * @author Martin Schiefer
 * @param sNodeId The tag id.
 * @return mixed
Key  | Value
------------- | -------------
[EBTag::MAPPING_VAL]  | Value of the tag
[EBTag::MAPPING_FLAG] | FALSE if value of the tag is valid
[EBTag::MAPPING_NAME] | Name of the tag
 */
public mixed EB_getTag(string sNodeId)
{
  return EBTag::getTagValue(sNodeId);
}

/**
 * @brief connects a function to the value change of an tag.
 * @author Martin Schiefer
 * @param fpCallBack The function pointer to the function which should be called.
 * @param dsNodeIds The dyn_string containing the tag ids.
 * @param aUserData User-defined data which is passed as parameter to the callback function.
 * @param bFirst Specifies if the callback function should be executed the first time already when the dpConnect() is called or first every time a value changes.
 * @return int 0, in the event of a failure returns -1.
 */
public int EB_connectTag(function_ptr fpCallBack, dyn_string dsNodeIds, anytype aUserData = "", bool bFirst = TRUE)
{
  return EBTag::connectTag(fpCallBack, dsNodeIds, aUserData, bFirst);
}

/**
 * @brief connects a function to the value change of an tag.
 * @author Martin Schiefer
 * @param fpCallBack The function pointer to the function which should be called.
 * @param dsNodeIds The dyn_string containing the tag ids.
 * @param aUserData User-defined data which is passed as parameter to the callback function.
 * @return int 0, in the event of a failure returns -1.
 */
public int EB_disconnectTag(function_ptr fpCallBack, dyn_string dsNodeIds, anytype aUserData = "")
{
  return EBTag::disconnectTag(fpCallBack, dsNodeIds, aUserData);
}

/**
 * @brief Sets the description for the given tag id
 * @param sNodeId: The tag id where the unit will be set
 * @param lsComment: The description in one or several languages
 * @return 0 in case of success, otherwise -1
 */
public int EB_setDescriptionForTag(const string &sNodeId, const langString &lsComment)
{
  return EBTag::setTagDescription(sNodeId, lsComment);
}

/**
  @brief Gets the description of a given Tagid.
  @author Martin Schiefer
  @param sTagId The TagId.
  @param bMultiLang FALSE to get a string with description in current language, TRUE to get a langString
  @returns string The description in the current language.
*/
anytype EB_getTagDescription(string sTagId, bool bMultiLang = FALSE)
{
  return EBTag::getTagDescription(sTagId, bMultiLang);
}

/**
 * @brief Sets the unit for the given tag id
 * @param sNodeId: The tag id where the unit will be set
 * @param lsUnit: The unit in one or several languages
 * @return 0 in case of success, otherwise -1
 */
public bool EB_setUnitForTag(const string &sNodeId, const langString &lsUnit)
{
  return EBTag::setTagUnit(sNodeId, lsUnit);
}

/**
  @brief Gets the unit of a given Tagid.
  @author Daniel Lomosits
  @param sTagId The TagId.
  @returns string The unit as lang string.
*/
langString EB_getTagUnit(string sTagId)
{
  return EBTag::getTagUnit(sTagId);
}

/**
 * @brief Sets the format string for the given tag id
 * @param sNodeId The tag id where the unit will be set
 * @param sFormat The format string
 * @return 0 in case of success, otherwise -1
 */
public int EB_setFormatForTag(const string &sNodeId, const string &sFormat)
{
  return EBTag::setTagFormat(sNodeId, sFormat);
}

/**
  gets the format string for the given tag id
  @author Martin Schiefer
  @param sNodeId: The tag id where the unit will be set
  @return langString: The format string
*/
public langString EB_getFormatForTag(const string &sNodeId)
{
  return EBTag::getTagFormat(sNodeId);
}



/**
 * @brief Sets the tag address active/inactive
 * @param sNodeId  The tag id where the configs will be set
 * @param bActive  If the address is active or not
 * @return 0 in case of success, otherwise -1
 */
public int EB_setActiveForTag(const string &sNodeId, bool bActive)
{
  return EBTag::setTagActive(sNodeId, bActive);
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
public int EB_createAddressForTag(const string &sNodeId, int iDrvNr, const string &sDrvIdent,
                                  const string &sRef, const string &sPollGroup,
                                  int iTrans, bool bActive = TRUE, int iDirection = DPATTR_ADDR_MODE_INPUT_POLL,
                                  string sDeviceId = "", uint uSubindex = 0u, bool bLowLevelFilter = TRUE)
{
  int iErr;

  // retry create address multiple times (temporary)
  for(int i = 0; i < 30; i++)
  {
    iErr = EBTag::createTagAddress(sNodeId, iDrvNr, sDrvIdent, sRef, sPollGroup,
                                   iTrans, bActive, iDirection, sDeviceId, uSubindex, bLowLevelFilter);
    if(iErr == 0)
    {
      return 0;
    }

    delay(1);
  }

  return iErr;
}

/**
  gets the reference string for the given tag id
  @author Martin Schiefer
  @param sNodeId: The tag id
  @returns string The reference string
*/
public string EB_getReferenceStringFromTag(const string &sNodeId)
{
  return EBTag::getReferenceString(sNodeId);
}

/**
  checks the address by making a single query for the given tag id
  @author Martin Schiefer
  @param sNodeId: The tag id where the configs will be set
  @param iDrvNr: The driver number
  @param iTimeOut: The timeout to wait fo answer
  @return true if query was successful
*/
public bool EB_checkAddressForTag(const string &sNodeId, int iDrvNr, int iTimeOut = 2)
{
  return EBTag::makeSingleQueryTagAddress(sNodeId, iDrvNr, iTimeOut);
}

/**
  checks the address by making a single query for the given tag id
  @author Martin Schiefer
  @param sNodeId: The tag id where the configs will be set
  @param iDrvNr: The driver number
  @param iTimeOut: The timeout to wait fo answer
  @return true if query was successful
*/
public bool EB_makeSingleQueryForTag(const string &sNodeId, int iDrvNr, int iTimeOut = 2)
{
  return EBTag::makeSingleQueryTagAddress(sNodeId, iDrvNr, iTimeOut);
}

/**
  starts a single query for the given tag id
  @author Martin Schiefer
  @param sNodeId: The tag id where the configs will be set
  @param iDrvNr: The driver number
*/
public void EB_startSingleQueryForTag(const string &sNodeId, int iDrvNr)
{
  EBTag::startSingleQueryTagAddress(sNodeId, iDrvNr);
}

/**
  creates a pv_range config for the given tag id
  @author Martin Schiefer
  @param sNodeId: The tag id where the config will be set
  @param fMin: Lower limit of the range
  @param fMax: Upper limit of the range
  @return 0 when it was successfully executed and in the event of a failure -1
*/
public int EB_createRangeForTag(const string &sNodeId, float fMin, float fMax)
{
  return EBTag::createTagRange(sNodeId, fMin, fMax);
}

/**
  creates an archive config for the given tag id
  @author Martin Schiefer
  @param sNodeId        The tag id where the config will be set
  @param sRefreshRate   The refreshrate of the tag, in accordance to this rate, the archive group is selected
  @param bActive        TRUE -> Enable archiving
  @return 0 when it was successfully executed and in the event of a failure -1
*/
public int EB_createArchiveForTag(const string &sNodeId, const string &sRefreshRate, bool bActive = TRUE)
{
  return EBTag::createTagArchive(sNodeId, sRefreshRate, bActive);
}

/**
  sets an archive config for the given tag id
  @author Martin Schiefer
  @param sNodeId        The tag id where the config will be set
  @param sRefreshRate   The refreshrate of the tag, in accordance to this rate, the archive group is selected
  @param bActive        TRUE -> Enable archiving
  @return 0 when it was successfully executed and in the event of a failure -1
*/
public int EB_setArchiveConfigForTag(const string &sNodeId, const string &sRefreshRate, bool bActive = TRUE)
{
  return EBTag::createTagArchive(sNodeId, sRefreshRate, bActive);
}

/**
  sets or remove an smothing config for the given tag id - if absolute and relative smoothing values are 0.0, the config will be removed
  @author Markus Trummer
  @param sNodeId              The tag id where the config will be set
  @param fSmoothingAbsolute   The ablolute smoothing value
  @param fSmoothingRelative   The relative smoothing value
  @return 0 when it was successfully executed and in the event of a failure -1
*/
public int EB_setSmoothingConfigForTag(const string &sNodeId, float fSmoothingAbsolute = 0.0, float fSmoothingRelative = 0.0)
{
  return EBTag::createSmoothingConfig(sNodeId, fSmoothingAbsolute, fSmoothingRelative);
}

/**
  @brief Checks if a given tagname is available.
  @author Martin Schiefer
  @param sTagName The tagname.
  @returns true if tagname is available
*/
bool EB_canCreateTag(string sTagName)
{
  string sNewTagName = sTagName;
  if (nameCheck(sNewTagName, 1) == 0)
  {
    return (!dpExists(sTagName));
  }
  else
  {
    return false;
  }
}

/**
  @brief Creates a root node element for a given app.
  @author Martin Schiefer
  @param sAppPath The name of the app.
  @param lsViewName The displayname of the app.
  @return string The id of the generated element.
*/
string EB_createView(string sAppPath, langString lsViewName = "")
{
  return EBTag::createView(sAppPath, lsViewName);
}

/**
  @brief Gets the viewname for a app.
  @author Martin Schiefer
  @param sAppPath The name of the app.
  @return string The viewname.
*/
string EB_getViewName(string sAppPath)
{
  return EBTag::getViewName(sAppPath);
}

/**
  @brief Creates a tag.
  @author Martin Schiefer
  @param sParentNodeId The id of the parent node.
  @param lsTagDisplayName The displayname of the tag.
  @param nodeType The type of node.
  @param tagType The type of tag.
  @param sMappedNodeId The id of the node to link.
  @param bAllowDuplicateTagNames flag to ignore name check of duplicate tags (so per device similar tag names are allowed)
  @return string The id of the generated tag.
*/
string EB_createTag(string sParentNodeId, langString lsTagDisplayName,
                    EBNodeType nodeType = EBNodeType::STRUCT,
                    EBTagType tagType = EBTagType::INT,
                    string sMappedNodeId = "",
                    bool bAllowDuplicateTagNames = FALSE)
{
  return EBTag::create(sParentNodeId, lsTagDisplayName, nodeType, tagType, sMappedNodeId, bAllowDuplicateTagNames);
}

/**
  @brief Creates a tag with a given nodeId.
  @author Martin Schiefer
  @param sParentNodeId The id of the parent node.
  @param sNodeId The given nodeId.
  @param lsTagDisplayName The displayname of the tag.
  @param nodeType The type of node.
  @param tagType The type of tag.
  @param sMappedNodeId The id of the node to link.
  @param bForceCreate When MAPPED && true a dp will be created.
  @return string The id of the generated tag.
*/
string EB_createTagWithNodeId(string sParentNodeId, string sNodeId,
                              langString lsTagDisplayName,
                              EBNodeType nodeType = EBNodeType::STRUCT,
                              EBTagType tagType = EBTagType::INT,
                              string sMappedNodeId = "",
                              bool bForceCreate = FALSE)
{
  return EBTag::createWithNodeId(sParentNodeId, sNodeId, lsTagDisplayName, nodeType, tagType, sMappedNodeId, bForceCreate);
}

/**
  @brief Changes the datapoint for a given nodeId.
  @author Martin Schiefer
  @param sNodeId The given nodeId.
  @param sDpe The datapoint.
  @param nodeType The nodeType.
  @return bool True if the set was ok.
*/
bool EB_changeTagLink(string sNodeId, string sDpe, EBNodeType nodeType = EBNodeType::DP)
{
  return EBTag::setDpForId(sNodeId, sDpe, nodeType);
}

/**
  @brief Deletes a tag and all children of the tag.
  @author Martin Schiefer
  @param sNodeId The id of the tag.
*/
void EB_deleteTagAndChildren(string sNodeId)
{
  dyn_string dsChildren = EB_getChildrenOfTag(sNodeId);
  for (int i = 1; i <= dynlen(dsChildren); i++)
  {
    EB_deleteTagAndChildren(dsChildren[i]);
  }
  EB_deleteTag(sNodeId);
}

/**
  @brief Deletes a tag.
  @author Martin Schiefer
  @param sNodeId The id of the tag.
  @return true if the deletion was ok.
*/
bool EB_deleteTag(string sNodeId)
{
  return EBTag::del(sNodeId);
}

/**
  @brief Changes the name of a tag.
  @author Martin Schiefer
  @param sNodeId The id of the tag.
  @param sTagDisplayName The displayname name.
  @param iLangNumber The languagenumber.
  @return true if the changing was ok.
*/
bool EB_changeTagName(string sNodeId, string sTagDisplayName, int iLangNumber = getActiveLang())
{
  return EBTag::changeName(sNodeId, sTagDisplayName, iLangNumber);
}

/**
  @brief Changes the names of a tag.
  @author Martin Schiefer
  @param sNodeId The id of the tag.
  @param lsTagDisplayName The displayname names.
  @param bAllowDuplicateTagNames flag to ignore name check of duplicate tags (so per device similar tag names are allowed)
  @return true if the changing was ok.
*/
bool EB_changeTagNames(string sNodeId, langString lsTagDisplayName, bool bAllowDuplicateTagNames = FALSE)
{
  return EBTag::changeNames(sNodeId, lsTagDisplayName, bAllowDuplicateTagNames);
}

/**
  @brief Gets the id of a tag by it's name.
  @author Martin Schiefer
  @param sTagName  The name of the tag.
  @param sView     The root element for filtering.
  @param type      The type of node.
  @return dyn_string The list of id's with the name.
*/
dyn_string EB_getIdFromTagName(string sTagName, string sView = "", EBNodeType type = EBNodeType::DP)
{
  string sNodeId = EBTag::getIdFromExactName(sTagName, sView, type);
  if (sNodeId == "")
  {
    return makeDynString();
  }
  else
  {
    return makeDynString(sNodeId);
  }
}


/**
  @brief Gets the id of a tag by it's name.
  @author Martin Schiefer
  @param sTagName  The name of the tag.
  @param sView     The root element for filtering.
  @param type      The type of node.
  @return dyn_string The list of id's with the name.
*/
dyn_string EB_getIdsFromTagName(string sTagName, string sView = "", EBNodeType type = EBNodeType::DP)
{
  return EBTag::getIdFromName(sTagName, sView, type);
}

/**
  @brief Gets the id of a tag by it's name.
  @author Martin Schiefer
  @param sTagName  The name of the tag.
  @param sView     The root element for filtering.
  @param daType    List of possible node types
  @return string   The id with the name.
*/
string EB_getIdFromExactName(string sTagName, string sView = "", dyn_anytype daType = makeDynAnytype(EBNodeType::DP))
{
  string sId = "";

  for (int i = 1; i <= dynlen(daType); i++)
  {
    sId = EBTag::getIdFromExactName(sTagName, sView, daType[i]);
    if (sId != "")
    {
      break;
    }
  }

  return sId;
}

/**
  @brief Gets the name of a tag by it's id.
  @author Martin Schiefer
  @param sNodeId The id of the tag.
  @param iLangNumber The languagenumber.
  @return string The name of the tag.
*/
string EB_getTagName(string sNodeId, int iLangNumber = getActiveLang())
{
  EBTag ebTag;
  return ebTag.getName(sNodeId, iLangNumber);
}

/**
  @brief Gets the names of a tag by it's id.
  @author Martin Schiefer
  @param sNodeId The id of the tag.
  @return langString The names of the tag.
*/
langString EB_getTagNames(string sNodeId)
{
  langString ls;
  for (int i = 0; i < getNoOfLangs(); i++)
  {
    setLangString(ls, i, EBTag::getName(sNodeId, i));
  }
  return ls;
}

/**
  @brief Checks if the name can be used for the tag.
  @author Martin Schiefer
  @param sName The name to check.
  @param sParentNodeId The id of the parent tag.
  @param ebNodeType The type of node.
  @param sViewName The name of the view which is ok too be part off
  @param sNodeId The id of the tag.
  @param sParentId The parentId witch is ok too be part off.
  @return true if name is ok.
*/
bool EB_isTagNameValid(langString sName, string sParentNodeId = "", EBNodeType ebNodeType = EBNodeType::DP, string sViewName = "", string sNodeId = "", string sParentId = "")
{
  return EBTag::isNameOk(sName, sParentNodeId, ebNodeType, sViewName, sNodeId, sParentId);
}

/**
 * @brief Checks if a name has unallowed characters.
 * @author Martin Schiefer
 * @param sName The name.
 * @return bool True if the name has unallowed characters.
 */
bool EB_tagNameHasUnallowedCharacters(string sName)
{
  return EBTag::hasUnallowedCharacters(sName);
}

/**
  @brief Gets the datapoint that is linked to the tag.
  @author Martin Schiefer
  @param sNodeId The id of the tag.
  @return string The datapoint that is linked to the tag.
*/
string EB_getDatapointForTagId(string sNodeId)
{
  return EBTag::getDpForId(sNodeId);
}

/**
 * @brief Returns all children of a given tag
 * @param sNodeId       ID of the tag
 * @param bRecursive    TRUE to also return grandchildren, FALSE for only the children
 * @return Children of the specified tag
 */
public dyn_string EB_getChildrenOfTag(const string &sNodeId, bool bRecursive = FALSE)
{
  dyn_string dsChildren;

  if (cns_nodeExists(sNodeId))
  {
    cnsGetChildren(sNodeId, dsChildren);
  }

  for (int i = 1, iLength = dynlen(dsChildren); i <= iLength && bRecursive; i++)
  {
    dynAppend(dsChildren, EB_getChildrenOfTag(dsChildren[i], bRecursive));
  }

  return dsChildren;
}

/**
  @brief Gets the EBTagType for the type string.
  @author Martin Schiefer
  @param sType The type string.
  @return EBTagType The EBTagType.
 */
public EBTagType EB_getTagTypeForString(const string &sType)
{
  string sTypeLower = strtolower(sType);

  switch (sTypeLower)
  {
    case "bool":   return EBTagType::BOOL; break;
    case "int":    return EBTagType::INT; break;
    case "float":  return EBTagType::FLOAT; break;
    case "uint":   return EBTagType::UINT; break;
    case "string": return EBTagType::STRING; break;
    case "time":   return EBTagType::TIME; break;
  }

  return EBTagType::NONE;
}

/**
  @brief Gets the type string for the EBTagType.
  @author Martin Schiefer
  @param eType The EBTagType.
  @return string The type string.
 */
public string EB_getStringForTagType(const EBTagType &eType)
{
  switch (eType)
  {
    case EBTagType::BOOL:   return "bool"; break;
    case EBTagType::INT:    return "int"; break;
    case EBTagType::FLOAT:  return "float"; break;
    case EBTagType::UINT:   return "uint"; break;
    case EBTagType::STRING: return "string"; break;
    case EBTagType::TIME:   return "time"; break;
  }

  return "";
}

/**
  @brief Gets the icon for a EBTagType.
  @author Martin Schiefer
  @param type The EBTagType.
  @return string The path to the icon.
 */
public string EB_getIconForTagType(const EBTagType &type)
{
  string sIconPath = "";
  string sDataType = "";

  switch (type)
  {
    case EBTagType::BOOL:   sDataType = "bool";   break;
    case EBTagType::INT:    sDataType = "int";    break;
    case EBTagType::FLOAT:  sDataType = "float";  break;
    case EBTagType::UINT:   sDataType = "uint";   break;
    case EBTagType::STRING: sDataType = "string"; break;
    case EBTagType::TIME:   sDataType = "time"; break;
    default:                sDataType = ""; break;
  }

  string sRelPath = getPath(PICTURES_REL_PATH, "EB_Package/" + sDataType + ".svg");
  sIconPath = sRelPath != "" ? sRelPath : (sDataType != "" ? ("VarTypes/" + sDataType + ".png") : "");
  return sIconPath;
}

/**
  @brief Gets the EBTagType for the WinCCOA elementType.
  @author Martin Schiefer
  @param iElementType The WinCCOA elementType.
  @return EBTagType The EBTagType.
 */
public EBTagType EB_getTagTypeForElementType(int iElementType)
{
  if (iElementType == DPEL_BOOL)
  {
    return EBTagType::BOOL;
  }
  if (iElementType == DPEL_INT)
  {
    return EBTagType::INT;
  }
  if (iElementType == DPEL_UINT)
  {
    return EBTagType::UINT;
  }
  if (iElementType == DPEL_FLOAT)
  {
    return EBTagType::FLOAT;
  }
  if (iElementType == DPEL_STRING)
  {
    return EBTagType::STRING;
  }
  if (iElementType == DPEL_TIME)
  {
    return EBTagType::TIME;
  }
  return EBTagType::NONE;
}

/**
  @brief Gets the rate for a tag.
  @author Martin Schiefer
  @param sTagName The name of the tag.
  @return string The rate.
 */
public string EB_getRateForTag(string sTagName)
{
  dyn_string dsNodeId = EBTag::getIdFromName(sTagName);
  string sNodeId;
  if (dynlen(dsNodeId) > 0)
  {
    sNodeId = dsNodeId[1];
  }
  return EBTag::getTagRate(sNodeId);
}


/**
  @brief Checks if the string is of the EBTagType.
  @author Martin Schiefer
  @param type The EBTagType.
  @param sValue The string.
  @return bool True if the string is of the EBTagType.
 */
public bool EB_checkTypeForString(EBTagType type, string sValue)
{
  string sAllowedChars;
  if (type == EBTagType::INT)
  {
    sAllowedChars = "1234567890-";
  }
  if (type == EBTagType::UINT)
  {
    sAllowedChars = "1234567890";
  }
  if (type == EBTagType::FLOAT)
  {
    sAllowedChars = "1234567890.-";
  }
  if (type == EBTagType::TIME)
  {
    sAllowedChars = "1234567890.: ";
  }
  if (type == EBTagType::INT || type == EBTagType::UINT || type == EBTagType::FLOAT)
  {
    for (int i = 0; i < strlen(sValue); ++i)
    {
      // check if there are unallowed chars in IP string
      if (strpos(sAllowedChars, sValue[i]) == -1)
      {
        return FALSE; //unallowed char in IP
      }
    }
  }

  if (type == EBTagType::BOOL)
  {
    if (uniStrToLower(sValue) == "true" || uniStrToLower(sValue) == "false")
    {
      return TRUE;
    }
    return FALSE;
  }
  return TRUE;
}

/**
  @brief Gets the tagtype for a tag.
  @author Martin Schiefer
  @param sNodeId The tag id.
  @return EBTagType The tagtype.
 */
public EBTagType EB_getTagType(const string &sNodeId)
{
  int iType = EBTag::getTagType(sNodeId);
  return EB_getTagTypeForElementType(iType);
}

/**
  @brief Gets the active for a tag.
  @author Martin Schiefer
  @param sNodeId The tag id.
  @return bool The active.
 */
public bool EB_getTagActive(const string &sNodeId)
{
  return EBTag::getTagActive(sNodeId);
}

/**
  @brief Gets the archive for a tag.
  @author Martin Schiefer
  @param sNodeId The tag id.
  @return bool The archive.
 */
public bool EB_getTagArchive(const string &sNodeId)
{
  return EBTag::getTagArchive(sNodeId);
}

/**
  @brief Gets the rate for a tag.
  @author Martin Schiefer
  @param sNodeId The tag id.
  @return string The rate.
 */
public string EB_getTagRate(const string &sNodeId)
{
  return EBTag::getTagRate(sNodeId);
}

