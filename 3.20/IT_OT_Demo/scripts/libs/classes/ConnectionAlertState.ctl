// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author Schiefer Martin
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
// declare variables and constants
/**
 * @brief Defines the enum ConnectionAlertState.
 */
enum ConnectionAlertState
{
  Disabled = 0,    //!< Newly created dpes have this value, which should not be shown (yet)
  Ok,
  Warning,
  Alert,
  ProtcolError
};


