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
class TstMnspMTConnect : TstMnsp
{
  //------------------------------------------------------------------------------
  // List of the test cases
  protected dyn_string getAllTestCaseIds()
  {
    dyn_string dsRet = makeDynString("MSC-AUTO-0000-SETUP", // Check if all necessary DPTs and DPs are defined in Project and set empty Mqtt string.
                         "MSC-AUTO-0250",       // Create single MTConnect and do basic check.
                         "MSC-AUTO-0251",       // Create additional MTConnect and do basic check.
                         "MSC-AUTO-0252",       // Delete single MTConnect and do basic check.
                         "MSC-AUTO-0253",       // Add tag for MTConnect and do basic check.
                         "MSC-AUTO-0254",       // Update MTConnect and do basic check.
                         "MSC-AUTO-0255");       // Create single MTConnect, S7 and do basic check.

    if (bHasFanucFocas)
    {
      dynAppend(dsRet, makeDynString("MSC-AUTO-0256"));  // Create single MTConnect, S7, FanucFocas and do basic check.
    }


    dynAppend(dsRet,
           makeDynString("MSC-AUTO-0257",       // Delete all devices and do basic check.
                      // "MSC-AUTO-0258",       // Create two MTConnect and do basic check.
                      // "MSC-AUTO-0259",       // Create single MTConnect and check if tags recevie values.
                         "MSC-AUTO-0344",       // Check browsing cmd plain file.
                         "MSC-AUTO-0345",       // Check browsing cmd zipped file.
                         "MSC-AUTO-0350",       // Check device name filter
                         "MSC-AUTO-0351"        // Check device name filter for changed device names
                        ));
    return dsRet;
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
      case "MSC-AUTO-0250":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_MTConnect"] = 1;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 2;
        m_mExpectedTagDps["EB_String"] = 4;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1MTConnect.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0251":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_MTConnect"] = 2;
        m_mExpectedTagDps["EB_Int"]    = 4;
        m_mExpectedTagDps["EB_Float"]  = 4;
        m_mExpectedTagDps["EB_String"] = 7;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_1MTConnect.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_2MTConnect.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0252":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_MTConnect"] = 1;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 2;
        m_mExpectedTagDps["EB_String"] = 4;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_2MTConnect.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1MTConnect_delete.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0253":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_MTConnect"] = 1;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 2;
        m_mExpectedTagDps["EB_String"] = 5;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_1MTConnect_delete.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1MTConnect_addDp.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0254":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_MTConnect"] = 1;
        m_mExpectedTagDps["EB_Int"]    = 1;
        m_mExpectedTagDps["EB_Float"]  = 3;
        m_mExpectedTagDps["EB_String"] = 5;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_1MTConnect_addDp.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1MTConnect_updateDP.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0255":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]   = 1;
        m_mExpectedDeviceDps["_MTConnect"] = 1;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 3;
        m_mExpectedTagDps["EB_Float"]  = 3;
        m_mExpectedTagDps["EB_String"] = 4;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1S7_1MTConnect.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0256":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_S7_Conn"]         = 1;
        m_mExpectedDeviceDps["_FocasConnection"] = 1;
        m_mExpectedDeviceDps["_MTConnect"]       = 1;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 4;
        m_mExpectedTagDps["EB_Float"]  = 4;
        m_mExpectedTagDps["EB_String"] = 5;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_1S7_1MTConnect.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1S7_1MTConnect_1FanucFocas.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0257":
      {
        resetCheckBasicFunctions();
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_xxxx_1S7_1MTConnect_1FanucFocas.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttString(EMPTY_MQTT_STRING);
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0258":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_MTConnect"] = 2;
        m_mExpectedTagDps["EB_Int"]    = 4;
        m_mExpectedTagDps["EB_Float"]  = 4;
        m_mExpectedTagDps["EB_String"] = 7;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_xxxx_2MTConnect.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0259":
      {
        return (int)setMqttStringFromFile("mqttDataString_xxxx_1MTConnect_Conn.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0344":
      {
        iErr = setMqttStringFromFile("mqttDataString_MTConnect_Browsing.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        return spSimBrowse.MTConnect();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0345":
      {
        iErr = setMqttStringFromFile("mqttDataString_MTConnect_Browsing.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        return spSimBrowse.MTConnect();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0350":
      {
        return (int)setMqttStringFromFile("mqttDataString_MTConnect_device_name_filter.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0351":
      {
        return (int)setMqttStringFromFile("mqttDataString_MTConnect_device_name_filter_change.json");
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
      case "MSC-AUTO-0250":
      case "MSC-AUTO-0251":
      case "MSC-AUTO-0252":
      case "MSC-AUTO-0253":
      case "MSC-AUTO-0254":
      case "MSC-AUTO-0255":
      case "MSC-AUTO-0256":
      case "MSC-AUTO-0257":
      case "MSC-AUTO-0258":
      {
        return checkBasicFunctions();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0259":
      {
        return checkMTConnect();
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0344":
      {
        return checkBrowsing("mqttCmdString_MTConnect_Browsing_plain.json", "MTConnect_*.json", "Browsing_expected_result_MTConnect.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0345":
      {
        return checkBrowsing("mqttCmdString_MTConnect_Browsing_gzip.json", "MTConnect_*.zip", "Browsing_expected_result_MTConnect.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0350":
      {
        return checkDeviceNameFilter("mt:Connect.one", "mt_Connect_one");
      }

      //--------------------------------------------------------------------------
      case "MSC-AUTO-0351":
      {
        return checkDeviceNameFilter("mt.Connect:-one.", "mt_Connect_-one_");
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
  TstMnspMTConnect test = TstMnspMTConnect();

  // start test
  test.startAll();

  // convert fullResult json file to jUnit file
  test.convertResultFile("MSC_MTConnect_Results");

  exit(0);
}
