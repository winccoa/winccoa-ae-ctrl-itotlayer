// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file scripts/libs/classes/EBXml.ctl
  @author Schiefer Martin
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlXml"
#uses "classes/EBTag"
#uses "EB_Package_Base/EB_Api_TagHandling"

//--------------------------------------------------------------------------------
// variables and constants

//--------------------------------------------------------------------------------
/**
 * @brief Defines the class EBXml.
 */
class EBXml
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  //------------------------------------------------------------------------------
  /**
   * @brief Default constructor.
   * @param sSearchKey Optional
   */
  public EBXml(string sSearchKey = "")
  {
    this.sSearchKey = sSearchKey;
  }

  /**
   * @brief reads the xml file and parse the data to a dyn_mapping
   * if the xml can't be parsed, the return value is false
   *
   * @param sParentNode the nodeId of the parent node
   * @param sFileName the filename of the xml file
   * @param dmData the dyn_mapping with the parsed data
   * @return bool true if the xml was parsed
   */
  public bool read(const string &sParentNode, const string &sFileName, dyn_mapping &dmData)
  {
    dynClear(dmData);
    dyn_mapping dmTempData;
    this.uiDocNum = xmlDocumentFromFile(sFileName, sErr, iErrLine, iErrColumn);
    if (this.uiDocNum == -1)
    {
      return FALSE;
    }
    this.travelTree(xmlFirstChild(this.uiDocNum), dmTempData);
    dmData = this.transform(sParentNode, dmTempData);
    return dynlen(dmData) > 0;
  }

  /**
   * @brief sets the mapping that describes the what key holds the information that are needed for import
   * @param mValues The mapping to set
   */
  public void setValuesMapping(mapping mValues = makeMapping("tag",     "Value",
                                                             "address", "addr",
                                                             "type",    "type"))
  {
    this.mValues = mValues;
  }

  /**
   * @brief sets the mapping that describes the what transformation function should be used for which key
   * @param mTransformFunctions The mapping to set
   */
  public void setTransfomationFunctions(mapping mTransformFunctions = makeMapping("tag", "_transformName",
                                                                                  "address", "_transformAddress",
                                                                                  "type", "_transformType"))
  {
    this.mTransformFunctions = mTransformFunctions;
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------

  protected mapping mValues = makeMapping("tag",     "Value",
                                          "address", "addr",
                                          "type",    "type");                            //!< Needed keys + info for import

  protected mapping mTransformFunctions = makeMapping("tag",     "_transformName",
                                                      "address", "_transformAddress",
                                                      "type",    "_transformType");      //!< Transformation function for each key

  /**
   * @brief Transforms the passed mapping with the set tranformation functions
   * @param sParentNode Node under which the data should be added
   * @param dmInput     Data to transform
   * @return Transformed data
   */
  protected dyn_mapping transform(const string &sParentNode, const dyn_mapping &dmInput)
  {
    dyn_mapping dmOutput;

    mapping mOutput;
    for (int i = 1; i <= dynlen(dmInput); i++)
    {
      mappingClear(mOutput);
      for (int j = 1; j <= mappinglen(this.mValues); j++)
      {
        string sInputMappingKey = mappingGetValue(this.mValues, j);
        if (mappingHasKey(dmInput[i], sInputMappingKey))
        {
          string sKey = mappingGetKey(this.mValues, j);
          string sFunction = "_noTransform";
          if (mappingHasKey(mTransformFunctions, sKey))
          {
            sFunction = mTransformFunctions[sKey];
          }
          if (sFunction == "_transformName")
          {
            string sNewValue;
            callFunction(sFunction, sParentNode, dmInput[i][sInputMappingKey], sNewValue);
            mOutput[sKey] = sNewValue;
          }
          else
          {
            mOutput[sKey] = callFunction(sFunction, dmInput[i][sInputMappingKey]);
          }
        }
      }
      if (mappinglen(mOutput) > 0)
      {
        dynAppend(dmOutput, mOutput);
      }
    }

    return dmOutput;
  }

  /**
   * @brief Returns the passed string without doing some transformation
   * @param sInput Data to pass back
   * @return Input data
   */
  protected string _noTransform(const string &sInput)
  {
    return sInput;
  }

  /**
   * @brief Transforms the passed tag name to a valid name
   * @param sParentNode Node under which the tag should be added
   * @param sValue      Tag name to transform to a valid name
   * @param sNewName    Transformed tag name
   * @return TRUE if the returned tag name is valid, otherwise FALSE
   */
  protected bool _transformName(const string &sParentNode, const string &sValue, string &sNewName)
  {
    EBTag ebTag;
    bool bRet = ebTag.isNameOk(sValue, sParentNode, EBNodeType::DP);
    sNewName = sValue;
    while (!bRet)
    {
      sNewName = _getNextTagName(sNewName);
      bRet = ebTag.isNameOk(sNewName, sParentNode, EBNodeType::DP);
    }
    return bRet;
  }

  /**
   * @brief Returns the next tag name from the passed tag name
   * @param sTagName    Tag name to get the next one from
   * @return Next tag name
   */
  protected string _getNextTagName(const string &sTagName)
  {
    string sNewTagName;
    string sPostfix = strrtrim(sTagName, "0123456789");// removes all digits until first non digit occurs from the right
    string sLastTagNumber = sTagName;
    strreplace(sLastTagNumber, sPostfix, "");
    int iLastTagNumber = (int)sLastTagNumber;
    string sFormatString;
    if (strlen((string)iLastTagNumber) != strlen(sLastTagNumber))
    {
      sFormatString = "%0" + strlen(sLastTagNumber) + "d";
    }
    else
    {
      sFormatString = "%d";
    }
    sprintf(sNewTagName, "%s" + sFormatString, sPostfix, iLastTagNumber + 1);
    return sNewTagName;
  }

  /**
   * @brief Transforms the passed address
   * @details No idea why the first byte is removed
   * @param sInput Address to transform
   * @return Transformed address
   */
  protected string _transformAddress(const string &sInput)
  {
    return substr(sInput, 1);
  }

  /**
   * @brief Transforms the passed type
   * @param sInput Type to transform
   * @return Transformed type
   */
  protected string _transformType(const string &sInput)
  {
    string sOutput = strtolower(sInput);
    if (sOutput == "byte")
    {
      sOutput = "uint";
    }
    else if (sOutput == "word")
    {
      sOutput = "uint";
    }
    else if (sOutput == "dword")
    {
      sOutput = "int";
    }

    if (dynContains(EB_getTagTypes(), sOutput) < 1)
    {
      sOutput = "string";
    }
    return sOutput;
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  string sSearchKey;
  string sErr;
  int iErrLine;
  int iErrColumn;
  uint uiDocNum;

  void travelTree(int iNode, dyn_mapping &dmData)
  {
    if (iNode != -1)
    {
      if (xmlNodeType(this.uiDocNum, iNode) == XML_ELEMENT_NODE  &&
          xmlNodeName(this.uiDocNum, iNode) == this.sSearchKey)
      {
        mapping mData = xmlElementAttributes(this.uiDocNum, iNode);
        int iChild = xmlFirstChild(this.uiDocNum, iNode);
        if (xmlNodeType(this.uiDocNum, iChild) == XML_TEXT_NODE)
        {
          mData["Value"] = xmlNodeValue(this.uiDocNum, iChild);
        }
        dynAppend(dmData, mData);
      }

      travelTree(xmlFirstChild(this.uiDocNum, iNode), dmData);
      travelTree(xmlNextSibling(this.uiDocNum, iNode), dmData);
    }
  }
};
