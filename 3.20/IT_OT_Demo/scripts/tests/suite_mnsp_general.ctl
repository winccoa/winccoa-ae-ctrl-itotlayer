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
#uses "tests/tstMnsp.ctl"

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/*!
  @brief Base class for use case tests for mnsp.ctl
  @details This class is derived from OaTest
*/
class TstMnspGeneral : TstMnsp
{
  //------------------------------------------------------------------------------
  // List of the test cases
  protected dyn_string getAllTestCaseIds()
  {
    return makeDynString("MSC-AUTO-0000-SETUP", // Check if all necessary DPTs and DPs are defined in Project and set empty Mqtt string.
                         "MSC-AUTO-0050",       // Add tag and do basic check
                         "MSC-AUTO-0060",       // Update Tag and do basic check
                         "MSC-AUTO-0070",       // Update device and do basic check
                         "MSC-AUTO-0080",       // Set empty Mqtt string and do basic check
                         "MSC-AUTO-0090",       // Check different poll rates per device and tags
                         "MSC-AUTO-0091",       // Change existing poll rates of tags
                         "MSC-AUTO-0100",       // Check different settings for low level comparison per device and tags
                         "MSC-AUTO-0110",       // Check different settings for low level comparison per device and tags
                         "MSC-AUTO-0120",       // Check if uknown keys in mqtt string cause errors
                         "MSC-AUTO-0131",       // Check quality statusbits for "BAD_DISCONNECT"
                         "MSC-AUTO-0132",       // Check quality statusbits for "BAD_CONNECTION_REJECTED"
                         "MSC-AUTO-0133",       // Check quality statusbits for "INVALID_ARGUMENT"
                         "MSC-AUTO-0134",       // Check quality statusbits for "GOOD_ARGUMENT"
                         "MSC-AUTO-0190",       // Check timeFromField option
                         "MSC-AUTO-0213",       // Set a bool cmd value false S7
                         "MSC-AUTO-0214",       // Set a bool cmd value 0 S7
                         "MSC-AUTO-0230",       // Create two S7 devices with same tags (duplicate tags) and do basic check.
                         "MSC-AUTO-0240",       // Certificate Handling single device
                         "MSC-AUTO-0242",       // Certificate Handling update cert
                         "MSC-AUTO-0244",       // Certificate Handling delete cert
                         "MSC-AUTO-0245",       // Certificate Handling two devices one with cert
                         "MSC-AUTO-0246",       // Certificate Handling two devices both with cert
                         "MSC-AUTO-0247",       // Certificate Handling check content of cert
                         // <currently unsupported by sqlite> "MSC-AUTO-0280",       // Check driver start and device created log entries for S7
                         // <currently unsupported by sqlite> "MSC-AUTO-0281",       // Check driver stop for S7
                         // <currently unsupported by sqlite> "MSC-AUTO-0290",       // set command for restart driver S7 and check log entry
                         "MSC-AUTO-0310",       // Check log export cmd
                         "MSC-AUTO-0300",       // Check protocol filter for S7 and OPCUA
                         "MSC-AUTO-0301",       // Check protocol filter for S7 and OPCUA after changes to device
                         "MSC-GEN-MQTT-CFG-010" // Check mqtt host and port config entry
                        );
  }

