#!/bin/bash

#-----------------------------------------
# MacPatch Rsync Service Setup Script
# MacPatch Version 2.5.x
#
# Script Ver. 1.0.0
#
#-----------------------------------------
clear

# Variables
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"

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
# Config Service
# -----------------------------------

if $USELINUX; then
	# Not Supported Yet
	exit 1;
fi

if $USEMACOS; then
	
	if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.rsync.plist ]; then
		if [ -f /Library/LaunchDaemons/gov.llnl.mp.rsync.plist ]; then
			rm /Library/LaunchDaemons/gov.llnl.mp.rsync.plist
		fi
		ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.rsync.plist /Library/LaunchDaemons/gov.llnl.mp.rsync.plist
	fi
	chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.tcwsl.plist
	chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.tcwsl.plist

fi
