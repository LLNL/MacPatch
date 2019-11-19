#!/bin/bash
#
# ----------------------------------------------------------------------------
# Script: MPServerUpgrader.sh
# Version: 2.0
#
# Description:
# Upgrade script will upgrade a current install of the MacPatch server
#
# History:
#
#   2.0     Add multiple upgrade types
#
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# How to use:
#
# sudo MPBuildServer.sh, will compile MacPatch server software
#
# sudo MPBuildServer.sh -p, will compile MacPatch server
# software, and create MacPatch server pkg installer. Only for
# Mac OS X.
#
# Linux requires MPBuildServer.sh, then run the buildLinuxPKG.sh
# locates in /Library/MacPatch/tmp/MacPatch/MacPatch PKG/Linux
#
# ----------------------------------------------------------------------------


# Make Sure User is root -----------------------------------------------------

if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this script."
   echo "Please re-run the script using sudo."
   echo
   exit 1;
fi

platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   platform='linux'
elif [[ "$unamestr" == 'Darwin' ]]; then
   platform='mac'
fi

OWNERGRP="79:70"
if [[ "$platform" == "linux" ]]; then
    OWNERGRP="www-data:www-data"
fi

# Script Variables -----------------------------------------------------------

MPBASE="/opt/MacPatch"
MPSRVCONTENT="${MPBASE}/Content/Web"
MPSERVERBASE="/opt/MacPatch/Server"
BUILDROOT="${MPBASE}/.build/server"
DTS=`date "+%Y%m%d-%H%M%S"`
SERVERBACKUPNAME="Server.$DTS"
SERVERBACKUPPATH="/opt/MacPatch/ServerUpgrade/$SERVERBACKUPNAME"
MPSERVERCONF="/opt/MacPatch/ServerConfig"
MPBASEBACK="/tmp/MPUSrvUpgrade"
GITBRANCH="master"
MOVECONTENT=true
MASTERSERVER=true
UPGRADETYPE="All"
# Script Input Args ----------------------------------------------------------

usage() { echo "Usage: $0 [-b GitHub Branch] [-t Upgrade Type (Webapps, All)] -d (Is Distribution server)" 1>&2; exit 1; }

while getopts "hb:t:d" opt; do
	case $opt in
		b)
			GITBRANCH=${OPTARG}
			;;
        t)
            UPGRADETYPE=${OPTARG}
            ;;
		h)
			echo
			usage
			exit 1
			;;
		d)
			MASTERSERVER=false
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			echo
			usage
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			echo
			usage
			exit 1
			;;
	esac
done

# Notice text -----------------------------------------------------------

clear
echo
echo "NOTICE..."
echo "This script is EXPERIMENTAL, please proceed with caution."
echo
echo "Before continuing with this script, an actual backup is recommended"
echo "in case anything should go wrong."
echo
echo "This script will backup all config files and nessasary content."
echo "It will then clone the MacPatch master branch and install the"
echo "new software. Once the install is completed. This script will"
echo "put back all of the configuration files and content."
echo
echo

read -p "Would you like to continue (Y/N)? [N]: " UPOK
UPOK=${UPOK:-N}
if [ "$UPOK" == "Y" ] || [ "$UPOK" == "y" ] ; then
	echo
else
	exit 0
fi

# ----------------------------------------------------------------------------
# Backup
# ----------------------------------------------------------------------------
# 1) Shutdown all services
$MPSERVERBASE/conf/scripts/setup/ServerSetup.py --unload All

# Make the Server Upgrade Backup directory
if [ ! -d "/opt/MacPatch/ServerUpgrade" ]; then
    mkdir -p /opt/MacPatch/ServerUpgrade
fi

if [[ "$UPGRADETYPE" == "All" ]]; then
    # Move and Rename the Server dir
    mv  $MPSERVERBASE $SERVERBACKUPPATH
elif [[ "$UPGRADETYPE" == "Webapps" ]]; then
    #statements
    mkdir -p $SERVERBACKUPPATH
    mv $MPSERVERBASE/env $SERVERBACKUPPATH/env
    mv $MPSERVERBASE/apps $SERVERBACKUPPATH/apps
    mv $MPSERVERBASE/conf $SERVERBACKUPPATH/conf
else
    echo "Invalid upgrade type, now exiting."
    exit 1
fi

# ----------------------------------------------------------------------------
# Download and build
# ----------------------------------------------------------------------------

# Pull Down Git Changes
cd /opt/MacPatch
git pull


if [[ "$UPGRADETYPE" == "All" ]]; then
    # Build new instance of the Server
    /opt/MacPatch/scripts/MPBuildServer.sh -u
elif [[ "$UPGRADETYPE" == "Webapps" ]]; then
    # Copy new web apps
    cp -r $MPBASE/Source/Server/apps $MPSERVERBASE/
    cp -r $MPBASE/Source/Server/conf $MPSERVERBASE/

    # Upgrade Yarn Libs
    echo
    echo "* Installing Javascript modules"
    echo
    cd ${MPSERVERBASE}/apps/mpconsole
    yarn install --cwd ${MPSERVERBASE}/apps/mpconsole --modules-folder static/yarn_components --no-bin-links

else
    echo "Invalid upgrade type, now exiting."
    exit 1
fi    

# ----------------------------------------------------------------------------
# Upgrade
# ----------------------------------------------------------------------------

# Update Schema, only on master server
echo
echo "* Updating DB Schema"
echo
if $MASTERSERVER; then
	cd $MPSERVERBASE/apps
    source ${MPSERVERBASE}/env/api/bin/activate
	./mpapi.py db upgrade head
	deactivate
fi

# ----------------------------------------------------------------------------
# Update Existsing config files with changes
# ----------------------------------------------------------------------------

# ------------------
# Clean up structure place holders
# ------------------
echo
echo "* Clean up Server dirtectory"
echo "-----------------------------------------------------------------------"
find ${MPBASE}/Server -name ".mpRM" -print | xargs -I{} rm -rf {}

# ------------------
# Set Permissions
# ------------------
clear
echo "Setting Permissions..."
chmod -R 0775 "${MPBASE}/Content"
chown -R $OWNERGRP "${MPBASE}/Content"
chmod -R 0775 "${MPSERVERBASE}/logs"
chmod -R 0775 "${MPSERVERBASE}/etc"
chmod -R 0775 "${MPSERVERBASE}/InvData"
chown -R $OWNERGRP "${MPSERVERBASE}/env"


# Start Services
$MPSERVERBASE/conf/scripts/setup/ServerSetup.py --load All
