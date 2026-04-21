// $License: NOLICENSE

/**
 * @file scripts/libs/classes/SymbolPreLoader.ctl
 * @brief Contains the SymbolPreLoader class, which provides some functions to help download pictures to the client.
 * @author Martin Schiefer
 */

/**
 * @brief Provides some functions to help download pictures to the client.
 */
class SymbolPreLoader
{
  /**
    @brief Loads the stylesheet.css and load all pictures that are included in the file.
    @author Martin Schiefer
  */
  public static void fromCSS()
  {
    string sFileName = getPath(CONFIG_REL_PATH, "stylesheet.css");
    string sFileContent;
    fileToString(sFileName, sFileContent);

    string sSearchText = "url(pictures:";
    string sFoundText;
    dyn_string dsFoundText;
    int iStartPos = strpos(sFileContent, sSearchText);

    while (iStartPos > 0)
    {
      iStartPos = iStartPos + strlen(sSearchText);
      int iEndPos = strpos(sFileContent, ")", iStartPos);
      sFoundText = substr(sFileContent, iStartPos, iEndPos - iStartPos);
      sFileContent = substr(sFileContent, iEndPos);

      dynAppend(dsFoundText, sFoundText);
      iStartPos = strpos(sFileContent, sSearchText);
    }

    dynUnique(dsFoundText);

    for (int i = 1; i <= dynlen(dsFoundText); i++)
    {
      getPath(ICONS_REL_PATH, dsFoundText[i]);
    }
  }
};
