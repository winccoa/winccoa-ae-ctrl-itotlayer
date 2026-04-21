// $License: NOLICENSE

/**
 * @file scripts/libs/EB_Package_Base/OA_Consts.ctl
 */

/**
 * @brief Defines constants of WinCC OA
 * @details Unfornately WinCC OA itself does not contains constants for these values, so they are defined here.
 */
struct OA_Consts
{
  // Constants for the trend widget
  static const string TREND_CURVE_DATA_TIME            = "time";                    //!< Mapping key for the time of the trend function 'curveDataAt'
  static const string TREND_CURVE_DATA_STATUS          = "status";                  //!< Mapping key for the status bits of the trend function 'curveDataAt'
  static const string TREND_CURVE_DATA_VALUE           = "value";                   //!< Mapping key for the value of the trend function 'curveDataAt'
  static const string TREND_CURVE_DATA_VALUE_FORMATTED = "formattedValue";          //!< Mapping key for the formatted value of the trend function 'curveDataAt'
  static const string TREND_CURVE_DATA_CAT_MSG_KEY     = "msgCatKey";               //!< Mapping key for the 'trendStatusPattern' of the trend function 'curveDataAt'
  static const string TREND_CURVE_DATA_POINT_ICON      = "pointIcon";               //!< Mapping key for the icon path of the trend function 'curveDataAt'

  // Constants for the net functions (netGet, netHead, netPost, netPut)
  static const string NET_OPTIONS_TARGET               = "target";                  //!< Target file or directory for the content
  static const string NET_OPTIONS_SSL_IGNORE_ERRORS    = "ignoreSslErrors";         //!< SSL errors to ignore

  static const string NET_OPTIONS_SSL_MISMATCH_HOST    = "HostNameMismatch";        //!< Allow mismatching host names
  static const string NET_OPTIONS_SSL_CERT_SELF_SIGNED = "SelfSignedCertificate";   //!< Allow self signed certificates

  static const string NET_RESULT_HTTP_STATUS_CODE      = "httpStatusCode";          //!< Received HTTP status code
  static const string NET_RESULT_TARGET                = "target";                  //!< File name of where the received content is stored

  //some error codes from OA
  static const string INFO_FROM_MANAGER                = "1";                       //!< Info message for logging
  static const string ERR_DP_NOT_EXISTS                = "7";                       //!< Error message for logging
  static const string ERR_UNEXPECTED_STATE             = "54";                      //!< Error message for logging

  static const int    INVALID_LANGUAGE_IDENTIFIER_STRING = 255;                     //!< Value indicating an invalid language identifier
};
