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

// Simulate browsing results
shared_ptr<TstBrowsing> spSimBrowse = new TstBrowsing();

//--------------------------------------------------------------------------------
/*!
  @brief Base class for use case tests for mnsp.ctl
  @details This class is derived from OaTest
*/
class TstMnspIEC61850 : TstMnsp
{
  //------------------------------------------------------------------------------
  // List of the test cases
  public dyn_string getAllTestCaseIds()
  {
    dyn_string dsRet = makeDynString("MSC-AUTO-0000-SETUP", // Check if all necessary DPTs and DPs are defined in Project and set empty Mqtt string.
                         "MSC-AUTO-0260",       // Create single IEC61850 do basic check.
                         "MSC-AUTO-0261",       // Add tags to single IEC61850 device and do basic check.
                         "MSC-AUTO-0262",       // Update tags of single IEC61850 device and do basic check.
                         "MSC-AUTO-0263",       // Delete tags of single IEC61850 device and do basic check.
                         "MSC-AUTO-0264",       // Create two IEC61850 devices and do basic check.
                         "MSC-AUTO-0265");      // Delete a IEC61850 device and do basic check.

    if (bHasFanucFocas)
    {
      dynAppend(dsRet, makeDynString(
                           "MSC-AUTO-0266",       // Create S7, Sinumerik, FanucFocas and IEC61850 device and do basic check.
                           "MSC-AUTO-0267"));     // Create S7, Sinumerik, FanucFocas and two IEC61850 device and do basic check.

    }

    dynAppend(dsRet, makeDynString(
                         "MSC-AUTO-0278",       // Check tag transformationtype IEC61850.
                         "MSC-AUTO-0279",       // Check tag transformationtype IEC61850 after change.
                         "MSC-AUTO-0326",       // Check hysteresis for IEC61850.
                         "MSC-AUTO-0327",       // Check hysteresis for IEC61850 after change.
                         "MSC-AUTO-0340",       // Check browsing cmd plain file.
                         "MSC-AUTO-0341"        // Check browsing cmd zipped file.
                        ));

    return dsRet;
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
      case "MSC-AUTO-0260":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_IEC61850_IED"] = 1;
        m_mExpectedTagDps["EB_Int"] = 1;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1IEC.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0261":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_IEC61850_IED"] = 1;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 1;
        m_mExpectedTagDps["EB_Float"]  = 1;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_1IEC.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1IEC_addDp.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0262":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_IEC61850_IED"] = 1;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_1IEC_addDp.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1IEC_updateDp.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0263":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_IEC61850_IED"] = 1;
        m_mExpectedTagDps["EB_Int"] = 1;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_1IEC_addDp.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1IEC.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0264":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_IEC61850_IED"] = 2;
        m_mExpectedTagDps["EB_Bool"]   = 2;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 2;
        m_mExpectedTagDps["EB_String"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_2IEC.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0265":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_IEC61850_IED"] = 1;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 1;
        m_mExpectedTagDps["EB_Float"]  = 1;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_2IEC.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_2IEC_delete.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0266":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 2;
        m_mExpectedDeviceDps["_FocasConnection"] = 1;
        m_mExpectedDeviceDps["_IEC61850_IED"] = 1;
        m_mExpectedTagDps["EB_Bool"]   = 2;
        m_mExpectedTagDps["EB_Int"]    = 3;
        m_mExpectedTagDps["EB_Float"]  = 5;
        m_mExpectedTagDps["EB_String"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1S7_1Sinumerik_1FanucFocas_1IEC.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0267":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"] = 2;
        m_mExpectedDeviceDps["_FocasConnection"] = 1;
        m_mExpectedDeviceDps["_IEC61850_IED"] = 2;
        m_mExpectedTagDps["EB_Bool"]   = 3;
        m_mExpectedTagDps["EB_Int"]    = 4;
        m_mExpectedTagDps["EB_Float"]  = 6;
        m_mExpectedTagDps["EB_String"] = 4;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_1S7_1Sinumerik_1FanucFocas_1IEC.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1S7_1Sinumerik_1FanucFocas_2IEC.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0278":
      {
        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_IEC61850_TransformationType.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0279":
      {
        iErr = setMqttStringFromFile("mqttDataString_xxxx_IEC61850_TransformationType.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_IEC61850_TransformationType_change.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0326":
      {
        m_mExpectedHysteresis.clear();
        m_mExpectedHysteresis["iec_plc_1_read_01"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_02"] = 2;
        m_mExpectedHysteresis["iec_plc_1_read_03"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_04"] = 5;
        m_mExpectedHysteresis["iec_plc_1_read_05"] = 7;
        m_mExpectedHysteresis["iec_plc_1_read_06"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_07"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_08"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_09"] = 2.7;
        m_mExpectedHysteresis["iec_plc_1_read_10"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_11"] = 1.5;
        m_mExpectedHysteresis["iec_plc_1_read_12"] = 0;

        return (int) setMqttStringFromFile("mqttDataString_IEC61850_hysteresis.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0327":
      {
        m_mExpectedHysteresis.clear();
        m_mExpectedHysteresis["iec_plc_1_read_01"] = 3;
        m_mExpectedHysteresis["iec_plc_1_read_02"] = 8;
        m_mExpectedHysteresis["iec_plc_1_read_03"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_04"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_05"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_06"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_07"] = 9;
        m_mExpectedHysteresis["iec_plc_1_read_08"] = 4;
        m_mExpectedHysteresis["iec_plc_1_read_09"] = 3.2;
        m_mExpectedHysteresis["iec_plc_1_read_10"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_11"] = 0;
        m_mExpectedHysteresis["iec_plc_1_read_12"] = 0.9;

        iErr = setMqttStringFromFile("mqttDataString_IEC61850_hysteresis.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int) setMqttStringFromFile("mqttDataString_IEC61850_hysteresis_change.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0340":
      {
        iErr = setMqttStringFromFile("mqttDataString_IEC61850_Browsing.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        return spSimBrowse.IEC61850();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0341":
      {
        iErr = setMqttStringFromFile("mqttDataString_IEC61850_Browsing.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        return spSimBrowse.IEC61850();
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
      case "MSC-AUTO-0260":
      case "MSC-AUTO-0261":
      case "MSC-AUTO-0262":
      case "MSC-AUTO-0263":
      case "MSC-AUTO-0264":
      case "MSC-AUTO-0265":
      case "MSC-AUTO-0266":
      case "MSC-AUTO-0267":
      {
        return checkBasicFunctions();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0278":
      case "MSC-AUTO-0279":
      {
        return checkTagTransformationType();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0326":
      {
        return checkHysteresis("iec_plc_1", m_mExpectedHysteresis);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0327":
      {
        return checkHysteresis("iec_plc_1", m_mExpectedHysteresis);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0340":
      {
        return checkBrowsing("mqttCmdString_IEC61850_Browsing_plain.json", "IEC61850_*.json", "Browsing_expected_result_IEC61850.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0341":
      {
        return checkBrowsing("mqttCmdString_IEC61850_Browsing_gzip.json", "IEC61850_*.zip", "Browsing_expected_result_IEC61850.json");
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
  TstMnspIEC61850 test = TstMnspIEC61850();

  // start test
  test.startAll();

  // convert fullResult json file to jUnit file
  test.convertResultFile("MSC_IEC61850_Results");

  exit(0);
}
