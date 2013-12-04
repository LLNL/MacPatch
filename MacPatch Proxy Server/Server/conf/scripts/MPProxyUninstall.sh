#!/bin/bash

#-----------------------------------------
# MacPatch Proxy Server Uninstall Script
# MacPatch Version 2.1.x
#
# Script Ver. 1.0.0
#
#-----------------------------------------
clear

MP_BASE="/Library/MacPatch"
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"

function checkHostConfig () {
    if [ "`whoami`" != "root" ] ; then   # If not root user,
       # Run this script again as root
       echo
       echo "You must be an admin user to run this script."
       echo "Please re-run the script using sudo."
       echo
       exit 1;
    fi
    
    osVer=`sw_vers -productVersion | cut -d . -f 2`
    if [ "$osVer" -le "6" ]; then
        echo "System is not running Mac OS X 10.7 or higher. Setup can not continue."
        exit 1
    fi
}

# -----------------------------------
# CheckConfig
# -----------------------------------

checkHostConfig

# -----------------------------------
# Run Script
# -----------------------------------

echo "This script will remove all of the files in ${MP_SRV_BASE}."
echo "Are you sure you want to continue [Y/N]?"
while read inputline
do
    answer="$inputline"
    if [ -z "${answer}" ]; then
        echo "Answer?"
    else
		if [ "${answer}" == "Y" -o "${answer}" == "y" ]; then
        	break
        else
        	echo "Uninstall will not continue..."
        	exit 0;
    	fi	
    fi
done

# Shutdown services
$MP_SRV_CONF/scripts/StartServices.sh -u

# Remove MacPatch
echo "Removing ${MP_SRV_BASE}"
rm -rf "${MP_SRV_BASE}"

