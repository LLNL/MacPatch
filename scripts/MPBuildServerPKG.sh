#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildServer.sh
# Version: 1.2.2
#
# Description:
# This is a very simple script to demonstrate how to automate
# the build process of the MacPatch Server.
#
# Info:
# Simply modify the GITROOT and BUILDROOT variables
#
# -------------------------------------------------------------
clear

MP_SERVER_PKG_VER="1.0.0.0"
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
cp -r ${MPSERVERBASE}/apache-tomcat ${MPSERVERBASE}/tomcat-mpsite
mkdir -p ${MPSERVERBASE}/tomcat-mpws/InvData/Files
mkdir -p ${MPSERVERBASE}/tomcat-mpws/InvData/Errors
mkdir -p ${MPSERVERBASE}/tomcat-mpws/InvData/Processed

cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/jetty-mpwsl/webapps/mpwsl/WEB-INF/lib/systemcommand.jar"
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

cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/jetty-mpsite/webapps/mp/WEB-INF/lib/systemcommand.jar"
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
chown -R $OWNERGRP ${MPSERVERBASE}/tomcat-mpsite

chown -R $OWNERGRP ${MPSERVERBASE}/Logs
chmod 0775 ${MPSERVERBASE}
rm -rf ${MPSERVERBASE}/apache-tomcat

# ------------------
# Clean up structure place holders
# ------------------
find ${MPSERVERBASE} -name ".mpRM" -print | xargs -I{} rm -rf {}

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
