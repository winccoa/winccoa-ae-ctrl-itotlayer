// $License: NOLICENSE

/**
 * @file scripts/libs/classes/EBTag.ctl
 * @brief Contains the EBTag class, which provides CRUD operations for tag names across all packages.
 * @author Martin Schiefer
 */

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "cns"
#uses "CtrlCNS"
#uses "classes/EBTagValue"

//--------------------------------------------------------------------------------
// declare variables and constants

/**
 * @brief Defines the enum EBTagType.
 */
enum EBTagType
{
  BOOL,
  INT,
  FLOAT,
  UINT,
  STRING,
  TIME,
  LONG,
  ULONG,
  NONE
};

/**
 * @brief Defines the enum EBNodeType.
 * @details Used for the CNS node type
 */
enum EBNodeType
{
  STRUCT = 1,
  DP = 2,
  SUBSCRIBEDSTRUCT = 501,
  SUBSCRIBED,
  MAPPEDSTRUCT = 601,
  MAPPED,
  DEVICE = 999
};

/**
 * @brief Defines the enum EBTagMetadataType.
 * @details Used for triggered event for meta data of tags.
 */
enum EBTagMetadataType
{
  Name = 0,
  Description,
  Unit,
  Format,
  Delete,
  Create
};

/*
  Easy example of an system with some tags in different Apps like S7, Mapped and Subscribed
  The CNSNodeType gives the information how this tag needs to be shown in the Virtual Tags CNS View, which is generated from the existing CNS Nodes
  CNSNodeType 2 the name of the Node is used for the Virtual Tags View
  CNSNodeType 602 it is a mapped tag and all Nodes from the TreeNode below are concatenated and seperated by a "." for the virtual Tags View
  CNSNodeType 502 it is a subscribed Tag all Nodes from the TreeNode below need to be concatenated and seperated depending on the CNSNodeType of the concatenated node
    If it is a Mapped Node(602) the seperator is a "." else it is a "@" for Subscribed Tags(502)
*/

//--------------------------------------------------------------------------------
/*!
 * @brief Handler for EBTag
 *
 * The class EBTag is used to handle Tags. Tags consists of nodes and datapoints. The datapoints can have
 * different types from type of EBTagType and are linked to nodes. The nodes themself can have a datapointlink or
 * are just logical grouping of tags.
 *
 * There are three different type of tags:
 * -)Subscribed: Tags subscribed from an other EdgeBox.
 * -)Mapped: Tags mapped to other tags.
 * -)Flat: All other tags.
 *
 * @author Martin Schiefer
 */
class EBTag
{

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  public static string SEP_VIEW      = ":";      //!< CNS view separator
  public static string SEP_PATH      = ".";      //!< CNS path separator
  public static string SEP_SUBSCRIBE = "@";      //!< Subscribe separator
  public static string DEBUG_FLAG    = "Tag";    //!< Debug flag
  public static string MAPPING_VAL   = "val";    //!< Value mapping key for the value
  public static string MAPPING_FLAG  = "flag";   //!< Value mapping key for the invalid flag
  public static string MAPPING_NAME  = "name";   //!< Value mapping key for the tag name

