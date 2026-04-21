// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
 * @file scripts/libs/EB_Package_MTConnect/MTClientLib.ctl
 * @author Schiefer Martin
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "CtrlHTTP"
#uses "CtrlXml"
#uses "CtrlPv2Admin"

//--------------------------------------------------------------------------------
// variables and constants
global int g_MTClientLibThreadId;                         //!< threadId used for the client lib

global int g_ComponentLevel;
global int g_PrevComponentLevel;


//--------------------------------------------------------------------------------
/**
 *  @brief Handler for MTClientLib.
 *  @author Martin Schiefer
 */
class MTClientLib
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  //------------------------------------------------------------------------------
  /**
   * @brief gets the device dp
   * @return string the device dp
   */
  public string getDeviceDp()
  {
    return this.sDeviceDp;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the configuration of the MTConnect device
   * @details browse the destianation URL and create the needed datatype and datapoint for saving the device configuration.
   * @details Serves a state and the id of the device.
   * @param sDestUrl the destination URL
   * @param sStatus the state (empty string when no error happend or a detailed error)
   * @param sLastInstance the id of the device instance
   * @param sId the id of the device
   * @param bMakeCSV true if a the polling result should also be repesented in a csv format (default: FALSE)
   * @return int 0 when everything was ok
   */
  public int getConfig(const string &sDestUrl, string& sStatus, string& sLastInstance, string sId, bool bMakeCSV = FALSE)
  {
    int iErrStat = 0;
    sStatus = "";
    string sProbeUrl = sDestUrl + "/probe";
    string sXml;

    if (mappinglen(this.mConditionVals) == 0)
    {
      this.mConditionVals["Normal"] = 0;
      this.mConditionVals["Warning"] = 1;
      this.mConditionVals["Fault"] = 2;
      this.mConditionVals["Unavailable"] = 3;
    }

    if (this.bUseLiveData)
    {
      iErrStat = netGet(sProbeUrl, sXml);

      if (iErrStat != 0)
      {
        sStatus = "Failed to GET from " + sProbeUrl;

        return iErrStat;
      }
    }

    string sErrMsg;
    int iErrLine = 0, iErrColumn = 0, iDocNum = 0;
    if (this.bUseLiveData)
    {
      iDocNum = xmlDocumentFromString(sXml, sErrMsg, iErrLine, iErrColumn);
    }
    else// Or for testing, we could read from a file as the source of some data:
    {
      //Not using live MTConnect data! - Reading from MTConnectDevices.xml
      iDocNum = xmlDocumentFromFile(getPath(DATA_REL_PATH) + "MTConnectDevices.xml", sErrMsg, iErrLine, iErrColumn);
    }

    if (iDocNum == -1)
    {
      sStatus = "Failed to parse received XML: " + sErrMsg + ". Line,Col=";

      if (this.bUseLiveData)
      {
        // For testing, save the received unparseable XML string
        // There is a handy fileToString, but why not stringToFile??
        file fOut = fopen(getPath(DATA_REL_PATH) + "MTConnectDevices_Bad.xml", "w");
        if (fOut)
        {
          fprintf(fOut, sXml);
          fclose(fOut);
        }
      }
      return -1;
    }

    if (this.bUseLiveData) // For testing, save the received XML
    {
      xmlDocumentToFile(iDocNum, getPath(DATA_REL_PATH) + "MTConnectDevices.xml");
    }

    // Now start parsing...
    int iID1, iID2;
    dyn_uint duNodes;

    iID1 = xmlFirstChild(iDocNum);  // Get the root node of the doc

    // Validate that this is the document-type we expected
    string sNodeName = xmlNodeName(iDocNum, iID1);

    // When we read from a file, the root node is the <?xml header - skip it
    if (sNodeName == "xml")
    {
      iID1 = xmlNextSibling(iDocNum, iID1);
      sNodeName = xmlNodeName(iDocNum, iID1);
    }

    if ((xmlNodeType(iDocNum, iID1) != XML_ELEMENT_NODE)
      ||(xmlNodeName(iDocNum, iID1) != "MTConnectDevices"))
    {
      sStatus = "Not a valid MTConnectDevices document! "+ sNodeName;
      return -2;
    }

    // Testing: parse and display every node in the document
    this.printNodes(iDocNum, iID1, 0);
    // TURN THIS OFF!!

    synchronized(mDeviceInfo)
    {
      mappingClear(this.mDeviceInfo);
    }
    this.sInstanceId = "";

    this.parseDeviceNodes(iDocNum, iID1, sId);
    this.publishLatestDevice(sId);          // Create DPTs & DPs

    sLastInstance = this.sInstanceId;

    // If we're making a CSV, walk the XML again and append rows to our dyn_string of CSV data
    if (bMakeCSV)
    {
      this.sLatestDevice = "";
      this.sMasterDeviceUuid = "";
      this.sMasterDeviceName = "";
      synchronized(mDeviceInfo)
      {
        mappingClear(this.mDeviceInfo);
      }
      dynClear(this.dsCSVData);
      this.parseDeviceNodesToCSV(iDocNum, iID1);  // Recurse till done
      this.writeCollectedDataToDP();
    }

    xmlCloseDocument(iDocNum);

    return iErrStat;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the state of the MTConnect device
   * @details browse the destianation URL and writes the values to the device configuration.
   * @details Serves a state and the id of the device.
   * @param sDestUrl the destination URL
   * @param sStatus the state (empty string when no error happend or a detailed error)
   * @param sLastInstance the id of the device instance
   * @param sId the id of the device
   * @param bMakeCSV true if a the polling result should also be repesented in a csv format (default: FALSE)
   * @return int 0 when everything was ok
   */
  public int getCurrent(const string &sDestUrl, string& sStatus, string& sLastInstance, string sId, bool bMakeCSV = FALSE)
  {
    DebugFTN("MTClient", " getCurrent(" + sDestUrl + ")");

    bool bNeedProbe = FALSE;
    int iErrStat = 0;
    sStatus = "";
    string sCurrentUrl = sDestUrl + "/current";
    string sXml;

    if (this.bUseLiveData)
    {
      iErrStat = netGet(sCurrentUrl, sXml);

      if (iErrStat != 0)
      {
        sStatus = "Failed to GET from " + sCurrentUrl;

        return iErrStat;
      }
    }

    string sErrMsg;
    int iErrLine = 0, iErrColumn = 0, iDocNum = 0;

    if (this.bUseLiveData)
    {
      iDocNum = xmlDocumentFromString(sXml, sErrMsg, iErrLine, iErrColumn);
    }
    else// Or for testing, we could read from a file as the source of some data:
    {
      //Not using live MTConnect data! - Reading from MTConnectStreams.xml
      iDocNum = xmlDocumentFromFile(getPath(DATA_REL_PATH) + "MTConnectStreams.xml", sErrMsg, iErrLine, iErrColumn);
    }

    if (iDocNum == -1)
    {
      sStatus = "Failed to parse received XML: " + sErrMsg;

      // For testing, save the received unparseable XML string
      // There is a handy fileToString, but why not stringToFile??
      file fOut = fopen(getPath(DATA_REL_PATH) + "MTConnectStreams_Bad.xml");
      if (fOut)
      {
        fprintf(fOut, sXml);
        fclose(fOut);
      }
      return -1;
    }

    if (this.bUseLiveData) // For testing, save the received XML
    {
      xmlDocumentToFile(iDocNum, getPath(DATA_REL_PATH) + "MTConnectStreams.xml");
    }

    // Now start parsing...

    int iID1;

    iID1 = xmlFirstChild(iDocNum);  // Get the root node of the doc

    // Validate that this is the document-type we expected
    string sNodeName = xmlNodeName(iDocNum, iID1);

    // When we read from a file, the root node is the <?xml header - skip it
    if (sNodeName == "xml")
    {
      iID1 = xmlNextSibling(iDocNum, iID1);
      sNodeName = xmlNodeName(iDocNum, iID1);
    }

    if ((xmlNodeType(iDocNum, iID1) != XML_ELEMENT_NODE)
      ||(xmlNodeName(iDocNum, iID1) != "MTConnectStreams"))
    {
      sStatus = "Not a valid MTConnectStreams document! "+ sNodeName;
      return -2;
    }

  // Testing Only: parse and display every node in the document
  //  this.printNodes(iDocNum, iID1);

    // Walk the XML and post every value to our corresponding DPE
    this.sCategory = "";
    this.sDataItemId = "";
    this.sTimestamp = "";
    this.sInstanceId = "";
    this.parseStreamNodes(iDocNum, iID1, bNeedProbe, sId, sStatus);

    // If we got an instanceId and it doesn't match the latest one we were passed, force a Probe
    if ((this.sInstanceId != "") && (sLastInstance != "") && (this.sInstanceId != sLastInstance))
    {
  //  sLastInstance = this.sInstanceId;
      bNeedProbe = true;
    }

    // If we're making a CSV, walk the XML again and append rows to our dyn_string of CSV data
    if (bMakeCSV && !bNeedProbe)
    {
      this.sLatestDevice = "";
      dynClear(this.dsCSVData);
      this.sCsvDp = "";
      this.sInstanceId = "";
      this.sCreationTime = "";
      this.sNextSequence = "";
      this.sFirstSequence = "";
      this.sLastSequence = "";
      this.parseStreamNodesToCSV(iDocNum, iID1);  // Recurse till done
      this.writeCollectedDataToDP();
    }

    xmlCloseDocument(iDocNum);

    if (bNeedProbe)
    {
      DebugFTN("MTClient", "Some DPs were not found or instanceID changed - triggering a probe request.");
      getConfig(sDestUrl, sStatus, sLastInstance, sId, true);
    }

    return iErrStat;
  }


  //------------------------------------------------------------------------------
  /**
   * @brief gets the treadId
   * @return int the treadId
   */
  public synchronized int getMyThreadId()
  {
    return g_MTClientLibThreadId;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the treadId
   * @param iNewId the treadId
   */
  public synchronized void setMyThreadId(int iNewId)
  {
    g_MTClientLibThreadId = iNewId;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the destination URL
   * @return string the destination URL
   */
  public string getDestUrl()
  {
    return this.sDestUrl;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief sets the destination URL
   * @param sDestUrl the destination URL
   */
  public void setDestUrl(const string &sDestUrl)
  {
    this.sDestUrl = sDestUrl;
  }









  //------------------------------------------------------------------------------
  /**
   * @brief starts a thead for polling the destinaion URL
   * @param iSec the pollRate in secounds
   */
  public void startTimedThread(int iSec)
  {
    stopTimedThread();

    int iId = 0;
    iId = getMyThreadId();
    if (iId > 0)
    {
      stopTimedThread();
    }
    iId = startThread("PollFunc", iSec);
    setMyThreadId(iId);
    DebugFTN("MTClient", "Started periodic updates at " + iSec + " seconds, threadId=", iId);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief stops a thead for polling the destinaion URL
   */
  public void stopTimedThread()
  {
    // Note: Rather than using stopThread, which will error if the thread was not created by "us",
    // we will just have the thread exit if a global variable is zero.
    int iId = getMyThreadId();
    setMyThreadId(0);
    if (iId != 0)
      delay(0,101);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief the poll function for polling the destination URL
   * @param iSec the pollRate in secounds
   */
  public void PollFunc(int iSec)
  {
    DebugFTN("MTClient", "PollFunc(" + iSec + "): starting, myThreadId=" + getMyThreadId());

    string sStatus;
    string sUrl = getDestUrl();

    while (getMyThreadId() != 0)
    {
      DebugFTN("MTClient", "polling...");
      getCurrent(sUrl, sStatus, this.sInstanceId);

      // we could just delay for sec seconds, but we want to detect shutdown quicker than that
      for (int totSec = 0; totSec < sec; totSec++)
      {
        for (int ms = 0; ms < 1000; ms += 100)
        {
          if (getMyThreadId() == 0)
          {
            break;
          }
          delay(0, 100);
        }
      }
    }
    DebugFTN("MTClient", "PollFunc(): ending");
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  string sDestUrl = "http://mtconnect.mazakcorp.com:5609";

  mapping mConditionVals; //g_mConditionVals
  bool bUseLiveData = TRUE; //bUseLiveData
  bool bSaveLiveData = FALSE;
  bool bPutHeadersOnCsv = FALSE; // Helps with testing - but apparently LM doesn't want them

  // Temp storage for parsed device data
  string sLatestDevice = "";
  mapping mDeviceInfo;
  dyn_mapping dmEvents, dmConditions, dmSamples;

  // and for parsed stream data
  string sCategory = "";
  string sDataItemId = "";
  string sTimestamp = "";

  // for collecting Current CSV data
  dyn_string dsCSVData;
  string sCsvDp;
  string sInstanceId = "";
  string sCreationTime = "";
  string sNextSequence = "";
  string sFirstSequence = "";
  string sLastSequence = "";
  string sSequence = "";

  // for collecting Probe CSV metadata
  int iComponentLevel = 0;
  int iPrevComponentLevel = 0;
  string sMasterDeviceName = "";
  string sMasterDeviceUuid = "";
  int iNumDevCompositions = 0;
  int iNumComponentCompositions = 0;

  string sDeviceDp = "";


  //------------------------------------------------------------------------------
  /**
   * @brief prints the nodes for debuging porpose
   * @param uDocNum the document number of the xml document
   * @param iNode the node
   * @param iLevel the level
   */
  private int printNodes(uint uDocNum, int iNode, int iLevel)
  {
    if ( iNode != -1 )
    {
      string sName;

      if ( xmlNodeType(uDocNum, iNode) == XML_TEXT_NODE )
      {
        DebugFTN("MTClient", "L="+iLevel+", value:", xmlNodeValue(uDocNum, iNode));
      }

      else if ( xmlNodeType(uDocNum, iNode) == XML_ELEMENT_NODE )
      {
        sName = xmlNodeName(uDocNum, iNode);
        if (sName == "Components")
        {
          iPrevComponentLevel = iComponentLevel;
          ++iComponentLevel;
          DebugFTN("MTClient", "++CL="+iComponentLevel);
        }
        DebugFTN("MTClient", "L="+iLevel+", CL="+iComponentLevel+", ", xmlNodeName(uDocNum, iNode), xmlElementAttributes(uDocNum, iNode) );
      }

      // recurse into child nodes if any
      int iRet = this.printNodes(uDocNum, xmlFirstChild(uDocNum, iNode), iLevel+1);
      DebugFTN("MTClient", "ret from child "+ sName + ", ret="+iRet+", CL="+iComponentLevel+", PCL="+iPrevComponentLevel);
      if ((iRet != -1) && (iComponentLevel > iPrevComponentLevel) && (sName == "Components"))
      {
        iComponentLevel = iPrevComponentLevel;
        DebugFTN("MTClient", "--CL="+iComponentLevel);
        if (iPrevComponentLevel > 0)
        {
          --iPrevComponentLevel;
        }
      }

      // recurse for sibling nodes if any
      this.printNodes(uDocNum, xmlNextSibling(uDocNum, iNode), iLevel);
    }
    return iNode;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the node name
   * @param uDocNum the document number of the xml document
   * @param iNode the node
   * @return string the node name
   */
  private string getNodeName(uint uDocNum, int iNode)
  {
    string sName = "";
    if (iNode != -1)
    {
      if ( xmlNodeType(uDocNum, iNode) == XML_ELEMENT_NODE )
      {
        sName = xmlNodeName(uDocNum, iNode);
      }
    }
    return sName;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief recursive fn to walk the received XML MTConnectDevices document (from a Probe request) and save data into our mappings
   * @param uDocNum the document number of the xml document
   * @param iNode the node
   * @param sId the id of the device
   */
  private void parseDeviceNodes(uint uDocNum, int iNode, string sId)
  {
    if ( iNode != -1 )
    {
      if ( xmlNodeType(uDocNum, iNode) == XML_ELEMENT_NODE )
      {
        string sNodeName = xmlNodeName(uDocNum, iNode);

        if (sNodeName == "Header")
        {
          mapping mDevAtts = xmlElementAttributes(uDocNum, iNode);
          if (mappingHasKey(mDevAtts, "instanceId"))
            this.sInstanceId = mDevAtts["instanceId"];
        }

        else if (sNodeName == "Device")
        {
          this.publishLatestDevice(sId);

          mapping mDevAtts = xmlElementAttributes(uDocNum, iNode);
          if (mappingHasKey(mDevAtts, "uuid"))
          {
            this.sLatestDevice = mDevAtts["uuid"];
          }

          this.mDeviceInfo["name"] = (mappingHasKey(mDevAtts, "name")) ? mDevAtts["name"] : "";
          this.mDeviceInfo["id"]   = (mappingHasKey(mDevAtts, "id"))   ? mDevAtts["id"] : "";
          this.mDeviceInfo["uuid"] = (mappingHasKey(mDevAtts, "uuid")) ? mDevAtts["uuid"] : "";
          this.mDeviceInfo["serialNumber"] = ""; // we'll get this in the next node

          // ToDo: We could save the value and the Description as well
        }
        else if (sNodeName == "Description")
        {
          mapping mDevAtts = xmlElementAttributes(uDocNum, iNode);
          if (mappingHasKey(mDevAtts, "serialNumber"))
          {
            this.mDeviceInfo["serialNumber"] = mDevAtts["serialNumber"];
          }
        }

        else if (sNodeName == "DataItem")
        {
          mapping mItemAtts = xmlElementAttributes(uDocNum, iNode);
          mapping mItem;
          string sDataCategory = (mappingHasKey(mItemAtts, "category")) ? mItemAtts["category"] : "";

          mItem["id"] = (mappingHasKey(mItemAtts, "id")) ? mItemAtts["id"] : "";
          mItem["name"] = (mappingHasKey(mItemAtts, "name")) ? mItemAtts["name"] : "";
          mItem["category"] = (mappingHasKey(mItemAtts, "category")) ? mItemAtts["category"] : "";
          mItem["type"] = (mappingHasKey(mItemAtts, "type")) ? mItemAtts["type"] : "";
          mItem["units"] = (mappingHasKey(mItemAtts, "units")) ? mItemAtts["units"] : "";

          if (sDataCategory == "SAMPLE")
          {
            dynAppend(this.dmSamples, mItem);
          }
          else if (sDataCategory == "CONDITION")
          {
            dynAppend(this.dmConditions, mItem);
          }
          else if (sDataCategory == "EVENT")
          {
            dynAppend(this.dmEvents, mItem);
          }
          else
          {
            DebugFTN("MTClient", " ignoring node " + mItem["name"] + " of category " + sDataCategory);
          }
        }

        xmlElementAttributes(uDocNum, iNode);  // a mapping with 0 or more items
      }

      else if ( xmlNodeType(uDocNum, iNode) == XML_TEXT_NODE )
      {
        DebugFTN("MTClient", "value:", xmlNodeValue(uDocNum, iNode));
      }

      // try recursing
      this.parseDeviceNodes(uDocNum, xmlFirstChild(uDocNum, iNode), sId);
      this.parseDeviceNodes(uDocNum, xmlNextSibling(uDocNum, iNode), sId);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief parses the device nodes to csv
   * @param uDocNum the document number of the xml document
   * @param iNode the node
   * @return the node
   */
  private int parseDeviceNodesToCSV(uint uDocNum, int iNode)
  {
    if ( iNode != -1 )
    {
      string sNodeName = "";
      if ( xmlNodeType(uDocNum, iNode) == XML_ELEMENT_NODE )
      {
        sNodeName = xmlNodeName(uDocNum, iNode);

        if (sNodeName == "Header")
        {
          mapping mDevAtts = xmlElementAttributes(uDocNum, iNode);
          if (mappingHasKey(mDevAtts, "instanceId"))
          {
            this.sInstanceId = mDevAtts["instanceId"];
          }

          if (mappingHasKey(mDevAtts, "creationTime"))
          {
            this.sCreationTime = mDevAtts["creationTime"];
            this.isoTimeToUTC(this.sCreationTime);
          }
        }

        else if (sNodeName == "Device")
        {
          this.writeCollectedDataToDP();                               // If there's data from a previous machine, write it now
          this.clearDevMaps();

          mapping mDevAtts = xmlElementAttributes(uDocNum, iNode);
          if (mappingHasKey(mDevAtts, "uuid"))
          {
            this.sLatestDevice = mDevAtts["uuid"];                 // This is the name of the [new] current machine
          }
          this.sCsvDp = "ProbeCSV_" + this.sLatestDevice;        // Name of DP to write this machine's CSV data to
          this.createDpForCSV("MTC_PROBE_CSV");                      // Create the DP if it didn't exist, else read it

          this.mDeviceInfo["DeviceName"] = (mappingHasKey(mDevAtts, "name")) ? mDevAtts["name"] : "";
          this.mDeviceInfo["DeviceId"]   = (mappingHasKey(mDevAtts, "id"))   ? mDevAtts["id"] : "";
          this.mDeviceInfo["DeviceUuid"] = (mappingHasKey(mDevAtts, "uuid")) ? mDevAtts["uuid"] : "";
          this.mDeviceInfo["DeviceSerialNumber"] = ""; // we'll get this in the next node

          if (strlen(this.sMasterDeviceUuid) == 0)
          {
            this.sMasterDeviceUuid = this.mDeviceInfo["DeviceUuid"];
          }
          if (strlen(this.sMasterDeviceName) == 0)
          {
            this.sMasterDeviceName = this.mDeviceInfo["DeviceName"];
          }

          // Find any and all Compositions within this Device which are not part of a Component,
          //  and add them to this.mDeviceInfo["DeviceComposition_#_name"]
          this.iNumDevCompositions = 0;
          this.getDeviceCompositions(uDocNum, iNode);
        }

        else if (sNodeName == "Description")
        {
          this.mDeviceInfo["DeviceDescription"] = xmlNodeValue(uDocNum, iNode);
          mapping mDevAtts = xmlElementAttributes(uDocNum, iNode);
          if (mappingHasKey(mDevAtts, "serialNumber"))
          {
            this.mDeviceInfo["DeviceSerialNumber"] = mDevAtts["serialNumber"];
          }
        }

        else if (sNodeName == "DataItem")
        {
          mapping mItemAtts = xmlElementAttributes(uDocNum, iNode);
          mapping mItem;

          this.mDeviceInfo["DataItemId"] = (mappingHasKey(mItemAtts, "id")) ? mItemAtts["id"] : "";
          this.mDeviceInfo["DataItemName"] = (mappingHasKey(mItemAtts, "name")) ? mItemAtts["name"] : "";
          this.mDeviceInfo["DataItemCategory"] = (mappingHasKey(mItemAtts, "category")) ? mItemAtts["category"] : "";
          this.mDeviceInfo["DataItemType"] = (mappingHasKey(mItemAtts, "type")) ? mItemAtts["type"] : "";
          this.mDeviceInfo["DataItemSubType"] = (mappingHasKey(mItemAtts, "subType")) ? mItemAtts["subType"] : "";
          this.mDeviceInfo["DataItemUnits"] = (mappingHasKey(mItemAtts, "units")) ? mItemAtts["units"] : "";
          this.mDeviceInfo["DataItemNativeUnits"] = (mappingHasKey(mItemAtts, "nativeUnits")) ? mItemAtts["nativeUnits"] : "";
          this.mDeviceInfo["DataItemCoordinateSystem"] = (mappingHasKey(mItemAtts, "coordinateSystem")) ? mItemAtts["coordinateSystem"] : "";
          this.mDeviceInfo["DataItemCompositionId"] = (mappingHasKey(mItemAtts, "compositionId")) ? mItemAtts["compositionId"] : "";
          this.mDeviceInfo["DataItemNativeScale"] = (mappingHasKey(mItemAtts, "nativeScale")) ? mItemAtts["nativeScale"] : "";

          dyn_string dsConstraints = this.getConstraints(uDocNum, iNode);
          this.mDeviceInfo["DataItemConstraint_1"] = (dynlen(dsConstraints) >= 1) ? dsConstraints[1] : "";
          this.mDeviceInfo["DataItemConstraint_2"] = (dynlen(dsConstraints) >= 2) ? dsConstraints[2] : "";
          this.mDeviceInfo["DataItemConstraint_3"] = (dynlen(dsConstraints) >= 3) ? dsConstraints[3] : "";
          this.mDeviceInfo["DataItemConstraint_4"] = (dynlen(dsConstraints) >= 4) ? dsConstraints[4] : "";
          this.mDeviceInfo["DataItemConstraint_5"] = (dynlen(dsConstraints) >= 5) ? dsConstraints[5] : "";
          this.mDeviceInfo["DataItemConstraint_6"] = (dynlen(dsConstraints) >= 6) ? dsConstraints[6] : "";

          this.appendCurrentProbeCSVRow();
        }

        else if (sNodeName == "Components")
        {
          g_PrevComponentLevel = g_ComponentLevel;
          ++g_ComponentLevel;
        }

        else if (sNodeName == "Composition")
        {
          ; //Elsewhere we parse these into Device-compositions or Component-compositions
        }

        // None of the above types.  If we have a current component-level, and the node has an id, save fields for the current component
        else
        {
          if (g_ComponentLevel > 0)
          {
            mapping mItemAtts = xmlElementAttributes(uDocNum, iNode);
            if (mappingHasKey(mItemAtts, "id"))
            {
              this.clearComponentInfo(g_ComponentLevel);  // Clear out any previous fields for this component-level
              string sPrefix;
              sprintf(sPrefix, "Component_%d_", g_ComponentLevel);
              this.mDeviceInfo[sPrefix+"Id"] = mItemAtts["id"];
              this.mDeviceInfo[sPrefix+"Type"] = sNodeName;
              this.mDeviceInfo[sPrefix+"Name"] = (mappingHasKey(mItemAtts, "name")) ? mItemAtts["name"] : "";
              this.mDeviceInfo[sPrefix+"NativeName"] = (mappingHasKey(mItemAtts, "nativeName")) ? mItemAtts["nativeName"] : "";
              this.mDeviceInfo[sPrefix+"Description"] = (mappingHasKey(mItemAtts, "description")) ? mItemAtts["description"] : "";
              this.mDeviceInfo[sPrefix+"Uuid"] = (mappingHasKey(mItemAtts, "uuid")) ? mItemAtts["uuid"] : "";

              // Find any and all Compositions for this Component and add them to Component_%d_Composition_# 1-6
              this.getComponentCompositions(uDocNum, iNode);
            }
          }
        }

      }

      // recurse into child nodes if any
      int iRet = this.parseDeviceNodesToCSV(uDocNum, xmlFirstChild(uDocNum, iNode));
      if ((iRet != -1) && (g_ComponentLevel > g_PrevComponentLevel) && (sNodeName == "Components"))
      {
        this.clearComponentInfo(g_ComponentLevel);
        g_ComponentLevel = g_PrevComponentLevel;
        if (g_PrevComponentLevel > 0)
        {
          --g_PrevComponentLevel;
        }
      }

      // recurse for sibling nodes if any
      this.parseDeviceNodesToCSV(uDocNum, xmlNextSibling(uDocNum, iNode));
    }
    return iNode;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the constrains for the device
   * @param uDocNum the document number of the xml document
   * @param iNode the node
   * @return dyn_string the list of constrains
   */
  private dyn_string getConstraints(uint uDocNum, int iNode)
  {
    dyn_string dsConstraints;
    iNode = xmlFirstChild(uDocNum, iNode);
    if ((iNode != -1) && (xmlNodeName(uDocNum, iNode) == "Constraints")) //ToDo: Don't require this to be first child
    {
      iNode = xmlFirstChild(uDocNum, iNode);
      while ((iNode != -1) && (xmlNodeName(uDocNum, iNode) == "Value")) //ToDo: Don't require this to be first child
      {
        int iChildNode=xmlFirstChild(uDocNum, iNode);
        if (iChildNode != -1)
        {
          if ( xmlNodeType(uDocNum, iChildNode) == XML_TEXT_NODE )
          {
            string sValue = xmlNodeValue(uDocNum, iChildNode);
            dynAppend(dsConstraints, sValue);
            if (dynlen(dsConstraints) >= 6)
            {
              break;
            }
          }
        }
        iNode = xmlNextSibling(uDocNum, iNode);
      }
    }
    return dsConstraints;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the compositions for the device
   * @param uDocNum the document number of the xml document
   * @param iNode the node
   */
  private void getDeviceCompositions(uint uDocNum, int iNode)
  {
    if (iNode == -1)
    {
      return;
    }

    string sName;

    iNode = xmlFirstChild(uDocNum, iNode);

    // Walk all the siblings at this level looking for <Compositions>
    while (iNode != -1)
    {
      sName = xmlNodeName(uDocNum, iNode);
      if (sName == "Compositions")
      {
        iNode = xmlFirstChild(uDocNum, iNode);
        // Walk all the siblings at this level looking for <Composition>
        while (iNode != -1)
        {
          sName = xmlNodeName(uDocNum, iNode);
          if (sName == "Composition")
          {
            mapping mDevAtts = xmlElementAttributes(uDocNum, iNode);
            if (mappingHasKey(mDevAtts, "uuid"))
            {
              if (++this.iNumDevCompositions > 6)
              {
                return;
              }
              string sPrefix;
              sprintf(sPrefix, "DeviceComposition_%d_", this.iNumDevCompositions);

              this.mDeviceInfo[sPrefix+"Name"] = (mappingHasKey(mDevAtts, "name")) ? mDevAtts["name"] : "";
              this.mDeviceInfo[sPrefix+"Type"] = (mappingHasKey(mDevAtts, "type")) ? mDevAtts["type"] : "";
              this.mDeviceInfo[sPrefix+"Id"]   = (mappingHasKey(mDevAtts, "id"))   ? mDevAtts["id"] : "";
              // Descripion is an element, not an attribute, and can have several attributes.
              // But the target schema only has one Description field.  We'll arbitrarily pick "model"
              int iNode2 = xmlFirstChild(uDocNum, iNode);
              if (iNode2 != -1)
              {
                sName = xmlNodeName(uDocNum, iNode2);
                if (sName == "Description")
                {
                  mapping mDescAtts = xmlElementAttributes(uDocNum, iNode2);
                  this.mDeviceInfo[sPrefix+"Description"] = (mappingHasKey(mDescAtts, "model")) ? mDescAtts["model"] : "";
                }
              }
            }
            iNode = xmlNextSibling(uDocNum, iNode);
          }
        }
        return;  //End of the Compositions - we're done
      }
      else
      {
        iNode = xmlNextSibling(uDocNum, iNode);
      }
    }
    return;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief gets the compositions for the device compoment
   * @param uDocNum the document number of the xml document
   * @param iNode the node
   */
  private void getComponentCompositions(uint uDocNum, int iNode)
  {
    if ((iNode == -1) || (g_ComponentLevel < 1) || (g_ComponentLevel > 6))
    {
      return;
    }

    string sName;

    iNode = xmlFirstChild(uDocNum, iNode);

    // Walk all the siblings at this level looking for <Compositions>
    while (iNode != -1)
    {
      sName = xmlNodeName(uDocNum, iNode);
      if (sName == "Compositions")
      {
        iNode = xmlFirstChild(uDocNum, iNode);
        // Walk all the siblings at this level looking for <Composition>
        while (iNode != -1)
        {
          sName = xmlNodeName(uDocNum, iNode);
          if (sName == "Composition")
          {
            mapping mDevAtts = xmlElementAttributes(uDocNum, iNode);
            if (mappingHasKey(mDevAtts, "uuid"))
            {
              if (++this.iNumComponentCompositions > 6)
              {
                return;
              }
              string sPrefix;
              sprintf(sPrefix, "Component_%d_Composition_%d_", g_ComponentLevel, this.iNumComponentCompositions);

              this.mDeviceInfo[sPrefix+"Name"] = (mappingHasKey(mDevAtts, "name")) ? mDevAtts["name"] : "";
              this.mDeviceInfo[sPrefix+"Type"] = (mappingHasKey(mDevAtts, "type")) ? mDevAtts["type"] : "";
              this.mDeviceInfo[sPrefix+"Id"]   = (mappingHasKey(mDevAtts, "id"))   ? mDevAtts["id"] : "";
              // Descripion is an element, not an attribute, and can have several attributes.
              // But the target schema only has one Description field.  We'll arbitrarily pick "model"
              int iNode2 = xmlFirstChild(uDocNum, iNode);
              if (iNode2 != -1)
              {
                sName = xmlNodeName(uDocNum, iNode2);
                if (sName == "Description")
                {
                  mapping mDescAtts = xmlElementAttributes(uDocNum, iNode2);
                  this.mDeviceInfo[sPrefix+"Description"] = (mappingHasKey(mDescAtts, "model")) ? mDescAtts["model"] : "";
                }
              }
            }
            iNode = xmlNextSibling(uDocNum, iNode);
          }
        }
        return;  //End of the Compositions - we're done
      }
      else
      {
        iNode = xmlNextSibling(uDocNum, iNode);
      }
    }
    return;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief clears the component information
   * @param iLevel the level
   */
  private void clearComponentInfo(int iLevel)
  {
    string sPrefix;
    sprintf(sPrefix, "Component_%d_", g_ComponentLevel);
    this.mDeviceInfo[sPrefix+"Id"] = "";
    this.mDeviceInfo[sPrefix+"Type"] = "";
    this.mDeviceInfo[sPrefix+"Name"] = "";
    this.mDeviceInfo[sPrefix+"NativeName"] = "";
    this.mDeviceInfo[sPrefix+"Description"] = "";
    this.mDeviceInfo[sPrefix+"Uuid"] = "";
    this.iNumComponentCompositions = 0;
    for (int i = 1; i <= 6; i++)
    {
      sprintf(sPrefix, "Component_%d_Composition_%d_", g_ComponentLevel, i);
      this.mDeviceInfo[sPrefix+"Id"] = "";
      this.mDeviceInfo[sPrefix+"Type"] = "";
      this.mDeviceInfo[sPrefix+"Name"] = "";
      this.mDeviceInfo[sPrefix+"Description"] = "";
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief clears the internal mappings
   */
  private void clearDevMaps()
  {
    synchronized(mDeviceInfo)
    {
      mappingClear(this.mDeviceInfo);
    }
    synchronized(dmSamples)
    {
      dynClear(this.dmEvents);
      dynClear(this.dmConditions);
      dynClear(this.dmSamples);
    }
    this.sLatestDevice = "";
  }

   //------------------------------------------------------------------------------
  /**
   * @brief creates the datapoint and datatype for the device and clears the internal mappings
   * @param sId the id of the device
   */
  private void publishLatestDevice(string sId)
  {
    if (this.sLatestDevice != "")
    {
      this.createDPTForDevice("_" + sId);
      this.createDPForDevice("_" + sId);
    }
    this.clearDevMaps();
  }

  //------------------------------------------------------------------------------
  /**
   * @brief creates the datatype for the device
   * @param sId the id of the device
   */
  private void createDPTForDevice(string sId)
  {
    DebugFTN("MTClient", "Device " + this.sLatestDevice + " has " + dynlen(this.dmSamples) + " samples, " + dynlen(this.dmConditions) + " conditions, " + dynlen(this.dmEvents) + " events.");
    string dptName = "MTC_" + this.sLatestDevice + sId;

    // Does this DPT already exist in OA?
    dyn_string dsDPTs = dpTypes(dptName);
    bool bExistsInOA = (dynlen(dsDPTs) > 0);

    dyn_dyn_string ddsElements;
    dyn_dyn_int ddiTypes;
    int iErr = 0;


    // To create a DPT takes two dyn-dyns, one of names and one of types,
    // with a row for each element of the structure for this type, and for each of those a dyn with the name or type at the
    // row for what I'll call the current "indentation level"

    // Top-level elements for the device
    ddsElements[1][1] = dptName;
    ddiTypes[1][1] = DPEL_STRUCT;

    ddsElements[2][2] = "name";
    ddiTypes[2][2] = DPEL_STRING;

    ddsElements[3][2] = "uuid";
    ddiTypes[3][2] = DPEL_STRING;

    ddsElements[4][2] = "id";
    ddiTypes[4][2] = DPEL_STRING;

    ddsElements[5][2] = "serialNumber";
    ddiTypes[5][2] = DPEL_STRING;

    int iOutIdx = 5;

    // Add the Samples
    ddsElements[++iOutIdx][2] = "Samples";
    ddiTypes[iOutIdx][2] = DPEL_STRUCT;
    synchronized(dmSamples)
    {
      for (int idx = 1; idx <= dynlen(this.dmSamples); idx++)
      {
        int iDpType = this.findDPType(this.dmSamples[idx]["category"], this.dmSamples[idx]["type"]);
        if (iDpType != 0)
        {
          ddsElements[++iOutIdx][3] = this.dmSamples[idx]["id"];
          ddiTypes[iOutIdx][3] = iDpType;
        }
      }

      // Add the Conditions
      ddsElements[++iOutIdx][2] = "Conditions";
      ddiTypes[iOutIdx][2] = DPEL_STRUCT;

      for (int idx = 1; idx <= dynlen(this.dmConditions); idx++)
      {
        int iDpType = this.findDPType(this.dmConditions[idx]["category"], this.dmConditions[idx]["type"]);
        if (iDpType != 0)
        {
          ddsElements[++iOutIdx][3] = this.dmConditions[idx]["id"];
          ddiTypes[iOutIdx][3] = iDpType;
        }
      }

      // Add the Events
      ddsElements[++iOutIdx][2] = "Events";
      ddiTypes[iOutIdx][2] = DPEL_STRUCT;

      for (int idx = 1; idx <= dynlen(this.dmEvents); idx++)
      {
        int iDpType = findDPType(this.dmEvents[idx]["category"], this.dmEvents[idx]["type"]);
        if (iDpType != 0)
        {
          ddsElements[++iOutIdx][3] = this.dmEvents[idx]["id"];
          ddiTypes[iOutIdx][3] = iDpType;
        }
      }

      // Create or update the DPT
      if (bExistsInOA)
      {
        dyn_dyn_string ddsCurrentElements;
        dyn_dyn_int ddiCurrentTypes;
        dpTypeGet(dptName, ddsCurrentElements, ddiCurrentTypes);
        if(ddsCurrentElements != ddsElements || ddiCurrentTypes != ddiTypes)
        {
          iErr = dpTypeChange(ddsElements, ddiTypes);
          if (iErr != 0)
          {
            DebugFTN("MTClient", "Failed to update DPType "+dptName + ", stat=" + iErr);
          }
          else
          {
            DebugFTN("MTClient", "Updated DPType " + dptName);
          }
        }
      }
      else
      {
        iErr = dpTypeCreate(ddsElements, ddiTypes);
        if (iErr != 0)
        {
          DebugFTN("MTClient", "dpTypeCreate failed for "+dptName, ddsElements, ddiTypes);
        }
        else
        {
          DebugFTN("MTClient", "Created DPType "+dptName);
        }
      }
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief creates the datapoint for the device
   * @param sId the id of the device
   */
  private void createDPForDevice(string sId)
  {
    DebugFTN("MTClient", "createDPForDevice()...", getStackTrace());
    string sDptName = "MTC_" + this.sLatestDevice + sId;
    string sDpName = "" + this.sLatestDevice + sId;
    this.sDeviceDp = sDpName;
    int iErr = dpCreate(sDpName, sDptName);
    if (iErr != 0)
    {
      DebugFTN("MTClient", "dpCreate failed for "+sDpName);
      return;
    }
    DebugFTN("MTClient", "Created DP "+sDpName, getStackTrace());

    // So now we have DPEs like:
    // MyDevice.name (,.uuid, .id, .serialNumber)
    // MyDevice.Samples.xpm (,...)
    // MyDevice.Conditions.servo (,...)
    // MyDevice.Events.functionalmode (,...)

    // For the Device info, we will just dpSet the values...
    synchronized(dmSamples)
    {
      for (int idx = 1; idx <= mappinglen(this.mDeviceInfo); idx++)
      {
        string sKey = mappingGetKey(this.mDeviceInfo, idx);
        string sDpeName = sDpName + "." + sKey;
        iErr = dpSet(sDpeName, this.mDeviceInfo[sKey]);
        if (iErr != 0)
        {
          DebugFTN("MTClient", "dpSet(" + sDpeName + ", this.mDeviceInfo[" + sKey + "]=" + this.mDeviceInfo[sKey] + ") failed, stat=" + iErr);
        }
      }

    // For the Samples, set the Units if available.  Set description from name if available, else from type

      for (int idx = 1; idx <= dynlen(this.dmSamples); idx++)
      {
        string sDpeName = sDpName + ".Samples." + this.dmSamples[idx]["id"];
        string sUnits = this.dmSamples[idx]["units"];
        if (strlen(sUnits) > 0)
        {
          dpSetUnit(sDpeName, sUnits);
        }

        string sName = this.dmSamples[idx]["name"];
        string sType = this.dmSamples[idx]["type"];
        string sDesc = (strlen(sName) > 0) ? sType + "/" + sName : sType;
        dpSetDescription(sDpeName, sDesc);
      }


    // Do the same for Events, but there are no units
      for (int idx = 1; idx <= dynlen(this.dmEvents); idx++)
      {
        string sDpeName = sDpName + ".Events." + this.dmEvents[idx]["id"];
        string sName = this.dmEvents[idx]["name"];
        string sType = this.dmEvents[idx]["type"];
        string sDesc = (strlen(sName) > 0) ? sName : sType;
        dpSetDescription(sDpeName, sDesc);
      }

    // Conditions also have no units, but we add alert-handling
      for (int idx = 1; idx <= dynlen(this.dmConditions); idx++)
      {
        string sDpeName = sDpName + ".Conditions." + this.dmConditions[idx]["id"];
        string sName = this.dmConditions[idx]["name"];
        string sType = this.dmConditions[idx]["type"];
        string sDesc = (strlen(sName) > 0) ? sName : sType;
        dpSetDescription(sDpeName, sDesc);

        // Set up alert-handling for this DPE...
        this.addCondAlert(sDpeName);
      }
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief parses the stream nodes for the device
   * @param uDocNum the document number of the xml document
   * @param iNode the node
   * @param bNeedProbe boolean that tells if a probe is needed
   * @param sId the id of the device
   * @param sStatus the state (empty string when no error happend or a detailed error)
   */
  private void parseStreamNodes(uint uDocNum, int iNode, bool &bNeedProbe, string sId, string &sStatus)
  {
    if ( iNode != -1 )
    {
      if ( xmlNodeType(uDocNum, iNode) == XML_ELEMENT_NODE )
      {
        string sNodeName = xmlNodeName(uDocNum, iNode);
        mapping mStreamAtts = xmlElementAttributes(uDocNum, iNode);

        if (sNodeName == "Header")
        {
          if (mappingHasKey(mStreamAtts, "instanceId"))
          {
            this.sInstanceId = mStreamAtts["instanceId"];
          }
        }

        else if (sNodeName == "DeviceStream")
        {
          if (mappingHasKey(mStreamAtts, "uuid"))
          {
            this.sLatestDevice = mStreamAtts["uuid"];  // This is the name of our DP

            // dpSet this each time so we can use its timestamp as time of last received poll
            string sDpeName = "" + this.sLatestDevice + "_" + sId + ".name";
            this.sDeviceDp = "" + this.sLatestDevice;
            int iErr = dpSet(sDpeName, this.sLatestDevice);
            if (iErr != 0)
            {
              bNeedProbe = true;
              DebugFTN("MTClient", "dpSet(" + sDpeName + ") failed, stat=" + iErr);
            }
          }
        }

        if (sNodeName == "Samples")
        {
          this.sCategory = "Samples";
          this.sDataItemId = "";
          this.sTimestamp = "";
        }
        else if (sNodeName == "Events")
        {
          this.sCategory = "Events";
          this.sDataItemId = "";
          this.sTimestamp = "";
        }
        else if (sNodeName == "Condition")
        {
          this.sCategory = "Conditions";
          this.sDataItemId = "";
          this.sTimestamp = "";
        }

        if (mappingHasKey(mStreamAtts, "dataItemId"))
        {
          this.sDataItemId = mStreamAtts["dataItemId"];
          if (mappingHasKey(mStreamAtts, "timestamp"))
          {
            this.sTimestamp = mStreamAtts["timestamp"];
          }
          else
          {
            this.sTimestamp = "";
          }

          strreplace(this.sTimestamp, "K", "Z");  // Saw some K suffixes!

          // Conditions are "special" - it's the node-name that holds the condition
          // These are strings, but there are only 4 possible values.
          // We map these to an Int 0,1,2,3 so we can set up alerts for them
          if (this.sCategory == "Conditions")
          {
            // Technically this may not be quite right - the spec says you could have
            // multiple conditions simultaneously.
            if (mappingHasKey(this.mConditionVals, sNodeName))
            {
              int iAlertVal = this.mConditionVals[sNodeName];
              string sDpeName =  "" + this.sLatestDevice + "_" + sId + "." + this.sCategory + "." + this.sDataItemId;
              if (dpExists(sDpeName))
              {
                time tTimestamp = scanTimeUTC(this.sTimestamp);
                int iErr = dpSetTimed(tTimestamp, sDpeName, iAlertVal);
                if (iErr != 0)
                {
                  bNeedProbe = TRUE;
                  DebugFTN("MTClient", "dpSetTimed(" + tTimestamp + ", " + sDpeName + ", " + iAlertVal + ") failed, stat=", iErr);
                }
                else
                {
                  DebugFTN("MTClient", "@1: dpSetTimed(" + tTimestamp + ", " + sDpeName + ", " + iAlertVal + ") stat=", iErr);
                }
              }
            }
          }
        }
      }

      else if ( xmlNodeType(uDocNum, iNode) == XML_TEXT_NODE )
      {
        anytype aValue = xmlNodeValue(uDocNum, iNode);
        DebugFTN("MTClient", "value:", aValue);
        if (this.sDataItemId == "avail")
        {
          if (aValue == "AVAILABLE")
          {
            sStatus = "";
          }
          else
          {
            sStatus = "UNAVAILABLE";
          }
        }
        string sDpeName =  "" + this.sLatestDevice + "_" + sId + "." + this.sCategory + "." + this.sDataItemId;
        if (dpExists(sDpeName))
        {
          if (strlen(this.sTimestamp) > 0)
          {
            time tTimestamp = scanTimeUTC(this.sTimestamp);
            int iErr = 0;
            if ((this.sCategory == "Samples") && (aValue == "UNAVAILABLE"))
            {
              iErr = dpSetTimed(tTimestamp, sDpeName+":_original.._aut_inv", 1);  // Set the invalid-bit
            }
            else
            {
              iErr = dpSetTimed(tTimestamp, sDpeName, aValue, sDpeName+":_original.._aut_inv", 0); // Set value and clear the invalid-bit
            }
            if (iErr != 0)
            {
              bNeedProbe = TRUE;
            }
            else
              DebugFTN("MTClient", "@2: dpSetTimed(" + tTimestamp + ", " + sDpeName + ", " + aValue + ") stat=", iErr);
          }
          else
          {
            int iErr = dpSet(sDpeName, aValue);
            if (iErr != 0)
            {
              bNeedProbe = TRUE;
              DebugFTN("MTClient", "dpSet(" + sDpeName + ", " + aValue + ") failed, stat=", iErr);
            }
            else
              DebugFTN("MTClient", "@3: dpSet(" + sDpeName + ", " + aValue + ") stat=", iErr);
          }
        }
        else
        {
          bNeedProbe = TRUE;
          DebugFTN("MTClient", "no such dpe: " + sDpeName);
        }
      }

      // Does this serve any purpose?
      xmlElementAttributes(uDocNum, iNode);

      // try recursing
      this.parseStreamNodes(uDocNum, xmlFirstChild(uDocNum, iNode), bNeedProbe, sId, sStatus);
      this.parseStreamNodes(uDocNum, xmlNextSibling(uDocNum, iNode), bNeedProbe, sId, sStatus);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief parses the stream nodes for the device to csv
   * @param uDocNum the document number of the xml document
   * @param iNode the node
   */
  private void parseStreamNodesToCSV(uint uDocNum, int iNode)
  {
    if (iNode != -1)
    {
      if (xmlNodeType(uDocNum, iNode) == XML_ELEMENT_NODE)
      {
        string sNodeName = xmlNodeName(uDocNum, iNode);
        mapping mStreamAtts = xmlElementAttributes(uDocNum, iNode);

        if (sNodeName == "Header")
        {
          if (mappingHasKey(mStreamAtts, "instanceId"))
          {
            this.sInstanceId = mStreamAtts["instanceId"];
          }

          if (mappingHasKey(mStreamAtts, "creationTime"))
          {
            this.sCreationTime = mStreamAtts["creationTime"];
            this.isoTimeToUTC(this.sCreationTime);
          }

          if (mappingHasKey(mStreamAtts, "firstSequence"))
          {
            this.sFirstSequence = mStreamAtts["firstSequence"];
          }

          if (mappingHasKey(mStreamAtts, "nextSequence"))
          {
            this.sNextSequence = mStreamAtts["nextSequence"];
          }

          if (mappingHasKey(mStreamAtts, "lastSequence"))
          {
            this.sLastSequence = mStreamAtts["lastSequence"];
          }
        }

        else if (sNodeName == "DeviceStream")
        {
          if (mappingHasKey(mStreamAtts, "uuid"))
          {
            this.writeCollectedDataToDP();                               // If there's data from a previous machine, write it now

            this.sLatestDevice = mStreamAtts["uuid"];                // This is the name of the [new] current machine
            this.sCsvDp = "CurrentCSV_" + this.sLatestDevice;        // Name of DP to write this machine's CSV data to
            this.createDpForCSV("MTC_CURRENT_CSV");                      // Create the DP if it didn't exist, else read it
          }
        }

        if (sNodeName == "Samples")
        {
          this.sCategory = "SAMPLE";
          this.sDataItemId = "";
          this.sTimestamp = "";
          this.sSequence = "";
        }
        else if (sNodeName == "Events")
        {
          this.sCategory = "EVENT";
          this.sDataItemId = "";
          this.sTimestamp = "";
          this.sSequence = "";
        }
        else if (sNodeName == "Condition")
        {
          this.sCategory = "CONDITION";
          this.sDataItemId = "";
          this.sTimestamp = "";
          this.sSequence = "";
        }

        if (mappingHasKey(mStreamAtts, "dataItemId"))
        {
          this.sDataItemId = mStreamAtts["dataItemId"];
          if (mappingHasKey(mStreamAtts, "timestamp"))
          {
            this.sTimestamp = mStreamAtts["timestamp"];
            this.isoTimeToUTC(this.sTimestamp);
          }
          else
          {
            this.sTimestamp = "";
          }

          if (mappingHasKey(mStreamAtts, "sequence"))
          {
            this.sSequence = mStreamAtts["sequence"];
          }
          else
          {
            this.sSequence = "";
          }

          // Conditions are "special" - it's the node-name that holds the condition
          // e.g. <Normal dataItemId="arf" ...
          // These are strings, but the standard says there are only 4 possible values: Normal, Warning, Fault, Unavailable
          // Regardless, this will be used as the Value for this CSV
          if (this.sCategory == "CONDITION")
          {
            this.appendCurrentCSVRow(strtoupper(sNodeName));
          }
        }
      }
      else if (xmlNodeType(uDocNum, iNode) == XML_TEXT_NODE)
      {
        this.appendCurrentCSVRow((string)xmlNodeValue(uDocNum, iNode));
      }

      // Does this serve any purpose?
      xmlElementAttributes(uDocNum, iNode);

      // try recursing
      this.parseStreamNodesToCSV(uDocNum, xmlFirstChild(uDocNum, iNode));
      this.parseStreamNodesToCSV(uDocNum, xmlNextSibling(uDocNum, iNode));
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief writes the polled data to the device datapoint
   */
  private void writeCollectedDataToDP()
  {
    if (dynlen(this.dsCSVData) > 0)
    {
      int iStat = dpSet(this.sCsvDp + ".", this.dsCSVData);
      if (iStat != 0)
      {
        DebugFTN("MTClient", "Error on dpSet for " + this.sCsvDp);
      }
      dynClear(this.dsCSVData);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief creates a datapoint for saving the device data into csv
   * @param sDPType the datoint type for the data point
   */
  private void createDpForCSV(const string &sDPType)
  {
    dynClear(this.dsCSVData);
    if (strlen(this.sCsvDp) == 0)
    {
      DebugFTN("MTClient", "createDpForCSV(): Error - DPName is empty for " + this.sLatestDevice);
      return;
    }
    if (dpExists(this.sCsvDp))
    {
      // Don't read existing data for a PROBE, only for CURRENT
      if (strpos(sDPType, "CURRENT") >= 0)
      {
        // Get any existing CSV data for this machine into this.dsCSVData, then we'll append to it
        int iStat = dpGet(this.sCsvDp + ".", this.dsCSVData);
        if (iStat != 0)
        {
          DebugFTN("MTClient", "createDpForCSV(): Error reading DP " + this.sCsvDp);
          return;
        }
      }
    }

    else// DP didn't exist - create it
    {
      int iErr = dpCreate(this.sCsvDp, sDPType);
      if (iErr != 0)
      {
        DebugFTN("MTClient", "dpCreate failed for "+this.sCsvDp);
        return;
      }
      DebugFTN("MTClient", "Created DP "+this.sCsvDp);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief appends the current device data to the csv
   * @param sValue the current device data
   */
  private void appendCurrentCSVRow(string& sValue)
  {
    if (this.bPutHeadersOnCsv && (dynlen(this.dsCSVData) == 0))
    {
      dynAppend(this.dsCSVData, "AgentInstanceId, DeviceUuid, DataItemId, HeaderCreationTime, HeaderNextSequence, HeaderFirstSequence, HeaderLastSequence, Category, Timestamp, Sequence, Value");
    }

    string CSVrow = this.sInstanceId + ", " +
                    this.sLatestDevice + ", " +
                    this.sDataItemId + ", " +
                    this.sCreationTime + ", " +
                    this.sNextSequence + ", " +
                    this.sFirstSequence + ", " +
                    this.sLastSequence + ", " +
                    this.sCategory + ", " +
                    this.sTimestamp + ", " +
                    this.sSequence + ", " +
                    sValue;
    dynAppend(this.dsCSVData, CSVrow);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief appends the probe device data to the csv
   * @param sValue the probe device data
   */
  private void appendCurrentProbeCSVRow()
  {
    string sItem;
    if (this.bPutHeadersOnCsv && (dynlen(this.dsCSVData) == 0))
    {
      string sHeader = "AgentInstanceId, DeviceUuid, DataItemId, HeaderCreationTime, MasterDeviceUuid, MasterDeviceName, DeviceId, ";
      sHeader += "DeviceName, DeviceNativeName, DeviceDescription, DeviceManufacturer, DeviceSerialNumber, DeviceStation, ";
      for (int i = 1; i <= 6; i++)
      {
        sprintf(sItem, "DeviceComposition_%d_Type, DeviceComposition_%d_Name, DeviceComposition_%d_Description, DeviceComposition_%d_Id, ", i,i,i,i);
        sHeader += sItem;
      }
      for (int i = 1; i <= 6; i++)
      {
        sprintf(sItem, "Component_%d_Id, Component_%d_Type, Component_%d_Name, Component_%d_NativeName, Component_%d_Description, Component_%d_Uuid, ", i,i,i,i,i,i);
        sHeader += sItem;
        for (int j = 1; j <= 6; j++)
        {
          sprintf(sItem, "Component_%d_Composition_%d_Type, Component_%d_Composition_%d_Name, Component_%d_Composition_%d_Description, Component_%d_Composition_%d_Id, ", i,j, i,j, i,j, i,j);
          sHeader += sItem;
        }
      }
      sHeader += "DataItemCategory, DataItemType, DataItemSubType, DataItemName, DataItemNativeName, DataItemCoordinateSystem, ";
      sHeader += "DataItemCompositionId, DataItemUnits, DataItemNativeUnits, DataItemNativeScale, ";
      sHeader += "DataItemConstraint_1, DataItemConstraint_2, DataItemConstraint_3, DataItemConstraint_4, DataItemConstraint_5, DataItemConstraint_6";
      dynAppend(this.dsCSVData, sHeader);
    }

    string sCsvRow = this.sInstanceId + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DeviceUuid")) ? this.mDeviceInfo["DeviceUuid"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemId")) ? this.mDeviceInfo["DataItemId"] : "") + ", ";
    sCsvRow += this.sCreationTime + ", ";
    sCsvRow += this.sMasterDeviceUuid + ", ";
    sCsvRow += this.sMasterDeviceName + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DeviceId")) ? this.mDeviceInfo["DeviceId"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DeviceName")) ? this.mDeviceInfo["DeviceName"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DeviceNativeName")) ? this.mDeviceInfo["DeviceNativeName"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DeviceDescription")) ? this.mDeviceInfo["DeviceDescription"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DeviceManufacturer")) ? this.mDeviceInfo["DeviceManufacturer"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DeviceSerialNumber")) ? this.mDeviceInfo["DeviceSerialNumber"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DeviceStation")) ? this.mDeviceInfo["DeviceStation"] : "") + ", ";

    for (int i = 1; i <= 6; i++)
    {
      sprintf(sItem, "DeviceComposition_%d_Type", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
      sprintf(sItem, "DeviceComposition_%d_Name", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
      sprintf(sItem, "DeviceComposition_%d_Description", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
      sprintf(sItem, "DeviceComposition_%d_Id", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
    }

    for (int i = 1; i <= 6; i++)
    {
      sprintf(sItem, "Component_%d_Id", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
      sprintf(sItem, "Component_%d_Type", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
      sprintf(sItem, "Component_%d_Name", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
      sprintf(sItem, "Component_%d_NativeName", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
      sprintf(sItem, "Component_%d_Description", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
      sprintf(sItem, "Component_%d_Uuid", i);
      sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";

      for (int j = 1; j <= 6; j++)
      {
        sprintf(sItem, "Component_%d_Composition_%d_Type", i,j);
        sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
        sprintf(sItem, "Component_%d_Composition_%d_Name", i,j);
        sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
        sprintf(sItem, "Component_%d_Composition_%d_Description", i,j);
        sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
        sprintf(sItem, "Component_%d_Composition_%d_Id", i,j);
        sCsvRow += ((mappingHasKey(this.mDeviceInfo, sItem)) ? this.mDeviceInfo[sItem] : "") + ", ";
      }
    }
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemCategory")) ? this.mDeviceInfo["DataItemCategory"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemType")) ? this.mDeviceInfo["DataItemType"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemSubType")) ? this.mDeviceInfo["DataItemSubType"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemName")) ? this.mDeviceInfo["DataItemName"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemNativeName")) ? this.mDeviceInfo["DataItemNativeName"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemCoordinateSystem")) ? this.mDeviceInfo["DataItemCoordinateSystem"] : "") + ", ";

    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemCompositionId")) ? this.mDeviceInfo["DataItemCompositionId"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemUnits")) ? this.mDeviceInfo["DataItemUnits"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemNativeUnits")) ? this.mDeviceInfo["DataItemNativeUnits"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemNativeScale")) ? this.mDeviceInfo["DataItemNativeScale"] : "") + ", ";

    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemConstraint_1")) ? this.mDeviceInfo["DataItemConstraint_1"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemConstraint_2")) ? this.mDeviceInfo["DataItemConstraint_2"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemConstraint_3")) ? this.mDeviceInfo["DataItemConstraint_3"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemConstraint_4")) ? this.mDeviceInfo["DataItemConstraint_4"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemConstraint_5")) ? this.mDeviceInfo["DataItemConstraint_5"] : "") + ", ";
    sCsvRow += ((mappingHasKey(this.mDeviceInfo, "DataItemConstraint_6")) ? this.mDeviceInfo["DataItemConstraint_6"] : "") + ", ";

    dynAppend(this.dsCSVData, sCsvRow);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief finds the correct data point type for category and type
   * @param sCategory the category
   * @param sType the type
   */
  private int findDPType(const string &sCategory, const string &sType)
  {
    int iDpType = 0;
    string sUpCat = strtoupper(sCategory);
    string sUpType = strtoupper(sType);
    if (sUpCat == "SAMPLE")
    {
      iDpType = DPEL_FLOAT;
    }
    else if (sUpCat == "CONDITION")
    {
      iDpType = DPEL_INT;  // Note: Conditions come in as a string, but we map the 4 possible values to 0,1,2,3
    }
    else if (sUpCat == "EVENT")
    {
      if (sUpType == "PART_COUNT")
      {
        iDpType = DPEL_INT;
      }
      else if (sUpType == "ROTARY_VELOCITY_OVERRIDE")
      {
        iDpType = DPEL_FLOAT;
      }
      else
      {
        iDpType = DPEL_STRING;
      }
    }
    return iDpType;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief adds a alert for a device condition to a dpe
   * @param sDpeName the dpe
   */
  private void addCondAlert(const string &sDpeName)
  {
    dyn_float dfLimits;
    dyn_string dsAlerttext;
    dyn_string dsAlertclass;
    dyn_errClass deErrors;

    dfLimits = makeDynString("*","2","3","4");
    dsAlerttext = makeDynString("", "Warning", "Fault", "Unavailable");
    dsAlertclass = makeDynString("", "warning.", "alert.", "information.");

    dpSetTimedWait(0, sDpeName + ":_alert_hdl.._type", DPCONFIG_ALERT_NONBINARYSIGNAL,

                  sDpeName + ":_alert_hdl.1._type", DPDETAIL_RANGETYPE_MATCH,
                  sDpeName + ":_alert_hdl.2._type", DPDETAIL_RANGETYPE_MATCH,
                  sDpeName + ":_alert_hdl.3._type", DPDETAIL_RANGETYPE_MATCH,
                  sDpeName + ":_alert_hdl.4._type", DPDETAIL_RANGETYPE_MATCH,

                  sDpeName + ":_alert_hdl.1._text", dsAlerttext[1],
                  sDpeName + ":_alert_hdl.2._text", dsAlerttext[2],
                  sDpeName + ":_alert_hdl.3._text", dsAlerttext[3],
                  sDpeName + ":_alert_hdl.4._text", dsAlerttext[4],

                  sDpeName + ":_alert_hdl.1._class", dsAlertclass[1],
                  sDpeName + ":_alert_hdl.2._class", dsAlertclass[2],
                  sDpeName + ":_alert_hdl.3._class", dsAlertclass[3],
                  sDpeName + ":_alert_hdl.4._class", dsAlertclass[4],

                  sDpeName + ":_alert_hdl.1._match", dfLimits[1],
                  sDpeName + ":_alert_hdl.2._match", dfLimits[2],
                  sDpeName + ":_alert_hdl.3._match", dfLimits[3],
                  sDpeName + ":_alert_hdl.4._match", dfLimits[4],

                  sDpeName + ":_alert_hdl.._active", TRUE);

    deErrors = getLastError();

    if (dynlen(deErrors) > 0)
    {
      DebugFTN("MTClient", "Error " + deErrors + " adding alert for " + sDpeName);
    }
  }

  //------------------------------------------------------------------------------
  /**
   * @brief this converts an iso dateTime string like "2018-03-09T16:33:29Z" to a more common UTC format like "2018-03-09 16:33:29"
   * @details milliseconds are optional and left in place
   * @param sTime the dateTime string
   */
  private void isoTimeToUTC(string& sTime)
  {
    strreplace(sTime, "T", " ");
    strreplace(sTime, "Z", "");
  }
};
