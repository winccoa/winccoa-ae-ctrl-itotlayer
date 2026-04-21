// $License: NOLICENSE

/**
 * @file scripts/libs/EB_Package_Base/EB_UtilsFile.ctl
 * @brief Contains various useful functions for file handling.
 */

/**
 * @brief This is the utility class for file handling.
 */
class EB_UtilsFile
{
  /**
   * @brief Returns if the specified path is absolute
   * @param sPath  Path to check
   * @return TRUE -> Path is absolute
   */
  public static bool isAbsolute(const string &sPath)
  {
    bool bResult = FALSE;

    // On windows absolute paths are at least 3 characters and the second is the drive separator
    if (_WIN32 && strlen(sPath) >= 3 && sPath[1] == ':')
    {
      bResult = TRUE;
    }
    // On all other systems absolute paths start with a slash
    else if (!_WIN32 && strlen(sPath) > 0 && sPath[0] == '/')
    {
      bResult = TRUE;
    }

    return bResult;
  }

  /**
   * @brief Writes content to the specified file
   * @param sFileName   File to write
   * @param aContent    Content to write
   * @return Number of written bytes OR in case of errors the function returns a negative number
   */
  public static int writeToFile(const string &sFileName, const anytype &aContent)
  {
    int iResult = -1;
    bool bBlob = getType(aContent) == BLOB_VAR;

    file f = fopen(sFileName, "w" + (bBlob ? "b" : ""));

    if (f != 0)
    {
      iResult = bBlob ? blobWrite(aContent, f) : fputs(aContent, f);

      fclose(f);
    }

    return iResult;
  }

  /**
   * @brief Returns a list of file hashes for the specified files
   * @param sProjectDir   Project directory for the relative files
   * @param dsFiles       Files to generate the hashes for
   * @return list of file hashes
   */
  public static dyn_string getFileHashes(const string &sProjectDir, const dyn_string &dsFiles)
  {
    dyn_string dsResult;

    for (int i = 1; i <= dynlen(dsFiles); i++)
    {
      string sFileName = getPath(sProjectDir, dsFiles[i]);

      dsResult[i] = sFileName == "" ? "" : getFileCryptoHash(sFileName, "SHA256");
    }

    return dsResult;
  }

  /**
   * @brief Returns a list of loaded libraries
   * @param iManId Manager to get the list from
   * @return List of loaded libraries
   */
  public static dyn_string getLoadedLibraries(int iManId = myManId())
  {
    const string DP_CTRL_DEBUG        = "_CtrlDebug_" + getManDpPart(iManId);
    const string NATIVE_REL_PATH_LIBS = makeNativePath(LIBS_REL_PATH);
    dyn_string dsResult;
    dyn_string dsDpesSet  = DP_CTRL_DEBUG + ".Command";
    dyn_string dsDpesWait = DP_CTRL_DEBUG + ".Result:_online.._value";

    if (dpExists(DP_CTRL_DEBUG))
    {
      dyn_string dsCommand = "info libs";
      dyn_anytype daValues;
      bool bTimeOutExpired;

      if (0 == dpSetAndWaitForValue(dsDpesSet, dsCommand, dsDpesWait, makeDynAnytype(), dsDpesWait, daValues, 1, bTimeOutExpired) && !bTimeOutExpired)
      {

        for (int i = 1; i <= dynlen(daValues[1]); i++)
        {
          string sLine = daValues[1][i];

          int iIndex = uniStrPos(sLine, NATIVE_REL_PATH_LIBS);

          if (iIndex >= 0)
          {
            dynAppend(dsResult, uniSubStr(sLine, iIndex + uniStrLen(NATIVE_REL_PATH_LIBS)));
          }
        }

        dynSort(dsResult);
        dynUnique(dsResult);
      }
    }

    return dsResult;
  }

  /**
   * @brief Returns a mapping of loaded libraries and file hash
   * @param iManId Manager to get the mapping from
   * @return Mapping of loaded libraries and file hash
   */
  public static mapping getLoadedLibHashes(int iManId = myManId())
  {
    mapping mLibraries;
    dyn_string dsLibraries = getLoadedLibraries(iManId);
    dyn_string dsLibHashes = getFileHashes(LIBS_REL_PATH, dsLibraries);

    for (int i = 1; i <= dynlen(dsLibraries); i++)
    {
      string sKey = dsLibraries[i];

      mLibraries[sKey] = dsLibHashes[i];
    }

    return mLibraries;
  }

  /**
   * @brief Returns the manager identifier part in dps
   * @details Example: UI 1 -> UI_1, Control 2 -> CTRL_2
   * @param iManId Manager id to get the dp id part for (default: myManId)
   * @return Manager identifier part in dps
   */
  private static string getManDpPart(int iManId = myManId())
  {
    string sResult;

    convManIntToName(iManId, sResult);

    strreplace(sResult, " -num ", "_");

    return sResult;
  }

};
