#uses "CtrlPv2Admin"
#uses "pa"

////////////////////////////////////////////////////////////////////
// Functions for pmon
//
// 			pmon_command(bool &error, string command)
// string	pmon_getManDescript(string manName)wa
// 			getChildPanelCentralPosition(string FileName, int &x, int &y)
// int		pmon_getLanguages(dyn_string &langs, dyn_int &langids)
// 			pmonStartManager(bool &err, string projName, int manPos)
// 			pmonStopManager(bool &err, string projName, int manPos)
// 			pmonKillManager(bool &err, string projName, int manPos)
// 			pmonDebugManager(bool &err, string projName, int manPos, string dbgLevel)
// 			pmonChangeManagerProps(bool &err, string projName, int manPos, dyn_string props)
// 			pmonDeleteManager(bool &err, string projName, int manPos)
// 			pmonInsertManager(bool &err, string projName, int manPos, dyn_string props)
// 			pmonStartAllManager(bool &err, string projName)
// 			pmonStopAllManager(bool &err, string projName)
//
////////////////////////////////////////////////////////////////////

//!!!!!!!!!!! constants !!!!!!!!!!!!!!!
const  int    PA_TCP_TIMEOUT          = 6;
const  int    PA_TCP_TIMEOUT_LOCAL    = 2;
const  int    PA_ATTEMPTS             = 200;
const  int    PA_ATTEMPTS_LOCAL       = 100;
const  int    PA_TIMEOUT_PMON_RUNNING = 10;

//const  int    PA_DEFAULT_PORTNUMBER   = 4999;
const  string PA_DEFAULT_HOSTNAME     = "localhost";
const  string PA_DEBUG_LEVEL          = "PMON";

private bool g_PMonInitialized = false;

struct PaProjectInfo {
  string name;
  string version;
  int pmonStatus;
  string path;
};

// list of PaProjectInfo
private dyn_anytype g_ProjectInformationList;

private int paGetProjInfoList(dyn_anytype &projectInfoList)
{
  DebugFTN(PA_DEBUG_LEVEL, __FUNCTION__);

  dyn_string projectNames, projectVersions, projectPaths;
  paGetProjs(projectNames, projectVersions, projectPaths);

  int count = 0;
  dynClear(projectInfoList);

  for (int i = 1; i <= dynlen(projectNames); i++)
  {
    if (paVersionStringToNumeric(projectVersions[i]) == VERSION_NUMERIC)
    {
      PaProjectInfo projectInfo;
      projectInfo.name = projectNames[i];
      projectInfo.version = projectVersions[i];
      projectInfo.pmonStatus = -1; // we determine this later
      projectInfo.path = projectPaths[i];

      dynAppend(projectInfoList, projectInfo);
      count++;
    }
  }

  return count;
}

//-----------------------------------------------------------------------------
// Generates Windows Script which outputs a list of project names an
// their PMon status
//
// @echo off
//
// setlocal EnableDelayedExpansion
//
// set pmonexe=C:/Siemens/Automation/WinCC_OA/3.15/bin/WCCILpmon
// set projectNames=DemoApplication_3.15 DEVharry_315 DEV_315_stdlib
//
// (for %%d in (%projectNames%) do (
// 	%pmonexe% -proj %%d -status
// 	echo %%d: !errorlevel!
// ))
//-----------------------------------------------------------------------------
private string paGenerateIsPmonRunningWindowsScript(string pmonExeName)
{
  DebugFTN(PA_DEBUG_LEVEL, __FUNCTION__);
  string projectNamesSpaceSeparated;

  for (int i = 1; i <= dynlen(g_ProjectInformationList); i++)
  {
    if (paVersionStringToNumeric(g_ProjectInformationList[i].version) == VERSION_NUMERIC)
    {
      projectNamesSpaceSeparated += g_ProjectInformationList[i].name + " ";
    }
  }

  string script =
      "@echo off\n"
      "\n"
      "setlocal EnableDelayedExpansion\n"
      "\n"
      "set pmonexe=" + pmonExeName + "\n"
      "set projectNames=" + projectNamesSpaceSeparated + "\n"
      "\n"
      "(for %%d in (%projectNames%) do (\n"
      "  %pmonexe% -proj %%d -status\n"
      "  echo %%d:!errorlevel!\n"
      "))\n"
      "";

  return script;
}

private string paGenerateIsPmonRunningWindowsScriptFile()
{
  DebugFTN(PA_DEBUG_LEVEL, __FUNCTION__);

  string scriptFileName = getenv("TEMP") + "\\WinCCOA_GetProjectStates.cmd";
  file scriptFile = fopen(scriptFileName, "w");

  if (scriptFile == 0)
    return paIsPmonRunningNormal(projName);

  string scriptCode = paGenerateIsPmonRunningWindowsScript(paGetPMonExecutableFileName());
  DebugFTN(PA_DEBUG_LEVEL, "scriptCode", scriptCode);

  fputs(scriptCode, scriptFile);
  fclose(scriptFile);
  return scriptFileName;
}

private string paGetPMonExecutableFileName()
{
  string pvssPath = WINCCOA_PATH;
  return pvssPath + "bin/" + getComponentName(PMON_COMPONENT);
}

private bool paIsPmonRunningNormal(string projName)
{
  DebugFTN(PA_DEBUG_LEVEL, __FUNCTION__, projName);

  string pvssPath = WINCCOA_PATH;
  string logFileName = pvssPath + "log/paIsPmonRunning.log";

  string projVers;
  int result = paGetProjAttr(projName, "proj_version", projVers);

  if ( paVersionStringToNumeric(projVers) < VERSION_NUMERIC )
  {
    // Read pvss_path from configfile to start pmon of the correct (project's) version
    if (paGetProjAttr(projName, "pvss_path", pvssPath) == -1)
      return (false);
  }

  string command = paGetPMonExecutableFileName()
      + " -proj " + projName
      + " -status"
      + " -log +stderr >> " + logFileName + " 2>&1"; // add "-dbg all" before -log to get debug information

  DebugFTN(PA_DEBUG_LEVEL, "system()", "BEGIN");

  // possible PMon results:
  //   0 = running
  //   1 = starting
  //   3 = stopped
  //   4 = unknown
  result = system(command);
  DebugFTN(PA_DEBUG_LEVEL, "system()", "END");

  return result == 0 || result == 1;
}

