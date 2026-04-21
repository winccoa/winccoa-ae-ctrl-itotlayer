void main()
{
  //DebugTN("Hi");
  delay(5);
  checkingFordatapointsExisting();
  // Specify the path to your JSON file
  string jsonFilePath = getPath(DATA_REL_PATH, "ITOTFile.json");

  // Load the JSON file content into a string
  string jsonString;
  bool fileLoaded = fileToString(jsonFilePath, jsonString, "UTF8");

  if (!fileLoaded)
  {
    CreateStandardInfo(PRIO_SEVERE, 5, "Failed to load the IT OT file");
    return;
  }


  // Decode the JSON string into a mapping or other data structure
  mapping jsonData = jsonDecode(jsonString);

  if (jsonData.isEmpty())
  {
    CreateStandardInfo(PRIO_SEVERE, 5, "IT OT JSON decoding failed or resulted in empty data.");

    return;
  }

  // Now you can work with jsonData as needed

  // Handle Southbound
  if (!jsonData.contains("Southbound"))
  {
    CreateStandardInfo(PRIO_SEVERE, 4, "Key 'Southbound' not found in JSON.");
    //DebugTN("Error: Key 'Southbound' not found in JSON.");
    return;
  }


  // Access the "southbound" mapping
  dyn_anytype southboundinit = jsonData["Southbound"];
  ////DebugTN("southboundinit", southboundinit);
  string currentData = "";
  dpGet("MindSphereConnector.receiveData", currentData);

  dyn_anytype southbound = refineMysouthboundText(southboundinit);
  //DebugTN("southboundnew", southbound);
  string encodedValue = jsonEncode(southbound);


  //check there is a change of the southbound data or not
  bool isThereChange = checkforChange(southbound, currentData);

  if (isThereChange)
  {
    CreateStandardInfo(PRIO_INFO, 4, "The southbound data is the same as last time, No new Southbound tags will be created/edited");
    // DebugTN("The southbound data is the same as last time, No new Southbound tags will be created/edited")     ;
  }

  else
  {
    //DebugTN("The southbound data is NOT the same as last time")     ;

    // dpSet("MindSphereConnector.receiveData", "");
    // dpSet("MindSphereConnector.mapping_dataPointId", "");
    CreateStandardInfo(PRIO_INFO, 4, "Started 'Southbound' Handling");
    delay(3);

    dyn_string myPreviousSouthboundData =makeDynString();
    myPreviousSouthboundData=GetCurrentSouthboundDatapoints();
    delay(4); //this is added to give some time to query the current datapoints before changing it

    handleSouthBound(southbound);

    string receiveData, configuration;

    while (true)
    {
      dpGet("MindSphereConnector.receiveData", receiveData);
      dpGet("MindSphereConnector.configuration", configuration);

      if (configuration == receiveData && receiveData != "")
      {
        delay(6);//this is to be sure that the new data is implemented already, but this is a  double security step which is not needed because the logic is already done in the if condition
        dyn_string myCurrentSouthboundData = GetCurrentSouthboundDatapoints();
        CompareSouthboundAndReportTheDifference(myPreviousSouthboundData, myCurrentSouthboundData);


        break;
      }

      delay(3);
    }



  }

  // Handle Northbound
  if (!jsonData.contains("Publish"))
  {
    CreateStandardInfo(PRIO_SEVERE, 3, "Key 'Publish' not found in JSON.");


  }
  else
  {
    // Access the "northbound" mapping

    dyn_anytype northbound = jsonData["Publish"];
    CreateStandardInfo(PRIO_INFO, 3, "Started 'Publish' Handling");
    handleNorthBound(northbound);
  }

  if (!jsonData.contains("Subscribe"))
  {
    CreateStandardInfo(PRIO_WARNING, 2, "Key 'Subscribe' not found in JSON.");

  }

  // Access the "northbound" mapping
  else
  {
    CreateStandardInfo(PRIO_INFO, 2, "Started 'Subscribe' Handling");
    dyn_anytype northboundSubscribe = jsonData["Subscribe"];
    handleNorthBoundSubscribe(northboundSubscribe);
  }

//Checking Unified name space
///////////////////////////////////////////////////////////
  mapping unifiedNameSpace;
  // Access the "Unified Name Space" mapping
  ////DebugTN("jsonData.contains", jsonData.contains("UnifiedNameSpace"));


  if (jsonData.contains("UnifiedNameSpace"))
  {
    unifiedNameSpace = jsonData["UnifiedNameSpace"];
    //DebugTN("! unifiedNameSpace.isEmpty()", ! unifiedNameSpace.isEmpty());

    if (! unifiedNameSpace.isEmpty())
    {
      dyn_string allPaths = collectPaths(unifiedNameSpace, "");
      CreateUnifiedNameSpaceCNS(allPaths);
    }
    else
    {
      CreateStandardInfo(PRIO_WARNING, 5, "Key 'UnifiedNameSpace' is empty in jsonData.");
      // DebugTN("Warning: Key 'UnifiedNameSpace' is empty in jsonData.");
    }
  }
  else
  {
    CreateStandardInfo(PRIO_WARNING, 5, "Key 'UnifiedNameSpace' is not existing in the JSON data");
    // Handle the case where the key does not exist
    //DebugN("Key 'UnifiedNameSpace' does not exist in jsonData.");
  }

  //////////////////////////////////////////////////////////////
  if (jsonData.contains("Dashboard"))
  {
//Check for dashboard

    // Access the "Unified Name Space" mapping
    //DebugTN("jsonData.contains Dashboard", jsonData.contains("Dashboard"));
    CreateStandardInfo(PRIO_INFO, 1, "Key 'Dashboard' is found, starting creating the dashboards.");
    dyn_anytype allDashboards = jsonData["Dashboard"];


    DashboardInitialize(allDashboards);


  }
  else
  {
    CreateStandardInfo(PRIO_WARNING, 1, "Key 'Dashboard' does not exist in jsonData.");
    // Handle the case where the key does not exist
    DebugTN("Warning: Key 'Dashboard' does not exist in jsonData.");
  }

  dyn_string myDatapointsParameters;
  dpGet("System1:datapointConfigs.", myDatapointsParameters);
  handleDatapointsParameters(myDatapointsParameters);




//restart managers
  delay(10);
  dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, 3));
  dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, 2));
  dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, 1));


}

//this function is implemented to get the current southbound datapoints, for the purpose to check the new added datapoints afterwards
dyn_string GetCurrentSouthboundDatapoints()
{
  dyn_string allDPs;
  dyn_string boolDPs = dpNames("*", "EB_Bool");
  dyn_string stringDPs = dpNames("*", "EB_String");
  dyn_string intDPs = dpNames("*", "EB_Int");
  dyn_string floatDPs = dpNames("*", "EB_Float");

  dynAppend(allDPs, boolDPs);
  dynAppend(allDPs, stringDPs);
  dynAppend(allDPs, intDPs);
  dynAppend(allDPs, floatDPs);
  //DebugTN("allDPs", allDPs);
  // ---------- change to real names ----------
  dyn_string realNames = makeDynString();

  for (int i = 1; i <= dynlen(allDPs); i++)
  {
    if(GetRealElementName(allDPs[i])!="")
    realNames.append(GetRealElementName(allDPs[i]));
  }
DebugTN("realNames",realNames);
//DebugTN("realNames",realNames);
  return realNames;
}

//This function is to check the new data added after the south bound logic implemented
CompareSouthboundAndReportTheDifference(dyn_string myPreviousSouthboundData, dyn_string myCurrentSouthboundData)
{
  dyn_string addedElements = makeDynString();  // new added elements
  dyn_string removedElements = makeDynString(); //deleted elements

//DebugTN("myPreviousSouthboundData",myPreviousSouthboundData);
//DebugTN("myCurrentSouthboundData",myCurrentSouthboundData);
  // ---------- 1. discover the added elements ----------
  for (int i = 1; i <= dynlen(myCurrentSouthboundData); i++)
  {
    string curr = myCurrentSouthboundData[i];
    bool found = FALSE;

    for (int j = 1; j <= dynlen(myPreviousSouthboundData); j++)
    {
      if (curr == myPreviousSouthboundData[j])
      {
        found = TRUE;
        break;
      }
    }

    if (!found)
    {
      addedElements.append(curr);
    }
  }

  // ---------- 2. discover the deleted elements ----------
  for (int i = 1; i <= dynlen(myPreviousSouthboundData); i++)
  {
    string curr = myPreviousSouthboundData[i];
    bool found = FALSE;

    for (int j = 1; j <= dynlen(myCurrentSouthboundData); j++)
    {
      if (curr == myCurrentSouthboundData[j])
      {
        found = TRUE;
        break;
      }
    }

    if (!found)
    {
      removedElements.append(curr);
    }
  }


  if (dynlen(addedElements) != 0)
  {
    dyn_string UniqueAddedElements = MakeUnique(addedElements);

    dyn_string arrayDriversForAdded = GetMeTheArrayOfSouthBoundDrivers(UniqueAddedElements);

    if (dynlen(UniqueAddedElements) == dynlen(arrayDriversForAdded))
    {
      dyn_string FinalAddedDataLogs = CreateMeFinaltext(UniqueAddedElements, arrayDriversForAdded);
      // DebugTN("Removed Elements",UniqueAddedElements);
      string multiLineAdded =  MakeMyTextMultiLine(FinalAddedDataLogs);
      CreateStandardInfo(PRIO_INFO, 4, "The 'Added' SouthBound datapoints and the accociated drivers are:" + multiLineAdded);
    }
    else
    {
      // DebugTN("Removed Elements", UniqueAddedElements);
      string multiLineAddedWithoutDriver = MakeMyTextMultiLine(UniqueAddedElements);
      CreateStandardInfo(PRIO_INFO, 4, "The 'Added' SouthBound datapoints are: " + multiLineAddedWithoutDriver);
    }
  }

  if (dynlen(removedElements) != 0)
  {

    dyn_string UniqueRemovedElements = MakeUnique(removedElements);

    //dyn_string arrayDriversForAdded = GetMeTheArrayOfSouthBoundDrivers(UniqueRemovedElements);

    //  DebugTN("Removed Elements", UniqueRemovedElements);

    string multiLineRemove =  MakeMyTextMultiLine(UniqueRemovedElements);
    CreateStandardInfo(PRIO_INFO, 4, "The 'Deleted' SouthBound datapoints and the accociated drivers are:" + multiLineRemove);
  }

}

string MakeMyTextMultiLine(dyn_string myArray)
{
  string result = "\n";

  for (int i = 1; i <= dynlen(myArray); i++)
  {
    result = result + myArray[i] + "\n";
  }

  return result;

}


