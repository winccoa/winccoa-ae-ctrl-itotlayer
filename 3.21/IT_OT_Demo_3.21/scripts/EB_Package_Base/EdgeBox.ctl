// $License: NOLICENSE

// used libraries (#uses)
#uses "dbVersionUpdate"
#uses "classes/EBlog"
#uses "EB_Package_Base/EB_const"
#uses "EB_Package_Base/EB_UtilsFile"
#uses "EB_Package_Base/EB_UtilsPmon"
#uses "EB_Package_Base/PackageState"
#uses "EB_Package_Base/OA_Consts"
#uses "EB_Package_Base/EB_UtilsPackage"

/**
 * @brief Defines the possible manager actions, which are executed upon installing/updating a package
 */
enum ManagerAction
{
  Install,
  Remove,
  Restart
};

// declare variables and constants
const string PACKAGE_FILE_EXTENSION = ".ini";                                            //!< File extension of the package ini files
const string PACKAGE_REL_PATH       = DATA_REL_PATH + "packages/";                       //!< Relative path containing the package ini files
const string PACKAGE_PATTERN        = EB_PREFIX_PACKAGE + "*" + PACKAGE_FILE_EXTENSION;  //!< Pattern for the package ini files
const string PROJECT_STATE_FILE     = DATA_PATH + "packages/state.box";                  //!< File indicating that the project is complete up and running
const string LOG_REASON             = "ManagersRunning";                                 //!< Reason for the manager not running logs

const string MAPKEY_PACKAGE_CONFIG   = "config";                                         //!< Package key for the configuration
const string MAPKEY_PACKAGE_PMON     = "pmon";                                           //!< Package key for the pmon indexes
const string MAPKEY_PACKAGE_STATE    = "state";                                          //!< Package key for the pmon running state
const string MAPKEY_PACKAGE_TIME     = "time";                                           //!< Package key for the config time
const string MAPKEY_CONFIG_DESCRIPTION  = "Description";                                 //!< Package config key for the description
const string MAPKEY_CONFIG_DPLISTS      = "DpLists";                                     //!< Package config key for the ascii import lists
const string MAPKEY_CONFIG_EDITABLE     = "Editable";                                    //!< Package config key for if the package has an admin mode
const string MAPKEY_CONFIG_HEADER       = "Header";                                      //!< Package config key for the ?
const string MAPKEY_CONFIG_HOME_SCREEN  = "HomeScreen";                                  //!< Package config key for the location of the package tile
const string MAPKEY_CONFIG_LIBRARIES    = "Libs";                                        //!< Package config key for the libraries
const string MAPKEY_CONFIG_MANAGERS     = "Drivers";                                     //!< Package config key for the manager
const string MAPKEY_CONFIG_NAME         = "Name";                                        //!< Package config key for the id
const string MAPKEY_CONFIG_PANELS       = "Screens";                                     //!< Package config key for the panels
const string MAPKEY_CONFIG_PICTURE      = "TilePicture";                                 //!< Package config key for the tile picture
const string MAPKEY_CONFIG_SCRIPTS      = "Controls";                                    //!< Package config key for the scripts
const string MAPKEY_CONFIG_TILE_NAME    = "TileName";                                    //!< Package config key for the display name
const string MAPKEY_CONFIG_VERSION      = "Version";                                     //!< Package config key for the version

const string MAPKEY_MANAGERS_MANAGER    = "Driver";                                      //!< Package manager key for the manager
const string MAPKEY_MANAGERS_OPTIONS    = "Options";                                     //!< Package manager key for the options
const string MAPKEY_MANAGERS_ACTION     = "Action";                                      //!< Package manager key for the action flag
const string MAPKEY_SCRIPTS_SCRIPT      = "Script";                                      //!< Package script key for the options
const string MAPKEY_PANELS_DESCRIPTION  = "Description";                                 //!< Package panels key for the description
const string MAPKEY_PANELS_NAME         = "Name";                                        //!< Package panels key for the name
const string MAPKEY_PANELS_PATH         = "Path";                                        //!< Package panels key for the relative path
const string MAPKEY_DPLIST_TYPE_INSTALL = "Install";                                     //!< Ascii import file(s) for new installations
const string MAPKEY_DPLIST_TYPE_UPDATE  = "Update";                                      //!< Ascii import file(s) for updates


dyn_string g_dsMonitoredPaths;                                                           //!< Absolute file paths that are monitored for changes
dyn_string g_dsPackagesThatNeedsRestart;                                                 //!< MList of Packages that need an restart
EBlog      g_Log;                                                                        //!< Log instance for creating and removing logs

/**
 * @brief This is main routine
 */
void main()
{
  // First clear the project running state
  if (isfile(PROJECT_STATE_FILE))
  {
    remove(PROJECT_STATE_FILE);
  }

  sysConnect("exitRequestCB", "exitRequested");

  // check if edge system datapoint exists
  if (dynlen(dpTypes("edgeSystem")) == 0 && getPath(DPLIST_REL_PATH, "EdgeBoxComplete.dpl") != "") //avoid import of all dplist files
  {
    dbVU_doAsciiImport(getPath(DPLIST_REL_PATH, "EdgeBoxComplete.dpl"));
  }

  updateSystem();

  // Determine the installed packages
  dyn_string dsPaths = getDirectories(PACKAGE_REL_PATH);
  dynAppend(dsPaths, getFilesForMonitoring());
  for (int i = dynlen(dsPaths); i > 0; i--)
  {
    if (isfile(dsPaths[i]))
    {
      string sFileName = baseName(dsPaths[i]);
      time   tFileTime = getFileModificationTime(dsPaths[i]);

      packageUpdate(sFileName, tFileTime);
    }

    fswAddPath(dsPaths[i]);
  }

  sysConnect("pathChangedCB", "fswPathChanged");

  dynSort(dsPaths);
  g_dsMonitoredPaths = dsPaths;

  // Update the 'manager is not running' logs
  updateManagerLogs();

  string sQuery = "SELECT '_online.._value' FROM '_Connections.{Api,Ctrl,Device,Driver}.ManNums' WHERE _DPT = \"_Connections\"";

  dpQueryConnectSingle("managersCB", TRUE, "", sQuery);

  // Clean up after a package has been removed
  sQuery = "SELECT '.Status:_online.._value' FROM '" + EB_PREFIX_PACKAGE + "*'"
           " WHERE _DPT = \"" + EB_DPTYPE_PACKAGES + "\" AND _DP != \"_mp_" + EB_DPTYPE_PACKAGES + "\" AND '.Status:_online.._value' == " + (int)PackageState::Removed;

  dyn_dyn_anytype ddaTab;

  dpQuery(sQuery, ddaTab);
  packageDpRemoveCB("", ddaTab);

  // Write the running state to file
  file f = fopen(PROJECT_STATE_FILE, "w");

  if (f != 0)
  {
    fputs("RUNNING\n", f);
    fclose(f);
  }
}

