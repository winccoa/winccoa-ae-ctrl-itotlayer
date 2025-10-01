// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
 * @file scripts/EB_Package_MTConnect/Service.ctl
 * @author Schiefer Martin
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "EB_Package_MTConnect/MTClientLib"
// #uses "EB_Package_MTConnect/MTConnectCommon"
// #uses "EB_Package_MTConnect/MTConnectDeviceList"
#uses "EB_Package_Base/EB_Api_TagHandling"
//--------------------------------------------------------------------------------
// variables and constants
// shared_ptr<MTConnectCommon> g_spMTConnectCommon;          //!< pointer to the common obj
// shared_ptr<MTConnectDeviceList> g_spMTConnectDeviceList;  //!< pointer to the device list
dyn_mapping g_dmConnected;                                //!< list of connected queries

dyn_string g_dsUrl;                                       //!< list of urls
dyn_int g_diPollRate;                                  //!< list of pollrates
dyn_time g_dtLastUpdate;                                  //!< list of last updates
dyn_string g_dsLastInstanceId;                            //!< list of last instance ids
dyn_string g_dsDeviceDP;
dyn_string g_dsDescription;                               //!< list of descriptions
dyn_anytype g_daCurrentDevice;                            //!< list of current devices
dyn_string g_dsConnectionDpe;                             //!< list of connection dpes
dyn_string g_dsDeviceId;                                  //!< list of device ids
bool bConfigurationChanging = FALSE;

const dyn_int diPossiblePollrates = makeDynInt(5, 10, 15, 30, 60, 300, 1800);
const dyn_string dsPossiblePollrates = makeDynString("MTCPollSec5", "MTCPollSec10", "MTCPollSec15", "MTCPollSec30", "MTCPollSec60", "MTCPollMin5", "MTCPollMin30");

const string MTCONNECT_CONFIG = "_MTDevices";     //!< Driver connection dptype

//--------------------------------------------------------------------------------
/**
 * @brief This is main rutine for polling the MTConnect devices and coping the values to the tags.
 */
void main()
{

//   g_spMTConnectCommon = MTConnectCommon::createCommonPointer();
  dpQueryConnectSingle("configChangedCB", TRUE, "", "SELECT '_online.._value' FROM 'EB_MTConnect.DeviceList'", 1000);

  dpConnect("preparePollDevices", TRUE, MTCONNECT_CONFIG + ".PollRate");

  // pre-defined poll rates
  timedFunc("PollSec5", "MTCPollSec5");
  timedFunc("PollSec10", "MTCPollSec10");
  timedFunc("PollSec15", "MTCPollSec15");
  timedFunc("PollSec30", "MTCPollSec30");
  timedFunc("PollSec60", "MTCPollSec60");
  timedFunc("PollMin5", "MTCPollMin5");
  timedFunc("PollMin30", "MTCPollMin30");
}

//--------------------------------------------------------------------------------
/**
 * @brief This is the callback function which is executed when the configuration changed.
 * @param sUserDate unused parameter
 * @param sConfig The json string with the configuration
 */
void configChangedCB(const string &sUserDate, const dyn_dyn_anytype &ddaConfig)
{
  bConfigurationChanging = TRUE;
  //DebugTN(__FUNCTION__);
  disconnectNodes();
//   dyn_string dsConnectedNodes;
//   dyn_string dsConnectedAddresses;
//
//
//   g_spMTConnectDeviceList = new MTConnectDeviceList(g_spMTConnectCommon);
//   g_spMTConnectDeviceList.load(sConfig);

  string sConfig = ddaConfig[dynlen(ddaConfig)][2]; //use last configuration

  dynClear(g_dsDeviceId);

  dyn_mapping dmDeviceTagList = jsonDecode(sConfig);

  for (int i = 1; i <= dynlen(dmDeviceTagList); i++)
  {
    for (int j = dynlen(dmDeviceTagList[i]["TagList"]); j > 0; j--)
    {
//       shared_ptr<MTConnectTag> spMTConnectTag = spMTConnectDevice.getTag(j);
      string sQuery = "SELECT '_original.._value', '_original.._stime', '_original.._aut_inv' FROM '" + dmDeviceTagList[i]["TagList"][j]["Address"] + "'";
      mapping mConnected = makeMapping("WorkFunction", "calcCB", "Userdata", dmDeviceTagList[i]["TagList"][j]["NodeId"], "Query", sQuery);
      dynAppend(g_dmConnected, mConnected);
    }
    dynAppend(g_dsDeviceId, dmDeviceTagList[i]["NodeId"]);
  }
  connectNodes();
  bConfigurationChanging = FALSE;
}

