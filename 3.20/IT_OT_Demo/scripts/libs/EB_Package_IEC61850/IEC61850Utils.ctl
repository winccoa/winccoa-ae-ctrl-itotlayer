// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
 * @file scripts/libs/EB_Package_IEC61850/IEC61850Utils.ctl
 * @brief Contains various useful functions for IEC61850.
 */

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "CtrlXml"
#uses "iec61850_plugin"

/**
 * @brief This is the utility class for IEC61850.
 */
class IEC61850Utils
{
  public static string readAddressFromScl(const string &sSclContent, const string &sApName, const string &sIedName)
  {
    string sResult;
    string sError;
    int iLine;
    int iColumn;
    int iXmlDocument = xmlDocumentFromString(sSclContent, sError, iLine, iColumn);
    dyn_dyn_string ddsIedList;

    if (iXmlDocument != -1)
    {
      int iFirstChild = xmlFirstChild(iXmlDocument);

      if (iFirstChild != -1)
      {
        int iNode;

        // Get XML entry point and read the IED info
        if (iec61850_browse_readXML_getChildNodeID(iXmlDocument, iFirstChild, iNode, IEC61850_XMLTEXT_SCL) &&
            iec61850_browse_readXML_getIEDsInfo(iNode, iXmlDocument, ddsIedList))
        {
          for (int i = 1; i <= dynlen(ddsIedList) && sResult == ""; i++)
          {
            if (sIedName == ddsIedList[i][1] && sApName == ddsIedList[i][2])
            {
              sResult = iec61850_getParamFromIedInfo(ddsIedList[i], IEC61850_XMLTEXT_IPADDRESS);
            }
          }
        }
      }
    }

    xmlCloseDocument(iXmlDocument);

    DebugTN(__FUNCTION__ + "(..., " + sApName + ", " + sIedName + ") Returning: " + sResult);

    return sResult;
  }

  public static dyn_string readRCBsFromScl(const string &sSclContent, const string &sApName, const string &sIedName, const string &sClientName)
  {
    dyn_string dsResult;
    string sError;
    int iLine;
    int iColumn;
    int iXmlDocument = xmlDocumentFromString(sSclContent, sError, iLine, iColumn);

    if (iXmlDocument != -1)
    {
      int iFirstChild = xmlFirstChild(iXmlDocument);

      if (iFirstChild != -1)
      {
        iec61850_getClientIedList(sIedName, sApName, iXmlDocument, iFirstChild, sClientName, dsResult);

        for (int i = 1; i <= dynlen(dsResult); i++)
        {
          dsResult[i] = strsplit(dsResult[i], "|")[1];
        }
      }
    }

    xmlCloseDocument(iXmlDocument);

    DebugTN(__FUNCTION__ + "(..., " + sApName + ", " + sIedName + ", " + sClientName + ") Returning:", dsResult);

    return dsResult;
  }

  public static bool createRCBs(const string &sConnectionDp, const dyn_string &dsRCBs)
  {
    bool bResult = TRUE;

    for (int i = 1; i <= dynlen(dsRCBs) && bResult; i++)
    {
      // Convert RCB name to data point name
      string sRcbDp = iec61850_getRcbDpName(sConnectionDp, dsRCBs[i]);

      // create the internal data point
      if (iec61850_createRcbDp(sConnectionDp, dsRCBs[i], "A"))
      {
        // check/wait for driver to initialize it
        bResult &= iec61850_checkDriverResponseCreateRcb(sRcbDp, TRUE);
      }
    }

    return bResult;
  }

  public static mapping readDataSets(const string &sConnectionDp)
  {
    mapping mResult;

    // Get all configured RCBs of the connection
    dyn_string dsRCBs = getRcbsOfConnection(sConnectionDp);

    for (int i = 1; i <= dynlen(dsRCBs); i++)
    {
      string sRcbDp = iec61850_getRcbDpName(sConnectionDp, dsRCBs[i]);

      dyn_string dsTags = readDataSetTagsForRcb(sConnectionDp, sRcbDp);

      for (int j = 1; j <= dynlen(dsTags); j++)
      {
        mResult[dsTags[j]] = "";
      }
    }

    return mResult;
  }

