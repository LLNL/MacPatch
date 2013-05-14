#!/bin/sh

#-----------------------------------------
# MacPatch Distribution Server Setup Script
# MacPatch Version 2.1.x
#
# Script Ver. 1.0.0
#
#-----------------------------------------
clear

# Variables
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"

# Start Services
MPWSL_SVC=0

# -----------------------------------
# Functions
# -----------------------------------

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

WSLServerHstCount=0
function addAdminHost () 
{	
	server_name=`hostname -f`
	read -p "MacPatch Distribution Server Hostname [$server_name]: " server_name
	server_name=${server_name:-`hostname -f`}
	read -p "MacPatch Distribution Server Port [2601]: " server_port
	server_port=${server_port:-2601}
	
	$((WSLServerHstCount++))
	server_route=`echo $server_name | awk -F . '{print $1}'` 
	server_route="$server_route-site$WSLServerHstCount"
	
	srvTxt="BalancerMember http://$server_name:$server_port route=$server_route loadfactor=50"
	WSLServerHstArr=("${WSLServerHstArr[@]}" "$srvTxt")
	
	echo "Host $server_name:$server_port added..."
}

function configApacheProxy () 
{
	echo "Add MacPatch Web Host(s)"
	while true
	do
		clear
		read -p "Add MacPatch Web (J2EE) Host [Y]:" addHostDoneQ
		addHostDoneQ=${addHostDoneQ:-Y}
		if [ "$addHostDoneQ" == "y" ] || [ "$addHostDoneQ" == "Y" ]; then
			addAdminHost
		else
			break
		fi
	done
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
	asusServer_name=`hostname -f`
fi

# -----------------------------------
# Config DB Settings
# -----------------------------------
read -p "Would you like to configure MacPatch Database info on this host [Y]: " dbConfig
dbConfig=${dbConfig:-Y}
if [ "$dbConfig" == "y" ] || [ "$dbConfig" == "Y" ]; then
	clear
	echo "Configure MacPatch Database Info..."
	echo " "
	read -p "MacPatch Database Server Hostname: " mp_db_hostname
	read -p "MacPatch Database Server Port Number [3306]: " mp_db_port
	mp_db_port=${mp_db_port:-3306}
	read -p "MacPatch Database Name [MacPatchDB]: " mp_db_name
	mp_db_name=${mp_db_name:-MacPatchDB}
	read -p "MacPatch Database Server User Name [mpdbadm]: " mp_db_usr
	mp_db_usr=${mp_db_usr:-mpdbadm}
	read -s -p "MacPatch Database Server User Password: " mp_db_pas
	clear
	echo ""
	echo "Writing configuration data to file ..."
	sed -i '' "s/\[DB-HOST\]/$mp_db_hostname/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[DB-NAME\]/$mp_db_name/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[DB-PORT\]/$mp_db_port/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[DB-USER\]/$mp_db_usr/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
	sed -i '' "s/\[DB-PASS\]/$mp_db_pas/g" "${MP_SRV_BASE}/conf/etc/siteconfig.xml"
fi

# -----------------------------------
# Run Setup
# -----------------------------------

read -p "Would you like to run the MacPatch WebServices App on this host [Y]: " mpWslServer_default
mpWslServer_default=${mpWslServer_default:-Y}
if [ "$mpWslServer_default" == "y" ] || [ "$mpWslServer_default" == "Y" ]; then

	# First shutdown any LaunchDaemon
	launchctl unload -w /Library/LaunchDaemons/gov.llnl.mp.*

	unset WSLServerHstArr
	WSLServerHstCount=0
	configApacheProxy

	WSLServerHstIndex=0
	WSLServerHstString=""
	for i in "${WSLServerHstArr[@]}"; do
		$((WSLServerHstIndex++))
		if [ "$WSLServerHstIndex" == "1" ]
		then
			WSLServerHstString="$i" 
		else
			WSLServerHstString="$WSLServerHstString@@$i" 
		fi
	done
	
	echo "Writing config to httpd.conf..."
	WSLServerHstString=`echo $WSLServerHstString | sed 's#\/#\\\/#g'`
	sed -i '' '/\t*#WslBalanceStart/,/\t*#WslBalanceStop/{;/\t*#/!s/.*/'"$WSLServerHstString"'/;}' "${HTTPD_CONF}"
	perl -i -p -e 's/@@/\n/g' "${HTTPD_CONF}"

	if [ ! -e "/Library/LaunchDaemons/gov.llnl.mp.wsl.plist" ]
	then
		if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.wsl.plist ]
		then
			ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.wsl.plist /Library/LaunchDaemons/gov.llnl.mp.wsl.plist
		fi
		
		MPWSL_SVC=1
	fi
	
	if [ ! -e "/Library/LaunchDaemons/gov.llnl.mp.invd.plist" ]
	then
		if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.invd.plist ]
		then
			ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.invd.plist /Library/LaunchDaemons/gov.llnl.mp.invd.plist
		fi
	fi
else
	exit	
fi

# Set Permissions
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.*
chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl*
chown -R 79:70 /Library/MacPatch/Server/jetty-*
chmod 777 /Library/MacPatch/Server/bin/

# Load The Services
if [ $MPWSL_SVC == 1 ]; then
	if [ ! -e "/Library/LaunchDaemons/gov.llnl.mploader.plist" ]; then
		read -p "Are you sure you want to start the Admin WebServices service [Y]: " svc04_default
		svc04_default=${svc04_default:-Y}
		if [ "$svc04_default" == "y" ] || [ "$svc04_default" == "Y" ]; then
			echo "Starting MacPatch Web Services App..."
			echo "launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.wsl.plist"
			launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.wsl.plist
			sleep 3
			echo
			echo "Starting MacPatch Inventory Helper..."
			echo "launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.invd.plist"
			launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.invd.plist
			sleep 3
		else
			echo
			echo "To Start the Service Run:"
			echo "launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.wsl.plist"
			echo "launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.invd.plist"			
			echo
		fi	
	fi
fi