dyn_string GetMeTheArrayOfSouthBoundDrivers(dyn_string Elements)
{
  dyn_string listOfDrivers = makeDynString();

//DebugTN("Elemenets",Elements);
  for (int i = 1 ; i <= dynlen(Elements); i++)
  {
    dyn_string dps;
    // DebugTN("Elements[i]",Elements[i]);
    cnsGetNodesByName("*" + Elements[i], "", CNS_SEARCH_ALL_NAMES, CNS_SEARCH_ALL_LANGUAGES, CNS_DATATYPE_DATAPOINT, dps);

//DebugTN("dps")
    for (int j = 1 ; j <= dynlen(dps); j++)
    {
      string dpElement = dps[j];

      if (dpElement.contains("EB_Package_S7Plus"))
        listOfDrivers[i] = "S7Plus";

      else if (dpElement.contains("EB_Package_S7"))
        listOfDrivers[i] = "S7";
      else if (dpElement.contains("EB_Package_IEC61850"))
        listOfDrivers[i] = "IEC61850";
      else if (dpElement.contains("EB_Package_BACnet"))
        listOfDrivers[i] = "BACnet";
      else if (dpElement.contains("EB_Package_Sinumerik"))
        listOfDrivers[i] = "Sinumerik";


    }


  }

  return listOfDrivers;
}
dyn_string CreateMeFinaltext(dyn_string UniqueAddedElements, dyn_string arrayDriversForAdded)
{
  dyn_string resultString = makeDynString();

  for (int i = 1 ; i <= dynlen(UniqueAddedElements); i++)
  {
    resultString[i] = "Datapoint: " + UniqueAddedElements[i] + " ,For Driver: " + arrayDriversForAdded[i] + " , ";

  }

  return resultString;
}


string GetRealElementName(string dpName)
{
  dyn_string cnsPath;
  cnsGetNodesByData(dpName + ".", CNS_SEARCH_ALL_TYPES, cnsPath);

  //DebugTN("cnsPath", cnsPath);
  langString name;

  for (int i = 1 ; i <= dynlen(cnsPath); i++)
  {
    string initialID = cnsPath[i];

    bool contains = initialID.contains("Node_");

    if (contains == true)
    {

      cnsGetDisplayNames(initialID, name);
      //DebugTN("name", name);
      return (string)name;
    }
    else
    {
      continue;
    }
  }
return "";

}



checkingFordatapointsExisting()
{
  if (!dpExists("_NorthboundSubscribeOPCUA"))
  {
    dpCreate("_NorthboundSubscribeOPCUA", "_OPCUAServer");
    dpSet("_OPCUA17.Command.AddServer", "NorthboundSubscribeOPCUA");
    dyn_string myserVersList; bool foundTheConnection = false;
    dpGet("_OPCUA17.Config.Servers", myserVersList);

    for (int i = 1; i <= dynlen(myserVersList); i++)
    {
      if (myserVersList[i] == "NorthboundSubscribeOPCUA")
        foundTheConnection = true;
    }

    if (!foundTheConnection)
    {
      myserVersList.append("NorthboundSubscribeOPCUA");
      dpSet("_OPCUA17.Config.Servers", myserVersList);

    }
  }

  if (!dpExists("_NorthboundSubscribeMQTT"))
  {
    dpCreate("_NorthboundSubscribeMQTT", "_MqttConnection");
    dpSet("_NorthboundSubscribeMQTT.Config.Address", "{\"ConnectionType\": 1,\"Username\": \"\",\"ConnectionString\": \"localhost\",\"Password\": \"\",\"Identity\": \"\",\"Certificate\": \"\",\"PSK\": \"\"}",
          "_NorthboundSubscribeMQTT.Config.ReduAddress", "{\"ConnectionType\": 1,\"Username\": \"\",\"ConnectionString\": \"\",\"Password\": \"\",\"Identity\": \"\",\"MaxTopicAlias\": 0,\"Certificate\": \"\",\"PSK\": \"\"}",
          "_NorthboundSubscribeMQTT.Config.DrvNumber", 18,
          "_NorthboundSubscribeMQTT.Config.PersistentSession", true,
          "_NorthboundSubscribeMQTT.Config.LifebeatTimeout", 20,
          "_NorthboundSubscribeMQTT.Config.ReconnectTimeout", 20,
          "_NorthboundSubscribeMQTT.Command.Enable", true



         );


  }

}


dyn_string MakeUnique(dyn_string inputArray)
{
  dyn_string uniqueArray = makeDynString();

  for (int i = 1; i <= dynlen(inputArray); i++)
  {
    string curr = inputArray[i];
    bool found = FALSE;

    // check if already in uniqueArray
    for (int j = 1; j <= dynlen(uniqueArray); j++)
    {
      if (curr == uniqueArray[j])
      {
        found = TRUE;
        break;
      }
    }

    if (!found)
    {
      uniqueArray.append(curr);
    }
  }

  return uniqueArray;
}



dyn_anytype refineMysouthboundText(dyn_anytype southboundinit)
{
  string dpConfigName = "datapointConfigs";

  if (!dpExists(dpConfigName + "."))
  {
    dpCreate(dpConfigName, "ITOTConfigParamsDynString");
    //Ahmed: here  report here somehow all the deleted datapoints
  }

  dpSet(dpConfigName + ".", "");
  dyn_string datapointsWithParameters;
  string currentdatapointstringparameters;

  for (int i = 1; i <= dynlen(southboundinit); i++)
  {

    mapping mainElement;
    mainElement = southboundinit[i];


    mainElement.insert("dataSourceId", mainElement["name"]);

    //******* here in the following lines, mapping the required words of the file , with the needed words by mindsphere logic
    //Reading the readCycle and replace it with readCycleInSeconds (needed by mindsphere)
    if (mappingHasKey(mainElement, "readCycle"))
    {
      string value = mainElement["readCycle"];
      mainElement["readCycleInSeconds"] = value;
      mappingRemove(mainElement, "readCycle");
      //   DebugTN("Hi, I came here ,", mainElement);
    }

//******




    // Process data points

    string dpstring = jsonEncode(mainElement["dataPoints"], false);
    dyn_anytype dataPointsArray = jsonDecode(dpstring);


    for (int j = 1; j <= dynlen(dataPointsArray); j++)
    {




      mapping dataPoint = dataPointsArray[j];
      currentdatapointstringparameters = "dpname:" + dataPoint["name"] + ",";

      dataPoint.insert("dataPointId", dataPoint["name"]);

      //check for additional parameters which are not in mindsphere
      if (dataPoint.contains("archive"))
      {
        currentdatapointstringparameters = currentdatapointstringparameters + "archive:" + dataPoint["archive"] + ",";
        dataPoint.remove("archive");

      }

      if (dataPoint.contains("minimumValue"))
      {
        currentdatapointstringparameters = currentdatapointstringparameters + "minimumValue:" + dataPoint["minimumValue"] + ",";
        dataPoint.remove("minimumValue");

      }

      if (dataPoint.contains("maximumValue"))
      {
        currentdatapointstringparameters = currentdatapointstringparameters + "maximumValue:" + dataPoint["maximumValue"] + ",";
        dataPoint.remove("maximumValue");
      }

      //DebugTN("datapointDatanoproblematall");
      mapping datapointData = dataPoint["dataPointData"];
      //DebugTN("datapointData", datapointData, "datapointData.contains", datapointData.contains("addressActive"));

      if (datapointData.contains("addressActive"))
      {
        //DebugTN("Hi , I entered to address active");
        currentdatapointstringparameters = currentdatapointstringparameters + "addressActive:" + datapointData["addressActive"] + ",";
        datapointData.remove("addressActive");

      }

//******* here in the following lines, mapping the required words of the file , with the needed words by mindsphere logic
      //Reading the readCycle and replace it with readCycleInSeconds (needed by mindsphere)
      if (mappingHasKey(datapointData, "readCycle"))
      {
        string value = datapointData["readCycle"];
        datapointData["readCycleInSeconds"] = value;
        mappingRemove(datapointData, "readCycle");
        // DebugTN("Hi, I came here 2,", datapointData);
      }

//******

//******* here in the following lines, mapping the required words of the file , with the needed words by mindsphere logic
      //Reading the direction and replace it with acquisitionType (needed by mindsphere)
      if (mappingHasKey(datapointData, "direction"))
      {
        string value = datapointData["direction"];
        datapointData["acquisitionType"] = value;
        mappingRemove(datapointData, "direction");
        // DebugTN("Hi, I came here 3,", datapointData);
      }

//******

      //******* here in the following lines, mapping the required words of the file , with the needed words by mindsphere logic
      //Reading the onChange and replace it with onDataChanged (needed by mindsphere)
      if (mappingHasKey(datapointData, "onChange"))
      {
        string value = datapointData["onChange"];
        datapointData["onDataChanged"] = value;
        mappingRemove(datapointData, "onChange");
        //  DebugTN("Hi, I came here 4,", datapointData);
      }

//******

      dataPoint["dataPointData"] = datapointData;
      dataPointsArray[j] = dataPoint; // Re-encode after modification
      //DebugTN("dataPointtesteveryloop", dataPointsArray[j]);
      datapointsWithParameters.append(currentdatapointstringparameters);




    }

    mainElement["dataPoints"] = dataPointsArray;

    southboundinit[i] = mainElement; // Final encoding
    //DebugTN("Updated southboundinit[i]", southboundinit[i]);
  }

  dpSet(dpConfigName + ".", datapointsWithParameters);
  //DebugTN("southbound", southboundinit);
  return southboundinit;
}

