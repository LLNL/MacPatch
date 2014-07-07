#!/bin/bash

#-----------------------------------------
# MacPatch Web Admin Server Setup Script
# MacPatch Version 2.5.x
# Tomcat Support, port changed
#
# Script Ver. 1.3.1
#
#-----------------------------------------
clear

# Variables
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"
HTTPD_CONF="${MP_SRV_BASE}/Apache2/conf/extra/httpd-vhosts.conf"
MP_DEFAULT_PORT="4601"

DIST='OSX'
XOSTYPE=`uname -s`
USELINUX=false
USEMACOS=false
OWNERGRP="79:70"

# Check and set os type
if [ $XOSTYPE == "Linux" ]; then

	if [ -f /etc/redhat-release ] ; then
		DIST='redhat'
	elif [ -f /etc/fedora-release ] ; then
		DIST=`redhat`
	elif [ -f /etc/lsb-release ] ; then
		. /etc/lsb-release
		DIST=$DISTRIB_ID
	fi

	USELINUX=true
	OWNERGRP="www-data:www-data"
elif [ $XOSTYPE == "Darwin" ]; then
	USEMACOS=true
else
  	echo "OS Type $XOSTYPE is not supported. Now exiting."
  	exit 1; 
fi

# Make Sure Script is running as root
if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this script."
   echo "Please re-run the script using sudo."
   echo
   exit 1;
fi

# -----------------------------------
# Config HTTP Services
# -----------------------------------

server_name=`hostname -f`
read -p "MacPatch Hostname [$server_name]: " server_name
server_name=${server_name:-`hostname -f`}

server_route=`echo $server_name | awk -F . '{print $1}'` 
server_route="$server_route-site1"

BalancerMember_STR="BalancerMember http://$server_name:$MP_DEFAULT_PORT route=$server_route loadfactor=50"

echo "Writing config to httpd.conf..."
ServerHstString=`echo $BalancerMember_STR | sed 's#\/#\\\/#g'`
sed -ie '/\t*#AdminBalanceStart/,/\t*#AdminBalanceStop/{;/\t*#/!s/.*/'"$ServerHstString"'/;}' "${HTTPD_CONF}"
perl -i -p -e 's/@@/\n/g' "${HTTPD_CONF}"

if $USELINUX; then
	if [ -d /Library/MacPatch/Server/tomcat-mpsite ]; then

		if [ "$DIST" == "redhat" ]; then
			SFILE1="/Library/MacPatch/Server/conf/init.d/MPTomcatSite"
			SUSCP1="systemctl enable MPTomcatSite"
		elif [ "$DIST" == "Ubuntu" ]; then
			SFILE1="/Library/MacPatch/Server/conf/init.d/Ubuntu/MPTomcatSite"
			SUSCP1="update-rc.d MPTomcatSite defaults"
		else
			echo "Distribution not supported. Startup scripts will not be generated."
			exit 1
		fi

		if [ -f "$SFILE1" ]; then
			if [ -f /etc/init.d/MPTomcatSite ]; then
				rm /etc/init.d/MPTomcatSite
			fi
			chmod +x "$SFILE1"
			ln -s "$SFILE1" /etc/init.d/MPTomcatSite
			eval $SUSCP1
		else
			echo "ERROR: No Startup Script found for MP Tomcat Site."
		fi
	fi
fi

if $USEMACOS; then
	if [ -d /Library/MacPatch/Server/tomcat-mpsite ]; then
		if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.tcsite.plist ]; then
			if [ -f /Library/LaunchDaemons/gov.llnl.mp.site.plist ]; then
				rm /Library/LaunchDaemons/gov.llnl.mp.site.plist
			fi
			ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.tcsite.plist /Library/LaunchDaemons/gov.llnl.mp.site.plist
		fi
		chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.tcsite.plist
		chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.tcsite.plist
	else
		if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.site.plist ]; then
			if [ -f /Library/LaunchDaemons/gov.llnl.mp.site.plist ]; then
				rm /Library/LaunchDaemons/gov.llnl.mp.site.plist
			fi
			ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.site.plist /Library/LaunchDaemons/gov.llnl.mp.site.plist
		fi
		chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.site.plist
		chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.site.plist
	fi	
fi
