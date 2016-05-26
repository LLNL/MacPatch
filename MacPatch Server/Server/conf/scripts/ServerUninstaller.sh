#!/bin/bash
# -------------------------------------------------------------
# Script: ServerUninstaller.sh
# Version: 1.0.0
#
# Description:
# Uninstall MacPatch Server Software
#
#
# History:
# 1.0.0: 	First version
#
# -------------------------------------------------------------

MPBASE="/Library/MacPatch"
MPSERVERBASE="/Library/MacPatch/Server"
MPSERVERCONT="/Library/MacPatch/Content"

launchDItems=('gov.llnl.mploader.plist' 'gov.llnl.mp.tomcat.plist' 'gov.llnl.mp.sync.plist'
	 'gov.llnl.mp.sus.sync.plist' 'gov.llnl.mp.rsync.plist' 'gov.llnl.mp.pfctl.plist'
	  'gov.llnl.mp.invd.plist' 'gov.llnl.mp.fw.plist' 'gov.llnl.mp.AVDefsSync.plist' 
	  'gov.llnl.mp.proxy.plist' 'gov.llnl.mp.ProxySync.plist');


if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this script."
   echo "Please re-run the script using sudo."
   echo
   exit 1;
fi

existsAndDelete () {
	if [ -f "$1" ]; then
		echo "Removing (rm -f) file $1"
		rm -f "$1" 2>/dev/null
	elif [ -d "$1" ]; then
		echo "Removing (rm -rf) directory $1"
		rm -rf "$1" 2>/dev/null
	fi
}

findAndDelete () {
	find $1 -name $2 -exec rm {} \;
}

launchDItem () {
	# Stop Running Services
	if [ -f "$1" ]; then
		echo "Stopping and removing $1"
		/bin/launchctl unload -w -F "$2" 2>/dev/null
		rm -f $2
		sleep 1
	fi
}

# MacPatch Deployment Dir
if [ -d $MPBASE ]; then

	# Remove 
	for i in "${launchItems[@]}"; do
		launchDItem "/Library/LaunchDaemons/$1"
	done
	
	# Delete MacPatch Server Files
	existsAndDelete "$MPSERVERBASE"
	
	# Delete MacPatch Content Files
	existsAndDelete "$MPSERVERCONT"
	
	echo "MacPatch Software has been fully removed!"
	echo "Please reboot the system..."
fi