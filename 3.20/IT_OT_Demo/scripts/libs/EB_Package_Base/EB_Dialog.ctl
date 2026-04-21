#uses "EB_Package_Base/EB_Api"

global bool bIsUlcUxUI = isFunctionDefined("getApplicationProperty") && getApplicationProperty("platformName") == "ulc";    //!< Indicates if function is executed from an ULC UX UI

/**
 * @file libs/EB_Package_Base/EB_Dialog.ctl
 * @brief The dialog framework allows to open standard dialogs
 * @details EB_openDialogInformation/EB_openDialogWarning/EB_openDialogQuestion will display text and return 0 or 1 (depending on pressed button)
 * EB_openDialog and EB_openDialogRetVal allows specify an one reference panel (string sPanelRefFile) which will be added as content of the dialog (and allow to avoid closing)
 * if an own reference content panel is use, the public function public bool requestedCloseOk(int iChoice, anytype &aRetValue) can be implemented to allow return value and to cancel closing
 */

/**
  @brief function for opening a dialog with information text
  @param sText text to display
  @param msgKey_ButtonTextOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param msgKey_ButtonTextNOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param sHelpLink option for defining a help page, which can be opened as popup, if "", no help button is shown
  @param bEnableAllButtons option for enabling all buttons (otherwise button 1 is disabled)
  @return selected button 0 = NOK button, 1 = OK button
*/
int EB_openDialogInformation(string sText, string msgKey_ButtonTextOk = "", string msgKey_ButtonTextNOk = "close", string sHelpLink = "", bool bEnableAllButtons = TRUE)
{
  return EB_openDialog(makeDynString("$TEXT:" + sText), "objects/dialog/dialog_subText.pnl", getCatStr("EB_Package_Base", "information"), msgKey_ButtonTextOk, msgKey_ButtonTextNOk, "EB_Package/dialogInformation.svg", "Separator", sHelpLink, bEnableAllButtons);
}

/**
  @brief function for opening a dialog with warning text
  @param sText text to display
  @param msgKey_ButtonTextOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param msgKey_ButtonTextNOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param sHelpLink option for defining a help page, which can be opened as popup, if "", no help button is shown
  @param bEnableAllButtons option for enabling all buttons (otherwise button 1 is disabled)
  @return selected button 0 = NOK button, 1 = OK button
*/
int EB_openDialogWarning(string sText, string msgKey_ButtonTextOk = "", string msgKey_ButtonTextNOk = "close", string sHelpLink = "", bool bEnableAllButtons = TRUE)
{
  return EB_openDialog(makeDynString("$TEXT:" + sText), "objects/dialog/dialog_subText.pnl", getCatStr("EB_Package_Base", "warning"), msgKey_ButtonTextOk, msgKey_ButtonTextNOk, "EB_Package/dialogWarning.svg", "defCol02", sHelpLink, bEnableAllButtons);
}

/**
  @brief function for opening a dialog with text and two options to select
  @param sText text to display
  @param msgKey_ButtonTextOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param msgKey_ButtonTextNOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param sHelpLink option for defining a help page, which can be opened as popup, if "", no help button is shown
  @param bEnableAllButtons option for enabling all buttons (otherwise button 1 is disabled)
  @return selected button 0 = NOK button, 1 = OK button
*/
int EB_openDialogQuestion(string sText, string msgKey_ButtonTextOk = "yes", string msgKey_ButtonTextNOk = "no", string sHelpLink = "", bool bEnableAllButtons = TRUE)
{
  return EB_openDialog(makeDynString("$TEXT:" + sText), "objects/dialog/dialog_subText.pnl", getCatStr("EB_Package_Base", "question"), msgKey_ButtonTextOk, msgKey_ButtonTextNOk, "EB_Package/dialogQuestion.svg", "Separator", sHelpLink, bEnableAllButtons);
}

