// $License: NOLICENSE
//--------------------------------------------------------------------------------
/** Tests for the ctrl manager: scripts/mnsp.ctl
  @file $relPath
  @test Use case tests for script: scripts/mnsp.ctl
  @copyright $copyright
  @author z0043ctz
 */

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "classes/projectEnvironment/ProjEnvProject"
#uses "tests/tstBrowsing"
#uses "ascii"
#uses "classes/oaTest/OaTest"
#uses "tests/testHelpers"
#uses "fileSystem"
#uses "classes/oaTest/OaTestResultJson"
#uses "classes/oaTest/OaTestResultJUnit"
#uses "classes/EBlog"
#uses "pmonInterface"

//--------------------------------------------------------------------------------
// Variables and Constants

// Empty Mqtt string for test setup
const string EMPTY_MQTT_STRING = "[]";

// List of all DPTs which have to exists in project
const vector<string> MNSP_DPT = makeVector("EB_Bool",
                                           "EB_Float");

// List of all DPs which have to exists in project
const vector<string> MNSP_DP = makeVector("MindSphereConnector");

// Mapping used for checking mapping_dataPointId
const dyn_mapping MAP_MQTT_MAPPINGS = makeDynMapping(makeMapping("count",   0,
                                                                 "toCheck", "key",
                                                                 "length",  (int)Mqtt::MINDPSPHERE_TAG_ID_LENGTH),
                                                     makeMapping("count",   0,
                                                                 "toCheck", "value",
                                                                 "length",  (int)Mqtt::MINDPSPHERE_TAG_ID_LENGTH),
                                                     makeMapping("count",   0,
                                                                 "toCheck", "value",
                                                                 "length",  (int)Mqtt::MINDPSPHERE_DEVICE_ID_LENGTH),
                                                     makeMapping("count",   0,
                                                                 "toCheck", "key",
                                                                 "length",  (int)Mqtt::MINDPSPHERE_DEVICE_ID_LENGTH),
                                                     makeMapping("count",   0,
                                                                 "toCheck", "key",
                                                                 "length",  (int)Mqtt::MINDPSPHERE_DEVICE_ID_LENGTH));

// Mapping used for checking internal device DPTs
const mapping MAP_DEVICE_DPTS = makeMapping("_S7_Conn",          0,
                                            "_FocasConnection",  0,
                                            "_S7PlusConnection", 0,
                                            "_IEC61850_IED",     0,
                                            "_MTConnect",        0,
                                            "_BacnetDevice",     0);

const string KEY_DEVICE_DPTS_MQTT     = "MNSP_MQTT_COMM";
const string KEY_DEVICE_DPTS_DRV_CONN = "_EB_DriverConnection";

// Mapping used for checking tag DPTs
const mapping MAP_TAG_DPTS = makeMapping("EB_Int",    0,
                                         "EB_Bool",   0,
                                         "EB_Float",  0,
                                         "EB_Uint",   0,
                                         "EB_String", 1,
                                         "EB_Time",   0);

// Pmon indexes
const int PMON_INDEX_MNSP_SCRIPT = 6;

// Encoding for all testfiles
const string ENCODING = "UTF8";

// Path to test result files
const string PATH_TO_FULL_RESULT_FILE  = PROJ_PATH + "fullResult.json";
const string PATH_TO_JUNIT_RESULT_FILE = PROJ_PATH + DATA_REL_PATH + "oaTest/results/";
const string JUNIT_FILE_EXTENSION      = ".xml";

//--------------------------------------------------------------------------------
/*!
  @brief Base class for use case tests for mnsp.ctl
  @details This class is derived from OaTest
*/
class TstMnsp : OaTest
{
  const bool bHasFanucFocas = getPath(BIN_REL_PATH, "WCCOAfocas") == "" ? FALSE : TRUE;

  // Flag indicating if test has been aborted
  public bool m_bTestAborted = FALSE;

  // Mapping contains current data from Mqtt file
  public dyn_mapping m_dmMqttData;

  // Mapping contains expected Mqtt mapping
  public dyn_mapping m_dmExpectedMqttMapping;

  // Mapping contains expected device
  public mapping m_mExpectedDeviceDps;

  // Mapping contains expected tags
  public mapping m_mExpectedTagDps;

  // PollRate
  public dyn_mapping m_dmExpectedPollRate;
  public const string MAP_KEY_POLLRATE_TAG      = "tag";
  public const string MAP_KEY_POLLRATE_MILLISEC = "pollrate";

  // LowLevel
  public dyn_mapping m_dmExpectedLowLevel;
  public const string MAP_KEY_LOWLEVEL_TAG  = "tag";
  public const string MAP_KEY_LOWLEVEL_FLAG = "lowlevel";

  // TimeSource
  public dyn_mapping m_dmExpectedTimeSource;
  public const string MAP_KEY_TIMESOURCE_TAG  = "tag";
  public const string MAP_KEY_TIMESOURCE_FLAG = "timesource";
  public const bool TIME_FROM_FIELD  = TRUE;
  public const bool TIME_FROM_SERVER = FALSE;

  // Command Values
  public mapping m_mExpectedTagCmd;
  public mapping m_mExpectedCmdResult;

  // Driver default values
  public mapping m_mExpectedDriverSettings;
  public const string KEY_DRV_DEFAULT_DEVTYPE = "deviceType";
  public const string KEY_DRV_DEFAULT_DEVSLOT = "deviceSlot";
  public const string KEY_DRV_DEFAULT_PLCTYPE = "plcType";

  public const mapping MAP_DRV_DEFAULT_S7 = makeMapping(KEY_DRV_DEFAULT_DEVTYPE, 2,
                                                        KEY_DRV_DEFAULT_DEVSLOT, 2,
                                                        KEY_DRV_DEFAULT_PLCTYPE, "S7 1500");

  public const mapping MAP_DRV_DEFAULT_SINUMERIK = makeMapping(KEY_DRV_DEFAULT_DEVTYPE, 768,
                                                               KEY_DRV_DEFAULT_DEVSLOT, 3,
                                                               KEY_DRV_DEFAULT_PLCTYPE, "Sinumerik 840D");

  // Quality status bits
  public const int QUALITY_CODE_BAD_DISCONNECT   = -2136145920;
  public const int QUALITY_CODE_BAD_CONNECTION   = -2136211456;
  public const int QUALITY_CODE_INVALID_ARGUMENT = -2136276992;
  public const int QUALITY_CODE_GOOD_ARGUMENT    = 0;

  // Certificate handling
  public mapping m_mExpectedCerts;

  // Logging
  public const time TEST_START_TIMESTAMP = getCurrentTime();
  public time m_tTestCaseStart;
  public dyn_string m_dsExpectedLogEntries;

  // Hysteresis
  public mapping m_mExpectedHysteresis;

  // Browsing
  public const string PATH_TO_BROWSE_RESULT_FILE = "/persistent_massdata/appData/browsing";
  public const int    MAX_FILE_SIZE = 16384;  // Constant for gzread of zipped browsing result

  // project environment
  ProjEnvProject m_proj = ProjEnvProject(PROJ);
  const float MAN_TIME_OUT = 30.0;

