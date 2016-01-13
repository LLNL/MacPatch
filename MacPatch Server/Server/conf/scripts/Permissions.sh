#!/bin/bash
# -------------------------------------------------------------
# Script: Permissions.sh
# Version: 1.5.0
#
# Description:
# Set/Fix permissions
#
#
# History:
# 1.0.0: 	First version
# 1.5.0:	Update abd variablized
#
# -------------------------------------------------------------

MPBASE="/Library/MacPatch"
MPSERVERBASE="/Library/MacPatch/Server"

XOSTYPE=`uname -s`
USELINUX=false
USEMACOS=false
OWNERGRP="79:70"

if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this script."
   echo "Please re-run the script using sudo."
   echo
   exit 1;
fi

# -----------------------------------
# OS Check
# -----------------------------------

# Check and set os type
if [ $XOSTYPE == "Linux" ]; then
	USELINUX=true
	OWNERGRP="www-data:www-data"
	getent passwd www-data > /dev/null 2&>1
	if [ $? -eq 0 ]; then
		echo "www-data user exists"
	else
    	echo "Create user www-data"
		useradd -r -M -s /dev/null -U www-data
	fi
elif [ $XOSTYPE == "Darwin" ]; then
	USEMACOS=true
else
  	echo "OS Type $XOSTYPE is not supported. Now exiting."
  	exit 1; 
fi

# Add _appserver to _www group and vice versa
if $USEMACOS; then
	dseditgroup -o edit -a _appserver -t user _www
	dseditgroup -o edit -a _www -t user _appserverusr
fi

TCATS=('tomcat-mpsite' 'tomcat-mpws' 'apache-tomcat');
for tcat in "${TCATS[@]}"; do
	if [ -d "${MPSERVERBASE}/$tcat" ]; then
		chown -R $OWNERGRP ${MPSERVERBASE}/$tcat
	fi
done

chown -R $OWNERGRP /Library/MacPatch/Server
chown -R $OWNERGRP /Library/MacPatch/Content
chmod 0775 /Library/MacPatch/Server
chmod 0775 /Library/MacPatch/Server/Logs
chmod -R 0775 /Library/MacPatch/Content/Web

if $USEMACOS; then
	chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/*
	chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/*
fi