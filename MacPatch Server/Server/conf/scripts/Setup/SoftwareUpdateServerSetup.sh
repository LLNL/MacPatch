#!/bin/bash

#-----------------------------------------
# MacPatch SoftwareUpdate Server Config Setup Script
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

function configASUS () 
{
	serveradmin stop swupdate
	sleep 2
	
	serveradmin settings swupdate:autoMirrorOnlyNew = no
	serveradmin settings swupdate:autoMirror = yes
	serveradmin settings swupdate:limitBandwidth = no
	serveradmin settings swupdate:valueBandwidth = 0
	serveradmin settings swupdate:checkError = no
	serveradmin settings swupdate:PurgeUnused = yes
	serveradmin settings swupdate:autoEnable = yes
	
	serveradmin start swupdate
	sleep 2
}

# -----------------------------------
# Main
# -----------------------------------

checkHostConfig

# -----------------------------------
# Config ASUS
# -----------------------------------

asusServer_name="NA"
read -p "Would you like to run the SoftwareUpdate Server on this host [Y]: " asusServer_default
asusServer_default=${asusServer_default:-Y}
if [ "$asusServer_default" == "y" ] || [ "$asusServer_default" == "Y" ]; then
	echo "Configuring Apple Software Update Server"
	configASUS
	clear
	echo "Note: Apple SoftwareUpdate sync can take up to a day to complete."
fi