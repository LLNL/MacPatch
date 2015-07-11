#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildProxyServer.sh
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
BUILDROOT="/Library/MacPatch/tmp/build/ProxyServer"
J2EE_SW=`find "${GITROOT}/MacPatch Server" -name "apache-tomcat-"* -type f -exec basename {} \; | head -n 1`

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
# Install required packages
# ------------------

if [ $XOSTYPE == "Linux" ]; then
	if [ -f "/etc/redhat-release" ]; then
		# Check if needed packges are installed or install
		pkgs=("gcc-c++" "git" "openssl-devel" "java-1.7.0-openjdk-devel" "libxml2-devel" "bzip2-libs" "bzip2-devel" "bzip2" "python-pip" "mysql-connector-python")

		for i in "${pkgs[@]}"
		do
			p=`rpm -qa --qf '%{NAME}\n' | grep -e ${i}$`
			if [ -z $p ]; then
				echo "Install $i"
				yum install -y ${i}
			fi
		done
	fi
fi

# ------------------
# Setup Tomcat
# ------------------

mkdir -p "${MPSERVERBASE}/apache-tomcat"
tar xvfz ${SRC_DIR}/${J2EE_SW} --strip 1 -C ${MPSERVERBASE}/tomcat-mpproxy
chmod +x ${MPSERVERBASE}/tomcat-mpproxyt/bin/*
rm -rf ${MPSERVERBASE}/tomcat-mpproxy/webapps/docs
rm -rf ${MPSERVERBASE}/tomcat-mpproxy/webapps/examples
rm -rf ${MPSERVERBASE}/tomcat-mpproxy/webapps/ROOT

# Web Services - App
mkdir -p "${MPSERVERBASE}/conf/app/war/proxy"
mkdir -p "${MPSERVERBASE}/conf/app/.proxy"
unzip "${MPSERVERBASE}/conf/src/openbd/openbd.war" -d "${MPSERVERBASE}/conf/app/.proxy"
rm -rf "${MPSERVERBASE}/conf/app/.proxy/manual"
rm -rf "${MPSERVERBASE}/conf/app/.proxy/bluedragon"
rm -rf "${MPSERVERBASE}/conf/app/.proxy/WEB-INF/classes/com"
rm -rf "${MPSERVERBASE}/conf/app/.proxy/WEB-INF/customtags"
mkdir -p "${MPSERVERBASE}/conf/app/.proxy/WEB-INF/customtags"
cp -r "${MPSERVERBASE}/conf/app/proxy/" "${MPSERVERBASE}/conf/app/.proxy"
cp -r "${MPSERVERBASE}/conf/app/mods/proxy/" "${MPSERVERBASE}/conf/app/.proxy"
cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/conf/app/.wsl/WEB-INF/lib/systemcommand.jar"
chmod -R 0775 "${MPSERVERBASE}/conf/app/.proxy"
chown -R $OWNERGRP "${MPSERVERBASE}/conf/app/.proxy"
jar cf "${MPSERVERBASE}/conf/app/war/wsl/ROOT.war" -C "${MPSERVERBASE}/conf/app/.proxy" .

# Tomcat Config - WSL
MPCONFWSL="${MPSERVERBASE}/conf/tomcat/proxy"
MPSRVTOMWSL="${MPSERVERBASE}/tomcat-mpproxy"
cp "${MPSERVERBASE}/conf/app/war/wsl/ROOT.war" "${MPSRVTOMWSL}/webapps"
cp "${MPCONFWSL}/bin/setenv.sh" "${MPSRVTOMWSL}/bin/setenv.sh"
cp "${MPCONFWSL}/bin/launchdTomcat.sh" "${MPSRVTOMWSL}/bin/launchdTomcat.sh"
cp -r "${MPCONFWSL}/conf/Catalina" "${MPSRVTOMWSL}/conf/"
cp -r "${MPCONFWSL}/conf/server.xml" "${MPSRVTOMWSL}/conf/server.xml"
cp -r "${MPCONFWSL}/conf/web.xml" "${MPSRVTOMWSL}/conf/web.xml"
chmod -R 0775 "${MPSRVTOMWSL}"
chown -R $OWNERGRP "${MPSRVTOMWSL}"

# ------------------
# Build Apache
# ------------------
${MPSERVERBASE}/conf/scripts/MPHttpServerBuild.sh

# ------------------
# Link & Set Permissions
# ------------------
chown -R 79:70 ${MPSERVERBASE}
chmod -R 0775 ${MPSERVERBASE}
chown root:wheel ${MPSERVERBASE}/conf/LaunchDaemons/*.plist
chmod 0644 ${MPSERVERBASE}/conf/LaunchDaemons/*.plist

# ------------------
# Clean up structure place holders
# ------------------
find ${MPSERVERBASE} -name ".mpRM" -print | xargs -I{} rm -rf {}
