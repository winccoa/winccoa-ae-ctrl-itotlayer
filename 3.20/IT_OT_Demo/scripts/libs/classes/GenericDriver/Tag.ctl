// $License: NOLICENSE

/**
 * @file scripts/libs/classes/GenericDriver/Tag.ctl
 */

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "EB_Package_Base/EB_Api"
#uses "classes/EBTag"
#uses "classes/GenericDriver/Common"

//--------------------------------------------------------------------------------
// declare variables and constants

//--------------------------------------------------------------------------------
/*!
 * @brief Handler for GenericDriverTag
 *
 * @details functions that need to be implemented:
 * \li public void createTag(int iDeviceId, string sDeviceNodeId, const string &sTagName, EBTagType tagType, const string &sAddress,
                        const mixed &miInput, string sRefreshRate = "1s", int iReadWrite = 1, mixed mMin = 0, mixed mMax = 0 , langString lsUnit = "")
 * \li public void readTableRow(const shape &shTable, int rowIndex, int iDeviceId, const string &sDeviceNodeId)
 * \li public GenericDriverTag fromJson(const string &sJson, string sDeviceNodeId = "", bool bRestore = FALSE)
 * \li public mapping writeToMapping(bool bWithNodeId = TRUE)
 * \li public string setupReferenceString()
 * \li public void setTransformation()
 *
 * default members:
 * \li DeviceId
 * \li DeviceNodeId
 * \li NodeId
 * \li TagName
 * \li DataType
 * \li Address
 * \li Refreshrate
 * \li ReadWrite
 * \li Min
 * \li Max
 * \li Unit
 * \li Active
 * \li Archive
 * \li Transformation
 *
 * @author Martin Schiefer
 */