public paRefreshProjectInformationList()
{
  if (g_PMonInitialized)
    return;

  DebugFTN(PA_DEBUG_LEVEL, __FUNCTION__);
  paGetProjInfoList(g_ProjectInformationList);

  string scriptFileName = paGenerateIsPmonRunningWindowsScriptFile();

  DebugFTN(PA_DEBUG_LEVEL, "int result = system(\"" + scriptFileName + "\", stdoutString);");
  string stdoutString;
  int result = system(scriptFileName, stdoutString);

  dyn_string stdoutLines = strsplit(stdoutString, '\n');
  DebugFTN(PA_DEBUG_LEVEL, "result", stdoutLines);

  // project in same order as filled by paGetProjInfoList()
  for (int i = 1; i <= dynlen(stdoutLines); i++)
  {
    dyn_string projectStatus = strsplit(stdoutLines[i], ':');

    if (dynlen(projectStatus) == 2)
    {
      string projectName = projectStatus[1];
      int pmonStatus = projectStatus[2];

      // just verify if the projects listed in g_ProjectInformationList have the same order as in stdoutLines
      if (g_ProjectInformationList[i].name != projectName)
      {
        DebugFTN(PA_DEBUG_LEVEL, "FATAL", "Project order wrong");
        break;
      }

      g_ProjectInformationList[i].pmonStatus = pmonStatus;
    }
  }

  DebugFTN(PA_DEBUG_LEVEL, "g_ProjectInformationList", g_ProjectInformationList);
  g_PMonInitialized = true;
}

private bool paIsPmonRunningViaWindowsScript(string projName)
{
  bool running = false;

  for (int i = 1; i <= dynlen(g_ProjectInformationList); i++)
  {
    if (g_ProjectInformationList[i].name == projName)
    {
      running = g_ProjectInformationList[i].pmonStatus == 0;
      break;
    }
  }

  DebugFTN(PA_DEBUG_LEVEL, __FUNCTION__, projName, running);
  return running;
}

//-----------------------------------------------------------------------------
// Determines if the PMon for projName is running or not.
//-----------------------------------------------------------------------------
bool paIsPmonRunning(string projName, bool forceUseLegacyFunction = true)
{
  if (_WIN32)
  {
    if (forceUseLegacyFunction)
    {
      return paIsPmonRunningNormal(projName);
    }
    else
    {
      paRefreshProjectInformationList();
      return paIsPmonRunningViaWindowsScript(projName);
    }
  }
  else
  {
    return paIsPmonRunningNormal(projName);
  }
}

paResetProjectInformationList()
{
  g_PMonInitialized = false;
  DebugFTN(PA_DEBUG_LEVEL, __FUNCTION__, g_PMonInitialized);
}

paWaitForPmon(string projName)
{
  int iTimeOut = 0;

  delay(0,200);
  while ( !paIsPmonRunning(projName) && (iTimeOut < PA_TIMEOUT_PMON_RUNNING) )
  {
    iTimeOut++;
    delay(1);
  }
}

//-----------------------------------------------------------------------------
// !!!!!!!!!!!!!!
//-----------------------------------------------------------------------------
paIsProjRunning(string projName, string &otherProject, bool &bRun, string sUser, string sPassword)
{
  file           fd;
  string         host;
  int            port, iErr;
  bool           err;
  dyn_dyn_string ddsResult;

  iErr = paGetProjHostPort(projName, host, port);
  otherProject = "";
  if ( iErr )
  {
    otherProject = "";
    bRun = false;
    return;
  }
  err = pmon_query(sUser+"#"+sPassword+"#PROJECT:", host, port, ddsResult, false, true);

  if ( err || dynlen(ddsResult) < 1 )
  {
    otherProject = "";
    bRun = false;
    return;
  }
  else
  if ( ddsResult[1][1] != projName )
  {
    otherProject = ddsResult[1][1];
    bRun = false;
    return;
  }
  else
  {
    otherProject = "";
    bRun = true;
    return;
  }
}

int paGetProjHostPort(string projName, string &host, int &port)
{
  int err = 0;
  string config, rec, sPort;
  file fd;
  dyn_string ds;

  err = paGetProjAttr(projName, "pmonPort", sPort); // ??? projName[@hostName]
  port = sPort;
  if ( port == 0 )
//    port = PA_DEFAULT_PORTNUMBER;
    port = pmonPort();

  err = paGetProjAttr(projName, "remoteHost", host);
  if ( host == "" )
    host = PA_DEFAULT_HOSTNAME;

  if ( err > 0 ) err = 0;
  return(err);
}

