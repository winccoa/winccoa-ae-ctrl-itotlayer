// $License: NOLICENSE

/**
 * @file libs/EB_Package_Gedi/EB_UtilsPackage.ctl
 * @brief Contains various useful functions for handling (local) packages.
 */

// used libraries (#uses)
#uses "json"

/**
 * @brief This is the utility class for package handling. It contains various useful functions for handling (local) packages.
 */
class EB_UtilsPackage
{
  public static const string PACKAGE_PREFIX       = "EB_Package_";
  public static const string PACKAGE_DPTYPE       = "EB_Packages";
  public static const string PACKAGE_CONFIG_DPE   = "Config";
  public static const string PACKAGE_DOWNLOAD_DIR = "downloads/";
  public static const string PACKAGE_BUILD_DIR    = "builds/";
  public static const string PACKAGE_PACK_DIR     = "files/package/";
  public static const string PACKAGE_TEMP_DIR     = "tmp/";
  public static const string PACKAGE_TEMPLATE_DIR = DATA_REL_PATH + "EB_Package_Gedi/Template/files/package/";
  public static const string PACKAGE_PACK_FILE    = "app.tar.gz";
  public static const string BASE_PACKAGE_ID      = "at.etm.edgebox.base";
  public static const string BASE_PACKAGE_DP      = "EB_Package_Base";    // Using the previously defined const does not work

  private static const string BASE_PACKAGE_LIST = "packages/base-packages.lst";
  private static const string BASE_PACKAGE_NAME = "IoT Box Base Application";

  /**
   * @brief Returns packages, which are part of the base package and have a dp
   * @return List of packages which are part of the base package and have a dp or empty dyn_string in case of failure
   */
  public static dyn_string getBasePackages()
  {
    dyn_string dsResult;
    string sFileName = getPath(DATA_REL_PATH, BASE_PACKAGE_LIST);

    if (sFileName != "")
    {
      string sContent;

      fileToString(sFileName, sContent);

      dyn_string dsLines = strsplit(sContent, "\n");

      for (int i = 1; i <= dynlen(dsLines); i++)
      {
        // Remove the package prefix & file extension
        string sPackage = substr(delExt(dsLines[i]), strlen(PACKAGE_PREFIX));

        if (sPackage != "" && getPath(DATA_REL_PATH, dsLines[i]) != "")
        {
          dynAppend(dsResult, sPackage);
        }
      }
    }
    else
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to find base packages list file: " + DATA_REL_PATH + BASE_PACKAGE_LIST));
    }

    dynSort(dsResult);