//--------------------------------------------------------------------------------
/**
 * @brief Connects all callbacks for the MTConnect devices.
 */
void connectNodes()
{
  for (int i = 1; i <= dynlen(g_dmConnected); i++)
  {
    mapping mToConnected = g_dmConnected[i];

    dpQueryConnectAll(mToConnected["WorkFunction"], TRUE, mToConnected["Userdata"], mToConnected["Query"]);
    //DebugTN(__FUNCTION__, mToConnected["WorkFunction"], TRUE, mToConnected["Userdata"], mToConnected["Query"]);
  }
}

//--------------------------------------------------------------------------------
/**
 * @brief Disconnects all connected callbacks.
 */
void disconnectNodes()
{
  for (int i = 1; i <= dynlen(g_dmConnected); i++)
  {
    mapping mToDisconnected = g_dmConnected[i];

    dpQueryDisconnect(mToDisconnected["WorkFunction"], mToDisconnected["Userdata"]);
  }

  dynClear(g_dmConnected);
}

//--------------------------------------------------------------------------------
/**
 * @brief This is the callback function which is executed when a input value of a MTConnect tag is changed.
 * @param aUserdata anytpye which holds the tag information
 * @param ddaTab the table which holds the values
 */
void calcCB(const anytype &aUserdata, const dyn_dyn_anytype &ddaTab)
{
  for (int i = 2; i <= dynlen(ddaTab); i++) //iterate over the table
  {
    anytype aValue = ddaTab[i][2];
    time tTime = (time)ddaTab[i][3];
    bool bInvalid = (bool)ddaTab[i][4];
    string sDpe = EBTag::getDpForId(aUserdata);

    if (sDpe != "") //on moment of deleting, avoid failures
    {
      dpSetTimed(tTime, sDpe, aValue,
                        sDpe + ":_original.._aut_inv", bInvalid,
                        sDpe + ":_original.._userbit2", TRUE,       // mark value from device requested
                        sDpe + ":_original.._userbit3", !bInvalid); //mark value came from Device
    }
  }
}

//--------------------------------------------------------------------------------
/**
 * @brief This is the callback function for the timed function
 * @param dp the name of the data point
 * @param before the time of previous call
 * @param now the time of current call
 * @param call is set to TRUE when the work function is called the last time.
 */
void PollSec5(string dp, time before, time now, bool call)
{
  string dpe = dpSubStr(dp, DPSUB_DP);                          // remove system name
  PollDevices(dpe);
}

//--------------------------------------------------------------------------------
/**
 * @brief This is the callback function for the timed function
 * @param dp the name of the data point
 * @param before the time of previous call
 * @param now the time of current call
 * @param call is set to TRUE when the work function is called the last time.
 */
void PollSec10(string dp, time before, time now, bool call)
{
  string dpe = dpSubStr(dp, DPSUB_DP);                          // remove system name
  PollDevices(dpe);
}

//--------------------------------------------------------------------------------
/**
 * @brief This is the callback function for the timed function
 * @param dp the name of the data point
 * @param before the time of previous call
 * @param now the time of current call
 * @param call is set to TRUE when the work function is called the last time.
 */
void PollSec15(string dp, time before, time now, bool call)
{
  string dpe = dpSubStr(dp, DPSUB_DP);                          // remove system name
  PollDevices(dpe);
}

//--------------------------------------------------------------------------------
/**
 * @brief This is the callback function for the timed function
 * @param dp the name of the data point
 * @param before the time of previous call
 * @param now the time of current call
 * @param call is set to TRUE when the work function is called the last time.
 */
void PollSec30(string dp, time before, time now, bool call)
{
  string dpe = dpSubStr(dp, DPSUB_DP);                          // remove system name
  PollDevices(dpe);
}

//--------------------------------------------------------------------------------
/**
 * @brief This is the callback function for the timed function
 * @param dp the name of the data point
 * @param before the time of previous call
 * @param now the time of current call
 * @param call is set to TRUE when the work function is called the last time.
 */
void PollSec60(string dp, time before, time now, bool call)
{
  string dpe = dpSubStr(dp, DPSUB_DP);                          // remove system name
  PollDevices(dpe);
}