  public static dyn_mapping getBrowsingStucture(const string &sConnectionDp)
  {
    dyn_string dsTagList;
    dpGet(sConnectionDp + IEC61850_DPE_IDP_TAGSLIST, dsTagList);
    mapping mTagToType;
    for(int i=1; i<=dynlen(dsTagList); i++)
    {
      dyn_string dsSplit = strsplit(dsTagList[i], "|");
      mTagToType[dsSplit[1]] = dsSplit[2];
    }

    dyn_anytype daFinalTagsList, daIec61850TreeObjects;
    // List Tag lists for tree view
    iec61850_treeView_getFinalTagsList(dsTagList, daFinalTagsList);
    iec61850_treeView_readIEC61850TagsNew(daFinalTagsList, daIec61850TreeObjects);

   dyn_mapping dmResult;
//    for (int i=1; i<=dynlen(daIec61850TreeObjects); i++)
   if(dynlen(daIec61850TreeObjects) == 1)
   {
     getTreeMapping(daIec61850TreeObjects[1], dmResult[1], mTagToType, "");
   }
    return dmResult;
  }


  private static void getTreeMapping(const anytype &aIec61850TreeObjects, mapping &mResult, const mapping &mTagToType, const string &sParentNodeName)
  {
    int iChildrenNum = aIec61850TreeObjects.getNumOfChildren();
    string sMyId = aIec61850TreeObjects.getId();
    mResult["address"] = sMyId;
    string sNodeName = sMyId;
    strreplace(sNodeName, "/", ".");
    strreplace(sNodeName, "$", ".");
    mResult["id"] = sNodeName;
    string sNodePath = sParentNodeName != "" ? substr(sMyId, strlen(sParentNodeName)+1) : sNodeName;
    mResult["nodeName"] = sNodePath;
    mResult["name"] = aIec61850TreeObjects.getDisplayName();
    mResult["type"] = mappingHasKey(mTagToType, sMyId) ? mTagToType[sMyId] : "node";//aIec61850TreeObjects.getElementType();
    mResult["extra"]= aIec61850TreeObjects.getCdcType();

    if (iChildrenNum>0)
    {
      mResult["children"] = makeDynMapping();
      for (int i=1; i<=iChildrenNum; i++)
      {
        mResult["children"][i]["parentId"] = sNodeName;
        getTreeMapping(aIec61850TreeObjects.getChild(i), mResult["children"][i], mTagToType, sNodeName);
      }
    }
  }


  /**
   * @brief Returns all RCBs available for this connection from the internal data point of the connection
   * @param sConnectionDp    Connection data point
   * @return RCBs of this connection
   */
  public static dyn_string getRcbsOfConnection(const string &sConnectionDp)
  {
    dyn_string dsResult;

    dpGet(sConnectionDp + IEC61850_DPE_IDP_RCB_NAMES, dsResult);

    for (int i = dynlen(dsResult); i > 0; i--)
    {
      string sRcb = dsResult[i];

      if (strpos(sRcb, "|A", strlen(sRcb) - 2) < 0)
      {
        dynRemove(dsResult, i);
      }
      else
      {
        dsResult[i] = substr(sRcb, 0, strlen(sRcb) - 2);
      }
    }

    return dsResult;
  }

  /**
   * @brief Returns the list of tags handled by the passed RCB
   * @param sConnectionDpName  The WinCC OA data point name of the connection which contains the RCB
   * @param sRcbDp             RCB data point which handles the data set
   * @return                   List of tags handled by the RCB
   */
  private static dyn_string readDataSetTagsForRcb(const string &sConnectionDp, const string &sRcbDp)
  {
    dyn_string dsResult;

    // Get the data set name from the internal data point of the RCB
    string sDataSetName;

    if (dpExists(sRcbDp))
    {
      dpGet(sRcbDp + IEC61850_DPE_RCB_DATSET, sDataSetName);

      dyn_string dsDataSetAttributesList;
      iec61850_Dataset_getDatasetAttributesList(strltrim(sConnectionDp, "_"), sDataSetName, dsResult);

      // remove q and t tags since they are not engineered
      removeQualityAndTimeTags(dsResult);
    }

    return dsResult;
  }

  /**
   * @brief Removes time and quality tags
   * @param dsTagsList  List of tags
   */
  private static void removeQualityAndTimeTags(dyn_string &dsTagsList)
  {
    for (int i = dynlen(dsTagsList); i > 0; i--)
    {
      // Check the last 2 characters
      string sTag = substr(dsTagsList[i], strlen(dsTagsList[i]) - 2);

      if (sTag == "$t" || sTag == "$q")
      {
        dynRemove(dsTagsList, i);
      }
    }
  }
};