handleDatapointsParameters(dyn_string myDatapointsParameters)
{
  dyn_string Debugarray;
  string dpname, minValue, maxValue;
  bool foundMin = false, foundMax = false;

  for (int i = 1; i <= dynlen(myDatapointsParameters); i++)
  {

    dyn_string textparts = strsplit(myDatapointsParameters[i], ",");
    //DebugTN("teststrimfirst", textparts);

    //additional lines to have the value of dpname
    dyn_string valuesPartsDPNAME = strsplit(textparts[1], ":");
    dpname = GetDPName(valuesPartsDPNAME[2], "datapoints configs");

    for (int j = 1; j <= dynlen(textparts); j++)
    {


      dyn_string valuesParts = strsplit(textparts[j], ":");
      //DebugTN("trimSecond", valuesParts);

      if (valuesParts[1] == "dpname")
      {
        dpname = GetDPName(valuesParts[2], "datapoints configs");
        //Debugarray.append("dpnamedpnamedpnamedpname" + dpname);


      }
      else if (valuesParts[1] == "archive")
      {

        dpSetWait(dpname + ":_archive.._type",
                  DPCONFIG_DB_ARCHIVEINFO,
                  dpname + ":_archive.._archive", (bool)valuesParts[2],
                  dpname + ":_archive.1._type",
                  DPATTR_ARCH_PROC_VALARCH,
                  dpname + ":_archive.1._class",
                  "_NGA_G_EVENT",
                  dpname + ":_archive.1._std_type",
                  DPATTR_VALUE_SMOOTH,
                  dpname + ":_archive.1._std_tol", 10);

        //handle here the archiving
        //Debugarray.append("I configured archive for datapoint:" + dpname);
        //DebugTN("I configured archive for datapoint:", dpname);
      }
      else if (valuesParts[1] == "addressActive")
      {
        //Debugarray.append("I configured addressActive for datapoint:" + dpname);
        //handle here the addressActive
        dpSetWait(dpname + ":_address.._active", (bool)  valuesParts[2]);
        //DebugTN("I configured addressActive for datapoint:", dpname);
      }
      else if (valuesParts[1] == "maximumValue")
      {
        //Debugarray.append("I configured maximumValue for datapoint:" + dpname);
        maxValue = valuesParts[2];
        foundMax = true;
        //DebugTN("I configured maximumValue for datapoint:", dpname);
      }
      else if (valuesParts[1] == "minimumValue")
      {
        //Debugarray.append("I configured minimumValue for datapoint:" + dpname);
        //handle here the minimumValue
        minValue = valuesParts[2];
        foundMin = true;
        //DebugTN("I configured minimumValue for datapoint:", dpname);
      }

    }

    if (foundMin || foundMax)
    {
      if (!foundMin)
        minValue = 0;

      if (!foundMax)
        maxValue = 100;
      else {}

      // //DebugTN("dpElementType(dpname)", dpElementType(dpname), "DPEL_BOOL", DPEL_BOOL);

      if (dpElementType(dpname) == DPEL_FLOAT || dpElementType(dpname) == DPEL_INT || dpElementType(dpname) == DPEL_UINT || dpElementType(dpname) == DPEL_ULONG || dpElementType(dpname) == DPEL_LONG)
      {
        dpSetWait(dpname + ":_pv_range.._type",
                  DPCONFIG_MINMAX_PVSS_RANGECHECK,
                  dpname + ":_pv_range.._min", minValue,
                  dpname + ":_pv_range.._max", maxValue,
                  dpname + ":_pv_range.._neg", FALSE,
                  dpname + ":_pv_range.._incl_min", TRUE,
                  dpname + ":_pv_range.._incl_max", TRUE,
                  dpname + ":_pv_range.._ignor_inv", FALSE);
        //Debugarray.append("I configured maximum Value for datapoint:" + dpname + "withvalues" + maxValue + "and" + minValue);
      }
      else
      {
        //Debugarray.append("The min max config is not configurable for data type: " +  dpElementType(dpname) + ", of the datapoint: " + dpname);
        // DebugTN("The min max config is not configurable for data type: " +  dpElementType(dpname) + ", of the datapoint: " + dpname);
      }
    }

    foundMin = false; foundMax = false;
  }

  dpSet("System1:resultparams.", Debugarray);
}

bool checkforChange(dyn_anytype southbound, string currentData)
{


  return jsonEncode(southbound) == currentData;
}

handleSouthBound(dyn_anytype southbound)
{


  dpSet("MindSphereConnector.receiveData", jsonEncode(southbound));

}

handleNorthBound(dyn_anytype northbound)
{
  int mqttNum, opcuaNum = 0;
  int connectionNum;
  string broker, port;
  string initialTopic;
  string mqttUsername, mqttPassword;
  NorthBoundinitialization();


  for (int i = 1; i <= dynlen(northbound); i++)
  {

    mapping northboundItem = northbound[i];
    //  //DebugTN("Northbound Item " + i);
    //  //DebugTN("Hi Ahmed " + northboundItem);
    //  //DebugTN("Connection Name: " + northboundItem["connectionName"]);
    // //DebugTN("Connection Type: " + northboundItem["connectionType"]);
    // //DebugTN("northboundItem[initialTopic]",northboundItem["initialTopic"]);

    CreateStandardInfo(PRIO_INFO, 3, "Created a 'Publish' connection with Type: " + (string)northboundItem["connectionType"] + ", With Name: " + (string)northboundItem["connectionName"]);

    if (northboundItem.contains("exposedViews"))
    {
      //DebugTN("I entered exposedViews");
      dyn_anytype exposedViews = northboundItem["exposedViews"];
      dyn_anytype  RefinedexposedViews = GetMeRefinedViewNames(exposedViews);
      //DebugTN("RefinedexposedViews", RefinedexposedViews);

      if (exposedViews[1] != NULL)
      {

        CreateStandardInfo(PRIO_INFO, 3, " For connection: " + (string)northboundItem["connectionType"] + ", With Name: " + (string)northboundItem["connectionName"] + ", All the datapoints related to the following Views are exposed to the connection: " + MakeMyTextMultiLine(exposedViews));

        if ((string)northboundItem["connectionType"] == "MQTT")
        {
          //DebugTN("I am handling MQTT exposedViews");
          broker = (string)northboundItem["broker"];
          port = (string)northboundItem["port"];
          mqttNum = mqttNum + 1;
          connectionNum = mqttNum;

          if (!(northboundItem.contains("initialTopic")))
          {
            initialTopic = "";
          }
          else if (northboundItem.contains("initialTopic"))
          {
            initialTopic = (string)northboundItem["initialTopic"];
          }

          if (!(northboundItem.contains("credentials")))
          {
            //DebugTN("Hi , I do not contain credentials as mqtt");
            mqttUsername = "";
            mqttPassword = "";
          }
          else if (northboundItem.contains("credentials"))
            //come here
          {
            //DebugTN("Hi , I contain credentials as mqtt");
            //  initialTopic = (string)northboundItem["initialTopic"];
            mapping credentials = northboundItem["credentials"];
            //DebugTN("credentials", credentials);
            mqttUsername = credentials["username"];
            mqttPassword = credentials["password"];
            //DebugTN("mqttUsername", "mqttPassword", mqttUsername, mqttPassword);
          }

          HandleOriginalCNSMQTT(RefinedexposedViews, connectionNum, broker, port, initialTopic, mqttUsername, mqttPassword);
        }

        else if ((string)northboundItem["connectionType"] == "OPCUA")
        {
          if (!(northboundItem.contains("initialTopic")) || (string)northboundItem["initialTopic"] == "")
          {
            //DebugTN("I am handling opc ua exposedViews");
            broker = "";
            port = "";
            HandleOriginalCNSOPCUA(RefinedexposedViews, connectionNum, broker, port);
          }
        }


      }

    }

    if (northboundItem.contains("useUnifiedNameSpace"))
      handleUnifiedNameSpaceWithDrivers((string)northboundItem["connectionType"], connectionNum, northboundItem["useUnifiedNameSpace"]);






  }

}

int  OPCUATransformationDetails(string dataType)
{

  if (dataType == "DEFAULT")
    return 750;
  else if (dataType == "BOOLEAN")
    return 751;

  else if (dataType == "SBYTE")
    return 752;
  else if (dataType == "BYTE")
    return 753;
  else if (dataType == "INT16")
    return 754;
  else if (dataType == "UINT16")
    return 755;
  else if (dataType == "INT")
    return 756;
  else if (dataType == "UINT32")
    return 757;
  else if (dataType == "INT64")
    return 758;
  else if (dataType == "UINT64")
    return 759;
  else if (dataType == "FLOAT")
    return 760;
  else if (dataType == "DOUBLE")
    return 761;
  else if (dataType == "STRING")
    return 762;
  else if (dataType == "DATETIME")
    return 763;
  else if (dataType == "GUID")
    return 764;
  else if (dataType == "BYTESTRING")
    return 765;
  else if (dataType == "XMLELEMENT")
    return 766;
  else if (dataType == "NODEID")
    return 767;
  else if (dataType == "LOCALIZEDTEXT")
    return 768;
  else
    return  750;
}