  //------------------------------------------------------------------------------
  /**
   * @brief Default constructor.
   * @author Martin Schiefer
   * @param sAppPath The app path.
   * @param lsViewName The view name.
   */
  public EBTag(string sAppPath = "", langString lsViewName = "")
  {
    this.createView(sAppPath, lsViewName);
    DebugFTN(DEBUG_FLAG, __FUNCTION__, this.dsNodeIds, this.fpCallBack);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief connection function for meta data
   * @author Daniel Lomosits
   * @param fpCallBack The pointer for the working function.
   * @param aUserData The given user data which shall be used.
   * @param bFirst Flag for the first connect.
   * @return 0 in case of success, otherwise -1
   */
  public int connectMetadata(function_ptr fpCallBack, anytype aUserData = "", bool bFirst = FALSE)
  {
    this.fpCallBackMetadata = fpCallBack;
    this.aUserDataMetadata = aUserData;
    this.bFirstMetadata = bFirst;
    dyn_string dsDpes;
    mapping mUserData;
    this._setupDataForMatadataConnect(this.fpCallBackMetadata, this.dsNodeIds, this.aUserDataMetadata, mUserData, dsDpes);
    DebugFTN(DEBUG_FLAG, __FUNCTION__, this.dsNodeIds, this.aUserDataMetadata, mUserData, dsDpes);
    return dpConnectUserData(this, this._callBackForMatadata, mUserData, this.bFirstMetadata, dsDpes);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief disconnecting function for meta data
   * @author Daniel Lomosits
   * @param bResetFunctionPtr Flag which describes whether function pointer shalle be reseted or not.
   * @return 0 in case of success, otherwise -1
   */
  public int disconnectMetadata(bool bResetFunctionPtr = TRUE)
  {
    int ibRet;
    if (this.fpCallBackMetadata != nullptr)
    {
      dyn_string dsDpes;
      mapping mUserData;
      this._setupDataForMatadataConnect(this.fpCallBackMetadata, this.dsNodeIds, this.aUserDataMetadata, mUserData, dsDpes);
      DebugFTN(DEBUG_FLAG, __FUNCTION__, this.dsNodeIds, this.aUserDataMetadata, mUserData, dsDpes);
      ibRet = dpDisconnectUserData(this, this._callBackForMatadata, mUserData, dsDpes);
    }
    if (bResetFunctionPtr)
    {
      this.fpCallBack = nullptr;
    }
    return ibRet;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief connects a function to the value change of an tag.
   * @author Martin Schiefer
   * @param fpCallBack The function pointer to the function which should be called.
   * @param aUserData User-defined data which is passed as parameter to the callback function.
   * @param bFirst Specifies if the callback function should be executed the first time already when the dpConnect() is called or first every time a value changes.
   * @return int 0, in the event of a failure returns -1.
   */
  public static int connect(function_ptr fpCallBack, anytype aUserData = "", bool bFirst = TRUE)
  {
    this.fpCallBack = fpCallBack;
    this.aUserData = aUserData;
    this.bFirst = bFirst;
    dyn_string dsDpes;
    mapping mUserData;
    dyn_dyn_string ddsNodesSeperated = this.getNodesSeperated(this.dsNodeIds);
    int iRet = 0;
    for (int i = 1; i <= dynlen(ddsNodesSeperated); i++)
    {
      dynClear(dsDpes);
      mappingClear(mUserData);
      dyn_string dsNodeIdsLocal = ddsNodesSeperated[i];
      this._setupDataForConnect(this.fpCallBack, dsNodeIdsLocal, this.aUserData, mUserData, dsDpes);
      DebugFTN(DEBUG_FLAG, __FUNCTION__, dsNodeIdsLocal, this.aUserData, mUserData, dsDpes);
      iRet = dpConnectUserData(this, this._callBack, mUserData, this.bFirst, dsDpes);
      if (iRet == -1)
      {
        return iRet;
      }
    }
    return iRet;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief disconnects a function to the value change of an tag.
   * @author Martin Schiefer
   * @param bResetFunctionPtr True if the function pointer should be cleared.
   * @return int 0, in the event of a failure returns -1.
   */
  public static int disconnect(bool bResetFunctionPtr = TRUE)
  {
    int ibRet;
    if (this.fpCallBack != nullptr)
    {
      dyn_string dsDpes;
      mapping mUserData;
      dyn_dyn_string ddsNodesSeperated = this.getNodesSeperated(this.dsNodeIds);
      for (int i = 1; i <= dynlen(ddsNodesSeperated); i++)
      {
        dynClear(dsDpes);
        mappingClear(mUserData);
        dyn_string dsNodeIdsLocal = ddsNodesSeperated[i];
        this._setupDataForConnect(this.fpCallBack, dsNodeIdsLocal, this.aUserData, mUserData, dsDpes);
        DebugFTN(DEBUG_FLAG, __FUNCTION__, this.dsNodeIds, this.aUserData, mUserData, dsDpes);
        ibRet = dpDisconnectUserData(this, this._callBack, mUserData, dsDpes);
      }
    }
    if (bResetFunctionPtr)
    {
      this.fpCallBack = nullptr;
    }
    return ibRet;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief assigns new nodeIds. When a function is connected to the old nodeIds they
   * will be disconnected and the new one will be connected.
   * @author Martin Schiefer
   * @param dsNodeIds The new nodeIds.
   */
  public void assign(const dyn_string &dsNodeIds)
  {
    DebugFTN(DEBUG_FLAG, __FUNCTION__, this.dsNodeIds, this.fpCallBack);
    if (this.fpCallBack != nullptr)
    {
      this.disconnect(FALSE);
    }
    this.dsNodeIds = dsNodeIds;
    if (this.fpCallBack != nullptr)
    {
      this.connectTag(this.fpCallBack, this.dsNodeIds, this.aUserData, this.bFirst);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief creates a view
   * Without any parameter the an empty string.
   * With parameter the function also creates a logical node as child of the "root-node". The first parameter is the
   * id of the tag and the second is the displayname of the tag. If the second parameter is not given the first value
   * is also taken as displayname. The generated nodeId will be returned.
   *
   * @param sAppPath The name of the app.
   * @param lsViewName The displayname of the app.
   * @return string The generated nodeId.
   */
  public static string createView(string sAppPath = "" , langString lsViewName = "")
  {
    string _sAppPath = "";
    if (sAppPath == "")
    {
      return _sAppPath;
    }
    string sSystemName = getSystemName();
    strreplace(sSystemName, ":", ".");
    _sAppPath = sSystemName + sAppPath + SEP_VIEW;
    dyn_string dsViews;
    cnsGetViews(substr(sSystemName, 0, strlen(sSystemName)-1), dsViews);
    bool bExists = dynContains(dsViews, _sAppPath);
    if( lsViewName != "")
    {
      if (!bExists)
      {
        cnsCreateView(sSystemName+sAppPath, lsViewName, SEP_PATH);
      }
      else
      {
        cnsChangeViewDisplayNames(sSystemName+sAppPath, lsViewName);
      }
    }
    else
    {
      if (!bExists)
      {
        cnsCreateView(sSystemName+sAppPath, sAppPath, SEP_PATH);
      }
    }
    return _sAppPath;
  }

  /**
   * @brief gets the viewname of an app.
   * @author Martin Schiefer
   * @param sAppPath The name of the app.
   * @return string The viewname.
  */
  public static string getViewName(const string &sAppPath)
  {
    string sSystemName = getSystemName();
    strreplace(sSystemName, ":", ".");
    return sSystemName+sAppPath+SEP_VIEW;
  }


  // TODO nice to have: create a function createByPath() does the same as create but the full path is given to the tag, if parent nodes are missing they are creted automatically with the needed derived type
  // this is similar to creteFolder() where a Path canbe given and the full path is created if not existing yet => convinience function for easier creation of mapped and subscribed tags and even App Tags
  // a parent node can be given as CNS ID, the rest is given as a path as langString where the nodes are either seperated by . or @


  /**
   * @brief creates a tag.
   * dependend on the paramater the function creates:
   * a node for a group of nodes (nodeType: STRUCT, SUBSCRIBEDSTRUCT or MAPPEDSTRUCT),
   * a node (nodeType: DP, SUBSCRIBED or MAPPED) with a datapoint from the given tagtype
   * a node (nodeType: DP, SUBSCRIBED or MAPPED) two a given datapoint sMappedNodeId
   *
   * before the node is created a plausibility check done if the node should be created.
   * it's plausibile when the parentnode is the "root-node", the parent node is a node for a group of nodes (struct)
   *
   * @author Martin Schiefer
   * @param sParentNodeId The id of the parent node.
   * @param lsTagDisplayName The displayname of the tag.
   * @param nodeType The type of node.
   * @param tagType The type of tag.
   * @param sMappedNodeId The id of the node to link.
   * @param bAllowDuplicateTagNames flag to ignore name check of duplicate tags (so per device similar tag names are allowed)
   * @return string The id of the generated tag.
   */
  public static string create(string &sParentNodeId, const langString &lsTagDisplayName,
                       EBNodeType nodeType = EBNodeType::STRUCT,
                       EBTagType tagType = EBTagType::INT,
                       string sMappedNodeId = "",
                       bool bAllowDuplicateTagNames = FALSE)
  {

    string sParentDp;
    int iParentType;
    cnsGetId(sParentNodeId, sParentDp, iParentType);
    string sNewNodeId = "";
    bool bPlausibility = (iParentType == 0 || // parent is view
                         (iParentType % 2 == 1) //parent is struct
                         );

    if (bPlausibility && isNameOk(lsTagDisplayName, sParentNodeId, nodeType, "", "", "", bAllowDuplicateTagNames))
    {
      if (sMappedNodeId == "" &&
         (nodeType == EBNodeType::DP ||
          nodeType == EBNodeType::SUBSCRIBED)
         )
      {
        sMappedNodeId = _createDp(tagType);
        if (sMappedNodeId == "")
        {
          return "";
        }
      }
      string sNodeId = _getNewNodeId();
      sNewNodeId = _createNode(sParentNodeId, sNodeId, lsTagDisplayName, nodeType, sMappedNodeId);
    }
    return sNewNodeId;
  }

  /**
   * @brief creates a tag with a given nodeId.
   * @author Martin Schiefer
   * @param sParentNodeId The id of the parent node.
   * @param sNodeId The given nodeId
   * @param lsTagDisplayName The displayname of the tag.
   * @param nodeType The type of node.
   * @param tagType The type of tag.
   * @param sMappedNodeId The id of the node to link.
   * @param bForceCreate When MAPPED && true a dp will be created.
   * @return string The id of the generated tag.
   */
  public static string createWithNodeId(const string &sParentNodeId, const string &sNodeId,
                                        const langString &lsTagDisplayName,
                                        EBNodeType nodeType = EBNodeType::STRUCT,
                                        EBTagType tagType = EBTagType::INT,
                                        string sMappedNodeId = "",
                                        bool bForceCreate = FALSE)
  {
    string sNewNodeId = "";

    if (isNameOk(lsTagDisplayName, sParentNodeId, nodeType))
    {
      if (sMappedNodeId == "" &&
         ((nodeType == EBNodeType::DP || nodeType == EBNodeType::SUBSCRIBED) ||
          nodeType == EBNodeType::MAPPED && bForceCreate)
         )
      {
        sMappedNodeId = _createDp(tagType);

        if (sMappedNodeId == "")
        {
          return "";
        }
      }

      string sPath = sParentNodeId;
      sNewNodeId = _createNode(sPath, sNodeId, lsTagDisplayName, nodeType, sMappedNodeId);
    }

    return sNewNodeId;
  }

  /**
   * @brief deletes a tag.
   * Checks if the given nodeId has a datapointlink and deletes the node and the linked datapoint if there is one.
   *
   * @author Martin Schiefer
   * @param sNodeId The id of the tag.
   * @return true if the deletion was ok.
  */
  public static bool del(const string &sNodeId)
  {
    string sDpeName;
    int iNodeType;
    cnsGetId(sNodeId, sDpeName, iNodeType);
    if (sDpeName != "")
    {
      dpDelete(sDpeName);
    }

    bool bRet = cns_deleteTreeOrNode(sNodeId);
    if (bRet)
    {
      anytype aVal;
      _setMetadataChanged(sNodeId, EBTagMetadataType::Delete, aVal);
    }
    return bRet;
  }

  /**
   * @brief changes the name of a tag.
   * @author Martin Schiefer
   * @param sNodeId The id of the tag.
   * @param sTagDisplayName The displayname name.
   * @param iLangNumber The languagenumber.
   * @param bAllowDuplicateTagNames flag to ignore name check of duplicate tags (so per device similar tag names are allowed)
   * @return true if the changing was ok.
   */
  public static bool changeName(const string &sNodeId, const string &sTagDisplayName, int iLangNumber = getActiveLang(), bool bAllowDuplicateTagNames = FALSE)
  {
    string sParent;
    bool bRet = cnsGetParent(sNodeId, sParent);
    if (!bRet)
    {
      sParent = cnsSubStr(sNodeId, CNSSUB_SYS | CNSSUB_VIEW);
    }
    string sDp;
    int iType;
    cnsGetId(sNodeId, sDp, iType);
    if (_isNameOkForLang(sTagDisplayName, sParent, (EBNodeType)iType, iLangNumber, "", sNodeId, "", bAllowDuplicateTagNames))
    {
      langString lsTagDisplayName;
      cnsGetDisplayNames(sNodeId, lsTagDisplayName);
      setLangString(lsTagDisplayName, iLangNumber, sTagDisplayName);
      bool bRet1 = cnsChangeNodeDisplayNames(sNodeId, lsTagDisplayName);
      if (bRet1)
      {
        _setMetadataChanged(sNodeId, EBTagMetadataType::Name, lsTagDisplayName);
      }
      return bRet1;
    }
    return FALSE;
  }

  /**
   * @brief changes the name of a tag.
   * @author Martin Schiefer
   * @param sNodeId The id of the tag.
   * @param lsTagDisplayName The displayname name.
   * @param bAllowDuplicateTagNames flag to ignore name check of duplicate tags (so per device similar tag names are allowed)
   * @return true if the changing was ok.
   */
  public static bool changeNames(const string &sNodeId, const langString &lsTagDisplayName, bool bAllowDuplicateTagNames = FALSE)
  {
    string sParent;
    bool bRet = cnsGetParent(sNodeId, sParent);
    if (!bRet)
    {
      sParent = cnsSubStr(sNodeId, CNSSUB_SYS | CNSSUB_VIEW);
    }
    string sDp;
    int iType;
    cnsGetId(sNodeId, sDp, iType);

    if (iType == 0) //not found (because device is new
    {
      return (isNameOk(lsTagDisplayName));
    }
    else if (isNameOk(lsTagDisplayName, sParent, (EBNodeType)iType, "", sNodeId, "", bAllowDuplicateTagNames))
    {
      bool bRet1 = cnsChangeNodeDisplayNames(sNodeId, lsTagDisplayName);
      if (bRet1)
      {
        _setMetadataChanged(sNodeId, EBTagMetadataType::Name, lsTagDisplayName);
      }
      return bRet1;
    }
    return FALSE;
  }

  /**
   * @brief gets the name of a tag by it's id.
   * @author Martin Schiefer
   * @param sNodeId The id of the tag.
   * @param iLangNumber The languagenumber.
   * @return string The name of the tag.
   */
  public static string getName(const string &sNodeId, int iLangNumber = getActiveLang())
  {
    string sDp;
    int iType;
    cnsGetId(sNodeId, sDp, iType);
    string s= _buildNodeName(sNodeId, "", iType, iLangNumber);
    return s;
  }

  /**
   * @brief Converts a tag name to its node id
   * @param sTagName    Tag name to get the node id from
   * @return Node id from the specified tag name or empty string in case the tag name was not found
   */
  public string getNodeIdFromName(const string &sTagName)
  {
    if (hasUnallowedCharacters(sTagName, FALSE, FALSE))
    {
      return "";
    }
    dyn_string dsCnsPaths;
    bool bRet = cnsGetNodesByName("*:" + sTagName, "", CNS_SEARCH_DISPLAY_NAME, CNS_SEARCH_ALL_LANGUAGES, CNS_DATATYPE_ALL_TYPES , dsCnsPaths);
    if (dynlen(dsCnsPaths) == 0 || !bRet)
    {
      return "";
    }
    else
    {
      return dsCnsPaths[1];
    }
  }

  /**
   * @brief gets the id of a tag by it's name.
   * @author Martin Schiefer
   * @param sTagName    The name of the tag.
   * @param sView       The root element for filtering.
   * @param type        The type of node.
   * @param iLang       The languagenumber.
   * @return string     The id with the name.
   */
  public static string getIdFromExactName(const string &sTagName, string sView = "", EBNodeType type = EBNodeType::DP, int iLang = getActiveLang())
  {
    dyn_string dsCnsPaths = getIdFromName(sTagName, sView, type, iLang);

    for (int i = 1; i <= dynlen(dsCnsPaths); i++)
    {
      if (sTagName == getName(dsCnsPaths[i], iLang))
      {
        return dsCnsPaths[i];
      }
    }

    return "";
  }

  /**
   * @brief gets the id of a tag by it's name.
   * @author Martin Schiefer
   * @param sTagName    The name of the tag.
   * @param sView       The root element for filtering.
   * @param type        The type of node.
   * @param iLang       The languagenumber.
   * @return dyn_string The list of id's with the name.
   */
  public static dyn_string getIdFromName(const string &sTagName, string sView = "", EBNodeType type = EBNodeType::DP, int iLang = getActiveLang())
  {
    string sTempTag = sTagName;

    // searchs for the CNSNodePath of the given TagNAme in the current lang
    // if the view == "" than it is searched in the virtual Tags View where the Tags are called Edgebox1@speed, Omac1.speed or just speed
    // if the View is filled than only in that a search is done like the ".S7:" View
    // If the App wants to search in teh own View the dev cn called it like EB.getIdFromName("tagTobeSearched", EB.getAppPath());
    // returns "" if not found, else the CNS Node Path

    int iCnsTypeSearch;
    if (type == EBNodeType::DP)
    {
      //Example for subscribed TC_Lane1_eb003@TC_Lane1_gw001.S7300.S7PLC3_int_tag0116 --> search for @ first
      //Example for mapped     test2.Status.Energy0.TypeID --> search for . second
      int iIndex = strpos(sTempTag, "@");

      if (iIndex >= 0)
      {
        iCnsTypeSearch = (int)EBNodeType::SUBSCRIBED;
        strchange(sTempTag, iIndex, 1, "."); // replace only the first \@ with a . because if a subscribed Tag is subscribed the Tag is called EB1\@EB2\@speed and the CNS is EB1.EB2\@speed therefore the second \@ is not allowed to be replaced with a dot
      }
      else if (strtok(sTempTag, ".") >= 0)
      {
        iCnsTypeSearch = (int)EBNodeType::MAPPED;
      }
      else
      {
        iCnsTypeSearch = (int)EBNodeType::DP;
      }
    }
    else
    {
      iCnsTypeSearch = (int)type;
    }

    // First check the top level nodes
    dyn_string dsCnsPaths;
    bool bRet = cnsGetNodesByName("*:" + sTempTag, sView, CNS_SEARCH_DISPLAY_NAME, iLang, iCnsTypeSearch, dsCnsPaths);

    // Also check if there are subnodes matching the specified name
    if (bRet)
    {
      dyn_string dsSubNodes;
      cnsGetNodesByName("*:*." + sTempTag, sView, CNS_SEARCH_DISPLAY_NAME, iLang, iCnsTypeSearch, dsSubNodes);

      dynAppend(dsCnsPaths, dsSubNodes);
    }

    if (dynlen(dsCnsPaths) == 0 || !bRet)
    {
      return makeDynString();
    }
    else
    {
      return dsCnsPaths;
    }
  }

  /**
   * @brief checks if the name can be used for the tag.
   * @author Martin Schiefer
   * @param sName            The name to check.
   * @param sParentNodeId    The id of the parent tag.
   * @param ebNodeType       The type of node.
   * @param sViewName        The name of the view which is ok to be part of.
   * @param sNodeId          The nodeId of the node.
   * @param sParent          The parentId which is ok to be part of.
   * @param bAllowDuplicateTagNames flag to ignore name check of duplicate tags (so per device similar tag names are allowed)
   * @return true if name is ok.
   */
  public static bool isNameOk(const langString &sName, string sParentNodeId = "",
                              EBNodeType ebNodeType = EBNodeType::DP, string sViewName = "",
                              string sNodeId = "", string sParent = "", bool bAllowDuplicateTagNames = FALSE)
  {
    if (cns_checkName(sName) != 0)
    {
      DebugFTN(DEBUG_FLAG, "Not a valid CNSName: ", sName, cns_checkName(sName), getStackTrace());
      return FALSE;
    }

    bool bAllLangSame = TRUE;

    for (int i = 0; i < getNoOfLangs() - 1 && bAllLangSame; i++)
    {
      if (sName[i] != sName[i + 1])
      {
        bAllLangSame = FALSE;
      }
    }

    DebugFTN(DEBUG_FLAG, __FUNCTION__, "allLangSame", bAllLangSame, sName);

    bool bResult = _isNameOkForLang(sName, sParentNodeId, ebNodeType, bAllLangSame ? CNS_SEARCH_ALL_LANGUAGES : getActiveLang(), sViewName, sNodeId, sParent, bAllowDuplicateTagNames);

    return bResult;
  }

  /**
   * @brief gets the dp for an id.
   * @author Martin Schiefer
   * @param sNodeId The id.
   * @return string The dp.
   */
  public static string getDpForId(const string &sNodeId)
  {
    string sDp;
    int iType;
    cnsGetId(sNodeId, sDp, iType);
    return sDp;
  }

  /**
   * @brief sets the dp for an id.
   * @author Martin Schiefer
   * @param sNodeId The id.
   * @param sDp The dp.
   * @param nodeType The nodeType.
   * @return bool True if the set was ok.
   */
  public static bool setDpForId(const string &sNodeId, const string &sDp, EBNodeType nodeType = EBNodeType::DP)
  {
    return cnsChangeNodeData(sNodeId, sDp, (int)nodeType);
  }

  /**
   * @brief checks if a name has unallowed characters.
   * @author Martin Schiefer
   * @param sName The name.
   * @param bIncludePath TRUE if SEP_PATH is not allowed (dafault TRUE).
   * @param bIncludeSub TRUE if SEP_SUBSCRIBE is not allowed (dafault TRUE).
   * @return bool True if the name has unallowed characters.
   */
  public static bool hasUnallowedCharacters(const string &sName, bool bIncludePath = TRUE, bool bIncludeSub = TRUE)
  {
    if (strpos(sName, SEP_VIEW) >-1)
    {
      return TRUE;
    }
    if (bIncludePath && strpos(sName, SEP_PATH) >-1)
    {
      return TRUE;
    }
    if (bIncludeSub &&  strpos(sName, SEP_SUBSCRIBE) >-1)
    {
      return TRUE;
    }
    if (sName == "")
    {
      return TRUE;
    }
    //leading space
    if (strpos(sName, " ") == 0)
    {
      return TRUE;
    }
    //tailing space
    if (strpos(sName, " ") == strlen(sName)-1)
    {
      return TRUE;
    }
    if (strpos(sName, "?") > -1 || strpos(sName, "*") > -1)
    {
      return TRUE;
    }
    return FALSE;
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
  public int connectTag(function_ptr fpCallBack, dyn_string dsNodeIds, anytype aUserData = "", bool bFirst = TRUE)
  {
    dyn_string dsDpes;
    mapping mUserData;
    dyn_dyn_string ddsNodesSeperated = getNodesSeperated(dsNodeIds);
    int iRet = 0;
    for (int i = 1; i <= dynlen(ddsNodesSeperated); i++)
    {
      dynClear(dsDpes);
      mappingClear(mUserData);
      dyn_string dsNodeIdsLocal = ddsNodesSeperated[i];
      this._setupDataForConnect(fpCallBack, dsNodeIdsLocal, aUserData, mUserData, dsDpes);
      iRet = dpConnectUserData(this, this._callBack, mUserData, bFirst, dsDpes);
      if (iRet == -1)
      {
        return iRet;
      }
    }
    return iRet;
  }

  /**
   * @brief connects a function to the value change of an tag.
   * @author Martin Schiefer
   * @param fpCallBack The function pointer to the function which should be called.
   * @param dsNodeIds The dyn_string containing the tag ids.
   * @param aUserData User-defined data which is passed as parameter to the callback function.
   * @return int 0, in the event of a failure returns -1.
   */
  public int disconnectTag(function_ptr fpCallBack, dyn_string dsNodeIds, anytype aUserData = "")
  {
    dyn_string dsDpes;
    mapping mUserData;
    dyn_dyn_string ddsNodesSeperated = getNodesSeperated(dsNodeIds);
    int iRet = 0;
    for (int i = 1; i <= dynlen(ddsNodesSeperated); i++)
    {
      dynClear(dsDpes);
      mappingClear(mUserData);
      dyn_string dsNodeIdsLocal = ddsNodesSeperated[i];
      this._setupDataForConnect(fpCallBack, dsNodeIdsLocal, aUserData, mUserData, dsDpes);
      iRet = dpDisconnectUserData(this, this._callBack, mUserData, bFirst, dsDpes);
      if (iRet == -1)
      {
        return iRet;
      }
    }
    return iRet;
  }

  /**
   * @brief sets a value of an tag.
   * @author Martin Schiefer
   * @param sNodeId The tag id.
   * @param aValue value to set.
   * @return int 0, in the event of a failure returns -1.
   */
  public static int setTagValue(const string &sNodeId, const anytype &aValue)
  {
    string sDpe = getDpForId(sNodeId);
    return dpSet(sDpe, aValue);
  }

  /**
   * @brief gets the value of a tag.
   * @author Daniel Lomosits
   * @param sNodeId The tag id.
   * @param aValue value to get.
   * @return int 0, in the event of a failure returns -1.
   */
  public static int getTagValue(const string &sNodeId, anytype &aValue)
  {
    string sDpe = getDpForId(sNodeId);
    return dpGet(sDpe, aValue);
  }

  /**
   * @brief gets the values of a tag within a timerange.
   * @author Martin Schiefer
   * @param sNodeId The tag id.
   * @param tStart The start of the timerange
   * @param tEnd The end of the timerange
   * @param iCount The number of the values before tStart and after tEnd that also have to be read out.
   * @param daValues The values.
   * @param dtTimes The timestamps.
   * @return int 0, in the event of a failure returns -1.
   */
  public static int getTagPeriod(const string &sNodeId, const time &tStart, const time &tEnd, int iCount, dyn_anytype &daValues, dyn_time &dtTimes)
  {
    string sDpe = getDpForId(sNodeId);
    return dpGetPeriod(tStart, tEnd, iCount, daValues, dtTimes);
  }

  /**
   * @brief sets the value of a tag active/inactive.
   * @author Daniel Lomosits
   * @param sNodeId The tag id.
   * @param bValue value to set.
   * @return int 0, in the event of a failure returns -1.
   */
  public static int setTagValueActive(string sNodeId, bool bValue)
  {
    string sDpe = getDpForId(sNodeId);
    return dpSet(sDpe + ":_online.._active", bValue);
  }

  /**
   * @brief sets a value of an tag and waits for the answer from the eventmanager.
   * @author Martin Schiefer
   * @param sNodeId The tag id.
   * @param aValue value to set.
   * @return int 0, in the event of a failure returns -1.
   */
  public static int setTagValueAndWait(const string &sNodeId, const anytype &aValue)
  {
    string sDpe = getDpForId(sNodeId);
    return dpSetWait(sDpe, aValue);
  }

  /**
   * @brief sets a value of an tag to a specific point in time.
   * @author Martin Schiefer
   * @param tSource The source time.
   * @param sNodeId The tag id.
   * @param aValue value to set.
   * @return int 0, in the event of a failure returns -1.
   */
  public static int setTagValueTimed(const time &tSource, const string &sNodeId, const anytype &aValue)
  {
    string sDpe = getDpForId(sNodeId);
    return dpSetTimed(tSource, sDpe, aValue);
  }

  /**
   * @brief sets a value of an tag to a specific point in time and waits for the answer from the eventmanager.
   * @author Martin Schiefer
   * @param tSource The source time.
   * @param sNodeId The tag id.
   * @param aValue value to set.
   * @return int 0, in the event of a failure returns -1.
   */
  public static int setTagValueTimedAndWait(const time &tSource, const string &sNodeId, const anytype &aValue)
  {
    string sDpe = getDpForId(sNodeId);
    return dpSetTimedWait(tSource, sDpe, aValue);
  }

  /**
   * @brief Sets the description for the given tag id
   * @param sNodeId: The tag id where the unit will be set
   * @param lsComment: The description in one or several languages
   * @return 0 in case of success, otherwise -1
   */
  public static int setTagDescription(const string &sNodeId, const langString &lsComment)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return -1;
    }
    int iRes = dpSetDescription(sDpe, lsComment);
    if (iRes == 0)
    {
      _setMetadataChanged(sNodeId, EBTagMetadataType::Description, lsComment);
    }
    return iRes;
  }

  /**
    @brief Gets the description of a given Tagid.
    @author Martin Schiefer
    @param sNodeId The TagId.
    @param bMultiLang FALSE to get a string with description in current language, TRUE to get a langString
    @returns string The description in the current language.
  */
  public static anytype getTagDescription(const string &sNodeId, bool bMultiLang = FALSE)
  {
    anytype aReturn;

    if (!bMultiLang)
    {
      aReturn = "";
    }

    string sDpe;
    int iType;
    if (cnsGetId(sNodeId, sDpe, iType)) //if path is ok
    {
      if (sDpe != "") // if has Dpe linked
      {

        aReturn = dpGetDescription(sDpe);
      }
    }
    return aReturn;
  }

  /**
   * @brief Sets the unit for the given tag id
   * @param sNodeId     Tag id where the unit will be set
   * @param lsUnit      Unit in one or several languages
   * @return 0 in case of success or -1 in case of failure
   */
  public static int setTagUnit(const string &sNodeId, const langString &lsUnit)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return -1;
    }
    bool bRet = dpSetUnit(sDpe, lsUnit);
    if (bRet)
    {
      _setMetadataChanged(sNodeId, EBTagMetadataType::Unit, lsUnit);
    }
    return bRet;
  }

  /**
    gets the unit string for the given tag id
    @author Daniel Lomosits
    @param sNodeId: The tag id where the unit will be set
    @return langString: The unit string
  */
  public static langString getTagUnit(const string &sNodeId)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return "";
    }
    return dpGetUnit(sDpe);
  }

  /**
   * @brief Sets the format string for the given tag id
   * @param sNodeId     Tag id where the unit will be set
   * @param sFormat     Format string
   * @return 0 in case of success or -1 in case of failure
   */
  public static int setTagFormat(const string &sNodeId, const string &sFormat)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return -1;
    }
    bool bRes = dpSetFormat(sDpe, sFormat);
    if (bRes)
    {
      _setMetadataChanged(sNodeId, EBTagMetadataType::Format, sFormat);
    }
    return bRes;
  }

