#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildServer.sh
# Version: 1.6.4
#
# Description:
# This is a very simple script to demonstrate how to automate
# the build process of the MacPatch Server.
#
# Info:
# Simply modify the GITROOT and BUILDROOT variables
#
# History:
# 1.4: 		Remove Jetty Support
#			Added Tomcat 7.0.57
# 1.5:		Added Tomcat 7.0.63
# 1.6:		Variableized the tomcat config
#			removed all Jetty refs
# 1.6.1: 	Now using InstallPyMods.sh script to install python modules
# 1.6.2:	Fix cp paths
# 1.6.3:	Updated OpenJDK to 1.8.0
# 1.6.4:	Updated to install Ubuntu packages
#
# -------------------------------------------------------------
MPBASE="/Library/MacPatch"
MPSERVERBASE="/Library/MacPatch/Server"
GITROOT="/Library/MacPatch/tmp/MacPatch"
BUILDROOT="/Library/MacPatch/tmp/build/Server"
SRC_DIR="${MPSERVERBASE}/conf/src"
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
# Install required packages
# ------------------

if [ $XOSTYPE == "Linux" ]; then
	if [ -f "/etc/redhat-release" ]; then
		# Check if needed packges are installed or install
		pkgs=("gcc-c++" "git" "openssl-devel" "java-1.8.0-openjdk-devel" "libxml2-devel" "bzip2-libs" "bzip2-devel" "bzip2" "python-pip" "mysql-connector-python")
	
		for i in "${pkgs[@]}"
		do
			p=`rpm -qa --qf '%{NAME}\n' | grep -e ${i}$`
			if [ -z $p ]; then
				echo "Install $i"
				yum install -y ${i}
			fi
		done

	elif [[ -r /etc/os-release ]]; then
	    . /etc/os-release
	    if [[ $ID = ubuntu ]]; then
	        pkgs=("git" "build-essential" "openjdk-7-jre" "openjdk-7-jdk" "zip" "libssl-dev" "libxml2-dev" "python-pip" "mysql-connector-python")
	        for i in "${pkgs[@]}"
			do
				p=`dpkg -l | grep '^ii' | grep ${i} | head -n 1 | awk '{print $2}' | grep ^${i}`
				if [ -z $p ]; then
					echo "Install $i"
					apt-get install -q -f -y ${i}
				fi
			done
	    fi
	else
		echo "Not running a supported version of Linux."
		exit 1;
	fi
fi

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
rm -rf "${MPSERVERBASE}/conf/app/.wsl/index.cfm"
rm -rf "${MPSERVERBASE}/conf/app/.wsl/manual"
cp -r "${MPSERVERBASE}"/conf/app/wsl/* "${MPSERVERBASE}"/conf/app/.wsl
cp -r "${MPSERVERBASE}"/conf/app/mods/wsl/* "${MPSERVERBASE}"/conf/app/.wsl

cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/conf/app/wsl_tmp/WEB-INF/lib/systemcommand.jar"
chmod -R 0775 "${MPSERVERBASE}/conf/app/.wsl"
chown -R $OWNERGRP "${MPSERVERBASE}/conf/app/.wsl"
jar cf "${MPSERVERBASE}/conf/app/war/wsl/ROOT.war" -C "${MPSERVERBASE}/conf/app/.wsl" .

# Admin Site - App
mkdir -p "${MPSERVERBASE}/conf/app/war/site"
mkdir -p "${MPSERVERBASE}/conf/app/.site"
unzip "${MPSERVERBASE}/conf/src/openbd/openbd.war" -d "${MPSERVERBASE}/conf/app/.site"
rm -rf "${MPSERVERBASE}/conf/app/.site/index.cfm"
rm -rf "${MPSERVERBASE}/conf/app/.site/manual"
cp -r "${MPSERVERBASE}"/conf/app/site/* "${MPSERVERBASE}"/conf/app/.site
cp -r "${MPSERVERBASE}"/conf/app/mods/site/* "${MPSERVERBASE}"/conf/app/.site
cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/conf/app/.site/WEB-INF/lib/systemcommand.jar"
chmod -R 0775 "${MPSERVERBASE}/conf/app/.site"
chown -R $OWNERGRP "${MPSERVERBASE}/conf/app/.site"
jar cf "${MPSERVERBASE}/conf/app/war/site/ROOT.war" -C "${MPSERVERBASE}/conf/app/.site" .

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

# ------------------------------------
# Install Python Packages
# ------------------------------------
if [ -f "/usr/bin/easy_install" ]; then
	${MPSERVERBASE}/conf/scripts/InstallPyMods.sh
fi

# ------------------
# Clean up structure place holders
# ------------------
find ${MPSERVERBASE} -name ".mpRM" -print | xargs -I{} rm -rf {}

# ------------------
# Create Archive
# ------------------
MKARC=0
read -p "Create Archive Of Server Install [N]: " MKARC
MKARC=${MKARC:-0}
if [ $MKARC == 1 ]; then
	zip -r ${MPBASE}/MacPatch_Server.zip ${MPSERVERBASE}
fi