handleNorthBoundSubscribe(dyn_anytype northboundSubscribe)
{
// dyn_string DPSubscribeCurrentDPList= GetCurrentSubscribeListOfDps();
//come here
  string allCreatedDPs;
  dyn_string UniqueCreatedDPs;
  dyn_string allCurrentDPs = makeDynString();

  for (int i = 1 ; i <= dynlen(northboundSubscribe); i++)
  {

    mapping arrayElement = northboundSubscribe[i];

    if (arrayElement["connectionType"] == "OPCUA")
    {
      string connectionType, server, port,  dataPointName, dataTypeJson, dataType, dataPointDescription, dpUnit, address, readCycleString; // Extracted from JSON
      int readCycleInt, driverNum = 17;
      bool onDataChange, addressActive;

      server = arrayElement["server"];
      port = arrayElement["port"];
      //handle here the connection parameters

      //DebugTN("opc ua address", "opc.tcp://" + server + ":" + port);
      dpSet("System1:_NorthboundSubscribeOPCUA.Config.ConnInfo", "opc.tcp://" + server + ":" + port);
      dpSet("System1:_NorthboundSubscribeOPCUA.Config.Active", 1);
      //handle here the datapoints
      dyn_anytype dataPoints = arrayElement["dataPoints"];
      mapping currentDPmap;

      for (int i = 1 ; i <= dynlen(dataPoints); i++)
      {
        currentDPmap = dataPoints[i];
        dataTypeJson = currentDPmap["dataType"];

        if (dataTypeJson == "BOOLEAN")
        {
          dataType = "SB_Sub_Bool";
        }
        else if (dataTypeJson == "STRING")
        {
          dataType = "SB_Sub_String";
        }
        else if (dataTypeJson == "INT")
        {
          dataType = "SB_Sub_Int";
        }
        else if (dataTypeJson == "DOUBLE" || dataTypeJson == "FLOAT")
        {
          dataType = "SB_Sub_Float";
        }
        else
        {
          CreateStandardInfo(PRIO_WARNING, 2, "Unsupported data type: " + dataType);
          // DebugTN("Unsupported data type: ", dataType);
          return;
        }

        //DebugTN("currentDPmap", currentDPmap);

        // Set the new data point name with prefix
        dataPointName = currentDPmap["name"];
        dataPointDescription = currentDPmap["description"];
        dpUnit = currentDPmap["unit"];
        addressActive = currentDPmap["active"];




        mapping dataPointData;
        dataPointData = currentDPmap["dataPointData"];
        //DebugTN("dataPointData", dataPointData);


        address = dataPointData["address"];

        if (dataPointData.contains("onChange"))
          onDataChange = dataPointData["onChange"];
        else
          onDataChange = false;

        //DebugTN("datapoint data", currentDPmap.contains("readCycle"), currentDPmap["readCycle"]);


        if (currentDPmap.contains("readCycle"))
        {

          //DebugTN("I have entered inside the datapoint cycle value");
          readCycleString = currentDPmap["readCycle"];
          //DebugTN("readCyclereadCycle", readCycleString);
        }
        else if (arrayElement.contains("readCycle"))
        {

          readCycleString = arrayElement["readCycle"];

          //DebugTN("I have entered inside the driver cycle value");
        }
        else
        {
          readCycleString = "1"     ;

          //DebugTN("cycle value = 1");
        }


        string dataPointElement = dataPointName + "."; // Root data point element

        allCurrentDPs.append(dataPointName);

        // Create the data point
        if (!dpExists(dataPointName))
        {
          dpCreate(dataPointName, dataType);
          UniqueCreatedDPs.append(dataPointName);
        }

        string pollGroupname = "_" + (int)(readCycleString) * 1000 + "ms";
        dyn_errClass lastError;
        int          direction;
        unsigned     dpIdPollgroup;
        int          dpElIdPollgroup;







        dpGetId(pollGroupname + ".",
                dpIdPollgroup,
                dpElIdPollgroup);
        //DebugTN("dpIdPollgroup", dpIdPollgroup);

        if (dpIdPollgroup == 0)
        {
          //DebugTN("createAdressConfigForOPCuaClient: poll group does not exist: " + pollGroupname);
          dpCreate(pollGroupname, "_PollGroup"); // Replace with actual data point type

        }

        dpSet(pollGroupname + ".Active", 1);
        readCycleInt = (int) readCycleString * 1000;
        //DebugTN("readCycleInt", readCycleInt);
        dpSet(pollGroupname + ".PollInterval", readCycleInt);
        //DebugTN("dataType", dataTypeJson);
        //DebugTN("OPCUATransformationDetails(dataType)", OPCUATransformationDetails(dataTypeJson));
        dpSetWait(dataPointElement + ":_distrib.._type",       DPCONFIG_DISTRIBUTION_INFO,
                  dataPointElement + ":_distrib.._driver",     driverNum,
                  dataPointElement + ":_address.._type",       DPCONFIG_PERIPH_ADDR_MAIN,
                  dataPointElement + ":_address.._drv_ident",  "OPCUA",
                  dataPointElement + ":_address.._reference",  "NorthboundSubscribeOPCUA$$1$1$" + address,
                  dataPointElement + ":_address.._poll_group", pollGroupname,
                  dataPointElement + ":_address.._direction",  4,
                  dataPointElement + ":_address.._lowlevel",   onDataChange,
                  dataPointElement + ":_address.._active",     addressActive,
                  dataPointElement + ":_address.._datatype", OPCUATransformationDetails(dataTypeJson),
                  dataPointElement + ":_address.._subindex",     0,
                  dataPointElement + ":_address.._offset",     0,
                  dataPointElement + ":_address.._internal",   0);
        dpSetUnit(dataPointElement, dpUnit);
        dpSetDescription(dataPointElement, dataPointDescription);

        /////add the additional parameters (archive -min - max)
        if (currentDPmap.contains("archive"))
        {
          dpSetWait(dataPointElement + ":_archive.._type",
                    DPCONFIG_DB_ARCHIVEINFO,
                    dataPointElement + ":_archive.._archive", currentDPmap["archive"],
                    dataPointElement + ":_archive.1._type",
                    DPATTR_ARCH_PROC_VALARCH,
                    dataPointElement + ":_archive.1._class",
                    "_NGA_G_EVENT",
                    dataPointElement + ":_archive.1._std_type",
                    DPATTR_VALUE_SMOOTH,
                    dataPointElement + ":_archive.1._std_tol", 10);


        }

        if (currentDPmap.contains("minimumValue") || currentDPmap.contains("maximumValue"))
        {
          int minVal, maxVal;

          if (currentDPmap.contains("minimumValue"))
            minVal = currentDPmap["minimumValue"];
          else
            minVal = 0;

          if (currentDPmap.contains("maximumValue"))
            maxVal = currentDPmap["maximumValue"];
          else
            maxVal = 100;

          if (dataTypeJson == "INT" || dataTypeJson == "FLOAT" || dataTypeJson == "DOUBLE")
          {
            dpSetWait(dataPointElement + ":_pv_range.._type",
                      DPCONFIG_MINMAX_PVSS_RANGECHECK,
                      dataPointElement + ":_pv_range.._min", minVal,
                      dataPointElement + ":_pv_range.._max", maxVal,
                      dataPointElement + ":_pv_range.._neg", FALSE,
                      dataPointElement + ":_pv_range.._incl_min", TRUE,
                      dataPointElement + ":_pv_range.._incl_max", TRUE,
                      dataPointElement + ":_pv_range.._ignor_inv", FALSE);
          }
          else
          {

            CreateStandardInfo(PRIO_WARNING, 2, "The min max config is not configurable for data type:" + dataTypeJson + ", for the datapoint" + dataPointElement + "For NorthBoundSubscribe For OPC UA");
          }

        }


        allCreatedDPs = allCreatedDPs + dataPointName + ",";

      }
    }
    else if (arrayElement["connectionType"] == "MQTT")
    {
      //DebugTN("I entered to create MQTT");
      string connectionType, broker, port,  dataPointName, dataTypeJson, dataType, dataPointDescription, dpUnit, topicString, loginUser = "", loginPassword = "" ; // Extracted from JSON
      int  driverNum = 18;
      bool onDataChange, addressActive;

      broker = arrayElement["broker"];
      port = arrayElement["port"];
      //DebugTN("I entered to create MQTT", broker, port);

      if (arrayElement.contains("credentials"))
      {
        mapping credentials = arrayElement["credentials"];

        if (credentials.contains("username"))
          loginUser = credentials["username"];

        if (credentials.contains("password"))
          loginPassword = credentials["password"];
      }

      //DebugTN("I entered to create MQTT", loginUser, loginPassword);
      //handle here the connection parameters
      string currentAddress = "{\"ConnectionType\": 1,\"ConnectionString\": \"" + broker + ":" + port + "\",\"Identity\": \"\",\"Password\": \"" + loginPassword + "\",\"PSK\": \"\",\"Certificate\": \"\",\"Username\": \"" + loginUser + "\"}";
      dpSet("System1:_NorthboundSubscribeMQTT.Config.Address", currentAddress);
      ///* //DebugTN("MQTT System1:_NorthboundSubscribeMQTT.Config

      dpSet("System1:_NorthboundSubscribeMQTT.Config.EstablishmentMode", 1);//*/
      dpSet("System1:_NorthboundSubscribeMQTT.Config.DrvNumber", driverNum);//*/
      //handle here the datapoints
      dyn_anytype dataPoints = arrayElement["dataPoints"];
      mapping currentDPmap;

      for (int i = 1 ; i <= dynlen(dataPoints); i++)
      {
        currentDPmap = dataPoints[i];
        dataTypeJson = currentDPmap["dataType"];

        if (dataTypeJson == "BOOLEAN")
        {
          dataType = "SB_Sub_Bool";
        }
        else if (dataTypeJson == "STRING")
        {
          dataType = "SB_Sub_String";
        }
        else if (dataTypeJson == "INT")
        {
          dataType = "SB_Sub_Int";
        }
        else if (dataTypeJson == "DOUBLE" || dataTypeJson == "FLOAT")
        {
          dataType = "SB_Sub_Float";
        }
        else
        {
          CreateStandardInfo(PRIO_WARNING, 2, "Unsupported data type for MQTT subscription: " + dataType);
          //  DebugTN("Unsupported data type for MQTT subscription: ", dataType);
          return;
        }

        //DebugTN("currentDPmap", currentDPmap);

        // Set the new data point name with prefix
        dataPointName = currentDPmap["name"];
        dataPointDescription = currentDPmap["description"];
        dpUnit = currentDPmap["unit"];
        addressActive = currentDPmap["active"];




        mapping dataPointData;
        dataPointData = currentDPmap["dataPointData"];
        //DebugTN("dataPointData", dataPointData);


        topicString = dataPointData["topic"];

        if (dataPointData.contains("onChange"))
          onDataChange = dataPointData["onChange"];
        else
          onDataChange = false;

        ////DebugTN("datapoint data", currentDPmap.contains("readCycle"), currentDPmap["readCycle"]);


        string dataPointElement = dataPointName + "."; // Root data point element
        allCurrentDPs.append(dataPointName);

        // Create the data point
        if (!dpExists(dataPointName))
        {
          dpCreate(dataPointName, dataType); // Replace with actual data point type
          UniqueCreatedDPs.append(dataPointName);
        }



        dpSetWait(dataPointElement + ":_distrib.._type",       DPCONFIG_DISTRIBUTION_INFO,
                  dataPointElement + ":_distrib.._driver",     driverNum,
                  dataPointElement + ":_address.._type",       DPCONFIG_PERIPH_ADDR_MAIN,
                  dataPointElement + ":_address.._drv_ident",  "MQTT",
                  dataPointElement + ":_address.._reference",  topicString,  // MQTT topic
                  dataPointElement + ":_address.._active",     addressActive,
                  dataPointElement + ":_address.._subindex",   0,
                  dataPointElement + ":_address.._offset",     0,
                  dataPointElement + ":_address.._internal",   0,
                  dataPointElement + ":_address.._mode",       2,
                  dataPointElement + ":_address.._connection", "_NorthboundSubscribeMQTT"
                 );  // Set mode (1 for Publish, 2 for Subscribe)

        dpSet(dataPointElement + ":_address.._lowlevel", onDataChange);

        dpSetUnit(dataPointElement, dpUnit);
        dpSetDescription(dataPointElement, dataPointDescription);

        if (currentDPmap.contains("archive"))
        {
          dpSetWait(dataPointElement + ":_archive.._type",
                    DPCONFIG_DB_ARCHIVEINFO,
                    dataPointElement + ":_archive.._archive", currentDPmap["archive"],
                    dataPointElement + ":_archive.1._type",
                    DPATTR_ARCH_PROC_VALARCH,
                    dataPointElement + ":_archive.1._class",
                    "_NGA_G_EVENT",
                    dataPointElement + ":_archive.1._std_type",
                    DPATTR_VALUE_SMOOTH,
                    dataPointElement + ":_archive.1._std_tol", 10);


        }

        if (currentDPmap.contains("minimumValue") || currentDPmap.contains("maximumValue"))
        {
          int minVal, maxVal;

          if (currentDPmap.contains("minimumValue"))
            minVal = currentDPmap["minimumValue"];
          else
            minVal = 0;

          if (currentDPmap.contains("maximumValue"))
            maxVal = currentDPmap["maximumValue"];
          else
            maxVal = 100;

          if (dataTypeJson == "INT" || dataTypeJson == "FLOAT" || dataTypeJson == "DOUBLE")
          {
            dpSetWait(dataPointElement + ":_pv_range.._type",
                      DPCONFIG_MINMAX_PVSS_RANGECHECK,
                      dataPointElement + ":_pv_range.._min", minVal,
                      dataPointElement + ":_pv_range.._max", maxVal,
                      dataPointElement + ":_pv_range.._neg", FALSE,
                      dataPointElement + ":_pv_range.._incl_min", TRUE,
                      dataPointElement + ":_pv_range.._incl_max", TRUE,
                      dataPointElement + ":_pv_range.._ignor_inv", FALSE);
          }
          else
          {
            CreateStandardInfo(PRIO_WARNING, 2, "The min max config is not configurable for data type:" + dataTypeJson + ", for the datapoint" + dataPointElement + "For NorthBoundSubscribe For OPC UA");

          }


        }


        allCreatedDPs = allCreatedDPs + dataPointName + ",";
      }


    }

  }

// DebugTN("allCurrentDPs", allCurrentDPs);
  dyn_string deletedDPs = CheckAboutOldCreatedSubscribedDPs(allCurrentDPs);
  dpSet("System1:currentSubscribedOPCUAAndMQTTDatapoints.", allCreatedDPs);
  DebugTN("UniqueCreatedDPs",UniqueCreatedDPs);
  CreateStandardInfo(PRIO_INFO, 2, "The 'Added' Subscribe datapoints are: " + MakeMyTextMultiLine(UniqueCreatedDPs));
  CreateStandardInfo(PRIO_INFO, 2, "The 'Deleted' Subscribe datapoints are: " + MakeMyTextMultiLine(deletedDPs));
}

