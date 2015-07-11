#!/bin/bash

#-----------------------------------------
# MacPatch Proxy Start/Stop Services Script
# MacPatch Version 2.1.x
#
# Script Ver. 1.1.0
#
#-----------------------------------------
clear

# Default is bogus
action="load"
service="All"
dryrun="0"

# -----------------------------------
# Functions
# -----------------------------------

function checkHostConfig () 
{
	if [ "`whoami`" != "root" ] ; then   # If not root user,
	   # Run this script again as root
	   echo
	   echo "You must be an admin user to run this script."
	   echo "Please re-run the script using sudo."
	   echo
	   exit 1;
	fi
}

function arrayContains () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

function isValidService () 
{
	array=("gov.llnl.mp.proxy.plist" "gov.llnl.mp.ProxySync.plist" "gov.llnl.mp.httpd.plist")
	arrayContains $1 "${array[@]}"
	return $?
}

# -----------------------------------
# Args
# -----------------------------------

while getopts lus:d flag; do
  case $flag in
    l)
      echo "Loading Services";
      action="load"
      ;;
    u)
      echo "Unloading Services";
      action="unload"
      ;;
    s)
      echo "Specifying Service $OPTARG";
      service=$OPTARG
      ;;  
    d)
      echo "Enable Dryrun";
      dryrun="1"
      ;;  
    ?)
      exit;
      ;;
  esac
done

shift $(( OPTIND - 1 ));

# -----------------------------------
# Test Area
# -----------------------------------
#echo "$action = $service"
#exit 0

# -----------------------------------
# Permission
# -----------------------------------

checkHostConfig

# -----------------------------------
# Validate Service Arg
# -----------------------------------
if [ "$service" != "All" ]; then
	if ! isValidService $service; then
		echo "$service is not a valid service."
		exit
	fi	
fi

# -----------------------------------------
# Permissions Fix
#
# It may be a bit overkill but Permissions to get out of whack 
# from time to time and need to be fixed.
# -----------------------------------------
if [ "$action" == "load" ]; then
	# Add _appserver to _www group and vice versa
	dseditgroup -o edit -a _appserver -t user _www
	dseditgroup -o edit -a _www -t user _appserverusr

	chown -R root:admin /Library/MacPatch/Server
	chown -R 79:70 /Library/MacPatch/Server/jetty-mpproxy
	chown -R 79:70 /Library/MacPatch/Server/Logs
	chown -R 79:70 /Library/MacPatch/Content/Web
	chmod 0775 /Library/MacPatch/Server
	chmod 0775 /Library/MacPatch/Server/Logs
	chmod -R 0775 /Library/MacPatch/Content/Web

	chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/*
	chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/*
fi	


# -----------------------------------
# Start or Stop Services
# -----------------------------------

if [ -e "/Library/LaunchDaemons/gov.llnl.mp.proxy.plist" ] && ([[ "$service" == "All" || "$service" == "gov.llnl.mp.proxy.plist" ]])
then
		echo "Starting MacPatch Proxy Service..."
		echo "launchctl $action -w /Library/LaunchDaemons/gov.llnl.mp.proxy.plist"
		if [ "$dryrun" == "0" ]; then
			launchctl $action -w /Library/LaunchDaemons/gov.llnl.mp.proxy.plist
			sleep 3
		fi		
fi

if [ -e "/Library/LaunchDaemons/gov.llnl.mp.ProxySync.plist" ] && ([[ "$service" == "All" || "$service" == "gov.llnl.mp.ProxySync.plist" ]])
then
		echo "Starting MacPatch Proxy Content Sync Service..."
		echo "launchctl $action -w /Library/LaunchDaemons/gov.llnl.mp.ProxySync.plist"
		if [ "$dryrun" == "0" ]; then
			launchctl $action -w /Library/LaunchDaemons/gov.llnl.mp.ProxySync.plist
			sleep 3
		fi
fi


if [ -e "/Library/LaunchDaemons/gov.llnl.mp.httpd.plist" ] && ([[ "$service" == "All" || "$service" == "gov.llnl.mp.httpd.plist" ]])
then
		echo "Starting MacPatch HTTPD Service..."
		echo "launchctl $action -w /Library/LaunchDaemons/gov.llnl.mp.httpd.plist"
		if [ "$dryrun" == "0" ]; then
			launchctl $action -w /Library/LaunchDaemons/gov.llnl.mp.httpd.plist
			sleep 3
		fi
fi