    return dsResult;
  }

  /**
   * @brief Returns packages, which are located in the download directory
   * @return List of packages which are located in the download directory or empty dyn_string in case of failure
   */
  public static dyn_string getDownloadedPackages()
  {
    dyn_string dsResult;
    string sDirectory = getPath(DATA_REL_PATH, PACKAGE_DOWNLOAD_DIR);

    if (sDirectory != "")
    {
      dyn_string dsFiles = getFileNames(sDirectory, PACKAGE_PREFIX + "*.tgz");

      for (int i = 1; i <= dynlen(dsFiles); i++)
      {
        string sFileName = dsFiles[i];

        // Remove the '.signed.tgz' part
        int iIndex = strpos(sFileName, ".");

        if (iIndex >= 0)
        {
          sFileName = substr(sFileName, 0, iIndex);
        }

        // Remove the 'EB_Package_' part
        dynAppend(dsResult, substr(sFileName, strlen(PACKAGE_PREFIX)));
      }
    }

    dynSort(dsResult);

    return dsResult;
  }

  /**
   * @brief Calls a callback function whenever the config of an installed package changes
   * @param fpWork Callback function that is called when a package config changes
   * @return returns 0, in the event of a failure returns < 0
   */
  public static int connectInstalledPackages(function_ptr fpWork)
  {
    string sQuery = "SELECT '." + PACKAGE_CONFIG_DPE + ":_online.._value' FROM '" + PACKAGE_PREFIX + "*' WHERE _DPT = \"" + PACKAGE_DPTYPE + "\"";

    return dpQueryConnectSingle(workInstalledPackagesCB, TRUE, fpWork, sQuery);
  }

  /**
   * @brief Returns packages, which are installed in the project
   * @return List of packages which are installed in the project or empty dyn_string in case of failure
   */
  public static dyn_mapping getInstalledPackages()
  {
    dyn_dyn_anytype ddaData;
    string sQuery = "SELECT '." + PACKAGE_CONFIG_DPE + ":_online.._value' FROM '" + PACKAGE_PREFIX + "*' WHERE _DPT = \"" + PACKAGE_DPTYPE + "\"";

    dpQuery(sQuery, ddaData);

    return convertPackageQuery(ddaData);
  }

  /**
   * @brief Extracts a package, so it is ready for installation
   * @param sFileName   File name of the (downloaded) package
   * @return Directory containing the extracted package or empty string in case of failure
   */
  public static string unzip(const string &sFileName)
  {
    string sResult;
    string sFullName = delExt(delExt(baseName(sFileName))); // Remove the directory and '.signed.tgz'
    string sDirectory = PROJ_PATH + DATA_REL_PATH + PACKAGE_DOWNLOAD_DIR + sFullName + "/";

    // Check 7zip
    string sZipProgram = getZipCommand();

    DebugFN("PACKAGE_UNZIP", __FUNCTION__ + "(" + sFileName + ") zipProgram: " + sZipProgram + " directory: " + sDirectory);

    if (sZipProgram != "")
    {
      string sOut;
      string sError;

      // Unzip application
      int iRc = system(sZipProgram + " e -y " + sFileName + " -so |" + sZipProgram + " e -y -si -ttar -o" + sDirectory + PACKAGE_TEMP_DIR, sOut, sError);

      DebugFN("PACKAGE_UNZIP", __FUNCTION__ + "(" + sFileName + ") unzip result: " + iRc + " file: " + sDirectory + PACKAGE_TEMP_DIR + PACKAGE_PACK_FILE + " isfile: " + isfile(sDirectory + PACKAGE_TEMP_DIR + PACKAGE_PACK_FILE), sOut, sError);

      // Check if the next file to extract exists
      if (isfile(sDirectory + PACKAGE_TEMP_DIR + PACKAGE_PACK_FILE))
      {
        // Unpack application
        iRc = system(sZipProgram + " e -y " + sDirectory + PACKAGE_TEMP_DIR + PACKAGE_PACK_FILE + " -so |" + sZipProgram + " e -y -si -ttar -spf -o" + sDirectory, sOut, sError);

        DebugFN("PACKAGE_UNZIP", __FUNCTION__ + "(" + sFileName + ") unpack result: " + iRc, sOut, sError);

        if (sError == "")
        {
          sResult = getPath(DATA_REL_PATH) + PACKAGE_DOWNLOAD_DIR + sFullName;
        }
        else
        {
          throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to unpack package: " + sFullName, sError));
        }
      }
      else
      {
        throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to unzip package: " + sFullName, sError));
      }

    }

    DebugFN("PACKAGE_UNZIP", __FUNCTION__ + "(" + sFileName + ") Returning: " + sResult);

    return sResult;
  }

  /**
   * @brief Installs a package, so it is ready for installation
   * @param sPath  Directory containing the extracted package
   * @return In the event of an error < 0, otherwise 0.
   */
  public static int install(const string &sPath)
  {
    int    iResult    = -1;
    string sCommand   = _WIN32 ? "" : "bash ";
    string sExtension = _WIN32 ? ".cmd" : ".sh";
    string sScript    = sPath + "/install" + sExtension;
    string sOut;
    string sError;

    if (isfile(sScript))
    {
      system(sCommand + sScript + " -project " + PROJ + " -directory " + dirName(PROJ_PATH), sOut, sError);

      if (sError == "")
      {
        iResult = 0;
      }
      else
      {
        throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to install package: " + baseName(delExt(sPath)), sError));
      }
    }
    else
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Installation file is missing", "Unable to install package: " + baseName(delExt(sPath))));
    }

    return iResult;
  }

  /**
   * @brief Creates a new package from our template files
   * @param sName  Name of the new package
   * @return In the event of an error < 0, otherwise 0.
   */
  public static int create(const string &sName)
  {
    string sFullName    = PACKAGE_PREFIX + sName;
    string sTemplateDir = getPath("", PACKAGE_TEMPLATE_DIR);
    mapping mReplace    = createReplaceMapping(sName);

    // Create the directories
    mkdir(PROJ_PATH + DATA_REL_PATH + "packages", 775);
    mkdir(PROJ_PATH + LIBS_REL_PATH + "packages", 775);
    mkdir(PROJ_PATH + SCRIPTS_REL_PATH  + sFullName, 775);
    mkdir(PROJ_PATH + LIBS_REL_PATH     + sFullName, 775);
    mkdir(PROJ_PATH + PANELS_REL_PATH   + sFullName, 775);
    mkdir(PROJ_PATH + PICTURES_REL_PATH + sFullName, 775);
    mkdir(PROJ_PATH + DPLIST_REL_PATH   + sFullName, 775);
    mkdir(PROJ_PATH + DATA_REL_PATH     + sFullName, 775);
    mkdir(PROJ_PATH + "help/" + "en_US.utf8/" + sFullName, 775);

    // Copy the template files and replace the placeholders
    createFile(sTemplateDir + "Package.ini",          PROJ_PATH + DATA_REL_PATH + "packages/" + sFullName + ".ini", mReplace);
    createFile(sTemplateDir + "Package.ctl.template", PROJ_PATH + LIBS_REL_PATH + "packages/" + sFullName + ".ctl", mReplace);


    for (int i = 0; i < getNoOfLangs(); i++)
    {
      createFile(sTemplateDir + "Package.cat", PROJ_PATH + MSG_REL_PATH + getLocale(i) + "/" + sFullName + ".cat", mReplace);
    }

    // Copy some example files
    copyFile(sTemplateDir + "Manager.ctl", PROJ_PATH + SCRIPTS_REL_PATH + sFullName + "/");
    copyFile(sTemplateDir + "Library.ctl", PROJ_PATH + LIBS_REL_PATH    + sFullName + "/");

    // Copy some more files
    copyFiles(sTemplateDir + "*.svg", PROJ_PATH + PICTURES_REL_PATH + sFullName + "/");
    copyFiles(sTemplateDir + "*.png", PROJ_PATH + PICTURES_REL_PATH + sFullName + "/");
    copyFiles(sTemplateDir + "*.pdf", PROJ_PATH + "help/" + "en_US.utf8/" + sFullName + "/");
    copyFiles(sTemplateDir + "*.pnl", PROJ_PATH + PANELS_REL_PATH   + sFullName + "/");
    copyFiles(sTemplateDir + "*.dpl", PROJ_PATH + DPLIST_REL_PATH   + sFullName + "/");

    return 0;
  }

  /**
   * @brief Builds a signed package for the specified package name
   * @param sName  Name of the package to build
   * @return In the event of an error < 0, otherwise 0.
   */
  public static int build(const string &sName)
  {
    int    iResult   = -1;
    string sFullName = PACKAGE_PREFIX + sName;
    string sDirBuild = PROJ_PATH + DATA_REL_PATH + PACKAGE_BUILD_DIR;
    string sDirDest  = sDirBuild + sFullName + "/";
    string sDirPack  = sDirDest + PACKAGE_PACK_DIR;

    // Check openssl
    string sOpenssl = findExecutable("openssl");

    // Check 7zip
    string sZipProgram = getZipCommand();

    // Check if publish key exists
    string sPubKey = getPath(CONFIG_REL_PATH, "appPublish.key");

    DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") openssl: " + sOpenssl + " zipProgram: " + sZipProgram + " pubKey: " + sPubKey);

    if (sOpenssl == "")
    {
      // Should never occur since it is a requirement for WinCC OA
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to find Openssl"));
    }
    // Check if 7-zip is available
    if (sZipProgram == "")
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to find 7-Zip"));
    }
    // Check if there is a certificate for signing the package
    // Perhaps the user has not created it yet
    if (sPubKey == "")
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to find key for signing the package"));
    }
    if (sOpenssl != "" && sZipProgram != "" && sPubKey != "")
    {
      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Creating directories");

      // Create the directories
      mkdir(sDirDest, 775);
      mkdir(sDirPack, 775);

      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Deleting: " + sDirPack + "data/packages");

      // Delete old sContents
      rmdir(sDirPack + "data/packages", TRUE);

      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Copying files");

      // Cleanup old sContents and copy the new sContent
    dyn_string sDirs = makeDynString(BIN_REL_PATH, COLORDB_REL_PATH, CONFIG_REL_PATH, DATA_REL_PATH, DPLIST_REL_PATH, PANELS_REL_PATH,
                                     PICTURES_REL_PATH, SCRIPTS_REL_PATH, LIBS_REL_PATH, LIBS_REL_PATH + "packages/");

      for (int i = 1; i <= dynlen(sDirs); i++)
      {
        rmdir(sDirPack + sDirs[i], TRUE);

        DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Copying files of dir: " + PROJ_PATH + sDirs[i] + sFullName + "*");

        if (testPath(PROJ_PATH + sDirs[i] + sFullName + "*"))
        {
          copyFiles(PROJ_PATH + sDirs[i] + sFullName + "*", sDirPack + sDirs[i], TRUE);
        }
      }

      sDirs = makeDynString(MSG_REL_PATH, HELP_REL_PATH);

      for (int i = 1; i <= dynlen(sDirs); i++)
      {
        for (int j = 0; j < getNoOfLangs(); j++)
        {
          string sLang = getLocale(j);

          rmdir(sDirPack + sDirs[i] + sLang, TRUE);

          if (testPath(PROJ_PATH + sDirs[i] + sLang + "/" + sFullName + "*"))
          {
            copyFiles(PROJ_PATH + sDirs[i] + sLang + "/" + sFullName + "*", sDirPack + sDirs[i] + sLang + "/", TRUE);
          }
        }
      }

      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Creating manifest");

      // Create manifest
      mkdir(sDirPack + "data/packages", 775);

      createFile(getPath(DATA_REL_PATH, "packages/" + sFullName + ".ini"), sDirPack + "data/packages/" + sFullName + ".ini", createReplaceMapping(sName));

      copyFile(sDirPack + "data/packages/" + sFullName + ".ini", sDirDest + "manifest.json");

      // Package template scripts
      string sDirTemplateScript;

      if (testPath(SOURCE_REL_PATH + "Packages/template/"))
      {
        sDirTemplateScript = getPath(SOURCE_REL_PATH, "Packages/template/");
      }

      else
      {
        sDirTemplateScript = getPath(SOURCE_REL_PATH, "EB_Package_Base/Packages/template/");
      }

      copyFiles(sDirTemplateScript + "*.env", sDirDest);
      copyFiles(sDirTemplateScript + "*.sh",  sDirDest);
      copyFiles(sDirTemplateScript + "*.cmd", sDirDest);
      addContent(sDirDest + "install.env", "PACK=" + sFullName);

      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Removing files");

      // Zip package
      remove(sDirBuild + sFullName + ".signed.tgz");
      remove(sDirBuild + sFullName + ".signed.tgz.urlencoded");

      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Removing directory: " + sDirBuild + "tmp");

      rmdir(sDirBuild + "tmp", TRUE);
      mkdir(sDirBuild + "tmp", 775);

      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Package files");

      string sOut, sErrors;

      int iRc = system(sZipProgram + " a -ttar -so -r . " + sDirDest + "* |" + sZipProgram + " a -tgzip " + sDirBuild + "tmp/" + PACKAGE_PACK_FILE + " -si", sOut, sErrors);

      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Package file, rc: " + iRc + " out: " + sOut + " error: " + sErrors);

      iRc = system(sOpenssl + " dgst -sha256 -sign " + sPubKey + " -out " + sDirBuild + "tmp/" + PACKAGE_PACK_FILE + ".sha256 " + sDirBuild + "tmp/" + PACKAGE_PACK_FILE, sOut, sErrors);

      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Package file, rc: " + iRc + " out: " + sOut + " error: " + sErrors);

      iRc = system(sZipProgram + " a -ttar -so -r . " + sDirBuild + "tmp/" + PACKAGE_PACK_FILE + " " + sDirBuild + "tmp/" + PACKAGE_PACK_FILE + ".sha256 |" + sZipProgram + " a -tgzip " + sDirBuild + "tmp/" + sFullName + ".signed.tgz -si", sOut, sErrors);

      DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Package file, rc: " + iRc + " out: " + sOut + " error: " + sErrors);

      // Check if the output file is there
      if (isfile(sDirBuild + "tmp/" + sFullName + ".signed.tgz"))
      {
        iResult = 0;
      }
    }

    DebugFN("PACKAGE_BUILD", __FUNCTION__ + "(" + sName + ") Returning: " + iResult);

    return iResult;
  }

  /**
   * @brief Removes the specified package from the project
   * @param sName  Name of the package to remove
   * @return In the event of an error < 0, otherwise 0.
   */
  public static int removePackage(const string &sName)
  {
    string sFullName = PACKAGE_PREFIX + sName;

    DebugFN("PACKAGE_REMOVE", __FUNCTION__ + "(" + sName + ")");

    // Remove the files
    remove(PROJ_PATH + DATA_REL_PATH + "packages/" + sFullName + ".ini");
    remove(PROJ_PATH + LIBS_REL_PATH + "packages/" + sFullName + ".ctl");

    for (int i = 0; i < getNoOfLangs(); i++)
    {
      remove(PROJ_PATH + MSG_REL_PATH + getLocale(i) + "/" + sFullName + ".cat");
    }

    // Remove the directories
    remove(PROJ_PATH + SCRIPTS_REL_PATH  + sFullName + "/");
    remove(PROJ_PATH + LIBS_REL_PATH     + sFullName + "/");
    remove(PROJ_PATH + PICTURES_REL_PATH + sFullName + "/");
    remove(PROJ_PATH + PANELS_REL_PATH   + sFullName + "/");
    remove(PROJ_PATH + DPLIST_REL_PATH   + sFullName + "/");
    remove(PROJ_PATH + DATA_REL_PATH     + sFullName + "/");

    return 0;
  }

  /**
   * @brief Callback function for 'connectInstalledPackages'
   * @details Converts the data and calls the callback function
   * @param fpWork      Callback function specified as specified in the connect
   * @param ddaData     Data as returned by dpQueryConnectSingle
   */
  private static void workInstalledPackagesCB(function_ptr fpWork, const dyn_dyn_anytype &ddaData)
  {
    // Convert the data
    dyn_mapping dmResult = convertPackageQuery(ddaData);

    // Call the callback function
    callFunction(fpWork, dmResult);
  }

  /**
   * @brief Converts the package config query result into a dyn_mapping
   * @param ddaData     Data as returned by dpQuery*
   * @return List of package configs
   */
  private static dyn_mapping convertPackageQuery(const dyn_dyn_anytype &ddaData)
  {
    dyn_mapping dmResult;
    dyn_string dsBasePackages = getBasePackages();

    for (int i = 2; i <= dynlen(ddaData); i++)
    {
      // Skip newly created datapoints without a config (yet)
      if (ddaData[i][2] != "")
      {
        mapping mMap = json_strToVal(ddaData[i][2]);
        mMap["dpe"] = dpSubStr(ddaData[i][1], DPSUB_SYS_DP);

        // Check if this mapping has the required key(s)
        if (!mappingHasKey(mMap, "Name"))
        {
          throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to determine package name for dp: " + ddaData[i][1], mMap));
        }
        // Check if this package is not part of the base package
        else if (dynContains(dsBasePackages, mMap["Name"]) <= 0)
        {
          dynAppend(dmResult, mMap);
        }
        // Only append the base package once
        else if (mappingHasKey(mMap, "Application") && mMap["Application"] == BASE_PACKAGE_ID)
        {
          // Replace the old name 'EdgeBox' with 'IoT Box'
          mMap["Name"] = BASE_PACKAGE_NAME;

          dynAppend(dmResult, mMap);
        }
      }
    }

    return dmResult;
  }

  /**
   * @brief Creates a mapping for replacing keywords from a template file
   * @param sName  Name of the package
   * @return In the event of an error < 0, otherwise 0.
   */
  private static mapping createReplaceMapping(const string &sName)
  {
    time    tCurrent = getCurrentTime();
    mapping mResult  = makeMapping("${NAME}",  sName,
                                   "${BUILD}", formatTimeUTC("%y%m%d%H%M", tCurrent),
                                   "${DATE}",  formatTimeUTC("%Y-%m-%d",   tCurrent),
                                   "${TIME}",  formatTimeUTC("%H:%M:%S",   tCurrent));

    return mResult;
  }

  /**
   * @brief Creates a new file from a template file
   * @param sTemplate   Template file name
   * @param sTarget     File name of the new file
   * @param mReplace    Mapping containing the keys to replace
   * @return In the event of an error < 0, otherwise 0.
   */
  public static int createFile(const string &sTemplate, const string &sTarget, const mapping mReplace = makeMapping())
  {
    int iResult = -1;
    string sContent;

    if (fileToString(sTemplate, sContent))
    {
      iResult = 0;

      DebugFN("PACKAGE_TEMPLATE", __FUNCTION__ + "(" + sTemplate + ", " + sTarget + ", ...) strlen: " + strlen(sContent));

      for (int i = 1; i <= mappinglen(mReplace); i++)
      {
        string sKey   = mappingGetKey(  mReplace, i);
        string sValue = mappingGetValue(mReplace, i);

        DebugFN("PACKAGE_TEMPLATE", __FUNCTION__ + "(" + sTemplate + ", " + sTarget + ", ...) Replacing '" + sKey + "' with: " + sValue);

        iResult += strreplace(sContent, sKey, sValue);
      }

      file f = fopen(sTarget, "w");

      fputs(sContent, f);

      fclose(f);
    }

    DebugFN("PACKAGE_TEMPLATE", __FUNCTION__ + "(" + sTemplate + ", " + sTarget + ", ...) Returning: " + iResult);

    return iResult;
  }

  /**
   * @brief Copies source files to the target directory
   * @param sSource     Files to copy (wildcards are allowed 'myDir/*.env')
   * @param sTarget     Target directory for the copied files
   * @param bRecursive  TRUE -> Also copy files from subdirectories
   * @return In the event of an error < 0, otherwise 0.
   */
  private static int copyFiles(const string &sSource, const string &sTarget, bool bRecursive = FALSE)
  {
    int iResult = 0;

    string sSourceDir = sSource;
    string sPattern   = "*";

    // Check if the specified source contains a pattern
    // and need to split it in a directory and pattern part
    if (!isdir(sSource))
    {
      sSourceDir = dirName(sSource);
      sPattern   = baseName(sSource);
    }

    DebugFN("PACKAGE_COPY", __FUNCTION__ + "(" + sSource + ", " + sTarget + ", " + bRecursive + ") dir: " + sSourceDir + " pattern: " + sPattern);

    dyn_string dsFiles = getFileNames(sSourceDir, sPattern, FILTER_FILES);

    for (int i = 1; i <= dynlen(dsFiles); i++)
    {
      // Apparently the target can also be a file
      // (it makes the target file in stead of copying it to the target directory)
      iResult += copyFile(sSourceDir + dsFiles[i], sTarget + dsFiles[i]);
    }

    if (bRecursive)
    {
      dyn_string dsDirectories = getFileNames(sSourceDir, sPattern, FILTER_DIRS);

      DebugFN("PACKAGE_COPY", __FUNCTION__ + "(" + sSource + ", " + sTarget + ", " + bRecursive + ") directories:", dsDirectories);

      for (int i = 1; i <= dynlen(dsDirectories); i++)
      {
        // Do not process hidden directories (or . and ..)
        if (dsDirectories[i][0] != ".")
        {
          iResult += copyFiles(sSourceDir + dsDirectories[i] + "/", sTarget + dsDirectories[i] + "/", bRecursive);
        }
      }
    }

    return iResult;
  }

  /**
   * @brief Checks if the specified file/directory exists
   * @param sPath  Path to check
   * @return TRUE -> path exists, FALSE -> path does not exist
   */
  private static bool testPath(const string &sPath)
  {
    dyn_string dsPaths = getFileNames(dirName(sPath), baseName(sPath), FILTER_FILES | FILTER_DIRS);

    DebugFN("PACKAGE_PATH", __FUNCTION__ + "(" + sPath + ") dir: " + dirName(sPath) + " pattern: " + baseName(sPath) + " dynlen: " + dynlen(dsPaths) + " Returning: " + (dynlen(dsPaths) > 0));

    return dynlen(dsPaths) > 0;
  }

  /**
   * @brief Appends the specified content to a file
   * @param sFileName   File in which to append the sContent
   * @param sContent    Content to append
   * @return In the event of an error < 0, otherwise 0.
   */
  private static int addContent(const string &sFileName, const string &sContent)
  {
    int iResult = -1;
    file f = fopen(sFileName, "a+");

    if (f != 0)
    {
      iResult = 0;

      // Skip to the end
      fseek(f, 0, SEEK_END);

      // And add the content
      fputs(sContent + "\n", f);

      fclose(f);
    }

    return iResult;
  }

  /**
   * @brief Returns the absolute path of the 7-zip command
   * @return Absolute path of the 7-zip command or empty string in case of failure
   */
  private static string getZipCommand()
  {
    // First try in the standard paths (PATH environment variable)
    string sResult = findExecutable(_WIN32 ? "7z" : "7za");

    if (sResult == "" && _WIN32)
    {
      // As a fallback try the standard 7-Zip location
      if (isfile("C:\\Program Files\\7-Zip\\7z.exe"))
      {
        sResult = "C:\\\"Program Files\"\\7-Zip\\7z.exe";
      }
    }

    return sResult;
  }
};
