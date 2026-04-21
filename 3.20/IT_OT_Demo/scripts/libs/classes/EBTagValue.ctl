// $License: NOLICENSE

//--------------------------------------------------------------------------------
// used libraries (#uses)

//--------------------------------------------------------------------------------
// declare variables and constans

//--------------------------------------------------------------------------------
/*!
 * @brief Handler for EBTagValue
 * @author Martin Schiefer
 */
class EBTagValue
{
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

  //------------------------------------------------------------------------------
  /** @brief Default c-tor
      @author Martin Schiefer
      @return initialized object of class EBTagValue
   */
  public EBTagValue()
  {
  }

  //------------------------------------------------------------------------------
  /** @brief Function returns value.
      @author Martin Schiefer
      @return value.
   */
  public anytype getVal()
  {
    return this.aValue;
  }

  //------------------------------------------------------------------------------
  /**
   * @brief Returns the formatted value.
   * @param sFormat Format string
   * @return Formatted value
   */
  public string getValFormated(const string &sFormat)
  {
    string sValue;
    sprintf(sValue, sFormat, this.aValue);
    return sValue;
  }

  //------------------------------------------------------------------------------
  /** @brief Function returns time of the value.
      @author Martin Schiefer
      @return time.
   */
  public time getTime()
  {
    return this.tStime;
  }

  //------------------------------------------------------------------------------
  /** @brief Function returns status bits of the value.
      @author Martin Schiefer
      @return status.
   */
  public bit64 getStatus()
  {
    return this.bStatus;
  }

  //------------------------------------------------------------------------------
  /** @brief Function returns manager who has wirten the value.
      @author Martin Schiefer
      @return status.
   */
  public string getManager()
  {
    return this.sManager;
  }


  //------------------------------------------------------------------------------
  /** @brief Function returns invalid.
      @author Martin Schiefer
      @return invalid.
   */
  public bool getInvalid()
  {
    bool bRet = FALSE;
    int iVal_exp_inv = getBit(this.bStatus, 5);
    int iVal_aut_inv = getBit(this.bStatus, 6);
    int iVal_stime_inv = getBit(this.bStatus, 17);
    if (iVal_exp_inv > -1 && iVal_aut_inv > -1 && iVal_stime_inv > -1)
    {
      bRet = iVal_exp_inv || iVal_aut_inv || iVal_stime_inv;
    }
    return bRet;
  }

  //------------------------------------------------------------------------------
  /** @brief Function sets the values.
      @author Martin Schiefer
      @param daVal dyn_anytpye with the value
      @param sName the name of the DPE
   */
  public void setValues(dyn_anytype daVal, string sName)
  {
    if (dynlen(daVal) == 4)
    {
      this.aValue = daVal[1];
      this.tStime = daVal[2];
      this.bStatus = daVal[3];
      convManIntToName(daVal[4], this.sManager);
    }
    this.sName = sName;
  }

  //------------------------------------------------------------------------------
  /** @brief Function sets the values.
      @author Martin Schiefer
      @param aVal1 the first value
      @param aVal2 the second value
      @param aVal3 the third value
      @param aVal4 the fourth value
      @param sName the name of the DPE
   */
  public void setSperateValues(anytype aVal1, anytype aVal2, anytype aVal3, anytype aVal4, string sName)
  {
    dyn_anytype daVal = makeDynAnytype(aVal1, aVal2, aVal3, aVal4);
    this.setValues(daVal, sName);
  }

  //------------------------------------------------------------------------------
  /** @brief Function gets the values as json string .
      @author Martin Schiefer
      @return string the json string
   */
  public string toJson()
  {
    mapping mRes = makeMapping("Value", aValue,
                               "Stime", tStime,
                               "Status", bStatus,
                               "Manager", sManager,
                               "Id", sName);
    return jsonEncode(mRes);
  }


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
  anytype aValue; //:_online.._value
  time tStime; //:_online.._stime
  bit64 bStatus; //:_online.._status64
  //int iManager;  //:_online.._manager
  string sManager;
  string sName;
};