//-----------------------------------------------------------------------------
//-------------------------------------------------------------
// execute tcp command
//-------------------------------------------------------------
bool pmon_command(string command, string host, int port,
             bool showErrorDialog = false, bool openTcp = false)
{
  int          fd,
               iTimeOut = (host=="localhost"||host=="")?PA_TCP_TIMEOUT_LOCAL:PA_TCP_TIMEOUT;
  bool         error = false;
  string       result;
  dyn_anytype  daResult;
  dyn_errClass err;

  error = false;

  //#104535: Avoid Child Panel if function is used in CTRL - Manager
  if(myManType() != UI_MAN)
    showErrorDialog = false;

  if ( openTcp )
  {
    fd = tcpOpen(host, port);
    err = getLastError();
    if ( dynlen(err) >= 1 )
    {
      if ( fd != -1 )
        tcpClose(fd);  //Es könnte Verbindung übrig bleiben

      throwError(err);  //Ausgeben da nicht per Default ausgegeben
      if (showErrorDialog) errorDialog(err);
      return(true);
    }
  }
  else if ( gTcpFileDescriptor2 < 0 )
  {
    err = getLastError();
    if ( dynlen(err) )
    {
      throwError(err);
      if (showErrorDialog) errorDialog(err);
    }
    return(true);
  }
  else
  {
    fd = gTcpFileDescriptor2;
  }

  command += "\n";

  if ( tcpWrite(fd, command) == -1 )
  {
    err = getLastError();
    if ( openTcp && fd > -1 ) tcpClose(fd);// fd = -1;

    if ( dynlen(err) )
    {
      throwError(err);
      if (showErrorDialog) errorDialog(err);
    }
    return(true);
  }

  if ( tcpRead(fd, result, iTimeOut) == -1 )
  {
    err = getLastError();
    if ( openTcp && fd > -1 ) tcpClose(fd);// fd = -1;

    if ( dynlen(err) )
    {
      throwError(err);
      if (showErrorDialog) errorDialog(err);
    }
    return(true);
  }
//DebugN("pmon_command --- command",command,"gTcpFileDescriptor",gTcpFileDescriptor,"fd",fd);
//DebugN("result",result);

  if ( strltrim(strrtrim(result)) == "" && showErrorDialog )
  {
    pmon_warningOutput("errTcp", -1);
    error = true;
  }
  else
  if ( result != "OK" && showErrorDialog )
  {
    string code;

    sscanf(result, "ERROR %s", code);
    pmon_warningOutput(code, -1);

    error = true;
  }

  if ( openTcp && fd > -1 ) tcpClose(fd);
  return(error);
}
//-------------------------------------------------------------
// execute tcp query
//   MGRLIST:LIST  or
//   MGRLIST:STATI
//-------------------------------------------------------------
bool pmon_query(string command, string host, int port,
                dyn_dyn_string &ddsResult, bool showErrorDialog = false, bool openTcp = false )
{
  int          fd, iCount = 0, i, j = 0, ret,
               iTimeOut = (host=="localhost" || host=="")?PA_TCP_TIMEOUT_LOCAL:PA_TCP_TIMEOUT;
  bool         bAnswerFull = false, error = false;
  string       result, sTemp;
  dyn_string   ds1, ds2, dsRes;
  dyn_anytype  daResult;
  string gTcpFifo;
  dyn_errClass err;

  if(myManType() != UI_MAN)
    showErrorDialog = false;

//DebugN("pmon_query --- command",command, host, port, showErrorDialog, openTcp);
  if (openTcp)  //new connection should be open
  {
    float tcpTimeOut;

    if ((host == "localhost" || host == getHostname()) && _WIN32)
    {
      tcpTimeOut = 0.250;
    }
    else
      tcpTimeOut = 5;

    fd = tcpOpen(host, port, tcpTimeOut);
    err = getLastError();
    if (dynlen(err) >= 1)
    {
      if ( fd != -1 )
        tcpClose(fd);  //Es könnten sonst Verbindungen übrig bleiben

      throwError(err);   //Auf jeden Fall ausgeben da es nicht von selbst ausgegeben wird
      if (showErrorDialog) errorDialog(err);

      return(true);
    }
  }
  else if (gTcpFileDescriptor < 0)
  {
    err = getLastError();
    if (dynlen(err))
    {
      throwError(err);
      if (showErrorDialog) errorDialog(err);
    }
    return(true);
  }
  else
  {
    fd = gTcpFileDescriptor;
  }

  command += "\n";

  //Write command
  ret = tcpWrite(fd, command);
  err = getLastError();
  //DebugN("pmon_query --- tcpWrite ERROR",gTcpFileDescriptor,"command",command);

  if ((ret == -1) || (dynlen(err) >= 1)) //Error in tcpWrite
  {
    if (openTcp && (fd > -1))     //if was opened and is still open
      tcpClose(fd);               //close connection

    throwError(err);
    if (showErrorDialog) errorDialog(err);

    gTcpFifo = "";
    return(true);
  }

  sTemp = gTcpFifo;

  // reading all answer lines
  result = "-1";
  while ((result != "") && !bAnswerFull)   //do as long not all pieces where get
  {                                        //if result is emty the last tcpRead dit not get answer
    int ret;                               //this means there is nothing more to get

    result = "";  //Start with emty string, because tcpRead does not reset it
    ret = tcpRead(fd, result, iTimeOut);
    err = getLastError();
    //DebugN("tcpRead", ret, dynlen(err), strlen(result), iTimeOut);
    if ((ret == -1) || (dynlen(err)>=1)) //Error in tcpRead
    {
      //DebugN("pmon_query --- tcpRead ERROR",gTcpFileDescriptor,"fd",fd);
      throwError(err);
      if (showErrorDialog) errorDialog(err);

      if (openTcp && (fd > -1))     //if was opened and is still open
        tcpClose(fd);               //close connection

      gTcpFifo = "";
      return(true);
    }

    if (strpos(command, "#PROJECT") > 0)
    {
      //DebugN("--- gTcpFileDescriptor",gTcpFileDescriptor,"fd",fd);
      //DebugN("--- result",result);
      if (openTcp && (fd > -1))     //if was opened and is still open
        tcpClose(fd);               //close connection

      ddsResult[1][1] = result;
      gTcpFifo = "";
      return(false);
    }

    sTemp += result;  //Result with tcpRead could come in pieces

    //check out count of items
    ds1 = strsplit(sTemp, "\n");
    if ((dynlen(ds1) > 1) && (strpos(ds1[1],"LIST") == 0) && (iCount == 0))
    {
      sscanf(ds1[1],"LIST:%d", iCount);
      if (strpos(command, "#MGRLIST:STATI") > 0)
        iCount +=3;
      else
        iCount +=2;
    }
/*
    else
    if ( dynlen(ds1) > 1 && strpos(ds1[1],"LIST") != 0 )
    {
      dynClear(ddsResult);
      gTcpFifo = "";
      return(false);
    }
*/
    while ((dynlen(ds1) > 0) && (strpos(ds1[1], "LIST:") != 0))
    {
      dynRemove(ds1, 1);
    }

    if ((dynlen(ds1) == iCount) && (iCount > 0))  //All pieces where get
    {
      bAnswerFull = true;
      break;
    }
    else
    {
      delay(0,10);
    }
  }

  if (openTcp && (fd > -1))     //if was opened and is still open
    tcpClose(fd);               //close connection

  if (!bAnswerFull)     //Not all pieces where get
  {
    dynClear(ddsResult);
    //DebugN("--- gTcpFileDescriptor",gTcpFileDescriptor,"fd",fd);
    //DebugN("Answer not full",ds1);
    return(true);
  }

  //Create Result
  //DebugN("--- gTcpFileDescriptor",gTcpFileDescriptor,"fd",fd);
  //DebugN("Answer",sTemp);
  strreplace(sTemp, ds1[1]+"\n", "");
  for (i=2; i<dynlen(ds1); i++)
  {
    dsRes = strsplit(ds1[i], ";");
    ddsResult[++j] = dsRes;
    strreplace(sTemp, ds1[i]+"\n", "");
  }
  strreplace(sTemp, ds1[i]+"\n", "");

  gTcpFifo = sTemp;

  return(false);
}

