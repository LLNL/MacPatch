#!/bin/bash

#-----------------------------------------
# MacPatch Server Setup Script
# MacPatch Version 2.5.x
#
# Script Ver. 1.2.0
#
#-----------------------------------------
clear

# Variables
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"
MP_DEFAULT_PORT="3601"

function checkHostConfig () {
	if [ "`whoami`" != "root" ] ; then   # If not root user,
	   # Run this script again as root
	   echo
	   echo "You must be an admin user to run this script."
	   echo "Please re-run the script using sudo."
	   echo
	   exit 1;
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
mp_server_port="$MP_DEFAULT_PORT"
mp_server_ssl="Y"
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
fi

defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mp.patchloader 'MPServerPort' "$mp_server_port"

if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist ]; then
	if [ -f /Library/LaunchDaemons/gov.llnl.mploader.plist ]; then
		rm /Library/LaunchDaemons/gov.llnl.mploader.plist
	fi
	ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist /Library/LaunchDaemons/gov.llnl.mploader.plist
fi
chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist

echo
echo "Please note, if you wish to replicate content from your own Apple SoftwareUpdate server"
echo "you will need to edit the ${MP_SRV_BASE}/conf/etc/gov.llnl.mp.patchloader.plist"
echo "file. "
echo


