#!/bin/bash

#-----------------------------------------
# MacPatch Web Services Server Setup Script
# MacPatch Version 2.1.x
#
# Script Ver. 1.0.0
#
#-----------------------------------------
clear

# Variables
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"
HTTPD_CONF="${MP_SRV_BASE}/Apache2/conf/extra/httpd-vhosts.conf"
MP_DEFAULT_PORT="2602"

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
# Config HTTP Services
# -----------------------------------

server_name=`hostname -f`
read -p "MacPatch Hostname [$server_name]: " server_name
server_name=${server_name:-`hostname -f`}
read -p "MacPatch Port [$MP_DEFAULT_PORT]: " server_port
server_port=${server_port:-$MP_DEFAULT_PORT}

server_route=`echo $server_name | awk -F . '{print $1}'` 
server_route="$server_route-site1"

BalancerMember_STR="BalancerMember http://$server_name:$server_port route=$server_route loadfactor=50"

echo "Writing config to httpd.conf..."
ServerHstString=`echo $BalancerMember_STR | sed 's#\/#\\\/#g'`
sed -i '' '/\t*#WslBalanceStart/,/\t*#WslBalanceStop/{;/\t*#/!s/.*/'"$ServerHstString"'/;}' "${HTTPD_CONF}"
perl -i -p -e 's/@@/\n/g' "${HTTPD_CONF}"

echo "Writing configuration data to jetty file ..."
sed -i '' "s/\[MP_PORT\]/$server_port/g" "${MP_SRV_BASE}/jetty-mpwsl/etc/jetty.xml"

if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.wsl.plist ]; then
	ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.wsl.plist /Library/LaunchDaemons/gov.llnl.mp.wsl.plist
fi
chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.wsl.plist
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.wsl.plist

if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.invd.plist ]; then
	ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.invd.plist /Library/LaunchDaemons/gov.llnl.mp.invd.plist
fi
chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.invd.plist
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.invd.plist