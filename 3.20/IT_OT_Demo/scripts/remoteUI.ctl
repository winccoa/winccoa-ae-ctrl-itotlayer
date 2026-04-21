// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author atw121x7
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/**
*/
main()
{
  dpConnect("workUpdateTriggered", FALSE, "MindSphereConnector.packageUpdate");
}

/**
 * @brief Workaround for the Remote UI of the Mindsphereconnector...Touches the files in a folder on the serve so that the fileWatcher recognizes a filehandle
 */
void fileToucher()
{
  string sPath = getPath(DATA_REL_PATH + "packages");
  string sCmd = "touch " + sPath + "/" + "state.box";

  while(TRUE)
  {
    delay(10);
    system(sCmd);
  }
}


workUpdateTriggered(string s, bool b)
{
  string sPath = getPath(DATA_REL_PATH + "packages");
  string sCmd = "touch " + sPath + "/" + "state.box";

  delay(0,200);
  system(sCmd);
}
