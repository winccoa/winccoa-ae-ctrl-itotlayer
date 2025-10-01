// $License: NOLICENSE

/**
 * @file scripts/libs/classes/Driver/Factory.ctl
 */

//--------------------------------------------------------------------------------
// used libraries (#uses)

//--------------------------------------------------------------------------------
// declare variables and constants

//--------------------------------------------------------------------------------
/**
 * @brief Handler for Factory
 */
class Factory
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  //------------------------------------------------------------------------------
  /**
   * @brief Returns a mapping with instances of all plugins
   * @details Name of the plugin is used as mapping key
   * @return Mapping containing all plugins
   */
  public static mapping getPluginMapping()
  {
    mapping mResult;
    dyn_string dsNames = mappingKeys(mPlugins);

    dynSort(dsNames);

    for (int i = 1; i <= dynlen(dsNames); i++)
    {
      string sName = dsNames[i];

      mResult[sName] = callFunction(mPlugins[sName]);
    }

    return mResult;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Registers a plugin at this factory
   * @param sName       Name of the plugin to register
   * @param fpCreate    Pointer to the function to create an instance of the plugin
   * @return TRUE -> Plugin has been registered successfully
   */
  public static bool registerPlugin(const string &sName, function_ptr fpCreate)
  {
    bool bResult = !mappingHasKey(mPlugins, sName);

    DebugFN("FACTORY", __FUNCTION__ + "(" + sName + ", ...) Returning: " + bResult);

    if (bResult)
    {
      mPlugins[sName] = fpCreate;
    }

    return bResult;
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
  private static mapping mPlugins;
};
