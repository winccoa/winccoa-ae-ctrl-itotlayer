// $License: NOLICENSE
//--------------------------------------------------------------------------------
/** Tests for the library: scripts/libs/$origLibRelPath.
  @file $relPath
  @test Unit tests for the library: scripts/libs/$origLibRelPath
  @copyright $copyright
  @author z0043ctz
 */

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "pmonInterface"


//--------------------------------------------------------------------------------
// Variables and Constants
const string PROJECT_NAME = PROJ;
const string PROJECT_CONFIG_PATH = getPath(CONFIG_REL_PATH);

const int MAX_COUNT = 100;
const int PMON_INDEX_EDGEBOX_SCRIPT = 3;
const int PMON_INDEX_MNSP_SCRIPT    = 6;

// list of debug flags which will be added for mnsp.ctl ctrl manager
const mapping MAN_OPT_MNSP = makeMapping("StartOptions", "-num 2 mnsp.ctl -dbg device,value,config,tag,command,browse,log,ignoreProtocolFilter,localSCDFile,bacnet");

const string KEY_START_ALL_TESTSUITES    = "--all";

dyn_string dsTestSuites = makeDynString("suite_mnsp_S7.ctl",
                                        "suite_mnsp_Sinumerik.ctl",
                                        "suite_mnsp_S7plus.ctl",
                                        "suite_mnsp_FanucFocas.ctl",
                                        "suite_mnsp_IEC61850.ctl",
                                        "suite_mnsp_MTConnect.ctl",
                                        "suite_mnsp_BACnet.ctl",
                                        "suite_mnsp_general.ctl");

const bool bHasFanucFocas = getPath(BIN_REL_PATH, "WCCOAfocas") == "" ? FALSE : TRUE;