class GenericDriverTag
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  //------------------------------------------------------------------------------
  /**
   * @brief c-tor
   * @param spCommon the shared_ptr for the GenericDriverCommon object
   */
  public GenericDriverTag(shared_ptr<GenericDriverCommon> spCommon = nullptr)
  {
    this.spCommon = spCommon;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the tagname
   * @return string the tagname
   */
  public langString getTagName()
  {
    return this.lsTagName;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the tagname
   * @param lsTagName the name to set
   */
  public void setTagName(const langString &lsTagName)
  {
    if (lsTagName != this.lsTagName)
    {
      this.bHasChanged = TRUE;
      this.lsTagName = lsTagName;
      this.bTagNameChanged = TRUE;
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the description
   * @return string the description
   */
  public langString getDescription()
  {
    return this.lsDescription;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the description
   * @param lsDescription the description to set
   */
  public void setDescription(const langString &lsDescription)
  {
    if (lsDescription != this.lsDescription)
    {
      this.lsDescription = lsDescription;
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the tagtype
   * @return EBTagType the tagtype
   */
  public EBTagType getTagType()
  {
    return this.tagType;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the tagtype
   * @param eType the tagtype to set
   */
  public void setTagType(EBTagType eType)
  {
    if (eType != this.tagType)
    {
      this.bHasChanged = TRUE;
      this.tagType = eType;
      this.bDatatypeChanged = TRUE;
      this.bAddressChanged = TRUE;
      this.setTransformation();
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the address
   * @return string the address
   */
  public string getAddress()
  {
    return this.sAddress;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the address
   * @param sAddress the address to set
   */
  public void setAddress(const string &sAddress)
  {
    if (sAddress != this.sAddress)
    {
      this.forceNewAddress(getAddressDirection());
      this.sAddress = sAddress;
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the internal variables so that createTagDp writes the address
   * @param iAddressDirection address direction (default: input polling)
   */
  public void forceNewAddress(int iAddressDirection = DPATTR_ADDR_MODE_INPUT_POLL)
  {
    this.iAddressDirection = iAddressDirection;
    this.bHasChanged       = TRUE;
    this.bAddressChanged   = TRUE;
    this.bDoneSingleQuery  = FALSE;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the unit
   * @return langString the unit
   */
  public langString getUnit()
  {
    return this.lsUnit;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the unit
   * @param lsUnit the unit to set
   */
  public void setUnit(const langString &lsUnit)
  {
    if (lsUnit != this.lsUnit)
    {
      this.bHasChanged = TRUE;
      this.lsUnit = lsUnit;
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the refreshrate
   * @return string the refreshrate
   */
  public string getRefreshRate()
  {
    return this.sRefreshRate;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the refreshrate
   * @param sRefreshRate the refreshrate to set
   */
  public void setRefreshRate(const string &sRefreshRate)
  {
    if (sRefreshRate != this.sRefreshRate)
    {
      this.bHasChanged = TRUE;
      this.sRefreshRate = sRefreshRate;
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets if the tag is active
   * @return bool true if archived
   */
  public bool getActive()
  {
    return this.bActive;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the active
   * @param bActive true if tag should be active
   */
  public void setActive(bool bActive)
  {
    this.bActive = bActive;
    this.bActiveHasChanged = TRUE;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets if the tag is active
   * @return bool true if archived
   */
  public bool getArchive()
  {
    return this.bArchive;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the archive
   * @param bArchive true if tag should be archived
   */
  public void setArchive(bool bArchive)
  {
    this.bArchive = bArchive;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the minvalue
   * @return mixed the minvalue
   */
  public mixed getMin()
  {
    return this.mMin;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the minvalue of the range config
   * @param mMin the minvalue to set
   */
  public void setMin(mixed mMin)
  {
    if (mMin != this.mMin)
    {
      this.bHasChanged = TRUE;
      this.mMin = (float) mMin;
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the maxvalue
   * @return mixed the maxvalue
   */
  public mixed getMax()
  {
    return this.mMax;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the maxvalue of the range config
   * @param mMax the maxvalue to set
   */
  public void setMax(mixed mMax)
  {
    if (mMax != this.mMax)
    {
      this.bHasChanged = TRUE;
      this.mMax = (float) mMax;
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the format string
   * @return string the format string
   */
  public string getFormat()
  {
    return this.sFormat;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the format string
   * @param sFormat the format string to set
   */
  public void setFormat(const string &sFormat)
  {
    this.sFormat = sFormat;

    if (this.sFormat == "" && this.tagType == EBTagType::FLOAT)
    {
      this.sFormat = "%0.2f";
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns the subindex
   * @return Subindex
   */
  public uint getSubindex()
  {
    return this.uSubindex;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Sets the subindex
   * @param uSubindex   subindex to set
   */
  public void setSubindex(uint uSubindex)
  {
    if (this.uSubindex != uSubindex)
    {
      this.forceNewAddress(getAddressDirection());
      this.uSubindex = uSubindex;
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief checks if the setted range configuration is ok
   * @return bool true if the configuration is ok
   */
  public bool isRangeConfigOk()
  {
    return ((this.mMin == 0 && this.mMax == 0) || (this.mMin < this.mMax));
  }

  //------------------------------------------------------------------------------
  /**
   * @brief checks if the given tagname is ok
   * @param lsTagName the name to check
   * @return bool true if the name is ok
   */
  public bool isTagNameValid(const langString &lsTagName)
  {
    return EB_isTagNameValid(lsTagName, this.sDeviceNodeId, spCommon.getNodeType());
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the nodeId
   * @return string the nodeId
   */
  public string getNodeId()
  {
    return this.sNodeId;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the invalid bit
   * @param bValue the invalid bit to set
   */
  public void setInvalid(bool bValue)
  {
    string sDpe = EB_getDatapointForTagId(this.sNodeId);
    if (!bValue)
    {
      dpSetWait(sDpe + ":_original.._exp_inv", bValue);
    }
    else
    {
      dpSetWait(sDpe + ":_original.._exp_inv", bValue,
                sDpe + ":_original.._from_SI", !bValue);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the address check bit
   * @param bValue the address check bit to set
   */
  public void setAddressCheckBit(bool bValue)
  {
    string sDpe = EB_getDatapointForTagId(this.sNodeId);
    dpSetWait(sDpe + this.ADDRESS_CHECK_BIT, bValue);
  }

  /**
   * @brief sets the address to unchecked
   * @details set both ADDRESS_CHECK_BIT (_userbit_2) and ADDRESS_OK_BIT (_userbit_3) at same time
   *          otherwise the connected callback functions is fired twice
   */
  public void setAddressUnchecked()
  {
    string sDpe = EB_getDatapointForTagId(this.sNodeId);

    if (dpExists(sDpe))
    {
      dpSetWait(sDpe + this.ADDRESS_CHECK_BIT, FALSE,
                sDpe + this.ADDRESS_OK_BIT, FALSE,
                sDpe + this.ADDRESS_SQ_BIT, FALSE);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the address check bit
   * @return bool the address check bit
   */
  public bool getAddressCheckBit()
  {
    string sDpe = EB_getDatapointForTagId(this.sNodeId);
    bool bValue;
    dpGet(sDpe + this.ADDRESS_CHECK_BIT, bValue);
    return bValue;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the address ok bit
   * @param bValue the address ok bit to set
   */
  public void setAddressOkBit(bool bValue)
  {
    string sDpe = EB_getDatapointForTagId(this.sNodeId);
    dpSetWait(sDpe + this.ADDRESS_OK_BIT, bValue);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the address ok bit
   * @return bool the address ok bit
   */
  public bool getAddressOkBit()
  {
    string sDpe = EB_getDatapointForTagId(this.sNodeId);
    bool bValue;

    dpGet(sDpe + this.ADDRESS_OK_BIT, bValue);

    return bValue;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the address direction
   * @param iDirection the address direction to set
   */
  public void setAddressDirection(int iDirection)
  {
    this.iAddressDirection = iDirection;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief get the address direction
   * @return iDirection the address direction to set
   */
  public int getAddressDirection()
  {
    return this.iAddressDirection;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief checks if the address is ok
   * @param sAddress the address to check
   * @return bool true if the address is ok
   */
  public bool checkAddress(const string &sAddress)
  {
    return TRUE;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Starts a single query for this tag
   * @param bHasDeviceConnection  True if the device has a connection
   */
  public void startSingleQuery(bool bHasDeviceConnection = FALSE)
  {
    if (bHasDeviceConnection && !this.bDoneSingleQuery)
    {
      this.bDoneSingleQuery = TRUE;
      EB_startSingleQueryForTag(this.sNodeId, spCommon.getDriverNumber());
      this.setAddressCheckBit(TRUE);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief creates the tag datapoint and sets all the configs
   */
  public void createTagDp()
  {
    if (this.sDeviceNodeId == "")
    {
      throwError(makeError("", PRIO_SEVERE, ERR_CONTROL, 54, "sDeviceNodeId empty"));
      return;
    }
    //if the datatype was updated -> delete and create the tag new
    if (this.bDatatypeChanged && this.sNodeId != "")
    {
      EB_deleteTag(this.sNodeId);
      this.sNodeId = "";
      this.bDatatypeChanged = FALSE;
    }
    if (this.bTagNameChanged && this.sNodeId != "")
    {
      EB_changeTagNames(this.sNodeId, this.lsTagName);
      this.bTagNameChanged = FALSE;
    }

    this.sNodeId = EB_createTag(this.sDeviceNodeId, this.lsTagName, spCommon.getNodeType(), this.tagType);

    if (this.sNodeId == "")
    {
      this.sNodeId = this.searchNodeId();
    }

    if (this.sNodeId == "")
    {
      throwError(makeError("", PRIO_SEVERE, ERR_CONTROL, 54, "sNodeId empty"));
      return;
    }

    if (this.bAddressChanged || this.bHasChanged)
    {
      this.sReference = this.setupReferenceString(); //sets up the sReference

      EB_createAddressForTag(this.sNodeId, spCommon.getDriverNumber(), spCommon.getDriverIdentifier(),
                           this.sReference, "_" + this.sRefreshRate,
                           (this.iTransformation == 0 ? spCommon.getDefaultTransformation() : this.iTransformation),
                           this.bActive, this.iAddressDirection,
                           this.sConnectionAttributeOnAddress,
                           this.uSubindex);

      if (!this.bDoneSingleQuery)
      {
        this.setAddressUnchecked();
      }
      this.bAddressChanged = FALSE;
      this.bHasChanged = FALSE;
      this.bActiveHasChanged = FALSE;
    }

    //set Address active/inactive
    if (this.bActiveHasChanged)
    {
      EB_setActiveForTag(this.sNodeId, this.bActive);
      this.bActiveHasChanged = FALSE;
    }

    // set unit always to keep sure that empty unit is also set
    EB_setUnitForTag(this.sNodeId, this.lsUnit);

    //if format string is defined set it
    if (this.sFormat != "")
    {
      EB_setFormatForTag(this.sNodeId, this.sFormat);
    }
    //if ranges are defined set pv range config
    if (this.isRangeConfigOk())
    {
      EB_createRangeForTag(this.sNodeId, this.mMin, this.mMax);
    }

    EB_setArchiveConfigForTag(this.sNodeId, this.sRefreshRate, this.bArchive);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief deletes the tag datapoint
   */
  public void deleteTagDp()
  {
    if (this.sNodeId == "")
    {
      this.sNodeId = this.searchNodeId();
    }
    if (this.sNodeId != "")
    {
      EB_deleteTag(this.sNodeId);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Create a tag object
   * @param iDeviceId        Id of the device
   * @param sDeviceNodeId    Node id of the device
   * @param sTagName         Name of the tag
   * @param tagType          Datatype of the tag(int, uint, float, string, bool)
   * @param sAddress         Reference string of the tag
   * @param miInput          Custom input
   * @param sRefreshRate     Refresh rate of the tag (default: 1s)
   * @param iReadWrite       Read-write (currently not in use)
   * @param mMin             Lower value range
   * @param mMax             Upper value range
   * @param lsUnit           Unit
   * @param sFormat          Format string
   * @param lsDesc           Description
   * @param uSubindex        Subindex
   */
  public void createTag(int iDeviceId, string sDeviceNodeId, const string &sTagName, EBTagType tagType, const string &sAddress,
                        const mixed &miInput, string sRefreshRate = "1s", int iReadWrite = 1, mixed mMin = 0, mixed mMax = 0,
                        langString lsUnit = "", string sFormat = "", langString lsDesc = "", uint uSubindex = 0u)
  {
    this.iDeviceId        = iDeviceId;
    this.sDeviceNodeId    = sDeviceNodeId;
    this.lsTagName        = sTagName;
    this.tagType          = tagType;
    this.sAddress         = sAddress;
    this.sRefreshRate     = sRefreshRate;
    this.iReadWrite       = iReadWrite;
    this.mMin             = mMin;
    this.mMax             = mMax;
    this.lsUnit           = lsUnit;
    this.bDatatypeChanged = FALSE;
    this.sFormat          = sFormat;
    this.lsDescription    = lsDesc;
    this.uSubindex        = uSubindex;

    this.setTransformation();
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Read values from a given table and write them to the current instance
   * @param mList the mapping of parameter get from a table row
   * @param iDeviceId Id of the device
   * @param sDeviceNodeId the node id of the device
   */
  public void fromTableRow(const mapping &mList, int iDeviceId, const string &sDeviceNodeId)
  {
    this.sDeviceNodeId = sDeviceNodeId;
    this.iDeviceId     = iDeviceId;
    this.bActive       = mList["ACTIVE"];
    this.tagType       = EB_getTagTypeForString(mList["TYPE"]);
    this.lsTagName     = mList["TAG"];
    this.lsDescription = (langString)mList["DESC"];
    this.sAddress      = mList["ADDRESS"];
    this.sRefreshRate  = mList["RATE"];
    this.iReadWrite    = 1;
    this.mMin          = mList["MIN"];
    this.mMax          = mList["MAX"];
    this.lsUnit        = (langString)mList["UNIT"];
    this.bArchive      = mList["ARCHIVE"];
    this.sFormat       = mList["FORMAT"];
    this.uSubindex     = mappingHasKey(mList, "SUBINDEX") ? mList["SUBINDEX"] : 0u;

    // Make sure the transformation is also set
    setTransformation();
  }


  //------------------------------------------------------------------------------
  /**
   * @brief decode a JSON string and write the values to the current instance
   * @param sJson information in JSON string
   * @param sDeviceNodeId The nodeId of the device
   * @param bRestore True if the data should be restored
   * @return an instance of this class
   */
  public GenericDriverTag fromJson(const string &sJson, string sDeviceNodeId = "", bool bRestore = FALSE)
  {
    mapping mJson = jsonDecode(sJson);

    this.bActive         = mappingHasKey(mJson, this.ACTIVE)         ? (bool)mJson[this.ACTIVE]         : FALSE;
    this.bArchive        = mappingHasKey(mJson, this.ARCHIVE)        ? (bool)mJson[this.ARCHIVE]        : FALSE;
    this.iDeviceId       = mappingHasKey(mJson, this.DEVICEID)       ?  (int)mJson[this.DEVICEID]       : 0;
    this.iReadWrite      = mappingHasKey(mJson, this.READWRITE)      ?  (int)mJson[this.READWRITE]      : 0;
    this.iTransformation = mappingHasKey(mJson, this.TRANSFORMATION) ?  (int)mJson[this.TRANSFORMATION] : spCommon.getDefaultTransformation();
    this.lsTagName       = mappingHasKey(mJson, this.TAGNAME)        ? EB_mappingToLangString(mJson[this.TAGNAME])  : "";
    this.lsDescription   = mappingHasKey(mJson, this.DESC)           ? EB_mappingToLangString(mJson[this.DESC])     : "";
    this.lsUnit          = mappingHasKey(mJson, this.UNIT)           ? EB_mappingToLangString(mJson[this.UNIT])     : "";
    this.tagType         = mappingHasKey(mJson, this.DATATYPE)       ? EB_getTagTypeForString(mJson[this.DATATYPE]) : EBTagType::INT;
    this.sDeviceNodeId   = mappingHasKey(mJson, this.DEVICENODEID)   ? mJson[this.DEVICENODEID]   : sDeviceNodeId;
    this.sNodeId         = mappingHasKey(mJson, this.NODEID)         ? mJson[this.NODEID]         : "";
    this.sAddress        = mappingHasKey(mJson, this.ADDRESS)        ? mJson[this.ADDRESS]        : "" ;
    this.sRefreshRate    = mappingHasKey(mJson, this.REFRESHRATE)    ? mJson[this.REFRESHRATE]    : "";
    this.sFormat         = mappingHasKey(mJson, this.FORMAT)         ? mJson[this.FORMAT]         : "";
    this.mMin            = mappingHasKey(mJson, this.MIN)            ? mJson[this.MIN]            : 0;
    this.mMax            = mappingHasKey(mJson, this.MAX)            ? mJson[this.MAX]            : 0;
    this.uSubindex       = mappingHasKey(mJson, this.SUBINDEX)       ? (uint)mJson[this.SUBINDEX] : 0u;

    if (bRestore)
    {
      this.forceNewAddress();
      this.createTagDp();
    }

    return this;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Write all information to a mapping
   * @param bWithNodeId True if the nodeId should also in the mapping
   * @return the mapping of the current object
   */
  public mapping writeToMapping(bool bWithNodeId = TRUE)
  {
    mapping mJson;

    mJson[this.DEVICEID]       = this.iDeviceId;
    mJson[this.TAGNAME]        = this.lsTagName;
    mJson[this.DESC]           = this.lsDescription;
    mJson[this.DATATYPE]       = EB_getStringForTagType(this.tagType);
    mJson[this.ADDRESS]        = this.sAddress;
    mJson[this.REFRESHRATE]    = this.sRefreshRate;
    mJson[this.READWRITE]      = this.iReadWrite;
    mJson[this.MIN]            = this.mMin;
    mJson[this.MAX]            = this.mMax;
    mJson[this.UNIT]           = this.lsUnit;
    mJson[this.ACTIVE]         = this.bActive;
    mJson[this.ARCHIVE]        = this.bArchive;
    mJson[this.TRANSFORMATION] = this.iTransformation;
    mJson[this.FORMAT]         = this.sFormat;
    mJson[this.SUBINDEX]       = this.uSubindex;

    if (bWithNodeId)
    {
      mJson[this.DEVICENODEID] = this.sDeviceNodeId;
      mJson[this.NODEID]       = this.sNodeId;
    }

    return mJson;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Write the current object to a JSON string
   * @param bWithNodeId True if the nodeId should also in the mapping
   * @return the information in JSON string
   */
  public string toJson(bool bWithNodeId = TRUE)
  {
    mapping mJson = this.writeToMapping(bWithNodeId);
    return jsonEncode(mJson);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief setups up the reference string for the driver
   * @return string the reference string
   */
  public string setupReferenceString()
  {
    DebugTN(__FUNCTION__, "needs to be implemented for driver derived from GenericDriverTag");
    return "";
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns the transformation type
   * @details Implemented for automatic tests
   * @return The transformation type
   */
  public int getTransformation()
  {
    return iTransformation;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief setups up the transformation for the driver
   */
  public void setTransformation()
  {
    DebugTN(__FUNCTION__, "needs to be implemented for driver derived from GenericDriverTag");
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------
  protected int        iDeviceId;                     //!< TODO: check need
  protected string     sDeviceNodeId;                 //!< TODO: check need
  protected string     sNodeId;                       //!< CNS node id
  protected langString lsTagName;                     //!< Tag name
  protected EBTagType  tagType;                       //!< Tag type
  protected string     sAddress;                      //!< User part of the address reference
  protected string     sRefreshRate;                  //!< in ms, 0 = on change, -1 = deactivated //TODO: int
  protected int        iReadWrite;                    //!< to be defined; read, write  read & write
  protected mixed      mMin;                          //!< Lower value range
  protected mixed      mMax;                          //!< Upper value range
  protected langString lsUnit;                        //!< Unit
  protected bool       bActive;                       //!< Active flag
  protected bool       bArchive;                      //!< Archived flag
  protected int        iTransformation;               //!< Transformation
  protected string     sReference;                    //!< Address reference for the driver
  protected string     sFormat;                       //!< Format
  protected langString lsDescription;                 //!< Description
  protected uint       uSubindex;                     //!< Subindex of the address config

  protected bool bHasChanged        = FALSE;          //!< Flag to indicate that the tag has changed
  protected bool bActiveHasChanged  = FALSE;          //!< Flag to indicate that the active flag has changed
  protected bool bDatatypeChanged   = FALSE;          //!< Flag to indicate that the datatype has changed
  protected bool bTagNameChanged    = FALSE;          //!< Flag to indicate that the tag name has changed
  protected bool bTagAddressOk      = FALSE;          //!< Flag to indicate that the address is OK
  protected bool bTagAddressChecked = FALSE;          //!< Flag to indicate that the address has been checked
  protected bool bAddressChanged    = FALSE;          //!< Flag to indicate that the address has changed
  protected bool bDoneSingleQuery   = FALSE;          //!< Flag to indicate that the single query has been executed

  protected string sConnectionAttributeOnAddress = ""; //!< Additional parameter for connection

  protected shared_ptr<GenericDriverCommon> spCommon; //!< Pointer to the GenericDriverCommon object

  //------------------------------------------------------------------------------
  /**
   * @brief search the nodeId by the name and sets it if the name is found
   * @return ?
   */
  protected string searchNodeId()
  {
    string sViewName = EB_createView(spCommon.getPackageName(), spCommon.getViewName());

    return EB_getIdFromExactName(this.lsTagName, sViewName, spCommon.getNodeType());
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
  static const string DEVICEID       = "DeviceId";
  static const string DEVICENODEID   = "DeviceNodeId";
  static const string NODEID         = "NodeId";
  static const string TAGNAME        = "TagName";
  static const string DATATYPE       = "DataType";
  static const string ADDRESS        = "Address";
  static const string REFRESHRATE    = "Refreshrate";
  static const string READWRITE      = "ReadWrite";
  static const string MIN            = "Min";
  static const string MAX            = "Max";
  static const string UNIT           = "Unit";
  static const string ACTIVE         = "Active";
  static const string ARCHIVE        = "Archive";
  static const string TRANSFORMATION = "Transformation";
  static const string FORMAT         = "Format";
  static const string DESC           = "Desc";
  static const string SUBINDEX       = "Subindex";

  public static const string ADDRESS_CHECK_BIT = ":_original.._userbit2";
  public static const string ADDRESS_OK_BIT    = ":_original.._userbit3";
  static const string ADDRESS_SQ_BIT    = ":_original.._from_SI";



  private int iAddressDirection = DPATTR_ADDR_MODE_INPUT_POLL;
};
