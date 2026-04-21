#uses "pmon"
#uses "classes/projectEnvironment/ProjEnvPmonComponent"
#uses "var"

const int MAN_STATE_UNKNOWN = -1;
const int MAN_STATE_NOT_RUNNING = 0;
const int MAN_STATE_INIT = 1;
const int MAN_STATE_RUNNING = 2;
const int MAN_STATE_BLOCKED = 3;


const string MAN_START_MODE_MANUAL = "manual";
const string MAN_START_MODE_ALWAYS = "always";
const string MAN_START_MODE_ONCE = "once";

int wwwThreadId = -1;

const int PROJ_RUNNING_STATE_DOWN = 0;
const int PROJ_RUNNING_STATE_STARTING = 1;
const int PROJ_RUNNING_STATE_MONITORING = 2;
const int PROJ_RUNNING_STATE_STOPPING = 3;

int insertManager(const mapping &opts, int manIdx = -1, int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  DebugTN(__FUNCTION__, manIdx, opts);
  if ( manIdx < 0 )
    manIdx = dynlen(getListOfManagerOptions());

  string data = "SINGLE_MGR:INS " + manIdx +
      " " + mappingGetValueDflt(opts, "Component", getComponentName(UI_COMPONENT)) +
        " " + pmonStartModeToStr(mappingGetValueDflt(opts, "StartMode", MAN_START_MODE_MANUAL)) +
        " " + mappingGetValueDflt(opts, "SecondToKill", 20) +
        " " + mappingGetValueDflt(opts, "Restart", 2) +
        " " + mappingGetValueDflt(opts, "ResetStartCounter", 2) +
        " " + mappingGetValueDflt(opts, "StartOptions", "");
  data = user + "#" + pw + "#" + data;

  if ( _pmonGet(host, port, data) == NULL )
    return -1;

  return manIdx;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function starts manager at the given idx. Index begin with 1. Pmon has idx 0 in progs file

  @param manIdx manager index
  @param port pmon port
  @param host pmon host
  @return errorcode
*/
int startManager(int manIdx, int port = pmonPort(), string host = "localhost")
{
  string url = "http://" +  host + ":" + port + "/SINGLE_MGR";
  string data = "idx=" + manIdx + "&START='Start'";
  mapping result, input = makeMapping("content", data);
  if ( netPost(url, input, result) )
  {
    DebugTN(__FUNCTION__, url, input, result);
    return -1;
  }
  return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function stopped manager at the given idx. Index begin with 1. Pmon has idx 0 in progs file

  @param manIdx manager index
  @param port pmon port
  @param host pmon host
  @return errorcode
*/
int stopManager(int manIdx, int port = pmonPort(), string host = "localhost")
{
  string url = "http://" +  host + ":" + port + "/SINGLE_MGR";
  string data = "idx=" + manIdx + "&STOP='Stop'";
  mapping result, input = makeMapping("content", data);
  if ( netPost(url, input, result) )
  {
    return -1;
  }
  return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function kills manager at the given idx. Index begin with 1. Pmon has idx 0 in progs file

  @param manIdx manager index
  @param port pmon port
  @param host pmon host
  @return errorcode
*/
int killManager(int manIdx, int port = pmonPort(), string host = "localhost")
{
  string url = "http://" +  host + ":" + port + "/SINGLE_MGR";
  string data = "idx=" + manIdx + "&KILL='Kill'";
  mapping result, input = makeMapping("content", data);
  if ( netPost(url, input, result) )
  {
    DebugTN(__FUNCTION__, url, input, result);
    return -1;
  }
  return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function deletes manager at the given idx. Index begin with 1. Pmon has idx 0 in progs file

  @param manIdx manager index
  @param port pmon port
  @param host pmon host
  @return errorcode
*/
int deleteManager(int manIdx, int port = pmonPort(), string host = "localhost")
{
  string url = "http://" +  host + ":" + port + "/SINGLE_MGR";
  string data = "idx=" + manIdx + "&DEL='Del'";
  mapping result, input = makeMapping("content", data);
  if ( netPost(url, input, result) )
  {
    DebugTN(__FUNCTION__, url, input, result);
    return -1;
  }
  return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function returns manager info as mapping.

  @param idx index of manager. The manager with index 0 is the pmon
  @param port pmon port
  @param host pmon host
  @param user project user name
  @param pw project user password
  @return mapping with manager information. In case of error returns empty mapping
*/
mapping getManagerInfo(int idx, int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  if ( idx < 0 )
    return makeMapping();

  idx++; // because manager list started with pmon
  dyn_mapping managers = getListOfManagersStati(port, host, user, pw);

  if ( idx > dynlen(managers) )
    return makeMapping();

  return managers[idx];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function returns manager state

  @param idx index of manager. The manager with index 0 is the pmon
  @param port pmon port
  @param host pmon host
  @param user project user name
  @param pw project user password
  @return manager state. See constants MAN_STATE_*
*/
int getManagerStatus(int idx, int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  return mappingGetValueDflt(getManagerInfo(idx, port, host, user, pw), "State", -1);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function returns manager PID

  @param idx index of manager. The manager with index 0 is the pmon
  @param port pmon port
  @param host pmon host
  @param user project user name
  @param pw project user password
  @return manager PID. When manager is not running return -1;
*/
int getManagerPid(int idx, int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  return mappingGetValueDflt(getManagerInfo(idx, port, host, user, pw), "Pid", -1);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function returns manager start time

  @param idx index of manager. The manager with index 0 is the pmon
  @param port pmon port
  @param host pmon host
  @param user project user name
  @param pw project user password
  @return manager start time.
*/
int getManagerStartTime(int idx, int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  return mappingGetValueDflt(getManagerInfo(idx, port, host, user, pw), "StartTime", -1);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function returns list of all managers

  ! The manager with index 1 is the pmon.

  @param port pmon port
  @param host pmon host
  @param user project user name
  @param pw project user password
  @return list with all managers. In case of err is empty dyn_mapping
*/
dyn_mapping getListOfManagersStati(int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  string data = user + "#" + pw + "#MGRLIST:STATI";
  dyn_string answer = _pmonGet(host, port, data);

  if ( dynlen(answer) < 2 )  /* content : LIST:9 <states> 2 MONITOR_MODE 0 1 ;*/
    return makeDynMapping();

  dynRemove(answer, dynlen(answer));
  dynRemove(answer, dynlen(answer));

  dyn_mapping list;
  for(int i = 1; i <= dynlen(answer); i++)
  {
    string line = answer[i];
    // 1 - state
    // 2 - pid
    // 3 - start mode
    // 4 - startTime
    // 5 - Manager number

    dyn_string items = strsplit(line, ";");
    if ( dynlen(items) != 5 )
      return makeDynMapping();

    string state = items[1];
    string pid = items[2];
    string startMode = items[3];
    string startTime = items[4];
    string manNo = items[5];

    strRemove(pid, " ");
    mapping map = makeMapping("State", (int)state,
                              "Pid", (int)pid,
                              "StartMode", (int)startMode,
                              "StartTime", (time)startTime,
                              "Number", (int)manNo);

    dynAppend(list, map);
  }
  return list;
}


/**
  @param idx
  @param port
  @param host
  @param user
  @param pw
  @return
*/
mapping getManagerOptions(int idx, int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  if ( idx < 0 )
    return makeMapping();

  idx++; // because manager list started with pmon
  dyn_mapping managers = getListOfManagerOptions(port, host, user, pw);
  if ( idx > dynlen(managers) )
    return makeMapping();

  return managers[idx];
}

dyn_mapping getListOfManagerOptions(int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  string data = user + "#" + pw + "#MGRLIST:LIST";
  dyn_string answer = _pmonGet(host, port, data);

  if ( dynlen(answer) < 1 )  /* content : LIST:9\n<states>\n;*/
    return makeDynMapping();

  dynRemove(answer, dynlen(answer));

  dyn_mapping list;
  for(int i = 1; i <= dynlen(answer); i++)
  {
    string line = answer[i];
    // 1 - component (manager name)
    // 2 - start mode
    // 3 - second to kill
    // 4 - Restart
    // 5 - resert start Count
    // 6 - startOptions

    dyn_string items = strsplit(line, ";");
    if ( dynlen(items) == 5 )
      dynAppend(items, ""); // options are empty

   if ( dynlen(items) != 6 )
      return makeDynMapping();

    mapping map = makeMapping("Component", items[1],
                              "StartMode", (int)items[2],
                              "SecondToKill", (int)items[3],
                              "Restart", (int)items[4],
                              "ResetStartCounter", (int)items[5],
                              "StartOptions", items[6]);

    dynAppend(list, map);
  }
  return list;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
int changeManagerOptions(int idx, const mapping &opts, int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  if ( mappingHasKey(opts, "") )
    return -1;

  mapping currOpts = getManagerOptions(idx, port, host, user, pw);
  if ( mappinglen(currOpts) <= 0 )
    return -2;

  addMapping(currOpts, opts);
  if ( setManagerOptions(idx, currOpts, port, host, user, pw) )
    return -3;

  return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function set the manager options
  @param idx indes of manager
  @param opts mapping with options

  key               | default value | description
  ------------------|---------------|-------------
  StartMode         | 0             | Use pmon constants PMON_START_ALWAYS, PMON_START_MANUAL, PMON_START_ONCE
  SecondToKill      | 20            |
  Restart           | 2             |
  ResetStartCounter | 2             |
  StartOptions      | ""            |

  @param port pmon port
  @param host pmon host
  @param user project user name
  @param pw project user password
  @return erroCode. Allways 0
*/
int setManagerOptions(int idx, const mapping &opts, int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  DebugTN(__FUNCTION__, idx, opts);
  string data = "SINGLE_MGR:PROP_PUT " + idx +
    //  " " + mappingGetValueDflt(opts, "Component", 0) +  // manager name not changeable
        " " + pmonStartModeToStr(mappingGetValueDflt(opts, "StartMode", 0)) +
        " " + mappingGetValueDflt(opts, "SecondToKill", 20) +
        " " + mappingGetValueDflt(opts, "Restart", 2) +
        " " + mappingGetValueDflt(opts, "ResetStartCounter", 2) +
        " " + mappingGetValueDflt(opts, "StartOptions", "");
  data = user + "#" + pw + "#" + data;

  anytype answer = _pmonGet(host, port, data);
  return 0;
}



//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function checks if the pmon is running
  @param port pmon port
  @param host pmon host
  @param user project user name
  @param pw project user password
  @return TRUE when pmon is running, else false
*/
bool isPmonRunning(int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  string data = user + "#" + pw + "#PROJECT:";
  string answer = _pmonGet(host, port, data);

  return ( answer != "" );
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function checks if the project is running.
  @param projName project name
  @param port pmon port
  @param host pmon host
  @param user project user name
  @param pw project user password
  @return TRUE when pmon is running, else false
*/
bool isProjRunning(string projName, int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  string data = user + "#" + pw + "#PROJECT:";
  string answer = _pmonGet(host, port, data);

  return ( answer != projName );
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function stop the Project. !the pmon musst be on living at the time.

  @param port pmon port
  @param host pmon host
  @return errCode. 0 == OK
*/
int startProject(int port = pmonPort(), string host = "localhost")
{
  string url = "http://" +  host + ":" + port + "/";
  string data = "START_ALL='Start Project'";
  mapping result, input = makeMapping("content", data);
  if ( netPost(url, input, result) )
  {
    DebugTN(__FUNCTION__, url, input, result);
    return -1;
  }
  return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function stop the Project, but the pmon are still on living after them. Stop only all proj managers

  @param port pmon port
  @param host pmon host
  @return errCode. 0 == OK
*/
int stopProject(int port = pmonPort(), string host = "localhost")
{
  string url = "http://" +  host + ":" + port + "/";
  string data = "STOP_ALL='Stop Project'";
  mapping result, input = makeMapping("content", data);
  if ( netPost(url, input, result) )
  {
    DebugTN(__FUNCTION__, url, input, result);
    return -1;
  }
  return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function restart the Project. Staopp all managers and start it again

  @param port pmon port
  @param host pmon host
  @return errCode. 0 == OK
*/
int restartProject(int port = pmonPort(), string host = "localhost")
{
  string url = "http://" +  host + ":" + port + "/";
  string data = "RESTART_ALL='Restart Project'";
  mapping result, input = makeMapping("content", data);
  if ( netPost(url, input, result) )
  {
    DebugTN(__FUNCTION__, url, input, result);
    return -1;
  }
  return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function returns the pmon project status

  @param port pmon port
  @param host pmon host
  @param user project user name
  @param pw project user password
  @return pmon project status (2 == Monitoring project)
*/
int getProjectStatus(string property = "status", int port = pmonPort(), string host = "localhost", string user = "", string pw = "")
{
  string data = user + "#" + pw + "#MGRLIST:STATI";
  dyn_string answer = _pmonGet(host, port, data);

  if ( dynlen(answer) < 2 )  /* content : LIST:9 <states> 2 MONITOR_MODE 0 1 ;*/
    return -2;

  int status    = -1;
  int emergency = -1;
  int demo      = -1;

  int index = dynlen(answer) - 1;

  string line = answer[index];
  string text;

  sscanf(line, "%d %s %d %d", status, text, emergency, demo);

  if ( property == "status" )
    return status;
  else if ( property == "emergency" )
    return emergency;
  else if ( property == "demo" )
    return demo;
  else
    return "";
}


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function start the pmon for this project. !!! work only locale
  @param projName project name
  @param autoStart shall start project automatically. Per default NO
  @return errCode. 0 == OK
  @todo mRosner, 28.09.2017: use pmonComponent
*/
int startPmon(string projName, bool autoStart = FALSE)
{
  string autostart = autoStart ? "" : " -noAutostart";
  string cmd, stdOut, stdErr;

  if ( _WIN32 )
    cmd = "start /b " + makeNativePath(getPath(BIN_REL_PATH, getComponentName(PMON_COMPONENT) + ".exe")) + " -PROJ " + projName + autostart;
  else
    cmd = makeNativePath(getPath(BIN_REL_PATH, getComponentName(PMON_COMPONENT))) + " -PROJ " + projName + autostart + " &";

  if ( system(cmd, stdOut, stdErr) )
  {
    DebugN(stdOut, stdErr);
    throwError(makeError("", PRIO_SEVERE, ERR_CONTROL, 0, __FUNCTION__ + " :: project (" + projName + ")can not be started ", cmd));
    return -1;
  }

  return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function stop the pmon. !Stop whole project and pmon.
  ! work only locale.

  @param projName project name.
  @return errCode. 0 == OK
*/
int stopPmon(string projName)
{
  ProjEnvPmonComponent pmon = ProjEnvPmonComponent();
  pmon.setProj(projName);

  if ( pmon.stop() )
  {
    DebugN(__FUNCTION__, pmon);
    return -3;
  }
  return 0;
}


//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
                                                                                PRIVATE
*/
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Internal function to make httpGet for pmon. Because pmon does understand only httpPost

  @param host pmon host
  @param port pmon port
  @param cmd command
  @return answer from httpGet
*/
private anytype _pmonGet(string host, int port, string cmd)
{
  int tcpTimeOut = 5;

  DebugFTN(__FUNCTION__, __FUNCTION__,host, port, tcpTimeOut, cmd);
  int socket = tcpOpen(host, port, tcpTimeOut);
  if ( dynlen(getLastError()) )
  {
    DebugTN(__FUNCTION__, "can not open conection", socket, host, port, tcpTimeOut);
    if ( socket != -1 )
      tcpClose(socket);
    return NULL;
  }

  cmd += "\n";
  if ( (tcpWrite(socket, cmd) < 0) || dynlen(getLastError()) )
  {
    DebugTN(__FUNCTION__, "can not write cmd", socket, cmd);
    tcpClose(socket);
    return NULL;
  }

  bool finish = FALSE;
  bool isList =FALSE;
  string answer;
  int readCount = 0;
  int expListCount;
  dyn_string list;
  do
  {
    string result;
    if ( tcpRead(socket, result, tcpTimeOut) )
    {
      DebugTN(__FUNCTION__, "can not read data", socket, result, tcpTimeOut);
      tcpClose(socket);
      return NULL;
    }
    DebugFTN(__FUNCTION__, __FUNCTION__, "result", result);
    answer += result;

    if ( readCount == 0 )
    {
      isList = strStartWith(answer, "LIST:");
      if ( isList )
      {
        expListCount = substr(answer, strlen("LIST:"), strpos(answer, "\n"));
      }
    }

    DebugFTN(__FUNCTION__, __FUNCTION__, "isList", isList, "expListCount", expListCount);
    if ( !isList )
    {
      finish = TRUE;
    }
    else
    {
      list = strsplit(answer, "\n");
      dynRemove(list, 1);
      if ( dynlen(list) > expListCount )
        finish = TRUE;
    }

    readCount++;
  }
  while( !finish );

  tcpClose(socket);

  if ( isList )
    return list;
  else
    return answer;
}
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function opens the project web overview

  @param projName project name.
*/
void startProjectWebOverview(string projName)
{
  wwwThreadId = getThreadId();
  int port;
  string host;
  paGetProjHostPort(projName, host, port);

  string url = "http://" + host + ":" + port+ "/";
  if ( isFunctionDefined("openUrl") )
    openUrl(url);
  else
    openUrlFromCtrl(url);

  if ( !_WIN32 )
    wwwThreadId = -1;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
  Function opens the project web overview from CTRL

  @param url
*/
int openUrlFromCtrl(string url)
{
  string cmd = url;

  if ( _WIN32 )
    cmd = "start " + cmd;
  else
    cmd = WINCCOA_BIN_PATH + " xdg-open " + url;

  string stdOut, stdErr;
  if ( system(cmd, stdOut, stdErr) )
    return -1;

  return 0;
}