dyn_string  CheckAboutOldCreatedSubscribedDPs(dyn_string allCurrentDPs)//deletion mechanism for all the extra old subscribed datapoints
{
  dyn_dyn_string SubscribedDPs;
  dyn_string deletedDPs = makeDynString();
  SubscribedDPs[1] = GetmyDPs("SB_Sub_Bool"); //1 for boolean datapoints
  SubscribedDPs[2] = GetmyDPs("SB_Sub_Float");
  SubscribedDPs[3] = GetmyDPs("SB_Sub_Int");
  SubscribedDPs[4] = GetmyDPs("SB_Sub_String");

  for (int i = 1 ; i <= dynlen(SubscribedDPs); i++)
  {
    if (dynlen(SubscribedDPs[i]) != 0)
    {
      dyn_string myTypeArray = SubscribedDPs[i];

      for (int j = 1 ; j <= dynlen(myTypeArray) ; j++)
      {
        if (!dynContains(allCurrentDPs, myTypeArray[j]))
        {
          deletedDPs.append(myTypeArray[j]);
          dpDelete(myTypeArray[j]);
        }
      }
    }
  }

  return deletedDPs;
}
dyn_string GetmyDPs(string dptype)
{

  dyn_string myDPs = dpNames("*", dptype);
  dyn_string dpParts;

  if (dynlen(myDPs) != 0)
  {
    for (int i = 1 ; i <= dynlen(myDPs); i++)
    {
      string val =   myDPs[i];
      dpParts = val.split(":");
      myDPs[i] = dpParts[2];

    }

  }

  return myDPs;

}
handleUnifiedNameSpaceWithDrivers(string connectionType, int connectionNum, bool UNSActiveValue)
{
  //DebugTN("UNSActiveValue", UNSActiveValue);

  if (UNSActiveValue)
  {
    dyn_string myCurrentViews;
    string myUNSView;
    dyn_string myUNSViewParts;
    dpGet("System1:CurrentUNSTitle.", myUNSView);
    myUNSViewParts = strsplit(myUNSView, ".");
    myUNSView = substr(myUNSViewParts[2], 0, strlen(myUNSViewParts[2]) - 1);
    //DebugTN("FinalUNSText", myUNSView);

    if (connectionType == "OPCUA")
    {

      dpGet("_OPCUAPvssServer.Config.CNSViews", myCurrentViews);

      myCurrentViews.append(myUNSView);
      dpSet("_OPCUAPvssServer.Config.CNSViews", myCurrentViews);
      dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, 3));
      delay(0.5);
    }
    else if (connectionType == "MQTT")
    {
      if (connectionNum == 1)
      {
        dpGet("_MqttPublisher.Config.CNSViews", myCurrentViews);
        myCurrentViews.append(myUNSView);
        dpSet("_MqttPublisher.Config.CNSViews", myCurrentViews);
      }
      else if (connectionNum == 2)
      {
        dpGet("_MqttPublisher2.Config.CNSViews", myCurrentViews);
        myCurrentViews.append(myUNSView);
        dpSet("_MqttPublisher2.Config.CNSViews", myCurrentViews);
      }

      dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, connectionNum));
      delay(0.5);
    }
  }
  else
  {
    //DebugTN("The using of UNS is not Active for :" + connectionType + "with number:" + connectionNum);
  }
}

dyn_anytype GetMeRefinedViewNames(dyn_anytype exposedViews)
{
  dyn_anytype refinednames;

  for (int i = 1 ; i <= dynlen(exposedViews) ; i++)
  {
    switch (exposedViews[i])
    {
      case "S7PLUS":
        refinednames[i] = "EB_Package_S7Plus";
        break;

      case "SINUMERIK":
        refinednames[i] = "EB_Package_Sinumerik";
        break;

      case "S7":
        refinednames[i] = "EB_Package_S7";
        break;

      case "BACNET":
        refinednames[i] = "EB_Package_BACnet";
        break;

      case "IEC61850":
        refinednames[i] = "EB_Package_IEC61850";
        break;

      case "MTCONNECT":
        refinednames[i] = "EB_Package_MTConnect";
        break;

      default:
        //DebugTN("Un-handeled driver type for exposing to OPCUA or MQTT");
        break;
    }






  }

  //DebugTN("refinednames", refinednames);
  return refinednames;


}


NorthBoundinitialization()
{


  if (!dpExists("_OPCUAPvssServer"))
  {
    dpCreate("_OPCUAPvssServer", "_OPCUAPvssServer");
    dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, 3));
  }

  if (!dpExists("_MqttPublisher"))
  {
    dpCreate("_MqttPublisher", "_MqttPublisher");
    dpSet("_MqttPublisher.Config.LifebeatTimeout", 20);
    dpSet("_MqttPublisher.Config.Address", "{\"ConnectionType\": 1,\"Username\": \"\",\"ConnectionString\": \"localhost:1884\",\"Password\": \"\",\"Identity\": \"\",\"Certificate\": \"\",\"PSK\": \"\"}");
    dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, 1));
  }

  if (!dpExists("_MqttPublisher2"))
  {
    dpCreate("_MqttPublisher2", "_MqttPublisher");
    dpSet("_MqttPublisher2.Config.LifebeatTimeout", 20);
    dpSet("_MqttPublisher2.Config.Address", "{\"ConnectionType\": 1,\"Username\": \"\",\"ConnectionString\": \"localhost:1884\",\"Password\": \"\",\"Identity\": \"\",\"Certificate\": \"\",\"PSK\": \"\"}");
    dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, 2));
  }


  dpSet("_OPCUAPvssServer.Config.CNSViews", "");
  dpSet("_MqttPublisher.Config.CNSViews", "");
  dpSet("_MqttPublisher2.Config.CNSViews", "");
}




HandleOriginalCNSOPCUA(dyn_anytype RefinedexposedViews, int connectionNum, string broker, string port)
{
  //DebugTN("HandleOriginalCNSOPCUA is called with ", RefinedexposedViews, "connection num", connectionNum);
  int accessLevel = 10;

  string systemName;
  int length = strlen(getSystemName());
  systemName = substr(getSystemName(), 0, length - 1);




  //DebugTN("hey i am opc ua ");
  dpSet("_OPCUAPvssServer.Config.CNSViews", RefinedexposedViews);

  dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, 3));
  delay(0.5);

  for (int i = 1; i <= dynlen(RefinedexposedViews); i++)
  {
    dyn_string childPaths;
    dyn_string grandchildPaths;
    string parentPath = systemName  + "." + RefinedexposedViews[i] + ":";
    cnsGetTrees(parentPath, childPaths);

    //DebugTN("childPaths[j]", childPaths);

    for (int j = 1; j <= dynlen(childPaths); j++)
    {
      cnsSetProperty(childPaths[j], "OA:OPC", accessLevel);
      cnsGetChildren(childPaths[j], grandchildPaths);
      //DebugTN("grandchildPaths", grandchildPaths);

      for (int k = 1; k <= dynlen(grandchildPaths); k++)
      {

        cnsSetProperty(grandchildPaths[k], "OA:OPC", accessLevel);
      }
    }

  }



}







HandleOriginalCNSMQTT(dyn_anytype RefinedexposedViews, int connectionNum, string broker, string port, string initialTopic, string mqttUsername, string mqttPassword)
{
  //DebugTN("HandleOriginalCNSMQTT is called with ", RefinedexposedViews, "connection num", connectionNum);
  int accessLevel = 7;

  string systemName;
  int length = strlen(getSystemName());
  systemName = substr(getSystemName(), 0, length - 1);




  if (connectionNum == 1)
  {
    //DebugTN("hey i am mqtt1");
    dpSet("_MqttPublisher.Config.CNSViews", RefinedexposedViews);
    dpSet("_MqttPublisher.Config.RootTopic", initialTopic);
    dpSet("_MqttPublisher.Config.Mode", 1);
    SetMQTTConnectionParameters("_MqttPublisher.Config.Address", broker, port, mqttUsername, mqttPassword);

  }
  else if (connectionNum == 2)
  {
    //DebugTN("hey i am mqtt2");
    dpSet("_MqttPublisher2.Config.CNSViews", RefinedexposedViews);
    dpSet("_MqttPublisher2.Config.RootTopic", initialTopic);
    dpSet("_MqttPublisher2.Config.Mode", 1);
    SetMQTTConnectionParameters("_MqttPublisher2.Config.Address", broker, port, mqttUsername, mqttPassword);
  }

  dpSet("_Managers.Exit:_original.._value", convManIdToInt(DEVICE_MAN, connectionNum));
  delay(0.5);

  for (int i = 1; i <= dynlen(RefinedexposedViews); i++)
  {
    dyn_string childPaths;
    dyn_string grandchildPaths;
    string parentPath = systemName + "."  + RefinedexposedViews[i] + ":";
    //DebugTN("MQTTparentstring", parentPath);
    cnsGetTrees(parentPath, childPaths);
    //DebugTN("MQTTchildPaths", childPaths);

    for (int j = 1; j <= dynlen(childPaths); j++)
    {
      cnsSetProperty(childPaths[j], "OA:MQTT", accessLevel);

      cnsGetChildren(childPaths[j], grandchildPaths);

      for (int j = 1; j <= dynlen(grandchildPaths); j++)
      {
        cnsSetProperty(grandchildPaths[j], "OA:MQTT", accessLevel);
      }

    }
  }
}