/**
 * @brief Combines 2 equally sized dyns into a mapping
 * @param aUserData   Keys for the new mapping
 * @param ddaData Values for the new mapping
 */
void packageDpRemoveCB(const anytype &aUserData, const dyn_dyn_anytype &ddaData)
{
  for (int i = 2; i <= dynlen(ddaData); i++)
  {
    DebugFTN("RESTART", __FUNCTION__ + "() Removing package dp: " + ddaData[i][1]);

    dpDelete(ddaData[i][1]);
  }
}

/**
 * @brief Callback function for started/stopped managers
 * @details Used to update the following
 *  1) Highest control manager number (used for creating debug dps)
 *  2) Update the 'manager is not running' logs
 *  3) Remove managers from the pmon list
 * @param aUserData User data (not used)
 * @param ddaData   Result of the query
 */
void managersCB(const anytype &aUserData, const dyn_dyn_anytype &ddaData)
{
  int iMaxControlNumber;
  // Determine the highest control manager number
  for (int i = 2; i <= dynlen(ddaData); i++)
  {
    if (strpos((string)ddaData[i][1], ".Ctrl.ManNums") >= 0)
    {
      iMaxControlNumber = dynMax(ddaData[i][2]);

      // Make sure the control debug dps exist
      for (int x = 1; x <= iMaxControlNumber; x++)
      {
        if (!dpExists("_CtrlDebug_CTRL_" + x))
        {
          dpCreate("_CtrlDebug_CTRL_" + x, "_CtrlDebug");
        }
      }
    }
  }

  DebugFTN("RESTART", __FUNCTION__ + "(..., ...) max control number: " + iMaxControlNumber);

  // Update the 'manager is not running' logs
  updateManagerLogs();

  EB_UtilsPmon::deleteManagers();
}

/**
 * @brief Converts a package file name to a application name (for logging)
 * @details Logging is the EBlog class
 * @param sFileName     File name to convert
 * @return Application name for logging
 */
string getAppNameForLogging(const string &sFileName)
{
  string sResult = delExt(sFileName);

  // Remove the package prefix
  if (substr(sResult, 0, strlen(EB_PREFIX_PACKAGE)) == EB_PREFIX_PACKAGE)
  {
    sResult = substr(sResult, strlen(EB_PREFIX_PACKAGE));
  }

  return sResult;
}


/**
 * @brief Clears and sets the 'manager is not running' logs
 */
void updateManagerLogs()
{
  dyn_string dsPackages = getPackageDpes();
  dyn_string dsManagers;
  dyn_string dsOptions;
  dyn_mapping dmApps = EB_UtilsPackage::getInstalledPackages();

  dyn_int diStates;
  dyn_string dsPackageNames;
  for (int i = 1; i <= dynlen(dsPackages); i++)
  {
    dynClear(dsManagers);
    dynClear(dsOptions);
    getControlsFromApp(dsPackages[i], dmApps, dsManagers, dsOptions);
    getDriversFromApp(dsPackages[i], dmApps, dsManagers, dsOptions);

    for (int j = 1; j <= dynlen(dsManagers); j++)
    {
      int iState = EB_UtilsPmon::getPmonState(dsManagers[j], dsOptions[j]);
      string sPackageName = "";
      for (int k = 1; k <= dynlen(dmApps); k++)
      {
        mapping mConfig = dmApps[k];
        if (mappingHasKey(mConfig, "dpe") && mConfig["dpe"] == dsPackages[i] && mappingHasKey(mConfig, "Name"))
        {
          sPackageName = mConfig["Name"];
        }
      }
      g_Log.setAppName(sPackageName);
      if (iState != 2)
      {
        EBlogEntry logEntry;
        logEntry.setLogEntry(LOG_TYPE_RUNTIME, LOG_REASON, "", 2, 0, sPackageName, "", "manager_not_running", makeMapping("$1", sPackageName));
        g_Log.doLog(logEntry, TRUE, TRUE);
      }
      else
      {
        dyn_atime datAlerts;
        g_Log.removePendingLogs(LOG_TYPE_RUNTIME, datAlerts, 0, LOG_REASON);
      }

    }
  }
}


/**
 * @brief Updates the system with newer settings
 * @details Only settings which cannot be updated thru an ascii import are modified here
 */
void updateSystem()
{
  int  iVersion;
  bool bDone;

  dpGet("EB_Packages.Version", iVersion);

  for (int i = iVersion; !bDone; i++)
  {
    switch (i)
    {
      case 0:
        increaseManagerRestartAttempts();
        break;

      case 1:
        addNodeTypeCNS(makeMapping(999, "Device"));
        break;

      case 2:
        addNodeTypeCNS(makeMapping(900, "Snapshot"));
        break;

      // When all update steps have been executed, the system is up-to-date
      // And after storing the current version the update process is done
      default:
        dpSet("EB_Packages.Version", i);
        bDone = TRUE;
        break;
    }
  }
}

/**
 * @brief Increases the pmon restart attempt count for the existing managers
 * @details The default restart count of 3 is not enough during OPA updates
 */
