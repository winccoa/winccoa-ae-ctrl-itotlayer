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
#uses "classes/TimeOut"
#uses "tests/tstMnsp.ctl"

//--------------------------------------------------------------------------------
// Variables and Constants

// Simulate browsing results
shared_ptr<TstBrowsing> spSimBrowse = new TstBrowsing();

//--------------------------------------------------------------------------------
/*!
  @brief Base class for use case tests for mnsp.ctl
  @details This class is derived from OaTest
*/
class TstMnspS7Plus : TstMnsp
{
  //------------------------------------------------------------------------------
  // List of the test cases
  public dyn_string getAllTestCaseIds()
  {
    return makeDynString("MSC-AUTO-0000-SETUP", // Check if all necessary DPTs and DPs are defined in Project and set empty Mqtt string.
                         "MSC-AUTO-0220",       // Create single S7Plus device and do basic check (Basic check includes check of CNS structure, device Dps, tag Dps, tag attributes, Mqtt mapping).
                         "MSC-AUTO-0221",       // Create additional S7Plus devices and do basic.
                         "MSC-AUTO-0222",       // Create multiple S7, Sinumerik devices and do basic check.
                         "MSC-AUTO-0223",       // Delete single S7Plus device and do basic check.
                         "MSC-AUTO-0224",       // Delete all devices and do basic check.
                         "MSC-AUTO-0225",       // Update S7Plus device all devices and do basic check.
                         "MSC-AUTO-0226",       // Create S7 and S7Plus device and do basic check.
                         "MSC-AUTO-0227",       // Delete all devices and do basic check.
                         "MSC-AUTO-0228",       // Delete all devices and do basic check.
                         "MSC-AUTO-0202",       // Check tag address direction and set a cmd value S7Plus
                         "MSC-AUTO-0212",       // Swap read and write address then check tag address direction and set a cmd value S7Plus
                         "MSC-AUTO-0215",       // Check tag address direction and set a cmd value S7Plus with float precision loss
                         "MSC-AUTO-0216",       // Check tag address direction and set a negative cmd value S7Plus with float precision loss
                         "MSC-AUTO-0274",       // Check tag transformationtype S7Plus.
                         "MSC-AUTO-0275",       // Check tag transformationtype S7Plus after change.
                         "MSC-AUTO-0320",       // Check hysteresis for S7Plus.
                         "MSC-AUTO-0321",       // Check hysteresis for S7Plus after change.
                         "MSC-AUTO-0342",       // Check browsing cmd plain file.
                         "MSC-AUTO-0343",        // Check browsing cmd zipped file.
                         "MSC-S7PLUS-IP-CHANGE" // Check if connection is deactivated in case the IP address is changed
                        );
  }

