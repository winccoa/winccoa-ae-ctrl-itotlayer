// $License: NOLICENSE
//--------------------------------------------------------------------------------
/** Library for automatic tests
  @file $relPath
  @copyright $copyright
  @author z0043ctz
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants
const string SYSTEM = "System1";

const string MQTT_DP             = "MindSphereConnector";
const string MQTT_DP_REC_DATA    = MQTT_DP + ".receiveData:_original.._value";
const string MQTT_DP_CONFIG      = MQTT_DP + ".configuration:_original.._value";
const string MQTT_DP_MAP         = MQTT_DP + ".mapping_dataPointId:_original.._value";
const string MQTT_DP_DIAG_CMD    = MQTT_DP + ".diagnostic.command:_original.._value";
const string MQTT_DP_CMD_RESP    = MQTT_DP + ".commandValues.commandResponse";
const string MQTT_DP_BROWSE_CMD  = MQTT_DP + ".browsing.receiveData";
const string MQTT_DP_BROWSE_REQ  = MQTT_DP + ".browsing.request_fileUpload";
const string MQTT_DP_BROWSE_RESP = MQTT_DP + ".browsing.response_fileUpload";

const string MQTT_COMM_DPT            = "MNSP_MQTT_COMM";
const string MQTT_COMM_COMMAND        = ".Command";
const string MQTT_COMM_COMMAND_RESULT = ".CommandResult";
const string MQTT_COMM_DATA           = ".Data";
const string MQTT_COMM_DIAG           = ".Diag";

const string DRIVER_NAME_S7        = "S7";
const string DRIVER_NAME_S7PLUS    = "S7PLUS";
const string DRIVER_NAME_SINUMERIK = "Sinumerik";
const string DRIVER_NAME_FOCAS     = "FOCAS";
const string DRIVER_NAME_IEC61850  = "IEC61850CLIENT";
const string DRIVER_NAME_MTCONNECT = "MTConnect";
const string DRIVER_NAME_BACNET    = "BACNET";

const dyn_string DP_TO_IGNORE = makeDynString("*:_bacnet_arraylenth_request_element",/*"*:MetadataChanged",*/ "*:BACnet_ConnectionTag_*");

const string EB_DRIVER_CONN_DPT      = "_EB_DriverConnection";
const string EB_DRIVER_CONN_DP_STATE = "State";
const string EB_DRIVER_CONN_DP_INFO  = "AddInfo";

const string KEY_EB_DRIVER_CONN_INFO_PLCTYPE = "plcType";

const string EB_MTCONNECT_DP            = "EB_MTConnect";
const string EB_MTCONNECT_DP_DEVICELIST = EB_MTCONNECT_DP + ".DeviceList";

const string KEY_EB_MTCONNECT_TAGLIST = "TagList";
const string KEY_EB_MTCONNECT_ADDRESS = "Address";
const string KEY_EB_MTCONNECT_NODEID  = "NodeId";

const string KEY_MQTT_COMM_DATA_VALUES   = "values";
const string KEY_MQTT_COMM_DATA_QC       = "qualityCode";
const string KEY_MQTT_COMM_DATA_DATAPTID = "dataPointId";

const string S7_CONFIG_DP           = "_S7_Config";
const string S7_CONFIG_DP_SLOT      = S7_CONFIG_DP + ".Slot";
const string S7_CONFIG_DP_CONN_TYPE = S7_CONFIG_DP + ".ConnectionType";

const int S7_CONFIG_SINUMERIK_OFFSET = 255;

const string S7_CONN_CONNSTATE = ".ConnState";
const string S7_CONN_OPSTATE   = ".OpState";

const int S7_TRANSFORMATION_TYPE_OFFSET         =  701;
const int S7PLUS_TRANSFORMATION_TYPE_OFFSET     = 1001;
const int FANUCFOCAS_TRANSFORMATION_TYPE_OFFSET = 1001;
const int IEC61850_TRANSFORMATION_TYPE_OFFSET   =    1;
const int BACNET_TRANSFORMATION_TYPE_OFFSET     =  800;

const string LOG_NUMBER_PROJECT_START                 = "000101";
const string LOG_NUMBER_PROJECT_STOP                  = "000102";
const string LOG_NUMBER_PROJECT_RESTART               = "000103";
const string LOG_NUMBER_LICENSE_EXPIRES               = "000104";
const string LOG_NUMBER_BROKER_CONNECTION_FAILURE     = "000105";
const string LOG_NUMBER_RUNNING_MANAGERS              = "000110";
const string LOG_NUMBER_MEMORY_ALMOST_FULL            = "000200";
const string LOG_NUMBER_MEMORY_FULL                   = "000201";
const string LOG_NUMBER_DISK_ALMOST_FULL              = "000202";
const string LOG_NUMBER_DISK_FULL                     = "000203";
const string LOG_NUMBER_CPU_USAGE_HIGH                = "000204";
const string LOG_NUMBER_CPU_USAGE_TOO_HIGH            = "000205";
const string LOG_NUMBER_EVENT_CPU_USAGE_HIGH          = "000206";
const string LOG_NUMBER_EVENT_CPU_USAGE_TOO_HIGH      = "000207";
const string LOG_NUMBER_EMERGENCY_MODE_ACTIVE         = "000208";
const string LOG_NUMBER_EMERGENCY_SOLVED              = "000209";
const string LOG_NUMBER_FILE_TRANSFERRED_SUCCESSFULLY = "000216";
const string LOG_NUMBER_FILE_TRANSFER_FAILED          = "000217";
const string LOG_NUMBER_USER_LOGGED_IN                = "000301";
const string LOG_NUMBER_USER_LOGGED_OUT               = "000302";
const string LOG_NUMBER_DRIVER_START                  = "000401";
const string LOG_NUMBER_DRIVER_STOP                   = "000402";
const string LOG_NUMBER_DRIVER_RESTART                = "000403";
const string LOG_NUMBER_MANAGER_IS_NOT_RUNNING        = "000404";
const string LOG_NUMBER_TAG_COUNT                     = "000428";
const string LOG_NUMBER_ALLOWED_TAGS                  = "000429";
const string LOG_NUMBER_CONFIGURED_CONNECTIONS        = "000430";
const string LOG_NUMBER_ACTIVE_CONNECTIONS            = "000431";

const string LOG_NUMBER_PLC_CONNECTION_ESTABLISHED    = "406";
const string LOG_NUMBER_PLC_CONNECTION_FAILURE        = "407";
const string LOG_NUMBER_DEVICE_CREATED                = "408";
const string LOG_NUMBER_DEVICE_CREATION_FAILURE       = "409";
const string LOG_NUMBER_APP_INSTALLATION_SUCCESSFUL   = "422";
const string LOG_NUMBER_APP_INSTALLATION_FAILURE      = "423";
const string LOG_NUMBER_APP_UPDATE_SUCCESSFUL         = "424";
const string LOG_NUMBER_APP_UPDATE_FAILURE            = "425";
const string LOG_NUMBER_APP_REMOVAL_SUCCESSFUL        = "426";
const string LOG_NUMBER_APP_REMOVAL_FAILURE           = "427";

const string LOG_NUMBER_S7_PREFIX = "002";

const dyn_string LOG_DEFAULT_FILTER = makeDynString("*");

//--------------------------------------------------------------------------------
// Enums
enum MqttMapping
{
  TAG_MNSP_ID_TO_CNS_ID,
  TAG_DP_NAME_TO_MNSP_ID,
  TAG_DP_NAME_TO_DEVICE_MNSP_ID,
  DEVICE_MNSP_ID_TO_DP_NAME,
  DEVICE_MNSP_ID_TO_CNS_ID,
  DEVICE_MNSP_ID_DATA
};

enum MqttErrorCodes
{
  errTimeOut = -4,
  errGetJsonString,
  errSetJsonString,
  errReadMqttFile,
  noError
};

enum S7ConnState
{
  NOT_CONNECTED,
  CONNECTED,
  GQ,
  NOT_ACTIVE
};

enum S7OpState
{
  STOP,
  STARTING,
  RUN,
  UNDEFINED
};