void increaseManagerRestartAttempts()
{
  /*// Get current pmon list
  dyn_dyn_string ddsPmonList = EB_UtilsPmon::query("MGRLIST:LIST");

  int iFirstManager = EB_UtilsPmon::findManager(getComponentName(CTRL_COMPONENT), "-f EdgeBox_scripts.lst");
  if (iFirstManager != -1)
  {

    for (int i = iFirstManager; i <= dynlen(ddsPmonList); i++)
    {
      if ((int)ddsPmonList[i][4] < DEFAULT_PMON_MANAGER_RESTART_COUNT && dynlen(ddsPmonList[i]) == 6 && (int)ddsPmonList[i][2] == 2)
      {
        DebugFTN("RESTART", "Changing restart count for manager " + ddsPmonList[i][1] + " " + ddsPmonList[i][6] + " index: " + i);

        // Set the manager restart count
        string sResult = EB_UtilsPmon::command("SINGLE_MGR:PROP_PUT " + i + " always " + ddsPmonList[i][3] + " " + DEFAULT_PMON_MANAGER_RESTART_COUNT + " " + ddsPmonList[i][5] + " " + ddsPmonList[i][6]);

        if (sResult != PMON_RESULT_SUCCESS)
        {
          throwError(makeError("", PRIO_WARNING, ERR_SYSTEM, 54, "Error changing restart count for manager " + ddsPmonList[i][1] + " " + ddsPmonList[i][6], sResult));
        }
      }
    }
  }*/
}

/**
 * @brief Adds a new CNS node type to the dpe
 * @param mTypes   Type(s) to add (key == id, value == name)
 */
void addNodeTypeCNS(const mapping &mTypes)
{
  dyn_string dsIcons, dsIds;
  dyn_langString dlsNames;
  dyn_int diValues;

  dpGet("_CNS_General.NodeTypes.Icon",      dsIcons,
        "_CNS_General.NodeTypes.TypeId",    dsIds,
        "_CNS_General.NodeTypes.TypeName",  dlsNames,
        "_CNS_General.NodeTypes.TypeValue", diValues);

  int iCount = dynlen(dlsNames);

  for (int i = 1; i <= mappinglen(mTypes); i++)
  {
    langString lsName = mappingGetValue(mTypes, i);
    int        iValue = mappingGetKey(  mTypes, i);
    int        iIndex = dynContains(diValues, iValue);

    if (iIndex <= 0)
    {
      dynAppend(dsIcons,  "");
      dynAppend(dsIds,    lsName);
      dynAppend(dlsNames, lsName);
      dynAppend(diValues, iValue);
    }
    else if (dsIds[iIndex] != lsName)
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to add CNS node type: " + lsName + " due to id '" + iValue + "' is already in use by: " + dsIds[iIndex]));
    }
  }

  if (iCount != dynlen(dlsNames))
  {
    dpSet("_CNS_General.NodeTypes.Icon",      dsIcons,
          "_CNS_General.NodeTypes.TypeId",    dsIds,
          "_CNS_General.NodeTypes.TypeName",  dlsNames,
          "_CNS_General.NodeTypes.TypeValue", diValues);
  }
}

/**
 * @brief Callback function for the exit request to do some clean up before stopping
 * @details It removes the project running state file
 * @param sEvent        Event (not used)
 * @param iExitCode     Exit code (not used)
 */
void exitRequestCB(const string &sEvent, int iExitCode)
{
  DebugFN("CB_EXIT",__FUNCTION__ + "(" + sEvent + ", " + iExitCode + ")");

  // Clear the project running state
  if (isfile(PROJECT_STATE_FILE))
  {
    remove(PROJECT_STATE_FILE);
  }
}

/**
 * @brief Returns the absolute paths from a relative path
 * @details It returns the absolute paths from project & subproject containing this subdirectory
 * @param sRelativePath Relative path to convert
 * @return Absolute paths of the directories
 */
dyn_string getDirectories(const string &sRelativePath)
{
  dyn_string dsResult;

  for (int i = 1; i <= SEARCH_PATH_LEN; i++)
  {
    string sDirectory = getPath(sRelativePath, "", getActiveLang(), i);

    if (sDirectory != "" && isdir(sDirectory))
    {
      dynAppend(dsResult, sDirectory);
    }
  }

  return dsResult;
}

/**
 * @brief Returns the paths of the files in the specified directories
 * @param dsDirectories Directories to get the files from
 * @param sPattern      Filter for the files to return
 * @return Paths of the files (directory + file)
 */
dyn_string getFilesFromDirectories(const dyn_string &dsDirectories, const string &sPattern)
{
  dyn_string dsResult;

  for (int i = 1; i <= dynlen(dsDirectories); i++)
  {
    dyn_string dsFiles = getFileNames(dsDirectories[i], sPattern, FILTER_FILES);

    for (int j = 1; j <= dynlen(dsFiles); j++)
    {
      dynAppend(dsResult, dsDirectories[i] + dsFiles[j]);
    }
  }

  return dsResult;
}

/**
 * @brief Returns all package config file paths
 * @return All package config file paths
 */
dyn_string getFilesForMonitoring()
{
  dyn_string dsResult;
  dyn_string dsDirectories = getDirectories(PACKAGE_REL_PATH);

  dsResult = getFilesFromDirectories(dsDirectories, PACKAGE_PATTERN);

  // Make sure only the toplevel/active file is in the list
  for (int i = dynlen(dsResult); i > 0; i--)
  {
    if (getPath(PACKAGE_REL_PATH, baseName(dsResult[i])) != dsResult[i])
    {
      dynRemove(dsResult, i);
    }
  }

  return dsResult;
}

/**
 * @brief Callback function for changed files
 * @details Used for installing/removing/updating packages
 * @param sEvent   Triggered by this event (not used, always 'fswPathChanged')
 * @param sPath    Path that has changed
 */
