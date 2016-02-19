#!/bin/bash

# ------------------------------------------------------------
# 	Script to build Reposado server for MacPatch
#
#	This Script supports only Mac OS X at this time
#
#	Version: 1.0.0
#
#	History:
# ------------------------------------------------------------

MP_BUILD_DIR=/Library/MacPatch/Reposado
TMP_DIR=/private/var/tmp/MPReposado
#BAS_DIR=$(cd $(dirname "$0"); pwd)
BAS_DIR=/Library/MacPatch/Server
SRC_DIR="$BAS_DIR/conf/src"
FLS_DIR="$BAS_DIR/conf/Reposado"
OWNERGRP="79:70"

if [ "`whoami`" != "root" ] ; then   # If not root user,
   # Run this script again as root
   echo
   echo "You must be an admin user to run this script."
   echo "Please re-run the script using sudo."
   echo
   exit 1;
fi

# ------------------------------------------------------------
# Set up TMP dir for download and compiles
# ------------------------------------------------------------
# Remove if exists
if [ -d "${TMP_DIR}" ]; then
	rm -rf ${TMP_DIR}
fi

# Create and go to tmp dir
mkdir -p ${TMP_DIR}
cd ${TMP_DIR}

HTTP_SW=`find "${SRC_DIR}" -name "nginx"* -type f -exec basename {} \; | head -n 1`
PCRE_SW=`find "${SRC_DIR}" -name "pcre-"* -type f -exec basename {} \; | head -n 1`
OSSL_SW=`find "${SRC_DIR}" -name "openssl-"* -type f -exec basename {} \; | head -n 1`

# PCRE
mkdir ${TMP_DIR}/pcre
tar xvfz ${SRC_DIR}/${PCRE_SW} --strip 1 -C ${TMP_DIR}/pcre

# NGINX
mkdir ${TMP_DIR}/nginx
tar xvfz ${SRC_DIR}/${HTTP_SW} --strip 1 -C ${TMP_DIR}/nginx

# OpenSSL
mkdir ${TMP_DIR}/openssl
tar xvfz ${SRC_DIR}/${OSSL_SW} --strip 1 -C ${TMP_DIR}/openssl

if [ ! -d "${MP_BUILD_DIR}" ]; then
	mkdir -p "${MP_BUILD_DIR}"
fi

echo "[STEP]: Build and Compile HTTPD..."
cd ${TMP_DIR}/nginx

export KERNEL_BITS=64
./configure --prefix=${MP_BUILD_DIR}/nginx \
--without-http_autoindex_module \
--without-http_ssi_module \
--with-http_ssl_module \
--with-openssl=${TMP_DIR}/openssl \
--with-pcre=${TMP_DIR}/pcre

make
make install

mkdir -p ${MP_BUILD_DIR}/Content/html
mkdir -p ${MP_BUILD_DIR}/Content/metadata
mkdir -p ${MP_BUILD_DIR}/Logs

# Clone Reposado
cd ${MP_BUILD_DIR}
git clone https://github.com/wdas/reposado.git

# Reposado Plist
cp "${FLS_DIR}/preferences.plist" ${MP_BUILD_DIR}/reposado/code/preferences.plist

# Set Hostname for repo_sync
clear
HOSTNAME=`hostname`
read -p "Reposado Server Hostname [$HOSTNAME]: " NEWHOSTNAME
NEWHOSTNAME=${NEWHOSTNAME:-$HOSTNAME}
BASEURL="http://$NEWHOSTNAME"
defaults write "${MP_BUILD_DIR}"/reposado/code/preferences LocalCatalogURLBase "$BASEURL"
plutil -convert xml1 "${MP_BUILD_DIR}"/reposado/code/preferences.plist
chmod 0755 "${MP_BUILD_DIR}"/reposado/code/preferences.plist

# Nginx Config
cp "${FLS_DIR}/nginx/nginx.conf" ${MP_BUILD_DIR}/nginx/conf/nginx.conf

# Set Permissions
chown -R 79:70 "${MP_BUILD_DIR}"

# Launch Daemons
cp -r "${FLS_DIR}/LaunchDaemons" ${MP_BUILD_DIR}
chown -R root:wheel "${MP_BUILD_DIR}/LaunchDaemons"
chmod 0644 "${MP_BUILD_DIR}"/LaunchDaemons/*
if [ -f /Library/LaunchDaemons/gov.llnl.mp.reposado.nginx.plist ]; then
	rm /Library/LaunchDaemons/gov.llnl.mp.reposado.nginx.plist
fi
if [ -f /Library/LaunchDaemons/gov.llnl.mp.reposado.sync.plist ]; then
	rm /Library/LaunchDaemons/gov.llnl.mp.reposado.sync.plist
fi
ln -s ${MP_BUILD_DIR}/LaunchDaemons/gov.llnl.mp.reposado.nginx.plist /Library/LaunchDaemons/gov.llnl.mp.reposado.nginx.plist
ln -s ${MP_BUILD_DIR}/LaunchDaemons/gov.llnl.mp.reposado.sync.plist /Library/LaunchDaemons/gov.llnl.mp.reposado.sync.plist

# Start Services
read -p "Would you like to load NGINX (Y/N)? [Y]: " LOADWWW
LOADWWW=${LOADWWW:-Y}
if [ "$LOADWWW" == "n" ] || [ "$LOADWWW" == "N" ] || [ "$LOADWWW" == "y" ] || [ "$LOADWWW" == "Y" ]; then
	if [ "$LOADWWW" == "y" ] || [ "$LOADWWW" == "Y" ] ; then
		launchctl unload /Library/LaunchDaemons/gov.llnl.mp.reposado.nginx.plist
		launchctl load /Library/LaunchDaemons/gov.llnl.mp.reposado.nginx.plist
	fi
fi
read -p "Would you like to load repo_sync (Y/N)? [Y]: " LOADREPO
LOADREPO=${LOADREPO:-Y}
if [ "$LOADREPO" == "n" ] || [ "$LOADREPO" == "N" ] || [ "$LOADREPO" == "y" ] || [ "$LOADREPO" == "Y" ]; then
	if [ "$LOADREPO" == "y" ] || [ "$LOADREPO" == "Y" ] ; then
		launchctl unload /Library/LaunchDaemons/gov.llnl.mp.reposado.sync.plist
		launchctl load /Library/LaunchDaemons/gov.llnl.mp.reposado.sync.plist
	fi
fi

# Setup Log Rotation for access.log
read -p "Would you like to enable nginx access.log rotation (Y/N)? [Y]: " LOADLOG
LOADLOG=${LOADLOG:-Y}
if [ "$LOADLOG" == "n" ] || [ "$LOADLOG" == "N" ] || [ "$LOADLOG" == "y" ] || [ "$LOADLOG" == "Y" ]; then
	if [ "$LOADLOG" == "y" ] || [ "$LOADLOG" == "Y" ] ; then
		cp ${FLS_DIR}/newsyslog.d/mp.nginx.conf /private/etc/newsyslog.d/mp.nginx.conf
	fi
fi
