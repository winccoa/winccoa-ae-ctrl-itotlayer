//////////////////////////////////////////////////////////////////////////////
// If you want to include a new driver:
//
// 1. In scripts/userDrivers.ctl
//    add new item to dds[i] for names, types and drivers respectively below
//
// 2. In panels/para
//    copy and change address_skeleton.pnl to create a new para-panel for
//    a new driver
//    panel name must be: address_newdrivertype.pnl
//    (in our example below: address_tstdrv1.pnl)
//
//    IMPORTANT: don't change the script in the panel-attributes and the buttons!
//
// 3. In this script below
//    add new case selection ( in our example case "tstdrv1":)
//     into the next four functions
//      upDpGetAddress
//      upDpSetAddress
//      upWritePanelAllAddressAttributes
//      upReadPanelAllAddressAttributes
//    and write the appropriate commands
//
//    global variable used for the _address.. -attributes is
//      anytype dpc;
//        dpc[1]=reference;
//        dpc[2]=subindex;
//        dpc[3]=mode;
//        dpc[4]=start;
//        dpc[5]=interval;
//        dpc[6]=reply;
//        dpc[7]=datatype;
//        dpc[8]=drv_ident;
//        dpc[9]=driver;
//    you don't have to set all of them, use only the necessary elements!
//////////////////////////////////////////////////////////////////////////////
//
// be careful: always use the same number of driver elements
// (e.g. dyn_strings, cases, etc.)
//
//////////////////////////////////////////////////////////////////////////////
// The examples in this script use a copy of panels/para/address_sim.pnl
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// main calls the needed function
// fct = 1: upDpGetAddress
// fct = 2: upDpSetAddress
// fct = 3: upWritePanelAllAddressAttributes
// fct = 4: upReadPanelAllAddressAttributes
//////////////////////////////////////////////////////////////////////////////
#uses "focasDrvPara.ctl"

anytype main(string dpe, int Id, anytype dpc, int fct)
{
  bool ok, all_right;

  switch (fct)
  {
    case 1: upDpGetAddress(dpe, Id, dpc);
      break;
    case 2: upDpSetAddress(dpe, Id, dpc, all_right); dpc[99]=all_right;
      break;
    case 3: upWritePanelAllAddressAttributes(dpe, Id, dpc);
      break;
    case 4: upReadPanelAllAddressAttributes(dpe, Id, dpc, all_right); dpc[99]=all_right;
      break;
  }
  return (dpc);
}

//////////////////////////////////////////////////////////////////////////////
// this function reads the datapoint values
//////////////////////////////////////////////////////////////////////////////
upDpGetAddress(string dpe, int Id, anytype &dpc)
{
  int         datatype,driver;
  bool        active;
  char        mode;
  string      drv_ident,reference,config=paGetDpConfig(globalOpenConfig[Id]),
              sPollGroup, connection;
  unsigned    subindex,offset;

  switch (globalAddressOld[Id])
  {
    case "focas":
        dpGet(dpe+":"+config+".._active",     active,
              dpe+":"+config+".._reference",  reference,
              dpe+":"+config+".._subindex",   subindex,
              dpe+":"+config+".._mode",       mode,
              dpe+":"+config+".._datatype",   datatype,
              dpe+":"+config+".._drv_ident",  drv_ident,
              dpe+":"+config+".._offset",     offset,
              dpe+":"+config+".._poll_group", sPollGroup,
              dpe+":"+config+".._connection", connection,
              dpe+":_distrib.._driver",       driver);

        if ( strpos(sPollGroup, getSystemName()) != -1 )
          sPollGroup = dpSubStr(sPollGroup, DPSUB_DP);
        if ( sPollGroup[0] == "_" )
          sPollGroup = strltrim(sPollGroup, "_");
        else if ( sPollGroup[0]=="(" )
          sPollGroup = "";

        dpc[1]=reference;
        dpc[2]=subindex;
        dpc[3]=mode;
        dpc[7]=datatype;
        dpc[8]=drv_ident;
        dpc[9]=driver;
        dpc[10]=offset;
        dpc[11]=sPollGroup;
        dpc[12]=active;
        dpc[13]=connection;
      break;
    default: break;
  }
}

//////////////////////////////////////////////////////////////////////////////
upDpSetAddress(string dpe, int Id, dyn_anytype dpc, bool &all_right)
{
  bool       ok;
  string     config=paGetDpConfig(globalOpenConfig[Id]),dpn=dpSubStr(dpe,DPSUB_DP)+".";
  dyn_int    drivers;
  dyn_string sPara;

  switch (globalAddressOld[Id])
  {
    case "focas" :
        paErrorHandlingDpSet(
          dpSetWait(dpe+":_distrib.._driver",dpc[9]),all_right);
        if (all_right)
          paErrorHandlingDpSet(
            dpSetWait(dpe+":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
                      dpe+":"+config+".._reference",dpc[1],
                      dpe+":"+config+".._subindex",dpc[2],
                      dpe+":"+config+".._mode",dpc[3],
                      dpe+":"+config+".._datatype",dpc[7],
                      dpe+":"+config+".._offset",dpc[10],
                      dpe+":"+config+".._poll_group",(dpc[11]!="")?getSystemName()+"_"+dpc[11]:"",
                      dpe+":"+config+".._active",FALSE,
                      dpe+":"+config+".._connection",dpc[13],
                      dpe+":"+config+".._drv_ident",dpc[8]),all_right);
        if (all_right && dpc[12])
           paErrorHandlingDpSet(
             dpSetWait(dpe+":_address.._active",dpc[12]),all_right);
      break;
    default: break;
  }
}

//////////////////////////////////////////////////////////////////////////////
upWritePanelAllAddressAttributes(string dpe, int Id, anytype dpc)
{
  switch (globalAddressOld[Id])
  {
     case "focas":
      paFocasUpdatePanelFromDpc(dpe, Id, dpc);
      break;

    default:
      break;
  }
}

//////////////////////////////////////////////////////////////////////////////
upReadPanelAllAddressAttributes(string dpe, int Id, dyn_anytype &dpc, bool &readOK)
{
  readOK=true;
  switch (globalAddressOld[Id])
  {
    case "focas":
      paFocasUpdateDpcFromPanel(dpc);
      break;
    default:
      break;
  }
}