synchronized void pathChangedCB(const string &sEvent, const string &sPath)
{
  // Check if this event is due to a deleted file
  if (!isdir(sPath) && !isfile(sPath))
  {
    // Unfortunately this event is not triggered (only for the directory)
  }
  // Check if the file has been modified
  else if (isfile(sPath))
  {
    time   tFileTime = getFileModificationTime(sPath);
    string sFileName = baseName(sPath);

    packageUpdate(sFileName, tFileTime);
  }
  else // This must be due to directory change
  {
    // Check if a file has been deleted
    for (int i = dynlen(g_dsMonitoredPaths); i > 0; i--)
    {
      if (!isdir(g_dsMonitoredPaths[i]) && !isfile(g_dsMonitoredPaths[i]))
      {
        string sFileName = baseName(g_dsMonitoredPaths[i]);

        throwError(makeError("", PRIO_INFO, ERR_SYSTEM, 54, "Removing package '" + delExt(sFileName) + "'"));

        packageRemove(delExt(sFileName));

        fswRemovePath(g_dsMonitoredPaths[i]);
        dynRemove(g_dsMonitoredPaths, i);
      }
    }

    // Check if there is a new file
    dyn_string dsFiles = getFilesForMonitoring();

    for (int i = dynlen(dsFiles); i > 0; i--)
    {
      if (dynContains(g_dsMonitoredPaths, dsFiles[i]) > 0)
      {
        dynRemove(dsFiles, i);
      }
    }

    DebugFTN("RESTART", __FUNCTION__ + "(" + sEvent + ", " + sPath + ") new files2:", dsFiles);

    for (int i = 1; i <= dynlen(dsFiles); i++)
    {
      string sFileName = baseName(dsFiles[i]);
      time   tFileTime = getFileModificationTime(dsFiles[i]);

      packageUpdate(sFileName, tFileTime);

      fswAddPath(dsFiles[i]);
      dynAppend(g_dsMonitoredPaths, dsFiles[i]);
    }
  }

  dynSort(g_dsMonitoredPaths);
}

/**
 * @brief Checks a package (based on a .ini file) for update
 * @param sFileName name of the .ini file which will be checked
 * @param tModified modification time of the ini file
 * @return TRUE -> Package has been updated
 */
void packageUpdate(const string &sFileName, time tModified)
{
  if (getPath(PACKAGE_REL_PATH, sFileName) == "")
  {
    throwError(makeError("", PRIO_WARNING, ERR_IMPL, 54, "Invalid package name", sFileName));
  }
  else
  {
    string sPath = getPath(PACKAGE_REL_PATH, sFileName);
    string sContent;

    if (fileToString(sPath, sContent))
    {
      anytype aConfig = jsonDecode(sContent);

      if (getType(aConfig) == MAPPING_VAR)
      {
        if      (!mappingHasKey(aConfig, MAPKEY_CONFIG_NAME))        throwError(makeError("", PRIO_WARNING, ERR_PARAM, 54, "Package file " + sPath + " does not contain a name!"));
        else if (!mappingHasKey(aConfig, MAPKEY_CONFIG_VERSION))     throwError(makeError("", PRIO_WARNING, ERR_PARAM, 54, "Package file " + sPath + " does not contain a version!"));
        else if (!mappingHasKey(aConfig, MAPKEY_CONFIG_DESCRIPTION)) throwError(makeError("", PRIO_WARNING, ERR_PARAM, 54, "Package file " + sPath + " does not contain a description!"));
        else if (!dpIsLegalName(delExt(sFileName)))                  throwError(makeError("", PRIO_WARNING, ERR_PARAM, 54, "Package file " + sPath + " is not a valid dp name!"));
        else
        {
          // Check if config datapoint exists, create if it does not exists
          string sDp = delExt(sFileName);

          if (!dpExists(sDp))
          {
            throwError(makeError("", PRIO_INFO, ERR_SYSTEM, 54, "Creating package dp: " + sDp));

            EB_dpCreateInstance(sDp, EB_DPTYPE_PACKAGES);

            throwError(makeError("", PRIO_INFO, ERR_SYSTEM, 54, "Finished creating package dp: " + sDp));
          }

          // Read existing datapoint and configuration (empty values if it did not exists before)
          string sVersion;
          string sConfig;
          time   tConfig;

          dpGet(sDp + ".Version", sVersion,
                sDp + ".Config",  sConfig,
                sDp + ".Config:_online.._stime", tConfig);

          if (tModified > tConfig)
          {
            // Show which package is being installed
            throwError(makeError("", PRIO_INFO, ERR_SYSTEM, 54, "Updating package '" + aConfig[MAPKEY_CONFIG_NAME] + "' version: " + aConfig[MAPKEY_CONFIG_VERSION] + " description: " + aConfig[MAPKEY_CONFIG_DESCRIPTION]));

            packageInstall(sDp, aConfig, jsonDecode(sConfig));
          }
          else
          {
            DebugFTN("RESTART", "Package file " + sPath + " is not new or a new version!");
          }
        }
      }
      else
      {
         DebugFTN("RESTART", "Package file " + sPath + " does not contain a valid json object!");
      }
    }
    else
    {
      DebugFTN("RESTART", "Package file " + sPath + " is not readable!");
    }
  }
}

/**
 * @brief Removes a package, all managers and drivers will be stopped and marked for removal.
 * @param sDp Package datapoint
 * @return Always TRUE
 */
void packageRemove(const string &sDp)
{
  DebugFTN("RESTART", __FUNCTION__, sDp);
  // create new description lang string from json
  string sJson;

  dpGet(sDp + ".Config", sJson);

  mapping mConfig = jsonDecode(sJson);

  // set new information to datapoints
  dpSet(sDp + ".Status", (int)PackageState::Removing);

  // Remove the managers
  string sFileName = sDp + PACKAGE_FILE_EXTENSION;

  dyn_mapping dmManagerActions = getActionsForManagers(makeMapping(), mConfig);

  for (int i = 1; i <= dynlen(dmManagerActions); i++)
  {
    if (dmManagerActions[i][MAPKEY_MANAGERS_ACTION] == ManagerAction::Remove)
    {
      string sManager = dmManagerActions[i][MAPKEY_MANAGERS_MANAGER];
      string sOptions = dmManagerActions[i][MAPKEY_MANAGERS_OPTIONS];
      EB_UtilsPmon::removeManager(sManager, sOptions);
    }
  }

  packageDpRemoveCB(sDp, makeDynAnytype(makeDynString(), makeDynString(sDp)));

  // set new information to datapoints
  dpSetWait(sDp + ".Status", (int)PackageState::Removed);
}

