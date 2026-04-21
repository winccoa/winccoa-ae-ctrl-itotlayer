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
class TstMnspS7 : TstMnsp
{
  //------------------------------------------------------------------------------
  // List of the test cases
  public dyn_string getAllTestCaseIds()
  {
    return makeDynString("MSC-AUTO-0000-SETUP", // Check if all necessary DPTs and DPs are defined in Project and set empty Mqtt string.
                         "MSC-AUTO-0001",       // Create single S7 device and do basic check (Basic check includes check of CNS structure, device Dps, tag Dps, tag attributes, Mqtt mapping).
                         "MSC-AUTO-0002",       // Create additional S7 devices and do basic.
                         "MSC-AUTO-0003",       // Create multiple Sinumerik devices and do basic check.
                         "MSC-AUTO-0010",       // Delete single Sinumerik device and do basic check.
                         "MSC-AUTO-0020",       // Delete single S7 device and do basic check.
                         "MSC-AUTO-0021",       // Delete all S7 devices and do basic check.
                         "MSC-AUTO-0022",       // Delete all devices.
                         "MSC-AUTO-0041",       // Check default values of S7 device
                         "MSC-AUTO-0043",       // Check slotNumber of S7 device
                         "MSC-AUTO-0045",       // Check slotNumber change of S7 device
                         "MSC-AUTO-0200",       // Check tag address direction and set a cmd value S7
                         "MSC-AUTO-0210",       // Swap read and write address then check tag address direction and set a cmd value S7
                         "MSC-AUTO-0270",       // Check tag transformationtype S7.
                         "MSC-AUTO-0271"        // Check tag transformationtype S7 after change.
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
      case "MSC-AUTO-0001":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 1;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 1;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0001.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0002":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 2;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0001.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0002.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0003":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 4;
        m_mExpectedTagDps["EB_Bool"]  = 2;
        m_mExpectedTagDps["EB_Int"]   = 3;
        m_mExpectedTagDps["EB_Float"] = 6;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0002.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0003.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0010":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 3;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 5;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0003.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0010.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0020":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 2;
        m_mExpectedTagDps["EB_Bool"]  = 1;
        m_mExpectedTagDps["EB_Int"]   = 1;
        m_mExpectedTagDps["EB_Float"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0010.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0020.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0021":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 1;
        m_mExpectedTagDps["EB_Float"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0020.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0021.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0022":
      {
        resetCheckBasicFunctions();
        setCheckBasicFunctions();

        return (int)setMqttString(EMPTY_MQTT_STRING);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0041":
      {
        m_mExpectedDriverSettings.clear();
        m_mExpectedDriverSettings = MAP_DRV_DEFAULT_S7;

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0001.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0043":
      {
        m_mExpectedDriverSettings.clear();
        m_mExpectedDriverSettings = MAP_DRV_DEFAULT_S7;
        m_mExpectedDriverSettings[KEY_DRV_DEFAULT_DEVSLOT] = 4;

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0043_1S7_DevSlot.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0045":
      {
        m_mExpectedDriverSettings.clear();
        m_mExpectedDriverSettings = MAP_DRV_DEFAULT_S7;
        m_mExpectedDriverSettings[KEY_DRV_DEFAULT_DEVSLOT] = 4;

        iErr = setMqttStringFromFile("mqttDataString_0001.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0043_1S7_DevSlot.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0200":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_read"]       = "READ";
        m_mExpectedTagCmd["Dp_write"]      = "WRITE";
        m_mExpectedTagCmd["Dp_read_write"] = "READ&WRITE";
        m_mExpectedTagCmd["Dp_unknown"]    = "READ";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_write"] = 5;

        return (int)setMqttStringFromFile("mqttDataString_0200.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0210":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_read"]       = "WRITE";
        m_mExpectedTagCmd["Dp_write"]      = "READ";
        m_mExpectedTagCmd["Dp_read_write"] = "READ&WRITE";
        m_mExpectedTagCmd["Dp_unknown"]    = "READ";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_read"] = 10;

        iErr = setMqttStringFromFile("mqttDataString_0200.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0210.json");
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
      case "MSC-AUTO-0270":
      {
        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_S7_TransformationType.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0271":
      {
        iErr = setMqttStringFromFile("mqttDataString_xxxx_S7_TransformationType.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_S7_TransformationType_change.json");
      }

      //--------------------------------------------------------------------------
//       case "MSC-AUTO-0280":
//       {
//         m_dsExpectedLogEntries = makeDynString(LOG_NUMBER_DRIVER_START,
//                                                LOG_NUMBER_S7_PREFIX + LOG_NUMBER_DEVICE_CREATED + " (1)");
//
//         iErr = setMqttString(EMPTY_MQTT_STRING);
//         if(iErr)
//         {
//           return -1;
//         }
//         return setMqttStringFromFile("mqttDataString_0001.json");
//       }
//
      //--------------------------------------------------------------------------
//       case "MSC-AUTO-0281":
//       {
//         m_dsExpectedLogEntries = makeDynString(LOG_NUMBER_DRIVER_STOP);
//
//         iErr = setMqttStringFromFile("mqttDataString_0001.json");
//         if(iErr)
//         {
//           return -1;
//         }
//         return setMqttString(EMPTY_MQTT_STRING);
//       }
//
      //--------------------------------------------------------------------------
//       case "MSC-AUTO-0290":
//       {
//         iErr = setMqttString(EMPTY_MQTT_STRING);
//         if(iErr)
//         {
//           return -1;
//         }
//         return setMqttStringFromFile("mqttDataString_0001.json");
//       }

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
//         string sMqttString;
//
        // check if all necessary DPT are defined
//         if(!Helpers::checkBaseDpt(MNSP_DPT))
//         {
//           return testAbort("Not all necessary DPTs defined");
//         }
//
        // check if all necessary DP are defined
//         if(!Helpers::checkBaseDp(MNSP_DP))
//         {
//           return testAbort("Not all necessary DPs defined");
//         }
//
        // set empty Mqtt string to start clean
//         Helpers::setMqttString(EMPTY_MQTT_STRING);
//
//         pass("Setup of automatic test OK");
//
//         return 0;
//
        return setUpTest();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0001":
      case "MSC-AUTO-0002":
      case "MSC-AUTO-0003":
      case "MSC-AUTO-0010":
      case "MSC-AUTO-0020":
      case "MSC-AUTO-0021":
      case "MSC-AUTO-0022":
      {
        return checkBasicFunctions();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0041":
      case "MSC-AUTO-0043":
      case "MSC-AUTO-0045":
      {
        return checkDriverConnectionDefaultValues(DRIVER_NAME_S7, 1, m_mExpectedDriverSettings);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0200":
      {
        return checkTagAquisition("Device_S7", m_mExpectedTagCmd, "mqttCmdString_0200.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0210":
      {
        return checkTagAquisition("Device_S7", m_mExpectedTagCmd, "mqttCmdString_0210.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0270":
      case "MSC-AUTO-0271":
      {
        return checkTagTransformationType();
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
  TstMnspS7 test = TstMnspS7();

  // start test
  test.startAll();

  // convert fullResult json file to jUnit file
  test.convertResultFile("MSC_S7_Results");

  exit(0);
}
