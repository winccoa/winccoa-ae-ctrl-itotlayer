#!/bin/bash
# ************************ uploadLogFiles.sh ********************
# @(#) $Author$ $Date$ $Revision$
# *******************************************************************
# * this script upload the log files
# * with following parameters:
# *   $1 <command_id>
# *   $2 <file pattern> (file name or '*')
# *******************************************************************

if [ ${PVSS_II} ]; then
  # Use if the environment variable without the 'config/config' part (last 13 characters)
  PROJ_PATH=${PVSS_II:0:-13}
else
  # Assume this script is located in the bin directory of the project
  SCRIPT_DIR=`dirname $0`
  PROJ_PATH=`dirname $SCRIPT_DIR`
fi

APP_NAME=${PVSS_II_PROJ}
DATE=`date +"%Y%m%dT%H%M%S"`
FILE_NAME="logcmd_$1_${DATE}_${APP_NAME}.tar.gz"
IFS='+';FILE_LIST=($2)

echo "Arguments:    $@"
echo "Project path: ${PROJ_PATH}"
echo "File:         ${FILE_NAME}"
echo "File list:    ${FILE_LIST[@]}"

cd ${PROJ_PATH}log/
tar -zcvf ${PROJ_PATH}data/${FILE_NAME} ${FILE_LIST[@]}

if [[ -d /persistent_massdata/tmp/logsToUpload ]]; then
  mv ${PROJ_PATH}data/${FILE_NAME} /persistent_massdata/tmp/logsToUpload/ 
fi
