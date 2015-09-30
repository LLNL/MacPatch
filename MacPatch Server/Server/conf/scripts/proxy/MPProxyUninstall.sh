#!/bin/bash

#-----------------------------------------
# MacPatch Proxy Server Uninstall Script
# MacPatch Version 2.7.x
#
# Script Ver. 1.1.0
#
#-----------------------------------------
clear

MP_BASE="/Library/MacPatch"
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"

if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this script."
   echo "Please re-run the script using sudo."
   echo
   exit 1;
fi

# -----------------------------------
# Run Script
# -----------------------------------

echo "This script will remove all of the files in ${MP_SRV_BASE}."
read -p "Are you sure you want to continue? [N] " rmAnswer
rmAnswer=${rmAnswer:-N}

if [ "${rmAnswer}" == "N" -o "${rmAnswer}" == "n" ]; then
    echo "Uninstall will not continue..."
    exit 0;
fi

read -p "Do you want to remove the software and patch content? [N] " swAnswer
swAnswer=${swAnswer:-N}

# Shutdown services
$MP_SRV_CONF/scripts/proxy/MPProxyConfig.py --services All --action stop

# Remove MacPatch
echo "Removing ${MP_SRV_BASE}"
rm -rf "${MP_SRV_BASE}"

if [ "${swAnswer}" == "Y" -o "${swAnswer}" == "y" ]; then
    echo "Removing ${MP_BASE}/Content"
    rm -rf "${MP_BASE}/Content"
fi