/**
 * @brief Install a package (update)
 * @param sDp
 * @param mConfig
 * @param mOldConfig    Empty if it is the first/initial installation
 * @return TRUE if package is installed successfully
 */
synchronized void packageInstall(const string &sDp, mapping &mConfig, const mapping &mOldConfig)
{
  if (mappingHasKey(mOldConfig, MAPKEY_CONFIG_VERSION) && mappingHasKey(mConfig, MAPKEY_CONFIG_VERSION))
  {
    callPackageUpdate(sDp, mOldConfig[MAPKEY_CONFIG_VERSION], mConfig[MAPKEY_CONFIG_VERSION]);
  }
  else
  {
    callPackageUpdate(sDp, "", "");
  }

  // create new description lang string from json
  langString lsDescription;
  dyn_string dsLangKeys = mappingKeys(mConfig[MAPKEY_CONFIG_DESCRIPTION]);
  for (int i = 1; i <= dynlen(dsLangKeys); i++)
  {
    int iIndex = getLangIdx(dsLangKeys[i]);

    if (iIndex != OA_Consts::INVALID_LANGUAGE_IDENTIFIER_STRING)
    {
      setLangString(lsDescription, iIndex, mConfig[MAPKEY_CONFIG_DESCRIPTION][dsLangKeys[i]]);
    }
  }

  string sTileName   = mappingHasKey(mConfig, MAPKEY_CONFIG_TILE_NAME)   ? mConfig[MAPKEY_CONFIG_TILE_NAME]   : "";
  string sHeader     = mappingHasKey(mConfig, MAPKEY_CONFIG_HEADER)      ? mConfig[MAPKEY_CONFIG_HEADER]      : "";
  string sPicture    = mappingHasKey(mConfig, MAPKEY_CONFIG_PICTURE)     ? mConfig[MAPKEY_CONFIG_PICTURE]     : "";
  string sHomeScreen = mappingHasKey(mConfig, MAPKEY_CONFIG_HOME_SCREEN) ? mConfig[MAPKEY_CONFIG_HOME_SCREEN] : "Home";
  bool   bEditable   = mappingHasKey(mConfig, MAPKEY_CONFIG_EDITABLE)    ? mConfig[MAPKEY_CONFIG_EDITABLE]    : FALSE;

  dyn_mapping dmPanels;
  dyn_string dsPath;
  dyn_string dsName;
  dyn_string dsDesc;

  if (mappingHasKey(mConfig, MAPKEY_CONFIG_PANELS))
  {
    dmPanels = mConfig[MAPKEY_CONFIG_PANELS];

    for (int i = 1; i <= dynlen(dmPanels); i++)
    {
      if (mappingHasKey(dmPanels[i], MAPKEY_PANELS_PATH))        dynAppend(dsPath, dmPanels[i][MAPKEY_PANELS_PATH]);
      if (mappingHasKey(dmPanels[i], MAPKEY_PANELS_NAME))        dynAppend(dsName, dmPanels[i][MAPKEY_PANELS_NAME]);
      if (mappingHasKey(dmPanels[i], MAPKEY_PANELS_DESCRIPTION)) dynAppend(dsDesc, dmPanels[i][MAPKEY_PANELS_DESCRIPTION]);
    }
  }

  dyn_string dsLibraries = getPackageLibs(sDp);
  dyn_string dsHashes    = EB_UtilsFile::getFileHashes(LIBS_REL_PATH, dsLibraries);

  // Fill the mapping
  mConfig[MAPKEY_CONFIG_LIBRARIES] = makeMappingFromDyns(dsLibraries, dsHashes);

  dyn_string  dsDpes = makeDynString(sDp + ".Version",
                                     sDp + ".Description",
                                     sDp + ".Config",
                                     sDp + ".TileName",
                                     sDp + ".Picture",
                                     sDp + ".Header",
                                     sDp + ".Panels.Path",
                                     sDp + ".Panels.Name",
                                     sDp + ".Panels.Description",
                                     sDp + ".HomeScreen",
                                     sDp + ".Editable",
                                     sDp + ".Status",
                                     sDp + ".:_lock._common._locked"); // Do not allow modification during the installation
  dyn_anytype daValues = makeDynAnytype(mConfig[MAPKEY_CONFIG_VERSION],
                                        lsDescription,
                                        jsonEncode(mConfig),
                                        sTileName,
                                        sPicture,
                                        sHeader,
                                        dsPath,
                                        dsName,
                                        dsDesc,
                                        sHomeScreen,
                                        bEditable,
                                        (int)PackageState::Installing,
                                        TRUE);

  // Make sure the hashes of the libraries are up-to-date
  if (hasNewLibraries(mOldConfig, dsLibraries, dsHashes))
  {
    dynAppend(dsDpes, sDp + ".Libs.Path");
    dynAppend(dsDpes, sDp + ".Libs.Hash");

    appendDynValue(daValues, dsLibraries);
    appendDynValue(daValues, dsHashes);

    checkHashes(mConfig[MAPKEY_CONFIG_LIBRARIES], getSystemName() + sDp);
  }

  // set new information to datapoints
  dpSet(dsDpes, daValues);

  // Import the ascii files
  string sType = !mappingHasKey(mOldConfig, MAPKEY_CONFIG_LIBRARIES) ? MAPKEY_DPLIST_TYPE_INSTALL : MAPKEY_DPLIST_TYPE_UPDATE;
  if (mappingHasKey(mConfig, MAPKEY_CONFIG_DPLISTS) && mappingHasKey(mConfig[MAPKEY_CONFIG_DPLISTS], sType))
  {
    importAsciiFiles(mConfig[MAPKEY_CONFIG_DPLISTS][sType]);
  }

  // Check which actions to execute on the managers
  dyn_mapping dmManagerActions = getActionsForManagers(mConfig, mOldConfig);
  DebugFTN("RESTART", __FUNCTION__, dmManagerActions);

  // Add the managers
  for (int i = 1; i <= dynlen(dmManagerActions); i++)
  {
    if (dmManagerActions[i][MAPKEY_MANAGERS_ACTION] == ManagerAction::Install)
    {
      string sManager = dmManagerActions[i][MAPKEY_MANAGERS_MANAGER];
      string sOptions = dmManagerActions[i][MAPKEY_MANAGERS_OPTIONS];
      EB_UtilsPmon::addManager(sManager, sOptions);
    }
  }

  // set new information to datapoints
  dpSet(sDp + ".Status", (int)PackageState::Installed,
        sDp + ".:_lock._common._locked", FALSE);
}


