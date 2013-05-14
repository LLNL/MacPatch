#!/bin/bash

#-----------------------------------------
# MacPatch SAV Defs Sync Setup Script
# MacPatch Version 2.1.x
#
# Script Ver. 1.0.0
#
#-----------------------------------------
clear

# Variables
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"

function checkHostConfig () {
	if [ "`whoami`" != "root" ] ; then   # If not root user,
	   # Run this script again as root
	   echo
	   echo "You must be an admin user to run this script."
	   echo "Please re-run the script using sudo."
	   echo
	   #exit 1;
	fi
	
	osType=`sw_vers -productName`
	osVer=`sw_vers -productVersion | cut -d . -f 2`
	if [ "$osType" != "Mac OS X Server" ]; then
		echo "System is not running Mac OS X Server. Server is recommended."
		#exit 1
	fi
	if [ "$osVer" -le "6" ]; then
		echo "System is not running Mac OS X (Server) 10.7 or higher. Setup can not continue."
		exit 1
	fi
}

function configAVSync () 
{	
	server_name=`hostname -f`
	read -p "MacPatch Server Name: [$server_name]: " -e t1
	if [ -n "$t1" ]; then
		defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mpavdl 'MPServerAddress' "$server_name"
	fi
	
	read -p "Use SSL for MacPatch connection [$mp_server_ssl]: " -e t1
	if [ -n "$t1" ]; then
		if [ "$t1" == "y" ] || [ "$t1" == "Y" ]; then
			server_port="2600"
		else	
			server_port="2602"
		fi
	
		defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mpavdl 'MPServerPort' "$server_port"
	fi
}

# -----------------------------------
# Main
# -----------------------------------

checkHostConfig

# -----------------------------------
# Config AV
# -----------------------------------

read -p "Would you like to run the Symantec Antivirus virus defs on this host [Y]: " avServer_default
avServer_default=${avServer_default:-Y}
if [ "$avServer_default" == "y" ] || [ "$avServer_default" == "Y" ]; then
	echo "Configuring Symantec Antivirus Sync..."
	configAVSync
fi