SetMQTTConnectionParameters(string dpName, string Broker, string Port, string mqttUsername, string mqttPassword)
{
  string dpgetResult;
  dpGet(dpName, dpgetResult);

// Decode the JSON string into a mapping
  mapping jsonData = jsonDecode(dpgetResult);

// Modify a specific part of the JSON
  jsonData["ConnectionString"] = Broker + ":" + Port; // Change the value as needed
  jsonData["Username"] = mqttUsername; // Change the value as needed
  jsonData["Password"] = mqttPassword; // Change the value as needed
// Encode the modified mapping back to a JSON string
  string modifiedJsonString = jsonEncode(jsonData, false);
  //DebugTN("Mqtt Brokers IPs", dpName, modifiedJsonString);
// Set the modified JSON string back to the data point
  dpSet(dpName, modifiedJsonString);
}


dyn_string collectPaths(mapping map, string parentPath)
{
  dyn_string paths; // Array to store the paths
  dyn_string keys = mappingKeys(map); // Get all keys in the mapping

  // //Debug: Log the keys
  //  //DebugTN("Keys in the mapping: ", keys);

  for (int i = 1; i <= dynlen(keys); i++)
  {
    string key = keys[i];
    anytype value = map[key];
    string fullPath = (parentPath != "") ? parentPath + "." + key : key;

    // //Debug: Log key and full path
    //  //DebugTN("Processing key: ", key, " with full path: ", fullPath);

    // Check if the value is a mapping before calling the recursive function
    if (getType(value) == MAPPING_VAR) // If value is another mapping
    {
      dyn_string subPaths = collectPaths(value, fullPath); // Recurse

      for (int j = 1; j <= dynlen(subPaths); j++)
      {
        paths.append(subPaths[j]); // Append the subpath to paths
      }
    }
    else if (dynlen(value) > 0) // If value is an array
    {
      dyn_string valueArray = value;  // Assuming it's a dyn_string array

      for (int j = 1; j <= dynlen(valueArray); j++)
      {
        // Append the full path and array element as a tag
        paths.append(fullPath + "." + (valueArray[j])); // Add tag to path
      }
    }
    else // For leaf nodes (non-mapping values like string, number, etc.)
    {
      paths.append(fullPath); // Add path for leaf node
    }
  }

  // //Debug: Log the collected paths
  //  //DebugTN("Collected paths: ", paths);



  return paths; // Return the collected paths
}


CreateUnifiedNameSpaceCNS(dyn_string allPaths)


{
  string systemName;
  string currentCreatedView;
  systemName = substr(getSystemName(), 0, strlen(getSystemName()) - 1) + ".";
  //DebugTN("allPaths");

  langString viewNames;
  dpGet("CurrentUNSTitle.", currentCreatedView);

  if (currentCreatedView != "" && cnsGetViewDisplayNames(currentCreatedView, viewNames))
  {
  //  DebugTN("Hi I deleted the old View");

    //DebugTN("currentCreatedView", currentCreatedView);
    cns_deleteView(currentCreatedView);
    delay(1);
    /*if ()
       DebugTN("deletion of CNS done successfully");
     else
       DebugTN("there is no such uns view to delete in the beginning");
    */
  }


  for (int i = 1; i <= dynlen(allPaths); i++)
  {

    dyn_string pathParts = strsplit(allPaths[i], ".");




    for (int j = 1; j <= dynlen(pathParts); j++)
    {
      langString myLang;
      int accessLevelOPC = 10;
      int accessLevelMQTT = 7;

      if (j == 1)
      {

        string viewID =  systemName + pathParts[j] + ":";

////DebugTN("View ID _______________________",viewID);
        if (!cns_viewExists(viewID))
        {
          //   DebugTN("in the other one I entered to create the view");
          langString myLang;
          setLangString(myLang, 0, "" + pathParts[j]);
          cnsCreateView(viewID, myLang);
        }
        else
        {
          //  DebugN("View already exists: ", viewID);

        }

        //setting the created main view ID
        dpSet("CurrentUNSTitle.", viewID);

      }
      else if (j > 1 && j < dynlen(pathParts))
      {
        //DebugTN("entered to create the UNS subviews");
        setLangString(myLang, 0, "" + pathParts[j]);

        string parentID = systemName + pathParts[1] + ":";

        for (int k = 2; k <= j - 1; k++)
        {
          parentID = parentID + "" + pathParts[k] + ".";
        }

        // //DebugTN("Parent ID _______________________",parentID);

        ////DebugTN("substr(parentID, strlen(parentID) - 1, 1)",substr(parentID, strlen(parentID) - 1, 1));
        if (substr(parentID, strlen(parentID) - 1, 1) == ".")
        {
          parentID = substr(parentID, 0, strlen(parentID) - 1);
          // //DebugTN("parentID2",parentID);
        }

        // DebugTN("parentID",parentID,"pathParts[j]",pathParts[j]);



        /**
          Here I am checking if the elements of the CNS is already existing or not
        **/

        if (!cns_nodeExists(GetTextToPassCNSCheck(parentID, pathParts[j])))
        {
          // DebugTN("textToPass",textToPass);
          // DebugTN("Hello I entered to cns");
          cns_createTreeOrNode(parentID, pathParts[j], myLang, "", CNS_DATATYPE_EMPTY);
        }

        if (j == 2)
        {
          cnsSetProperty(parentID + "" + pathParts[j], "OA:OPC", accessLevelOPC);
          cnsSetProperty(parentID + "" + pathParts[j], "OA:MQTT", accessLevelMQTT);
        }
        else
        {
          cnsSetProperty(parentID + "." + pathParts[j], "OA:OPC", accessLevelOPC);
          cnsSetProperty(parentID + "." + pathParts[j], "OA:MQTT", accessLevelMQTT);
        }
      }
      else if (j == dynlen(pathParts))
      {
        setLangString(myLang, 0, "" + pathParts[j]);

        string parentID = "System1." + pathParts[1] + ":";

        for (int k = 2; k <= j - 1; k++)
        {
          parentID = parentID + "" + pathParts[k] + ".";
        }

        if (substr(parentID, strlen(parentID) - 1, 1) == ".")
        {
          parentID = substr(parentID, 0, strlen(parentID) - 1);
          //DebugTN("parentID", parentID);
        }

        //DebugTN("pathParts[j]", pathParts[j]);
        //DebugTN("GetDPName(pathParts[j])", pathParts[j], GetDPName(pathParts[j]));
        if (!cns_nodeExists(GetTextToPassCNSCheck(parentID, pathParts[j])))
          cns_createTreeOrNode(parentID, pathParts[j], myLang, GetDPName(pathParts[j]), CNS_DATATYPE_DATAPOINT);

        cnsSetProperty(parentID + "." + pathParts[j], "OA:OPC", accessLevelOPC);
        cnsSetProperty(parentID + "." + pathParts[j], "OA:MQTT", accessLevelMQTT);

      }
      else
      {}


    }

  }
}

string GetTextToPassCNSCheck(string parentID, string pathParts)
{
  string textToPass = "";
  int length = parentID.length();

  if (length > 0)
  {
    char lastChar = parentID.at(length - 1); // Get the last character

    if (lastChar == ':')
    {
      textToPass = parentID + pathParts;
    }
    else
    {
      textToPass = parentID + "." + pathParts;
    }
  }

  return textToPass;

}
string GetDPName(string dpname, string comingFrom = "")
{

  //DebugTN("the dpname I have is :", dpname);

  dyn_string nodes;
  string dp; // Variable to hold the data point name
  int type;  // Variable to hold the node type

  bool foundCNSDpname = cnsGetNodesByName("*" + dpname, "", CNS_SEARCH_ALL_NAMES, CNS_SEARCH_ALL_LANGUAGES, CNS_DATATYPE_ALL_TYPES, nodes);
  //DebugTN("foundCNSDpname", foundCNSDpname, "with nodes", nodes);
  //DebugTN("Paths:", nodes);
  //DebugTN("coming from", comingFrom);

  if (dynlen(nodes) != 0)
  {
    cnsGetId(nodes[1], dp, type);
    //DebugN("Data Point Name: ", dp);
    //DebugN("Node Type: ", type);
  }




  else
  {
    //DebugTN("I will try to add which is coming from northbound subscription");
    dp = dpname + ".";
    bool dpExistss = dpExists(dp);
    //DebugTN("northboundSubdpExistss", dpExistss);

    if (!dpExistss)
    {
      //DebugN("Node not found or no data point linked.");
      return "DPNOTFOUND";
    }
  }

  //DebugTN("the dpname I return is :", dp);
  return dp;

}


DashboardInitialize(dyn_anytype allDashboards)
{
  string dashboardNames;

  int totalDashboards = dynlen(allDashboards);
  //DebugTN("length of dynamic Dashboards", totalDashboards);  // Verify this prints 2
  //DebugTN("Dashboard[1]:", allDashboards[1]);
  //DebugTN("Dashboard[2]:", allDashboards[2]);
  mapping dashboardContent;

  for (int i = 1; i <= dynlen(allDashboards); i++)  // Ensure loop starts at 1 and goes up to total length
  {
    //DebugTN("Loop iteration index i:", i);  // Should print 1 and 2


    //DebugTN("Dashboard Data Retrieved:", allDashboards[i]);
    dashboardContent = allDashboards[i];

    if (!dashboardContent.isEmpty())
    {
      //DebugTN("Creating Dashboard:", dashboardContent, " at index:", i);

      //Ahmed: check here the dashboard name and start it from 100 for example
      CreateDashboard(dashboardContent, i);
      //Ahmed: check here the dashboard name and start it from 100 for example
      dashboardNames = dashboardNames + "_Dashboard_00000" + i + ",";

    }
    else
    {
      //Ahmed: check here the dashboard name and start it from 100 for example
      CreateStandardInfo(PRIO_SEVERE, 1, "Dashboard entry is empty at index: " + i);
      // DebugTN("Dashboard entry is empty at index", i);
    }
  }

  dpSet("System1:CurrentCreatedDashboards.", dashboardNames);
}