//--------------------------------------------------------------------------------
/**
 * @brief This is the callback function for the timed function
 * @param dp the name of the data point
 * @param before the time of previous call
 * @param now the time of current call
 * @param call is set to TRUE when the work function is called the last time.
 */
void PollMin5(string dp, time before, time now, bool call)
{
  string dpe = dpSubStr(dp, DPSUB_DP);                          // remove system name
  PollDevices(dpe);
}

//--------------------------------------------------------------------------------
/**
 * @brief This is the callback function for the timed function
 * @param dp the name of the data point
 * @param before the time of previous call
 * @param now the time of current call
 * @param call is set to TRUE when the work function is called the last time.
 */
void PollMin30(string dp, time before, time now, bool call)
{
  string dpe = dpSubStr(dp, DPSUB_DP);                          // remove system name
  PollDevices(dpe);
}

//--------------------------------------------------------------------------------
/**
 * @brief Sets the globals to the correct values
 * @param dpe The name of the datapoint
 * @param polls the poll rate
 */
void preparePollDevices(string dpe, dyn_string polls)
{
  dyn_string dsUrl;
  dyn_string dsPollRate;
  dyn_time dtLastUpdate;
  dyn_string dsLastInstanceId;
  dyn_int diConnState;
  dyn_string dsDescription;


  synchronized(g_dsLastInstanceId)
  {
    //read in the current config of S7 plcs
    dpGet(MTCONNECT_CONFIG + ".URL", g_dsUrl,
          MTCONNECT_CONFIG + ".PollRate", dsPollRate,
          MTCONNECT_CONFIG + ".LastUpdate", g_dtLastUpdate,
          MTCONNECT_CONFIG + ".LastInstanceId", g_dsLastInstanceId,
          MTCONNECT_CONFIG + ".PolledDP", g_dsDeviceDP,
          MTCONNECT_CONFIG + ".Description", g_dsDescription,
          MTCONNECT_CONFIG + ".ConnectionDpe", g_dsConnectionDpe);


    //use equal or next faster poll rate
    for (int i=dynlen(dsPollRate); i>0; i--)                        // check all poll names for this one
    {
      for (int j = dynlen(diPossiblePollrates); j>0; j--)
      {
          //diPossiblePollrates = makeDynInt(5, 10, 15, 30, 60, 300, 1800);
        if((int)dsPollRate[i] >= diPossiblePollrates[j] || j==1) // real polling fast or equal to setting
        {
          g_diPollRate[i] = diPossiblePollrates[j];
          j = 0;
        }
      }
    }
    dynClear(g_daCurrentDevice);
    for (int i = 1; i <= dynlen(g_dsUrl); i++)
    {
      shared_ptr<MTClientLib> sp_currentDevice = new MTClientLib();
      dynAppend(g_daCurrentDevice, sp_currentDevice);
    }
  }
}

//--------------------------------------------------------------------------------
/**
 * @brief Polls the configured devices
 * @param sDpe The name of the datapoint
 */
void PollDevices(string sDpe)
{
  if (bConfigurationChanging)
  {
    return;
  }

  int i;
  string sStatus;
  strreplace(sDpe, "MTCPollSec", "");
  int iPollIntervall = (int) sDpe;

  synchronized(g_dsLastInstanceId)
  {
    for (i=dynlen(g_diPollRate); i>0; i--)                        // check all poll names for this one
    {
      if(g_diPollRate[i] == iPollIntervall && dynlen(g_dsDeviceId) >= i && dynlen(g_dsLastInstanceId) >= i) //found a poll group
      {
        string sInstance = g_dsLastInstanceId[i];
        shared_ptr<MTClientLib> sp_currentDevice = g_daCurrentDevice[i];
        sp_currentDevice.getCurrent(g_dsUrl[i], sStatus, sInstance, g_dsDeviceId[i], FALSE);

        if (g_dsLastInstanceId[i] != sInstance)
        {
          g_dsLastInstanceId[i] = sInstance;
          dpSet(MTCONNECT_CONFIG + ".LastInstanceId", g_dsLastInstanceId);     // Track latest instanceId so MTC_getCurrent can force a probe if it changes
        }

        int iConnState;
        if (sStatus == "")
        {
          iConnState = 1;
        }
        else
        {
          iConnState = 0;
        }
        g_dtLastUpdate[i] = getCurrentTime();

        dpSet(g_dsConnectionDpe[i], iConnState,
              MTCONNECT_CONFIG + ".LastUpdate", g_dtLastUpdate);
      }
    }
  }
}
