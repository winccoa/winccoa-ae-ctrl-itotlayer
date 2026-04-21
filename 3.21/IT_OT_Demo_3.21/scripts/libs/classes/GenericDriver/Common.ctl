// $License: NOLICENSE

/**
 * @file scripts/libs/classes/GenericDriver/Common.ctl
 */

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "classes/EBTag"
#uses "classes/EBCsv"
#uses "EB_Package_Base/EB_UtilsCommon"

//--------------------------------------------------------------------------------
// declare variables and constants
/**
 * @brief Enum for the alert (class) priority (& color)
 */
enum ConfigurationState
{
  Undefined,
  Ok        = 1, // Green
  Pending   = 3, // Yellow
  Alert     = 4  // Red
};

//--------------------------------------------------------------------------------
/*!
 * @brief Handler for GenericDriverCommon
 * @details Derived classes must override at least the following member variables:
 *   - iDriverNumber
 *   - sDriverIdentifier
 *   - sAppName
 *   - sJsonDpe
 *   - iDefaultTransformation
 *   - sConnectionStateQuery
 *   - sConnectionStateDP
 *   - dsCsvHeaders
 *
 * @author Martin Schiefer
 */
class GenericDriverCommon
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  //------------------------------------------------------------------------------
  /**
   * @brief c-tor
   */
  public GenericDriverCommon()
  {
    this.iDriverNumber = 1;
    this.sDriverIdentifier = "GenericDriver";
    this.sAppName = APPNAME;

    this.nodeType = EBNodeType::DP;
    this.sJsonDpe = "EB_GENDRV.DeviceList";
    this.iDefaultTransformation = 0;

    this.sConnectionStateQuery = "SELECT '_original.._value' FROM '_GENDRV*.State.ConnState' WHERE _DPT = \"_GENDRVServer\"";
    this.sConnectionStateDP = "_GENDRV";
    this.sDeviceName = "Device";

    this.dsCsvHeaders = makeDynString("active", "tag", "address", "type", "rate","min", "max", "archive", "unit", "format", "desc");
    this.dsAdditionalExportHeaders = makeDynString();

    this.bConnectionTagNeeded = FALSE;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the driver number
   * @return int the driver number
   */
  public int getDriverNumber()
  {
    return iDriverNumber;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the app name
   * @return string the app name
   */
  public string getAppName()
  {
    return sAppName;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the driver identifier
   * @return string the driver identifier
   */
  public string getDriverIdentifier()
  {
    return sDriverIdentifier;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the viewname
   * @return langString the viewname
   */
  public langString getViewName()
  {
    return EB_UtilsCommon::getLangStringForString(sAppName);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the package name
   * @return string the package name
   */
  public string getPackageName()
  {
    return "EB_Package_" + sAppName;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the nodetype
   * @return EBNodeType the nodetype
   */
  public EBNodeType getNodeType()
  {
    return nodeType;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the json DPE
   * @return string the json DPE
   */
  public string getJsonDpe()
  {
    return sJsonDpe;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the default transformation
   * @return int the default transformation
   */
  public int getDefaultTransformation()
  {
    return iDefaultTransformation;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the query for the connectionstate
   * @return string the query
   */
  public string getConnectionStateQuery()
  {
    return sConnectionStateQuery;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the DP for the connectionstate
   * @return string the DP
   */
  public string getConnectionStateDP()
  {
    return sConnectionStateDP;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the device name
   * @return string the device name
   */
  public string getDeviceName()
  {
    return sDeviceName;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the additional headers for export
   * @return dyn_string the additional headers
   */
  public dyn_string getAdditionalExportHeaders()
  {
    return dsAdditionalExportHeaders;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the headers for export
   * @param bHasSubindex TRUE if the subindex is available
   * @return the headers
   */
  public dyn_string getExportTableHeaders(bool bHasSubindex = FALSE)
  {
    dyn_string dsRetVal = dsDefaultExportHeaders;

    if (bHasSubindex)
    {
      dynAppend(dsRetVal, "SUBINDEX");
    }

    dynAppend(dsRetVal, getAdditionalExportHeaders());

    return dsRetVal;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the headers for csv file
   * @return dyn_string the headers
   */
  public dyn_string getCsvHeaders()
  {
    return dsCsvHeaders;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the shared_ptr for EBCsv class
   * @return shared_ptr<EBCsv> the shared_ptr
   */
  public shared_ptr<EBCsv> getCsvPointer()
  {
    return new EBCsv();
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the function_ptr for this class
   * @return function pointer to create a new common instance
   */
  public static shared_ptr<GenericDriverCommon> createCommonPointer()
  {
    return new GenericDriverCommon();
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns if the driver needs a tag to establish a connection
   * @return TRUE -> For each new device automatically a new tag will be created
   */
  public bool getConnectionTagNeeded()
  {
    return bConnectionTagNeeded;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns driver connection DPT
   * @return Returns driver connection DPT
   */
  public string getConnectionDPT()
  {
    return "";
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------
  protected dyn_string dsDefaultExportHeaders = makeDynString("ACTIVE", "TAG", "ADDRESS", "TYPE", "RATE",
                                                              "MIN", "MAX", "ARCHIVE", "UNIT", "FORMAT", "DESC"); //!< Default columns for export

  protected int    iDriverNumber       = 1;                                                                       //!< Manager number of the driver
  protected string sDriverIdentifier   = "GenericDriver";                                                         //!< Identifier of the driver
  protected string sAppName;                                                                                      //!< Package name

  protected EBNodeType nodeType        = EBNodeType::DP;                                                          //!< CNS node type for tags
  protected string sJsonDpe            = "EB_GENDRV.DeviceList";                                                  //!< Dpe containing the device list
  protected int iDefaultTransformation = 0;                                                                       //!< Default transformation

  protected string sConnectionStateQuery = "SELECT '_original.._value' FROM '_GENDRV*.State.ConnState' WHERE _DPT = \"_GENDRVServer\"";    //!< Query to get the connection states
  protected string sConnectionStateDP    = "_GENDRV";                                                             //!< Dptype for the driver connections
  protected string sDeviceName           = "Device";                                                              //!< Name of the device (usually PLC or device)

  protected dyn_string dsAdditionalExportHeaders;                                                                 //!< Additional columns to export
  protected dyn_string dsCsvHeaders;                                                                              //!< Header texts in a CSV file

  protected bool bConnectionTagNeeded = FALSE;                                                                    //!< TRUE if a tag must configured to let the driver establish a connection

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
  public static const string APPNAME = "GENDRV";                                                                  //!< app name
};
