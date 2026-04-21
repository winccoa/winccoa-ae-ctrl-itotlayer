
////////////////////////////////////////////////////////////////////////////////////////////////////

// string sONL    = ":_online.._value";
// string sSUB    = ".Subscriptions.";
// string sDrvCfg = "_FocasConfig";

const int FOCAS_SUBINDEX_MIN      =  0;
const int FOCAS_SUBINDEX_MAX_1001 =  7;
const int FOCAS_SUBINDEX_MAX_1011 = 15;
const int FOCAS_SUBINDEX_MAX_1012 = 31;

////////////////////////////////////////////////////////////////////////////////////////////////////

paFocasUpdatePanelFromDpc(string dpe, int Id, anytype dpc)
{
  string     sConnection, sTransArt, sPollGroup, sRef;
  int        iDriver, iOffset, iLowLevelComp, iIndex, iModus, iEinAus, iTransArt, iSubIndex;
  bool       bActive;
  dyn_string dsConnections;

  dsConnections = dpNames(dpSubStr(dpe, DPSUB_SYS)+"*", "_FocasConnection");
  sConnection = substr(dpSubStr(dpc[13], DPSUB_DP), strlen("_"));

  for ( iIndex = dynlen(dsConnections); iIndex > 0; iIndex-- )
    if ( isReduDp(dsConnections[iIndex]))
      dynRemove(dsConnections, iIndex);

  if ( dynlen(dsConnections) > 0 )
  {
    for ( iIndex = 1; iIndex <= dynlen(dsConnections); iIndex++ )
    {
      dsConnections[iIndex] = dpSubStr(dsConnections[iIndex], DPSUB_DP);
      dsConnections[iIndex] = substr(dsConnections[iIndex], strlen("_"), strlen(dsConnections[iIndex]) - 1);
    }
  }
  else
  {
    dyn_float  df;
    dyn_string ds;

    ChildPanelOnCentralModalReturn("vision/MessageWarning",
                                   getCatStr("para","warning"),
                                   makeDynString(getCatStr("para", "apc_noequipment")),
                                   df, ds);

    dpSetWait(myUiDpName()+".Para.OpenConfig", "",
              myUiDpName()+".Para.ModuleName", myModuleName());
  }

  int iPos = dynContains(dsConnections, sConnection);

  sRef        = dpc[1];
  iSubIndex   = dpc[2];
  iTransArt   = dpc[7];
  sTransArt   = paFocasConvertTransformationToStr(iTransArt);
  iDriver     = dpc[9];
  iOffset     = dpc[10];
  sPollGroup  = dpc[11];
  bActive     = dpc[12];
  sConnection = substr(dpSubStr(dpc[13], DPSUB_DP), strlen("_"));

  paFocasSetSubIndex(iTransArt, iSubIndex);

  int modus = paFocasDecodeModeToPanel(dpc[3], iLowLevelComp, iEinAus, iModus);

  setMultiValue( "tfReference",      "text",           sRef,
                 "sbDriver",         "text",           iDriver,
                 "cmbTransArt",      "selectedText",   sTransArt,
                 "cbLowLevel",       "state", 0,       iLowLevelComp,
                 "cmbConnection",    "items",          dsConnections,
                 "cmbConnection",    "selectedPos",    (sConnection=="" && dynlen(dsConnections))?dynContains(dsConnections,dsConnections[1]):iPos,
                 "einaus",           "number",         iEinAus,
                 "einaus",           "itemEnabled", 0, false,
                 "einaus",           "itemEnabled", 2, false,
                 "modus",            "number",         iModus,
                 "cmbPollGroup",     "text",           sPollGroup,
                 "cboAddressActive", "state", 0,       bActive);

  frmPollGroup.visible = (modus==4);
  txtPollGroup.visible = (modus==4);
  cmbPollGroup.visible = (modus==4);
  cmdPollGroup.visible = (modus==4);

  if ( sConnection == "" )
    sConnection = cmbConnection.text;

  if ( dynContains(dsConnections, sConnection) < 1 )
  {

    dyn_float  df;
    dyn_string ds;

    ChildPanelOnCentralModalReturn("vision/MessageWarning",
                                   getCatStr("para", "warning"),
                                   makeDynString(getCatStr("para", "apc_nousedequipment")),
                                   df, ds);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

int paFocasDecodePanelToMode(int lowlevel, int einaus, int mode)
{
  int q = 3;  // initialize to input SQ

  if (einaus==1)
  {
    if (mode == 0)
      q = 4;                        // DP as input. Data will be polled.
    //else if (mode == 2)
    //  q = 9;                        // alarm currently not supported
  }

  if (q != 9 && lowlevel)
    q+=64;                    // + LLV (only for data)

  return q;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

int paFocasDecodeModeToPanel(int mode, int &lowlevel, int &einaus, int &iModus)
{
  unsigned q = mode;

  if (q >= 64)          // first decode lowlevel
  {
    q-=64;
    lowlevel=1;
  }
  else
    lowlevel=0;

  switch(q)
  {
    case 4:
      // input polling
      einaus = 1;
      iModus = 0;
      break;
    case 3:
      // input SQ
      einaus = 1;
      iModus = 1;
      break;
    /*
    case 9:
      // alarm currently not supported
      einaus = 1;
      iModus = 2;
      break;
    */
    default:
      einaus = 1;
      iModus = 1;
      break;
  }

  return q;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

paFocasUpdateDpcFromPanel(dyn_anytype &dpc)
{
  uint       uiMode;
  int        iDriver, iLowLevelComp, iModus, iEinAus, iTransArt, iSubIndex;
  bool       bActive;
  string     sRef, sConnection, sTransArt, sPollGroup;

  getMultiValue("tfReference",      "text",         sRef,
                "sbDriver",         "text",         iDriver,
                "cmbTransArt",      "selectedText", sTransArt,
                "cbLowLevel",       "state", 0,     iLowLevelComp,
                "cmbConnection",    "text",         sConnection,
                "einaus",           "number",       iEinAus,
                "modus",            "number",       iModus,
                "cmbPollGroup",     "text",         sPollGroup,
                "cboAddressActive", "state", 0,     bActive,
                "subindex",         "value",        iSubIndex);

  sConnection = "_" + sConnection;

  uiMode = paFocasDecodePanelToMode(iLowLevelComp, iEinAus, iModus);
  iTransArt = paFocasConvertTransformationToEnum(sTransArt);


  // fill the dyn_anytype
  dpc[1]  = sRef;
  dpc[2]  = iSubIndex;
  dpc[3]  = uiMode;
  dpc[7]  = iTransArt;
  dpc[8]  = globalAddressDrivers[dynContains(globalAddressTypes,globalAddressNew[paMyModuleId()])];
  dpc[9]  = iDriver;
  dpc[10] = 0; // offset
  dpc[11] = sPollGroup;
  dpc[12] = bActive;
  dpc[13] = sConnection;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

dyn_int paFocasCheckDrvNums()
{
  dyn_int diCheckedDrvNums;

  string sSys = getSystemName();
  dyn_int diCDMN, diCDMN_2;

  dpGet(sSys + "_Connections.Driver.ManNums:_online.._value", diCDMN);

  for ( int i = 1; i <= dynlen(diCDMN); i++ )
  {
    string sDrv;

    if ( dpExists(sSys + "_Driver" + diCDMN[i]) )
      dpGet(sSys + "_Driver" + diCDMN[i] + ".DT", sDrv);

    if ( sDrv == "Focas" || sDrv == "Focas" )
      dynAppend(diCheckedDrvNums, diCDMN[i]);
  }

  if ( isRedundant() )
  {
    dpGet(sSys + "_Connections_2.Driver.ManNums:_online.._value", diCDMN_2);

    for ( int i = 1; i <= dynlen(diCDMN_2); i++ )
    {
      string sDrv_2;

      if ( dpExists(sSys + "_Driver" + diCDMN_2[i]) )
        dpGet(sSys + "_Driver" + diCDMN_2[i] + "_2.DT", sDrv_2);

      if ( sDrv_2 == "Focas" || sDrv_2 == "FOCAS" )
        dynAppend(diCheckedDrvNums, diCDMN_2[i]);
    }
  }

  dynSort(diCheckedDrvNums);
  return diCheckedDrvNums;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

string paFocasConvertTransformationToStr(int i)
{
  string s;

  if      ( i == 1000 ) s = "default";
  else if ( i == 1001 ) s = "bit in byte";
  else if ( i == 1002 ) s = "int8";
  else if ( i == 1003 ) s = "int16";
  else if ( i == 1004 ) s = "int32";
  else if ( i == 1005 ) s = "uint8";
  else if ( i == 1006 ) s = "uint16";
  else if ( i == 1007 ) s = "uint32";
  else if ( i == 1008 ) s = "float";
  else if ( i == 1009 ) s = "double";
  else if ( i == 1010 ) s = "string";
  else if ( i == 1011 ) s = "bit in word";
  else if ( i == 1012 ) s = "bit in dword";
  else                  s = "default";

  return s;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

int paFocasConvertTransformationToEnum(string s)
{
  int i;

  if      ( s == "default"      ) i = 1000;
  else if ( s == "bit in byte"  ) i = 1001;
  else if ( s == "int8"         ) i = 1002;
  else if ( s == "int16"        ) i = 1003;
  else if ( s == "int32"        ) i = 1004;
  else if ( s == "uint8"        ) i = 1005;
  else if ( s == "uint16"       ) i = 1006;
  else if ( s == "uint32"       ) i = 1007;
  else if ( s == "float"        ) i = 1008;
  else if ( s == "double"       ) i = 1009;
  else if ( s == "string"       ) i = 1010;
  else if ( s == "bit in word"  ) i = 1011;
  else if ( s == "bit in dword" ) i = 1012;
  else                            i = 1000;

  return i;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

void paFocasSetSubIndex(int iTransArt, int iSubIndex)
{
  bool bSubIndexActive = ( iTransArt == 1001 || iTransArt == 1011 || iTransArt == 1012 );

  switch ( iTransArt )
  {
    case 1001:
      setValue("subindex", "maximum", FOCAS_SUBINDEX_MAX_1001);
      iSubIndex = (iSubIndex > FOCAS_SUBINDEX_MAX_1001) ? FOCAS_SUBINDEX_MAX_1001 : iSubIndex;
    break;

    case 1011:
      setValue("subindex", "maximum", FOCAS_SUBINDEX_MAX_1011);
      iSubIndex = (iSubIndex > FOCAS_SUBINDEX_MAX_1011) ? FOCAS_SUBINDEX_MAX_1011 : iSubIndex;
    break;

    case 1012:
      setValue("subindex", "maximum", FOCAS_SUBINDEX_MAX_1012);
      iSubIndex = (iSubIndex > FOCAS_SUBINDEX_MAX_1012) ? FOCAS_SUBINDEX_MAX_1012 : iSubIndex;
    break;

    default:
    break;
  }

  setMultiValue("subindex", "enabled", bSubIndexActive,
                "subindex", "value",   bSubIndexActive ? iSubIndex : 0,
                "ptSubIdx", "foreCol", bSubIndexActive ? "_3DText" : "_ButtonBarBackground");
}
