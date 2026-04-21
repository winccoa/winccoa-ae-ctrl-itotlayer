// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author z0043ctz
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants

// timed function internal datapointtype
const string TIMED_FUNC_DPT = "_TimedFunc";
// name of timed function datapoint which is created in this script
const string TIMED_FUNC_DP  = "_MSC_onBoard";
// intervall of timed function in seconds
const uint   TIMED_FUNC_INT = 60;

// MSC onboard datapoint
const string ONBOARD_DPE  = "_M_S.onb";
// MSC value written to onboard datapoint
const string ONBOARD_DATA = "{\"value\":1,\"state\":\"Onboarded\"}";

//--------------------------------------------------------------------------------
/**
*/
main()
{
  int iErr;

  DebugTN(__FILE__, "start of script");

  if(!dpExists(TIMED_FUNC_DP))
  {
    iErr = createTimedFuncDp();
    if(iErr)
    {
      DebugTN(__FILE__, "Creation of timed func dp returns error code <" + iErr + ">");
      exit(1);
    }
  }

  iErr = timedFunc("workFunc", TIMED_FUNC_DP);
  if(iErr)
  {
    DebugTN(__FILE__, "Start of timed function returns error code <" + iErr + ">");
    exit(2);
  }
}

//------------------------------------------------------------------------------
/**
@brief work function of timed function (writes MSC onboard state)
@param sDp name of the data point (not used)
@param tBefore Timestamp of previous call (not used)
@param tNow	Timestamp of current call (not used)
@return Error code
    value | description
    ------|------------
    0     | success
    -1    | failed to set MSC onboard datapoint
*/
void workFunc(string sDp, time tBefore, time tNow)
{
  int iErr;

  DebugTN(__FILE__, "Timed function trigger");

  iErr = dpSet(ONBOARD_DPE, ONBOARD_DATA);
  if(iErr)
  {
    DebugTN(__FILE__, "Set of onbord string to onboard DP <" + ONBOARD_DPE + "> returns error code <" + iErr + ">");
  }
}

//------------------------------------------------------------------------------
/**
@brief Creates a timed function datapoint for MSC onborad state
@return Error code
    value | description
    ------|------------
    0     | success
    -1    | Error occured
*/
int createTimedFuncDp()
{
  int iErr;

  iErr = dpCreate(TIMED_FUNC_DP, TIMED_FUNC_DPT);
  if(iErr)
  {
    return -1;
  }

  return dpSet(TIMED_FUNC_DP + ".interval", TIMED_FUNC_INT,
               TIMED_FUNC_DP + ".syncTime", -1);
}


