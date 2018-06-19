#!/bin/bash
#
# ----------------------------------------------------------------------------
# Script: MPServerUpgrader.sh
# Version: 1.0
#
# Description:
# Upgrade script will upgrade a current install of the MacPatch server
#
# History:
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

# Script Variables -----------------------------------------------------------

MPBASE="/opt/MacPatch"
MPSRVCONTENT="${MPBASE}/Content/Web"
MPSERVERBASE="/opt/MacPatch/Server"
BUILDROOT="${MPBASE}/.build/server"

MPBASEBACK="/tmp/MPUSrvUpgrade"
GITBRANCH="master"
# Script Input Args ----------------------------------------------------------

usage() { echo "Usage: $0 [-b GitHub Branch]" 1>&2; exit 1; }

while getopts "hc:" opt; do
	case $opt in
		b)
			GITBRANCH=${OPTARG}
			;;
		h)
			echo
			usage
			exit 1
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

mkdir -p /tmp/MPUSrvUpgrade/Server/nginx/conf
cp $MPSERVERBASE/nginx/conf/nginx.conf /tmp/MPUSrvUpgrade/Server/nginx/conf
cp -r $MPSERVERBASE/nginx/conf/sites /tmp/MPUSrvUpgrade/Server/nginx/conf/sites

# etc files
mkdir -p /tmp/MPUSrvUpgrade/Server/etc
cp $MPSERVERBASE/etc /tmp/MPUSrvUpgrade/Server/etc

# py app files
mkdir -p /tmp/MPUSrvUpgrade/Server/apps
cp $MPSERVERBASE/apps/*.cfg /tmp/MPUSrvUpgrade/Server/apps

# Move the content files to tmp location
mv $MPSERVERBASE/Content /tmp/MPUSrvUpgrade/Content

#rm -rf /tmp/MPUSrvUpgrade/Content/Web/tools

# Move Base Bir
mv /opt/MacPatch /opt/MacPatch_back

# ----------------------------------------------------------------------------
# Download and build
# ----------------------------------------------------------------------------

# Clone new sw
cd /opt
git clone https://github.com/LLNL/MacPatch.git -b $GITBRANCH

# Build new sw
/opt/MacPatch/scripts/MPBuildServer.sh

# ----------------------------------------------------------------------------
# Restore
# ----------------------------------------------------------------------------

# nignx
mv $MPSERVERBASE/nginx/conf/nginx.conf $MPSERVERBASE/nginx/conf/nginx.conf.back
cp /tmp/MPUSrvUpgrade/Server/nginx/conf/nginx.conf $MPSERVERBASE/nginx/conf/nginx.conf

mv $MPSERVERBASE/nginx/conf/sites $MPSERVERBASE/nginx/conf/sites.back
cp -r /tmp/MPUSrvUpgrade/Server/nginx/sites $MPSERVERBASE/nginx/conf/sites

# etc
mv $MPSERVERBASE/etc $MPSERVERBASE/etc_orig
mv /tmp/MPUSrvUpgrade/Server/etc $MPSERVERBASE/etc

# py app
mv $MPSERVERBASE/apps/conf_console.cfg $MPSERVERBASE/apps/conf_console.cfg.back
cp /tmp/MPUSrvUpgrade/Server/apps/conf_console.cfg $MPSERVERBASE/apps/conf_console.cfg

mv $MPSERVERBASE/apps/config.cfg $MPSERVERBASE/apps/config.cfg.back
cp /tmp/MPUSrvUpgrade/Server/apps/config.cfg $MPSERVERBASE/apps/config.cfg

mv $MPSERVERBASE/apps/conf_wsapi.cfg $MPSERVERBASE/apps/conf_wsapi.cfg.back
cp /tmp/MPUSrvUpgrade/Server/apps/conf_wsapi.cfg $MPSERVERBASE/apps/conf_wsapi.cfg

# Content
rm -rf $MPSERVERBASE/Content/Web/clients
mv /tmp/MPUSrvUpgrade/Content/Web/clients $MPSERVERBASE/Content/Web/clients

rm -rf $MPSERVERBASE/Content/Web/patches
mv /tmp/MPUSrvUpgrade/Content/Web/patches $MPSERVERBASE/Content/Web/patches

rm -rf $MPSERVERBASE/Content/Web/sav
mv /tmp/MPUSrvUpgrade/Content/Web/sav $MPSERVERBASE/Content/Web/sav

rm -rf $MPSERVERBASE/Content/Web/sw
mv /tmp/MPUSrvUpgrade/Content/Web/sw $MPSERVERBASE/Content/Web/sw

# Update Schema
cd $MPSERVERBASE/apps
source env/bin/activate
./mpapi.py db upgrade head
deactivate

# Start Services
$MPSERVERBASE/conf/scripts/setup/ServerSetup.py --load All
