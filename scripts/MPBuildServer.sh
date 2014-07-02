#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildServer.sh
# Version: 1.1
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
SRC_DIR="${MPSERVERBASE}/conf/src"
TCATSRV=0

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

# -----------------------------------
# Main
# -----------------------------------

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

# ------------------------------------
# ASK On J2EE Server Type
# Tomcat support is new and going to replace Jetty
# ------------------------------------

read -p "Use experimental Tomcat config [N]: " TCATSRV
TCATSRV=${TCATSRV:-0}

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
# Copy compiled files
# ------------------
cp -R ${GITROOT}/MacPatch\ Server/Server ${MPBASE}

if $USEMACOS; then
	# ------------------
	# Compile the agent components
	# ------------------
	xcodebuild clean build -project ${GITROOT}/MacPatch/MacPatch.xcodeproj -target SERVER_BUILD SYMROOT=${BUILDROOT}

	# ------------------
	# Remove the build and symbol files
	# ------------------
	find ${BUILDROOT} -name "*.build" -print | xargs -I{} rm -rf {}
	find ${BUILDROOT} -name "*.dSYM" -print | xargs -I{} rm -rf {}

	# ------------------
	# Copy compiled files
	# ------------------
	cp -R ${BUILDROOT}/Release/ ${MPSERVERBASE}/bin
fi

# ------------------
# Setup Tomcat
# ------------------
J2EE_SW="apache-tomcat-7.0.54.tar.gz"
if [ $TCATSRV != 1 ]; then
	mkdir -p "${MPSERVERBASE}/apache-tomcat"
	tar xvfz ${SRC_DIR}/${J2EE_SW} --strip 1 -C ${MPSERVERBASE}/apache-tomcat
fi

# ------------------
# Build Apache
# ------------------
${MPSERVERBASE}/conf/scripts/MPHttpServerBuild.sh

# ------------------
# Link & Set Permissions
# ------------------
ln -s ${MPSERVERBASE}/conf/Content/Doc ${MPBASE}/Content/Doc
chown -R 79:70 ${MPSERVERBASE}

if [ $TCATSRV == 0 ]; then
	rm -rf "${MPSERVERBASE}/apache-tomcat"
	chmod -R 0775 ${MPSERVERBASE}/jetty-mpsite
	chown -R $OWNERGRP ${MPSERVERBASE}/jetty-mpsite
	chmod -R 0775 ${MPSERVERBASE}/jetty-mpwsl
	chown -R $OWNERGRP ${MPSERVERBASE}/jetty-mpwsl
else
	cp -r ${MPSERVERBASE}/apache-tomcat ${MPSERVERBASE}/tomcat-mpws
	mv ${MPSERVERBASE}/apache-tomcat ${MPSERVERBASE}/tomcat-mpsite

	chmod -R 0775 "${MPSERVERBASE}/jetty-mpwsl/webapps/mpwsl"
	chown -R $OWNERGRP "${MPSERVERBASE}/jetty-mpwsl/webapps/mpwsl"
	rm -rf  "${MPSERVERBASE}/tomcat-mpws/webapps/ROOT"
	jar cf "${MPSERVERBASE}/conf/tomcat/mpws/ROOT.war" -C "${MPSERVERBASE}/jetty-mpwsl/webapps/mpwsl" .
	cp "${MPSERVERBASE}/conf/tomcat/mpws/ROOT.war" "${MPSERVERBASE}/tomcat-mpws/webapps"
	cp "${MPSERVERBASE}/conf/tomcat/mpws/bin/setenv.sh" "${MPSERVERBASE}/tomcat-mpws/bin/setenv.sh"
	cp "${MPSERVERBASE}/conf/tomcat/mpws/bin/launchdTomcat.sh" "${MPSERVERBASE}/tomcat-mpws/bin/launchdTomcat.sh"
	cp -r "${MPSERVERBASE}/conf/tomcat/mpws/conf/Catalina" "${MPSERVERBASE}/tomcat-mpws/conf/"
	cp -r "${MPSERVERBASE}/conf/tomcat/mpws/conf/server.xml" "${MPSERVERBASE}/tomcat-mpws/conf/server.xml"
	cp -r "${MPSERVERBASE}/conf/tomcat/mpws/conf/web.xml" "${MPSERVERBASE}/tomcat-mpws/conf/web.xml"
	rm -rf "${MPSERVERBASE}/jetty-mpwsl"

	chmod -R 0775 "${MPSERVERBASE}/jetty-mpsite/webapps/mp"
	chown -R $OWNERGRP "${MPSERVERBASE}/jetty-mpsite/webapps/mp"
	rm -rf "${MPSERVERBASE}/tomcat-mpsite/webapps/ROOT"
	jar cf "${MPSERVERBASE}/conf/tomcat/mpsite/ROOT.war" -C "${MPSERVERBASE}/jetty-mpsite/webapps/mp" .
	cp "${MPSERVERBASE}/conf/tomcat/mpsite/ROOT.war" "${MPSERVERBASE}/tomcat-mpsite/webapps"
	cp "${MPSERVERBASE}/conf/tomcat/mpsite/bin/setenv.sh" "${MPSERVERBASE}/tomcat-mpsite/bin/setenv.sh"
	cp "${MPSERVERBASE}/conf/tomcat/mpsite/bin/launchdTomcat.sh" "${MPSERVERBASE}/tomcat-mpsite/bin/launchdTomcat.sh"
	cp -r "${MPSERVERBASE}/conf/tomcat/mpsite/conf/Catalina" "${MPSERVERBASE}/tomcat-mpsite/conf/"
	cp -r "${MPSERVERBASE}/conf/tomcat/mpsite/conf/server.xml" "${MPSERVERBASE}/tomcat-mpsite/conf/server.xml"
	cp -r "${MPSERVERBASE}/conf/tomcat/mpsite/conf/web.xml" "${MPSERVERBASE}/tomcat-mpsite/conf/web.xml"
	rm -rf "${MPSERVERBASE}/jetty-mpsite"

	chmod -R 0775 ${MPSERVERBASE}/tomcat-mpws
	chown -R $OWNERGRP ${MPSERVERBASE}/tomcat-mpws
	chmod -R 0775 ${MPSERVERBASE}/tomcat-mpsite
	chown -R 79:70 ${MPSERVERBASE}/tomcat-mpsite
fi

chown -R $OWNERGRP ${MPSERVERBASE}/Logs
chmod 0775 ${MPSERVERBASE}


# ------------------
# Clean up structure place holders
# ------------------
find ${MPSERVERBASE} -name ".mpRM" -print | xargs -I{} rm -rf {}

# ------------------
# Create Archive
# ------------------
zip -r ${MPBASE}/MacPatch_Server.zip ${MPSERVERBASE}