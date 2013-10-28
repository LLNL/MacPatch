#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildProxyServer.sh
# Version: 1.0
#
# Description:
# This is a very simple script to demonstrate how to automate
# the build process of the MacPatch Server.
#
# Info:
# Simply modify the GITROOT and BUILDROOT variables
#
# -------------------------------------------------------------
MPBASE="/Library/MacPatch"
MPSERVERBASE="/Library/MacPatch/Server"
GITROOT="/Library/MacPatch/tmp/MacPatch"
BUILDROOT="/Library/MacPatch/tmp/build/Server"

if [ -d "$BUILDROOT" ]; then
	rm -rf ${BUILDROOT}
else
	mkdir -p ${BUILDROOT}	
fi	

if [ ! -d "$GITROOT" ]; then
	echo "$GITROOT is missing. Please clone MacPatch repo to /Library/MacPatch/tmp"
	echo
	echo "cd /Library/MacPatch/tmp; git clone https://github.com/SMSG-MAC-DEV/MacPatch.git"
	exit
fi	

# ------------------
# Create Skeleton Dir Structure
# ------------------
mkdir -p /Library/MacPatch
mkdir -p /Library/MacPatch/Content
mkdir -p /Library/MacPatch/Content/Web
mkdir -p /Library/MacPatch/Content/Web/clients
mkdir -p /Library/MacPatch/Content/Web/patches
mkdir -p /Library/MacPatch/Content/Web/sav
mkdir -p /Library/MacPatch/Content/Web/sw
mkdir -p /Library/MacPatch/Server
mkdir -p /Library/MacPatch/Server/lib
mkdir -p /Library/MacPatch/Server/Logs

# ------------------
# Compile the agent components
# ------------------
xcodebuild -project ${GITROOT}/MacPatch/MPFramework/MPLibrary.xcodeproj clean
xcodebuild -project ${GITROOT}/MacPatch/MPFramework/MPLibrary.xcodeproj SYMROOT=${BUILDROOT}

if [ ! -f "${BUILDROOT}/Release/libMacPatch.a" ] ; then
	echo "Error: MacPatch static library compiler error"
	exit 1
fi

xcodebuild clean build -project ${GITROOT}/MacPatch/MPProxySync/MPProxySync.xcodeproj SYMROOT=${BUILDROOT} HEADER_SEARCH_PATHS="${BUILDROOT}/usr/local/include"

if [ ! -f "${BUILDROOT}/Release/MPProxySync" ] ; then
	echo "Error: MPProxySync compiler error"
	exit 1
fi

# ------------------
# Remove the build and symbol files
# ------------------
find ${BUILDROOT} -name "*.build" -print | xargs -I{} rm -rf {}
find ${BUILDROOT} -name "*.dSYM" -print | xargs -I{} rm -rf {}

# ------------------
# Copy compiled files
# ------------------
# Remove the static library and header files
rm ${BUILDROOT}/Release/libMacPatch.a
rm -r ${BUILDROOT}/Release/usr

cp -R ${GITROOT}/MacPatch\ Proxy\ Server/Server ${MPBASE}
cp -R ${BUILDROOT}/Release/ ${MPSERVERBASE}/bin

# ------------------
# Build Apache
# ------------------
${MPSERVERBASE}/conf/scripts/MPHttpServerBuild.sh

# ------------------
# Link & Set Permissions
# ------------------
chown -R root:admin ${MPSERVERBASE}
chown -R 79:70 ${MPSERVERBASE}/jetty-mpproxy
chown -R 79:70 ${MPSERVERBASE}/Logs
chmod -R 0775 ${MPSERVERBASE}

# ------------------
# Clean up structure place holders
# ------------------
find ${MPSERVERBASE} -name ".mpRM" -print | xargs -I{} rm -rf {}