//-------------------------------------------------------------
// get description of a manager ('clear text')
//-------------------------------------------------------------
string pmon_getManDescript(string manName)
{
  string descript;

  pmonClearLastError();

  if ( strpos(manName, ".exe") > 0 )
    manName = strrtrim(manName, ".exe");
  descript = getCatStr("managers", manName);

  if ( dynlen(getLastError()) )  descript = ""; // not found

  return descript;
}

//-------------------------------------------------------------
// calculate central position of a child panel
//-------------------------------------------------------------
getChildPanelCentralPosition(string FileName, int &x, int &y)
{
   int     PBreite,PHoehe;
   float   factor = 1.0;
   dyn_int di;

   di=getPanelSize(FileName);
   panelSize(myPanelName(),PBreite,PHoehe);

   x=(PBreite-di[1])/2/factor;
   y=(PHoehe-di[2]-20)/2/factor;
   if(x<0) x=0;
   if(y<0) y=0;
}

//-------------------------------------------------------------
// calculate central position of a module with panel
//-------------------------------------------------------------
getModuleCentralPosition(string FileName, int &x, int &y)
{
   int     SBreite,SHoehe;
   float   factor = 1.0;
   dyn_int di;

   di=getPanelSize(FileName);
   getScreenSize (SBreite, SHoehe);

   x=(SBreite-di[1])/2/factor;
   y=(SHoehe-di[2]-20)/2/factor;
//   y=100;
   if(x<0) x=0;
   if(y<0) y=0;
}

//-------------------------------------------------------------
// get all available languages in PVSS (reading from PVSS_PATH + "nls/lang.dir")
//-------------------------------------------------------------
int pmon_getLanguages(dyn_string &langs, dyn_int &langids)
{
  int    err = 0, langid;
  string langname, rec;
  file   fd = fopen(WINCCOA_PATH + "nls/lang.dir", "r");

  langs = makeDynString();
  langids = makeDynInt();
  if ( fd == 0 )
  {
    err = -1; return(err);
  }
  while ( !feof(fd) )
  {
    fgets(rec, 65535, fd);
    strreplace(rec, "\n", "");
    if ( strltrim(strrtrim(rec)) == "" || rec[0] == "#") continue;

    sscanf(rec, "%d%s", langid, langname);
    if ( langid == 254 || langid == 255 || langid == 65535 ) continue;

    dynAppend(langs, langname);
    dynAppend(langids, langid);
  }
  fclose(fd);
  return(err);
}

//-------------------------------------------------------------
// start manager at position manPos according properties saved in progs
//-------------------------------------------------------------
pmonStartManager(bool &err, string projName, int manPos, string sUser, string sPassword)
{
  string str, host;
  int    port, iErr = paGetProjHostPort(projName, host, port);
  dyn_dyn_anytype daResult;

  if ( iErr )
  {
    pmon_warningOutput("errHostOrPort", -1);
    err = true;
    return;
  }

  sprintf(str, "SINGLE_MGR:START %d", manPos);
  str = sUser+"#"+sPassword+"#"+str;

  err = pmon_command(str, host, port, true);
}

//-------------------------------------------------------------
// stop manager at position manPos
//-------------------------------------------------------------
pmonStopManager(bool &err, string projName, int manPos, string sUser, string sPassword)
{
  string str, host;
  int    port, iErr = paGetProjHostPort(projName, host, port);
  dyn_dyn_anytype daResult;

  if ( iErr )
  {
    pmon_warningOutput("errHostOrPort", -1);
    err = true;
    return;
  }

  sprintf(str, "SINGLE_MGR:STOP %d", manPos);
  str = sUser+"#"+sPassword+"#"+str;

  err = pmon_command(str, host, port, true);
}

//-------------------------------------------------------------
// terminate manager at position manPos (forced KILL)
//-------------------------------------------------------------
pmonKillManager(bool &err, string projName, int manPos, string sUser, string sPassword)
{
  string str, host;
  int    port, iErr = paGetProjHostPort(projName, host, port);
  dyn_dyn_anytype daResult;

  if ( iErr )
  {
    pmon_warningOutput("errHostOrPort", -1);
    err = true;
    return;
  }

  sprintf(str, "SINGLE_MGR:KILL %d", manPos);
  str = sUser+"#"+sPassword+"#"+str;

  err = pmon_command(str, host, port, true);
}

//-------------------------------------------------------------
// debug manager at position manPos with debug level dbgLevel
//-------------------------------------------------------------
pmonDebugManager(bool &err, string projName, int manPos, string dbgLevel, string sUser, string sPassword)
{
  string str, host;
  int    port, iErr = paGetProjHostPort(projName, host, port);
  dyn_dyn_anytype daResult;

  if ( iErr )
  {
    pmon_warningOutput("errHostOrPort", -1);
    err = true;
    return;
  }

  sprintf(str, "SINGLE_MGR:DEBUG %d ", manPos);
  str += dbgLevel;
  str = sUser+"#"+sPassword+"#"+str;

  err = pmon_command(str, host, port, true);
}

