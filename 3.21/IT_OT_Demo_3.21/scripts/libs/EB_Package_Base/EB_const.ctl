/**
 * @file libs/EB_Package_Base/EB_const.ctl
 * @brief This library defines common constants for the IOT suite.
 */

// Port numbers
const int OPCUA_PORT               = 5840;                                     //!< Port of the publish OPC UA server
const int PUBLISH_SERVICE_PORT     = 5841;                                     //!< Port of the publish HTTP server
const int PUBLISH_SERVICE_PORT_SSL = 5842;                                     //!< Port of the publish HTTPS server

// Common constants
const int INDICATOR_STATE_UNDEFINED = 0;                                       //!< Header indicator value for the undefined state (light grey color)
const int INDICATOR_STATE_OK        = 1;                                       //!< Header indicator value for the OK state        (light green color)
const int INDICATOR_STATE_INFO      = 2;                                       //!< Header indicator value for the info state      (dark yellow color)
const int INDICATOR_STATE_WARNING   = 3;                                       //!< Header indicator value for the warning state   (light yellow color)
const int INDICATOR_STATE_ALERT     = 4;                                       //!< Header indicator value for the alert state     (light red color)

// Common Dptypes
const string EB_DPTYPE_PACKAGES = "EB_Packages";                               //!< Dptype of the package dps

// Common prefixes
const string EB_PREFIX_PACKAGE = "EB_Package_";                                //!< Prefix for package names, dps & directories

// Images
const string EB_IMAGE_OK          = "EB_Package/Check_green.svg";              //!< Image visualizing the OK state (green check mark)
const string EB_IMAGE_WARN        = "EB_Package/Check_yellow.svg";             //!< Image visualizing the warning state (yellow question '?' mark)
const string EB_IMAGE_NOK         = "EB_Package/Cross_redpure.svg";            //!< Image visualizing the NOK state (red cross)
const string EB_IMAGE_CONF_NOK    = "EB_Package/Cross_greydark.svg";           //!< Image visualizing the NOK state (grey cross)
const string EB_IMAGE_TRASH       = "EB_Package/TrashCan_greydark_small.svg";  //!< Image showing a trash can
const string EB_IMAGE_TRASH_RED   = "EB_Package/TrashCan_red_small.svg";       //!< Image visualizing the marked for deletion state (red trash can)
const string EB_IMAGE_EDIT        = "EB_Package/EBedit24.svg";                 //!< Image showing an edit icon
const string EB_IMAGE_CHECKED     = "checkbox_checked.svg";                    //!< Image showing checked box
const string EB_IMAGE_UNCHECKED   = "checkbox_unchecked.svg";                  //!< Image showing unchecked box
const string EB_IMAGE_ADD         = "wf/buttons/add.png";                      //!< Image showing plus (+)
const string EB_IMAGE_HELP        = "EB_Package/Help.svg";                     //!< Image showing a help icon (encircled question '?' mark)
const string EB_IMAGE_OK_SMALL    = "EB_Package/Check_green_small.svg";        //!< Image visualizing the OK state (green check mark)
const string EB_IMAGE_NOK_SMALL   = "EB_Package/Cross_redpure_small.svg";      //!< Image visualizing the NOK state (red cross)
const string EB_IMAGE_WARN_SMALL  = "EB_Package/Check_yellow_small.svg";       //!< Image visualizing the warning state (yellow question '?' mark)
const string EB_IMAGE_MANDATORY   = "EB_Package/Mandatory_yellow_small.svg";   //!< Image indicating a mandatory field (yellow exclamation '!' mark)
const string EB_IMAGE_ARROW_DOWN  = "wf/stylesheet/downarrow_pressed.svg";     //!< Image showing a white downward pointing triangle
const string EB_IMAGE_ARROW_UP    = "wf/stylesheet/uparrow_pressed.svg";       //!< Image showing a white upward pointing triangle
const string EB_IMAGE_SORT_DOWN   = "wf/stylesheet/downarrow.svg";             //!< Image showing a downward pointing triangle
const string EB_IMAGE_SORT_UP     = "wf/stylesheet/uparrow.svg";               //!< Image showing a upward pointing triangle
const string EB_IMAGE_FAVORITE    = "EB_Package/star-outline.svg";             //!< Image showing a favorite icon (star)
const string EB_IMAGE_LANG        = "EB_Package/LangEdit.svg";                 //!< Image showing a lang editor icon (globe)
const string EB_IMAGE_DFLMACHINE  = "EB_Package/Gauge.svg";                    //!< Image showing a gauge icon
const string EB_IMAGE_COPY        = "EB_Package/Copy.svg";                     //!< Image showing a copy icon
const string EB_IMAGE_CUT         = "EB_Package/cut-solid.svg";                //!< Image showing a cutter icon

const string EB_MENU_ITEM = "EB_Package/MenuItem.svg";                         //!< Image showing a menu item icon
const string EB_MENU_HELP = "EB_Package/Help.svg";                             //!< Image showing a help icon (encircled question '?' mark)

// Panels
const string EB_PANEL_MAIN        = "EB_Package_Base/EBmain_panel";            //!< Relative file name of the main panel
const string EB_PANEL_LOGIN       = "tiles/internal/tiles/LoginTile";          //!< Relative file name of the login panel
const string EB_PANEL_TAG_BROWSER = "EB_Package_DataSource/DataSource";        //!< Relative file name of the tag browser

// Module names
const string EB_MODULE_APP         = "appModule";                              //!< Name of the module containing the main panel
const string EB_MODULE_TAG_BROWSER = "TagBrowser";                             //!< Name of the module containing the tag browser

// Text colors
const string EB_COLOR_INCORRECT_INPUT = "STD_value_not_ok";                    //!< highlight incorrect input

// timer
const string EB_TIMER_DPE = "_Event.Heartbeat";                                //!< DPE, which should be triggered every second for the timer

// pmon userdata
const string PMON_USER = "";                                                   //!< Pmon user, used by the EdgeBox script to add/remove managers
const string PMON_PASS = "";                                                   //!< Pmon password, used by the EdgeBox script to add/remove managers

// return value mapping keys
const string EB_RETURN_STRING = "StringValues";                                //!< Deprecated, should be not used anymore
const string EB_RETURN_FLOAT  = "FloatValues";                                 //!< Deprecated, should be not used anymore

// http results
const string EB_HTTP_OK          = "Status: 200 OK";                           //!< HTTP OK status code
const string EB_HTTP_BAD_REQUEST = "Status: 400 Error";                        //!< HTTP bad request error code
const string EB_HTTP_NOT_FOUND   = "Status: 404 Error";                        //!< HTTP not found error code
const string EB_HTTP_CONFLICT    = "Status: 409 Error";                        //!< HTTP conflict error code

// font
const string EB_FONT_FRONT_END = "Noto Sans,-1,";                              //!< Used to create a complete font string with the specified size
const string EB_FONT_BACK_END = ",5,50,0,0,0,0,0";                             //!< Used to create a complete font string with the specified size

// home screen
const string EB_HOMESCREEN_TILE = "internal/AppTile";                          //!< Tile type of the home screen tiles

//default format
const string EB_FORMAT_NONE   = "";                                            //!< Default format for other types
const string EB_FORMAT_STRING = "%s";                                          //!< Default format for string values
const string EB_FORMAT_INT    = "%d";                                          //!< Default format for integer values
const string EB_FORMAT_UINT   = "%u";                                          //!< Default format for unsigned values
const string EB_FORMAT_FLOAT  = "%0.2f";                                       //!< Default format for floating point values
const string EB_FORMAT_TIME   = "%t";                                          //!< Default format for time values
