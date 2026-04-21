#!/bin/sh
# ************************ postLogFileHandler.sh ********************
# @(#) $Author$ $Date$ $Revision$
# *******************************************************************
# * this script is called after a WinCC OA log file has been renamed to .bak
# * with following parameters:
# *   $1 <new_file_name>
# *******************************************************************

if [ ${PVSS_II} ]; then
  # Use if the environment variable without the 'config/config' part (last 13 characters)
  PROJ_PATH=${PVSS_II:0:-13}
else
  # Assume this script is located in the bin directory of the project
  SCRIPT_DIR=`dirname $0`
  PROJ_PATH=`dirname $SCRIPT_DIR`
fi

# Get the file name without the directory part
FILE_NAME=`basename $1`

# Read the 'pvss_path' value from the config file
WINCC_OA_PATH=`awk -F ' = ' '/^pvss_path/{gsub(/"/, "", $2); print $2}' ${PROJ_PATH}/config/config`

echo "Arguments:    $@"
echo "Project path: ${PROJ_PATH}"
echo "Project:      ${PVSS_II_PROJ}"
echo "File:         ${FILE_NAME}"

${WINCC_OA_PATH}/bin/WCCOAascii -PROJ ${PVSS_II_PROJ} -set MindSphereConnector.diagnostic.logFileSwitched ${FILE_NAME}