//-------------------------------------------------------------
// change manager properties at position manPos (excepting name)
//-------------------------------------------------------------
pmonChangeManagerProps(bool &err, string projName, int manPos, dyn_string props, string sUser, string sPassword)
{
  string str, host;
  int    port, iErr = paGetProjHostPort(projName, host, port);
  dyn_dyn_anytype daResult;

  if ( iErr )
  {
    pmon_warningOutput("errHostOrPort", -1);
    err = true;
    return;
  }

  str = "SINGLE_MGR:PROP_PUT " + manPos +
    //  " " + props[1] +  // manager name not changeable
        " " + props[2] +
        " " + props[3] +
        " " + props[4] +
        " " + props[5] +
        " " + props[6];
  str = sUser+"#"+sPassword+"#"+str;

  err = pmon_command(str, host, port, true);
}

//-------------------------------------------------------------
// remove manager at position manPos from progs
//-------------------------------------------------------------
bool pmonDeleteManager(bool &err, string projName, int manPos, string sUser, string sPassword)
{
  string str, host;
  int    port, iErr = paGetProjHostPort(projName, host, port);
  dyn_dyn_anytype daResult;

  if ( iErr )
  {
    pmon_warningOutput("errHostOrPort", -1);
    err = true;
    return(true);
  }

  sprintf(str, "SINGLE_MGR:DEL %d ", manPos);
  str = sUser+"#"+sPassword+"#"+str;

  err = pmon_command(str, host, port, true);
  return(true);
}

//-------------------------------------------------------------
// insert manager at position manPos with properties props
//-------------------------------------------------------------
bool pmonInsertManager(bool &err, string projName, int manPos, dyn_string props, string sUser, string sPassword)
{
  string str, host;
  int    port, iErr = paGetProjHostPort(projName, host, port);
  dyn_dyn_anytype daResult;

  if ( iErr )
  {
    pmon_warningOutput("errHostOrPort", -1);
    err = true;
    return(true);
  }

  str = "SINGLE_MGR:INS " + manPos +
        " " + props[1] +
        " " + props[2] +
        " " + props[3] +
        " " + props[4] +
        " " + props[5] +
        " " + props[6];
  str = sUser+"#"+sPassword+"#"+str;

  err = pmon_command(str, host, port, true);
  return(true);
}

//-------------------------------------------------------------
// start all managers according properties saved in progs
//-------------------------------------------------------------
pmonStartAllManager(bool &err, string projName, string sUser, string sPassword)
{
  string str, host;
  int    port, iErr = paGetProjHostPort(projName, host, port);
  dyn_dyn_anytype daResult;

  if ( iErr )
  {
    pmon_warningOutput("errHostOrPort", -1);
    err = true;
    return;
  }

  sprintf(str, "START_ALL:");
  str = sUser+"#"+sPassword+"#"+str;

  err = pmon_command(str, host, port, true);
  // keeping as last project
  iErr = paSetActProj(projName);
}

//-------------------------------------------------------------
// stop all managers
//-------------------------------------------------------------
pmonStopAllManager(bool &err, string projName, string sUser, string sPassword)
{
  string str, host;
  int    port, iErr = paGetProjHostPort(projName, host, port);
  dyn_dyn_anytype daResult;

  if ( iErr )
  {
    pmon_warningOutput("errHostOrPort", -1);
    err = true;
    return;
  }

  sprintf(str, "STOP_ALL:");
  str = sUser+"#"+sPassword+"#"+str;

  err = pmon_command(str, host, port, true);
}