/**
  @brief function for opening a dialog with text and two options to select
  @param sTitle title to show in dialog header
  @param sText text to be displayed before the input value field
  @param sText2 text to display after the value (e.g. the unit)
  @param aValue start and return value
  @param sCheckForType Check if the value is of the specified type (default: no type check)
  @param msgKey_ButtonTextOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param msgKey_ButtonTextNOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param sHelpLink option for defining a help page, which can be opened as popup, if "", no help button is shown
  @param bEnableAllButtons option for enabling all buttons (otherwise button 1 is disabled as long the value does not differ from start value)
  @return selected button 0 = NOK button, 1 = OK button
*/
int EB_openDialogInput(const string &sTitle, const string &sText, const string &sText2, anytype &aValue, string sCheckForType = "", string msgKey_ButtonTextOk = "apply", string msgKey_ButtonTextNOk = "cancel", string sHelpLink = "", bool bEnableAllButtons = FALSE)
{
  //use mapping to transfer correct datatype
  mapping mValue = makeMapping("value", aValue, "type", getType(aValue));
  int iRet = EB_openDialogRetVal(makeDynString("$TEXT:" + sText, "$TEXT2:" + sText2, "$TYPE:" + sCheckForType, "$VALUE:" + jsonEncode(mValue), "$BOOL_ALWAYS_ENABLE_APPLY:" + bEnableAllButtons), "objects/dialog/dialog_subInput.pnl", sTitle, mValue, msgKey_ButtonTextOk, msgKey_ButtonTextNOk, "EB_Package/dialogEdit.svg", "Separator", sHelpLink, bEnableAllButtons);
  if (iRet != 0)
  {
    aValue = mValue["value"];
  }
  return iRet;
}

/**
  @brief function for opening a generic dialog, which displays content via a given panel reference (dialog sub panel)
  @param dsParams Dollar parameters for the dialog sub panel
  @param sPanelRefFile file name of the dialog sub panel
  @param sTitle title to show in dialog header
  @param msgKey_ButtonTextOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param msgKey_ButtonTextNOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param sIcon optional file name of an icon file, if "", no icon will be shown
  @param sTitleColor option color for header background, if "", default color will be used
  @param sHelpLink option for defining a help page, which can be opened as popup, if "", no help button is shown
  @param bEnableAllButtons option for enabling all buttons (otherwise button 1 is disabled)
  @return selected button 0 = NOK button, 1 = OK button
*/
int EB_openDialog(const dyn_string &dsParams, const string &sPanelRefFile, const string &sTitle, string msgKey_ButtonTextOk = "", string msgKey_ButtonTextNOk = "", string sIcon = "", string sTitleColor = "", string sHelpLink = "", bool bEnableAllButtons = TRUE)
{
  anytype aReturnValue;
  return EB_openDialogRetVal(dsParams, sPanelRefFile, sTitle, aReturnValue, msgKey_ButtonTextOk, msgKey_ButtonTextNOk, sIcon, sTitleColor, sHelpLink, bEnableAllButtons);
}

