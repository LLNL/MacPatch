#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildServerPKG.sh
# Version: 1.6
#
# Description:
# This is a very simple script to demonstrate how to automate
# the build process of the MacPatch Server.
#
# Info:
# Simply modify the GITROOT and BUILDROOT variables
#
# History:
# 1.6: 	Synced with MPBuildServer.sh file
#
# -------------------------------------------------------------
clear

MP_SERVER_PKG_VER="1.1.0.0"
MPBASE="/Library/MacPatch"
MPSERVERBASE="/Library/MacPatch/Server"
GITROOT="/Library/MacPatch/tmp/MacPatch"
BUILDROOT="/Library/MacPatch/tmp/Server"
SRC_DIR="${MPSERVERBASE}/conf/src"
J2EE_SW=`find "${GITROOT}/MacPatch Server" -name "apache-tomcat-"* -type f -exec basename {} \; | head -n 1`

XOSTYPE=`uname -s`
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
# Server Check 
# -----------------------------------
BUILDPKG="Y"

if [ -d "${MPSERVERBASE}" ]; then 
	echo
	echo "This system contains a possible MacPatch server deployment."
	echo "This deployment will be removed allong with all of the content."
	echo
	read -p "Would you like to continue (Y/N)? [N]: " BUILDPKG
	BUILDPKG=${BUILDPKG:-N}
	echo
fi

if [ "$BUILDPKG" == "n" ] || [ "$BUILDPKG" == "N" ] || [ "$BUILDPKG" == "y" ] || [ "$BUILDPKG" == "Y" ]; then

	if [ "$BUILDPKG" == "n" ] || [ "$BUILDPKG" == "N" ] ; then
			exit 0;
	fi
else
	echo
	echo "Error: Incorrect answer type, exiting script."
	echo
	exit 1;
fi

# -----------------------------------
# OS Check
# -----------------------------------

# Check os type
if [ $XOSTYPE == "Linux" ]; then
	echo "OS Type $XOSTYPE is not supported. Now exiting."
  	exit 1; 
fi

# -----------------------------------
# Main
# -----------------------------------

if [ -d "$BUILDROOT" ]; then
	rm -rf ${BUILDROOT}
	mkdir -p ${BUILDROOT}
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
mkdir -p /Library/MacPatch/Content/Web/tools
mkdir -p /Library/MacPatch/Server
mkdir -p /Library/MacPatch/Server/lib
mkdir -p /Library/MacPatch/Server/Logs

# ------------------
# Copy compiled files
# ------------------
cp -R ${GITROOT}/MacPatch\ Server/Server ${MPBASE}
cp ${MPSERVERBASE}/conf/Content/Web/tools/MPAgentUploader.app.zip /Library/MacPatch/Content/Web/tools/

# ------------------
# Setup Tomcat
# ------------------

