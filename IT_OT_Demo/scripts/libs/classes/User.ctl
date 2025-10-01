// $License: NOLICENSE

/**
 * @file scripts/libs/classes/User.ctl
 * @brief Contains the User class.
 * @author mPokorny
 */

//--------------------------------------------------------------------------------
// used libraries (#uses)

//--------------------------------------------------------------------------------
// declare variables and constants

/**
 * @brief Defines the enum Role.
 */
enum Role
{
  Undefined,
  Maintainer,
  Manager,
  Operator,
  Guest
  // ...
};

//--------------------------------------------------------------------------------
/** @brief This is a User class for user management derived from BasicUser.
 *   @author mPokorny
 */
class User
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Default constructor
   * @param id     User id
   */
  public User(uint id = getUserId())
  {
    if (id < 0 )
    {
      this.uId = -1;
      return this; // given ID is not valid
    }

    this.uId = id;
    if (readProps() )
    {
      this.uId = -1;
    }

    if (id != DEFAULT_USERID)
    {
      readUsrProps();
    }
    return this;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**  Static Method that proofs if the id already exsits
   *  @param uId    The user id to check
   *  @return TRUE -> if the id exists, FALSE -> the id not exists
   */
  public static bool exists(uint uId)
  {
    return (getUsrIdx(uId) > 0);
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**  Static Method that return all ids2
   *  @return dyn_uint ids
   */
  public static dyn_uint getAllIds()
  {
    dyn_uint ids;
    if (dpExists("_Users.UserId") )// in case of no data/event connection
    {
      dpGet("_Users.UserId", ids);
    }
    return ids;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**  Method to get the id of the basicuser
   *  @return The id of the user
   */
  public uint getId()
  {
    return this.uId;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Method returns the group id
   * @return int 0 when OK
   */
  public uint getGroupId()
  {
    return this.uGroupId;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Method sets the GroupId
   * @param uId -> new GroupId
   * @return int 0 when OK or -1 if the id is < 0
   */
  public int setGroupId(uint uId)
  {
    if (uId < 0 )
    {
      return -1;
    }

    this.uGroupId = uId;
    return 0;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**  Method returns the full name
   *  @return langstring fullName
   */
  public langString getFullName()
  {
    return this.lsName;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Sets the full name
   * @param lsName Full name of the user
   * @return int 0 when OK or -1 if a text missing in the langstring(e.g. not all languages have a text assigned)
   */
  public int setFullName(const langString &lsName)
  {
    if (checkLs(lsName))
    {
      return -1;
    }

    this.lsName = lsName;
    return 0;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Method returns the permission set
   * @return bit32 permissions
   */
  public bit32 getPermissionSet()
  {
    return this.b32Permissions;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Method sets the PermissionSet
   * @param b32PermissionSet
   * @return int 0 when OK
   */
  public int setPermissionSet(bit32 b32PermissionSet)
  {
    this.b32Permissions = b32PermissionSet;
    return 0;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Method checks if the user has the forwarded permLevel
   * @param iPermLevel
   * @return TRUE if the user has the permissionlevel otherwise FALSE
   */
  public bool hasPermision(int iPermLevel)
  {
    if ((iPermLevel < 0) || (iPermLevel > 31))
    {
      return FALSE;
    }

    return getBit(this.b32Permissions, iPermLevel);
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Method  can set a forwarded permLevel to TRUE or FALSE
   * @param iPermLevel
   * @param bOn
   * @return int 0 when OK
   *            -1 not existing permLevel
   *            -2 when an error happend
   */
  public int setPermision(int iPermLevel, bool bOn)
  {
    if ((iPermLevel < 0) || (iPermLevel > 31))
    {
      return -1;
    }

    if (setBit(this.b32Permissions, iPermLevel, bOn))
    {
      return -2;
    }

    return 0;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**  Method return the Description of the permLevel
   *  @param iPermLevel
   *  @return langString descrition and "" if there is no description
   */
  public langString getPermissionName(int iPermLevel)
  {
    if (iPermLevel < 0)
    {
      return "";
    }

    dyn_langString dls;
    dpGet("_Users.PermissionDes", dls);
    iPermLevel++; // started by idx 1
    if (dynlen(dls) < iPermLevel)
    {
      return "";
    }

    return dls[iPermLevel];
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Returns user role as int
   * @return Role
   */
  public int getRole()
  {
    return (int)eRole;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Sets the role of the user
   * @param eRole
   */
  public void setRole(const Role &eRole)
  {
    this.eRole = eRole;
    setChangeFlag(TRUE);
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns if this user has the manager role
   * @return TRUE if user has the manager role
   */
  public bool isManager()
  {
    if (eRole == Role::Manager || eRole == Role::Maintainer)
    {
      return TRUE;
    }

    return FALSE;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns if this user has the super admin role
   * @return TRUE if user has the super admin role
   */
  public bool isSuperAdmin()
  {
    return eRole == Role::Maintainer;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns if this user has the view only (guest) role
   * @return TRUE if user has the view only role
   */
  public bool isViewOnly()
  {
    if (eRole == Role::Guest)
    {
      return TRUE;
    }

    return FALSE;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns if this user has defined role
   * @return TRUE if user does not have a valid role
   */
  public bool isNotUndefined()
  {
    return eRole != Role::Undefined;
  }

  //------------------------------------------------------------------------------
  /**
    @brief Returns if this user has the specified minimum role
    @param eMinRole The role to check against
    @return TRUE -> User has at least the specified role
  */
  public bool hasMinimumRequiredRole(Role eMinRole)
  {
    if (this.isNotUndefined())
    {
      int iCurrentRole = (int)eRole;
      int iMinRole = (int)eMinRole;
      return iCurrentRole <= iMinRole;
    }
    return false;
  }

  //------------------------------------------------------------------------------
  /** @brief Returns a mapping of most attributes
   *  @return properties
   */
  public mapping getProperties()
  {
    return makeMapping("Id", makeMapping("Value", uId, "Access", "R"),
                       "FullName", makeMapping("Value", getFullName(), "Access", "RW"),
                       "GroupId", makeMapping("Value", getGroupId(), "Access", "RW"),
                       "PermissionSet", makeMapping("Value", getPermissionSet(), "Access", "RW"),
                       "Role", makeMapping("Value", getRole(), "Access", "RW")
                       );
  }

  //------------------------------------------------------------------------------
  /** @brief Saves the attributes on DPs
   *  @return 0 if OK and < 0 if an error happened
   */
  public int save()
  {
    if (!isChanged())
    {
      return 0;
    }

    if (saveUserDp())
    {
      return -1;
    }

  	if (isFunctionDefined("hook_user_afterSave"))
   {
	    hook_user_afterSave(this);
   }

    setChangeFlag(FALSE);
    return 0;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns a pointer to the currently logged in user
   * @return Pointer to the currently logged in user
   */
  static public shared_ptr<User> getLoggedIn()
  {
    if (spLoggedInUser == nullptr)
    {
      spLoggedInUser = new User();
    }

    return spLoggedInUser;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Logs out the user. sets the shared_ptr to nullptr so that a new ptr is created when asking for it
   */
  static public void logoutUser()
  {
    spLoggedInUser = nullptr;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns the name of the specified role
   * @param eRole  Role to get the name from
   * @return Name of the specified role
   */
  static public string getRoleName(Role eRole)
  {
    string result;

    switch (eRole)
    {
      case Role::Guest:         result = "View Only";    break;
      case Role::Operator:      result = "Operator";     break;
      case Role::Manager:       result = "Admin";        break;
      case Role::Maintainer:    result = "Super Admin";  break;
      case Role::Undefined:     result = "Undefined";    break;
      default:
        result = "Unknown <" + (int)eRole + ">";
        break;
    }

    return result;
  }

//--------------------------------------------------------------------------------
//@protected members
//--------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Returns the index of the specified user
   * @param uId The user id
   * @return Index of the user
   */
  protected static int getUsrIdx(uint uId)
  {
    return dynContains(getAllIds(), uId);
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Reads the user properties from the database in the internal variables
   * @return < 0 -> Error, 0 -> Success
   */
  protected int readProps()
  {
    int idx = getUsrIdx(uId);

    if (idx <= 0)
    {
      return -1;
    }

    dyn_uint duGroups;
    dyn_langString dlNames;
    dyn_bit32 dbPermissions;
    dyn_string dsLangs;

    dpGet("_Users.GroupIds", duGroups,
          "_Users.FullName", dlNames,
          "_Users.PermissionSet", dbPermissions,
          "_Users.Language", dsLangs);

    if ((dynlen(duGroups) < idx) || (dynlen(dlNames) < idx) ||
        (dynlen(dbPermissions) < idx) || (dynlen(dsLangs) < idx))
    {
      return -2;
    }

    uGroupId     = duGroups[idx];
    lsName        = dlNames[idx];
    b32Permissions = dbPermissions[idx];
    sLang        = dsLangs[idx];
    return 0;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------
  /**
   * @brief Write the user properties in the database from the internal variables
   * @return < 0 -> Error, 0 -> Success
   */
  protected int saveUserDp()
  {
    string sUser;
    int idx = getUsrIdx(uId);

    if (idx <= 0)
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to save user", "idx is invalid"));
      return -1;
    }

    if (!lockObject(makeDynString("_Users.GroupIds", "_Users.FullName", "_Users.PermissionSet", "_Users.Language"), user, FALSE) )
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to save user", "Unable to acquire lock"));
      return -2;
    }

    dyn_uint duGroups;
    dyn_langString dlNames;
    dyn_bit32 dbPermissions;
    dyn_string dsLangs;

    dpGet("_Users.GroupIds", duGroups,
          "_Users.FullName", dlNames,
          "_Users.PermissionSet", dbPermissions,
          "_Users.Language", dsLangs);

    if ((dynlen(duGroups) < idx) || (dynlen(dlNames) < idx) ||
        (dynlen(dbPermissions) < idx) || (dynlen(dsLangs) < idx))
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to save user", "Invalid database value lengths"));
      unlockObject(makeDynString("_Users.GroupIds", "_Users.FullName", "_Users.PermissionSet", "_Users.Language"));
      return -3;
    }

    duGroups[idx] = uGroupId;
    dlNames[idx] = lsName;
    dbPermissions[idx] = b32Permissions;
    dsLangs[idx] = sLang;

    if (dpSetWait("_Users.GroupIds", duGroups,
                  "_Users.FullName", dlNames,
                  "_Users.PermissionSet", dbPermissions,
                  "_Users.Language", dsLangs))
    {
      throwError(makeError("", PRIO_SEVERE, ERR_SYSTEM, 54, "Unable to save user", "dpSet failed"));
      throwError(getLastError());
      unlockObject(makeDynString("_Users.GroupIds", "_Users.FullName", "_Users.PermissionSet", "_Users.Language"));
      return -4;
    }

    if (!unlockObject(makeDynString("_Users.GroupIds", "_Users.FullName", "_Users.PermissionSet", "_Users.Language")))
    {
      throwError(makeError("", PRIO_WARNING, ERR_SYSTEM, 54, "Unable to release lock"));
      return -5;
    }

    return 0;
  }

  /**
   * @brief Sets the changed flag
   * @param changed     Flag to set
   */
  protected void setChangeFlag(bool changed)
  {
    this.bChanged = changed;
  }

  /**
   * @brief Returns the changed flag
   * @return Changed flag
   */
  protected bool isChanged()
  {
    return this.bChanged;
  }

  protected uint uId;        //!< Id of this user
  protected bool bChanged;   //!< Some flag

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
  uint uGroupId;        //!< Group id of this user
  langString lsName;     //!< Full name of this user
  bit32 b32Permissions;   //!< Permission bits of this user
  string sLang;         //!< Language of this user
  Role eRole;
  static private shared_ptr<User> spLoggedInUser = nullptr;

  //------------------------------------------------------------------------------
  private int readUsrProps()
  {
    if (getUserPermission(9, this.uId))
    {
      eRole = (int)Role::Maintainer;
    }
    else if (getUserPermission(8, this.uId))
    {
      eRole = (int)Role::Manager;
    }
    else if (getUserPermission(7, this.uId))
    {
      eRole = (int)Role::Operator;
    }
    else if (getUserPermission(6, this.uId))
    {
      eRole = (int)Role::Guest;
    }
    else
    {
      eRole = (int)Role::Undefined;
    }

    return 0;
  }

  //---------------------------------------------------------------------------------------------------------------------------------------
  /**
    Checks if every langString has a corresponding text set in every language
    @cond @author Pokorny, Martin @endcond
    @param lsToCheck   langString to be checked
    @return int ErrorCode
      0 ... Text set for every language
     -1 ... Text NOT set for at least one language
     -2 ... Text NOT set for all languages
  */
  private int checkLs(const langString &lsToCheck)
  {
    string textOfLang;
    int numOfLangsWithText = 0;
    const int _NUMBER_OF_LANGS = getNoOfLangs();

    for (int i = 1; i <= _NUMBER_OF_LANGS; i++)
    {
      textOfLang = lsToCheck[i - 1];  //Der Index der Sprachen beginnt bei 0

      if (textOfLang != "")
      {
        numOfLangsWithText++;
      }
    }

    if (_NUMBER_OF_LANGS == numOfLangsWithText)  //Text setet for every language - Ok
    {
      return 0;
    }
    else if (numOfLangsWithText > 0)   //Text NOT set for at least one language
    {
      return -1;
    }
    else   //Text NOT set for all languages
    {
      return -2;
    }
  }
};


//---------------------------------------------------------------------------------------------------------------------------------------
/**
  @brief function makes from given absolute path the realtive path to project
  @author Pokorny, Martin
  @param  absPath absolute path
  @param  key keyword (PICTURES_REL_PATH)
  @return string relative path. in case of error ""
*/
private string _getRelPath(string absPath, string key = "")
{
  if (absPath == "")
  {
    return "";
  }

  absPath = makeNativePath(absPath);
  dyn_string dsProjs;
  for (int i = 1; i <= SEARCH_PATH_LEN ; i++)
  {
    dsProjs[i] = makeNativePath(getPath("", "", "", i));
  }

  // check if absPath starts with some proj paths
  for (int i = 1; i <= dynlen(dsProjs) ; i++)
  {
    if (strpos(absPath, dsProjs[i]) == 0)
    {
      return substr(absPath, strlen(dsProjs[i]));
    }
  }

  // in remote-ui must be proj paths not equal
  if (key == "")
  {
    key = PICTURES_REL_PATH;
  }


  key = makeNativePath(key);
  int keyPos = strpos(absPath, key);
  if (keyPos == 0)
  {
    return absPath;
  }
  else if (keyPos > 0)
  {
    return substr(absPath, keyPos);
  }

  return "";
}