//-------------------------------------------------------------
int pmonStartProject(int &err, string projectName, dyn_anytype moduleParams,
                     bool autostart, bool openConsole, string sUser, string sPassword,
                     bool openLogviewer)
{
  string  sPmon, sLog, sPvssPath, sConfig, consoleName, host, sss,
          otherProject = "", sAutostart = (autostart)?"":" -noAutostart";
  int     port, iErr, fd;
  bool    isRunning, startConsoleProcess = false;
  dyn_int di;
  dyn_errClass derr;

  paGetProjAttr(projectName, "pvss_path", sPvssPath);
  //paGetProjAttr(projectName, "PVSS_II", sConfig);
  iErr = paProjName2ConfigFile(projectName, sConfig);
  paIsProjRunning(projectName, otherProject, isRunning, sUser, sPassword);

  if (myManType() != UI_MAN)
  {
    if (openConsole)
    {
      //In a CTRL manager the console must be started by starting a control process
      startConsoleProcess = true;
      openConsole = false;
    }
  }

  if ( otherProject != "" )
  {
    err = -1;
    pmon_warningOutput("errOtherProject",// + " (Proj: " + otherProject + "),
                       err);
    return(err);
  }

  iErr = paGetProjHostPort(projectName, host, port);

  if ( !isRunning && !openConsole  )
  {
    if ( _WIN32 )
    {
      sPmon = sPvssPath + "\\bin\\"+getComponentName(PMON_COMPONENT)+" -config " + sConfig + " " + sAutostart;
      systemDetached(sPmon);
    }
    else
    {
      sPmon = sPvssPath + "/bin/"+getComponentName(PMON_COMPONENT)+" -PROJ " + projectName + " -config " + sConfig + " " + sAutostart;
      iErr = paGetProjAttr(projectName, "proj_path", sss);
      strreplace(sss,"\\","/");

      if ( sss[strlen(sss)-1] != "/" )
      {
        sss +="/";
      }

      sPmon += " >>"+sss+LOG_REL_PATH+getComponentName(PMON_COMPONENT)+"_"+getHostname()+".log 2>&1 &";
      system(sPmon);
    }

    paWaitForPmon(projectName);

    fd = tcpOpen(host, port);
    derr = getLastError();
    if ( dynlen(derr) >= 1 )
    {
      if ( fd != -1 )
        tcpClose(fd);  //Es könnte Verbindung übrig bleiben

      throwError(derr);  //Ausgeben da nicht per Default ausgegeben
      err = -1;
      gTcpFileDescriptor = -1;
      gTcpFileDescriptor2 = -1;
      pmon_warningOutput("pmon\uA7errOpenPort\uA7$1\uA7" + (string)port, err);

      return(err);
    }
    else
    {
      gTcpFileDescriptor = fd;
      gTcpHostName = host;
      gTcpPortNumber = port;
    }
    fd = tcpOpen(host, port);
    derr = getLastError();
    if ( dynlen(derr) >= 1 )
    {
      if ( fd != -1 )
        tcpClose(fd);  //Es könnte Verbindung übrig bleiben

      throwError(derr);  //Ausgeben da nicht per Default ausgegeben
      err = -1;
      if ( gTcpFileDescriptor > -1 ) tcpClose(gTcpFileDescriptor);
      gTcpFileDescriptor = -1;
      gTcpFileDescriptor2 = -1;
      pmon_warningOutput("pmon\uA7errOpenPort\uA7$1\uA7" + (string)port, err);

      return(err);
    }
    else
    {
      gTcpFileDescriptor2 = fd;
    }
  }
  else if ( isRunning && !openConsole)
  {
    if ( gTcpFileDescriptor < 0 )
    {
      fd = tcpOpen(host, port);
      derr = getLastError();
      if ( dynlen(derr) >= 1 )
      {
        if ( fd != -1 )
          tcpClose(fd);  //Es könnte Verbindung übrig bleiben

        throwError(derr);  //Ausgeben da nicht per Default ausgegeben
        err = -1;
        pmon_warningOutput("pmon\uA7errOpenPort\uA7$1\uA7" + (string)port, err);

        return(err);
      }
      else
      {
        gTcpFileDescriptor = fd;
        gTcpHostName = host;
        gTcpPortNumber = port;
      }
    }
    if ( gTcpFileDescriptor2 < 0 )
    {
      fd = tcpOpen(host, port);
      derr = getLastError();
      if ( dynlen(derr) >= 1 )
      {
        if ( fd != -1 )
          tcpClose(fd);  //Es könnte Verbindung übrig bleiben

        throwError(derr);  //Ausgeben da nicht per Default ausgegeben
        err = -1;
        pmon_warningOutput("pmon\uA7errOpenPort\uA7$1\uA7" + (string)port, err);

        return(err);
      }
      else
      {
        gTcpFileDescriptor2 = fd;
      }
    }
  }

  if ( openConsole )
  {
    pmonCreateConsoleName(consoleName);
    di=getPanelSize("projAdmin/console.pnl");
    gModuleParams[1]  = consoleName;
    gModuleParams[4]  = di[1];
    gModuleParams[5]  = di[2];
    gModuleParams[8]  = "Scale";
    gModuleParams[9]  = "projAdmin/console.pnl";
    gModuleParams[10] = "";
    gModuleParams[11] = makeDynString(projectName,sAutostart,sUser,sPassword);

    err = moduleOn(gModuleParams);
  }

  if ( openLogviewer )
  {
    pmonStartLogviewer(projectName, true);
  }
//!!!
//  gProjRuns[dynContains(gProjList,projectName)] = true;

  // keeping as last project
  if ( autostart )
    iErr = paSetActProj(projectName);

  if ( startConsoleProcess )
  {
    string command;
    if ( _WIN32 )
      command = "start /b cmd /c " + WINCCOA_PATH + BIN_REL_PATH +getComponentName(UI_COMPONENT)+ " -console";
    else
      command = WINCCOA_PATH + BIN_REL_PATH +getComponentName(UI_COMPONENT)+ " +config config.pa -console &";
    system(command);
  }

  return(err);
}

//.............................................................
pmonStartLogviewer(string projectName, bool bSingle = false)
{
  int          iErr;
  string       sPvssPath, sProjPath, sConfig, sLog,
               sLocLang = getLocale(getActiveLang()), sLang, sLangBack,
               sSingle = (bSingle)?" -single":"";

  paGetProjAttr(projectName, "proj_path", sProjPath);
  paGetProjAttr(projectName, "pvss_path", sPvssPath);
  //paGetProjAttr(projectName, "PVSS_II", sConfig);
  iErr = paProjName2ConfigFile(projectName, sConfig);

  sLang = paGetLogviewerLang(sConfig, sLocLang);
  pmonClearLastError();

  sLangBack = sLang;
  if ( sLang != sLocLang )
  {
    if ( sLang == "" )
    {
      sLang = sLocLang;
    }
  }

  if ( _WIN32 )
    sLog = "start /b " + sPvssPath + "\\bin\\" + getComponentName(LOGVIEWER_COMPONENT) + sSingle + " -config " + sConfig +
           " -lang " + sLang;
  else
    sLog = sPvssPath + "/bin/" + getComponentName(LOGVIEWER_COMPONENT) + sSingle + " -config " + sConfig +
           " -lang " + sLang + " &";

  system(sLog);

}
//.............................................................
pmonStartVersionLogviewer()
{
  string sProjPath = WINCCOA_PATH,
         sPvssPath = WINCCOA_PATH,
         sConfig   = WINCCOA_PATH + "/config/config",
         sLog, sLang, sLangBack, sLocLang;

  sLang = paGetLogviewerLang(sConfig, sLocLang);
  pmonClearLastError();

  sLangBack = sLang;
  if ( sLang != sLocLang )
  {
    if ( sLang == "" )
    {
      sLang = sLocLang;
    }
  }

  if ( _WIN32 )
    sLog = "start /b " + sPvssPath + "\\bin\\" + getComponentName(LOGVIEWER_COMPONENT) + " -config " + sConfig +
           " -lang " + sLang;
  else
    sLog = sPvssPath + "/bin/" + getComponentName(LOGVIEWER_COMPONENT) + " -config " + sConfig +
           " -lang " + sLang + " &";

  system(sLog);

}
//.............................................................
string paGetLogviewerLang(string sConfig, string sLocLang)
{
  int          iErr;
  string       sLang;
  dyn_string   dsLangs;

  iErr = paCfgReadValue(sConfig, "general", "lang",  sLang);
  iErr = paCfgReadValueList(sConfig, "general", "langs", dsLangs);
  if ( dynlen(dsLangs) < 1 )
  {
      return("");
  }
  else
  if ( dynContains(dsLangs, sLocLang) )
    return(sLocLang);
  else
  {
    if ( sLang != "" )
      return(sLang);
    else
      return(dsLangs[1]);
  }
}