mkdir -p "${MPSERVERBASE}/apache-tomcat"
tar xvfz ${SRC_DIR}/${J2EE_SW} --strip 1 -C ${MPSERVERBASE}/apache-tomcat
chmod +x ${MPSERVERBASE}/apache-tomcat/bin/*
rm -rf ${MPSERVERBASE}/apache-tomcat/webapps/docs
rm -rf ${MPSERVERBASE}/apache-tomcat/webapps/examples
rm -rf ${MPSERVERBASE}/apache-tomcat/webapps/ROOT

# ------------------
# Build Apache
# ------------------
${MPSERVERBASE}/conf/scripts/MPHttpServerBuild.sh
chown -R $OWNERGRP ${MPSERVERBASE}/Apache2

# ------------------
# Link & Set Permissions
# ------------------
ln -s ${MPSERVERBASE}/conf/Content/Doc ${MPBASE}/Content/Doc
chown -R $OWNERGRP ${MPSERVERBASE}

cp -r ${MPSERVERBASE}/apache-tomcat ${MPSERVERBASE}/tomcat-mpws
mv ${MPSERVERBASE}/apache-tomcat ${MPSERVERBASE}/tomcat-mpsite
mkdir -p ${MPSERVERBASE}/tomcat-mpws/InvData/Files
mkdir -p ${MPSERVERBASE}/tomcat-mpws/InvData/Errors
mkdir -p ${MPSERVERBASE}/tomcat-mpws/InvData/Processed

# Web Services - App
mkdir -p "${MPSERVERBASE}/conf/app/war/wsl"
mkdir -p "${MPSERVERBASE}/conf/app/.wsl"
unzip "${MPSERVERBASE}/conf/src/openbd/openbd.war" -d "${MPSERVERBASE}/conf/app/.wsl"
cp -r "${MPSERVERBASE}/conf/app/wsl" "${MPSERVERBASE}/conf/app/.wsl"
cp -r "${MPSERVERBASE}/conf/app/mods/wsl" "${MPSERVERBASE}/conf/app/.wsl"
cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/conf/app/.wsl/WEB-INF/lib/systemcommand.jar"
chmod -R 0775 "${MPSERVERBASE}/conf/app/.wsl"
chown -R $OWNERGRP "${MPSERVERBASE}/conf/app/.wsl"
jar cf "${MPSERVERBASE}/conf/app/war/wsl/ROOT.war" -C "${MPSERVERBASE}/conf/app/.wsl" .
rm -rf "${MPSERVERBASE}/conf/app/.wsl"
rm -rf "${MPSERVERBASE}/conf/app/wsl"

# Admin Site - App
mkdir -p "${MPSERVERBASE}/conf/app/war/site"
mkdir -p "${MPSERVERBASE}/conf/app/.site"
unzip "${MPSERVERBASE}/conf/src/openbd/openbd.war" -d "${MPSERVERBASE}/conf/app/.site"
cp -r "${MPSERVERBASE}/conf/app/site" "${MPSERVERBASE}/conf/app/.site"
cp -r "${MPSERVERBASE}/conf/app/mods/site" "${MPSERVERBASE}/conf/app/.site"
cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/conf/app/.site/WEB-INF/lib/systemcommand.jar"
chmod -R 0775 "${MPSERVERBASE}/conf/app/.site"
chown -R $OWNERGRP "${MPSERVERBASE}/conf/app/.site"
jar cf "${MPSERVERBASE}/conf/app/war/site/ROOT.war" -C "${MPSERVERBASE}/conf/app/.site" .
rm -rf "${MPSERVERBASE}/conf/app/.site"
rm -rf "${MPSERVERBASE}/conf/app/site"

# Tomcat Config - WSL
MPCONFWSL="${MPSERVERBASE}/conf/tomcat/mpws"
MPSRVTOMWSL="${MPSERVERBASE}/tomcat-mpws"
cp "${MPSERVERBASE}/conf/app/war/wsl/ROOT.war" "${MPSRVTOMWSL}/webapps"
cp "${MPCONFWSL}/bin/setenv.sh" "${MPSRVTOMWSL}/bin/setenv.sh"
cp "${MPCONFWSL}/bin/launchdTomcat.sh" "${MPSRVTOMWSL}/bin/launchdTomcat.sh"
cp -r "${MPCONFWSL}/conf/Catalina" "${MPSRVTOMWSL}/conf/"
cp -r "${MPCONFWSL}/conf/server.xml" "${MPSRVTOMWSL}/conf/server.xml"
cp -r "${MPCONFWSL}/conf/web.xml" "${MPSRVTOMWSL}/conf/web.xml"
chmod -R 0775 "${MPSRVTOMWSL}"
chown -R $OWNERGRP "${MPSRVTOMWSL}"

# Tomcat Config - Admin
MPCONFSITE="${MPSERVERBASE}/conf/tomcat/mpsite"
MPSRVTOMSITE="${MPSERVERBASE}/tomcat-mpsite"
cp "${MPSERVERBASE}/conf/app/war/site/ROOT.war" "${MPSRVTOMSITE}/webapps"
cp "${MPCONFSITE}/bin/setenv.sh" "${MPSRVTOMSITE}/bin/setenv.sh"
cp "${MPCONFSITE}/bin/launchdTomcat.sh" "${MPSRVTOMSITE}/bin/launchdTomcat.sh"
cp -r "${MPCONFSITE}/conf/Catalina" "${MPSRVTOMSITE}/conf/"
cp -r "${MPCONFSITE}/conf/server.xml" "${MPSRVTOMSITE}/conf/server.xml"
cp -r "${MPCONFSITE}/conf/web.xml" "${MPSRVTOMSITE}/conf/web.xml"
chmod -R 0775 "${MPSRVTOMSITE}"
chown -R $OWNERGRP "${MPSRVTOMSITE}"

# Set Permissions
chown -R $OWNERGRP ${MPSERVERBASE}/Logs
chmod 0775 ${MPSERVERBASE}
chown root:wheel ${MPSERVERBASE}/conf/LaunchDaemons/*.plist
chmod 0644 ${MPSERVERBASE}/conf/LaunchDaemons/*.plist

# ------------------
# Clean up structure place holders
# ------------------
find ${MPSERVERBASE} -name ".mpRM" -print | xargs -I{} rm -rf {}

# ------------------
# Clean up un-needed files for binary distribution
# If src files are needed, they can be cloned
# ------------------
rm -rf "${MPSERVERBASE}/conf/scripts/Linux"
rm -rf "${MPSERVERBASE}/conf/scripts/MPHttpServerBuild.sh"
rm -rf "${MPSERVERBASE}/conf/scripts/_Old_"
rm -rf "${MPSERVERBASE}/conf/src/openbd"
find "${MPSERVERBASE}/conf/src" -name *.tar.gz -print | xargs -I{} rm {}
rm -f "${MPSERVERBASE}/conf/lib"

# ------------------
# Move Files For Packaging
# ------------------
PKG_FILES_ROOT_MP="${BUILDROOT}/Server/Files/Library/MacPatch"

cp -R ${GITROOT}/MacPatch\ PKG/Server ${BUILDROOT}

mv "${MPSERVERBASE}" "${PKG_FILES_ROOT_MP}/"
mv "${MPBASE}/Content" "${PKG_FILES_ROOT_MP}/"

# ------------------
# Create the Server pkg
# ------------------
mkdir -p "${BUILDROOT}/PKG"

# Create Server base package
pkgbuild --root "${BUILDROOT}/Server/Files/Library" \
--identifier gov.llnl.mp.server \
--install-location /Library \
--scripts ${BUILDROOT}/Server/Scripts \
--version $MP_SERVER_PKG_VER \
${BUILDROOT}/PKG/Server.pkg

# Create the final package with scripts and resources
productbuild --distribution ${BUILDROOT}/Server/Distribution \
--resources ${BUILDROOT}/Server/Resources \
--package-path ${BUILDROOT}/PKG \
${BUILDROOT}/PKG/_MPServer.pkg

# Possibly Sign the newly created PKG
clear
echo
read -p "Would you like to sign the installer PKG (Y/N)? [N]: " SIGNPKG
SIGNPKG=${SIGNPKG:-N}
echo

if [ "$SIGNPKG" == "Y" ] || [ "$SIGNPKG" == "y" ] ; then
	clear
	echo
	read -p "The name of the identity to use for signing the package: " IDENTNAME
	IDENTNAME=${IDENTNAME:-None}
	echo  "Signing package..."
	if [ "$IDENTNAME" == "None" ] ; then
		echo
		echo "There was an issue with the identity."
		echo "Please sign the package by hand."
		echo 
		echo "/usr/bin/productsign --sign [IDENTITY] ${BUILDROOT}/PKG/_MPServer.pkg ${BUILDROOT}/PKG/MPServer.pkg"
		echo
	else
		/usr/bin/productsign --sign "${IDENTNAME}" ${BUILDROOT}/PKG/_MPServer.pkg ${BUILDROOT}/PKG/MPServer.pkg
		if [ $? -eq 0 ]; then
			# GOOD
			rm ${BUILDROOT}/PKG/_MPServer.pkg
		else
			# FAILED
			echo "The signing process failed."
			echo 
			echo "Please sign the package by hand."
			echo 
			echo "/usr/bin/productsign --sign [IDENTITY] ${BUILDROOT}/PKG/_MPServer.pkg ${BUILDROOT}/PKG/MPServer.pkg"
			echo
		fi
		#
	fi

else
	mv ${BUILDROOT}/PKG/_MPServer.pkg ${BUILDROOT}/PKG/MPServer.pkg
fi

# Clean up the base package
rm ${BUILDROOT}/PKG/Server.pkg

# Open the build package dir
open ${BUILDROOT}/PKG
