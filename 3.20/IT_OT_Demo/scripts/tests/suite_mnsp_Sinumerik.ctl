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
class TstMnspSinumerik : TstMnsp
{
  //------------------------------------------------------------------------------
  // List of the test cases
  protected dyn_string getAllTestCaseIds()
  {
    return makeDynString("MSC-AUTO-0000-SETUP", // Check if all necessary DPTs and DPs are defined in Project and set empty Mqtt string.
                         "MSC-AUTO-0023",       // Create single Sinumerik and do basic check.
                         "MSC-AUTO-0024",       // Create additional Sinumerik devices and do basic.
                         "MSC-AUTO-0025",       // Create multiple S7 devices and do basic check.
                         "MSC-AUTO-0026",       // Delete single S7 device and do basic check.
                         "MSC-AUTO-0027",       // Delete all Sinumerik devices and do basic check.
                         "MSC-AUTO-0028",       // Delete all exisiting devices and do basic check
                         "MSC-AUTO-0029",       // Set multiple S7 and Sinumerik devices and do basic check.
                         "MSC-AUTO-0042",       // Check default values of Sinumerik device
                         "MSC-AUTO-0044",       // Check slotNumber of Sinumerik device
                         "MSC-AUTO-0046",       // Check slotNumber change of Simuerik device
                         "MSC-AUTO-0201",       // Check tag address direction and set a cmd value Sinumerik
                         "MSC-AUTO-0211",       // Swap read and write address then check tag address direction and set a cmd value Sinumerik
                         "MSC-AUTO-0272",       // Check tag transformationtype Sinumerik.
                         "MSC-AUTO-0273",       // Check tag transformationtype Sinumerik after change.
                         "MSC-AUTO-0322",       // Check hysteresis for Sinumerik.
                         "MSC-AUTO-0323"        // Check hysteresis for Sinumerik after change.
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
      case "MSC-AUTO-0023":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 1;
        m_mExpectedTagDps["EB_Float"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0023.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0024":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 2;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 2;
        m_mExpectedTagDps["EB_Float"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0023.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0024.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0025":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 4;
        m_mExpectedTagDps["EB_Bool"]  = 2;
        m_mExpectedTagDps["EB_Int"]   = 3;
        m_mExpectedTagDps["EB_Float"] = 6;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0024.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0003.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0026":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 3;
        m_mExpectedTagDps["EB_Bool"]  = 2;
        m_mExpectedTagDps["EB_Int"]   = 3;
        m_mExpectedTagDps["EB_Float"] = 4;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0003.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0026.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0027":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 1;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 1;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0026.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0001.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0028":
      {
        resetCheckBasicFunctions();
        setCheckBasicFunctions();

        return (int)setMqttString(EMPTY_MQTT_STRING);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0029":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 4;
        m_mExpectedTagDps["EB_Bool"]  = 2;
        m_mExpectedTagDps["EB_Int"]   = 3;
        m_mExpectedTagDps["EB_Float"] = 6;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0003.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0042":
      {
        m_mExpectedDriverSettings.clear();
        m_mExpectedDriverSettings = MAP_DRV_DEFAULT_SINUMERIK;

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0021.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0044":
      {
        m_mExpectedDriverSettings.clear();
        m_mExpectedDriverSettings = MAP_DRV_DEFAULT_SINUMERIK;
        m_mExpectedDriverSettings[KEY_DRV_DEFAULT_DEVSLOT] = 5;

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0044_1Sinumerik_DevSlot.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0046":
      {
        m_mExpectedDriverSettings.clear();
        m_mExpectedDriverSettings = MAP_DRV_DEFAULT_SINUMERIK;
        m_mExpectedDriverSettings[KEY_DRV_DEFAULT_DEVSLOT] = 5;

        iErr = setMqttStringFromFile("mqttDataString_0021.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0044_1Sinumerik_DevSlot.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0201":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_read"]       = "READ";
        m_mExpectedTagCmd["Dp_write"]      = "WRITE";
        m_mExpectedTagCmd["Dp_read_write"] = "READ&WRITE";
        m_mExpectedTagCmd["Dp_unknown"]    = "READ";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_write"] = 50;

        return (int)setMqttStringFromFile("mqttDataString_0201.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0211":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_read"]       = "WRITE";
        m_mExpectedTagCmd["Dp_write"]      = "READ";
        m_mExpectedTagCmd["Dp_read_write"] = "READ&WRITE";
        m_mExpectedTagCmd["Dp_unknown"]    = "READ";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_read"] = 100;

        iErr = setMqttStringFromFile("mqttDataString_0201.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0211.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0272":
      {
        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_Sinumerik_TransformationType.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0273":
      {
        iErr = setMqttStringFromFile("mqttDataString_xxxx_Sinumerik_TransformationType.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_Sinumerik_TransformationType_change.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0322":
      {
        m_mExpectedHysteresis.clear();
        m_mExpectedHysteresis["sin_plc_1_read_01"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_02"] = 2;
        m_mExpectedHysteresis["sin_plc_1_read_03"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_04"] = 5;
        m_mExpectedHysteresis["sin_plc_1_read_05"] = 7;
        m_mExpectedHysteresis["sin_plc_1_read_06"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_07"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_08"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_09"] = 2.7;
        m_mExpectedHysteresis["sin_plc_1_read_10"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_11"] = 1.5;
        m_mExpectedHysteresis["sin_plc_1_read_12"] = 0;

        return (int) setMqttStringFromFile("mqttDataString_Sinumerik_hysteresis.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0323":
      {
        m_mExpectedHysteresis.clear();
        m_mExpectedHysteresis["sin_plc_1_read_01"] = 3;
        m_mExpectedHysteresis["sin_plc_1_read_02"] = 8;
        m_mExpectedHysteresis["sin_plc_1_read_03"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_04"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_05"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_06"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_07"] = 9;
        m_mExpectedHysteresis["sin_plc_1_read_08"] = 4;
        m_mExpectedHysteresis["sin_plc_1_read_09"] = 3.2;
        m_mExpectedHysteresis["sin_plc_1_read_10"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_11"] = 0;
        m_mExpectedHysteresis["sin_plc_1_read_12"] = 0.9;

        iErr = setMqttStringFromFile("mqttDataString_Sinumerik_hysteresis.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int) setMqttStringFromFile("mqttDataString_Sinumerik_hysteresis_change.json");
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
      case "MSC-AUTO-0023":
      case "MSC-AUTO-0024":
      case "MSC-AUTO-0025":
      case "MSC-AUTO-0026":
      case "MSC-AUTO-0027":
      case "MSC-AUTO-0028":
      case "MSC-AUTO-0029":
      {
        return checkBasicFunctions();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0042":
      case "MSC-AUTO-0044":
      case "MSC-AUTO-0046":
      {
        return checkDriverConnectionDefaultValues(DRIVER_NAME_SINUMERIK, 1, m_mExpectedDriverSettings);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0201":
      {
        return checkTagAquisition("Device_Sinumerik", m_mExpectedTagCmd, "mqttCmdString_0201.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0211":
      {
        return checkTagAquisition("Device_Sinumerik", m_mExpectedTagCmd, "mqttCmdString_0211.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0272":
      case "MSC-AUTO-0273":
      {
        return checkTagTransformationType();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0322":
      {
        return checkHysteresis("sin_plc_1", m_mExpectedHysteresis);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0323":
      {
        return checkHysteresis("sin_plc_1", m_mExpectedHysteresis);
      }

      //--------------------------------------------------------------------------
      default:
      {
        fail("Test case <" + sTcId + "> not found");
        return -1;
      }
    }
  }

};

//--------------------------------------------------------------------------------
main()
{
  TstMnspSinumerik test = TstMnspSinumerik();

  // start test
  test.startAll();

  // convert fullResult json file to jUnit file
  test.convertResultFile("MSC_Sinumerik_Results");

  exit(0);
}
