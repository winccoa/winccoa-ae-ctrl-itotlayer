// $License: NOLICENSE
//--------------------------------------------------------------------------------
/** Prepare automatic test run for MNSP_Connect.
 *  - Add the testframework subproject to config file
 *  - Disable codemeter licensing during tests
 */

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "CtrlPv2Admin"


//--------------------------------------------------------------------------------
// Variables and Constants
const string CFG_FILE_PATH = PROJ_PATH + CONFIG_REL_PATH + "config";

const string CFG_SECTION_GENERAL = "general";

const string CFG_KEY_PROJ_PATH  = "proj_path";
const string CFG_KEY_CM_LICENSE = "useCMLicense";
const string CFG_KEY_LANG       = "lang";

const string TEST_FRAMEWORK_SUB_PROJ = "/opt/WinCC_OA/3.19/TestFramework_3.19";


//--------------------------------------------------------------------------------
main()
{
  int iErr;
  bool bCmLicense;
  bool bIsDefault;
  dyn_string dsCfgEntries;

  DebugTN("preparing project for testrun...");

  iErr = paCfgReadValueList(CFG_FILE_PATH, CFG_SECTION_GENERAL, CFG_KEY_PROJ_PATH, dsCfgEntries);
  if(iErr != 0)
  {
    DebugTN("Could not read config key (" + CFG_KEY_PROJ_PATH + ")", "Error code <" + iErr + ">");
    exit(1);
  }

  if(!dsCfgEntries.contains(TEST_FRAMEWORK_SUB_PROJ))
  {
    iErr = paCfgInsertValue(CFG_FILE_PATH, CFG_SECTION_GENERAL, BEFORE_FIRST_KEY, CFG_KEY_PROJ_PATH,
                            CFG_KEY_PROJ_PATH, TEST_FRAMEWORK_SUB_PROJ);
    if(iErr != 0)
    {
      DebugTN("Could not set test framework sub project in config file <" + iErr + ">");
      exit(1);
    }
  }

  bCmLicense = paCfgReadValueDflt(CFG_FILE_PATH, CFG_SECTION_GENERAL, CFG_KEY_CM_LICENSE, TRUE, bIsDefault);
  if(bCmLicense)
  {
    if(!bIsDefault)
    {
      iErr = paCfgDeleteValue(CFG_FILE_PATH, CFG_SECTION_GENERAL, CFG_KEY_CM_LICENSE);
      if(iErr != 0)
      {
        DebugTN("Could delete  disable codemeter license <" + iErr + ">");
        exit(1);
      }
    }

    iErr = paCfgInsertValue(CFG_FILE_PATH, CFG_SECTION_GENERAL, AFTER_LAST_KEY, CFG_KEY_LANG,
                            CFG_KEY_CM_LICENSE, FALSE);
    if(iErr != 0)
    {
      DebugTN("Could not disable codemeter license <" + iErr + ">");
      exit(1);
    }
  }

  DebugTN("preparation done");
  exit(0);
}
