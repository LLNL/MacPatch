#!/bin/bash
#
# --------------------------------------------------------------
# Script mpContentSync.sh
# Version 1.0
# Edit: MASTER_SERVER variable
#
# Runs via LaunchDaemon on Interval
#
# --------------------------------------------------------------

SYNC_DIR_NAME="mpContentWeb"
MASTER_SERVER="localhost"
LOCAL_CONTENT="/Library/MacPatch/Content/Web"

# Dont Run Unless Master Server Is Configured
if [ "$MASTER_SERVER" != "localhost" ]; then
	echo "$(/bin/date +"%Y-%m-%d %H:%M:%S") --- Starting Content Sync..."
	/usr/bin/rsync -vai --delete-before --ignore-errors --exclude=.DS_Store \
	$MASTER_SERVER::$SYNC_DIR_NAME $LOCAL_CONTENT
	echo "$(/bin/date +"%Y-%m-%d %H:%M:%S") --- Content Sync Complete"
fi
