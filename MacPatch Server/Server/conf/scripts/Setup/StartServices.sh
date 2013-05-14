#!/bin/bash

#-----------------------------------------
# MacPatch Start Services Script
# MacPatch Version 2.1.x
#
# Script Ver. 1.0.0
#
#-----------------------------------------
clear


if [ ! -e "/Library/LaunchDaemons/gov.llnl.mpavdl.plist" ]; then
		echo "Starting MacPatch Symantec Antivirus Sync..."
		launchctl load -w /Library/LaunchDaemons/gov.llnl.mpavdl.plist
		sleep 3
fi

if [ ! -e "/Library/LaunchDaemons/gov.llnl.mploader.plist" ]; then
		echo "Starting MacPatch SoftwareUpdate Server Helper..."
		launchctl load -w /Library/LaunchDaemons/gov.llnl.mploader.plist
		sleep 3
fi


if [ ! -e "/Library/LaunchDaemons/gov.llnl.mp.site.plist" ]; then
		echo "Starting MacPatch Admin Console App..."
		echo "launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.site.plist"
		launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.site.plist
		sleep 3
fi

if [ ! -e "/Library/LaunchDaemons/gov.llnl.mp.wsl.plist" ]; then

		echo "Starting MacPatch Web Services App..."
		echo "launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.wsl.plist"
		launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.wsl.plist
		sleep 3
		
		echo "Starting MacPatch Inventory Helper..."
		echo "launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.invd.plist"
		launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.invd.plist
		sleep 3
fi

if [ ! -e "/Library/LaunchDaemons/gov.llnl.mp.httpd.plist" ]; then
	echo "Starting MacPatch Apache..."
	echo "launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.httpd.plist"
	launchctl load -w /Library/LaunchDaemons/gov.llnl.mp.httpd.plist
	sleep 3
fi