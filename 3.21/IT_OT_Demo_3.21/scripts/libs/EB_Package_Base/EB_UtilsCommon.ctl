// $License: NOLICENSE

/**
 * @file libs/EB_Package_Base/EB_UtilsCommon.ctl
 * @brief Contains various useful functions for the UI.
 */

// used libraries (#uses)
#uses "EB_Package_Base/EB_const"

/**
 * @brief This is the utility class for the UI. It contains various useful functions for the UI.
 */
class EB_UtilsCommon
{
  /**
   * @brief Searches the catalog of the app.
   * @details If key is not found the base catalog will be searched.
   * If the key wasn't found in both catalogs the key will be returned.
   * @author Martin Schiefer
   * @param sAppName  The name of the app.
   * @param sKey  The key to search for.
   * @param iLang  The integer of the language (default: currentLang).
   */
  public static string getCatString(const string &sAppName, const string &sKey, int iLang = getActiveLang())
  {
    string sErrorMsgPart = ".cat not found";
    string sMsg = getCatStr(EB_PREFIX_PACKAGE + sAppName, sKey, iLang);

    if (strpos(sMsg, sErrorMsgPart) > -1)
    {
      sMsg = getCatStr(EB_PREFIX_PACKAGE + "Base", sKey, iLang);
      if (strpos(sMsg, sErrorMsgPart) > -1)
      {
        sMsg = sKey;
      }
    }
    return sMsg;
  }

  /**
   * @brief Searches the catalog of the app.
   * @details If key is not found the base catalog will be searched.
   * If the key wasn't found in both catalogs the key will be returned.
   * @author Daniel Lomosits
   * @param sAppName  The name of the app.
   * @param sKey  The key to search for.
   */
  public static langString getCatLangString(const string &sAppName, const string &sKey)
  {
    langString lsRet;
    for(int i = 0; i < getNoOfLangs(); i++)
    {
      setLangString(lsRet, i, getCatString(sAppName, sKey, i));
    }
    return lsRet;
  }

  /**
    @brief Gets the path with the 'EB_Package_' prefix for an appName.
    @author Martin Schiefer
    @param sAppName The appName.
    @return string The path.
  */
  public static string getPackagePath(const string &sAppName)
  {
    return EB_PREFIX_PACKAGE + sAppName;
  }

  /**
    @brief Sets the given text to the langtext.
    @author Martin Schiefer
    @param sText The text to set.
    @return langString The langstring.
  */
  public static langString getLangStringForString(const string &sText)
  {
    langString lsText;
    for (int i = 0; i < getNoOfLangs(); i++)
    {
      setLangString(lsText, i, sText);
    }
    return lsText;
  }


  /**
   * @brief gets the list of supported fractial digits.
   * @author Martin Schiefer
   * @return dyn_string the list.
   */
  public static dyn_string getFractionalDigits()
  {
    return makeDynString("FALSE", "-", "0", "1", "2", "3", "4", "5");
  }

  /**
   * @brief gets fractial digits from a format string or "-"
   * if the format string doesn't contain a "." and a "f".
   * @author Martin Schiefer
   * @return string fractial digits.
   */
  public static string getFractionalDigitsFromFormatString(const string &sFormat)
  {
    int iPointPos = strpos(sFormat, ".");
    int iFPos = strpos(sFormat, "f");
    if (iPointPos > 0 && iFPos > 0)
    {
      return substr(sFormat, iPointPos + 1, iFPos - (iPointPos + 1));
    }
    return "-";
  }

  /**
   * @brief gets the format string from the fractial digits.
   * if the factionional digits are not supported the format string is an emtpy string
   * @author Martin Schiefer
   * @return string the format string.
   */
  public static string getFormatStringFromFractionaldigits(const string &sFractionalDigits)
  {
    if (sFractionalDigits == "-")
    {
      return "";
    }
    return "%0." + sFractionalDigits + "f";
  }
};
