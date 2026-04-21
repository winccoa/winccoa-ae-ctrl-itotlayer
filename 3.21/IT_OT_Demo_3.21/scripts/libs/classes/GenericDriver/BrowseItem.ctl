// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
 * @file $relPath
 * @copyright $copyright
 */

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "classes/EBTag"

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/**
 * @brief
 */
struct BrowseItem
{
  string    name;
  EBTagType type;
  string    address;
  string    extras;
  string    transformation;
  bool      writeable;
};