/**
 * @brief Returns the libraries of the specified package
 * @param sPackage Package to get the libraries from
 * @return Relative library paths
 */
dyn_string getPackageLibs(const string &sPackage)
{
  dyn_string dsResult;

  // Also include libraries located in subprojects
  for (int i = 1; i <= SEARCH_PATH_LEN; i++)
  {
    dyn_string dsFiles;
    string sProjectDir = getPath(LIBS_REL_PATH, "", getActiveLang(), i);
    string sDirectory  = sProjectDir + sPackage + "/";

    if (isdir(sDirectory))
    {
      dsFiles = getYoungerFiles(sDirectory, 0);

      // Make the files relative
      for (int j = 1; j <= dynlen(dsFiles); j++)
      {
        dsFiles[j] = makeUnixPath(substr(dsFiles[j], strlen(sProjectDir)));
      }

      dynAppend(dsResult, dsFiles);
    }
  }

  // Do not forget the package library
  dynAppend(dsResult, "packages/" + sPackage + ".ctl");

  dynSort(dsResult);
  dynUnique(dsResult);

  dyn_string dsResult1;
  for(int i = 1; i <= dynlen(dsResult); i++)
  {
    getUses(dsResult[i], dsResult1);
  }

  dynAppend(dsResult, dsResult1);
  dynSort(dsResult);
  dynUnique(dsResult);

  return dsResult;
}

/**
 * @brief Add the used libraries of the specified file
 * @param sFileName The file
 * @param dsUses The used libraries
 */
void getUses(const string &sFileName, dyn_string &dsUses)
{
  string sProjectDir = getPath(LIBS_REL_PATH, "");
  if (isfile(sProjectDir + sFileName))
  {
    string sFileContent;
    fileToString(sProjectDir + sFileName, sFileContent);

    dyn_string dsFileContent = strsplit(sFileContent, "\n");
    for (int i = 1; i <= dynlen(dsFileContent); i++)
    {
      int iPos = strpos(dsFileContent[i], "#uses \"");
      if(iPos >= 0)
      {
        strreplace(dsFileContent[i], "#uses \"", "");
        int iPos1 = strpos(dsFileContent[i], "\"");
        string sUses = uniSubStr(dsFileContent[i], 0, iPos1);
        if (isfile(sProjectDir + sUses + ".ctl") && dynContains(dsUses, sUses + ".ctl") <= 0)
        {
          dynAppend(dsUses, sUses + ".ctl");
          getUses(sUses + ".ctl", dsUses);
        }
      }
    }

    dynSort(dsUses);
    dynUnique(dsUses);
  }
}

/**
 * @brief Combines 2 equally sized dyns into a mapping
 * @param daKeys   Keys for the new mapping
 * @param daValues Values for the new mapping
 * @return Mapping with the specified keys and values
 */
mapping makeMappingFromDyns(const dyn_anytype &daKeys, const dyn_anytype &daValues)
{
  mapping mResult;

  // Return an empty mapping if the dyns do not have the same length
  if (dynlen(daKeys) == dynlen(daValues))
  {
    // Fill the mapping
    for (int i = 1; i <= dynlen(daKeys); i++)
    {
      anytype aKey = daKeys[i];

      mResult[aKey] = daValues[i];
    }
  }

  return mResult;
}

/**
 * @brief Imports the specified ascii files
 * @param dsFiles  Relative paths of the files to import
 */
void importAsciiFiles(const dyn_string &dsFiles)
{
  DebugFTN("RESTART", __FUNCTION__, dsFiles);
  for (int i = 1; i <= dynlen(dsFiles); i++)
  {
    dbVU_doAsciiImport(getPath(DPLIST_REL_PATH, dsFiles[i]));
  }
}

/**
 * @brief Checks if there are new(er) libraries compared against the old config
 * @param mOldConfig    Old config
 * @param dsLibs        Newly installed libraries
 * @param dsHashes      Hashes of the library files
 * @return TRUE -> List contains new(er) libraries
 */
bool hasNewLibraries(const mapping &mOldConfig, const dyn_string &dsLibs, const dyn_string &dsHashes)
{
  bool bResult = !mappingHasKey(mOldConfig, MAPKEY_CONFIG_LIBRARIES) || mappinglen(mOldConfig[MAPKEY_CONFIG_LIBRARIES]) < dynlen(dsLibs);

  if (!bResult)
  {
    mapping    mLibs  = mOldConfig[MAPKEY_CONFIG_LIBRARIES];
    dyn_string dsKeys = mappingKeys(mLibs);
    dyn_string dsNew  = dsLibs;

    for (int i = 1; i <= dynlen(dsKeys) && !bResult; i++)
    {
      string sKey = dsKeys[i];
      int iIndex = dynContains(dsLibs, sKey);

      if (iIndex > 0)
      {
        dynRemove(dsNew, dynContains(dsNew, sKey));

        bResult = mLibs[sKey] != dsHashes[iIndex];
      }
    }

    if (dynlen(dsNew) > 0)
    {
      bResult = TRUE;
    }
  }

  return bResult;
}

/**
 * @brief Checks the hashes of all installed packages
 * @param mNewHashes  Mapping with the new hashes
 * @param sAppDpe Dpe of the package
 */
