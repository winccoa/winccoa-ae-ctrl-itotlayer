// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author z0043ctz
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "ascii"
#uses "pmonInterface"

//--------------------------------------------------------------------------------
// Variables and Constants


//--------------------------------------------------------------------------------
/*!
  @brief Base class for sim. of browsing results
  @details This class is used to simulate browsing result without a real plc for MSC and IOT.
*/
class TstBrowsing
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  //------------------------------------------------------------------------------
  /**
    @brief Simulate browsing result of MTConnect driver
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | error importing ascii file
            -2    | read polled dp failed
            -3    | replacing polled dp failed
  */
  public int MTConnect()
  {
    int iErr;
    dyn_string dsPolledDps;

    // import ascii file with browse result
    iErr = asciiImport("browse_sim_mtconnect.dpl");
    if(iErr < 0)
    {
      return -1;
    }

    // replace polled dp with dp from ascii file
    iErr = dpGet("_MTDevices.PolledDP", dsPolledDps);
    if(iErr < 0)
    {
      return -2;
    }

    dsPolledDps.replaceAt(0, "9617890b-7526-9f6b-214f-0c860ace6485_1");

    iErr = dpSetWait("_MTDevices.PolledDP", dsPolledDps);
    if(iErr < 0)
    {
      return -3;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Simulate browsing result of IEC61850 driver
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | error importing ascii file
  */
  public int IEC61850()
  {
    int iErr;

    // import ascii file with browse result
    iErr = asciiImport("browse_sim_iec61850.dpl");
    if(iErr < 0)
    {
      return -1;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Stop S7plus driver as preparation for simulating browsing result of S7plus driver
    @param sDeviceDp Internal device datapoint of S7plus connection
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Internal device datapoint does not exist
            -2    | stop driver failed
            -3    | could not connect to internal device datapoint
  */
  public int S7plusPrepare(const string &sDeviceDp)
  {
    int iErr;

    if(!dpExists(sDeviceDp))
    {
      return -1;
    }

    delay(10);

    // Stop S7+ driver
    iErr = this.stopDrv(MAN_NAME_S7PLUS);
    if(iErr < 0)
    {
      return -2;
    }

    // connect to intern DP for browse simulation
    iErr = dpConnect("S7plusCB", FALSE, sDeviceDp + ".Browse.GetBranch");
    if(iErr < 0)
    {
      return -3;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Disconnect from S7plus driver connection datapoint and start driver again
    @param sDeviceDp Internal device datapoint of S7plus connection
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not disconnect from internal device datapoint
            -2    | start of driver failed
  */
  public int S7plusCleanUp(const string &sDeviceDp)
  {
    int iErr;

    // disconnect from intern DP after browse
    iErr = dpDisconnect("S7plusCB", sDeviceDp + ".Browse" + ".GetBranch");
    if(iErr < 0)
    {
      return -1;
    }

    // start S7+ driver again
    iErr = this.startDrv(MAN_NAME_S7PLUS);
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Stop opc ua driver as preparation for simulating browsing result of opc ua driver
    @param sDeviceDp Internal device datapoint of opc ua connection
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Internal device datapoint does not exist
            -2    | stop driver failed
            -3    | could not connect to internal device datapoint
  */
  public int OpcUaPrepare(const string &sDeviceDp)
  {
    int iErr;

    if(!dpExists(sDeviceDp))
    {
      return -1;
    }

    // Stop S7+ driver
     iErr = this.stopDrv(MAN_NAME_OPCUA);
     if(iErr < 0)
     {
       return -2;
     }

    // connect to intern DP for browse simulation
    iErr = dpConnect("OpcUaCB", FALSE, sDeviceDp + ".Browse.GetBranch");
    if(iErr < 0)
    {
      return -3;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Disconnect from opc ua driver connection datapoint and start driver again
    @param sDeviceDp Internal device datapoint of opc ua connection
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not disconnect from internal device datapoint
            -2    | start of driver failed
  */
  public int OpcUaCleanUp(const string &sDeviceDp)
  {
    int iErr;

    // disconnect from intern DP after browse
    iErr = dpDisconnect("OpcUaCB", sDeviceDp + ".Browse" + ".GetBranch");
    if(iErr < 0)
    {
      return -1;
    }

    // start S7+ driver again
    iErr = this.startDrv(MAN_NAME_OPCUA);
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Connect to BACnet driver as preparation for simulating browsing result of opc ua driver
    @param sDeviceDp Internal device datapoint of opc ua connection
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | Internal device datapoint does not exist
            -2    | stop driver failed
            -3    | could not connect to internal device datapoint
  */
  public int BACnetPrepare(const string &sDeviceDp)
  {
    int iErr;

    if(!dpExists(sDeviceDp))
    {
      return -1;
    }

    // connect to intern DP for browse simulation
    iErr = dpConnect("BACnetCB", FALSE, sDeviceDp + ".Browse.Objects.DeviceId");
    if(iErr < 0)
    {
      return -2;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Disconnect from opc ua driver connection datapoint and start driver again
    @param sDeviceDp Internal device datapoint of opc ua connection
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | could not disconnect from internal device datapoint
            -2    | start of driver failed
  */
  public int BACnetCleanUp(const string &sDeviceDp)
  {
    int iErr;

    // disconnect from intern DP after browse
    iErr = dpDisconnect("BACnetCB", sDeviceDp + ".Browse.Objects.DeviceId");
    if(iErr < 0)
    {
      return -1;
    }

    return 0;
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  //------------------------------------------------------------------------------
  /**
    @brief Callback for S7plus browsing simulation
    @param sDeviceDp Internal device datapoint of S7plus connection
    @param dsValues Contains browse request values
  */
  private void S7plusCB(string sDeviceDp, dyn_string dsValues)
  {
    int iErr;

    sDeviceDp = dpSubStr(sDeviceDp, DPSUB_DP);

    // import ascii file with browse result
    iErr = asciiImport("browse_sim_s7plus.dpl");
    if(iErr < 0)
    {
      return;
    }

    delay(0, 100);

    // set browsing done
    dpSetWait(sDeviceDp + ".Browse.RequestId:_original.._value", dsValues.first());
  }

  //------------------------------------------------------------------------------
  /**
    @brief Callback for opc ua client browsing simulation
    @param sDeviceDp Internal device datapoint of opc ua client connection
    @param dsValues Contains browse request values
  */
  private void OpcUaCB(string sDeviceDp, dyn_string dsValues)
  {
    int iErr;

    sDeviceDp = dpSubStr(sDeviceDp, DPSUB_DP);

    // import ascii file with browse result
    iErr = asciiImport("browse_sim_opcua.dpl");
    if(iErr < 0)
    {
      return;
    }

    delay(0, 100);

    // set browsing done
    dpSetWait(sDeviceDp + ".Browse.RequestId:_original.._value", dsValues.first());
  }

  //------------------------------------------------------------------------------
  /**
    @brief Callback for opc ua client browsing simulation
    @param sDeviceDp Internal device datapoint of opc ua client connection
    @param dsValues Contains browse request values
  */
  private void BACnetCB(string sDeviceDp, uint iDeviceId)
  {
    int iErr;

    sDeviceDp = dpSubStr(sDeviceDp, DPSUB_DP);

    // import ascii file with browse result
    iErr = asciiImport("browse_sim_bacnet.dpl");
    if(iErr < 0)
    {
      return;
    }

    delay(0, 100);

    // set browsing done
    dpSetWait(sDeviceDp + ".Browse.Objects.DeviceIdReturn:_original.._value", iDeviceId);
  }

  //------------------------------------------------------------------------------
  /**
    @brief Stop given driver
    @param sDriverName Name of driver to stop e.g. "WCCOAs7plus"
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | get index of driver failed
            -2    | change driver start option failed
            -3    | could not stop driver
  */
  private int stopDrv(const string &sDriverName)
  {
    int iErr;
    int iManIndex;

    // get pmon index of driver
    iManIndex = this.getIndexOfManager(sDriverName);
    if(iManIndex < 0)
    {
      return -1;
    }

    // change start mode to manual
    iErr = changeManagerOptions(iManIndex, makeMapping("StartMode", MAN_START_MODE_MANUAL));
    if(iErr < 0)
    {
      return -2;
    }

    // stop driver
    iErr = stopManager(iManIndex);
    if(iErr < 0)
    {
      return -3;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Start given driver
    @param sDriverName Name of driver to start e.g. "WCCOAs7plus"
    @return Error code
            value | description
            ------|------------
            0     | success
            -1    | get index of driver failed
            -2    | change driver start option failed
            -3    | could not start driver
  */
  private int startDrv(const string &sDriverName)
  {
    int iErr = 0;
    int iManIndex = 0;

    // get pmon index of driver
    iManIndex = this.getIndexOfManager(sDriverName);
    if(iManIndex < 0)
    {
      return -1;
    }

    // change start mode to auto
    iErr = changeManagerOptions(iManIndex, makeMapping("StartMode", MAN_START_MODE_ALWAYS));
    if(iErr < 0)
    {
      return -2;
    }

    // start driver
    iErr = startManager(iManIndex);
    if(iErr < 0)
    {
      return -3;
    }

    return 0;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Get index of given manager
    @param sManager Manager e.g. "WCCOAs7"
    @return Error code
            value | description
            ------|------------
            >= 0  | index of given manager
            -1    | Manager not found
  */
  private int getIndexOfManager(const string &sManager)
  {
    int iErr;
    dyn_mapping dmManagerList;

    dmManagerList = getListOfManagerOptions();

    for(int i = 1; i <= dynlen(dmManagerList); i++)
    {
      if(dmManagerList[i]["Component"] == sManager)
      {
        return --i;
      }
    }

    return -1;
  }

  // manager name of s7plus driver
  private const string MAN_NAME_S7PLUS = "WCCOAs7plus";
  // manager name of opcua driver
  private const string MAN_NAME_OPCUA  = "WCCOAopcua";

};
