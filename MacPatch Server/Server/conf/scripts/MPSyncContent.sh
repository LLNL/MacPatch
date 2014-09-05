#!/bin/bash
#
# --------------------------------------------------------------
# Script MPSyncContent.sh
# Version 1.1.0
# Edit: MASTER_SERVER variable
#
# Runs via LaunchDaemon on Interval or Cron Job
#
# --------------------------------------------------------------


# Rsync Path
SYNC_DIR_NAME="mpContentWeb"
# Rsync Server 
MASTER_SERVER="localhost"
# Sync Content to...
LOCAL_CONTENT="/Library/MacPatch/Content/Web"

MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF="${MP_SRV_BASE}/conf"
MP_SYNC_PLIST="${MP_SRV_CONF}/etc/gov.llnl.mp.sync.plist"

USE_SERVER=false
USE_PLIST=true

function usage
{
	echo
    echo "usage: MPSyncContent.sh [-s server] | [-p plist] | -h"
    echo
    echo "  -s   --server    Rsync Server to Sync from"
    echo "  -p   --plist     Plist containing config data"
    echo 
    echo "  -h   --help      Help or Usage"
    echo
}


# Process Args

while [ "$1" != "" ]; do
    case $1 in
        -s | --server ) 	shift
                            MASTER_SERVER=$1
                            USE_SERVER=true
                            ;;
        -p | --plist )	 	shift
                            MP_SYNC_PLIST=$1
                            ;;
        -h | --help )       usage
                            exit
                            ;;
    esac
    shift
done

# Dont Run Unless Master Server Is Configured

if [ $USE_SERVER == false ]; then

	if [ ! -f $MP_SYNC_PLIST ]; then
		echo "Error, $MP_SYNC_PLIST was not found."
		exit 1
	fi

	MASTER_SERVER = `defaults read $MP_SYNC_PLIST MPServerAddress`
fi

if [ "$MASTER_SERVER" != "localhost" ]; then
	echo "$(/bin/date +"%Y-%m-%d %H:%M:%S") --- Starting Content Sync..."
	/usr/bin/rsync -vai --delete-before --ignore-errors --exclude=.DS_Store \
	$MASTER_SERVER::$SYNC_DIR_NAME $LOCAL_CONTENT
	echo "$(/bin/date +"%Y-%m-%d %H:%M:%S") --- Content Sync Complete"
else
	echo "Error, localhost is not supported."
fi