//--------------------------------------------------------------------------------
/*!
  @brief Base class for reading CNS data
  @details This class is used to get all necessary CNS information needed for automatic tests.
           All methods of this class are static.
*/
class Cns
{
  //------------------------------------------------------------------------------
  /**
    @brief Get CNS ID of every protocol (CNS View)
    @param[out] dsCnsProtocolIds Array of CNS View IDs
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to read CNS
  */
  public static int getProtocolIds(dyn_string &dsCnsProtocolIds)
  {
    dsCnsProtocolIds.clear();

    return cnsGetViews(SYSTEM, dsCnsProtocolIds) ? 0 : -1;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS display name of every protocol (CNS View)
    @param[out] dsCnsProtocolNames Array of CNS View display names
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to read CNS
            -2    | failed to get display names
  */
  public static int getProtocolNames(dyn_string &dsCnsProtocolNames)
  {
    int iErr;
    dyn_string dsCnsProtocolIds;

    dsCnsProtocolNames.clear();

    iErr = getProtocolIds(dsCnsProtocolIds);
    if(iErr < 0)
    {
      return -1;
    }

    for(int i = 0; i < dsCnsProtocolIds.count(); i++)
    {
      langString lsCnsProtocolName;

      if(!cnsGetViewDisplayNames(dsCnsProtocolIds.at(i), lsCnsProtocolName))
      {
        return -2;
      }

      dsCnsProtocolNames.append((string)lsCnsProtocolName);
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get mapping of CNS View ID to display name
    @param[out] mCnsProtIdsToNames Mapping of CNS View ID to display name
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS View IDs
            -2    | failed to get CNS View display names
            -3    | Missmatch in ID and display name count
  */
  public static int getProtocolIdsToNamesMapping(mapping &mCnsProtIdsToNames)
  {
    int iErr;
    dyn_string dsCnsProtocolIds;
    dyn_string dsCnsProtocolNames;

    mCnsProtIdsToNames.clear();

    iErr = getProtocolIds(dsCnsProtocolIds);
    if(iErr < 0)
    {
      return -1;
    }

    iErr = getProtocolNames(dsCnsProtocolNames);
    if(iErr < 0)
    {
      return -2;
    }

    if(dsCnsProtocolIds.count() != dsCnsProtocolNames.count())
    {
      return -3;
    }

    for(int i = 0; i < dsCnsProtocolIds.count(); i++)
    {
      mCnsProtIdsToNames.insert(dsCnsProtocolIds.at(i), dsCnsProtocolNames.at(i));
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get mapping of CNS View display name to ID
    @param[out] mCnsProtNamesToIds Mapping of CNS View display name to ID
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS View IDs
            -2    | failed to get CNS View display names
            -3    | Missmatch in ID and display name count
  */
  public static int getProtocolNamesToIdsMapping(mapping &mCnsProtNamesToIds)
  {
    int iErr;
    dyn_string dsCnsProtocolIds;
    dyn_string dsCnsProtocolNames;

    mCnsProtNamesToIds.clear();

    iErr = getProtocolIds(dsCnsProtocolIds);
    if(iErr < 0)
    {
      return -1;
    }

    iErr = getProtocolNames(dsCnsProtocolNames);
    if(iErr < 0)
    {
      return -2;
    }

    if(dsCnsProtocolIds.count() != dsCnsProtocolNames.count())
    {
      return -3;
    }

    for(int i = 0; i < dsCnsProtocolNames.count(); i++)
    {
      mCnsProtNamesToIds.insert(dsCnsProtocolNames.at(i), dsCnsProtocolIds.at(i));
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS IDs of all devices
    @param[out] dsCnsDeviceIds Array of device CNS IDs (CNS Node)
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS View IDs
            -2    | failed to get child nodes of CNS View
  */
  public static int getAllDeviceIds(dyn_string &dsCnsDeviceIds)
  {
    int iErr;
    dyn_string dsCnsProtocolIds;

    dsCnsDeviceIds.clear();

    iErr = getProtocolIds(dsCnsProtocolIds);
    if(iErr < 0)
    {
      return -1;
    }

    for(int i = 0; i < dsCnsProtocolIds.count(); i++)
    {
      dyn_string dsCnsTrees;

      if(!cnsGetTrees(dsCnsProtocolIds.at(i), dsCnsTrees))
      {
        return -2;
      }

      dynAppend(dsCnsDeviceIds, dsCnsTrees);
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS display names of all devices
    @param[out] dsCnsDeviceNames Array of device CNS display names (CNS Node)
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS View IDs
            -2    | failed to get child nodes of CNS View
            -3    | failed to get display names of child nodes
  */
  public static int getAllDeviceNames(dyn_string &dsCnsDeviceNames)
  {
    int iErr;
    dyn_string dsCnsProtocolIds;

    dsCnsDeviceNames.clear();

    iErr = getProtocolIds(dsCnsProtocolIds);
    if(iErr < 0)
    {
      return -1;
    }

    for(int i = 0; i < dsCnsProtocolIds.count(); i++)
    {
      dyn_string dsCnsTrees;

      if(!cnsGetTrees(dsCnsProtocolIds.at(i), dsCnsTrees))
      {
        return -2;
      }

      for(int j = 0; j < dsCnsTrees.count(); j++)
      {
        langString lsCnsDeviceName;

        if(!cnsGetDisplayNames(dsCnsTrees.at(j), lsCnsDeviceName))
        {
          return -3;
        }

        dsCnsDeviceNames.append((string)lsCnsDeviceName);
      }
    }

    return 0;
  }


  //------------------------------------------------------------------------------
  /**
    @brief Get CNS IDs of all tags
    @param[out] dsCnsTagIds Array of tag CNS IDs (CNS Node)
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS device IDs
            -2    | failed to get child nodes of devices
  */
  public static int getAllTagIds(dyn_string &dsCnsTagIds)
  {
    int iErr;
    dyn_string dsCnsDeviceIds;

    dsCnsTagIds.clear();

    iErr = getAllDeviceIds(dsCnsDeviceIds);
    if(iErr < 0)
    {
      return -1;
    }

    for(int i = 0; i < dsCnsDeviceIds.count(); i++)
    {
      dyn_string dsCnsChildren;

      if(!cnsGetChildren(dsCnsDeviceIds.at(i), dsCnsChildren))
      {
        return -2;
      }

      dynAppend(dsCnsTagIds, dsCnsChildren);
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS display names of all tags
    @param[out] dsCnsTagNames Array of tag CNS display names (CNS Node)
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS device IDs
            -2    | failed to get child nodes of devices
  */
  public static int getAllTagNames(dyn_string &dsCnsTagNames)
  {
    int iErr;
    dyn_string dsCnsDeviceIds;

    dsCnsTagNames.clear();

    iErr = getAllDeviceIds(dsCnsDeviceIds);
    if(iErr < 0)
    {
      return -1;
    }

    for(int i = 0; i < dsCnsDeviceIds.count(); i++)
    {
      dyn_string dsCnsChildren;

      if(!cnsGetChildren(dsCnsDeviceIds.at(i), dsCnsChildren))
      {
        return -2;
      }

      for(int j = 0; j < dsCnsChildren.count(); j++)
      {
        langString lsCnsTagName;

        cnsGetDisplayNames(dsCnsChildren.at(j), lsCnsTagName);
        dsCnsTagNames.append((string)lsCnsTagName);
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get mapping of CNS device display names to IDs
    @param[out] mCnsDevNamesToIds Mapping of CNS device display names to IDs
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS device IDs
            -2    | failed to get CNS device display names
            -3    | Missmatch in count of IDs and display names
  */
  public static int getDeviceNamesToIdsMapping(mapping &mCnsDevNamesToIds)
  {
    int iErr;
    dyn_string dsCnsDeviceIds;
    dyn_string dsCnsDeviceNames;

    mCnsDevNamesToIds.clear();

    iErr = getAllDeviceIds(dsCnsDeviceIds);
    if(iErr < 0)
    {
      return -1;
    }

    iErr = getAllDeviceNames(dsCnsDeviceNames);
    if(iErr < 0)
    {
      return -2;
    }

    if(dsCnsDeviceIds.count() != dsCnsDeviceNames.count())
    {
      return -3;
    }

    for(int i = 0; i < dsCnsDeviceNames.count(); i++)
    {
      mCnsDevNamesToIds.insert(dsCnsDeviceNames.at(i), dsCnsDeviceIds.at(i));
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get mapping of CNS device IDs to display names
    @param[out] mCnsDevIdsToNames Mapping of CNS device IDs to display names
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS device IDs
            -2    | failed to get CNS device display names
            -3    | Missmatch in count of IDs and display names
  */
  public static int getDeviceIdsToNamesMapping(mapping &mCnsDevIdsToNames)
  {
    int iErr;
    dyn_string dsCnsDeviceIds;
    dyn_string dsCnsDeviceNames;

    mCnsDevIdsToNames.clear();

    iErr = getAllDeviceIds(dsCnsDeviceIds);
    if(iErr < 0)
    {
      return -1;
    }

    iErr = getAllDeviceNames(dsCnsDeviceNames);
    if(iErr < 0)
    {
      return -2;
    }

    if(dsCnsDeviceIds.count() != dsCnsDeviceNames.count())
    {
      return -3;
    }

    for(int i = 0; i < dsCnsDeviceIds.count(); i++)
    {
      mCnsDevIdsToNames.insert(dsCnsDeviceIds.at(i), dsCnsDeviceNames.at(i));
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get mapping of CNS tag IDs to display names
    @param[out] mCnsTagIdsToNames Mapping of CNS tag IDs to display names
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS tag IDs
            -2    | failed to get CNS tag display names
            -3    | Missmatch in count of IDs and display names
  */
  public static int getTagIdsToNamesMapping(mapping &mCnsTagIdsToNames)
  {
    int iErr;
    dyn_string dsCnsTagIds;
    dyn_string dsCnsTagNames;

    mCnsTagIdsToNames.clear();

    iErr = getAllTagIds(dsCnsTagIds);
    if(iErr < 0)
    {
      return -1;
    }

    iErr = getAllTagNames(dsCnsTagNames);
    if(iErr < 0)
    {
      return -2;
    }

    if(dsCnsTagIds.count() != dsCnsTagNames.count())
    {
      return -3;
    }

    for(int i = 0; i < dsCnsTagIds.count(); i++)
    {
      mCnsTagIdsToNames.insert(dsCnsTagIds.at(i), dsCnsTagNames.at(i));
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get mapping of CNS tag display names to IDs
    @param[out] mCnsTagNamesToIds Mapping of CNS tag display names to IDs
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS tag IDs
            -2    | failed to get CNS tag display names
            -3    | Missmatch in count of IDs and display names
  */
  public static int getTagNamesToIdMapping(mapping &mCnsTagNamesToIds)
  {
    int iErr;
    dyn_string dsCnsTagIds;
    dyn_string dsCnsTagNames;

    mCnsTagNamesToIds.clear();

    iErr = getAllTagIds(dsCnsTagIds);
    if(iErr < 0)
    {
      return -1;
    }

    iErr = getAllTagNames(dsCnsTagNames);
    if(iErr < 0)
    {
      return -2;
    }

    if(dsCnsTagIds.count() != dsCnsTagNames.count())
    {
      return -3;
    }

    for(int i = 0; i < dsCnsTagNames.count(); i++)
    {
      mCnsTagNamesToIds.insert(dsCnsTagNames.at(i), dsCnsTagIds.at(i));
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS tag IDs of given device
    @param sCnsDeviceId CNS device ID
    @param[out] dsCnsTagIds Array of CNS tag IDs
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS device children
  */
  public static int getTagIds(const string &sCnsDeviceId, dyn_string &dsCnsTagIds)
  {
    int iErr;

    dsCnsTagIds.clear();

    if(!cnsGetChildren(sCnsDeviceId, dsCnsTagIds))
    {
      return -1;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS tag display names of given device
    @param sCnsDeviceId CNS device ID
    @param[out] dsCnsTagNames Array of CNS tag display names
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS device children
            -2    | failed to get display names of tags
  */
  public static int getTagNames(const string &sCnsDeviceId, dyn_string &dsCnsTagNames)
  {
    int iErr;
    dyn_string dsCnsTagIds;

    dsCnsTagNames.clear();

    if(!cnsGetChildren(sCnsDeviceId, dsCnsTagIds))
    {
      return -1;
    }

    for(int i = 0; i < dsCnsTagIds.count(); i++)
    {
      langString lsCnsTagName;

      if(!cnsGetDisplayNames(dsCnsTagIds.at(i), lsCnsTagName))
      {
        return -2;
      }
      dsCnsTagNames.append((string)lsCnsTagName);
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS device IDs of given protocol ID
    @param sProtocolId CNS protocol ID
    @param[out] dsCnsDeviceIds Array of CNS device IDs
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS protocol children
  */
  public static int getDeviceIds(const string &sProtocolId, dyn_string &dsCnsDeviceIds)
  {
    dsCnsDeviceIds.clear();

    if(!cnsGetTrees(sProtocolId, dsCnsDeviceIds))
    {
      return -1;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS device display names of given protocol ID
    @param sProtocolId CNS protocol ID
    @param[out] dsCnsDeviceNames Array of CNS device display names
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS protocol children
            -2    | failed to get display names of devices
  */
  public static int getCnsDeviceNames(const string &sProtocolId, dyn_string &dsCnsDeviceNames)
  {
    int iErr;
    dyn_string dsCnsDeviceIds;

    dsCnsDeviceNames.clear();

    if(!cnsGetTrees(sProtocolId, dsCnsDeviceIds))
    {
      return -1;
    }

    for(int i = 0; i < dsCnsDeviceIds.count(); i++)
    {
      langString lsCnsDeviceName;

      if(!cnsGetDisplayNames(dsCnsDeviceIds.at(i), lsCnsDeviceName))
      {
        return -2;
      }

      dsCnsDeviceNames.append((string)lsCnsDeviceName);
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS device ID of given Tag ID
    @param sCnsTagId CNS tag ID
    @param[out] sDeviceId CNS device ID
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS tag parent
  */
  public static int getTagDeviceId(const string &sCnsTagId, string &sDeviceId)
  {
    return cnsGetParent(sCnsTagId, sDeviceId) ? 0 : -1;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS device display name of given Tag ID
    @param sCnsTagId CNS tag ID
    @param[out] sDeviceName CNS device display name
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS tag parent
            -2    | failed to get CNS device display name
  */
  public static int getTagDeviceName(const string &sCnsTagId, string &sDeviceName)
  {
    string sDeviceId;
    langString lsDeviceName;

    if(!cnsGetParent(sCnsTagId, sDeviceId))
    {
      return -1;
    }

    if(!cnsGetDisplayNames(sDeviceId, lsDeviceName))
    {
      return -2;
    }

    sDeviceName = (string)lsDeviceName;

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS protocol ID of given device ID
    @param sCnsDeviceId CNS device ID
    @param[out] sProtocolId CNS protocol ID
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS protocol IDs
            -2    | failed to get CNS device IDs
            -3    | protocol ID of given device ID not found
  */
  public static int getDeviceProtocolId(const string &sCnsDeviceId, string &sProtocolId)
  {
    int iErr;
    dyn_string dsProtocolIds;

    iErr = getProtocolIds(dsProtocolIds);
    if(iErr < 0)
    {
      return -1;
    }

    for(int i = 0; i < dsProtocolIds.count(); i++)
    {
      dyn_string dsDeviceIds;

      iErr = getDeviceIds(dsProtocolIds.at(i), dsDeviceIds);
      if(iErr < 0)
      {
        return -2;
      }

      if(dsDeviceIds.contains(sCnsDeviceId))
      {
        sProtocolId = dsProtocolIds.at(i);

        return 0;
      }
    }

    return -3;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get CNS protocol display name of given device ID
    @param sCnsDeviceId CNS device ID
    @param[out] sProtocolName CNS protocol display name
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to get CNS protocol IDs
            -2    | failed to get CNS device IDs
            -3    | protocol ID of given device ID not found
            -4    | failed to get CNS protocol display name
  */
  public static int getDeviceProtocolName(const string &sCnsDeviceId, string &sProtocolName)
  {
    int iErr;
    dyn_string dsProtocolIds;

    iErr = getProtocolIds(dsProtocolIds);
    if(iErr < 0)
    {
      return -1;
    }

    for(int i = 0; i < dsProtocolIds.count(); i++)
    {
      dyn_string dsDeviceIds;

      iErr = getDeviceIds(dsProtocolIds.at(i), dsDeviceIds);
      if(iErr < 0)
      {
        return -2;
      }

      if(dsDeviceIds.contains(sCnsDeviceId))
      {
        langString lsProtocolName;

        if(!cnsGetViewDisplayNames(dsProtocolIds.at(i), lsProtocolName))
        {
          return -4;
        }

        sProtocolName = (string)lsProtocolName;

        return 0;
      }
    }

    return -3;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get WinCC OA Dp name of given CNS ID
    @param sCnsId CNS ID
    @param[out] sDp WinCC OA Dp
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Given ID not found
  */
  public static int getDpFromId(const string &sCnsId, string &sDp)
  {
    return cnsGetId(sCnsId, sDp) ? 0 : -1;
  }

};

//--------------------------------------------------------------------------------
/*!
  @brief Base class for reading tag data
  @details This class is used to get all necessary tag information needed for automatic tests.
           All methods of this class are static.
*/
class Tag
{
  //------------------------------------------------------------------------------
  /**
    @brief Get description of given tag
    @param sTagDp Tag Dp (can be CNS ID too)
    @param[out] sTagDescription Description of tag
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Given Dp does not exists
  */
  public static int getDescription(const string &sTagDp, string &sTagDescription)
  {
    langString lsDpDescription;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    lsDpDescription = dpGetDescription(sTagDp, -2);
    sTagDescription = (string)lsDpDescription;

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get unit of given tag
    @param sTagDp Tag Dp (can be CNS ID too)
    @param[out] sTagUnit Unit of tag
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Given Dp does not exists
  */
  public static int getUnit(const string &sTagDp, string &sTagUnit)
  {
    langString lsDpUnit;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    lsDpUnit = dpGetUnit(sTagDp);
    sTagUnit = (string)lsDpUnit;

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get datatype of given tag
    @param sTagDp Tag Dp (can be CNS ID too)
    @param[out] sDataType Datatype of tag
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Given Dp does not exists
  */
  public static int getDataType(const string &sTagDp, string &sDataType)
  {
    int iElementType;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    iElementType = dpElementType(sTagDp);

    switch (iElementType)
    {
      case DPEL_CHAR:           sDataType = "char";           break;
      case DPEL_UINT:           sDataType = "uint";           break;
      case DPEL_INT:            sDataType = "int";            break;
      case DPEL_ULONG:          sDataType = "ulong";          break;
      case DPEL_LONG:           sDataType = "long";           break;
      case DPEL_FLOAT:          sDataType = "float";          break;
      case DPEL_BOOL:           sDataType = "bool";           break;
      case DPEL_BIT32:          sDataType = "bit32";          break;
      case DPEL_BIT64:          sDataType = "bit64";          break;
      case DPEL_STRING:         sDataType = "string";         break;
      case DPEL_TIME:           sDataType = "time";           break;
      case DPEL_DPID:           sDataType = "dpId";           break;
      case DPEL_LANGSTRING:     sDataType = "langString";     break;
      case DPEL_BLOB:           sDataType = "blob";           break;
      case DPEL_TYPEREF:        sDataType = "TYPEREF";        break;
      case DPEL_DYN_CHAR:       sDataType = "dyn_char";       break;
      case DPEL_DYN_UINT:       sDataType = "dyn_uint";       break;
      case DPEL_DYN_INT:        sDataType = "dyn_int";        break;
      case DPEL_DYN_ULONG:      sDataType = "dyn_ulong";      break;
      case DPEL_DYN_LONG:       sDataType = "dyn_long";       break;
      case DPEL_DYN_FLOAT:      sDataType = "dyn_float";      break;
      case DPEL_DYN_BOOL:       sDataType = "dyn_bool";       break;
      case DPEL_DYN_BIT32:      sDataType = "dyn_bit32";      break;
      case DPEL_DYN_BIT64:      sDataType = "dyn_bit64";      break;
      case DPEL_DYN_STRING:     sDataType = "dyn_string";     break;
      case DPEL_DYN_TIME:       sDataType = "dyn_time";       break;
      case DPEL_DYN_DPID:       sDataType = "dyn_dpId";       break;
      case DPEL_DYN_LANGSTRING: sDataType = "dyn_langString"; break;
      case DPEL_DYN_BLOB:       sDataType = "dyn_blob";       break;
      default:                  sDataType = "";               break;
    }

    sDataType = sDataType.toUpper();

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get transformation type of given tag
    @param sTagDp Tag Dp
    @param[out] sTransformationType Tag transformation type
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | given tag dp does not exist
            -2    | _address.._drv_ident attribute not found
            -3    | _address.._datatype attribute not found
  */
  public static int getTransformationType(const string &sTagDp, string &sTransformationType)
  {
    int iErr;
    int iTransformationType;
    string sDriverType;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    iErr = getAtrributeString(sTagDp, ":_address.._drv_ident", sDriverType);
    if(iErr < 0)
    {
      return -2;
    }

    iErr = getAtrributeInt(sTagDp, ":_address.._datatype", iTransformationType);
    if(iErr < 0)
    {
      return -3;
    }

    switch (sDriverType)
    {
      case DRIVER_NAME_S7:
      case DRIVER_NAME_SINUMERIK:
      {
        sTransformationType = convertS7TransformationType(iTransformationType);
        break;
      }

      case DRIVER_NAME_S7PLUS:
      {
        sTransformationType = convertS7PlusTransformationType(iTransformationType);
        break;
      }

      case DRIVER_NAME_FOCAS:
      {
        sTransformationType = convertFanucFocasTransformationType(iTransformationType);
        break;
      }

      case DRIVER_NAME_IEC61850:
      {
        sTransformationType = convertIEC61850TransformationType(iTransformationType);
        break;
      }
      
      case DRIVER_NAME_BACNET:
      {
        sTransformationType = convertBACnetTransformationType(iTransformationType);
        break;
      }

      default:
      {
        break;
      }
    }

    sTransformationType = sTransformationType.toUpper();

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Convert given S7 transformation type into string
    @param iType Transformation type
    @return Transformation type as string
  */
  private static string convertS7TransformationType(const int iType)
  {
    dyn_string dsTypes = makeDynString ("INT16", //701
                                        "INT32",
                                        "UINT16",
                                        "BYTE",
                                        "FLOAT", //705
                                        "BIT",
                                        "STRING",
                                        "UINT32",
                                        "DATEANDTIME",
                                        "BLOB",  //710
                                        "BITSTRING",
                                        "TIMESPAN",
                                        "TIMEOFDAY",
                                        "S5TIME",
                                        "TIMER",  //715
                                        "COUNTER",
                                        "DATE",
                                        "DATETIMELONG");

    return (iType >= S7_TRANSFORMATION_TYPE_OFFSET) ? dsTypes.at(iType - S7_TRANSFORMATION_TYPE_OFFSET) : "";
  }

  //------------------------------------------------------------------------------
  /**
    @brief Convert given S7Plus transformation type into string
    @param iType Transformation type
    @return Transformation type as string
  */
  private static string convertS7PlusTransformationType(const int iType)
  {
    dyn_string dsTypes = makeDynString ("DEFAULT",     //1001
                                        "BOOL",
                                        "BYTE",
                                        "WORD",
                                        "DWORD",       //1005
                                        "LWORD",
                                        "USINT",
                                        "UINT",
                                        "UDINT",
                                        "ULINT",       //1010
                                        "SINT",
                                        "INT",
                                        "DINT",
                                        "LINT",
                                        "REAL",        //1015
                                        "LREAL",
                                        "DATE",
                                        "DATETIME",
                                        "TIME",
                                        "TIME_OF_DAY", //1020
                                        "LDATETIME",
                                        "LTIME",
                                        "LTOD",
                                        "DTL",
                                        "S5TIME",      //1025
                                        "STRING",
                                        "WSTRING");

    return (iType >= S7PLUS_TRANSFORMATION_TYPE_OFFSET) ? dsTypes.at(iType - S7PLUS_TRANSFORMATION_TYPE_OFFSET) : "";
  }

  //------------------------------------------------------------------------------
  /**
    @brief Convert given FanucFocas transformation type into string
    @param iType Transformation type
    @return Transformation type as string
  */
  private static string convertFanucFocasTransformationType(const int iType)
  {
    dyn_string dsTypes = makeDynString ("BITINBYTE",
                                        "INT8",
                                        "INT16",
                                        "INT32",
                                        "UINT8",
                                        "UINT16",
                                        "UINT32",
                                        "FLOAT",
                                        "DOUBLE",
                                        "STRING",
                                        "BITINWORD",
                                        "BITINDWORD");

    return (iType >= FANUCFOCAS_TRANSFORMATION_TYPE_OFFSET) ? dsTypes.at(iType - FANUCFOCAS_TRANSFORMATION_TYPE_OFFSET) : "";
  }

  //------------------------------------------------------------------------------
  /**
    @brief Convert given IEC61850 transformation type into string
    @param iType Transformation type
    @return Transformation type as string
  */
  private static string convertIEC61850TransformationType(const int iType)
  {
    dyn_string dsTypes = makeDynString ("INT8",
                                        "INT32",
                                        "INT64",
                                        "UINT8",
                                        "UINT16",
                                        "UINT32",
                                        "FLOAT32",
                                        "BOOL",
                                        "BITSTRING",
                                        "OCTETSTRING64",
                                        "VISIBLESTRING64",
                                        "VISIBLESTRING255",
                                        "TIMESTAMP",
                                        "FLOAT64",
                                        "INT16");

    return (iType >= IEC61850_TRANSFORMATION_TYPE_OFFSET) ? dsTypes.at(iType - IEC61850_TRANSFORMATION_TYPE_OFFSET) : "";
  }

  //------------------------------------------------------------------------------
  /**
    @brief Convert given BACnet transformation type into string
    @param iType Transformation type
    @return Transformation type as string
  */
  private static string convertBACnetTransformationType(const int iType)
  {
    dyn_string dsTypes = makeDynString ("DEFAULT",
                                        "BOOLEAN",
                                        "UNSIGNED INTEGER",
                                        "SIGNED INTEGER",
                                        "REAL",
                                        "DOUBLE",
                                        "OCTETS",
                                        "STRING",
                                        "BITSTRING",
                                        "ENUMERATED",
                                        "DATE",
                                        "TIME",
                                        "DATETIME");

    return (iType >= BACNET_TRANSFORMATION_TYPE_OFFSET) ? dsTypes.at(iType - BACNET_TRANSFORMATION_TYPE_OFFSET) : "";
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get given attribute of given tag as string
    @param sTagDp Tag Dp (can be CNS ID too)
    @param sAttribut Tag attribute to read
    @param[out] sValue Value of attribute
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Given Dp does not exists
            -2    | Error reading given attribute
  */
  private static int getAtrributeString(const string &sTagDp, const string &sAttribut, string &sValue)
  {
    int iErr;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    iErr = dpGet(sTagDp + sAttribut, sValue);
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get given attribute of given tag as integer
    @param sTagDp Tag Dp (can be CNS ID too)
    @param sAttribut Tag attribute to read
    @param[out] iValue Value of attribute
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Given Dp does not exists
            -2    | Error reading given attribute
  */
  private static int getAtrributeInt(const string &sTagDp, const string &sAttribut, int &iValue)
  {
    int iErr;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    iErr = dpGet(sTagDp + sAttribut, iValue);
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get given attribute of given tag as float
    @param sTagDp Tag Dp (can be CNS ID too)
    @param sAttribut Tag attribute to read
    @param[out] fValue Value of attribute
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Given Dp does not exists
            -2    | Error reading given attribute
  */
  private static int getAtrributeFloat(const string &sTagDp, const string &sAttribut, float &fValue)
  {
    int iErr;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    iErr = dpGet(sTagDp + sAttribut, fValue);
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get given attribute of given tag as bool
    @param sTagDp Tag Dp (can be CNS ID too)
    @param sAttribut Tag attribute to read
    @param[out] bValue Value of attribute
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Given Dp does not exists
            -2    | Error reading given attribute
  */
  private static int getAtrributeBool(const string &sTagDp, const string &sAttribut, bool &bValue)
  {
    int iErr;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    iErr = dpGet(sTagDp + sAttribut, bValue);
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get address of given tag
    @param sCnsId CNS ID of Tag
    @param sTagDp Tag Dp
    @param[out] sAddress Tag address
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | _address attribute not found
            -2    | _address.._reference attribute not found
            -3    | _address.._drv_ident attribute not found
            -11   | MTConnect device list not found
            -12   | MTConnect device list is empty
            -13   | MTConnect device list invalid mapping
            -14   | MTConnect device list does not contain tag dp
  */
  public static int getAddress(const string &sCnsId, const string &sTagDp, string &sAddress)
  {
    int iErr;
    string sDriverType;
    string sDeviceId;
    string sProtocollName;

    iErr = Cns::getTagDeviceId(sCnsId, sDeviceId);
    iErr = Cns::getDeviceProtocolName(sDeviceId, sProtocollName);

    if(sProtocollName == DRIVER_NAME_MTCONNECT)
    {
      return getMTConnectAddress(sCnsId, sAddress);
    }

    if(!waitForAddress(sTagDp))
    {
      return -1;
    }

    iErr = getAtrributeString(sTagDp, ":_address.._reference", sAddress);
    if(iErr < 0)
    {
      return -2;
    }

    iErr = getAtrributeString(sTagDp, ":_address.._drv_ident", sDriverType);
    if(iErr < 0)
    {
      return -3;
    }

    switch (sDriverType)
    {
      case DRIVER_NAME_S7:
      case DRIVER_NAME_IEC61850:
      case DRIVER_NAME_BACNET:
      {
        splitAddress(sAddress);
        break;
      }

      case DRIVER_NAME_SINUMERIK:
      case DRIVER_NAME_S7PLUS:
      case DRIVER_NAME_FOCAS:
      default:
      {
        break;
      }

    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get MTConncet address of given tag
    @param sCnsId CNS ID of Tag
    @param[out] sAddress Tag address
    @return Error code
            value | description
            ------|------------
            0     | success
            -11   | MTConnect device list not found
            -12   | MTConnect device list is empty
            -13   | MTConnect device list invalid mapping
            -14   | MTConnect device list does not contain tag dp
  */
  private static int getMTConnectAddress(const string &sCnsId, string &sAddress)
  {
    int iErr;
    string sDeviceList;
    dyn_string dsMTConnectDps;
    dyn_mapping dmDeviceList;
    dyn_mapping dmTagList;

    iErr = dpGet(EB_MTCONNECT_DP_DEVICELIST, sDeviceList);
    if(iErr < 0)
    {
      return -11;
    }

    dmDeviceList = jsonDecode(sDeviceList);

    if(dmDeviceList.count() <= 0)
    {
      return -12;
    }

    for(int i = 1; i <= dmDeviceList.count(); i++)
    {
      if(!dmDeviceList[i].contains(KEY_EB_MTCONNECT_TAGLIST))
      {
        return -13;
      }
      dmTagList = dmDeviceList[i].value(KEY_EB_MTCONNECT_TAGLIST);

      for(int j = 1; j <= dmTagList.count(); j++)
      {
        if(dmTagList[j][KEY_EB_MTCONNECT_NODEID] == sCnsId)
        {
          sAddress = dmTagList[j][KEY_EB_MTCONNECT_ADDRESS];
          splitMTConnectAddress(sAddress);

          return 0;
        }
      }
    }

    return -14;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Split given address and remove PLC name (e.g. SPLC1.DB10 => DB10)s
    @param[out] sAddress Tag address
  */
  private static void splitAddress(string &sAddress)
  {
    vector<string> vsAddress;

    vsAddress = sAddress.split(".");
    vsAddress.removeAt(0);
    sAddress = "";
    for(int i = 0; i < vsAddress.count() - 1; i++)
    {
      sAddress += vsAddress.at(i) + ".";
    }
    if(vsAddress.count() > 0)
    {
      sAddress += vsAddress.last();
    }

    return;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Split given MTConnet address and remove PLC name (e.g. MAZAK-M77KP290337_1.id => id)
    @param[out] sAddress Tag address
  */
  private static void splitMTConnectAddress(string &sAddress)
  {
    vector<string> vsAddress;

    vsAddress = sAddress.split(".");
    if(dpExists(vsAddress.first()) && dynlen(dpNames("*", "MTC_" + vsAddress.first())) > 0)
    {
      vsAddress.removeAt(0);
    }
    sAddress = "";
    for(int i = 0; i < vsAddress.count() - 1; i++)
    {
      sAddress += vsAddress.at(i) + ".";
    }
    if(vsAddress.count() > 0)
    {
      sAddress += vsAddress.last();
    }

    return;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get poll rate of given tag
    @param sTagDp Tag Dp (can be CNS ID too)
    @param[out] iPollGroup Tag poll rate
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | _address attribute not found
            -2    | _address.._poll_group attribute not found
            -3    | corresponding intern dp with poll group not found
            -4    | could not get poll rate
  */
  public static int getAddressPollGroup(const string &sTagDp, int &iPollGroup)
  {
    int iErr;
    string sDp;

    if(!waitForAddress(sTagDp))
    {
      return -1;
    }

    iErr = getAtrributeString(sTagDp, ":_address.._poll_group", sDp);
    if(iErr < 0)
    {
      return -2;
    }

    if(!dpExists(sDp))
    {
      return -3;
    }

    iErr = dpGet(sDp + ".PollInterval", iPollGroup);
    if(iErr < 0)
    {
      return -4;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get aqusition type of given tag
    @param sTagDp Tag Dp (can be CNS ID too)
    @param[out] sAquiType Tag aqusition type
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | _address attribute not found
            -2    | _address.._direction attribute not found
  */
  public static int getAddressAquisitionType(const string &sTagDp, string &sAquiType)
  {
    int iErr;
    int iAddressDir;

    if(!waitForAddress(sTagDp))
    {
      return -1;
    }

    iErr = getAtrributeInt(sTagDp, ":_address.._direction", iAddressDir);
    if(iErr < 0)
    {
      return -2;
    }

    switch (iAddressDir)
    {
      case DPATTR_ADDR_MODE_INPUT_POLL: sAquiType = "READ";       break;
      case DPATTR_ADDR_MODE_IO_POLL:    sAquiType = "READ&WRITE"; break;
      case DPATTR_ADDR_MODE_IO_SQUERY:  sAquiType = "WRITE";      break;
      default:                          sAquiType = "";           break;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get low level comparison bit of tag
    @param sTagDp Tag Dp (can be CNS ID too)
    @param[out] bOnDataChange Tag low level comparison bit
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | _address attribute not found
            -2    | _address.._lowlevel attribute not found
  */
  public static int getAddressOnDataChange(const string &sTagDp, bool &bOnDataChange)
  {
    int iErr;

    if(!waitForAddress(sTagDp))
    {
      return -1;
    }

    iErr = getAtrributeBool(sTagDp, ":_address.._lowlevel", bOnDataChange);
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

   //------------------------------------------------------------------------------
  /**
    @brief Get _smooth config of tag
    @param sTagDp Tag Dp (can be CNS ID too)
    @param[out] fSmoothValue Value of _smooth config, if _smooth config does not exists value = 0
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | error reading given attribute
  */
  public static int getSmoothConfigValue(const string &sTagDp, float &fSmoothValue)
  {
    int iErr;

    iErr = getAtrributeFloat(sTagDp, ":_smooth.._std_tol", fSmoothValue);
    if(iErr < 0)
    {
      return -1;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Wait unit _address attribute of tag has been created
    @param sTagDp Tag Dp (can be CNS ID too)
    @param iMaxCnt Maximum time to wait in counts (1 count equals 100ms delay)
    @return Error code
            value | description
            ------|------------
            FALSE | _address has not been created during given timeout
            TRUE  | _address has been created
  */
  private static bool waitForAddress(const string &sTagDp, int iMaxCnt = 100)
  {
    int iAddressType;
    int iErr;
    int iCnt = 0;

    while(iCnt < iMaxCnt)
    {
      iErr = dpGet(sTagDp + ":_address.._type", iAddressType);
      if(iErr == 0 && iAddressType == DPCONFIG_PERIPH_ADDR_MAIN)
      {
        return TRUE;
      }

      delay(0, 100);
      iCnt++;
    }

    return FALSE;
  }

};

//--------------------------------------------------------------------------------
/*!
  @brief Base class for reading device data
  @details This class is used to get all necessary device information needed for automatic tests.
           All methods of this class are static.
*/
class Device
{
  //------------------------------------------------------------------------------
  /**
    @brief Get plc type of given driver dp
    @param sDriverType Driver Name
    @param uIndex Index of driver
    @param[out] sPlcType Driver Plc type
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Given driver name not found
            -2    | Could not read driver connection dp
            -3    | Mapping does not contain plcType
  */
  public static int getPlcType(const string &sDriverType, const uint uIndex, string &sPlcType)
  {
    int iErr;
    string sDrvInfo;
    string sDrvCon = dpSubStr(sDriverType + "#" + (string)uIndex, DPSUB_SYS_DP);
    dyn_string dsDrvConn = dpNames("*", EB_DRIVER_CONN_DPT);
    mapping mDrvInfo;

    if(!dsDrvConn.contains(sDrvCon))
    {
      return -1;
    }

    iErr = dpGet(sDrvCon + "." + EB_DRIVER_CONN_DP_INFO, sDrvInfo);
    if(iErr < 0)
    {
      return -2;
    }

    mDrvInfo = jsonDecode(sDrvInfo);

    if(!mDrvInfo.contains(KEY_EB_DRIVER_CONN_INFO_PLCTYPE))
    {
      return -3;
    }

    sPlcType = mDrvInfo.value(KEY_EB_DRIVER_CONN_INFO_PLCTYPE);

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get device type of driver dp
    @param sDriverType Driver Name
    @param uIndex Index of driver
    @param[out] uDeviceType Driver device type
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Could not read driver device type
  */
  public static int getDeviceType(const string &sDriverType, const uint uIndex, uint &uDeviceType)
  {
    int iErr;

    switch(sDriverType)
    {
      case DRIVER_NAME_S7:
      {
        iErr = getS7ConfigAttributeInt(S7_CONFIG_DP_CONN_TYPE, uIndex, uDeviceType);
        break;
      }

      case DRIVER_NAME_SINUMERIK:
      {
        iErr = getS7ConfigAttributeInt(S7_CONFIG_DP_CONN_TYPE, (uIndex + S7_CONFIG_SINUMERIK_OFFSET), uDeviceType);
        break;
      }

      default: break;
    }

    return iErr;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get slot of driver dp
    @param sDriverType Driver Name
    @param uIndex Index of driver
    @param[out] uDeviceSlot Driver slot
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Could not read driver slot
  */
  public static int getDeviceSlot(const string &sDriverType, const uint uIndex, uint &uDeviceSlot)
  {
    int iErr;

    switch(sDriverType)
    {
      case DRIVER_NAME_S7:
      {
        iErr = getS7ConfigAttributeInt(S7_CONFIG_DP_SLOT, uIndex, uDeviceSlot);
        break;
      }

      case DRIVER_NAME_SINUMERIK:
      {
        iErr = getS7ConfigAttributeInt(S7_CONFIG_DP_SLOT, (uIndex + S7_CONFIG_SINUMERIK_OFFSET), uDeviceSlot);
        break;
      }

      default: break;
    }

    return iErr;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get S7 connection uint attribute
    @param sAttribute Attribute of S7 connection to read (use constants)
    @param iIndex Index of driver
    @param[out] uValue Value read from dp
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not read given attribute
            -2    | list does not contain given index
  */
  private static int getS7ConfigAttributeInt(const string &sAttribute, const int iIndex, uint &uValue)
  {
    int iErr;
    dyn_uint duValue;

    iErr = dpGet(sAttribute, duValue);
    if(iErr < 0)
    {
      return -1;
    }

    if(duValue.count() < iIndex)
    {
      return -2;
    }

    uValue = duValue[iIndex];

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get connection state of given device
    @param sDriverType Type of device e.g. S7, Sinumerik, etc. use const DRIVER_NAME_*
    @param uIndex Index of driver e.g 1 for _S7PLC1
    @param[out] iConnState Value of connection state
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not read connection state of given device
  */
  public static int getConnState(const string &sDriverType, const uint uIndex, int &iConnState)
  {
    int iErr;
    string sDp;

    switch(sDriverType)
    {
      case DRIVER_NAME_S7:
      case DRIVER_NAME_SINUMERIK:
      {
        sDp = "_" + sDriverType + "PLC" + (string)uIndex + S7_CONN_CONNSTATE;
        break;
      }

      default: break;
    }

    iErr = dpGet(sDp, iConnState);
    if(iErr < 0)
    {
      return -1;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set connection state of given device and wait for value change on given dp
    @param sDriverType Type of device e.g. S7, Sinumerik, etc. use const DRIVER_NAME_*
    @param uIndex Index of driver e.g 1 for _S7PLC1
    @param iConnState Value of connection state
    @param sDpToWaitForValueChange Wait for value change on this dp
    @param daReturnValue Data from dp of sDpToWaitForValueChange
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not set connection state to given device
            -2    | wait for value change od given dp timed out
  */
  public static int setConnStateAndWaitForValue(const string &sDriverType, const uint uIndex, const int iConnState, const string &sDpToWaitForValueChange, dyn_anytype &daReturnValue)
  {
    bool bTimedOut;
    int iErr;
    string sDp;

    switch(sDriverType)
    {
      case DRIVER_NAME_S7:
      case DRIVER_NAME_SINUMERIK:
      {
        sDp = "_" + sDriverType + "PLC" + (string)uIndex + S7_CONN_CONNSTATE;
        break;
      }

      default: break;
    }

    iErr = dpSetAndWaitForValue(makeDynString(sDp), makeDynAnytype(iConnState),
                                makeDynString(sDpToWaitForValueChange + ":_original.._value_changed"), makeDynAnytype(TRUE),
                                makeDynString(sDpToWaitForValueChange + ":_original.._value"), daReturnValue, 10, bTimedOut);
    if(iErr < 0)
    {
      return -1;
    }

    return bTimedOut ? -2 : 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set connection state of given device
    @param sDriverType Type of device e.g. S7, Sinumerik, etc. use const DRIVER_NAME_*
    @param uIndex Index of driver e.g 1 for _S7PLC1
    @param iConnState Value of connection state
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not set connection state to given device
  */
  public static int setConnState(const string &sDriverType, const uint uIndex, const int iConnState)
  {
    int iErr;
    string sDp;

    switch(sDriverType)
    {
      case DRIVER_NAME_S7:
      case DRIVER_NAME_SINUMERIK:
      {
        sDp = "_" + sDriverType + "PLC" + (string)uIndex + S7_CONN_CONNSTATE;
        break;
      }

      default: break;
    }

    iErr = dpSetWait(sDp, iConnState);
    if(iErr < 0)
    {
      return -1;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get operation state of given device
    @param sDriverType Type of device e.g. S7, Sinumerik, etc. use const DRIVER_NAME_*
    @param uIndex Index of driver e.g 1 for _S7PLC1
    @param[out] iOpState Value of operation state
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not read operation state of given device
  */
  public static int getOpState(const string &sDriverType, const uint uIndex, int &iOpState)
  {
    int iErr;
    string sDp;

    switch(sDriverType)
    {
      case DRIVER_NAME_S7:
      case DRIVER_NAME_SINUMERIK:
      {
        sDp = "_" + sDriverType + "PLC" + (string)uIndex + S7_CONN_OPSTATE;
        break;
      }

      default: break;
    }

    iErr = dpGet(sDp, iOpState);
    if(iErr < 0)
    {
      return -1;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set operation state of given device and wait for value change on given dp
    @param sDriverType Type of device e.g. S7, Sinumerik, etc. use const DRIVER_NAME_*
    @param uIndex Index of driver e.g 1 for _S7PLC1
    @param iOpState Value of operation state
    @param sDpToWaitForValueChange Wait for value change on this dp
    @param daReturnValue Data from dp of sDpToWaitForValueChange
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not set operation state to given device
            -2    | wait for value change od given dp timed out
  */
  public static int setOpStateAndWaitForValue(const string &sDriverType, const uint uIndex, const int iOpState, const string &sDpToWaitForValueChange, dyn_anytype &daReturnValue)
  {
    bool bTimedOut;
    int iErr;
    string sDp;

    switch(sDriverType)
    {
      case DRIVER_NAME_S7:
      case DRIVER_NAME_SINUMERIK:
      {
        sDp = "_" + sDriverType + "PLC" + (string)uIndex + S7_CONN_OPSTATE;
        break;
      }

      default: break;
    }

    iErr = dpSetAndWaitForValue(makeDynString(sDp), makeDynAnytype(iOpState),
                                makeDynString(sDpToWaitForValueChange + ":_original.._value_changed"), makeDynAnytype(TRUE),
                                makeDynString(sDpToWaitForValueChange + ":_original.._value"), daReturnValue, 10, bTimedOut);
    if(iErr < 0)
    {
      return -1;
    }

    return bTimedOut ? -2 : 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set operation state of given device
    @param sDriverType Type of device e.g. S7, Sinumerik, etc. use const DRIVER_NAME_*
    @param uIndex Index of driver e.g 1 for _S7PLC1
    @param iOpState Value of operation state
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not set operation state to given device
  */
  public static int setOpState(const string &sDriverType, const uint uIndex, const int iOpState)
  {
    int iErr;
    string sDp;

    switch(sDriverType)
    {
      case DRIVER_NAME_S7:
      case DRIVER_NAME_SINUMERIK:
      {
        sDp = "_" + sDriverType + "PLC" + (string)uIndex + S7_CONN_OPSTATE;
        break;
      }

      default: break;
    }

    iErr = dpSetWait(sDp, iOpState);
    if(iErr < 0)
    {
      return -1;
    }

    return 0;
  }

};

//--------------------------------------------------------------------------------
/*!
  @brief Base class for helper methods
  @details This class is used for various helper methods needed for automatic tests.
           All methods of this class are static.
*/
class Helpers
{
  // Used for dpSetAndWaitForValue timeout
  private static const int TIME_OUT = 180;

  //------------------------------------------------------------------------------
  /**
    @brief Check if all given datapoint types are defined
    @param vDpt Array of datapoint types to check
    @return Error code
            value | description
            ------|------------
            FALSE | Missing datapoint type
            TRUE  | All datapoint types are defined
  */
  public static bool checkBaseDpt(const vector<string> &vDpt)
  {
    dyn_string dsDpTypes;

    dsDpTypes = dpTypes("*");

    for(int i = 0; i < vDpt.count(); i++)
    {
      if(!dsDpTypes.contains(vDpt.at(i)))
      {
        return FALSE;
      }
    }

    return TRUE;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check if all given datapoints are defined
    @param vDpt Array of datapoints to check
    @return Error code
            value | description
            ------|------------
            FALSE | Missing datapoint
            TRUE  | All datapoints are defined
  */
  public static bool checkBaseDp(const vector<string> &vDp)
  {
    for(int i = 0; i < vDp.count(); i++)
    {
      if(!dpExists(vDp.at(i)))
      {
        return FALSE;
      }
    }

    return TRUE;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get number of datapoints for given datapoint type
    @param sDpt Datapoint type
    @return Datapoint count
  */
  public static int getDptCount(const string &sDpt)
  {
    dyn_string dsDps;

    dsDps = dpNames("*", sDpt);

    for(int i = 0; i < DP_TO_IGNORE.count(); i++)
    {
      dyn_bool dbIgnore = patternMatch(DP_TO_IGNORE.at(i),dsDps);
      for (int j = dynlen(dbIgnore); j > 0; j--)
      {
        if (dbIgnore[j])
        {
          dsDps.removeAt(j-1);
        }
      }
    }

    return dsDps.count();
  }

  //------------------------------------------------------------------------------
  /**
    @brief Read json file, check if content is valid and write content to string
    @param sInputFilePath File path
    @param sEncoding Encoding of file
    @param[out] sJsonString String containig file content
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Could not read file
            -2    | Json content unvalid
  */
  public static int readJsonFile(const string &sInputFilePath, const string &sEncoding, string &sJsonString)
  {
    int iErr;

    iErr = fileToString(sInputFilePath, sJsonString, sEncoding);
    if(iErr < 0)
    {
      return -1;
    }

    if(!json_isValid(sJsonString))
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set a given string to the mqtt receive datapoint
    @param sMqttString String to set
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Error in dpGet
            -2    | Error in dpSet
            -3    | Timeout from script
  */
  public static MqttErrorCodes setMqttString(const string &sMqttString)
  {
    int iErr;
    bool bTimedOut;
    string sCurrentMqttString;
    dyn_anytype daReturnValues;

    iErr = dpGet(MQTT_DP_CONFIG, sCurrentMqttString);
    if(iErr < 0)
    {
      return MqttErrorCodes::errGetJsonString;
    }

    // Do not set mqttString if same string shall be written
    if(sCurrentMqttString == sMqttString)
    {
      return MqttErrorCodes::noError;
    }

    iErr = dpSetAndWaitForValue(makeDynString(MQTT_DP_REC_DATA),
                                makeDynAnytype(sMqttString),
                                makeDynString(MQTT_DP_CONFIG),
                                makeDynAnytype(sMqttString),
                                makeDynString(MQTT_DP_CONFIG),
                                daReturnValues,
                                TIME_OUT,
                                bTimedOut);
    if (!bTimedOut && sMqttString == "[]") //to avoid pmon detecting manager stopped a second ago to be blocking on inserting again
    {
      delay(1);
    }

    if(iErr < 0)
    {
      return MqttErrorCodes::errSetJsonString;
    }

    return bTimedOut ? MqttErrorCodes::errTimeOut : MqttErrorCodes::noError;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get mqtt receive datapoint string
    @param[out] sMqttString String from mqtt receive datapoint
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Error in dpGet
  */
  public static int getMqttString(string &sMqttString)
  {
    return dpGet(MQTT_DP_REC_DATA, sMqttString);
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set dp(s) and wait for value change mqtt receive datapoint string
    @param dpList Array of dps to set
    @param valueList Array of values to set to given dps
    @param jsonDpToCheck Dp to check for value change
    @return Mapping with data from dp to wait (jsonDpToCheck)
  */
  public static dyn_anytype dpSetdelayed(const dyn_string &dpList, const dyn_anytype &valueList, const string &jsonDpToCheck, bool &bIsTimedOut, int iTimeOut = TIME_OUT)
  {
    dyn_anytype daConfig;

    dpSetAndWaitForValue(dpList, valueList,
                         (jsonDpToCheck + ":_original.._value_changed"), makeDynAnytype(TRUE),
                         (jsonDpToCheck + ":_original.._value"), daConfig, iTimeOut, bIsTimedOut);
    return daConfig;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set dp(s) and wait for value change mqtt receive datapoint string
    @param dpList Array of dps to set
    @param valueList Array of values to set to given dps
    @param jsonDpToCheck Dp to check for value change
    @return Mapping with data from dp to wait (jsonDpToCheck)
  */
  public static dyn_anytype dpSetdelayedMultiple(dyn_string &dpList, dyn_anytype &valueList , const dyn_string &dsDpsToCheck)
  {
    bool bTimeout;
    dyn_string dsDpNamesWait;
    dyn_string dsDpNamesReturn;
    dyn_anytype daConditions;
    dyn_anytype dmConfig;

    for(int i = 0; i < dsDpsToCheck.count(); i++)
    {
      dsDpNamesWait.append(dsDpsToCheck.at(i) + ":_original.._value_changed");
      dsDpNamesReturn.append(dsDpsToCheck.at(i) + ":_original.._value");
      daConditions.append(TRUE);
    }

    dpSetAndWaitForValue(dpList, valueList, dsDpNamesWait, daConditions, dsDpNamesReturn, dmConfig, TIME_OUT, bTimeout);

    return dmConfig;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get value (_online) of given _userbit of given tag
    @param sTagDp Tag dp
    @param uUserBit Index of _userbit to read e.g. 1 for _userbit1
    @param[out] bValue Value of userbit
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | given tag dp does not exist
            -2    | failed to read given tag dp
  */
  public static int getTagUserBit(const string &sTagDp, const uint uUserBit, bool &bValue)
  {
    int iErr;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    iErr = dpGet(sTagDp + ":_online.._userbit" + (string)uUserBit, bValue);
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set value (_online) of given _userbit of given tag
    @param sTagDp Tag dp
    @param uUserBit Index of _userbit to set e.g. 1 for _userbit1
    @param bValue Value of userbit
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | given tag dp does not exist
            -2    | failed to read given tag dp
  */
  public static int setTagUserBit(const string &sTagDp, const uint uUserBit, bool bValue)
  {
    int iErr;

    if(!dpExists(sTagDp))
    {
      return -1;
    }

    iErr = dpSetWait(sTagDp + ":_original.._userbit" + (string)uUserBit, bValue);
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get array with certificates for given path
    @param sDriverCertPath Path to certificates
    @param[out] dsCerts Array of certifiactes found in directory
    @param bWithPath When TRUE array contains complete path, when FALSE array contains only filename
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | given tpath is unvalid
  */
  public static int getCertificates(const string &sDriverCertPath, dyn_string &dsCerts, bool bWithPath = FALSE)
  {
    bool bIsPath;
    string sPath = getPath(DATA_REL_PATH + sDriverCertPath);

    bIsPath = isdir(sPath);
    if(!bIsPath)
    {
      return -1;
    }

    dsCerts = getFileNames(sPath);

    if(bWithPath)
    {
      for(int i = 0; i < dsCerts.count(); i++)
      {
        dsCerts.at(i) = sPath + "/" + dsCerts.at(i);
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get Index of connection DP e.g. _S7PLC1 -> 1
    @param sCnsDeviceId CNS device ID
    @param[out] uIndex Index of connection DP
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | error reading CNS
  */
  public static int getIndexOfConnectionDp(const string &sCnsDeviceId, uint &uIndex)
  {
    int iErr;
    string sDeviceDp;
    dyn_string dsSplit;

    iErr = Cns::getDpFromId(sCnsDeviceId, sDeviceDp);
    if(iErr)
    {
      return -1;
    }

    sDeviceDp = dpSubStr(sDeviceDp, DPSUB_DP);

    dsSplit = sDeviceDp.split("#");

    uIndex = (int)dsSplit.last();

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check if given log table contains given log entry (constants LOG_NUMBER_*)
    @param ddaLogs Log table
    @param sExpectedLogEntry Expected log entry (see constants LOG_NUMBER_*)
    @param[out] bContains Flag if long entry is in log table
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Log table is empty
            -2    | Expected log entry is empty string
  */
  public static int checkLogTableContains(const dyn_dyn_anytype &ddaLogs, const string &sExpectedLogEntry, bool &bContains)
  {
    int iErr;

    if(ddaLogs.count() <= 1)
    {
      return -1;
    }
    if(sExpectedLogEntry.length() <= 0)
    {
      return -2;
    }

    bContains = FALSE;

    for(int  i = 2; i <= ddaLogs.count(); i++)
    {
      string sCurrentLogEntry = ddaLogs[i][6];

      if(sCurrentLogEntry == sExpectedLogEntry)
      {
        bContains = TRUE;
        break;
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check if given log string contains given log entry (constants LOG_NUMBER_*)
    @param sLogs Log string
    @param sExpectedLogEntry Expected log entry (see constants LOG_NUMBER_*)
    @param[out] bContains Flag if long entry is in log table
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Log string is empty

  */
  public static int checkLogStringContains(const string &sLogs, const string &sExpectedLogEntry, bool &bContains)
  {
    int iErr;
    mapping mLogs;

    if(sLogs == "")
    {
      return -1;
    }

    mLogs = jsonDecode(sLogs);

    bContains = FALSE;

    for(int  i = 1; i <= dynlen(mLogs["logs"]); i++)
    {
      string sCurrentLogEntry = mLogs["logs"][i]["reason"];

      if(sCurrentLogEntry == sExpectedLogEntry)
      {
        bContains = TRUE;
        break;
      }
    }

    return 0;
  }

};

//--------------------------------------------------------------------------------
/*!
  @brief Base class for Mqtt mapping helper methods
  @details This class is used for reading Mqtt mapping informations needed for automatic tests.
           All methods of this class are static.
*/
class Mqtt
{
  // Length of mindsphere tag id
  public static const int MINDPSPHERE_TAG_ID_LENGTH = 13;
  // Length of mindsphere device id
  public static const int MINDPSPHERE_DEVICE_ID_LENGTH = 36;

  //------------------------------------------------------------------------------
  /**
    @brief Get every Mqtt mapping
    @param[out] dmMqttMapping Mqtt mapping
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to read dp
  */
  public static int getDynMapping(dyn_mapping &dmMqttMapping)
  {
    int iErr;
    string sMqttMapping;

    dmMqttMapping.clear();

    iErr = dpGet(MQTT_DP_MAP, sMqttMapping);
    if(iErr < 0)
    {
      return -1;
    }

    dmMqttMapping = jsonDecode(sMqttMapping);

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get Mqtt mapping for given index
    @param iIndex Index of dynamic mapping
    @param[out] mMqttMapping Mqtt mapping
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to read dp
            -1    | index not found in dynamic mapping
  */
  public static int getMapping(const int iIndex, mapping &mMqttMapping)
  {
    int iErr;
    dyn_mapping dmMqttMapping;

    mMqttMapping.clear();

    iErr = getDynMapping(dmMqttMapping);
    if(iErr < 0)
    {
      return -1;
    }

    if(dmMqttMapping.count() < iIndex)
    {
      return -2;
    }

    mMqttMapping = dmMqttMapping.at(iIndex);

    return 0;
  }

};

//--------------------------------------------------------------------------------
/*!
  @brief Base class for Mqtt communication Dpt helper methods
  @details This class is used for reading  Mqtt communication dps informations needed for automatic tests.
           All methods of this class are static.
*/
class MqttComm
{
  //------------------------------------------------------------------------------
  /**
    @brief Get every Mqtt communciaton dp
    @return Array of dps
  */
  public static dyn_string getDps()
  {
    return dpNames("*", MQTT_COMM_DPT);
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get mapping of given mqtt communication dp attribute
    @param iIndex Index of communication dp e.g. 1 for MNSP_MQTT_COMM_1
    @param sDpe Attribute to read e.g. MNSP_MQTT_COMM_1.Data (use constants MQTT_COMM_*)
    @param[out] dmData Mapping from dpe
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | given index is invalid
            -2    | failed to read given dp attribute
            -3    | time out dpe contains empty string
  */
  public static int getMapping(const string &sMqttDp, const string &sDpe, dyn_mapping &dmData, int iMaxCnt = 50)
  {
    int iErr;
    int iCnt;
    string sData;
    dyn_string dsMqttCommDps = getDps();

    if(!dsMqttCommDps.contains(dpSubStr(sMqttDp, DPSUB_SYS_DP)))
    {
      return -1;
    }

    // wait max. 10 seconds until callback of mnsp script writes dpe
    while(iCnt < iMaxCnt)
    {
      iErr = dpGet(sMqttDp + sDpe, sData);
      if(iErr < 0)
      {
        return -2;
      }
      if(sData != "")
      {
        dmData = jsonDecode(sData);
        return 0;
      }

      delay(0, 200);
      iCnt++;
    }

    return -3;
  }

};
