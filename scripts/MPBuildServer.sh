#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildServer.sh
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
xcodebuild -project ${GITROOT}/MacPatch/MacPatch\ Server/MacPatch\ Server.xcodeproj -target SERVER_BUILD SYMROOT=${BUILDROOT}

# ------------------
# Remove the build and symbol files
# ------------------
find ${BUILDROOT} -name "*.build" -print | xargs -I{} rm -rf {}
find ${BUILDROOT} -name "*.dSYM" -print | xargs -I{} rm -rf {}

# ------------------
# Copy compiled files
# ------------------
cp -R ${GITROOT}/MacPatch\ Server/Server ${MPBASE}
cp -R ${BUILDROOT}/Release/ ${MPSERVERBASE}/bin

# ------------------
# Build Apache
# ------------------
${MPSERVERBASE}/conf/scripts/MPHttpServerBuild.sh

# ------------------
# Link & Set Permissions
# ------------------
ln -s ${MPSERVERBASE}/conf/Content/Doc ${MPBASE}/Content/Doc
chown -R root:admin ${MPSERVERBASE}
chown -R 79:70 ${MPSERVERBASE}/jetty-mpsite
chown -R 79:70 ${MPSERVERBASE}/jetty-mpwsl
chown -R 79:70 ${MPSERVERBASE}/Logs
chmod 0775 ${MPSERVERBASE}

# ------------------
# Clean up structure place holders
# ------------------
find ${MPSERVERBASE} -name ".mpRM" -print | xargs -I{} rm -rf {}

# ------------------
# Create Archive
# ------------------
ditto -c -k ${MPSERVERBASE} ${MPBASE}/MacPatch_Server.zip