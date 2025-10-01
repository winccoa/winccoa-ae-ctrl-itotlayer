// $License: NOLICENSE 
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author atw121x7
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/**
*/

const string DPE_DATAPOINTIDMAPPING = "aMQTT.mapping_dataPointId";
const int SIM_INTERVALL = 10;
mapping mSimValues;

main()
{
//   this.enabled(FALSE);
  dpConnect("configurationChangedCB", TRUE, DPE_DATAPOINTIDMAPPING);
  startThread("doSim");
}

configurationChangedCB(string s, string sJson)
{
  dyn_mapping dm = jsonDecode(sJson);
  DebugN("json",sJson, dm);
  mapping mDPEs = dm[3];
  dyn_string dsDPEs = mappingKeys(mDPEs);

  synchronized(mSimValues)
  {
    mSimValues = makeMapping("FLOAT", makeDynMapping(),"BOOL", makeDynMapping(),"INT", makeDynMapping());
    for(int i = dynlen(dsDPEs); i>0; i--)
    {
      anytype aVal;
      string sType;
      if (strpos(dsDPEs[i], "Float") > 0)
      {
        sType = "FLOAT";
        aVal = 0.0 + ((12*i)%100);
      }
      if (strpos(dsDPEs[i], "Int") > 0)
      {
        sType = "INT";
        aVal = 0 + ((12*i)%100);
      }
      if (strpos(dsDPEs[i], "Bool") > 0)
      {
        sType = "BOOL";
        aVal = FALSE + i%2;
      }
      dynAppend(mSimValues[sType],makeMapping("dpe",dsDPEs[i], "value", aVal));
    }
  }
}

doSim()
{
  int iDiff;
  delay(2);
  while(1)
  {
    dyn_string dsDPEs;
    dyn_anytype daVals;

    synchronized(mSimValues)
    {
      dyn_string dsTypes = mappingKeys(mSimValues);
      for(int i=dynlen(dsTypes); i>0; i--)
      {
        for (int j=dynlen(mSimValues[dsTypes[i]]); j > 0; j--)
        {
          iDiff++;
          if(iDiff > 10)
            iDiff=1;
          if (dsTypes == "BOOL")
          {
            mSimValues[dsTypes[i]][j]["value"] = iDiff%2;
          }
          else
          {
            if ( mSimValues[dsTypes[i]][j]["value"] >= 100)
               mSimValues[dsTypes[i]][j]["value"] = mSimValues[dsTypes[i]][j]["value"] * 0; //keep data type
            else
              mSimValues[dsTypes[i]][j]["value"] += iDiff;
          }

          dynAppend(dsDPEs, mSimValues[dsTypes[i]][j]["dpe"]);
          dynAppend(daVals, mSimValues[dsTypes[i]][j]["value"]);
        }
      }
      dpSet(dsDPEs, daVals);
      DebugN("set vals", dsDPEs, daVals);
    }
    delay(SIM_INTERVALL);
  }
}