  //------------------------------------------------------------------------------
  // Precondition for test case
  protected int beforeTc(const string &sTcId)
  {
    MqttErrorCodes iErr;

    if(m_bTestAborted)
    {
      return abort("Setup of TC aborted due to previous TC");
    }

    m_tTestCaseStart = getCurrentTime();

    switch(sTcId)
    {
      //--------------------------------------------------------------------------
      case "MSC-AUTO-0000-SETUP":
      {
        return pass("Import of ascii file OK -> no additional DPs needed");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0050":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 2;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0044.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0020.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0060":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 3;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Float"] = 7;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0050.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0060.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0070":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 3;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 6;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0060.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0070.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0090":
      {
        m_dmExpectedPollRate.clear();
        m_dmExpectedPollRate = makeDynMapping(makeMapping(MAP_KEY_POLLRATE_TAG,      "S7TagNr1",
                                                          MAP_KEY_POLLRATE_MILLISEC, 60000),
                                              makeMapping(MAP_KEY_POLLRATE_TAG,      "S7TagNr2",
                                                          MAP_KEY_POLLRATE_MILLISEC, 10000),
                                              makeMapping(MAP_KEY_POLLRATE_TAG,      "S7TagNr3",
                                                          MAP_KEY_POLLRATE_MILLISEC, 120000));

        return (int)setMqttStringFromFile("mqttDataString_0090.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0091":
      {
        m_dmExpectedPollRate.clear();
        m_dmExpectedPollRate = makeDynMapping(makeMapping(MAP_KEY_POLLRATE_TAG,      "S7TagNr1",
                                                          MAP_KEY_POLLRATE_MILLISEC, 60000),
                                              makeMapping(MAP_KEY_POLLRATE_TAG,      "S7TagNr2",
                                                          MAP_KEY_POLLRATE_MILLISEC, 60000),
                                              makeMapping(MAP_KEY_POLLRATE_TAG,      "S7TagNr3",
                                                          MAP_KEY_POLLRATE_MILLISEC, 80000));

        iErr = setMqttStringFromFile("mqttDataString_0090.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0091.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0100":
      {
        m_dmExpectedLowLevel.clear();
        m_dmExpectedLowLevel = makeDynMapping(makeMapping(MAP_KEY_LOWLEVEL_TAG,  "S7TagNr1",
                                                          MAP_KEY_LOWLEVEL_FLAG, FALSE),
                                              makeMapping(MAP_KEY_LOWLEVEL_TAG,  "S7TagNr2",
                                                          MAP_KEY_LOWLEVEL_FLAG, TRUE),
                                              makeMapping(MAP_KEY_POLLRATE_TAG,  "S7TagNr3",
                                                          MAP_KEY_LOWLEVEL_FLAG, FALSE));

        return (int)setMqttStringFromFile("mqttDataString_0100.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0110":
      {
        m_dmExpectedLowLevel.clear();
        m_dmExpectedLowLevel = makeDynMapping(makeMapping(MAP_KEY_LOWLEVEL_TAG,  "S7TagNr1",
                                                          MAP_KEY_LOWLEVEL_FLAG, FALSE),
                                              makeMapping(MAP_KEY_LOWLEVEL_TAG,  "S7TagNr2",
                                                          MAP_KEY_LOWLEVEL_FLAG, TRUE),
                                              makeMapping(MAP_KEY_POLLRATE_TAG,  "S7TagNr3",
                                                          MAP_KEY_LOWLEVEL_FLAG, TRUE));

        return (int)setMqttStringFromFile("mqttDataString_0110.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0120":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 3;
        m_mExpectedTagDps["EB_Int"] = 6;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0120.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0131":
      case "MSC-AUTO-0132":
      case "MSC-AUTO-0133":
      case "MSC-AUTO-0134":
      {
        return (int)setMqttStringFromFile("mqttDataString_0001_1S7_1DP.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0190":
      {
        m_dmExpectedTimeSource.clear();
        m_dmExpectedTimeSource = makeDynMapping(makeMapping(MAP_KEY_TIMESOURCE_TAG,  "S7TagNr1",
                                                            MAP_KEY_TIMESOURCE_FLAG, TIME_FROM_FIELD),
                                                makeMapping(MAP_KEY_TIMESOURCE_TAG,  "S7TagNr2",
                                                            MAP_KEY_TIMESOURCE_FLAG, TIME_FROM_SERVER),
                                                makeMapping(MAP_KEY_TIMESOURCE_TAG,  "S7TagNr3",
                                                            MAP_KEY_TIMESOURCE_FLAG, TIME_FROM_FIELD));

        return (int)setMqttStringFromFile("mqttDataString_0190.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0213":
      case "MSC-AUTO-0214":
      {
        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_write"] = FALSE;

        return (int)setMqttStringFromFile("mqttDataString_0213.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0230":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 2;
        m_mExpectedTagDps["EB_Bool"]  = 2;
        m_mExpectedTagDps["EB_Int"]   = 2;
        m_mExpectedTagDps["EB_Float"] = 2;
        setCheckBasicFunctions();

        return (int)setMqttStringFromFile("mqttDataString_0230.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0240":
      {
        m_mExpectedCerts.clear();
        m_mExpectedCerts.insert(DRIVER_NAME_S7, 1);

        return (int)setMqttStringFromFile("mqttDataString_0240.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0242":
      {
        m_mExpectedCerts.clear();
        m_mExpectedCerts.insert(DRIVER_NAME_S7, 1); // changed test case only one certificate is used now

        return (int)setMqttStringFromFile("mqttDataString_0242.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0244":
      {
        m_mExpectedCerts.clear();
        m_mExpectedCerts.insert(DRIVER_NAME_S7, 0);

        return (int)setMqttStringFromFile("mqttDataString_0001.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0245":
      {
        m_mExpectedCerts.clear();
        m_mExpectedCerts.insert(DRIVER_NAME_S7, 1);

        return (int)setMqttStringFromFile("mqttDataString_0245.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0246":
      {
        m_mExpectedCerts.clear();
        m_mExpectedCerts.insert(DRIVER_NAME_S7, 2);

        return (int)setMqttStringFromFile("mqttDataString_0246.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0247":
      {
        m_mExpectedCerts.clear();
        m_mExpectedCerts.insert(DRIVER_NAME_S7, 1);

        return (int)setMqttStringFromFile("mqttDataString_0247.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0280":
      {
        m_dsExpectedLogEntries = makeDynString(LOG_NUMBER_DRIVER_START,
                                               LOG_NUMBER_S7_PREFIX + LOG_NUMBER_DEVICE_CREATED + " (1)");

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0001.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0281":
      {
        m_dsExpectedLogEntries = makeDynString(LOG_NUMBER_DRIVER_STOP);

        iErr = setMqttStringFromFile("mqttDataString_0001.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        return waitUntilManagerRemoved("WCCOAs7");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0290":
      {
        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0001.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0300":
      {
        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        int iRetVal = changeManagerStartOptions(PMON_INDEX_MNSP_SCRIPT, "none", "ignoreProtocolFilter");
        if(iRetVal)
        {
          return iRetVal;
        }

        return (int)setMqttStringFromFile("mqttDataString_0300.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0301":
      {
        return (int)setMqttStringFromFile("mqttDataString_0301.json");
      }

      //--------------------------------------------------------------------------
      default:
      {
        return 0;
      }
    }
  }

  //------------------------------------------------------------------------------
  // Actual test case
  protected int startTestCase(const string &sTcId)
  {
    if(m_bTestAborted)
    {
      return abort("TC aborted due to previous TC");
    }

    switch(sTcId)
    {
      //--------------------------------------------------------------------------
      case "MSC-AUTO-0000-SETUP":
      {
        return setUpTest();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0050":
      case "MSC-AUTO-0060":
      case "MSC-AUTO-0070":
      case "MSC-AUTO-0080":
      case "MSC-AUTO-0120":
      case "MSC-AUTO-0230":
      {
        return checkBasicFunctions();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0090":
      case "MSC-AUTO-0091":
      {
        return checkPollRate(m_dmExpectedPollRate);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0100":
      case "MSC-AUTO-0110":
      {
        return checkLowLevel(m_dmExpectedLowLevel);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0131":
      {
        return checkQualityStatusBitsBad("mt_S7_11", (int)S7ConnState::NOT_CONNECTED, QUALITY_CODE_BAD_DISCONNECT, TRUE, FALSE);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0132":
      {
        return checkQualityStatusBitsBad("mt_S7_11", (int)S7ConnState::NOT_ACTIVE, QUALITY_CODE_BAD_CONNECTION, FALSE, TRUE);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0133":
      {
        return checkQualityStatusBitsInvalid("mt_S7_11", (int)S7OpState::RUN, QUALITY_CODE_INVALID_ARGUMENT, FALSE, FALSE);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0134":
      {
        return checkQualityStatusBitsGood("mt_S7_11", QUALITY_CODE_GOOD_ARGUMENT, FALSE, FALSE);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0190":
      {
        return checkTimeFromField(m_dmExpectedTimeSource);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0213":
      {
        return checkBoolCmd("Device_S7", "mqttCmdString_0213.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0214":
      {
        return checkBoolCmd("Device_S7", "mqttCmdString_0214.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0240":
      case "MSC-AUTO-0242":
      case "MSC-AUTO-0244":
      case "MSC-AUTO-0245":
      case "MSC-AUTO-0246":
      {
        return checkCertificates(m_mExpectedCerts);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0247":
      {
        return checkCertificateContent(DRIVER_NAME_S7, 1);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0280":
      case "MSC-AUTO-0281":
      {
        return checkLogTable(m_dsExpectedLogEntries);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0290":
      {
        return checkDriverRestart("WCCOAs7");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0300":
      {
        return checkProtocolFilter("S7", "_S7_Conn");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0301":
      {
        return checkProtocolFilter("S7", "_S7_Conn");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0310":
      {
        return checkLogExport();
      }

      //--------------------------------------------------------------------------
      case "MSC-GEN-MQTT-CFG-010":
      {
        return checkMqttCfgEntries("10.10.10.10", 1884);
      }

      //--------------------------------------------------------------------------
      default:
      {
        fail("Test case <" + sTcId + "> not found");
        return -1;
      }
    }
  }

  //------------------------------------------------------------------------------
  // Cleanup for test case
  public int afterTc(const string &sTcId)
  {
    MqttErrorCodes iErr;

    if(m_bTestAborted)
    {
      return abort("Cleanup of TC aborted due to previous TC");
    }

    switch(sTcId)
    {
      //--------------------------------------------------------------------------
      case "MSC-AUTO-0301":
      {
        return changeManagerStartOptions(PMON_INDEX_MNSP_SCRIPT, "ignoreProtocolFilter", "none");
      }

      //--------------------------------------------------------------------------
      default:
      {
        return 0;
      }
    }
  }

};

//--------------------------------------------------------------------------------
main()
{
  TstMnspGeneral test = TstMnspGeneral();

  // start test
  test.startAll();

  // convert fullResult json file to jUnit file
  test.convertResultFile("MSC_General_Results");

  exit(0);
}