  /**
   * @brief Gets the format string for the given tag id
   * @param sNodeId     Tag id where the unit will be set
   * @return The format string
   */
  public static langString getTagFormat(const string &sNodeId)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return "";
    }
    return dpGetFormat(sDpe);
  }

  /**
   * @brief Set the tag address active/inactive
   * @param sNodeId     Tag id where the configs will be set
   * @param bActive     If the address is active or not
   * @return 0 in case of success or -1 in case of failure
   */
  public static int setTagActive(const string &sNodeId, bool bActive)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return -1;
    }
    int iErr;

    iErr = dpSetWait(sDpe + ":_address.._active", bActive);
    dyn_errClass dErr = getLastError();

    if (iErr != 0)
    {
      return iErr;
    }

    return dynlen(dErr) ? -99 : iErr;
  }

  /**
   * @brief Gets the reference string for the given tag id
   * @param sNodeId     Tag id
   * @returns The reference string
   */
  public static string getReferenceString(const string &sNodeId)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return "";
    }

    int iType;
    dpGet(sDpe + ":_address.._type", iType );
    if (iType != DPCONFIG_PERIPH_ADDR_MAIN)
    {
      return "";
    }

    string sRef;
    dpGet(sDpe + ":_address.._reference", sRef);
    return sRef;
  }

  /**
   * @brief Creates an address and distrib config for the given tag id
   * @param sNodeId          Tag id where the configs will be set
   * @param iDrvNr           Driver number
   * @param sDrvIdent        Protocol. e.g.: "S7", "OPCUA", ...
   * @param sRef             Reference string
   * @param sPollGroup       Pollgroup used
   * @param iTrans           Transformation
   * @param bActive          If the address is active or not (default: TRUE/active)
   * @param iDirection       Direction of the address (default: Input polling)
   * @param sDeviceId        Id of the device (Optional)
   * @param uSubindex        Subindex in the read value (Optional)
   * @param bLowLevelFilter  Only send value changes (Optional)
   * @return 0 in case of success or -1 in case of failure
   */
  public static int createTagAddress(const string &sNodeId, int iDrvNr, const string &sDrvIdent,
                         const string &sRef, const string &sPollGroup,
                         int iTrans, bool bActive = TRUE, int iDirection = DPATTR_ADDR_MODE_INPUT_POLL,
                         string sDeviceId = "", uint uSubindex = 0u, bool bLowLevelFilter = TRUE)
  {
    int    iErr = -1;
    string sDpe = getDpForId(sNodeId);

    if (sDpe != "")
    {
      // create dist & address config
      iErr = dpSetWait(sDpe + ":_distrib.._type",   DPCONFIG_DISTRIBUTION_INFO,
                       sDpe + ":_distrib.._driver", iDrvNr,
                       sDpe + ":_address.._type",       DPCONFIG_PERIPH_ADDR_MAIN,
                       sDpe + ":_address.._drv_ident",  sDrvIdent,
                       sDpe + ":_address.._reference",  sRef,             // die eigentliche Adresse
                       sDpe + ":_address.._poll_group", sPollGroup,       // Pollgruppe
                       sDpe + ":_address.._direction",  iDirection,       // Eingangsadresse
                       sDpe + ":_address.._lowlevel",   bLowLevelFilter,  // Lowlevel Vergleich aktivieren
                       sDpe + ":_address.._active",     bActive,          // Adresse aktivieren
                       sDpe + ":_address.._datatype",   iTrans,           // Transformationsart
                       sDpe + ":_address.._connection", sDeviceId,
                       sDpe + ":_address.._subindex",   uSubindex);

      dyn_errClass deErrors = getLastError();

      if (dynlen(deErrors) > 0)
      {
        iErr = -99;
      }
    }

    return iErr;
  }

  /**
   * @brief Checks the address by making a single query for the given tag id
   * @param sNodeId     Tag id where the configs will be set
   * @param iDrvNr      Driver number
   * @param iTimeOut    Timeout to wait for answer
   * @return true if query was successful
   */
  public static bool makeSingleQueryTagAddress(const string &sNodeId, int iDrvNr, int iTimeOut = 2)
  {
    string sDpe = getDpForId(sNodeId);
    dyn_anytype daReturnValues;
    bool bExpired = FALSE;
    dyn_string dsNamesSet    = makeDynString("_Driver" + iDrvNr + ".SQ");
    dyn_string dsValuesSet   = makeDynString(sDpe);
    dyn_anytype daConditions = makeDynBool(TRUE);
    dyn_string dsNamesWait   = makeDynString(sDpe + ":_online.._from_SI");
    dyn_string dsNamesReturn = makeDynString(sDpe + ":_online.._value");

    dpSetAndWaitForValue(dsNamesSet, dsValuesSet, dsNamesWait, daConditions, dsNamesReturn, daReturnValues, iTimeOut, bExpired);

    return !bExpired;
  }

  /**
   * @brief Starts a single query for the given tag id
   * @param sNodeId     Tag id where the configs will be set
   * @param iDrvNr      Driver number
   */
  public static void startSingleQueryTagAddress(const string &sNodeId, int iDrvNr)
  {
    string sDpe = getDpForId(sNodeId);
    dpSet("_Driver" + iDrvNr + ".SQ", sDpe);
  }

  /**
   * @brief Creates a pv_range config for the given tag id
   * @param sNodeId     Tag id where the config will be set
   * @param fMin        Lower limit of the range
   * @param fMax        Upper limit of the range
   * @return 0 when it was successfully executed and in the event of a failure -1
   */
  public static int createTagRange(const string &sNodeId, float fMin, float fMax)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return 0;
    }
    if (fMin == fMax)
    {
      return 0;
    }
    return dpSetWait(sDpe + ":_pv_range.._type", DPCONFIG_MINMAX_PVSS_RANGECHECK,
                     sDpe + ":_pv_range.._incl_min", TRUE,
                     sDpe + ":_pv_range.._incl_max", TRUE,
                     sDpe + ":_pv_range.._min", fMin,
                     sDpe + ":_pv_range.._max", fMax);
  }

  /**
   * @brief Creates an archive config for the given tag id
   * @param sNodeId          Tag id where the config will be set
   * @param sRefreshRate     Refresh rate of the tag, in accordance to this rate, the archive group is selected
   * @param bActive          TRUE -> Enable archiving
   * @return 0 when it was successfully executed and in the event of a failure -1
   */
  public static int createTagArchive(const string &sNodeId, const string &sRefreshRate, bool bActive = TRUE)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return 0;
    }

    string sArchive = "";

    switch (sRefreshRate)
    {
      // Fall thru as there is only a single archive for tags
      case "100ms":
      case "1s":
      case "5s":
        sArchive = "_ValueArchive_1";  // Archive for tags
        break;
    }

    if (sArchive != "")
    {
      return dpSetWait(sDpe + ":_archive.._type", DPCONFIG_DB_ARCHIVEINFO,
                       sDpe + ":_archive.._archive", bActive,
                       sDpe + ":_archive.1._type", DPATTR_ARCH_PROC_VALARCH,
                       sDpe + ":_archive.1._class", getSystemName() + sArchive);
    }
    else
    {
      //if empty or invalid pollgroup is defined, delete archive config
      return dpSetWait(sDpe + ":_archive.._type", DPCONFIG_NONE);
    }
  }

  /**
    @brief Gets the rate for a tag.
    @author Martin Schiefer
    @param sNodeId The tag id.
    @return string The rate.
   */
  public static string getTagRate(const string &sNodeId)
  {
    string sRetVal = "5s";
    string sPollGroup;
    string sDpe = getDpForId(sNodeId);
    int iType;

    dpGet(sDpe + ":_address.._type", iType);

    if (iType == DPCONFIG_PERIPH_ADDR_MAIN)
    {
      dpGet(sDpe + ":_address.._poll_group", sPollGroup);
      sRetVal = dpSubStr(sPollGroup, DPSUB_DP);
      sRetVal = substr(sRetVal, 1);
    }

    return sRetVal;
  }

  /**
   * @brief Creates or deletes (if absolute and relative smoothing values are 0.0) a smoothing config for the given tag id
   * @param sNodeId          Tag id where the config will be set
   * @param fSmoothingAbsolute   The ablolute smoothing value
   * @param fSmoothingRelative   The relative smoothing value
   * @return 0 when it was successfully executed and in the event of a failure -1
   */
  public static int createSmoothingConfig(const string &sNodeId, float fSmoothingAbsolute = 0.0, float fSmoothingRelative = 0.0)
  {
    string sDpe = getDpForId(sNodeId);
    if (sDpe == "")
    {
      return 0;
    }

    if (fSmoothingAbsolute != 0.0 || fSmoothingRelative != 0.0)
    {
      return dpSetWait(sDpe + ":_smooth.._type",     DPCONFIG_SMOOTH_SIMPLE_MAIN,
                       sDpe + ":_smooth.._std_type", fSmoothingAbsolute != 0.0 ? DPATTR_VALUE_SMOOTH : DPATTR_VALUE_REL_SMOOTH,
                       sDpe + ":_smooth.._std_tol",  fSmoothingAbsolute != 0.0 ? fSmoothingAbsolute  : fSmoothingRelative);
    }
    else
    {
      //if no absolute or relative smoothing is defined, delete smoothing config
      return dpSetWait(sDpe + ":_smooth.._type", DPCONFIG_NONE);
    }
  }

  /**
    @brief Gets the tagtype for a tag.
    @author Martin Schiefer
    @param sNodeId The tag id.
    @return EBTagType The tagtype.
   */
  public static int getTagType(const string &sNodeId)
  {
    string sDp;
    int iType;
    cnsGetId(sNodeId, sDp, iType);

    if (iType == 2) //means DP(E)
    {
      return dpElementType(sDp);
    }

    return iType;
  }

  /**
    @brief Gets the active for a tag.
    @author Martin Schiefer
    @param sNodeId The tag id.
    @return bool The active.
   */
  public static bool getTagActive(const string &sNodeId)
  {
    bool bActive = FALSE;
    string sDpe = getDpForId(sNodeId);
    if (sDpe != "")
    {
      dpGet(sDpe + ":_address.._active", bActive);
    }
    return bActive;
  }

  /**
    @brief Gets the archive for a tag.
    @author Martin Schiefer
    @param sNodeId The tag id.
    @return bool The archive.
   */
  public static bool getTagArchive(const string &sNodeId)
  {
    bool bArchive = FALSE;
    string sDpe = getDpForId(sNodeId);
    if (sDpe != "")
    {
      dpGet(sDpe + ":_archive.._archive", bArchive);
    }
    return bArchive;
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  private dyn_dyn_string getNodesSeperated(dyn_string dsNodeIds)
  {
    int iMaxDsNodeIds = 20;
    dyn_dyn_string ddsRetVal;
    dyn_string dsVal;
    for (int i = 1; i <= dynlen(dsNodeIds); i++)
    {
      dynAppend(dsVal, dsNodeIds[i]);
      if (i % iMaxDsNodeIds == 0)
      {
        dynAppend(ddsRetVal, dsVal);
        dynClear(dsVal);
      }
    }
    return ddsRetVal;
  }


  private void _callBack(const mapping& mUserData, const dyn_string &dsDpe, const dyn_anytype &daVal)
  {
    DebugFTN(DEBUG_FLAG, __FUNCTION__, mUserData, dsDpe, daVal);
    mapping mRet;
    for (int i = 1; i <= dynlen(dsDpe); i = i+4)
    {
      string sDpe = dpSubStr(dsDpe[i], DPSUB_SYS_DP) + ".";
      if (mappingHasKey(mUserData["dpes"], sDpe))
      {
        EBTagValue tagValue;
        tagValue.setSperateValues(daVal[i], daVal[i+1], daVal[i+2], daVal[i+3], sDpe);
        mRet[mUserData["dpes"][sDpe]] = tagValue;
      }
      else
      {
        sDpe = dpSubStr(dsDpe[i], DPSUB_SYS_DP_EL);
        if (mappingHasKey(mUserData["dpes"], sDpe))
        {
          EBTagValue tagValue;
          tagValue.setSperateValues(daVal[i], daVal[i+1], daVal[i+2], daVal[i+3], sDpe);
          mRet[mUserData["dpes"][sDpe]] = tagValue;
        }
      }
    }
    callFunction(mUserData["cb"], mRet, mUserData["userData"]);
  }

  private void _setupDataForConnect(function_ptr fpCallBack, const dyn_string &dsNodeIds, const anytype &aUserData,
                                   mapping &mUserData, dyn_string &dsDpes)
  {
    mapping mDataPoints;
    for (int i = 1; i <= dynlen(dsNodeIds); i++)
    {
      string sDpe = getDpForId(dsNodeIds[i]);
      dynAppend(dsDpes, sDpe + ":_online.._value");
      dynAppend(dsDpes, sDpe + ":_online.._stime");
      dynAppend(dsDpes, sDpe + ":_online.._status64");
      dynAppend(dsDpes, sDpe + ":_online.._manager");
      mDataPoints[sDpe] = dsNodeIds[i];
    }
    mUserData["cb"] = fpCallBack;
    mUserData["userData"] = aUserData;
    mUserData["dpes"] = mDataPoints;
  }

  private void _setupDataForMatadataConnect(function_ptr fpCallBack, const dyn_string &dsNodeId, const anytype &aUserData,
                                   mapping &mUserData, dyn_string &dsDpes)
  {
    dynAppend(dsDpes, "MetadataChanged.");
    mUserData["cb"] = fpCallBack;
    mUserData["userData"] = aUserData;
  }

  private void _callBackForMatadata(const mapping &mUserData, const dyn_string &dsDpe, const dyn_anytype &daVal)
  {
    DebugFTN(DEBUG_FLAG, __FUNCTION__, mUserData, dsDpe, daVal);
    mapping mRet = jsonDecode(daVal);
    if (this._filterNodesForCallback(mRet))
    {
      callFunction(mUserData["cb"], mRet, mUserData["userData"]);
    }
  }

  private bool _filterNodesForCallback(const mapping &mInput)
  {
    if (mappingHasKey(mInput, "NodeId"))
    {
      if (dynContains(this.dsNodeIds, mInput["NodeId"]) > 0)
      {
        return TRUE;
      }
    }
    return FALSE;
  }

  private static int _iNodenumber = 0;

  private static string _buildNodeName(const string &sNodeId, string sTagDisp = "",
                                       int sourceType = 0, int iLangNumber = getActiveLang())
  {
    langString lsDisplayNames;
    cnsGetDisplayNames(sNodeId, lsDisplayNames);
    string sDisplayName = lsDisplayNames[iLangNumber];

    string sNodeParent;
    cnsGetParent(sNodeId, sNodeParent);

    if (sourceType == (int)EBNodeType::STRUCT || sourceType == (int)EBNodeType::DP || sourceType == (int)EBNodeType::MAPPED || sourceType == (int)EBNodeType::MAPPEDSTRUCT)//struct, normal and mapped
    {
      sTagDisp = sDisplayName + "." + sTagDisp;
    }
    else if (sourceType == (int)EBNodeType::SUBSCRIBED && strlen(sNodeId) > strlen(cnsSubStr(sNodeId, CNSSUB_SYS | CNSSUB_VIEW | CNSSUB_ROOT ))) // Mapped Tag sub
    {
      sTagDisp = sDisplayName + "." + sTagDisp;
    }
    else // Mapped Tag root
    {
      sTagDisp = sDisplayName + "@" + sTagDisp;
    }

    string root = cnsSubStr(sNodeParent, CNSSUB_SYS | CNSSUB_VIEW);
    if (strlen(root) >= strlen(sNodeParent)) //check if the root node is reached already
    {
      if (sourceType == (int)EBNodeType::DP)
      {
        if (strpos(sTagDisp, ".")+1 == strlen(sTagDisp))
        {
          return substr(sTagDisp, 0, strlen(sTagDisp)-1);
        }
        else
        {
          return substr(sTagDisp, strpos(sTagDisp, ".")+1, strlen(sTagDisp)-strpos(sTagDisp, ".")-2); // only the last node is needed
        }
      }
      return substr(sTagDisp, 0, strlen(sTagDisp)-1); // cut out the . in the end of the Path
    }
    else
    {
      string s = _buildNodeName(sNodeParent, sTagDisp, sourceType, iLangNumber);
      return s;
    }
  }

  private static string _createDp(EBTagType eType)
  {
    string sDpType;

    switch (eType)
    {
      case EBTagType::BOOL:   sDpType = "EB_Bool";   break;
      case EBTagType::INT:    sDpType = "EB_Int";    break;
      case EBTagType::FLOAT:  sDpType = "EB_Float";  break;
      case EBTagType::UINT:   sDpType = "EB_Uint";   break;
      case EBTagType::STRING: sDpType = "EB_String"; break;
      case EBTagType::TIME:   sDpType = "EB_Time";   break;
      case EBTagType::LONG:   sDpType = "EB_Long";   break;
      case EBTagType::ULONG:  sDpType = "EB_Ulong";  break;
      case EBTagType::NONE:   sDpType = "EB_String"; break;     // Also return a dptype for undefined data types
      default:
        return "";
        break;
    }

    string sDpName = _getNewDpName(sDpType);

    if (!dpExists(sDpName))
    {
      int iErr = dpCreate(sDpName, sDpType);
      if (iErr != 0)
      {
        return "";
      }
    }

    if (eType == EBTagType::FLOAT)
    {
      dpSetFormat(sDpName + ".", "%0.2f");
    }

    return sDpName;
  }

  private static string _getNewDpName(const string &sDpType)
  {
    dyn_string dsNames = dpNames("EB_*", sDpType);
    dynSort(dsNames);
    int iNextIndex = 0;
    string sLastIndex;
    string sLastName;
    if (dynlen(dsNames) > 0)
    {
      sLastName = dsNames[dynlen(dsNames)];
      sLastIndex = substr(sLastName, strlen(sLastName)-4);
      iNextIndex = (int)sLastIndex;
    }

    iNextIndex++;
    string sNextIndexPostfix;
    sprintf(sNextIndexPostfix, "%04d", iNextIndex);
    return sDpType + sNextIndexPostfix;
  }

  private static string _getNewNodeId()
  {
    if (_iNodenumber == 0)
    {
      _iNodenumber = (long)getCurrentTime();
    }
    else
    {
      _iNodenumber = _iNodenumber + 1;
    }
    int iNextIndex = _iNodenumber;
    string sNextIndex = "Node_" + iNextIndex;
    return sNextIndex;
  }

  private static string _createNode(string &sParentId, const string &sNodeId, const langString &lsNodeName,
                                    EBNodeType nodeType = EBNodeType::STRUCT, string sDpName = "")
  {
    string sRetVal = "";
    string sSystemName = getSystemName();
    strreplace(sSystemName, ":", "");
    if (strpos(sParentId, sSystemName) == -1)
    {
      sParentId = sSystemName + sParentId;
    }
    if (sDpName == "")
    {
      cns_createTreeOrNode(sParentId, sNodeId, lsNodeName, "", (int)nodeType);
    }
    else
    {
      cns_createTreeOrNode(sParentId, sNodeId, lsNodeName, dpSubStr(sDpName, DPSUB_ALL), (int)nodeType);
    }
    int iViewSep = strpos(sParentId, SEP_VIEW);
    if (strlen(sParentId)-1 == iViewSep)
    {
      sRetVal = sParentId + sNodeId;
    }
    else
    {
      sRetVal = sParentId + SEP_PATH + sNodeId;
    }
    _setMetadataChanged(sRetVal, EBTagMetadataType::Create, sRetVal);
    return sRetVal;
  }

  private static bool _isNameOkForLang(const string &sName, const string &sParentNodeId, EBNodeType nodeType,
                                       int iLangNumber = CNS_SEARCH_ALL_LANGUAGES,
                                       string sViewName = "", string sNodeId = "",
                                       string sParent = "",
                                       bool bAllowDuplicateTagNames = FALSE)
  {
    if (hasUnallowedCharacters(sName))
    {
      return FALSE;
    }

    string sTagNameSearch = "*." + sName;
    int iType = CNS_DATATYPE_ALL_TYPES;
    dyn_string dsNodes;
    bool bIgnoreDuplicateTagNameCheck = FALSE;

    if (nodeType == EBNodeType::MAPPEDSTRUCT     || nodeType == EBNodeType::MAPPED ||    // Hack for datamapping app; TODO
        nodeType == EBNodeType::SUBSCRIBEDSTRUCT || nodeType == EBNodeType::SUBSCRIBED)  // Hack for subscribe app; TODO
    {
      if (cns_isView(sParentNodeId))
      {
        sTagNameSearch = "*:" + sName;
      }
      else if (cns_nodeExists(sParentNodeId))
      {
        langString lsPath;

        cnsGetDisplayPath(sParentNodeId, lsPath);

        sTagNameSearch = "*:" + cnsSubStr(lsPath, CNSSUB_PARENT, FALSE) + "." + sName;
      }
      else
      {
        sTagNameSearch = "*:" + sParentNodeId + "." + sName;
      }
    }
    else //tag and not device/app node
    {
      bIgnoreDuplicateTagNameCheck = bAllowDuplicateTagNames;
    }

    if (nodeType == EBNodeType::DP)
    {
      iType = (int)EBNodeType::DP;
    }

    if (!cnsGetNodesByName(sTagNameSearch, CNS_SEARCH_DISPLAY_NAME, iLangNumber, iType, dsNodes))
    {
      DebugFTN(DEBUG_FLAG, "No CNS things found");
      return FALSE;
    }

    return bIgnoreDuplicateTagNameCheck || _checkNodesForAcceptance(dsNodes, sViewName, sNodeId, sParent);
  }

  private static bool _checkNodesForAcceptance(const dyn_string &dsNodes, const string &sViewName,
                                               const string &sNodeId, const string &sParent)
  {
    if (dynlen(dsNodes) > 0)
    {
      if (sNodeId != "" && dynlen(dsNodes) == 1 && dsNodes[1] == sNodeId)
      {
        return TRUE;
      }

      if (sViewName != "")
      {
        return cnsSubStr(dsNodes[1], CNSSUB_VIEW, FALSE) == sViewName;
      }

      if (sParent != "")
      {
        dyn_string dsCnsParts = strsplit(dsNodes[1], SEP_PATH);
        string sPublishViewName = getConstFromPackage("Publish", "Api", "PUBLISH_CNS_VIEW_NAME");

        if (sPublishViewName != "")
        {
          dyn_string dsPublish = strsplit(dsNodes[1], SEP_VIEW);
          string sSystemName = strrtrim(getSystemName(), ":");

          return dsCnsParts[1] + SEP_PATH + dsCnsParts[2] == sParent || dsPublish[1] + ":" == sSystemName + "." + sPublishViewName;
        }

        return dsCnsParts[1] + SEP_PATH + dsCnsParts[2] == sParent;
      }

      return FALSE;
    }

    return TRUE;
  }

  private static void _setMetadataChanged(const string &sNodeId, EBTagMetadataType eType, const anytype &aNewValue)
  {
    mapping mJson = makeMapping("NodeId", sNodeId, "Type", eType, "Value", aNewValue);
    string sJson = jsonEncode(mJson);
    dpSet("MetadataChanged.", sJson);
  }

  /**
    @brief Gets the value a constant from a package if package is installed, otherwise the function return a empty string.
    @author Martin Schiefer
    @param sPackageName The name of the package.
    @param sFileName The name of the file in the package.
    @param sConstName The name of the constant.
    @return string The value of the constant or empty string.
   */
  private static string getConstFromPackage(const string &sPackageName, const string &sFileName, const string &sConstName)
  {
    string sValue = "";
    bool bFileExists = FALSE;
    string sSubdir = "EB_Package_" + sPackageName +"/";
    //check if file exists
    if (getPath(LIBS_REL_PATH + sSubdir, sFileName + ".ctc") != "")
    {
      bFileExists = TRUE;
    }
    else if (getPath(LIBS_REL_PATH + sSubdir, sFileName + ".ctl") != "")
    {
      bFileExists = TRUE;
    }

    //get the value of the constant
    if (bFileExists)
    {
      evalScript(sValue,
                 "#uses \"" + sSubdir + sFileName + "\"\n"
                 "string main()\n"
                 "{\n"
                 "  return " + sConstName + ";\n"
                 "}",
                 makeDynString());
    }
    return sValue;
  }

  string _sApp;
  dyn_string dsNodeIds;
  bool bFirst = TRUE;
  function_ptr fpCallBack = nullptr;
  anytype aUserData;

  bool bFirstMetadata = TRUE;
  function_ptr fpCallBackMetadata = nullptr;
  anytype aUserDataMetadata;
};

/**
 * @brief Defines the class Node.
 */
class Node
{
  private static int _iNodenumber = 0;
  public static string getNewNodeId()
  {
    if (_iNodenumber == 0)
    {
      _iNodenumber = (int)getCurrentTime();
    }
    else
    {
      _iNodenumber = _iNodenumber + 1;
    }
    int iNextIndex = _iNodenumber;
    string sNextIndex = "Node_" + iNextIndex;
    return sNextIndex;
  }
};
