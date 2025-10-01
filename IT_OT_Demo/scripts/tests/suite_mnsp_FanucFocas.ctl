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
class TstMnspFanucFocas : TstMnsp
{
  //------------------------------------------------------------------------------
  // List of the test cases
  public dyn_string getAllTestCaseIds()
  {
    return makeDynString("MSC-AUTO-0000-SETUP", // Check if all necessary DPTs and DPs are defined in Project and set empty Mqtt string.
                         "MSC-AUTO-0030",       // Create single FanucFocas device and do basic check.
                         "MSC-AUTO-0031",       // Create additional FanucFocas devices and do basic.
                         "MSC-AUTO-0032",       // Create additional S7 and Sinumerik devices and do basic.
                         "MSC-AUTO-0033",       // Delete single FanucFocas device and do basic check.
                         "MSC-AUTO-0034",       // Delete single S7 device and do basic check.
                         "MSC-AUTO-0035",       // Delete all devices and do basic check.
                         "MSC-AUTO-0036",       // Create single S7 device and do basic check.
                         "MSC-AUTO-0037",       // Create additional FanucFocas devices and do basic.
                         "MSC-AUTO-0038",       // Delete single FanucFocas device and do basic check.
                         "MSC-AUTO-0039",       // Delete all devices and do basic check.
                         "MSC-AUTO-0040",       // Create single S7, Sinumerik and FanucFocas device and do basic check.
                         "MSC-AUTO-0276",       // Check tag transformationtype FanucFocas.
                         "MSC-AUTO-0277",       // Check tag transformationtype FanucFocas after change.
                         "MSC-AUTO-0324",       // Check hysteresis for FanucFocas.
                         "MSC-AUTO-0325",       // Check hysteresis for FanucFocas after change.
                         "MSC-FANUC-BROWSING"   // Check FanucFocas default browsing
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
      case "MSC-AUTO-0035":
      case "MSC-AUTO-0039":
      {
        resetCheckBasicFunctions();
        setCheckBasicFunctions();

        return (int)setMqttString(EMPTY_MQTT_STRING);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0036":
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
      case "MSC-AUTO-0030":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_FocasConnection"] = 1;
        m_mExpectedTagDps["EB_Int"]    = 1;
        m_mExpectedTagDps["EB_Float"]  = 1;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0030.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0031":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_FocasConnection"] = 2;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 2;
        m_mExpectedTagDps["EB_String"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0030.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0031.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0032":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]         = 2;
        m_mExpectedDeviceDps["_FocasConnection"] = 2;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 3;
        m_mExpectedTagDps["EB_Float"]  = 5;
        m_mExpectedTagDps["EB_String"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0031.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0032.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0033":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]         = 2;
        m_mExpectedDeviceDps["_FocasConnection"] = 1;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 4;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0032.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0033.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0034":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]         = 1;
        m_mExpectedDeviceDps["_FocasConnection"] = 1;
        m_mExpectedTagDps["EB_Int"]    = 1;
        m_mExpectedTagDps["EB_Float"]  = 3;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0033.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0034.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0037":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]         = 1;
        m_mExpectedDeviceDps["_FocasConnection"] = 2;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 3;
        m_mExpectedTagDps["EB_Float"]  = 3;
        m_mExpectedTagDps["EB_String"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0037.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0038":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]         = 1;
        m_mExpectedDeviceDps["_FocasConnection"] = 1;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 2;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0037.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0038.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0040":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]         = 2;
        m_mExpectedDeviceDps["_FocasConnection"] = 2;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 3;
        m_mExpectedTagDps["EB_Float"]  = 5;
        m_mExpectedTagDps["EB_String"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_0032.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0276":
      {
        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_FanucFocas_TransformationType.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0277":
      {
        iErr = setMqttStringFromFile("mqttDataString_xxxx_FanucFocas_TransformationType.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_FanucFocas_TransformationType_change.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0324":
      {
        m_mExpectedHysteresis.clear();
        m_mExpectedHysteresis["fanuc_plc_1_read_01"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_02"] = 2;
        m_mExpectedHysteresis["fanuc_plc_1_read_03"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_04"] = 5;
        m_mExpectedHysteresis["fanuc_plc_1_read_05"] = 7;
        m_mExpectedHysteresis["fanuc_plc_1_read_06"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_07"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_08"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_09"] = 2.7;
        m_mExpectedHysteresis["fanuc_plc_1_read_10"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_11"] = 1.5;
        m_mExpectedHysteresis["fanuc_plc_1_read_12"] = 0;

        return (int) setMqttStringFromFile("mqttDataString_FanucFocas_hysteresis.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0325":
      {
        m_mExpectedHysteresis.clear();
        m_mExpectedHysteresis["fanuc_plc_1_read_01"] = 3;
        m_mExpectedHysteresis["fanuc_plc_1_read_02"] = 8;
        m_mExpectedHysteresis["fanuc_plc_1_read_03"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_04"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_05"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_06"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_07"] = 9;
        m_mExpectedHysteresis["fanuc_plc_1_read_08"] = 4;
        m_mExpectedHysteresis["fanuc_plc_1_read_09"] = 3.2;
        m_mExpectedHysteresis["fanuc_plc_1_read_10"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_11"] = 0;
        m_mExpectedHysteresis["fanuc_plc_1_read_12"] = 0.9;

        iErr = setMqttStringFromFile("mqttDataString_FanucFocas_hysteresis.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int) setMqttStringFromFile("mqttDataString_FanucFocas_hysteresis_change.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-FANUC-BROWSING":
      {
        return (int)setMqttStringFromFile("mqttDataString_FanucFocas_Browsing.json");
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
      case "MSC-AUTO-0030":
      case "MSC-AUTO-0031":
      case "MSC-AUTO-0032":
      case "MSC-AUTO-0033":
      case "MSC-AUTO-0034":
      case "MSC-AUTO-0035":
      case "MSC-AUTO-0036":
      case "MSC-AUTO-0037":
      case "MSC-AUTO-0038":
      case "MSC-AUTO-0039":
      case "MSC-AUTO-0040":
      {
        return checkBasicFunctions();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0276":
      case "MSC-AUTO-0277":
      {
        return checkTagTransformationType();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0324":
      {
        return checkHysteresis("fanuc_plc_1", m_mExpectedHysteresis);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0325":
      {
        return checkHysteresis("fanuc_plc_1", m_mExpectedHysteresis);
      }

      //--------------------------------------------------------------------------
      case "MSC-FANUC-BROWSING":
      {
        return checkBrowsing("mqttCmdString_FanucFocas_Browsing_plain.json", "FanucFocas_*.json", "Browsing_expected_result_FanucFocas.json");
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
  TstMnspFanucFocas test = TstMnspFanucFocas();

  // start test
  test.startAll();

  // convert fullResult json file to jUnit file
  test.convertResultFile("MSC_FanucFocas_Results");

  exit(0);
}
