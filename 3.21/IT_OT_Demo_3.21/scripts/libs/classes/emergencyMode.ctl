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

enum eEmgergencyMode
{
  normalOperation,
  emergencyMemory,
  emergencyDisk,
  emergencyWaitForRestart
};

class EmergencyMode
{
#event stateUpdate(eEmgergencyMode currentState)

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
  public static void connectToStateChange(function_ptr fpCallback) synchronized(singletonEmergencyMode)
  {
    bool bFirstConnect;

    if (singletonEmergencyMode == nullptr)
    {
      DebugFTN("EmergencyMode", "EmergencyMode -> singelton to be created");
      bFirstConnect = TRUE; //first connect will trigger event once
      singletonEmergencyMode = new EmergencyMode();
      DebugFTN("EmergencyMode", "EmergencyMode -> singelton created");
    }

    if (fpCallback != nullptr)
    {
      DebugFTN("EmergencyMode", "EmergencyMode -> class connect 1");
      classConnect(fpCallback, singletonEmergencyMode, "stateUpdate");
      DebugFTN("EmergencyMode", "EmergencyMode -> class connect 2");

      if (!bFirstConnect)
      {
        DebugFTN("EmergencyMode", "EmergencyMode -> bFirstConnect 1");
        callFunction(fpCallback, eCurrentState);
        DebugFTN("EmergencyMode", "EmergencyMode -> bFirstConnect 2");
      }
    }

    DebugFTN("EmergencyMode", "EmergencyMode -> connectToStateChange finished");
  }
  public static eEmgergencyMode getCurrentState() synchronized(singletonEmergencyMode)
  {
    return eCurrentState;
  }

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
  //private constructor (singleton)
  private EmergencyMode() synchronized(singletonEmergencyMode)
  {
    string sPostFix = myReduHostNum() == 2 ? "_2" : "";
    dpConnect(workCB_emergencyMode, "_MemoryCheck" + sPostFix + ".EmergencyKBLimit",
                                    "_MemoryCheck" + sPostFix + ".AvailKB",
                                    "_ArchivDisk" + sPostFix + ".EmergencyKBLimit",
                                    "_ArchivDisk" + sPostFix + ".AvailKB");
  }
  private void workCB_emergencyMode(string sDPE1, int memLimit, string sDPE2, int memAvail,
                                    string sDPE3, int diskLimit, string sDPE4, int diskAvail) synchronized(singletonEmergencyMode)
  {
    DebugFTN("EmergencyMode", "EmergencyMode -> work 1");

    if (eCurrentState == eEmgergencyMode::emergencyWaitForRestart) //no update - need to restart anyway
    {
      return;
    }

    DebugFTN("EmergencyMode", "EmergencyMode -> work 2");
    eEmgergencyMode eNewState;

    if (memAvail < memLimit) //CAME UNACK reason memory
    {
      eNewState = eEmgergencyMode::emergencyMemory;
    }
    else if (diskAvail < diskLimit) //CAME UNACK reason disk space
    {
      eNewState = eEmgergencyMode::emergencyDisk;
    }
    else if (eCurrentState == eEmgergencyMode::emergencyMemory ||
             eCurrentState == eEmgergencyMode::emergencyDisk) //condition is good again, but have been in emergency mode -> requires restart
    {
      eNewState = eEmgergencyMode::emergencyWaitForRestart;
    }

    if (eCurrentState != eNewState || isAnswer()) //state change
    {
      DebugFTN("EmergencyMode", "EmergencyMode -> work 3", eCurrentState, eNewState);
      eCurrentState = eNewState;

      triggerClassEvent(singletonEmergencyMode.stateUpdate, eCurrentState);
    }

    DebugFTN("EmergencyMode", "EmergencyMode -> work 4 nothing to do", eCurrentState);
  }

  private static shared_ptr<EmergencyMode> singletonEmergencyMode;
  private static eEmgergencyMode eCurrentState;
};