CreateDashboard(mapping Dashboard, int dashboardNumber)
{

  dyn_string keys = mappingKeys(Dashboard); // Get all keys in the mapping
  //DebugTN("AllDashboard", Dashboard);

  CreateTheDashboardMainInfo(Dashboard["name"], Dashboard["description"], dashboardNumber);

  dyn_anytype widgets = Dashboard["widgets"];
  //DebugTN("mycurrentWidgetArray", widgets);
  delay(1);
  CreateTheDashboardWidgets(widgets, dashboardNumber);
// //DebugTN("dashboard[\"widgets\"]", Dashboard["widgets"]);
// //DebugTN("final//Debug", Dashboard["name"], Dashboard["description"], Dashboard["widgets"]);

}

CreateTheDashboardMainInfo(string dashboardName, string dashboardDescription, int dashboardNumber)
{
  string dataPoint = "_Dashboard_00000" + dashboardNumber;
  string dataPointType = "_Dashboard";

// Check if the data point exists
  if (!dpExists(dataPoint))
  {
    // Create the data point if it does not exist
    if (dpCreate(dataPoint, dataPointType))
    {

      //DebugTN("Dashboard Data point created: " + dataPoint);
    }
    else
    {
      //DebugTN("Failed to create Dashboard data point: " + dataPoint);
    }
  }
  else
  {
    //DebugTN("Dashboard Data point already exists: " + dataPoint);
  }


  dpSet(dataPoint + ".isPublished", 1);
  dpSet(dataPoint + ".id", dashboardNumber);
//create the dashboard
  string name = dashboardName;
  string description = dashboardDescription;

  // Create the dashboard with the specified JSON structure
  string dashboardJson = "{\"name\":{\"en_US.utf8\":\"" + name + "\"},"
                         "\"description\":{\"en_US.utf8\":\"" + description + "\"},"
                         "\"presentation\":{\"margin\":null,"
                         "\"backgroundColor\":{\"color\":\"rgba(255,255,255,1)\",\"useDifferentColors\":true,\"darkModeColor\":\"rgba(19,19,19,1)\"},"
                         "\"transparentWidgets\":false},"
                         "\"rangeSelectorValue\":{\"state\":\"undefined\"},"
                         "\"icon\":null,\"showInMenu\":false}";
  //DebugTN("dashboardJson", dashboardJson);
  dpSet(dataPoint + ".settings", dashboardJson);
  CreateStandardInfo(PRIO_INFO, 1, "A dashboard with name: " + name + " has been created successfully");
}


