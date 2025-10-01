// $License: NOLICENSE

/**
 * @file scripts/libs/classes/EBCsv.ctl
 * @brief Contains the EBCsv class, which provides im/export functionality of tags.
 */

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "csv"
#uses "json"
#uses "classes/EBTag"
#uses "EB_Package_Base/EB_Api_TagHandling"

//--------------------------------------------------------------------------------
// declare variables and constants

/**
 * @brief Defines the enum EBCsvType.
 */
enum EBCsvType
{
  Flat,
  Hierarchy
};

//--------------------------------------------------------------------------------
/*!
 * @brief Handler for CsvImporter
 *
 * @author Martin Schiefer
 */
class EBCsv
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  //------------------------------------------------------------------------------
  /**
   * @brief Default constructor
   * @param cDelimiter  Delimiter for the values
   * @param eType       File type (flat or hierarchical)
   */
  public EBCsv(char cDelimiter = ';', EBCsvType eType = EBCsvType::Flat)
  {
    this.cDelimiter = cDelimiter;
    this.eType = eType;
  }

  /**
   * @brief reads the csv file and parse the data to a dyn_mapping
   * if a line can't be parsed, the linenumber is added to the return value
   *
   * @param sParentNode the nodeId of the parent node
   * @param sFileName the filename of the csv file
   * @param dmData the dyn_mapping with the parsed data
   * @return dyn_int the linenumbers that can't be parsed
   */
  public dyn_int read(const string &sParentNode, const string &sFileName, dyn_mapping &dmData)
  {
    dynClear(dmData);
    if (this.eType == EBCsvType::Flat)
    {
      return _readFlat(sParentNode, sFileName, dmData);
    }
    else
    {
      return _readHierarchy(sParentNode, sFileName, dmData);
    }
  }

  /**
   * @brief writes a dyn_mapping to a csv file
   *
   * @param sFileName the filename of the csv file
   * @param dmData the dyn_mapping with the data to write into the file
   * @return errCode
   * \li 0 success
   * \li -1 file does not exists
   * \li -2 can nt open file in wb+ mode
   * \li -3 content can not be writen to file
   */
  public int write(string sFileName,const dyn_mapping &dmData)
  {
    fclose(fopen(sFileName, "w")); //create file
    if (this.eType == EBCsvType::Flat)
    {
      return _writeFlat(sFileName, dmData);
    }
    else
    {
      return _writeHierarchy(sFileName, dmData);
    }
  }

  /**
   * @brief sets the neededColumns
   * @param dsNeededFlatColumns The columns to set
   */
  public void setNeededColumns(dyn_string dsNeededFlatColumns = makeDynString("active",
                                                 "tag",
                                                 "address",
                                                 "type",
                                                 "rate",
                                                 "min",
                                                 "max",
                                                 "archive",
                                                 "unit"))
  {
    this.dsNeededFlatColumns = dsNeededFlatColumns;

    for (int i = 1; i <= dynlen(this.dsNeededFlatColumns); i++)
    {
      if (!mappingHasKey(this.mCheckFunctions, this.dsNeededFlatColumns[i]))
      {
        this.mCheckFunctions[this.dsNeededFlatColumns[i]] = "_checkString";
      }
    }
  }

  /**
   * @brief Sets the optional columns
   * @param dsOptionalFlatColumns The columns to set
   */
  public void setOptionalColumns(dyn_string dsOptionalFlatColumns = makeDynString("subindex"))
  {
    this.dsOptionalFlatColumns = dsOptionalFlatColumns;

    for (int i = 1; i <= dynlen(this.dsOptionalFlatColumns); i++)
    {
      if (!mappingHasKey(this.mCheckFunctions, this.dsOptionalFlatColumns[i]))
      {
        this.mCheckFunctions[this.dsOptionalFlatColumns[i]] = "_checkString";
      }
    }
  }

  /**
   * @brief Sets the check function for the specified column
   * @param sColumn          Column to check by the specified function
   * @param sCheckFunction   Function to check if the column content is valid
   */
  public void changeCheckFunction(const string &sColumn, const string &sCheckFunction)
  {
    this.mCheckFunctions[sColumn] = sCheckFunction;
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------
  protected char cDelimiter;                                                   //!< Values are separated by this character
  protected EBCsvType eType;                                                   //!< File can be one of this enum values (flat or hierarchical)
  protected dyn_string dsOptionalFlatColumns = makeDynString("subindex");      //!< Default optional columns (these columns are used by driver apps)
  protected dyn_string dsNeededFlatColumns = makeDynString("active",
                                                           "tag",
                                                           "address",
                                                           "type",
                                                           "rate",
                                                           "min",
                                                           "max",
                                                           "archive",
                                                           "unit");            //!< Default mandatory columns (these columns are used by driver apps)

  protected mapping mCheckFunctions = makeMapping("active",   "_checkBool",
                                                  "tag",      "_checkName",
                                                  "address",  "_checkAddress",
                                                  "type",     "_checkType",
                                                  "rate",     "_checkRate",
                                                  "min",      "_checkMin",
                                                  "max",      "_checkMax",
                                                  "archive",  "_checkBool",
                                                  "unit",     "_checkUnit",
                                                  "subindex", "_checkUint");   //!< Default check functions

  /**
   * @brief Writes the hierarchical data to the specified csv file
   * @param sFileName   Target file
   * @param dmData      Data to write
   * @return 0 in case of success
   */
  protected int _writeHierarchy(const string &sFileName, const dyn_mapping &dmData)
  {
    return -3;
  }

  /**
   * @brief Writes the data to the specified csv file
   * @param sFileName   Target file
   * @param dmData      Data to write
   * @return 0 in case of success
   */
  protected int _writeFlat(const string &sFileName, const dyn_mapping &dmData)
  {
    dyn_dyn_string dsCsvData;
    for (int i = 1; i <= dynlen(dmData); i++)
    {
      dynAppend(dsCsvData, _writeFlatLine(dmData[i]));
    }
    return csvFileWrite(sFileName, dsCsvData, cDelimiter);
  }

  /**
   * @brief Returns the passed data as a dyn_string
   * @param mLine  Data to convert
   * @return Data converted to lines
   */
  protected dyn_string _writeFlatLine(const mapping &mLine)
  {
    dyn_string dsLine;

    for (int i = 1; i <= dynlen(dsNeededFlatColumns) + dynlen(dsOptionalFlatColumns); i++)
    {
      string sKey = i <= dynlen(dsNeededFlatColumns) ? dsNeededFlatColumns[i] : dsOptionalFlatColumns[i - dynlen(dsNeededFlatColumns)];

      if (mappingHasKey(mLine, sKey))
      {
        dynAppend(dsLine, mLine[sKey]);
      }
    }

    return dsLine;
  }

  /**
   * @brief Returns data from the specified flat CSV file
   * @param sParentNode Node under which the data should be added
   * @param sFileName   File to read
   * @param dmData      Read data
   * @return List of invalid lines
   */
  protected dyn_int _readFlat(const string &sParentNode, const string &sFileName, dyn_mapping &dmData)
  {
    dyn_dyn_anytype ddaCsvData;
    dyn_int diErrorLines;
    mapping mLine;
    int rc = csvFileRead(sFileName, ddaCsvData, cDelimiter);

    if (rc == 0)
    {
      for (int i = 1; i <= dynlen(ddaCsvData); ++i) // iterate lines
      {
        mappingClear(mLine);

        if (_checkLine(sParentNode, ddaCsvData[i], mLine))
        {
          dynAppend(dmData, mLine);
        }
        else
        {
          dynAppend(diErrorLines, i);
        }
      }
    }

    return diErrorLines;
  }

  /**
   * @brief Returns data from the specified hierarchical CSV file
   * @param sParentNode Node under which the data should be added
   * @param sFileName   File to read
   * @param dmData      Read data
   * @return List of invalid lines
   */
  protected dyn_int _readHierarchy(const string &sParentNode, const string &sFileName, dyn_mapping &dmData)
  {
    return makeDynInt();
  }

  /**
   * @brief Checks if the passed line data is valid
   * @param sParentNode Node under which the data should be added
   * @param dsLineData  Values of the line
   * @param mOutput     Possible converted data
   * @return TRUE if line is valid, otherwise FALSE
   */
  protected bool _checkLine(const string &sParentNode, const dyn_string &dsLineData, mapping &mOutput)
  {
    for (int i = 1; i <= dynlen(dsNeededFlatColumns) + dynlen(dsOptionalFlatColumns); i++)
    {
      bool   bValue = FALSE;
      uint   uValue = 0;
      string sKey      = i <= dynlen(dsNeededFlatColumns) ? dsNeededFlatColumns[i] : dsOptionalFlatColumns[i - dynlen(dsNeededFlatColumns)];
      string sValue    = _getDataByName(sKey, dsLineData);
      string sFunction = mCheckFunctions[sKey];
      bool   bRet      = dynlen(dsLineData) < i;

      if (sFunction == "_checkBool")
      {
        bRet |= callFunction(sFunction, sValue, bValue);
      }
      else if (sFunction == "_checkUint")
      {
        bRet |= callFunction(sFunction, sValue, uValue);
      }
      else if (sFunction == "_checkName")
      {
        if (json_isValid(sValue))
        {
          sFunction = "_checkJson";
        }
        string sNewValue;
        bRet |= callFunction(sFunction, sParentNode, sValue, sNewValue);
        sValue = sNewValue;
      }
      else
      {
        bRet |= callFunction(sFunction, sValue);
      }
      if (bRet)
      {
        if (sFunction == "_checkBool")
        {
          mOutput[sKey] = bValue;
        }
        else if (sFunction == "_checkUint")
        {
          mOutput[sKey] = uValue;
        }
        else
        {
          mOutput[sKey] = sValue;
        }
      }
    }

    return mappinglen(mOutput) == dynlen(dsNeededFlatColumns) + dynlen(dsOptionalFlatColumns);
  }

  /**
   * @brief Returns the value from the specified column
   * @param sName       Column name to get the value from
   * @param dsLineData  Values of the line
   * @return The value or empty string if the column is not found or optional
   */
  protected string _getDataByName(const string &sName, const dyn_string &dsLineData)
  {
    string sResult;
    int iPos = dynContains(dsNeededFlatColumns, sName);

    if (0 < iPos && iPos <= dynlen(dsLineData))
    {
      sResult = dsLineData[iPos];
    }
    else
    {
      iPos = dynContains(dsOptionalFlatColumns, sName);

      if (0 < iPos && iPos + dynlen(dsNeededFlatColumns) <= dynlen(dsLineData))
      {
        sResult = dsLineData[iPos + dynlen(dsNeededFlatColumns)];
      }
    }

    return sResult;
  }

  /**
   * @brief Checks if the passed data is a valid boolean
   * @param sValue Boolean value as string
   * @param bValue Converted boolean value
   * @return TRUE if boolean is valid, otherwise FALSE
   */
  protected bool _checkBool(const string &sValue, bool &bValue)
  {
    bool bRet = FALSE;
    if (patternMatch("[Tt][Rr][Uu][Ee]", sValue))
    {
      bValue = TRUE;
      bRet = TRUE;
    }
    if (patternMatch("[Ff][Aa][Ll][Ss][Ee]", sValue))
    {
      bValue = FALSE;
      bRet = TRUE;
    }
    return bRet;
  }

  /**
   * @brief Checks if the passed data is a valid unsigned integer
   * @param sValue Unsigned integer value as string
   * @param uValue Converted unsigned integer value
   * @return TRUE if value is valid, otherwise FALSE
   */
  protected bool _checkUint(const string &sValue, uint &uValue)
  {
    bool bRet = regexpIndex("^\\d+$", sValue) == 0;

    uValue = sValue;

    return bRet;
  }

  /**
   * @brief Checks if the passed tag name is valid
   * @param sParentNode Node under which the data should be added
   * @param lsValue     Tag name to check
   * @param lsNewName   Possible newly generated tag name
   * @return TRUE if the passed back tag name is valid, otherwise FALSE
   */
  protected bool _checkName(const string &sParentNode, const langString &lsValue, langString &lsNewName)
  {
    bool bRet = EBTag::isNameOk(lsValue, sParentNode, EBNodeType::DP);
    lsNewName = lsValue;
    while (!bRet)
    {
      lsNewName = _getNextTagName(lsNewName);
      bRet = EBTag::isNameOk(lsNewName, sParentNode, EBNodeType::DP);
    }
    return bRet;
  }

  /**
   * @brief Checks if the passed json encoded langString contains valid tag names
   * @param sParentNode Node under which the data should be added
   * @param sValue      Json encoded langString
   * @param sNewName    Possible newly generated tag name json encoded
   * @return TRUE if json encoded langString has now valid tag names, otherwise FALSE
   */
  protected bool _checkJson(const string &sParentNode, const string &sValue, string &sNewName)
  {
    bool bRet = FALSE;

    if (json_isValid(sValue))
    {
      langString lsValue = EB_mappingToLangString(jsonDecode(sValue));
      langString lsNewName = lsValue;

      bRet = EBTag::isNameOk(lsValue, sParentNode, EBNodeType::DP);

      while (!bRet)
      {
        lsNewName = _getNextTagName(lsNewName);
        bRet = EBTag::isNameOk(lsNewName, sParentNode, EBNodeType::DP);
      }

      sNewName = jsonEncode(EB_LangStringToMapping(lsNewName));
    }

    return bRet;
  }

  /**
   * @brief Returns the next tag name from the passed tag name
   * @param lsTagName   Tag name to get the next one from
   * @return Next tag name
   */
  protected langString _getNextTagName(const langString &lsTagName)
  {
    langString lsNewTagName;

    for (int i = 0; i < getNoOfLangs(); i++)
    {
      string sPostfix = strrtrim(lsTagName[i], "0123456789");// removes all digits until first non digit occurs from the right
      string sLastTagNumber = lsTagName[i];
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

      sprintf(sLastTagNumber, "%s" + sFormatString, sPostfix, iLastTagNumber + 1);

      setLangString(lsNewTagName, i, sLastTagNumber);
    }

    return lsNewTagName;
  }

  /**
   * @brief Checks if the passed address is valid
   * @param sValue Address to check
   * @return TRUE if address is valid, otherwise FALSE
   */
  protected bool _checkAddress(const string &sValue)
  {
    return TRUE;
  }

  /**
   * @brief Checks if the passed type is valid
   * @param sValue Type to check
   * @return TRUE if type is valid, otherwise FALSE
   */
  protected bool _checkType(const string &sValue)
  {
    return dynContains(EB_getTagTypes(), sValue) > 0;
  }

  /**
   * @brief Checks if the passed poll rate is valid
   * @param sValue Poll rate to check
   * @return TRUE if poll rate is valid, otherwise FALSE
   */
  protected bool _checkRate(const string &sValue)
  {
    return dynContains(EB_getTagRates(), sValue) > 0;
  }

  /**
   * @brief Checks if the passed minimum value is valid
   * @param sValue Minimum value to check
   * @return TRUE if minimum value is valid, otherwise FALSE
   */
  protected bool _checkMin(const string &sValue)
  {
    return TRUE;
  }

  /**
   * @brief Checks if the passed maximum value is valid
   * @param sValue Maximum value to check
   * @return TRUE if maximum value is valid, otherwise FALSE
   */
  protected bool _checkMax(const string &sValue)
  {
    return TRUE;
  }

  /**
   * @brief Checks if the passed unit is valid
   * @param sValue Unit to check
   * @return TRUE if unit is valid, otherwise FALSE
   */
  protected bool _checkUnit(const string &sValue)
  {
    return TRUE;
  }

  /**
   * @brief Checks if the passed string is valid
   * @param sValue String to check
   * @return TRUE if string is valid, otherwise FALSE
   */
  protected bool _checkString(const string &sValue)
  {
    return TRUE;
  }
};
