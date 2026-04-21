// $License: NOLICENSE
/**
 * @file scripts/libs/classes/EBlogEntry.ctl
 * @brief Contains the EBlogEntry class, which defines an log entry for the EBlog class.
 */

/**
 * @brief Entry is one alarm instance
 */
class EBlogEntry
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
  public langString lsText;                      //!< Log text
  public string sReason;                         //!< key for searching and removing
  public int iType;                              //!< alarm class 1-4
  public string sType;                           //!< DPE leaf
  public time tTime;                             //!< time of the log
  public int aCnt;                               //!< aCount of the atime
  public string sAppName;                        //!< Application owning the log entry
  public string sColor;                          //!< Log color (defined by the alert class)

  public static const int iLOG_ENTRY_TYPE_ERROR  = 1;   //!< Priority for errors
  public static const int iLOG_ENTRY_TYPE_STATUS = 2;   //!< Priority for status messages
  public static const int iLOG_ENTRY_TYPE_PARAM  = 3;   //!< Priority for parameter messages

  public static const string sDPT = "_EB_Log";   //!< (Embedded) dptype needed for the log functionality

  /**
    @author mtrummer
    @param sEntryType: entry tpye -> DPE leaf for the log (Runtime, Configuration, Internet, Periphery, Update)
    @param sEntryReason: reason for the log (e.g. IP, Port, Device, ...)
    @param lsEntryText: multi lingual text of the log entry (or sEntryTextKey will be used to get text from message catalogue)
    @param iEntryType: type/priority of the log entry -> part of the alarm class
    @param tEntryTime: time of log entry (when has the the failure or status change appeared)
    @param sEntryAppName: appName
    @param sEntryColor: current color of an entry (defined by alarm class)
    @param sEntryTextKey: message catalog entry key of log message - will be searched in "EB_Package_<AppName>" and "EB_Package" cat file
    @param mReplacePlaceholders: mapping with keys to be replaced in text e.g. $1:15, $2:287
  */
  public EBlogEntry(string sEntryType=LOG_TYPE_RUNTIME, string sEntryReason="", langString lsEntryText="", int iEntryType=1, time tEntryTime=0, string sEntryAppName="", string sEntryColor="", string sEntryTextKey="", mapping mReplacePlaceholders=makeMapping())
  {
    if(sEntryType=="" || sEntryReason=="" || (dynlen((dyn_string)lsEntryText)==0 && sEntryTextKey==""))
      return;
    setLogEntry(sEntryType, sEntryReason, lsEntryText, iEntryType, tEntryTime, sEntryAppName, sEntryColor, sEntryTextKey, mReplacePlaceholders);
  }

  /**
    @author mtrummer
    @param sEntryType: entry tpye -> DPE leaf for the log (Runtime, Configuration, Internet, Periphery, Update)
    @param sEntryReason: reason for the log (e.g. IP, Port, Device, ...)
    @param lsEntryText: multi lingual text of the log entry (or sEntryTextKey will be used to get text from message catalogue)
    @param iEntryType: type/priority of the log entry (iLOG_ENTRY_TYPE_ERROR, iLOG_ENTRY_TYPE_STATUS, iLOG_ENTRY_TYPE_PARAM)
    @param tEntryTime: time of log entry (when has the the failure or status change appeared)
    @param sEntryAppName: appName
    @param sEntryColor: current color of an entry (defined by alarm class)
    @param sEntryTextKey: message catalog entry key of log message - will be searched in "EB_Package_<AppName>" and "EB_Package" cat file
    @param mReplacePlaceholders: mapping with keys to be replaced in text e.g. $1:15, $2:287
  */
  public void setLogEntry(const string &sEntryType, const string &sEntryReason, const langString &lsEntryText, int iEntryType, time tEntryTime, string sEntryAppName, string sEntryColor="", string sEntryTextKey="", mapping mReplacePlaceholders=makeMapping())
  {
    sType    = sEntryType;
    sReason  = sEntryReason;
    lsText   = lsEntryText != "" ? lsEntryText : getLangTextFromCatStr("EB_Package_" + sEntryAppName, sEntryTextKey, mReplacePlaceholders);
    iType    = iEntryType;
    sAppName = sEntryAppName;
    sColor   = sEntryColor;
    tTime    = tEntryTime;   // Replace the 0 time as late as possible to keep track if a time was specified
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

  /**
    @author mtrummer
    @param sCatFile: message catalogue file name
    @param sKey: key to search for
    @param mReplacePlaceholders: mapping with keys to be replaced in text e.g. $1:15, $2:287
    @param bOwnLang: if ture, return just own language
  */
  private langString getLangTextFromCatStr(const string &sCatFile, const string &sKey, mapping mReplacePlaceholders=makeMapping(), bool bOwnLang=false)
  {
    if(bOwnLang)
    {
      string sTmp = getCatStr(sCatFile, sKey);
      if(dynlen(getLastError())>0) //if no entry in app specific file, search in EB_Package messager catalogue
        sTmp = getCatStr("EB_Package", sKey);
      replacePlaceholders(sTmp, mReplacePlaceholders);
      return (langString)sTmp;
    }
    else //search for each language
    {
      dyn_string ds;
      for(int i=0; i<getNoOfLangs(); i++)
      {
        ds[i+1] = getCatStr(sCatFile, sKey, i);
        if(dynlen(getLastError())>0) //if no entry in app specific file, search in EB_Package messager catalogue
          ds[i+1] = getCatStr("EB_Package", sKey, i);
        replacePlaceholders(ds[i+1], mReplacePlaceholders, i);
      }
      return (langString) ds;
    }
  }

  /**
    @author mtrummer
    @param sText: place in which placeholders will be replaced
    @param mReplacePlaceholders: mapping with keys to be replaced in text e.g. $1:15, $2:287
    @param iLang: the language index
  */
  private replacePlaceholders(string &sText, mapping &mReplacePlaceholders, int iLang=-1)
  {
    dyn_string dsKeys = mappingKeys(mReplacePlaceholders);
    for(int i=dynlen(dsKeys); i>0; i--)
    {
      string sTmp;
      if(iLang!=-1 && getType(mReplacePlaceholders[dsKeys[i]])==LANGSTRING_VAR)
      {
        DebugFN("REPLACE", "replacePlaceholders", mReplacePlaceholders[dsKeys[i]], (dyn_string)(mReplacePlaceholders[dsKeys[i]]));
        sTmp = ((dyn_string)(mReplacePlaceholders[dsKeys[i]]))[iLang+1];
      }
      else
        sTmp =mReplacePlaceholders[dsKeys[i]];
      strreplace(sText, dsKeys[i], sTmp);
    }
  }
};
