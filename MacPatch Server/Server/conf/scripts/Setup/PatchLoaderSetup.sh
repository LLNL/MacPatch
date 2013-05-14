#!/bin/bash

#-----------------------------------------
# MacPatch Server Setup Script
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

# -----------------------------------
# Main
# -----------------------------------

checkHostConfig


# -----------------------------------
# Config Patch Loader
# -----------------------------------

server_name=`hostname -f`
server_port="8088"
read -p "Apple Software Update Server Name: [$server_name]: " -e t1
if [ -n "$t1" ]; then
	server_name=$t1
fi

read -p "Apple Software Update Server Port: [$server_port]: " -e t1
if [ -n "$t1" ]; then
	server_port=$t1
fi
defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mploader ASUSServer "http://${server_name}:${server_port}"

mp_server_name=`hostname -f`
mp_server_port="2602"
mp_server_ssl="N"
read -p "MacPatch Server Name: [$mp_server_name]: " -e t1
if [ -n "$t1" ]; then
	defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mploader 'MPServerAddress' "$server_name"
fi

read -p "Use SSL for MacPatch connection [$mp_server_ssl]: " -e t1
if [ -n "$t1" ]; then
	if [ "$t1" == "y" ] || [ "$t1" == "Y" ]; then
		mp_server_port="2600"
		defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mploader 'MPServerUseSSL' -bool YES
	else	
		mp_server_port="2602"
		defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mploader 'MPServerUseSSL' -bool NO
	fi
	
	defaults write ${MP_SRV_BASE}/conf/etc/gov.llnl.mploader 'MPServerPort' "$mp_server_port"
fi