//--------------------------------------------------------------------------------
/*!
  @brief Base class for testrunner which starts all testsuites
  @details This class sets up and starts all automated tests for MindSphere Connectivity project
*/
class TestRunner
{
  //------------------------------------------------------------------------------
  /**
    @brief Setup automatic test
    @return Error code
            value | description
            ------|------------
             0    | success
            -1    | rename of shield file failed
            -2    | delete localAddress config entry failed
            -3    | add localAddress config entry failed
            -4    | pmon did not start
            -5    | pmon is not running
            -6    | project did not start
            -7    | project is not running
  */
  public int setUp()
  {
    // Start pmon of project
    if(startPmon(PROJECT_NAME, FALSE))
    {
      tearDown();
      return -2;
    }

    // Wait for startup of pmon
    for(int i = 1; i <= MAX_COUNT; i++)
    {
      if(isPmonRunning())
      {
        break;
      }

      delay(0, 100);
    }

    // add debug flags for mnsp.ctl ctrl manager
    if(changeManagerOptions(PMON_INDEX_MNSP_SCRIPT, MAN_OPT_MNSP))
    {
      tearDown();
      return -6;
    }

    // Abort setup if pmon could not be started
    if(!isPmonRunning())
    {
      tearDown();
      return -3;
    }

    // Start project
    if(startProject())
    {
      tearDown();
      return -4;
    }

    // Wait for startup of project
    for(int i = 1; i <= MAX_COUNT; i++)
    {
      if(getProjectStatus() == PROJ_RUNNING_STATE_MONITORING)
      {
        break;
      }

      delay(1);
    }

    // Abort setup if project is not running
    if(getProjectStatus() != PROJ_RUNNING_STATE_MONITORING)
    {
      tearDown();
      return -5;
    }
    //deactivate MQTT device connection
    setMqttConnectionActive(FALSE);
    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Start testsuite for mnsp.ctl
    @return Error code
            value | description
            ------|------------
             0    | success
            -1    | testsuite could not be started
  */
  public int startTest(const string sKey)
  {
    int iErr;

    int iPosFanucFocas = dynContains(dsTestSuites, "suite_mnsp_FanucFocas.ctl");
    if (!bHasFanucFocas && iPosFanucFocas > 0)
    {
      dynRemove(dsTestSuites, iPosFanucFocas);
    }


    if(sKey == KEY_START_ALL_TESTSUITES)
    {
      iErr = startAllTestSuites();
    }
    else if (dsTestSuites.contains(sKey))
    {
      iErr = startTestSuite(sKey);
    }
    else
    {
      iErr = -1;
    }

    return iErr;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Start testsuite for mnsp.ctl
    @return Error code
            value | description
            ------|------------
             0    | success
            -1    | testsuite could not be started
  */
  public int startTestSuite(const string sTestSuite)
  {
    int iErr;
    string sStdOut, sStdErr;
    string sCmd = makeNativePath(WINCCOA_BIN_PATH) + getComponentName(CTRL_COMPONENT) + " -proj " + PROJECT_NAME + " " + "tests/" + sTestSuite;

    DebugTN(__FUNCTION__, sCmd);

    iErr = system(sCmd, sStdOut, sStdErr);
    DebugTN(__FUNCTION__, iErr, sStdOut, sStdErr);

    return iErr;
  }

  //------------------------------------------------------------------------------
  /**
    @brief
    @return Error code
            value | description
            ------|------------
             0    | success
            -1    | testsuite could not be started
  */
  public int startAllTestSuites()
  {
    for(int i = 0; i < dsTestSuites.count(); i++)
    {
      int iErr;

      iErr = startTestSuite(dsTestSuites.at(i));
      if(iErr)
      {
        return iErr;
      }
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Stop project and teardown testrunner
    @return Error code
            value | description
            ------|------------
             0    | success
            -1    | project could not be stopped
  */
  public int tearDown()
  {
//    setMqttConnectionActive(TRUE);
    return stopPmon(PROJECT_NAME);
  }

  //------------------------------------------------------------------------------
  /**
    @brief de-/activate MQTT device connection
    @return Error code
            value | description
            ------|------------
             0    | success
            -1    | project could not be stopped
  */
  public void setMqttConnectionActive(bool bActive)
  {
    dpSetWait("_MindsphereMQTT.Config.EstablishmentMode", (int) bActive);
  }

  //------------------------------------------------------------------------------
  /**
  */
  public void createResultDir()
  {
    rmdir(PROJ_PATH + DATA_REL_PATH + "oaTest/results");
    mkdir(PROJ_PATH + DATA_REL_PATH);
    mkdir(PROJ_PATH + DATA_REL_PATH + "oaTest");
    mkdir(PROJ_PATH + DATA_REL_PATH + "oaTest/results");
  }

  //------------------------------------------------------------------------------
  /**
    @brief Create a fullResult.json file
    @return Error code
            value | description
            ------|------------
             0    | success
            -1    | test has been aborted
  */
  public int createResultFile()
  {
    return fclose(fopen(PROJ_PATH + "fullResult.json", "wb+"));
  }

};


//--------------------------------------------------------------------------------
main(const string &sKey)
{
  int iErr;
  TestRunner tstRun = TestRunner();

  DebugTN("Testrunner started...");

  tstRun.createResultDir();

  iErr = tstRun.createResultFile();
  if(iErr != 0)
  {
    DebugTN("Error (" + iErr + ") in creating result file !!!");
    exit(1);
  }

  iErr = tstRun.setUp();
  if(iErr != 0)
  {
    DebugTN("Error (" + iErr + ") in setup of testrun !!!");
    exit(1);
  }

  iErr = tstRun.startTest(sKey);
  if(iErr != 0)
  {
    DebugTN("Error (" + iErr + ") in run of testsuite(s) (" + sKey + ") !!!");
    exit(1);
  }

  iErr = tstRun.tearDown();
  if(iErr != 0)
  {
    DebugTN("Error (" + iErr + ") in teardown of test !!!");
    exit(1);
  }

  DebugTN("Testrunner finished");
  exit(0);
}
