#!/bin/bash

#-----------------------------------------
# MacPatch Server Setup Script
# MacPatch Version 2.1.x
#
# Script Ver. 1.1.0
#
#-----------------------------------------
clear

# Variables
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"
MP_DEFAULT_PORT="2601"

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
# Main
# -----------------------------------

checkHostConfig


# -----------------------------------
# Config Patch Loader Settings
# -----------------------------------

mp_server_name=`hostname -f`
mp_server_port="2601"
mp_server_ssl="N"
read -p "MacPatch Server Name: [$mp_server_name]: " -e t1
if [ -n "$t1" ]; then
	defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mp.patchloader 'MPServerAddress' "$server_name"
fi

read -p "Use SSL for MacPatch connection [$mp_server_ssl]: " -e t1
if [ -n "$t1" ]; then
	if [ "$t1" == "y" ] || [ "$t1" == "Y" ]; then
		mp_server_port="2600"
		defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mp.patchloader 'MPServerUseSSL' -bool YES
	else	
		defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mp.patchloader 'MPServerUseSSL' -bool NO
		read -p "MacPatch Port [$MP_DEFAULT_PORT]: " mp_server_port
		mp_server_port=${server_port:-$MP_DEFAULT_PORT}
	fi
	
	defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mp.patchloader 'MPServerPort' "$mp_server_port"
fi

if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist ]; then
	ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist /Library/LaunchDaemons/gov.llnl.mploader.plist
fi
chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist

echo
echo "Please note, if you wish to replicate content from your own Apple SoftwareUpdate server"
echo "you will need to edit the ${MP_SRV_BASE}/conf/etc/gov.llnl.mp.patchloader.plist"
echo "file. 
echo