void checkHashes(const mapping &mNewHashes, const string &sAppDpe)
{
  //mNewHashes: [filename] = hash;
  //mApps: [filename] = list of apps
  mapping mApps;
  dyn_string dsFileWithNewHash;
  dyn_string dsApps = getPackageDpes();

  for (int i = 1; i<= dynlen(dsApps); i++)
  {
    dyn_string dsHash, dsPath;
    dpGet(dsApps[i] + ".Libs.Hash", dsHash,
          dsApps[i] + ".Libs.Path", dsPath);

    for (int j = 1; j <= dynlen(dsPath); j++)
    {
      dyn_string dsIncludedApps;
      if (mappingHasKey(mApps, dsPath[j]))
      {
        dsIncludedApps = mApps[dsPath[j]];
        dynAppend(dsIncludedApps, dsApps[i]);
        mApps[dsPath[j]] = dsIncludedApps;
      }
      else
      {
        mApps[dsPath[j]] = makeDynString(dsApps[i]);
      }

      if (mappingHasKey(mNewHashes, dsPath[j]))
      {
        if(mNewHashes[dsPath[j]] != dsHash[j])
        {
          if (!dynContains(dsFileWithNewHash, dsPath[j]))
          {
            dynAppend(dsFileWithNewHash, dsPath[j]);
          }
        }
      }
    }

  }

  synchronized(g_dsPackagesThatNeedsRestart)
  {
    dynClear(g_dsPackagesThatNeedsRestart);

    for (int i = 1; i <= dynlen(dsFileWithNewHash); i++)
    {
      if (mappingHasKey(mApps, dsFileWithNewHash[i]))
      {
        dynAppend(g_dsPackagesThatNeedsRestart, mApps[dsFileWithNewHash[i]]);
      }
    }
    //dynAppend(g_dsPackagesThatNeedsRestart, sAppDpe); // add own package to list
    dynSort(g_dsPackagesThatNeedsRestart);
    dynUnique(g_dsPackagesThatNeedsRestart);
  }

  DebugFTN("RESTART", "packages that need an restart:", g_dsPackagesThatNeedsRestart);
  dyn_mapping dmApps = EB_UtilsPackage::getInstalledPackages();
  updateUsedHashes(dmApps, mNewHashes);
}

/**
 * @brief Updates the new hashes for all packages
 * @param dmApps List of package configs
 * @param mNewHashes  Mapping with the new hashes
 */
void updateUsedHashes(const dyn_mapping &dmApps, const mapping &mNewHashes)
{
  for (int i = 1; i <= dynlen(dmApps); i++)
  {
    bool bChanged = FALSE;
    mapping mConfig = dmApps[i];
    string sDp;

    if (mappingHasKey(mConfig, "dpe"))
    {
      sDp = dpSubStr(mConfig["dpe"], DPSUB_DP);
      string sConfig;
      dpGet(sDp + ".Config", sConfig);
      mConfig = jsonDecode(sConfig);
    }

    if (mappingHasKey(mConfig, MAPKEY_CONFIG_LIBRARIES))
    {
      mapping mHashes = mConfig[MAPKEY_CONFIG_LIBRARIES];
      for (int j = 1; j <= mappinglen(mHashes); j++)
      {
        string sOldHashKey = mappingGetKey(mHashes, j);
        if (mappingHasKey(mNewHashes, sOldHashKey))
        {
          mHashes[sOldHashKey] = mNewHashes[sOldHashKey];
          bChanged = TRUE;
        }
      }
      mConfig[MAPKEY_CONFIG_LIBRARIES] = mHashes;
    }

    if (bChanged && sDp != "")
    {
      dyn_string dsLibraries = getPackageLibs(sDp);
      dyn_string dsHashes    = EB_UtilsFile::getFileHashes(LIBS_REL_PATH, dsLibraries);

      dyn_string dsDpes = makeDynString(sDp + ".Config", sDp + ".Libs.Path", sDp + ".Libs.Hash");
      dyn_anytype daValues = makeDynAnytype(jsonEncode(mConfig), dsLibraries, dsHashes);

      dpSet(dsDpes, daValues);
    }

  }
}

/**
 * @brief Returns the actions to execute for the managers
 * @param mConfig       Current configuration
 * @param mOldConfig    Old configuration
 * @return List of changed managers
 */
dyn_mapping getActionsForManagers(const mapping &mConfig, const mapping &mOldConfig)
{
  // Make a single collection of managers
  dyn_mapping dmResult  = makeSingleManagerList(mOldConfig);
  dyn_mapping dmNewList = makeSingleManagerList(mConfig);

  // Remove the managers that are also in the new config
  for (int i = dynlen(dmResult); i > 0; i--)
  {
    int iIndex = findMappingInList(dmNewList, dmResult[i]);

    if (iIndex > 0)
    {
      dynRemove(dmNewList, iIndex);

      dmResult[i][MAPKEY_MANAGERS_ACTION] = ManagerAction::Restart;
    }
    else
    {
      // Set the remove flag
      dmResult[i][MAPKEY_MANAGERS_ACTION] = ManagerAction::Remove;
    }
  }

  // Set the install flag for the remaining new managers
  for (int i = 1; i <= dynlen(dmNewList); i++)
  {
    dmNewList[i][MAPKEY_MANAGERS_ACTION] = ManagerAction::Install;
  }

  // And add them to the result list
  dynAppend(dmResult, dmNewList);

  DebugFN("CHANGED_MANAGERS", __FUNCTION__ + "(..., ...) Changed managers:", dmResult);

  return dmResult;
}

/**
 * @brief Returns a single list of managers
 * @details It combines the scripts and other managers into a single list
 * @param mConfig  Configuration
 * @return Single list of managers
 */
dyn_mapping makeSingleManagerList(const mapping &mConfig)
{
  dyn_mapping dmResult = mappingHasKey(mConfig, MAPKEY_CONFIG_MANAGERS) ? mConfig[MAPKEY_CONFIG_MANAGERS] : makeDynMapping();

  for (int i = 1; mappingHasKey(mConfig, MAPKEY_CONFIG_SCRIPTS) && i <= dynlen(mConfig[MAPKEY_CONFIG_SCRIPTS]); i++)
  {
    dynAppend(dmResult, makeMapping(MAPKEY_MANAGERS_MANAGER, getComponentName(CTRL_COMPONENT),
                                    MAPKEY_MANAGERS_OPTIONS, mConfig[MAPKEY_CONFIG_SCRIPTS][i][MAPKEY_SCRIPTS_SCRIPT]));
  }

  return dmResult;
}

/**
 * @brief Returns the index of the specified mapping in the list
 * @param dmList  List to find the mapping in
 * @param mMap    Mapping to find
 * @return Index of the specified mapping
 */