//.............................................................
pmonStopLogviewer(string projectName)
{
  int     iErr;
  string  sPvssPath, sConfig, sLog;

  paGetProjAttr(projectName, "pvss_path", sPvssPath);
  //paGetProjAttr(projectName, "PVSS_II", sConfig);
  iErr = paProjName2ConfigFile(projectName, sConfig);

  if ( _WIN32 )
    sLog = "start /b " + sPvssPath + "\\bin\\" + getComponentName(LOGVIEWER_COMPONENT) + " -config " + sConfig + " -stop";
  else
    sLog = sPvssPath + "/bin/" + getComponentName(LOGVIEWER_COMPONENT) + " -config " + sConfig + " -stop &";

  system(sLog);
}

//-------------------------------------------------------------
int pmonStopProject(int &err, string projectName, bool closeModule = false)
{
  int     iErr;
  string  sPmon, sPvssPath, sConfig;

//setTrace(2);
  paGetProjAttr(projectName, "pvss_path", sPvssPath);
  //paGetProjAttr(projectName, "PVSS_II", sConfig);
  iErr = paProjName2ConfigFile(projectName, sConfig);

  if ( _WIN32 )
    sPmon = sPvssPath + "\\bin\\"+getComponentName(PMON_COMPONENT)+" -stopWait -config " + sConfig;
  else
    sPmon = sPvssPath + "/bin/"+getComponentName(PMON_COMPONENT)+" -stopWait -config " + sConfig;

  err = system(sPmon);
  if ( err )
  {
    pmon_warningOutput("errorStop", err);
    return(-1);
  }

  pmonStopLogviewer(projectName);

  if ( gTcpFileDescriptor > -1 )
  {
    tcpClose(gTcpFileDescriptor);
    gTcpFileDescriptor = -1;
  }
  if ( gTcpFileDescriptor2 > -1 )
  {
    tcpClose(gTcpFileDescriptor2);
    gTcpFileDescriptor2 = -1;
  }
  gTcpHostName = "";
  gTcpPortNumber = -1;
  return(0);
}

//-------------------------------------------------------------
pmonSetAuth(string projectName,
            string oldUserName, string oldPassword,
            string newUserName, string newPassword,
            int &err,
            bool errLog = false)
{
  int          iErr;
  string       sPmon, sPvssPath, sConfig;
  dyn_errClass dErr;

  paGetProjAttr(projectName, "pvss_path", sPvssPath);
  //paGetProjAttr(projectName, "PVSS_II", sConfig);
  iErr = paProjName2ConfigFile(projectName, sConfig);

  if ( iErr || sPvssPath == "" || sConfig == "" )
  {
    err = -99; return;
  }

  if ( _WIN32 )
    sPmon = sPvssPath + "\\bin\\" + getComponentName(PMON_COMPONENT);
  else
    sPmon = sPvssPath + "/bin/"   + getComponentName(PMON_COMPONENT);

  sPmon += " -config " + sConfig + " -auth";
  if ( oldUserName == "" )
    sPmon +=" \"\"";
  else
    sPmon += " \"" + oldUserName + "\"";
  if ( oldPassword == "" )
    sPmon +=" \"\"";
  else
    sPmon += " \"" + oldPassword + "\"";
  if ( newUserName == "" )
    sPmon +=" \"\"";
  else
    sPmon += " \"" + newUserName + "\"";
  if ( newPassword == "" )
    sPmon +=" \"\"";
  else
    sPmon += " \"" + newPassword + "\"";

  sPmon += " >>" + sPvssPath + "/log/"+getComponentName(PMON_COMPONENT)+"_"+getHostname()+".log 2>&1";

  err = system(sPmon);
}
//--------------------------------------------------------------------------
paVerifyPassword(string projName, string user, string password, int &iErr)
{
  pmonSetAuth(projName, user, password, user, password, iErr, false);
}

//-------------------------------------------------------------
pmonCreateConsoleName(string &consoleName)
{
  consoleName = "WinCC OA " + VERSION;
  return;
  int i = 1;

  while ( true )
  {
    if ( isModuleOpen("PVSS_Console_" + i) )
    {
      i++;
    }
    else
    {
      sprintf(consoleName, "PVSS_Console_%d", i);
      return;
    }
  }
}

