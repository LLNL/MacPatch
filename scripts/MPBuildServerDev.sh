#!/bin/bash
#
# -------------------------------------------------------------
# Dev Script
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

# Web Services - App
rm -rf "${MPSERVERBASE}/conf/app/wsl_tmp"

mkdir -p "${MPSERVERBASE}/conf/app/war/wsl"
mkdir -p "${MPSERVERBASE}/conf/app/wsl_tmp"
unzip "${MPSERVERBASE}/conf/src/openbd/openbd.war" -d "${MPSERVERBASE}/conf/app/wsl_tmp"
rm -rf "${MPSERVERBASE}/conf/app/wsl_tmp/index.cfm"
rm -rf "${MPSERVERBASE}/conf/app/wsl_tmp/manual"

echo "${MPSERVERBASE}/conf/app/wsl ${MPSERVERBASE}/conf/app/wsl_tmp"
cp -r "${MPSERVERBASE}"/conf/app/wsl/* "${MPSERVERBASE}"/conf/app/wsl_tmp
cp -r "${MPSERVERBASE}"/conf/app/mods/wsl/* "${MPSERVERBASE}"/conf/app/wsl_tmp

cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/conf/app/wsl_tmp/WEB-INF/lib/systemcommand.jar"
chmod -R 0775 "${MPSERVERBASE}/conf/app/wsl_tmp"
chown -R $OWNERGRP "${MPSERVERBASE}/conf/app/wsl_tmp"
#mv "${MPSERVERBASE}/conf/app/wsl_tmp" "${MPSERVERBASE}/conf/app/.wsl"
#jar cf "${MPSERVERBASE}/conf/app/war/wsl/ROOT.war" -C "${MPSERVERBASE}/conf/app/.wsl" .

exit

# Admin Site - App
mkdir -p "${MPSERVERBASE}/conf/app/war/site"
mkdir -p "${MPSERVERBASE}/conf/app/.site"
unzip "${MPSERVERBASE}/conf/src/openbd/openbd.war" -d "${MPSERVERBASE}/conf/app/.site"
rm -rf "${MPSERVERBASE}/conf/app/.site/index.cfm"
rm -rf "${MPSERVERBASE}/conf/app/.site/manual"
cp -r "${MPSERVERBASE}/conf/app/site/" "${MPSERVERBASE}/conf/app/.site"
cp -r "${MPSERVERBASE}/conf/app/mods/site/" "${MPSERVERBASE}/conf/app/.site"
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