int findMappingInList(const dyn_mapping &dmList, const mapping &mMap)
{
  int iResult;

  for (int i = 1; i <= dynlen(dmList) && iResult == 0; i++)
  {
    if (dmList[i] == mMap)
    {
      iResult = i;
    }
  }

  return iResult;
}

/**
 * @brief Gets the list of managers and options from the package
 * @param sPackageDpe Dpe of the package
 * @param dmApps List of package configs
 * @param dsManagers The list of managers
 * @param dsOptions The list of options
 */
void getControlsFromApp(const string &sPackageDpe, dyn_mapping dmApps, dyn_string &dsManagers, dyn_string &dsOptions)
{
  DebugFTN("RESTART", __FUNCTION__, sPackageDpe, dsManagers, dsOptions);
  dyn_string dsSplit;

  for (int i = 1; i <= dynlen(dmApps); i++)
  {
    mapping mConfig = dmApps[i];
    DebugFTN("RESTART", __FUNCTION__, sPackageDpe, mConfig["dpe"]);
    if (mappingHasKey(mConfig, "dpe") && mConfig["dpe"] == sPackageDpe)
    {
      if (mappingHasKey(mConfig, "Controls"))
      {
        string sControls1 = mConfig["Controls"];
        dynAppend(dsSplit, strsplit(sControls1, "|"));
        for (int j = 1; j <= dynlen(dsSplit); j++)
        {
          string sControls = dsSplit[j];
          sControls = strrtrim(strltrim(sControls));
          sControls = substr(sControls, strlen("Script:"), strlen(sControls));
          sControls = strrtrim(strltrim(sControls, ":"));
          dynAppend(dsManagers, getComponentName(CTRL_COMPONENT));
          dynAppend(dsOptions, sControls);
        }
      }
    }
  }
}

/**
 * @brief Gets the list of managers and options from the package
 * @param sPackageDpe Dpe of the package
 * @param dmApps List of package configs
 * @param dsManagers The list of managers
 * @param dsOptions The list of options
 */
void getDriversFromApp(const string &sPackageDpe, dyn_mapping dmApps, dyn_string &dsManagers, dyn_string &dsOptions)
{
  DebugFTN("RESTART", __FUNCTION__, sPackageDpe, dsManagers, dsOptions);
  dyn_string dsSplit;

  for (int i = 1; i <= dynlen(dmApps); i++)
  {
    mapping mConfig = dmApps[i];
    DebugFTN("RESTART", __FUNCTION__, sPackageDpe, mConfig["dpe"]);
    if (mappingHasKey(mConfig, "dpe") && mConfig["dpe"] == sPackageDpe)
    {
      if (mappingHasKey(mConfig, "Drivers"))
      {
        string sDrivers = mConfig["Drivers"];
        dynAppend(dsSplit, strsplit(sDrivers, "|"));
        dsSplit[1] = strrtrim(strltrim(dsSplit[1]));
        dsSplit[2] = strrtrim(strltrim(dsSplit[2]));
        dsSplit[1] = substr(dsSplit[1], strlen("Driver:"), strlen(dsSplit[1]));
        dsSplit[2] = substr(dsSplit[2], strlen("Options:"), strlen(dsSplit[2]));
        dsSplit[1] = strrtrim(strltrim(dsSplit[1], ":"));
        dsSplit[2] = strrtrim(strltrim(dsSplit[2], ":"));
        dynAppend(dsManagers, dsSplit[1]);
        dynAppend(dsOptions, dsSplit[2]);
      }
    }
  }
}

/**
 * @brief Returns the list of dpes of installed packages
 * @return dyn_string The list
 */
dyn_string getPackageDpes()
{
  return dpNames("EB_Package_*", "EB_Packages");
}


/**
 * @brief Appends a dyn type value to a dyn dyn type list
 * @param daList   List to append the value to
 * @param daValue  Value to append
 */
void appendDynValue(dyn_anytype &daList, const dyn_anytype &daValue)
{
  daList[dynlen(daList) + 1] = daValue;
}

/**
 * @brief Calls the package update function
 * @param sDp      Datapoint of the package
 * @param sFrom    from version
 * @param sTo      to version
 * @return TRUE -> Restart the managers of this package
 */
bool callPackageUpdate(const string &sDp, const string &sFrom, const string &sTo)
{
  string sAppName     = substr(sDp, strlen(EB_PREFIX_PACKAGE));
  string sFileName    = getPath(SOURCE_REL_PATH, "EB_Package_Base/update.ctl");
  string sNewFileName = PROJ_PATH + SCRIPTS_REL_PATH + "EB_Package_Base/update" + sAppName + ".ctl";
  string sFileContent;
  int iReturnCode;

  if(sFileName != "")
  {
    //load and replace
    fileToString(sFileName, sFileContent);
    strreplace(sFileContent, "$appName", sAppName);

    file fNewFile = fopen(sNewFileName, "w+");
    fputs(sFileContent, fNewFile);
    fclose(fNewFile);

    // Wait max 10 seconds until the needed library is available
    for (int i = 1; i <= 10 && getPath(LIBS_REL_PATH, "packages/" + EB_PREFIX_PACKAGE + sAppName + ".ctl") == ""; i++)
    {
      delay(1);
    }

    if (getPath(LIBS_REL_PATH, "packages/" + EB_PREFIX_PACKAGE + sAppName + ".ctl") != "")
    {
      //call
      string sCtrl = getPath(BIN_REL_PATH, getComponentName(CTRL_COMPONENT) + (_WIN32 ? ".exe" : "")) + " -PROJ " + PROJ;
      string sCommand = sCtrl + " EB_Package_Base/update" + sAppName + ".ctl " + sFrom + " " + sTo;

      iReturnCode = system(sCommand);
    }
    else
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to execute update script for package: " + sAppName));
    }

    remove(sNewFileName);

    DebugFN("PACKAGE_UPDATE", __FUNCTION__ + "(" + sDp + ", " + sFrom + ", " + sTo + ") Returning: " + (iReturnCode != 0) + " return code: " + iReturnCode);

    return iReturnCode != 0;
  }
  else
  {
    return FALSE;
  }
}