  //------------------------------------------------------------------------------
  /**
    @brief Set Mqtt string and store content of string in m_dmMqttData
    @param sMqttString Mqtt string to set
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to set Mqtt string
  */
  public int setUpTest()
  {
    int iErr;

    // check if all necessary DPT are defined
    if(!Helpers::checkBaseDpt(MNSP_DPT))
    {
      return testAbort("Not all necessary DPTs defined");
    }

    // check if all necessary DP are defined
    if(!Helpers::checkBaseDp(MNSP_DP))
    {
      return testAbort("Not all necessary DPs defined");
    }

    // set empty Mqtt string to start clean
    iErr = (int)Helpers::setMqttString(EMPTY_MQTT_STRING);
    if(iErr)
    {
      return testAbort("Reset mqtt string failed");
    }

    pass("Setup of automatic test OK");

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set Mqtt string and store content of string in m_dmMqttData
    @param sMqttString Mqtt string to set
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to set Mqtt string
  */
  public MqttErrorCodes setMqttString(const string &sMqttString)
  {
    m_dmMqttData.clear();
    m_dmMqttData = jsonDecode(sMqttString);

    return Helpers::setMqttString(sMqttString);
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set Mqtt string from given file and store content of string in m_dmMqttData
    @param sFilePath Relativ path of file to set. (root is data path)
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failed to read json file
            -2    | failed to set Mqtt string
  */
  public MqttErrorCodes setMqttStringFromFile(string sFilePath)
  {
    int iErr;
    string sJsonString;

    sFilePath = getPath(DATA_REL_PATH, sFilePath);

    iErr = Helpers::readJsonFile(sFilePath, ENCODING, sJsonString);
    if(iErr)
    {
      return MqttErrorCodes::errReadMqttFile;
    }

    return setMqttString(sJsonString);
  }

  //------------------------------------------------------------------------------
  /**
    @brief Reset mappings needed for checkBasicFunctions TCs
  */
  public void resetCheckBasicFunctions()
  {
    // Reset expected device Dps
    m_mExpectedDeviceDps.clear();
    m_mExpectedDeviceDps = MAP_DEVICE_DPTS;

    // Reset expected tag Dps
    m_mExpectedTagDps.clear();
    m_mExpectedTagDps = MAP_TAG_DPTS;

    // Reset expected Mqtt mapping
    m_dmExpectedMqttMapping.clear();
    m_dmExpectedMqttMapping = MAP_MQTT_MAPPINGS;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set mappings needed for checkBasicFunctions TCs
  */
  public void setCheckBasicFunctions()
  {
    int iExpectedDeviceCnt;
    int iExpectedTagCnt;

    for(int i = 0; i < m_mExpectedDeviceDps.count(); i++)
    {
      iExpectedDeviceCnt += m_mExpectedDeviceDps.valueAt(i);
    }

    for(int i = 0; i < m_mExpectedTagDps.count(); i++)
    {
      iExpectedTagCnt += m_mExpectedTagDps.valueAt(i);
    }

    // Define expected device DPs
    m_mExpectedDeviceDps[KEY_DEVICE_DPTS_DRV_CONN] = iExpectedDeviceCnt;
    m_mExpectedDeviceDps[KEY_DEVICE_DPTS_MQTT]     = iExpectedDeviceCnt;

    // Define expected Mqtt mapping
    m_dmExpectedMqttMapping.at((int)MqttMapping::TAG_MNSP_ID_TO_CNS_ID)["count"]         = iExpectedTagCnt;
    m_dmExpectedMqttMapping.at((int)MqttMapping::TAG_DP_NAME_TO_MNSP_ID)["count"]        = iExpectedTagCnt;
    m_dmExpectedMqttMapping.at((int)MqttMapping::TAG_DP_NAME_TO_DEVICE_MNSP_ID)["count"] = iExpectedTagCnt;
    m_dmExpectedMqttMapping.at((int)MqttMapping::DEVICE_MNSP_ID_TO_DP_NAME)["count"]     = iExpectedDeviceCnt;
    m_dmExpectedMqttMapping.at((int)MqttMapping::DEVICE_MNSP_ID_TO_CNS_ID)["count"]      = iExpectedDeviceCnt;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check CNS structure, device Dps, tag Dps, tag attributes and Mqtt mapping for TC.
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkBasicFunctions()
  {
    int iErr;

    iErr = checkCnsStructure(m_dmMqttData);
    if(iErr < 0)
    {
      return testAbort("Error in checkCnsStructure");
    }

    iErr = checkDpCount(m_mExpectedDeviceDps);
    if(iErr < 0)
    {
      return testAbort("Error in checkDpCount of device DPs");
    }

    iErr = checkDpCount(m_mExpectedTagDps);
    if(iErr < 0)
    {
      return testAbort("Error in checkDpCount of tag DPs");
    }

    iErr = checkAllDpAttributes(m_dmMqttData);
    if(iErr < 0)
    {
      return testAbort("Error in checkAllDpAttributes");
    }

    iErr = checkMqttTopics(m_dmMqttData);
    if(iErr < 0)
    {
      return testAbort("Error in checkMqttTopics");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Compare CNS structure with given mapping
    @param dmMqtt Mapping with expected CNS structure
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkCnsStructure(const dyn_mapping &dmMqtt)
  {
    int iErr;
    dyn_string dsCnsDeviceNames;

    iErr = Cns::getAllDeviceNames(dsCnsDeviceNames);
    if(iErr < 0)
    {
      return testAbort("Error in Cns::getAllDeviceNames");
    }

    assertEqual(dsCnsDeviceNames.count(), dmMqtt.count(), "Check if same device count");

    for(int i = 0; i < dmMqtt.count(); i++)
    {
      iErr = checkCnsDevice(dmMqtt.at(i), dsCnsDeviceNames);
      if(iErr < 0)
      {
        return testAbort("Error in checkCnsDevice at <" + i + ">");
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Compare CNS device structure with given mapping
    @param dmMqtt Mapping with expected CNS device structure
    @param dsCnsDeviceNames Array containing all CNS device names
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkCnsDevice(const mapping &mMqttDevice, const dyn_string &dsCnsDeviceNames)
  {
    int iErr;
    dyn_mapping dsMqttTags;
    mapping mCnsDeviceNamesToIds;
    dyn_string dsCnsDataPoints;
    string sCnsProtocol;

    if(!mMqttDevice.contains("name"))
    {
      return testAbort("Key <" + "name" + "> in mapping " + mMqttDevice + " not found");
    }
    assertTrue(dsCnsDeviceNames.contains(mMqttDevice.value("name")), "Check if device is found in CNS structure");

    iErr = Cns::getDeviceNamesToIdsMapping(mCnsDeviceNamesToIds);
    if(iErr < 0)
    {
      return testAbort("Error in getDeviceNamesToIdsMapping");
    }

    if(!mMqttDevice.contains("protocol"))
    {
      return testAbort("Key <" + "protocol" + "> in mapping " + mMqttDevice + " not found");
    }
    Cns::getDeviceProtocolName(mCnsDeviceNamesToIds.value(mMqttDevice.value("name")), sCnsProtocol);
    assertEqual(sCnsProtocol.toUpper(), mMqttDevice.value("protocol"), "Check if device has correct parent (protocol) in CNS");

    if(!mMqttDevice.contains("dataPoints"))
    {
      return testAbort("Key <" + "dataPoints" + "> in mapping " + mMqttDevice + " not found");
    }
    dsMqttTags = mMqttDevice.value("dataPoints");
    Cns::getTagNames(mCnsDeviceNamesToIds.value(mMqttDevice.value("name")), dsCnsDataPoints);

    assertEqual(dsCnsDataPoints.count(), dsMqttTags.count(), "Check if tag count of device is equal to CNS structure");

    for(int i = 0; i < dsMqttTags.count(); i++)
    {
      iErr = checkCnsTag(dsMqttTags.at(i), dsCnsDataPoints);
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Compare CNS tag data with given mapping
    @param mMqttTag Mapping with expected CNS tag data
    @param dsCnsDataPoints Array containing all CNS tag names
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkCnsTag(const mapping &mMqttTag, const dyn_string &dsCnsDataPoints)
  {
    if(!mMqttTag.contains("name"))
    {
      return testAbort("Key <" + "name" + "> in mapping " + mMqttTag + " not found");
    }

    assertTrue(dsCnsDataPoints.contains(mMqttTag.value("name")), "Check if tag is defined in CNS");

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check if every Datapoint type has same number of datapoints as expected in given mapping
    @param mExpectedResult Mapping with expected number of datapoints
    @return always 0
  */
  public int checkDpCount(const mapping &mExpectedResult)
  {
    mapping m;

    for(int i = 0; i < mExpectedResult.count(); i++)
    {
      assertEqual(Helpers::getDptCount(mExpectedResult.keyAt(i)), mExpectedResult.valueAt(i), "Check if DPT <" + mExpectedResult.keyAt(i) + "> count equals expected value");
    }

    return 0;
  }


  //------------------------------------------------------------------------------
  /**
    @brief Compare attributes of all datapoints with given mapping
    @param dmMqtt Mapping with expected attribute data for every datapoint
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkAllDpAttributes(const dyn_mapping &dmMqtt)
  {
    int iErr;
    mapping mCnsTagsToIds;

    iErr = Cns::getTagNamesToIdMapping(mCnsTagsToIds);
    if(iErr < 0)
    {
      return testAbort("Error in Cns::getTagNamesToIdMapping");
    }

    for(int i = 0; i < dmMqtt.count(); i++)
    {
      mapping mMqttDevice = dmMqtt.at(i);

      if(!mMqttDevice.contains("dataPoints"))
      {
        return testAbort("Key <" + "dataPoints" + "> in mapping " + mMqttDevice + " not found");
      }

      for(int j = 0; j < mMqttDevice["dataPoints"].count(); j++)
      {
        mapping mMqttTag = mMqttDevice["dataPoints"].at(j);
        string sCnsId;

        if(!mMqttTag.contains("name"))
        {
          return testAbort("Key <" + "name" + "> in mapping " + mMqttTag + " not found");
        }
        sCnsId = mCnsTagsToIds.value(mMqttTag.value("name"));

        iErr = checkDpAttributes(mMqttTag, sCnsId);
        if(iErr < 0)
        {
          return -1;
        }
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Compare attributes of given datapoint with given mapping
    @param mMqttTag Mapping with expected attribute data for datapoint
    @param sCnsId CNS ID of datapoint to check
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkDpAttributes(const mapping &mMqttTag, const string &sCnsId)
  {
    int iErr;
    string sDp;
    string sTagDescription;
    string sTagUnit;
    string sTagDataType;
    string sTagAddress;

    iErr = Cns::getDpFromId(sCnsId, sDp);
    if(iErr < 0)
    {
      return testAbort("Error in Cns::getDpFromId for Id <" + sCnsId + ">");
    }

    if(mMqttTag.contains("description"))
    {
      Tag::getDescription(sDp, sTagDescription);
      assertEqual(sTagDescription, mMqttTag.value("description"), "Check description of Tag <" + sDp + ">");
    }

    if(mMqttTag.contains("unit"))
    {
      Tag::getUnit(sDp, sTagUnit);
      assertEqual(sTagUnit, mMqttTag.value("unit"), "Check unit of Tag <" + sDp + ">");
    }

//     if(mMqttTag.contains("dataType"))
//     {
//       Tag::getDataType(sDp, sTagDataType);
//       assertEqual(sTagDataType, mMqttTag.value("dataType"), "");
//     }

    if(mMqttTag.contains("dataPointData"))
    {
      if(mMqttTag["dataPointData"].contains("address"))
      {
        iErr = Tag::getAddress(sCnsId, sDp, sTagAddress);
        if(iErr < 0)
        {
          testAbort("Unable to read address of Tag <" + sDp + ">. ErrorCode(" + iErr + ")");
        }
        assertEqual(sTagAddress, mMqttTag["dataPointData"].value("address"), "Check address of Tag <" + sDp + ">");
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Compare Mqtt mapping with given mapping
    @param dmExpectedMqttMapping Mapping with expected mqtt mapping
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkMqttMapping(dyn_mapping &dmExpectedMqttMapping)
  {
    int iErr;
    dyn_mapping dmMqttMapping;

    iErr = Mqtt::getDynMapping(dmMqttMapping);
    if(iErr < 0)
    {
      return testAbort("Failed to get Mqtt mapping");
    }

    assertEqual(dmMqttMapping.count(), dmExpectedMqttMapping.count(), "Check Mqtt mapping count");

    for(int i = 0; i < dmMqttMapping.count(); i++)
    {
      mapping mMqttMapping = dmMqttMapping.at(i);
      mapping mMqttExpectedMapping = dmExpectedMqttMapping.at(i);

      assertEqual(mMqttMapping.count(), mMqttExpectedMapping.value("count"), "check Mqtt mapping entries count");

      if(mMqttExpectedMapping.value("toCheck") == "key")
      {
        for(int j = 0; j < mMqttMapping.count(); j++)
        {
          assertEqual(strlen(mMqttMapping.keyAt(j)), mMqttExpectedMapping.value("length"), "Check Mnsp ID length of mapping key");
        }
      }
      else if(mMqttExpectedMapping.value("toCheck") == "value")
      {
        for(int j = 0; j < mMqttMapping.count(); j++)
        {
          assertEqual(strlen(mMqttMapping.valueAt(j)), mMqttExpectedMapping.value("length"), "Check Mnsp ID length of mapping value");
        }
      }
      else
      {
        return testAbort("Unknown value <" + mMqttExpectedMapping.value("toCheck") + "> in mapping key <" + "toCheck" + ">");
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Compare Mqtt mapping with given mapping
    @param dmExpectedMqttMapping Mapping with expected mqtt mapping
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkMqttTopics(dyn_mapping &dmExpectedMqttMapping)
  {
    int iErr;
    const dyn_string dsTopicsToCheck = makeDynString(MQTT_COMM_DATA,
                                                     MQTT_COMM_DIAG);

    for(int i = 1; i <= dmExpectedMqttMapping.count(); i++)
    {
      const string sDeviceName = dmExpectedMqttMapping[i]["name"];
      string sDeviceId;
      string sMnspId;
      string sMqttDp;
      mapping mDeviceNameToId;
      mapping mMnspIdtoDeviceId;
      mapping mMnspIdtoMqttDp;

      Cns::getDeviceNamesToIdsMapping(mDeviceNameToId);
      Mqtt::getMapping((int)MqttMapping::DEVICE_MNSP_ID_TO_CNS_ID, mMnspIdtoDeviceId);
      Mqtt::getMapping((int)MqttMapping::DEVICE_MNSP_ID_TO_DP_NAME, mMnspIdtoMqttDp);

      sDeviceId = mDeviceNameToId.value(sDeviceName);

      for(int j = 0; j < mMnspIdtoDeviceId.count(); j++)
      {
        if(mMnspIdtoDeviceId.valueAt(j) == sDeviceId)
        {
          sMnspId = mMnspIdtoDeviceId.keyAt(j);
        }
      }

      sMqttDp = mMnspIdtoMqttDp.value(sMnspId);
      if(!dpExists(sMqttDp))
      {
        return testAbort("Mqtt comm dp <" + sMqttDp + "> not found");
      }

      for(int j = 0; j < dsTopicsToCheck.count(); j++)
      {
        const string sCurrentTopic = dsTopicsToCheck.at(j);
        string sMqttTopic;

        dpGet(sMqttDp + sCurrentTopic + ":_address.._reference", sMqttTopic);
        assertTrue(sMqttTopic.contains(sDeviceName), "Check if mqtt topic <" + sCurrentTopic + "> contains device name <" + sDeviceName + ">");
        assertTrue(sMqttTopic.contains(sMnspId), "Check if mqtt topic <" + sCurrentTopic + "> contains id <" + sMnspId + ">");
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check pollrate of given datapoints
    @param dmExpectedMqttMapping Mapping with datapoints to check and expected values
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkPollRate(const dyn_mapping &dmExpectedPollRate)
  {
    int iErr;
    mapping mCnsTags;

    iErr = Cns::getTagNamesToIdMapping(mCnsTags);
    if(iErr < 0)
    {
      return testAbort("Failed to get Cns mapping");
    }

    for(int i = 1; i <= dmExpectedPollRate.count(); i++)
    {
      string sCnsId;
      int iPollRate;

      if(!dmExpectedPollRate[i].contains(MAP_KEY_POLLRATE_TAG) ||
         !dmExpectedPollRate[i].contains(MAP_KEY_POLLRATE_MILLISEC))
      {
        return testAbort("Mapping key <" + MAP_KEY_POLLRATE_TAG + "> not found!");
      }

      sCnsId = mCnsTags.value(dmExpectedPollRate[i].value(MAP_KEY_POLLRATE_TAG));

      if(!dpExists(sCnsId))
      {
        return testAbort("Correspondig Dp to tag name <" + dmExpectedPollRate[i].value(MAP_KEY_POLLRATE_TAG) + "> not found!");
      }

      iErr = Tag::getAddressPollGroup(sCnsId, iPollRate);
      if(iErr < 0)
      {
        return testAbort("Failed to read poll rate from CNS ID <" + sCnsId + ">");
      }

      assertEqual(iPollRate, dmExpectedPollRate[i].value(MAP_KEY_POLLRATE_MILLISEC), "Check poll rate for CNS ID <" + sCnsId + "> equals <" + iPollRate + ">");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check low level bit of given datapoints
    @param dmExpectedLowLevel Mapping with datapoints to check and expected values
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkLowLevel(const dyn_mapping &dmExpectedLowLevel)
  {
    int iErr;
    mapping mCnsTags;

    iErr = Cns::getTagNamesToIdMapping(mCnsTags);
    if(iErr < 0)
    {
      return testAbort("Failed to get Cns mapping");
    }

    for(int i = 1; i <= dmExpectedLowLevel.count(); i++)
    {
      string sCnsId;
      bool bLowLevel;

      if(!dmExpectedLowLevel[i].contains(MAP_KEY_LOWLEVEL_TAG) ||
         !dmExpectedLowLevel[i].contains(MAP_KEY_LOWLEVEL_FLAG))
      {
        return testAbort("Mapping key <" +  + "> not found!");
      }

      sCnsId = mCnsTags.value(dmExpectedLowLevel[i].value(MAP_KEY_LOWLEVEL_TAG));

      if(!dpExists(sCnsId))
      {
        return testAbort("Correspondig Dp to tag name <" + dmExpectedLowLevel[i].value(MAP_KEY_LOWLEVEL_TAG) + "> not found!");
      }

      iErr = Tag::getAddressOnDataChange(sCnsId, bLowLevel);
      if(iErr < 0)
      {
        return testAbort("Failed to read low level flag from CNS ID <" + sCnsId + ">");
      }

      assertEqual(bLowLevel, dmExpectedLowLevel[i].value(MAP_KEY_LOWLEVEL_FLAG), "Check low level flag for CNS ID <" + sCnsId + "> equals <" + bLowLevel + ">");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check time source of given datapoints
    @param dmExpectedTimeSource Mapping with datapoints to check and expected values
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkTimeFromField(const dyn_mapping &dmExpectedTimeSource)
  {
    int iErr;
    mapping mCnsTags;

    const int TIME_DIFFERENCE = 30;

    iErr = Cns::getTagNamesToIdMapping(mCnsTags);
    if(iErr < 0)
    {
      return testAbort("Failed to get Cns mapping");
    }

    for(int i = 1; i <= dmExpectedTimeSource.count(); i++)
    {
      dyn_mapping dmMqttMapping;
      string sCnsId;
      string sDpName;
      string sMqttMapping;
      bool bTimesource;
      time tToMS,tFromDp;

      sCnsId = mCnsTags.value(dmExpectedTimeSource[i].value(MAP_KEY_TIMESOURCE_TAG));
      Cns::getDpFromId(sCnsId,sDpName);

      //time of dp differs by 30 sec.
      dpSetTimed(getCurrentTime()-TIME_DIFFERENCE,sDpName,0);

      delay(2); //temporary - remove after rework

      //get time from mqtt string sent to mindsphere
      dpGet("System1:MNSP_MQTT_COMM_1.Data:_online.._value", sMqttMapping);
      dmMqttMapping = jsonDecode(sMqttMapping);
      tToMS=dmMqttMapping.at(0)["timestamp"];

      //get time from dp
      dpGet(sDpName+":_original.._stime",tFromDp);

      //compare time
      if(second(tToMS)==second(tFromDp))
      {
        bTimesource=TIME_FROM_FIELD;
      }
      else
      {
        bTimesource=TIME_FROM_SERVER;
      }

      assertEqual(bTimesource, dmExpectedTimeSource[i].value(MAP_KEY_TIMESOURCE_FLAG), "Check time source");
    }
    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get index of given manager
    @param sManager Manager e.g. "WCCOAs7"
    @param iMaxCnt max. count for wait
    @return Error code
            value | description
            ------|------------
            >= 0  | index of given manager
            -1    | Manager not found
  */
  public int waitUntilManagerRemoved(const string &sManager, const int iMaxCnt = 100)
  {
    int iCnt;

    // wait max. 10 seconds (100 x 100ms) for manager to be removed
    while(iCnt < iMaxCnt)
    {
      if(getIndexOfManager(sManager) < 0)
      {
        return 0;
      }

      delay(0, 100);
      iCnt++;
    }

    return -1;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get index of given manager
    @param sManager Manager e.g. "WCCOAs7"
    @return Error code
            value | description
            ------|------------
            >= 0  | index of given manager
            -1    | Manager not found
  */
  public int getIndexOfManager(const string &sManager)
  {
    dyn_mapping dmManagerList;

    dmManagerList = getListOfManagerOptions();

    for(int i = 1; i <= dynlen(dmManagerList); i++)
    {
      if(dmManagerList[i]["Component"] == sManager)
      {
        return --i;
      }
    }

    return -1;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check commad value for TC
    @param mExpectedTagAqui Mapping containing expected aquisition types for tags
    @param sCommandFile Path to file containing commad string (root is data path)
    @param mExpectedCmdResult Mapping containing expected result of commad string
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkTagAquisition(const string &sDeviceName, const mapping &mExpectedTagAqui, const string &sCommandFile, const mapping &mExpectedCmdResult)
  {
    int iErr;
    string sDeviceId;
    string sMqttCommDp;
    string sFilePath;
    string sJsonString;
    mapping mCnsTags;

    iErr = getMqttCommDp(sDeviceName, sDeviceId, sMqttCommDp);
    if(iErr < 0)
    {
      return testAbort("Failed to get Mqtt Dp");
    }

    iErr = Cns::getTagNamesToIdMapping(mCnsTags);
    if(iErr < 0)
    {
      return testAbort("Failed to get Cns mapping");
    }

    assertEqual(mCnsTags.count(), mExpectedTagAqui.count(), "Check tag aquisition type");

    for(int i = 0; i < mExpectedTagAqui.count(); i++)
    {
      string sCnsId;
      string sAquiType;

      sCnsId = mCnsTags.value(mExpectedTagAqui.keyAt(i));

      if(!dpExists(sCnsId))
      {
        return testAbort("Correspondig Dp to tag name <" + mCnsTags.keyAt(i) + "> not found!");
      }

      iErr = Tag::getAddressAquisitionType(sCnsId, sAquiType);
      if(iErr < 0)
      {
        return testAbort("Failed to read poll rate from CNS ID <" + sCnsId + ">");
      }

      assertEqual(sAquiType, mExpectedTagAqui.valueAt(i), "Check aquisition type for CNS ID <" + sCnsId + "> equals <" + sAquiType + ">");
    }

    sFilePath = getPath(DATA_REL_PATH, sCommandFile);

    iErr = Helpers::readJsonFile(sFilePath, ENCODING, sJsonString);
    if(iErr < 0)
    {
      return testAbort("Could not read file <" + sCommandFile + ">");
    }

    for(int i = 0; i < mExpectedCmdResult.count(); i++)
    {
      float fDpVal;
      string sTagDp;
      dyn_string dsDpList;
      dyn_anytype daValueList;

      dsDpList = makeDynString(sMqttCommDp + MQTT_COMM_COMMAND);
      daValueList = makeDynAnytype(sJsonString);

      checkCmdValueResponse(dsDpList, daValueList, sTagDp, "FAILED");

      Cns::getDpFromId(mCnsTags.value(mExpectedCmdResult.keyAt(i)), sTagDp);

      checkCmdValueResponse(dsDpList, daValueList, sTagDp, "EXECUTED");

      dpGet(sTagDp, fDpVal);
      assertEqual(fDpVal, (float)mExpectedCmdResult.valueAt(i), "Check dp value after CMD");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check commad value for TC
    @param mExpectedTagAqui Mapping containing expected aquisition types for tags
    @param sCommandFile Path to file containing commad string (root is data path)
    @param mExpectedCmdResult Mapping containing expected result of commad string
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkBoolCmd(const string &sDeviceName, const string &sCommandFile, const mapping &mExpectedCmdResult)
  {
    int iErr;
    string sDeviceId;
    string sMqttCommDp;
    string sFilePath;
    string sJsonString;
    mapping mCnsTags;

    iErr = getMqttCommDp(sDeviceName, sDeviceId, sMqttCommDp);
    if(iErr < 0)
    {
      return testAbort("Failed to get Mqtt Dp");
    }

    iErr = Cns::getTagNamesToIdMapping(mCnsTags);
    if(iErr < 0)
    {
      return testAbort("Failed to get Cns mapping");
    }

    sFilePath = getPath(DATA_REL_PATH, sCommandFile);

    iErr = Helpers::readJsonFile(sFilePath, ENCODING, sJsonString);
    if(iErr < 0)
    {
      return testAbort("Could not read file <" + sCommandFile + ">");
    }

    for(int i = 0; i < mExpectedCmdResult.count(); i++)
    {
      bool bDpVal;
      string sTagDp;
      dyn_string dsDpList;
      dyn_anytype daValueList;

      dsDpList = makeDynString(sMqttCommDp + MQTT_COMM_COMMAND);
      daValueList = makeDynAnytype(sJsonString);

      Cns::getDpFromId(mCnsTags.value(mExpectedCmdResult.keyAt(i)), sTagDp);

      checkCmdValueResponse(dsDpList, daValueList, sTagDp, "EXECUTED");

      dpGet(sTagDp, bDpVal);
      assertEqual(bDpVal, (bool)mExpectedCmdResult.valueAt(i), "Check dp value after CMD");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set cmd value and check result
    @param dsMqttCommDps Mqtt dps to set
    @param dsCmdValues Data for Mqtt dp to set
    @param sTagDp Tag dp which value has been set in data
    @param sExpectedResult Expected result of cmd values e.g. FAILED
    @param iMaxCnt Maximum count for dp change on cmd value result dp
  */
  public void checkCmdValueResponse(dyn_string &dsMqttCommDps, dyn_string &dsCmdValues, string &sTagDp, const string &sExpectedResult, const int iMaxCnt = 100)
  {
    bool bFlagExecuted;
    bool bIsTimedOut;
    int iCnt;
    string sCmdResult;
    dyn_anytype daResult;
    mapping mCmdResult;

    dpSet(MQTT_DP_CMD_RESP, "");

    daResult = Helpers::dpSetdelayed(dsMqttCommDps, dsCmdValues, MQTT_DP_CMD_RESP, bIsTimedOut);
    mCmdResult = jsonDecode(daResult.first());
    assertEqual(mCmdResult["state"], "EXECUTING", "Check result of CMD executing");

    if(sTagDp != "")
    {
      dpSet(sTagDp + ":_original.._aut_inv"   , FALSE,
            sTagDp + ":_original.._transition", FALSE);
    }

    while(iCnt < iMaxCnt)
    {
      dpGet(MQTT_DP_CMD_RESP, sCmdResult);
      mCmdResult.clear();
      mCmdResult = jsonDecode(sCmdResult);

      if(mCmdResult["state"] == sExpectedResult)
      {
        bFlagExecuted = TRUE;
        break;
      }

      delay(0, 200);
      iCnt++;
    }
    assertTrue(bFlagExecuted, "Check result of CMD done");

  }

  //------------------------------------------------------------------------------
  /**
    @brief return MQTT_COMM_<num> dp from given device name
    @param sCnsDeviceName CNS name of device
    @param[out] sDeviceId CNS device ID as reference
    @param[out] sMqttCommDp MQTT_COMM dp as reference
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | error reading CNS
  */
  public static int getMqttCommDp(const string &sCnsDeviceName, string &sDeviceId, string &sMqttCommDp)
  {
    int iErr;
    string sMnspId;
    mapping mDeviceNameToId;
    mapping mMnspIdtoDeviceId;
    mapping mMnspIdtoMqttDp;

    iErr = Cns::getDeviceNamesToIdsMapping(mDeviceNameToId);
    if(iErr)
    {
      return -1;
    }

    iErr = Mqtt::getMapping((int)MqttMapping::DEVICE_MNSP_ID_TO_CNS_ID, mMnspIdtoDeviceId);
    if(iErr)
    {
      return -1;
    }

    iErr = Mqtt::getMapping((int)MqttMapping::DEVICE_MNSP_ID_TO_DP_NAME, mMnspIdtoMqttDp);
    if(iErr)
    {
      return -1;
    }

    sDeviceId = mDeviceNameToId.value(sCnsDeviceName);

    for(int i = 0; i < mMnspIdtoDeviceId.count(); i++)
    {
      if(mMnspIdtoDeviceId.valueAt(i) == sDeviceId)
      {
        sMnspId = mMnspIdtoDeviceId.keyAt(i);
      }
    }

    sMqttCommDp = mMnspIdtoMqttDp.value(sMnspId);

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check default values of driver connection dp
    @param sDriverName Driver name to check
    @param iIndex Driver index to check
    @param mExpectedResult Mapping containing expected results
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkDriverConnectionDefaultValues(const string &sDriverName, const int iIndex, const mapping &mExpectedResult)
  {
    uint uDeviceType;
    uint uDeviceSlot;
    string sPlcType;

    if(!mExpectedResult.contains(KEY_DRV_DEFAULT_DEVTYPE))
    {
      return testAbort("Could not find Key <" + KEY_DRV_DEFAULT_DEVTYPE + "> in mapping");
    }
    Device::getDeviceType(sDriverName, iIndex, uDeviceType);
    assertEqual(uDeviceType, (uint)mExpectedResult.value(KEY_DRV_DEFAULT_DEVTYPE), "Check device type");

    if(!mExpectedResult.contains(KEY_DRV_DEFAULT_DEVSLOT))
    {
      return testAbort("Could not find Key <" + KEY_DRV_DEFAULT_DEVSLOT + "> in mapping");
    }
    Device::getDeviceSlot(sDriverName, iIndex, uDeviceSlot);
    assertEqual(uDeviceSlot, (uint)mExpectedResult.value(KEY_DRV_DEFAULT_DEVSLOT), "Check device slot");

    if(!mExpectedResult.contains(KEY_DRV_DEFAULT_PLCTYPE))
    {
      return testAbort("Could not find Key <" + KEY_DRV_DEFAULT_PLCTYPE + "> in mapping");
    }
    Device::getPlcType(sDriverName, iIndex, sPlcType);
    assertEqual(sPlcType, mExpectedResult.value(KEY_DRV_DEFAULT_PLCTYPE), "Check device plc type");

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check qualtiy status bits for bad connection
    @param iState State to set.
    @param iExpectedQualityCode Expected quality code in mapping.
    @param bExpectedUserBit4 Expected value for _userbit4 of tag.
    @param bExpectedUserBit5 Expected value for _userbit5 of tag.
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkQualityStatusBitsBad(const string &sDeviceName, const int iState, const int &iExpectedQualityCode, const bool bExpectedUserBit4, const bool bExpectedUserBit5)
  {
    int iErr;
    int iActualState;
    uint uConnDpIndex;
    string sDeviceId;
    string sMqttDp;
    dyn_string dsTags;
    dyn_anytype daReturnValue;
    dyn_mapping dmQualityCode;

    getMqttCommDp(sDeviceName, sDeviceId, sMqttDp);

    iErr = Cns::getTagIds(sDeviceId, dsTags);
    if(iErr < 0)
    {
      return testAbort("Error in Cns::getAllTagIds");
    }

    Helpers::getIndexOfConnectionDp(sDeviceId, uConnDpIndex);

    Device::setConnStateAndWaitForValue(DRIVER_NAME_S7, uConnDpIndex, (int)S7ConnState::NOT_CONNECTED, sMqttDp + MQTT_COMM_DATA, daReturnValue);
    Device::setOpStateAndWaitForValue(DRIVER_NAME_S7, uConnDpIndex, (int)S7OpState::STOP, sMqttDp + MQTT_COMM_DATA, daReturnValue);

    Device::getConnState(DRIVER_NAME_S7, uConnDpIndex, iActualState);

    if(iActualState != iState)
    {
      iErr = Device::setConnStateAndWaitForValue(DRIVER_NAME_S7, uConnDpIndex, iState, sMqttDp + MQTT_COMM_DATA, daReturnValue);
      if(iErr < 0)
      {
        return testAbort("Error in Device setState");
      }

      dmQualityCode = jsonDecode(daReturnValue.first());
    }
    else
    {
      iErr = MqttComm::getMapping(sMqttDp, MQTT_COMM_DATA, dmQualityCode);
      if(iErr < 0)
      {
        return testAbort("Error in MqttComm::getMapping");
      }
    }

    if(dmQualityCode.count() == 0 || !dmQualityCode[1].contains(KEY_MQTT_COMM_DATA_VALUES))
    {
      return testAbort("Key <" + KEY_MQTT_COMM_DATA_VALUES + "> in mapping not found");
    }

    checkQualityStatusBits(dmQualityCode, dsTags, iExpectedQualityCode, bExpectedUserBit4, bExpectedUserBit5);

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check qualtiy status bits for invalid setting
    @param iState State to set.
    @param iExpectedQualityCode Expected quality code in mapping.
    @param bExpectedUserBit4 Expected value for _userbit4 of tag.
    @param bExpectedUserBit5 Expected value for _userbit5 of tag.
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkQualityStatusBitsInvalid(const string &sDeviceName, const int iState, const int &iExpectedQualityCode, const bool bExpectedUserBit4, const bool bExpectedUserBit5)
  {
    int iErr;
    int iActualState;
    uint uConnDpIndex;
    string sDeviceId;
    string sMqttDp;
    dyn_string dsTags;
    dyn_mapping dmQualityCode;
    dyn_anytype daReturnValue;

    getMqttCommDp(sDeviceName, sDeviceId, sMqttDp);

    iErr = Cns::getTagIds(sDeviceId, dsTags);
    if(iErr < 0)
    {
      return testAbort("Error in Cns::getAllTagIds");
    }

    Helpers::getIndexOfConnectionDp(sDeviceId, uConnDpIndex);

    Device::setConnStateAndWaitForValue(DRIVER_NAME_S7, uConnDpIndex, (int)S7ConnState::CONNECTED, sMqttDp + MQTT_COMM_DATA, daReturnValue);
    Device::getOpState(DRIVER_NAME_S7, uConnDpIndex, iActualState);

    if(iActualState != iState)
    {
      iErr = Device::setOpStateAndWaitForValue(DRIVER_NAME_S7, uConnDpIndex, iState, sMqttDp + MQTT_COMM_DATA, daReturnValue);
      if(iErr < 0)
      {
        return testAbort("Error in Device setState");
      }

      dmQualityCode = jsonDecode(daReturnValue.first());
    }
    else
    {
      iErr = MqttComm::getMapping(sMqttDp, MQTT_COMM_DATA, dmQualityCode);
      if(iErr < 0)
      {
        return testAbort("Error in MqttComm::getMapping");
      }
    }

    if(dmQualityCode.count() == 0 || !dmQualityCode[1].contains(KEY_MQTT_COMM_DATA_VALUES))
    {
      return testAbort("Key <" + KEY_MQTT_COMM_DATA_VALUES + "> in mapping not found");
    }

    checkQualityStatusBits(dmQualityCode, dsTags, iExpectedQualityCode, bExpectedUserBit4, bExpectedUserBit5);

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check qualtiy status bits for good connection
    @param iExpectedQualityCode Expected quality code in mapping.
    @param bExpectedUserBit4 Expected value for _userbit4 of tag.
    @param bExpectedUserBit5 Expected value for _userbit5 of tag.
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkQualityStatusBitsGood(const string &sDeviceName, const int &iExpectedQualityCode, const bool bExpectedUserBit4, const bool bExpectedUserBit5)
  {
    bool bIsTimedOut;
    int iErr;
    uint uConnDpIndex;
    string sDeviceId;
    string sMqttDp;
    dyn_string dsTags;
    dyn_string dsDpList;
    dyn_anytype daReturnValue;
    dyn_anytype daValueList;
    dyn_anytype daQualityCode;
    dyn_mapping dmQualityCode;

    getMqttCommDp(sDeviceName, sDeviceId, sMqttDp);

    iErr = Cns::getTagIds(sDeviceId, dsTags);
    if(iErr < 0)
    {
      return testAbort("Error in Cns::getAllTagIds");
    }

    Helpers::getIndexOfConnectionDp(sDeviceId, uConnDpIndex);

    Device::setConnStateAndWaitForValue(DRIVER_NAME_S7, uConnDpIndex, (int)S7ConnState::CONNECTED, sMqttDp + MQTT_COMM_DATA, daReturnValue);
    Device::setOpStateAndWaitForValue(DRIVER_NAME_S7, uConnDpIndex, (int)S7OpState::RUN, sMqttDp + MQTT_COMM_DATA, daReturnValue);

    for(int i = 0; i < dsTags.count(); i++)
    {
      dsDpList.append(dsTags.at(i) + ":_original.._userbit3");
      daValueList.append(TRUE);
    }

    Helpers::dpSetdelayed(dsDpList, daValueList, sMqttDp + MQTT_COMM_DATA, bIsTimedOut);

    dsDpList.clear();
    daValueList.clear();

    for(int i = 0; i < dsTags.count(); i++)
    {
      dsDpList.append(dsTags.at(i) + ":_original.._value");
      daValueList.append(0);
    }

    daQualityCode = Helpers::dpSetdelayed(dsDpList, daValueList, sMqttDp + MQTT_COMM_DATA, bIsTimedOut);
    dmQualityCode = jsonDecode(daQualityCode);

    if(dmQualityCode.count() == 0 || !dmQualityCode[1].contains(KEY_MQTT_COMM_DATA_VALUES))
    {
      return testAbort("Key <" + KEY_MQTT_COMM_DATA_VALUES + "> in mapping not found");
    }

    checkQualityStatusBits(dmQualityCode, dsTags.first(), iExpectedQualityCode, bExpectedUserBit4, bExpectedUserBit5);

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check userbit4, userbit5 and qualityCode for TC
    @param dmQualityCode Mapping with quality code for every tag
    @param dsTags Array with tags to check
    @param iExpectedQualityCode Expected quality code in mapping.
    @param bExpectedUserBit4 Expected value for _userbit4 of tag.
    @param bExpectedUserBit5 Expected value for _userbit5 of tag.
  */
  public void checkQualityStatusBits(const dyn_mapping &dmQualityCode, const dyn_string dsTags, const int &iExpectedQualityCode, const bool bExpectedUserBit4, const bool bExpectedUserBit5)
  {
    for(int i = 1; i <= dynlen(dmQualityCode[1][KEY_MQTT_COMM_DATA_VALUES]); i++)
    {
      assertEqual((int)dmQualityCode[1][KEY_MQTT_COMM_DATA_VALUES][i][KEY_MQTT_COMM_DATA_QC], iExpectedQualityCode, "Check quality code for datapointId <" + dmQualityCode[1][KEY_MQTT_COMM_DATA_VALUES][i][KEY_MQTT_COMM_DATA_DATAPTID] + ">");
    }

    for(int i = 0; i < dsTags.count(); i++)
    {
      bool bUserBit4;
      bool bUserBit5;

      Helpers::getTagUserBit(dsTags.at(i), 4, bUserBit4);
      Helpers::getTagUserBit(dsTags.at(i), 5, bUserBit5);

      assertEqual(bUserBit4, bExpectedUserBit4, "Check value of _userbit4 for tag <" + dsTags.at(i) + ">");
      assertEqual(bUserBit5, bExpectedUserBit5, "Check value of _userbit5 for tag <" + dsTags.at(i) + ">");
    }
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check number of created certificates for TC
    @param dmQualityCode Mapping with expected cnt of certificates for driver
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkCertificates(const mapping &mExpectedCerts)
  {
    for(int i = 0; i < mExpectedCerts.count(); i++)
    {
      int iErr;
      dyn_string dsCerts;

      iErr = Helpers::getCertificates(mExpectedCerts.keyAt(i), dsCerts);
      if(iErr < 0)
      {
        return testAbort("Could not get certificates for given path <" + mExpectedCerts.keyAt(i) + ">");
      }

      assertEqual(dsCerts.count(), mExpectedCerts.valueAt(i), "Check number of certificates for <" + mExpectedCerts.keyAt(i) + ">");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check content of created certificates for TC
    @param sDriverCertPath Path to certificates for certain driver
    @param iExpectedCertCnt Expected number of certificates
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkCertificateContent(const string &sDriverCertPath, const int iExpectedCertCnt)
  {
    int iErr;
    dyn_string dsCerts;
    dyn_anytype daCertificates;

    iErr = Helpers::getCertificates(sDriverCertPath, dsCerts, TRUE);
    if(iErr < 0)
    {
      return testAbort("Could not get certificates for given path <" + sDriverCertPath + ">");
    }

    assertEqual(dsCerts.count(), iExpectedCertCnt, "Check number of certificates for <" + sDriverCertPath + ">");

    daCertificates = m_dmMqttData[1]["protocolData"]["certificateFileContents"];

    if(daCertificates.count() != dsCerts.count())
    {
      return testAbort("Missmatch in certificate count");
    }

    for(int i = 0; i < dsCerts.count(); i++)
    {
      bool bSucces;
      string sFileContent;

      bSucces = fileToString(dsCerts.at(i), sFileContent);
      if(!bSucces)
      {
        return testAbort("Could not read file <" + dsCerts.at(i) + ">");
      }

      assertEqual(sFileContent, (string)daCertificates.at(i), "Compare content of certificate <" + dsCerts.at(i) + ">");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check if MTConnect driver receives values
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkMTConnect()
  {
    int iErr;
    string sDeviceList;
    dyn_string dsMTConnectDps;
    dyn_mapping dmDeviceList;
    dyn_mapping dmTagList;

    iErr = dpGet(EB_MTCONNECT_DP_DEVICELIST, sDeviceList);
    if(iErr < 0)
    {
      return testAbort("Error reading dp <" + EB_MTCONNECT_DP_DEVICELIST + ">");
    }

    dmDeviceList = jsonDecode(sDeviceList);
    if(dmDeviceList.count() <= 0)
    {
      return testAbort("MTConnect device list <" + EB_MTCONNECT_DP_DEVICELIST + "> empty");
    }

    for(int i = 1; i <= dmDeviceList.count(); i++)
    {
      dmTagList = dmDeviceList[i].value(KEY_EB_MTCONNECT_TAGLIST);

      for(int j = 1; j <= dmTagList.count(); j++)
      {
        bool bCorrect;
        string sDp = dmTagList[j][KEY_EB_MTCONNECT_NODEID];
        anytype aVal;

        if(!dpExists(sDp))
        {
          testAbort("Tag dp does not exist <" + sDp + ">");
        }

        iErr = dpGet(sDp + ":_original.._value", aVal);
        if(iErr < 0)
        {
          testAbort("Error reading original value of dp <" + sDp + ">");
        }

        bCorrect = ((string)aVal != "" && (string)aVal != "0");
        assertTrue(bCorrect, "Check if dp <" + sDp + "> has received value from MTConnect driver");
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check transformation type of tags
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkTagTransformationType()
  {
    int iErr;
    mapping mCnsTagNamesToIds;

    Cns::getTagNamesToIdMapping(mCnsTagNamesToIds);

    for(int i = 1; i <= m_dmMqttData.count(); i++)
    {
      dyn_mapping dmDatapoints = m_dmMqttData[i]["dataPoints"];

      for(int j = 1; j <= dmDatapoints.count(); j++)
      {
        string sTagDp;
        string sTagTransType;
        const string sTagName = dmDatapoints[j]["name"];
        const string sExpectedTagTransType = dmDatapoints[j]["dataPointData"]["typeTransformation"];

        sTagDp = mCnsTagNamesToIds.value(sTagName);

        Tag::getTransformationType(sTagDp, sTagTransType);

        assertEqual(sTagTransType, sExpectedTagTransType, "Check transformation type of tag <" + sTagName + "> (" + sTagTransType + ") equals (" + sExpectedTagTransType + ")");
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check transformation type of tags
    @param dsExpectedLogEntries Array with expected log entries (see constants LOG_NUMBER_*)
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkLogTable(const dyn_string &dsExpectedLogEntries)
  {
    string sLogs;
    time tNow = getCurrentTime();

    sLogs = EBlog::getLogAsJsonString(-1, LOG_DEFAULT_FILTER, LOG_DEFAULT_FILTER, m_tTestCaseStart, tNow);

    if(sLogs == "")
    {
      return testAbort("Historic log table for given timerange (" + m_tTestCaseStart + " - " + tNow + ") is empty");
    }

    for(int i = 0; i < dsExpectedLogEntries.count(); i++)
    {
      bool bContains;

      Helpers::checkLogStringContains(sLogs, dsExpectedLogEntries.at(i), bContains);
      assertTrue(bContains, "Check if log entry <" + dsExpectedLogEntries.at(i) + "> exists in historic log table");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Set driver restart command and check log
    @param sDriver Drivername which should be restarted e.g. "WCCOAs7"
    @param iMaxCnt Maximun time to wait for driver restart (default 100, 1 count = 100ms)
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkDriverRestart(const string &sDriver, const int iMaxCnt = 100)
  {
    bool bDriverRestartFlag;
    int iManIndex;
    int iPid;
    int iCnt;

    iManIndex = getIndexOfManager(sDriver);
    iPid = getManagerPid(iManIndex);
    if(iPid == "-1")
    {
      return testAbort("Could not read PID of manager <" + sDriver + ">");
    }

    dpSet(MQTT_DP_DIAG_CMD, "{\"commandId\":\"ab7cb462-aa21-4111-ba4c-d78349936306\",\"createdAt\":\"2021-02-23T11:59:13.751Z\",\"data\":{\"type\":\"ddd\",\"version\":\"v1\",\"payload\":{\"restartManager\":{\"manager\":\"" + sDriver + "\",\"options\":\"\"}}}}");

    // wait max. 10 seconds (100 x 100ms) for driver/manager to restart
    while(iCnt < iMaxCnt)
    {
      int iNewPid = getManagerPid(iManIndex);

      if(iPid != iNewPid && iNewPid != -1)
      {
        bDriverRestartFlag = TRUE;
        break;
      }

      delay(0, 100);
      iCnt++;
    }

    assertTrue(bDriverRestartFlag, "Check if driver did restart");

    return checkLogTable(makeDynString(LOG_NUMBER_DRIVER_RESTART));
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check if protocol filter for given protocol works
    @param sProtocolName Name of protocol e.g. "S7"
    @param sConnDp Corresponding connection dp of protocol e.g. "_S7_Conn"
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkProtocolFilter(const string &sProtocolName, const string &sConnDp)
  {
    int iErr;
    dyn_string dsCnsDeviceIds;
    dyn_string dsCnsDataPoints;
    string sCnsProtocol;

    assertEqual(Helpers::getDptCount(sConnDp), 0, "Check if no <" + sConnDp + "> dp has been created");

    iErr = Cns::getAllDeviceIds(dsCnsDeviceIds);
    if(iErr < 0)
    {
      return testAbort("Error in getAllDeviceIds");
    }

    for(int i = 0; i < dsCnsDeviceIds.count(); i++)
    {
      string sCnsProtocol;

      Cns::getDeviceProtocolName(dsCnsDeviceIds.at(i), sCnsProtocol);
      assertNotEqual(sCnsProtocol.toUpper(), sProtocolName.toUpper(), "Check if no device of protocol <" + sProtocolName + "> has been created");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check export of log files
    @return always 0
  */
  public int checkLogExport()
  {
    const string sDirPath = "/persistent_massdata/tmp/logsToUpload/";
    const string sFilePattern = "logcmd_*";
    dyn_string dsFiles;

    dsFiles = getFileNames(sDirPath, sFilePattern);
    assertEqual(dsFiles.count(), 0, "check if no log export file is dir before cmd");

    dpSet(MQTT_DP_DIAG_CMD, "{\"commandId\":\"ab7cb462-aa21-4111-ba4c-d78349936306\",\"createdAt\":\"2021-02-23T11:59:13.751Z\",\"data\":{\"type\":\"ddd\",\"version\":\"v1\",\"payload\":{\"getLogs\":{\"files\":\"PVSS_II.log\"}}}}");

    assertTrue(checkFileCount(sDirPath, sFilePattern, 1), "check log export file exists in dir after cmd");

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check browsing for different drivers
    @param sCommandFile Path to file containing commad string (root is data path)
    @param sFilePattern Pattern name of created browse result file (e.g. "IEC61850_*" for IEC81650)
    @param sExpectedResultFile Path to file used for browse result comparison
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkBrowsing(const string &sCommandFile, const string &sFilePattern, const string &sExpectedResultFile)
  {
    bool bIsTimedOut;
    int iErr;
    const int iTimeOut = 50;
    string sJsonString;
    string sFilePath;
    string sExpectedResult;
    string sBrowsingResult;
    dyn_string dsFiles;
    dyn_anytype daRequest;
    anytype aCommand;
    mapping mRequest;
    mapping mResponse = makeMapping("localPath", "",
                                    "requestId", "",
                                    "status", "SUCCEEDED");

    if(!isdir(PATH_TO_BROWSE_RESULT_FILE))
    {
      bool bRet;
      bRet = mkdir(PATH_TO_BROWSE_RESULT_FILE);
    }

    dsFiles = getFileNames(PATH_TO_BROWSE_RESULT_FILE, sFilePattern);
    assertEqual(dsFiles.count(), 0, "check if no  browse result file exists in dir before cmd");

    sFilePath = getPath(DATA_REL_PATH, sCommandFile);
    iErr = Helpers::readJsonFile(sFilePath, ENCODING, sJsonString);
    if(iErr < 0)
    {
      return testAbort("Could not read file <" + sCommandFile + ">");
    }

    aCommand = jsonDecode(sJsonString);

    dpSetAndWaitForValue(makeDynString(MQTT_DP_BROWSE_CMD),
                         makeDynAnytype(sJsonString),
                         makeDynString(MQTT_DP_BROWSE_REQ + ":_online.._value"),
                         makeDynAnytype(),
                         makeDynString(MQTT_DP_BROWSE_REQ + ":_original.._value"),
                         daRequest,
                         iTimeOut,
                         bIsTimedOut);

    if(bIsTimedOut)
    {
      return testAbort("Browsing request timed out");
    }

    assertTrue(checkFileCount(PATH_TO_BROWSE_RESULT_FILE, sFilePattern, 1), "Check if browse result file exists in dir after cmd");

    fileToString(getPath(DATA_REL_PATH, sExpectedResultFile), sExpectedResult, "UTF8");

    dsFiles = getFileNames(PATH_TO_BROWSE_RESULT_FILE, sFilePattern);

    if(aCommand["data"]["payload"]["encodings"] == "gzip")
    {
      copyFile(PATH_TO_BROWSE_RESULT_FILE + "/" + dsFiles.first(), PATH_TO_BROWSE_RESULT_FILE + "/browseResult.gz");
      gzread(PATH_TO_BROWSE_RESULT_FILE + "/browseResult.gz", sBrowsingResult, MAX_FILE_SIZE);
      remove(PATH_TO_BROWSE_RESULT_FILE + "/browseResult.gz");
      sExpectedResult = substr(sExpectedResult, 0, MAX_FILE_SIZE); //safety for file comparison: if browse result file > MAX_FILE_SIZE
    }
    else
    {
      fileToString(PATH_TO_BROWSE_RESULT_FILE + "/" + dsFiles.first(), sBrowsingResult, "UTF8");
    }

    assertEqual(sExpectedResult, sBrowsingResult, "Compare browse result files");

    if (sExpectedResult!=sBrowsingResult)
    {
      if (aCommand["data"]["payload"]["encodings"] == "gzip")
        copyFile(PATH_TO_BROWSE_RESULT_FILE + "/" + dsFiles.first(), getPath(LOG_REL_PATH) + "_unexpectedBrowsingResult_" + sExpectedResultFile + ".gz");
      else
        copyFile(PATH_TO_BROWSE_RESULT_FILE + "/" + dsFiles.first(), getPath(LOG_REL_PATH) + "_unexpectedBrowsingResult_" + sExpectedResultFile + ".txt");
      file fLogFile = fopen(getPath(LOG_REL_PATH) + "_unexpectedBrowsingResult_" + sExpectedResultFile + ".log", "w");
      fputs(sBrowsingResult,fLogFile);
      fclose(fLogFile);
    }

    mRequest = jsonDecode(daRequest.first());
    mResponse["localPath"] = mRequest["localPath"];
    mResponse["requestId"] = mRequest["id"];

    dpSet(MQTT_DP_BROWSE_RESP, jsonEncode(mResponse));

    assertTrue(checkFileCount(PATH_TO_BROWSE_RESULT_FILE, sFilePattern, 0), "Check if browse result file exists is deleted form dir after msc response");

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check if number of files with given pattern are in given directory
    @param sDir Directory where to check
    @param sFilePattern Pattern name of files
    @param iFileCnt Pattern name of files
    @param iMaxCnt Wait max. count (in 250ms steps) for file count to be equal (e.g. 40x250ms = 10s)
    @return Given file count equals real file count
  */
  public bool checkFileCount(const string &sDir, const string &sFilePattern, const int iFileCnt, int iMaxCnt = 40)
  {
    int iCnt;
    dyn_string dsFiles;

    while(iCnt < iMaxCnt)
    {
      dsFiles = getFileNames(sDir, sFilePattern);

      if(dsFiles.count() == iFileCnt)
      {
        return TRUE;
      }

      delay(0, 250);
      iCnt++;
    }

    return FALSE;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check hysteresis (_smooth config) for given device
    @param sDeviceName Name of device
    @param mExpectedResults Mapping with expected results for hysteresis
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | test has been aborted
  */
  public int checkHysteresis(const string &sDeviceName, const mapping &mExpectedResults)
  {
    int iErr;
    string sDeviceId;
    string sMqttCommDp;
    mapping mCnsTags;

    iErr = getMqttCommDp(sDeviceName, sDeviceId, sMqttCommDp);
    if(iErr < 0)
    {
      return testAbort("Failed to get Mqtt Dp");
    }

    iErr = Cns::getTagNamesToIdMapping(mCnsTags);
    if(iErr < 0)
    {
      return testAbort("Failed to get Cns mapping");
    }

    for(int i = 0; i < mExpectedResults.count(); i++)
    {
      string sCnsId;
      float fSmoothValue;

      sCnsId = mCnsTags.value(mExpectedResults.keyAt(i));

      iErr = Tag::getSmoothConfigValue(sCnsId, fSmoothValue);
      if(iErr < 0)
      {
        return testAbort("Failed to read _smooth config from CNS ID <" + sCnsId + ">");
      }

      assertEqual(fSmoothValue, (float)mExpectedResults.valueAt(i), "Check hystersis for CNS ID <" + sCnsId + ">");
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Change start options of given manager
    @param iManIndex Pmon index of manager
    @param sNewOption Option to insert
    @param sOldOption Option to replace
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | invalid manager index
            -2    | change options fail
            -3    | manager does not stop
            -4    | manager does not start
            -5    | manager is not running
  */
  public int changeManagerStartOptions(const int iManIndex, const string &sNewOption, const string &sOldOption)
  {
    int iErr;
    int iCnt;
    const int iMaxCnt = 20;
    string sManagerStartOptions;
    mapping mManagerOptions;

    mManagerOptions = getManagerOptions(iManIndex);
    if(!mManagerOptions.count() > 0)
    {
      return -1;
    }

    sManagerStartOptions = mManagerOptions["StartOptions"];

    if(sOldOption != "")
    {
      sManagerStartOptions.replace(sOldOption, sNewOption);
    }
    else
    {
      sManagerStartOptions += sNewOption;
    }

    mManagerOptions["StartOptions"] = sManagerStartOptions;

    iErr = changeManagerOptions(iManIndex, mManagerOptions);
    if(iErr)
    {
      return -2;
    }

    iErr = stopManager(iManIndex);
    if(iErr)
    {
      return -3;
    }

    iErr = startManager(iManIndex);
    if(iErr)
    {
      return -4;
    }

    // wait max. 5 seconds (20x250ms) for manager running
    while(iCnt < iMaxCnt)
    {
      if(getManagerStatus(iManIndex) == MAN_STATE_RUNNING)
      {
        return 0;
      }

      delay(0, 250);
      iCnt++;
    }

    return -5;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check filter for device names (device names cannot contain "-" or "." characters
    @param sOriDevName Original device name from mqtt string
    @param sNewDevName Expected device name after filtering
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not get CNS device names
  */
  public int checkDeviceNameFilter(const string &sOriDevName, const string &sNewDevName)
  {
    int iErr;
    bool bOriDevNameFound = FALSE;
    bool bNewDevNameFound = FALSE;
    dyn_string dsCnsDeviceNames;

    iErr = Cns::getAllDeviceNames(dsCnsDeviceNames);
    if(iErr < 0)
    {
      return testAbort("Error in Cns::getAllDeviceNames");
    }

    for(int i = 0; i < dsCnsDeviceNames.count(); i++)
    {
      string sActDevName = dsCnsDeviceNames.at(i);

      if(sActDevName == sOriDevName)
      {
        bOriDevNameFound = TRUE;
      }
      else if (sActDevName == sNewDevName)
      {
        bNewDevNameFound = TRUE;
      }
    }

    assertFalse(bOriDevNameFound, "Check if given original device name <"+ sOriDevName +"> has not been created in CNS view");
    assertTrue(bNewDevNameFound,  "Check if expected new device name <"+ sNewDevName +"> has been created in CNS view");

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Check possible mqtt config entries for mnsp script
    @param sMqttHost Mqtt connection IP address
    @param iMqttPort Mqtt connection port number
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | failure
  */
  public int checkMqttCfgEntries(const string &sMqttHost, const int &iMqttPort)
  {
    int iErr;
    int iManIdx;
    string sAddressJson;
    string sConnString;
    mapping mAddress;
    dyn_string dsSplit;
    ProjEnvManagerOptions manOpts;

    // insert config entries to config.level
    iErr = m_proj.insertCfgValue(sMqttHost, "mqttHost", "mnsp", "config.level");
    if(iErr)
    {
      return testAbort("Could not insert cfg entry <" + sMqttHost + ">");
    }
    iErr = m_proj.insertCfgValue(iMqttPort, "mqttPort ", "mnsp", "config.level");
    if(iErr)
    {
      return testAbort("Could not insert cfg entry <" + iMqttPort + ">");
    }

    iManIdx = m_proj.getManagerIndex(CTRL_COMPONENT, "-num 2");
    if(iManIdx < 0)
    {
      return testAbort("Could not get manager index of mnsp.ctl ctrl manager <" + iManIdx + ">");
    }

    // restart manager
    manOpts = m_proj.getManagerOptions(iManIdx);
    manOpts.startMode = ProjEnvManagerStartMode::Manual;
    m_proj.changeManagerOptions(iManIdx, manOpts);
    delay(1);
    m_proj.stopManager(iManIdx, MAN_TIME_OUT);
    delay(1);
    m_proj.startManager(iManIdx, MAN_TIME_OUT);
    delay(1);

    // [{"ConnectionType":1,"ConnectionString":"10.10.10.10:1884","Certificate":""}]
    iErr = dpGet("_MindsphereMQTT.Config.Address", sAddressJson);

    mAddress = jsonDecode(sAddressJson);

    // ["sConnString"]["10.10.10.10:1884"]
    sConnString = mAddress.value("ConnectionString");

    // ["dsSplit"][dyn_string 2 items
    //      1: "10.10.10.10"
    //      2: "1884"
    // ]
    dsSplit = strsplit(sConnString, ":");

    assertEqual(dsSplit.at(0), sMqttHost, "check if correct host address set on connection datapoint");
    assertEqual((int)dsSplit.at(1), iMqttPort, "check if correct port number set on connection datapoint");

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Abort current TC
    @param sMessage Abort message written to log
    @return always -1
  */
  public int testAbort(const string &sMessage)
  {
    // if first abort message
    if(!m_bTestAborted)
    {
      m_bTestAborted = TRUE;
      createTestAbortLog(sMessage);
    }

    return abort(sMessage);
  }

  //------------------------------------------------------------------------------
  /**
    @brief Create log file with additional info when test has been aborted
    @param sMessage Abort message written to log
  */
  public void createTestAbortLog(const string &sMessage)
  {
    file fTestAbortLog;

    fTestAbortLog = fopen(PROJ_PATH + LOG_REL_PATH + "testAbortLog", "w+");

    fputs("Reason for abort: " + sMessage + "\n\n", fTestAbortLog);

    // write current mqtt string to file
    fputs("## Mqtt string ##\n", fTestAbortLog);
    fputs(jsonEncode(m_dmMqttData, FALSE), fTestAbortLog);
    fputs("#################\n", fTestAbortLog);

    // write pmon status to file
    fputs("## PMON status ##\n", fTestAbortLog);
    fputs(jsonEncode(getListOfManagersStati(), FALSE), fTestAbortLog);
    fputs("#################\n", fTestAbortLog);

    // write pmon options to file
    fputs("## PMON status ##\n", fTestAbortLog);
    fputs(jsonEncode(getListOfManagerOptions(), FALSE), fTestAbortLog);
    fputs("#################\n", fTestAbortLog);


    fflush(fTestAbortLog);
    fclose(fTestAbortLog);

    return;
  }

  //------------------------------------------------------------------------------
  /**
  */
  public int convertResultFile(const string &sTestSuiteName)
  {
    int iErr;
    OaTestResultJson  jsonResult  = OaTestResultJson();
    OaTestResultJUnit junitResult = OaTestResultJUnit();

    if(isfile(PATH_TO_JUNIT_RESULT_FILE + sTestSuiteName))
    {
      return -1;
    }

    iErr = jsonResult.fromFile(PATH_TO_FULL_RESULT_FILE);
    if(iErr)
    {
      return -2;
    }

    junitResult.setTestSuiteName(sTestSuiteName);
    junitResult.opCopy(jsonResult);

    iErr = junitResult.convert();
    if(iErr)
    {
      return -3;
    }

    iErr = junitResult.toFile(PATH_TO_JUNIT_RESULT_FILE + sTestSuiteName + JUNIT_FILE_EXTENSION);
    if(iErr)
    {
      return -4;
    }

    return 0;
  }

};