CreateTheDashboardWidgets(dyn_anytype widgets, int dashboardNumber)
{
  dyn_string AllWidgets;
  //DebugTN("widgetsAfterFunctionCall", widgets);
  string dataPoint = "_Dashboard_00000" + dashboardNumber;

  for (int i = 1 ; i <= dynlen(widgets) ; i++)
  {
    mapping myWidget = widgets[i];
    //  //DebugTN("myWidget" + i, myWidget);
    //DebugTN("myWidget[", myWidget["type"] == "gauge");

    //case Gauge
    if (myWidget["type"] == "gauge")
    {
      //DebugTN("I strrted appending gauge ");
      string gaugeWidgetId, gaugeWidgetY, gaugeWidgetRows, gaugeWidgetX, gaugeWidgetCols, gaugeDataPath, gaugeRangeType, gaugeMaxValue, gaugeMinValue, gaugeWidgetTitle;
      gaugeWidgetId = GenerateRandomID();
      gaugeWidgetY = myWidget["y"];
      gaugeWidgetX = myWidget["x"];
      gaugeWidgetRows = myWidget["rows"];
      gaugeWidgetCols = myWidget["cols"];
      gaugeDataPath = myWidget["dataPoint"];
      gaugeWidgetTitle = myWidget["title"];

      //handling the case that we do not have a range setting in the widget
      if (myWidget.contains("rangeSettings"))
      {
        mapping rangeSettings = myWidget["rangeSettings"];
        //gaugeMaxValue, gaugeMinValue, gaugeWidgetTitle, gaugeWidgetId;

        if (rangeSettings.contains("max"))
          gaugeMaxValue = rangeSettings["max"];
        else
          gaugeMaxValue = 100;

        if (rangeSettings.contains("min"))
          gaugeMinValue = rangeSettings["min"];
        else
          gaugeMinValue = 0;

        if (rangeSettings.contains("type"))
          gaugeRangeType = rangeSettings["type"];
        else
          gaugeRangeType = "manual";

      }
      else
      {

        //gaugeMaxValue, gaugeMinValue, gaugeWidgetTitle, gaugeWidgetId;

        gaugeMaxValue = 100;
        gaugeMinValue = 0;
        gaugeRangeType = "manual";

      }

      //DebugTN("ok until now");
      //DebugTN("gaugeDataPath", gaugeDataPath);
      string nametest = GetDPName(gaugeDataPath, "gauge");
      // DebugTN("nametest",nametest,"gaugeDataPath",gaugeDataPath);

      bool pvRangeExists = checkForPVRangeAvailability(nametest);

      //DebugTN("pvRangeExists",pvRangeExists);
      if (gaugeRangeType == "oa")
      {
        if (!pvRangeExists)
        {
          DebugTN("The PV Range config is not existing, therefore \"oa\" config can not used for the range config of the gauge, the manual configs will be used instead");
          gaugeRangeType = "manual";
        }

      }

      //DebugTN("nametest", nametest);
      // Create the gauge widget JSON
      string gaugeWidgetJson = "{\"id\":\"" + gaugeWidgetId + "\",\"y\":" + gaugeWidgetY + ",\"rows\":" + gaugeWidgetRows + ",\"x\":" + gaugeWidgetX + ",\"cols\":" + gaugeWidgetCols + ",\"name\":\"WUI_gauge.Widget.gauge.label\",\"minItemCols\":6,\"minItemRows\":6,\"settings\":{\"type\":\"gauge\",\"data\":{\"dataPath\":\"" + GetDPName(gaugeDataPath) + "\",\"dataType\":\"float\",\"isCnsNode\":false},\"chartOptions\":{\"formatSettings\":{\"value\":\"\",\"type\":\"oa\"},\"unitSettings\":{\"type\":\"oa\",\"value\":\"\"},\"rangeSettings\":{\"type\":\"" + gaugeRangeType + "\",\"max\":\"" + gaugeMaxValue + "\",\"min\":" + gaugeMinValue + "}},\"jsonFileName\":\"gauge\",\"generalSettings\":{\"title\":{\"name\":{\"en_US.utf8\":\"" + gaugeWidgetTitle + "\"},\"queryName\":false,\"nameSource\":\"manual\"},\"subtitle\":{\"name\":null,\"queryName\":false,\"nameSource\":\"manual\"},\"background\":{\"customBackground\":false,\"backgroundColor\":{\"color\":\"\",\"useDifferentColors\":false,\"darkModeColor\":\"\"}}},\"generalDataSettings\":{\"statusInfo\":{\"badge\":false}},\"id\":\"" + gaugeWidgetId + "\"}}";
      AllWidgets.append(gaugeWidgetJson);
      //DebugTN("I appended gauge successfully");
    }

    //case Label
    else if (myWidget["type"] == "label")
    {
      string labelWidgetId, labelWidgetY, labelWidgetRows, labelWidgetX, labelWidgetCols, labelDataPath, labelWidgetTitle ;
      labelWidgetId = GenerateRandomID();
      //DebugTN("labelWidgetId", labelWidgetId);
      labelWidgetY = myWidget["y"];
      labelWidgetX = myWidget["x"];
      labelWidgetRows = myWidget["rows"];
      labelWidgetCols = myWidget["cols"];
      labelDataPath = myWidget["dataPoint"];
      labelWidgetTitle = myWidget["title"];



      // Create the label widget JSON
      string labelWidgetJson = "{\"id\":\"" + labelWidgetId + "\",\"y\":" + labelWidgetY + ",\"rows\":" + labelWidgetRows + ",\"x\":" + labelWidgetX + ",\"cols\":" + labelWidgetCols + ",\"name\":\"WUI_label.Widget.label.label\",\"minItemCols\":6,\"minItemRows\":3,\"settings\":{\"type\":\"label\",\"data\":{\"dataPath\":\"" + GetDPName(labelDataPath, "label")  + "\",\"dataType\":\"float\",\"isCnsNode\":false},\"queryPostfix\":false,\"queryAlertConfig\":true,\"formatSettings\":{\"value\":\"\",\"type\":\"oa\"},\"jsonFileName\":\"label\",\"iconSizeFactor\":0.5,\"generalSettings\":{\"title\":{\"name\":{\"en_US.utf8\":\"" + labelWidgetTitle + "\"},\"queryName\":false,\"nameSource\":\"manual\"},\"subtitle\":{\"name\":null,\"queryName\":false,\"nameSource\":\"manual\"},\"background\":{\"customBackground\":false,\"backgroundColor\":{\"color\":\"\",\"useDifferentColors\":false,\"darkModeColor\":\"\"}}},\"generalDataSettings\":null,\"valuePrefix\":null,\"valuePostfix\":null,\"fontColor\":{\"color\":\"rgb(var(--color-base000))\",\"useDifferentColors\":false,\"darkModeColor\":\"rgb(var(--color-base000))\"},\"fontSizeFactor\":0.75,\"icon\":\"\",\"iconAlign\":0,\"iconPosition\":0,\"id\":\"" + labelWidgetId + "\"}}";

      AllWidgets.append(labelWidgetJson);
      //DebugTN("I appended label successfully");
    }

    //case Trend
    else if (myWidget["type"] == "trend")
    {
      string trendWidgetId, trendWidgetY, trendWidgetRows, trendWidgetX, trendWidgetCols, trendDataPath, trendWidgetTitle ;
      trendWidgetId = GenerateRandomID();
      trendWidgetY = myWidget["y"];
      trendWidgetX = myWidget["x"];
      trendWidgetRows = myWidget["rows"];
      trendWidgetCols = myWidget["cols"];
      trendDataPath = myWidget["dataPoint"];
      trendWidgetTitle = myWidget["title"];



      // Create the trend widget JSON
      string trendWidgetJson = "{\"id\":\"" + trendWidgetId + "\",\"y\":" + trendWidgetY + ",\"rows\":" + trendWidgetRows + ",\"x\":" + trendWidgetX + ",\"cols\":" + trendWidgetCols + ",\"name\":\"WUI_trend.Widget.trend.label\",\"minItemCols\":8,\"minItemRows\":8,\"settings\":{\"type\":\"trend\",\"data\":[{\"dataPath\":\"" + GetDPName(trendDataPath, "trend") + "\",\"dataType\":\"float\",\"isCnsNode\":false}],\"chartOptions\":{\"rangeSelector\":{\"show\":true,\"default\":\"60min\"},\"stacked\":false,\"xAxis\":{\"axisLabel\":{\"interval\":2,\"rotate\":30},\"type\":\"time\",\"splitLine\":{\"show\":true}},\"legend\":{\"show\":true,\"position\":\"bottomright\"},\"tooltip\":{\"show\":true},\"series\":[{\"name\":{\"name\":null,\"queryName\":true,\"nameSource\":\"description\",\"nameDataPath\":\"" + GetDPName(trendDataPath, "trend") + "\"},\"type\":\"line\",\"symbol\":\"none\",\"yAxis\":{\"show\":true,\"use\":-1,\"position\":\"left\",\"rangeSettings\":{\"type\":\"auto\",\"max\":\"100\",\"min\":\"0\"}},\"areaStyle\":{\"area\":false},\"dpe\":{\"dataPath\":\"" + GetDPName(trendDataPath, "trend") + "\",\"dataType\":\"float\",\"isCnsNode\":false},\"transition\":\"step\",\"confidence\":false,\"compress\":true,\"lineStyle\":{\"type\":\"solid\",\"width\":2,\"color\":{\"color\":\"#235461\",\"useDifferentColors\":false,\"darkModeColor\":\"#235461\"}},\"formatSettings\":{\"value\":\"\",\"type\":\"oa\"},\"unitSettings\":{\"type\":\"oa\",\"value\":{\"en_US.utf8\":\"\"}}}],\"yAxis\":{\"type\":\"value\",\"splitLine\":{\"show\":true},\"rangeSource\":\"auto\",\"valueFrom\":null,\"valueTo\":null},\"grid\":{\"top\":\"40\",\"bottom\":\"60\"},\"dataZoom\":[{\"type\":\"insidex\",\"start\":0,\"end\":100},{\"type\":\"\",\"start\":0,\"end\":100}]},\"jsonFileName\":\"linechart\",\"generalSettings\":{\"title\":{\"name\":{\"en_US.utf8\":\"" + trendWidgetTitle + "\"},\"queryName\":false,\"nameSource\":\"manual\"},\"subtitle\":{\"name\":null,\"queryName\":false,\"nameSource\":\"manual\"},\"background\":{\"customBackground\":false,\"backgroundColor\":{\"color\":\"\",\"useDifferentColors\":false,\"darkModeColor\":\"\"}}},\"id\":\"" + trendWidgetId + "\"}}";


      AllWidgets.append(trendWidgetJson);
      //DebugTN("I appended trend successfully");
    }

    //case Pie

    else if (myWidget["type"] == "pie")
    {
      dyn_string PieDatapoints = myWidget["dataPoints"], Piedescription = myWidget["dataPointsDescription"];
      string pieWidgetId, pieWidgetY, pieWidgetRows, pieWidgetX, pieWidgetCols, pieDataPath, pieWidgetTitle, totalDatapointsString = "", totalDescriptionString = "";
      dyn_string arrayOfColors;
      dyn_string arrayOfDarkColors;
      arrayOfColors.append("#123123", "#006FE6", "#BBD0D7", "#265461", "#016FE6", "#BBC0D7");
      arrayOfDarkColors.append("#123123", "#006FE6", "#BBD0D7", "#265461", "#016FE6", "#BBC0D7");

      pieWidgetId = GenerateRandomID();
      pieWidgetY = myWidget["y"];
      pieWidgetX = myWidget["x"];
      pieWidgetRows = myWidget["rows"];
      pieWidgetCols = myWidget["cols"];

      pieWidgetTitle = myWidget["title"];


////////////////////////////////////////////
      //create the Pie names
      totalDatapointsString = "[";

      for (int i = 1 ; i <= dynlen(PieDatapoints) ; i++)
      {
        totalDatapointsString = totalDatapointsString + "{\"dataPath\":\"" + GetDPName(PieDatapoints[i]) + "\",\"dataType\":\"float\",\"isCnsNode\":false}";

        if (i != dynlen(PieDatapoints))
          totalDatapointsString = totalDatapointsString + ",";
      }

      totalDatapointsString = totalDatapointsString + "]";
      //DebugTN("totalDatapointsString", totalDatapointsString);

      //create the Pie descriptions

      totalDescriptionString =  "[";

      for (int i = 1 ; i <= dynlen(Piedescription) ; i++)
      {
        if (i == 1)
        {
          totalDescriptionString = totalDescriptionString + "{\"name\":{\"name\":{\"en_US.utf8\":\"" + Piedescription[i] + "\"},\"queryName\":false,\"nameSource\":\"manual\"},\"dpe\":{\"dataPath\":\"" + GetDPName(PieDatapoints[i]) + "\",\"dataType\":\"float\",\"isCnsNode\":false},\"color\":{\"color\":\"" + arrayOfColors[i] + "\",\"useDifferentColors\":false,\"darkModeColor\":\"" + arrayOfDarkColors[i] + "\"},\"formatSettings\":{\"value\":\"%0.2f\",\"type\":\"oa\"},\"unitSettings\":{\"type\":\"oa\",\"value\":{\"en_US.utf8\":\"\"}}}";
          //DebugTN("totalDatapointsString" + i, totalDescriptionString);
        }
        else
        {
          totalDescriptionString = totalDescriptionString + "{\"name\":{\"name\":{\"en_US.utf8\":\"" + Piedescription[i] + "\"},\"queryName\":false,\"nameSource\":\"manual\"},\"dpe\":{\"dataPath\":\"" + GetDPName(PieDatapoints[i]) + "\",\"dataType\":\"float\",\"isCnsNode\":false},\"color\":{\"color\":\"" + arrayOfColors[i] + "\",\"useDifferentColors\":false,\"darkModeColor\":\"" + arrayOfDarkColors[i] + "\"},\"formatSettings\":{\"value\":\"%0.0d\",\"type\":\"oa\"},\"unitSettings\":{\"type\":\"oa\",\"value\":{\"en_US.utf8\":\"\"}}}";
          //DebugTN("totalDatapointsString" + i, totalDescriptionString);
        }

        if (i != dynlen(Piedescription))
        {
          totalDescriptionString = totalDescriptionString + ",";
          //DebugTN("totalDatapointsString" + i, totalDescriptionString);
        }
      }



      totalDescriptionString = totalDescriptionString + "]";
      /////////////////////////////////////


// Create the pie widget JSON
      string pieWidgetJson = "{\"id\":\"" + pieWidgetId + "\",\"y\":" + pieWidgetY + ",\"rows\":" + pieWidgetRows + ",\"x\":" + pieWidgetX + ",\"cols\":" + pieWidgetCols + ",\"name\":\"WDK_pie.Widget.pie.label\",\"minItemCols\":6,\"minItemRows\":6,\"settings\":{\"type\":\"pie\",\"data\":" + totalDatapointsString + ",\"chartOptions\":{\"series\":" + totalDescriptionString + ",\"legend\":{\"show\":true,\"orient\":\"vertical\",\"position\":\"topright\"},\"tooltip\":{\"show\":true},\"chartType\":{\"type\":\"pie\",\"pieRadius\":50,\"radius\":[25,75],\"roseType\":\"area\"},\"label\":{\"show\":true,\"position\":\"outside\",\"formatter\":\"value\"},\"labelLine\":{\"show\":true}},\"jsonFileName\":\"pie\",\"generalSettings\":{\"title\":{\"name\":{\"en_US.utf8\":\"" + pieWidgetTitle + "\"},\"queryName\":false,\"nameSource\":\"manual\"},\"subtitle\":{\"name\":null,\"queryName\":false,\"nameSource\":\"manual\"},\"background\":{\"customBackground\":false,\"backgroundColor\":{\"color\":\"\",\"useDifferentColors\":false,\"darkModeColor\":\"\"}}},\"id\":\"" + pieWidgetId + "\"}}";



      AllWidgets.append(pieWidgetJson);
      //DebugTN("I appended pie successfully");
    }

    //DebugTN("I finished creating the dashboard");
    dpSet(dataPoint + ".widgets", AllWidgets);


  }


}
bool checkForPVRangeAvailability(string dpName)
{
  bool pvRangeExists = false;
  int pvRangeType;
  dpGet(dpName + ":_pv_range.._type", pvRangeType);

//DebugTN("pvRangeType",pvRangeType);
  if (pvRangeType == DPCONFIG_NONE)
  {
    // No PV range config is set
    // Handle the case accordingly
    pvRangeExists = false;

  }
  else
  {
    pvRangeExists = true;
  }

  return pvRangeExists;
}

string GenerateRandomID()
{
  string randomString = "";
  dyn_string myarraysIDs;
  dpGet("System1:dashboardIds.", myarraysIDs);


  string validCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  int charCount = strlen(validCharacters);


  for (int i = 0; i < charCount; i++)
  {
    int randomIndex = rand() % charCount; // Generate a random index
    randomString += validCharacters[randomIndex]; // Get the character at the index
  }

  //DebugN("Generated Random String:", randomString + (string)getCurrentTime());

  if (dynlen(myarraysIDs) == 0)
  {
    dynAppend(myarraysIDs, randomString);
    dpSet("System1:dashboardIds.", myarraysIDs);
    //DebugTN("randomString coming from empty:", randomString + (string)getCurrentTime());
    return randomString + (string)getCurrentTime();
  }
  else
  {

    bool foundId = false;

    for (int i = 1; i <= dynlen(myarraysIDs); i++)
    {
      if (myarraysIDs[i] == randomString)
      {

        randomString = randomString + 2500 * rand();
        dynAppend(myarraysIDs, randomString);
        dpSet("System1:dashboardIds.", myarraysIDs);
        foundId = true;
        //DebugTN("randomString coming from found:", randomString + (string)getCurrentTime());
        return randomString + (string)getCurrentTime();
      }

    }

    if (! foundId)
    {
      dynAppend(myarraysIDs, randomString);
      dpSet("System1:dashboardIds.", myarraysIDs);
      foundId = true;
      //DebugTN("randomString coming from not found:", randomString + (string)getCurrentTime());
      return randomString + (string)getCurrentTime();
    }
  }

  return randomString + (string)getCurrentTime();
}





CreateStandardInfo(int logImportance, int seQuenceNumber, string errorMessage, string logCategory = "ITOT_LOG", int  logType = ERR_PARAM)
{
  errClass retError;
  retError = makeError(logCategory, logImportance, logType, seQuenceNumber, errorMessage); /* Function call.*/

  int i = throwError(retError);
//  DebugTN(  throwError(retError)); /* Outputs the error message */

}





























