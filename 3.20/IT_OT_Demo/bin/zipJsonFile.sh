#!/bin/bash
# ************************ zipJsonFile.sh ********************
# @(#) $Author$ $Date$ $Revision$
# *******************************************************************
# * this script zipps a file from a given folder
# * with following parameters:
# *   $1 folder
# *   $2 file name to be zipped - the output file will be same filename.zip
# *******************************************************************

FILE_IN="$2.json"
FILE_OUT="$2.zip"


cd $1

echo "tar -zcvf ${FILE_OUT} ${FILE_IN}"

tar -zcvf ${FILE_OUT} ${FILE_IN}