  //------------------------------------------------------------------------------
  // Precondition for test case
  public int beforeTc(const string &sTcId)
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
      case "MSC-AUTO-0220":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7PlusConnection"] = 1;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 1;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0220.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0221":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7PlusConnection"] = 2;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0220.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0221.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0222":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]          = 2;
        m_mExpectedDeviceDps["_S7PlusConnection"] = 2;
        m_mExpectedTagDps["EB_Bool"]  = 2;
        m_mExpectedTagDps["EB_Int"]   = 3;
        m_mExpectedTagDps["EB_Float"] = 6;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0221.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0222.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0223":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]          = 2;
        m_mExpectedDeviceDps["_S7PlusConnection"] = 1;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 2;
        m_mExpectedTagDps["EB_Float"] = 5;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0222.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0223.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0224":
      {
        resetCheckBasicFunctions();
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0223.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttString(EMPTY_MQTT_STRING);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0225":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7PlusConnection"] = 1;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Float"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0220.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0225.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0226":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]          = 1;
        m_mExpectedDeviceDps["_S7PlusConnection"] = 1;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0001.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0226.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0227":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]          = 1;
        m_mExpectedDeviceDps["_S7PlusConnection"] = 2;
        m_mExpectedTagDps["EB_Bool"]  = 2;
        m_mExpectedTagDps["EB_Int"]   = 2;
        m_mExpectedTagDps["EB_Float"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0226.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0227.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0228":
      {
        resetCheckBasicFunctions();
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0227.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttString(EMPTY_MQTT_STRING);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0202":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_read"]       = "READ";
        m_mExpectedTagCmd["Dp_write"]      = "WRITE";
        m_mExpectedTagCmd["Dp_read_write"] = "READ&WRITE";
        m_mExpectedTagCmd["Dp_unknown"]    = "READ";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_write"] = 500;

        return (int)setMqttStringFromFile("mqttDataString_0202.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0212":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_read"]       = "WRITE";
        m_mExpectedTagCmd["Dp_write"]      = "READ";
        m_mExpectedTagCmd["Dp_read_write"] = "READ&WRITE";
        m_mExpectedTagCmd["Dp_unknown"]    = "READ";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_read"] = 1000;

        iErr = setMqttStringFromFile("mqttDataString_0202.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0212.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0215":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_write"] = "WRITE";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_write"] = 5.99;

        return (int)setMqttStringFromFile("mqttDataString_0215.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0216":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_write"] = "WRITE";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_write"] = -5.99;

        return (int)setMqttStringFromFile("mqttDataString_0215.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0274":
      {
        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_S7Plus_TransformationType.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0275":
      {
        iErr = setMqttStringFromFile("mqttDataString_xxxx_S7Plus_TransformationType.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_S7Plus_TransformationType_change.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0320":
      {
        m_mExpectedHysteresis.clear();
        m_mExpectedHysteresis["s7plus_plc_1_read_01"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_02"] = 2;
        m_mExpectedHysteresis["s7plus_plc_1_read_03"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_04"] = 5;
        m_mExpectedHysteresis["s7plus_plc_1_read_05"] = 7;
        m_mExpectedHysteresis["s7plus_plc_1_read_06"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_07"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_08"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_09"] = 2.7;
        m_mExpectedHysteresis["s7plus_plc_1_read_10"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_11"] = 1.5;
        m_mExpectedHysteresis["s7plus_plc_1_read_12"] = 0;

        return (int) setMqttStringFromFile("mqttDataString_S7Plus_hysteresis.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0321":
      {
        m_mExpectedHysteresis.clear();
        m_mExpectedHysteresis["s7plus_plc_1_read_01"] = 3;
        m_mExpectedHysteresis["s7plus_plc_1_read_02"] = 8;
        m_mExpectedHysteresis["s7plus_plc_1_read_03"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_04"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_05"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_06"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_07"] = 9;
        m_mExpectedHysteresis["s7plus_plc_1_read_08"] = 4;
        m_mExpectedHysteresis["s7plus_plc_1_read_09"] = 3.2;
        m_mExpectedHysteresis["s7plus_plc_1_read_10"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_11"] = 0;
        m_mExpectedHysteresis["s7plus_plc_1_read_12"] = 0.9;

        iErr = setMqttStringFromFile("mqttDataString_S7Plus_hysteresis.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int) setMqttStringFromFile("mqttDataString_S7Plus_hysteresis_change.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0342":
      {
        iErr = setMqttStringFromFile("mqttDataString_S7Plus_Browsing.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        return spSimBrowse.S7plusPrepare("_S7PlusPLC1");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0343":
      {
        iErr = setMqttStringFromFile("mqttDataString_S7Plus_Browsing.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        return spSimBrowse.S7plusPrepare("_S7PlusPLC1");
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
  public int startTestCase(const string &sTcId)
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
      case "MSC-AUTO-0220":
      case "MSC-AUTO-0221":
      case "MSC-AUTO-0222":
      case "MSC-AUTO-0223":
      case "MSC-AUTO-0224":
      case "MSC-AUTO-0225":
      case "MSC-AUTO-0226":
      case "MSC-AUTO-0227":
      case "MSC-AUTO-0228":
      {
        return checkBasicFunctions();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0202":
      {
        return checkTagAquisition("Device_S7Plus", m_mExpectedTagCmd, "mqttCmdString_0202.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0212":
      {
        return checkTagAquisition("Device_S7Plus", m_mExpectedTagCmd, "mqttCmdString_0212.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0215":
      {
        return checkTagAquisition("Device_S7Plus", m_mExpectedTagCmd, "mqttCmdString_0215.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0216":
      {
        return checkTagAquisition("Device_S7Plus", m_mExpectedTagCmd, "mqttCmdString_0216.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0274":
      case "MSC-AUTO-0275":
      {
        return checkTagTransformationType();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0320":
      {
        return checkHysteresis("s7plus_plc_1", m_mExpectedHysteresis);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0321":
      {
        return checkHysteresis("s7plus_plc_1", m_mExpectedHysteresis);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0342":
      {
        return checkBrowsing("mqttCmdString_S7Plus_Browsing_plain.json", "S7Plus_*.json", "Browsing_expected_result_S7Plus.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0343":
      {
        return checkBrowsing("mqttCmdString_S7Plus_Browsing_gzip.json", "S7Plus_*.zip", "Browsing_expected_result_S7Plus.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-S7PLUS-IP-CHANGE":
      {
        return checkIpAddressChange("_S7PlusPLC1");
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
      case "MSC-AUTO-0342":
      {
        return spSimBrowse.S7plusCleanUp("_S7PlusPLC1");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0343":
      {
        return spSimBrowse.S7plusCleanUp("_S7PlusPLC1");
      }

      //--------------------------------------------------------------------------
      default:
      {
        return 0;
      }
    }
  }

  //------------------------------------------------------------------------------
  private int checkIpAddressChange(const string &sConnectionDp)
  {
    shared_ptr<bool> pIsDisconnected = new bool(false);
    shared_ptr<TimeOut> pTimer = nullptr;
    MqttErrorCodes iErr;

    // create a device
    iErr = setMqttStringFromFile("mqttDataString_0220.json");
    if(iErr != MqttErrorCodes::noError)
    {
      return (int)iErr;
    }

    dpConnectUserData("ipAddressChangeCB", pIsDisconnected, sConnectionDp + ".Command.Enable");

    // start timer
    pTimer = new TimeOut(30.0);

    // change ip address
    iErr = setMqttStringFromFile("mqttDataString_S7Plus_ip_change.json");
    if(iErr != MqttErrorCodes::noError)
    {
      dpDisconnectUserData("ipAddressChangeCB", pIsDisconnected, sConnectionDp + ".Command.Enable");
      return (int)iErr;
    }

    // wait until disconnected call back happens or timer has expired
    while (!pTimer.hasExpired() && pIsDisconnected)
    {
      delay(1);
    }

    assertFalse(pTimer.hasExpired(), "Check if disconnected callback for ip address change has been received in given time frame");

    dpDisconnectUserData("ipAddressChangeCB", pIsDisconnected, sConnectionDp + ".Command.Enable");

    return 0;
  }

  //------------------------------------------------------------------------------
  private void ipAddressChangeCB(shared_ptr<bool> bIsDisconnected, const string &sDp, const bool bEnable)
  {
    bIsDisconnected = bEnable;
  }

};

//--------------------------------------------------------------------------------
main()
{
  TstMnspS7Plus test = TstMnspS7Plus();

  // start test
  test.startAll();

  // convert fullResult json file to jUnit file
  test.convertResultFile("MSC_S7Plus_Results");

  exit(0);
}