//-------------------------------------------------------------
pmon_getLicense(bool &bLicense)
{
  string     tempfile = tmpnam();
  string     s;
  dyn_string ds, dss;
  string     code;
  string     command = WINCCOA_PATH+"bin/"+getComponentName(GETHW_COMPONENT)+" > "+tempfile+" 2>&1";

  bLicense = false;
  if ( _WIN32 )
    strreplace(command, "/", "\\");

  system(command);
  fileToString(tempfile , s);
  remove(  tempfile);

  ds = strsplit (  s, "=");

  code = ds[2];
  dss = strsplit(code, "\n");
  code = dss[1];

  strreplace(code, " \"", "");
  strreplace(code, "\"", "");
  strreplace(code, "\n", "");

  if ( access(WINCCOA_PATH + "shield", R_OK) == 0 )
  {
    fileToString(WINCCOA_PATH + "shield", s);
    ds = strsplit(code, " ");
    if ( dynlen(ds) > 0 &&
         strpos(s, ds[1]) > 0 &&
         strpos(s, ds[2]) > 0
       )
      bLicense = true;
  }
}
//-------------------------------------------------------------
pmon_warningOutput(string sMessage, int iError, ...)
{
  va_list      vaList;
  int          vaLen = va_start(vaList);
  string       projName = "";
  bool         bPVSS = true;
  string       sPATH;
  mixed        m;
  int          i, x, y;
  string       s;
  dyn_anytype  daResult;
  dyn_errClass dErr;

  for ( i = 1; i <= vaLen; i++ )
  {
    m = vaList[i];
    if ( getType(m) == STRING_VAR )
    {
      projName = m;
    }
    else
    if ( getType(m) == BOOL_VAR )
    {
      bPVSS = m;
    }
  }

  va_end(vaList);

  sPATH = (bPVSS)?"WINCCOA_PATH/":"PROJ_PATH/";

  s = (projName=="")?"":" (Proj: " + projName + ")";

  dErr = getLastError();
  if ( strpos(sMessage, "\uA7") > 0 )
  {
    dyn_string ds = strsplit(sMessage, "\uA7");
    if ( dynlen(ds) > 1 )
    {
      sMessage = getCatStr(ds[1], ds[2]);
      if ( dynlen(ds) > 3 )
        strreplace(sMessage, ds[3], ds[4]);
    }
  }
  else
    sMessage = getCatStr("pmon", sMessage);

  strreplace(sMessage, "\n", " ");
  if ( dynlen(dErr) )
  {
    sMessage += getCatStr("pmon", "seeInLog") + " ";
    sMessage += sPATH + LOG_REL_PATH + "PVSS_II.log";
    throwError(dErr);
  }
  else
  if ( sMessage == getCatStr("pmon", "errMissingProgs") ||
       sMessage == getCatStr("pmon", "errorStop") )
  {
    sMessage += getCatStr("pmon", "seeInLog") + " ";
    sMessage += sPATH + LOG_REL_PATH +getComponentName(PMON_COMPONENT)+"_"+getHostname()+".log";
  }

  sMessage += s;

  getChildPanelCentralPosition("vision/MessageWarning", x, y);
  gParams[1]  = myModuleName();
  gParams[2]  = "vision/MessageWarning";
  gParams[3]  = myPanelName();
  gParams[4]  = "";
  gParams[5]  = x;
  gParams[6]  = y;
  gParams[9]  = makeDynString(sMessage);
  childPanel(gParams, daResult);
}

//--------------------------------------------------------------------------
dyn_errClass pmon_makeError(int iCode, string sNote1 = "", string sNote2 = "", string sNote3 = "")
{
  if ( sNote1 == "" )
    return( makeError("pmon", PRIO_WARNING, ERR_SYSTEM, iCode));
  else
  if ( sNote2 == "" )
    return( makeError("pmon", PRIO_WARNING, ERR_SYSTEM, iCode, sNote1));
  else
  if ( sNote3 == "" )
    return( makeError("pmon", PRIO_WARNING, ERR_SYSTEM, iCode, sNote1, sNote2));
  else
    return( makeError("pmon", PRIO_WARNING, ERR_SYSTEM, iCode, sNote1, sNote2, sNote3));
}
//--------------------------------------------------------------------------
// This is a dummy function to clear lastError if it is not needed
//--------------------------------------------------------------------------
pmonClearLastError()
{
  bool bErr = checkScript("");
}

//--------------------------------------------------------------------------

int paCheckCopyReduSource(string sPath)
{
  int    iErr;
  string s, sConfig, dataConf, sProjPath, Hostname, Projname, sVer;

  if ( sPath == "" ) return(0);

  sPath = strrtrim(strltrim(sPath));
  if ( sPath[strlen(sPath)-1] == "/" )
    strrtrim(sPath, "/");
  crSource.text = sPath;

  sConfig = sPath + "/config/config";
  // is project valid?
  iErr = paCheckProj(sPath, 3); // PA_IS_PROJ_DIR
  pmonClearLastError();
  if ( iErr )
  {
    pmon_warningOutput("errServerProjNotValid", -1);
    resetFields();
    return(-1);
  }
  // is a remote project?
  iErr = paGetHostProjFromPath(sPath, Hostname, Projname);
  pmonClearLastError();
  if ( iErr || Projname == "" )
  {
    pmon_warningOutput("errEmptyProjectName", -1);
    resetFields();
    return(-1);
  }
  if ( !isDbgFlag("ETM_INTERNAL_ROBOT_CHECK_COPY_REDU") &&
       _WIN32 &&
       strtolower(Hostname) == strtolower(getHostname())
     )
  {
    pmon_warningOutput("errLocalServer", -1);
    resetFields();
    return(-1);
  }

  iErr = paGetRemoteProjAttr(sPath, "data", dataConf);
  if ( iErr )
  {
    pmon_warningOutput("errorGetProjAttr", -1);
    resetFields();
    return(-1);
  }
  else
  if ( strpos(dataConf, "$") < 0 )
  {
    pmon_warningOutput("reduProjNotRedu", -1);
    resetFields();
    return(-1);
  }

  iErr = paGetRemoteProjAttr(sPath, "proj_path", sProjPath);
  if ( iErr )
  {
    pmon_warningOutput("errorGetProjAttr", -1);
    resetFields();
    return(-1);
  }
  iErr = paGetRemoteProjAttr(sPath, "proj_version", sVer);
  if ( iErr || sVer != VERSION )
  {
    pmon_warningOutput("errVersion", -1);
    resetFields();
    return(-1);
  }

  strreplace(sProjPath, "\\", "/");
  iErr = paGetHostProjFromPath(sProjPath, Hostname, Projname);
  s = sProjPath;
  strreplace(s, Projname, "");

  gMap["crSource"] = sPath;
  gMap["crTarget"] = sProjPath;
  crTarget.text = sProjPath;

  if ( access(sProjPath, F_OK) == 0 )
  {
    pmon_warningOutput("errProjPathExists", -1);
    resetFields();
    return(-1);
  }

  string projInstallDir;
  iErr = paProjName2InstallDir (Projname, projInstallDir);
  pmonClearLastError();
  if ( !iErr )
  {
    pmon_warningOutput("errProjRegistered", -1);
    resetFields();
    return(-1);
  }


  return(0);
}
//.........................................................................
resetFields()
{
//  gMap["crSource"] = "";
//  gMap["crTarget"] = "";
//  crSource.text = "";
//  crTarget.text = "";
  setInputFocus(myModuleName(), myPanelName(), "cmdProjectRedu");
}