/**
  @brief function for opening a generic dialog, which displays content via a given panel reference (dialog sub panel) and returns an anytype value via reference parameter
  @param dsParams Dollar parameters for the dialog sub panel
  @param sPanelRefFile file name of the dialog sub panel (if function public bool requestedCloseOk(int iChoice, anytype &aRetValue) exists, this will be executed before closing
  @param sTitle title to show in dialog header
  @param aReturnValue anytype reference parameter used to via public bool requestedCloseOk(int iChoice, anytype &aRetValue) on dialog sub panel
  @param msgKey_ButtonTextOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param msgKey_ButtonTextNOk yes/no/ok/cancel/close message catalogue key from button OK text, will be taken from EB_Package_Base.cat, if "", button will be invisible
  @param sIcon optional file name of an icon file, if "", no icon will be shown
  @param sTitleColor option color for header background, if "", default color will be used
  @param sHelpLink option for defining a help page, which can be opened as popup, if "", no help button is shown
  @param bEnableAllButtons option for enabling all buttons (otherwise button 1 is disabled)
  @return selected button 0 = NOK button, 1 = OK button
*/
int EB_openDialogRetVal(dyn_string dsParams, const string &sPanelRefFile, const string &sTitle, anytype &aReturnValue, string msgKey_ButtonTextOk = "", string msgKey_ButtonTextNOk = "", string sIcon = "", string sTitleColor = "", string sHelpLink = "", bool bEnableAllButtons = TRUE)
{
  if (msgKey_ButtonTextOk != "")
  {
    msgKey_ButtonTextOk = getCatStr("EB_Package_Base", msgKey_ButtonTextOk);
  }
  if (msgKey_ButtonTextNOk != "")
  {
    msgKey_ButtonTextNOk = getCatStr("EB_Package_Base", msgKey_ButtonTextNOk);
  }

  dynAppend(dsParams, "$Btn0:"             + msgKey_ButtonTextNOk);
  dynAppend(dsParams, "$Btn1:"             + msgKey_ButtonTextOk);
  dynAppend(dsParams, "$TitleText:"        + sTitle);
  dynAppend(dsParams, "$PanelRef:"         + sPanelRefFile);
  dynAppend(dsParams, "$ICON:"             + sIcon);
  dynAppend(dsParams, "$TITLECOLOR:"       + sTitleColor);
  dynAppend(dsParams, "$HelpLink:"         + sHelpLink);           //if help is set, the dollar parameter activates (shows) the help button
  dynAppend(dsParams, "$EnableAllButtons:" + bEnableAllButtons);   //if help is set, the dollar parameter activates (shows) the help button

  int iRet; //default is cancel

  // to allow dialog started from dialog, panel name needs to be unique
  string sPanelDefault = "dialog";
  string sPanel = sPanelDefault;
  int iCount = 0;

  while (isPanelOpen(sPanel))
  {
    iCount++;
    sPanel = sPanelDefault + "_" + iCount;
  }

  mapping mOptions = makeMapping("makeVisible", FALSE);
  dyn_anytype da = makeDynAnytype(myModuleName(), "objects/dialog/dialog.pnl", myPanelName(), sPanel,
                                  50, 50, 1.0, FALSE, dsParams,
                                  //nativly not modal, because of touchscreen keyboard
                                  bIsUlcUxUI, //modal - there will be no half transparent cover of background (transparent panel background is not supported by ULC UX)
                                  mOptions);
  anytype daReturn;
  childPanel(da, daReturn);
  if (dynlen(daReturn) > 0) // ALT + F4 was not pressed
  {
    iRet = daReturn[1];
  }

  if (dynlen(daReturn)>1 && strlen(daReturn[2])>0 && iRet != 0) //ok button pressed, otherwise do not modify return value
  {
    aReturnValue = jsonDecode(daReturn[2]);
  }

  return iRet; //button number
}

/**
 * @brief function for requesting close of dialog (can be triggered from dialog content reference panel) to close dialog
 * @param iButton  Used button to close the dialog (return value of the open dialog function)
 */
void EB_closeDialog(int iButton)
{
  //search for dialog panel and execute the doColos function
  shape shParent = getShape(myModuleName() + "." + myPanelName() + ":");
  invokeMethod(shParent, "doClose", iButton);
}

/**
  @brief function enablind and disabling dialog buttons
  @param bEnable true for enabling and flase for disabling buttons
  @param iButtonNr number of button to enable or disable, default -1 means all buttons
*/
void EB_dialogButtonEnabled(bool bEnable, int iButtonNr = -1)
{
  if (iButtonNr == -1) //all buttons
  {
    setMultiValue("Btn0", "enabled", bEnable,
                  "Btn1", "enabled", bEnable);
  }
  else
  {
    setValue("Btn" + iButtonNr, "enabled", bEnable);
  }
}

/**
 * @brief function for opening a dialog to edit a multi language string
 * @param lsText        Multi language text which should be edited
 * @param sHeaderText   Optional: text to show in the header
 * @return success 0 = nothing changed, 1 = multi language string changed
 */
int EB_openDialogMultiLang(langString &lsText, const string sHeaderText = "")
{
  // The return value is always a decoded json string, so make sure the provided value has the right type
  string sJson = jsonEncode(lsText);
  dyn_mapping dmBuff = jsonDecode(sJson);

  int iRet = EB_openDialogRetVal(makeDynString("$TEXT:" + sJson, "$HEADER:" + sHeaderText), "objects/dialog/multiLangEditor.pnl", "", dmBuff);
  lsText = EB_mappingToLangString(dmBuff[1]);

  return iRet;
}

/**
 * @brief This is the utility class for dialogs. It contains various useful members for dialogs.
 */
class EB_Dialog
{
  public static const int BUTTON_NOK = 0; //!< Returned value if clicked on the NOK button
  public static const int BUTTON_OK  = 1; //!< Returned value if clicked on the OK button
};
