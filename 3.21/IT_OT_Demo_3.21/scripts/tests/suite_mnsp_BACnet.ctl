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
class TstBACnet : TstMnsp
{
  //------------------------------------------------------------------------------
  // List of the test cases
  public dyn_string getAllTestCaseIds()
  {
    return makeDynString("MSC-AUTO-0000-SETUP", // Check if all necessary DPTs and DPs are defined in Project and set empty Mqtt string.
                         "MSC-BACNET-GEN-010",
                         "MSC-BACNET-GEN-020",
                         "MSC-BACNET-GEN-030",
                         "MSC-BACNET-GEN-040",
                         "MSC-BACNET-GEN-050",
                         "MSC-BACNET-GEN-060",
                         "MSC-BACNET-GEN-070",
                         "MSC-BACNET-GEN-080",
                         "MSC-BACNET-GEN-090",
                         "MSC-BACNET-GEN-100",
                         "MSC-BACNET-GEN-110",
                         "MSC-BACNET-TRANS-010",
                         "MSC-BACNET-TRANS-020",
                         "MSC-BACNET-WRITE-010",
                         "MSC-BACNET-WRITE-020",
                         "MSC-BACNET-BROWSE-010",
                         "MSC-BACNET-BROWSE-020"
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
      case "MSC-BACNET-GEN-010":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_BacnetDevice"] = 1;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 1;
        m_mExpectedTagDps["EB_Float"]  = 1;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_GEN_010.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-020":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_BacnetDevice"] = 3;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 1;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_BACnet_GEN_010.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_GEN_020.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-030":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_BacnetDevice"] = 3;
        m_mExpectedDeviceDps["_IEC61850_IED"] = 1;
        m_mExpectedDeviceDps["_S7_Conn"]      = 1;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 3;
        m_mExpectedTagDps["EB_Float"]  = 3;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_BACnet_GEN_020.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_GEN_030.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-040":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_BacnetDevice"] = 2;
        m_mExpectedDeviceDps["_IEC61850_IED"] = 1;
        m_mExpectedDeviceDps["_S7_Conn"]      = 1;
        m_mExpectedTagDps["EB_Bool"]   = 1;
        m_mExpectedTagDps["EB_Int"]    = 2;
        m_mExpectedTagDps["EB_Float"]  = 3;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_BACnet_GEN_030.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_GEN_040.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-050":
      {
        resetCheckBasicFunctions();
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_BACnet_GEN_040.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttString(EMPTY_MQTT_STRING);
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-060":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_BacnetDevice"] = 2;
        m_mExpectedDeviceDps["_IEC61850_IED"] = 1;
        m_mExpectedDeviceDps["_S7_Conn"]      = 1;
        m_mExpectedTagDps["EB_Int"]    = 1;
        m_mExpectedTagDps["EB_Float"]  = 4;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_BACnet_GEN_040.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_GEN_060.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-070":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_BacnetDevice"] = 2;
        m_mExpectedDeviceDps["_S7_Conn"]      = 1;
        m_mExpectedTagDps["EB_Float"]  = 4;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_0021.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_GEN_070.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-080":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_BacnetDevice"] = 2;
        m_mExpectedTagDps["EB_Float"]  = 2;
        m_mExpectedTagDps["EB_String"] = 2;
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_BACnet_GEN_070.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_GEN_080.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-090":
      {
        resetCheckBasicFunctions();
        setCheckBasicFunctions();

        iErr = setMqttStringFromFile("mqttDataString_BACnet_GEN_070.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttString(EMPTY_MQTT_STRING);
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-100":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_BacnetDevice"] = 2;
        m_mExpectedTagDps["EB_Float"]  = 4;
        m_mExpectedTagDps["EB_String"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_GEN_100.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-GEN-110":
      {
        resetCheckBasicFunctions();
        m_mExpectedDeviceDps["_BacnetDevice"] = 1;
        m_mExpectedTagDps["EB_Float"]  = 4;
        m_mExpectedTagDps["EB_String"] = 3;
        setCheckBasicFunctions();

        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_GEN_110.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-TRANS-010":
      {
        iErr = setMqttString(EMPTY_MQTT_STRING);
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_TransformationType.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-TRANS-020":
      {
        iErr = setMqttStringFromFile("mqttDataString_BACnet_TransformationType.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_TransformationType_change.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-WRITE-010":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_read"]       = "READ";
        m_mExpectedTagCmd["Dp_write"]      = "WRITE";
        m_mExpectedTagCmd["Dp_read_write"] = "READ&WRITE";
        m_mExpectedTagCmd["Dp_unknown"]    = "READ";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_write"] = 500;

        return (int)setMqttStringFromFile("mqttDataString_BACnet_write_010.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-WRITE-020":
      {
        m_mExpectedTagCmd.clear();
        m_mExpectedTagCmd["Dp_read"]       = "WRITE";
        m_mExpectedTagCmd["Dp_write"]      = "READ";
        m_mExpectedTagCmd["Dp_read_write"] = "READ&WRITE";
        m_mExpectedTagCmd["Dp_unknown"]    = "READ";

        m_mExpectedCmdResult.clear();
        m_mExpectedCmdResult["Dp_read"] = 9152;

        iErr = setMqttStringFromFile("mqttDataString_BACnet_write_010.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }
        return (int)setMqttStringFromFile("mqttDataString_BACnet_write_020.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-BROWSE-010":
      {
        iErr = setMqttStringFromFile("mqttDataString_BACnet_Browsing.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        return spSimBrowse.BACnetPrepare("_Bacnet_13");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-BROWSE-020":
      {
        iErr = setMqttStringFromFile("mqttDataString_BACnet_Browsing.json");
        if(iErr != MqttErrorCodes::noError)
        {
          return (int)iErr;
        }

        return spSimBrowse.BACnetPrepare("_Bacnet_13");
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
      case "MSC-BACNET-GEN-010":
      case "MSC-BACNET-GEN-020":
      case "MSC-BACNET-GEN-030":
      case "MSC-BACNET-GEN-040":
      case "MSC-BACNET-GEN-050":
      case "MSC-BACNET-GEN-060":
      case "MSC-BACNET-GEN-070":
      case "MSC-BACNET-GEN-080":
      case "MSC-BACNET-GEN-090":
      case "MSC-BACNET-GEN-100":
      case "MSC-BACNET-GEN-110":
      {
        return checkBasicFunctions();
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-TRANS-010":
      case "MSC-BACNET-TRANS-020":
      {
        return checkTagTransformationType();
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-WRITE-010":
      {
        return checkTagAquisition("BACnetDev1", m_mExpectedTagCmd, "mqttCmdString_BACnet_write_010.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-WRITE-020":
      {
        return checkTagAquisition("BACnetDev1", m_mExpectedTagCmd, "mqttCmdString_BACnet_write_020.json", m_mExpectedCmdResult);
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-BROWSE-010":
      {
        return checkBrowsing("mqttCmdString_BACnet_Browsing_plain.json", "BACnet_*.json", "Browsing_expected_result_BACnet.json");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-BROWSE-020":
      {
        return checkBrowsing("mqttCmdString_BACnet_Browsing_gzip.json", "BACnet_*.zip", "Browsing_expected_result_BACnet.json");
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
      case "MSC-BACNET-BROWSE-010":
      {
        return spSimBrowse.BACnetCleanUp("_Bacnet_13");
      }

      //--------------------------------------------------------------------------
      case "MSC-BACNET-BROWSE-020":
      {
        return spSimBrowse.BACnetCleanUp("_Bacnet_13");
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
  TstBACnet test = TstBACnet();

  // start test
  test.startAll();

  // convert fullResult json file to jUnit file
  test.convertResultFile("MSC_BACnet_Results");

  exit(0);
}
