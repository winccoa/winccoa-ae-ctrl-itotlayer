#!/bin/sh
# ************************ recoverProject.sh ********************
# @(#) $Author$ $Date$ $Revision$
# *******************************************************************
# * this script sets up the mindsphere project
# *******************************************************************

PROJECT_DIRECTORY=/persistent_massdata
PROJECT_NAME=MNSP_Connect
WINCCOA_VERSION=3.19
WINCCOA_CONFIG=/opt/WinCC_OA/${WINCCOA_VERSION}/${PROJECT_NAME}
DOCKER_IP=$1
AUTOTEST=0

if [ "$1" = "autotest" ] || [ "$2" = "autotest" ]; then
  AUTOTEST=1
fi

echo "autotest?" $AUTOTEST

#exit

trap "echo nokill project recovery script" 15

# Stop the possibly running project
/opt/WinCC_OA/${WINCCOA_VERSION}/bin/WCCILpmon -proj ${PROJECT_NAME} -stopWait


if [ $AUTOTEST=0 ]; then
	echo "recover project"
	# Delete the old project
	rm -rf ${PROJECT_DIRECTORY}/${PROJECT_NAME}
	# Extract the project
	cp -R /opt/WinCC_OA/${WINCCOA_VERSION}/${PROJECT_NAME} ${PROJECT_DIRECTORY}
	# Replace Project Path
	sed -i "s#$WINCCOA_CONFIG#$PROJECT_DIRECTORY/$PROJECT_NAME#" ${PROJECT_DIRECTORY}/${PROJECT_NAME}/config/config
else
	echo "recover test project"
	# Delete only db, log and data/packages/EB_Package_*.ini
	rm -rf ${PROJECT_DIRECTORY}/${PROJECT_NAME}/db
	rm ${PROJECT_DIRECTORY}/${PROJECT_NAME}/log/*.*
	rm ${PROJECT_DIRECTORY}/${PROJECT_NAME}/data/packages/EB_Package_*.ini
	# copy only db to reset for autotest
	cp -R /opt/WinCC_OA/${WINCCOA_VERSION}/${PROJECT_NAME}/db ${PROJECT_DIRECTORY}/${PROJECT_NAME}
	cp -R /opt/WinCC_OA/${WINCCOA_VERSION}/${PROJECT_NAME}/config ${PROJECT_DIRECTORY}/${PROJECT_NAME}
fi

# Add config entry for MQTT in docker
if [ -f /.dockerenv ]; then
    echo "[mnsp]" >> ${PROJECT_DIRECTORY}/${PROJECT_NAME}/config/config
    echo "mqttHost = "${DOCKER_IP}"" >> ${PROJECT_DIRECTORY}/${PROJECT_NAME}/config/config
else
	# Replace Service User
	sed -i "s/#User=/User=isbuser/" /etc/systemd/system/winccoa@.service
fi

# Copy pvssInst folder
if [ ! -d "/etc/opt/pvss_old" ];then

  mkdir -p /etc/opt/pvss_old
  cp -R /etc/opt/pvss/* /etc/opt/pvss_old

fi

# Copy pvssInst folder
mkdir -p ${PROJECT_DIRECTORY}/pvss
cp -R /etc/opt/pvss_old/* ${PROJECT_DIRECTORY}/pvss

# Remove old pvssInst folder
rm -rf /etc/opt/pvss

# Also set the permissions on the project files
chmod -R u+rwX,go+rX ${PROJECT_DIRECTORY}/${PROJECT_NAME}
chmod -R u+rwX,go+rX ${PROJECT_DIRECTORY}/pvss
chown -R isbuser:root ${PROJECT_DIRECTORY}/${PROJECT_NAME}
chown -R isbuser:root ${PROJECT_DIRECTORY}/pvss

# Create symbolik link of pvssInst.conf
ln -s ${PROJECT_DIRECTORY}/pvss /etc/opt/pvss

 # Make sure the restored project is registered (in case it was not before)
        /opt/WinCC_OA/${WINCCOA_VERSION}/bin/WCCILpmon -autofreg -config ${PROJECT_DIRECTORY}/${PROJECT_NAME}/config/config -status

echo "autotest? " $AUTOTEST

if [ $AUTOTEST = 0 ]; then
	# Start the project
	  su -c "(/opt/WinCC_OA/3.19/bin/WCCILpmon -proj ${PROJECT_NAME} &)" - isbuser
	echo "++++++++++++ project start +++++++++++++++++"
else

        echo "++++++++++++ project start autotest +++++++++++++++++"

	/opt/WinCC_OA/3.19/bin/WCCOActrl /persistent_massdata/MNSP_Connect/scripts/tests/prepareTestRun.ctl -n -log +stderr -proj MNSP_Connect
	/opt/WinCC_OA/3.19/bin/WCCOActrl /persistent_massdata/MNSP_Connect/scripts/tests/testRunner.ctl --all -n -log +stderr -proj MNSP_Connect
fi

