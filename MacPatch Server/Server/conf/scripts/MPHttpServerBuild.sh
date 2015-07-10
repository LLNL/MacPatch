#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPHttpServerBuild.sh
# Version: 1.1
#
# Description:
# Will Download and Compile PCRE & Apache 2.4.x for MacPatch Server
# Updated 6/27/14 Updated SW
#
# Info:
# Simply modify the GITROOT and BUILDROOT variables
#
# History:
# 1.1:	Added New Httpd and Apr-Util and PCRE source
#
# -------------------------------------------------------------

MP_BUILD_DIR=/Library/MacPatch/Server
MP_CONF_DIR=${MP_BUILD_DIR}/conf
MP_HTTPD_DIR=/Library/MacPatch/Server/Apache2
MP_PCRE_DIR=${MP_BUILD_DIR}/lib/pcre
TMP_DIR=/private/var/tmp/MPApache
SRC_DIR=${MP_BUILD_DIR}/conf/src
XOSTYPE=`uname -s`
USELINUX=false
USEMACOS=false
OWNERGRP="79:70"
DIST='OSX'

# Check and set os type
if [ $XOSTYPE == "Linux" ]; then

	if [ -f /etc/redhat-release ] ; then
		DIST='redhat'
	elif [ -f /etc/fedora-release ] ; then
		DIST=`redhat`
	elif [ -f /etc/lsb-release ] ; then
		. /etc/lsb-release
		DIST=$DISTRIB_ID
	fi

	USELINUX=true
	OWNERGRP="www-data:www-data"
elif [ $XOSTYPE == "Darwin" ]; then
	USEMACOS=true
else
  	echo "OS Type $XOSTYPE is not supported. Now exiting."
  	exit 1; 
fi

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

# "httpd-2.4.12.tar.gz"
HTTPD_SW=`find "${SRC_DIR}" -name "httpd-2"* -type f -exec basename {} \; | head -n 1`
# "apr-1.5.2.tar.gz"
APR_SW=`find "${SRC_DIR}" -name "apr-1"* -type f -exec basename {} \; | head -n 1`
# "apr-util-1.5.4.tar.gz"
APRUTIL_SW=`find "${SRC_DIR}" -name "apr-util-1"* -type f -exec basename {} \; | head -n 1`
# "pcre-8.36.tar.gz"
PCRE_SW=`find "${SRC_DIR}" -name "pcre-"* -type f -exec basename {} \; | head -n 1`

# Apache HTTPD
mkdir ${TMP_DIR}/httpd
tar xvfz ${SRC_DIR}/${HTTPD_SW} --strip 1 -C ${TMP_DIR}/httpd
if $USEMACOS; then
	cp ${MP_CONF_DIR}/httpd/layout/config.layout.httpd ${TMP_DIR}/httpd/config.layout
fi

# APR
mkdir ${TMP_DIR}/apr
tar xvfz ${SRC_DIR}/${APR_SW} --strip 1 -C ${TMP_DIR}/apr
cp -R ${TMP_DIR}/apr ${TMP_DIR}/httpd/srclib/apr
if $USEMACOS; then
	cp ${MP_CONF_DIR}/httpd/layout/config.layout.apr ${TMP_DIR}/httpd/srclib/apr/config.layout
fi

# APR-UTIL
mkdir ${TMP_DIR}/apr-util
tar xvfz ${SRC_DIR}/${APRUTIL_SW} --strip 1 -C ${TMP_DIR}/apr-util
cp -R ${TMP_DIR}/apr-util ${TMP_DIR}/httpd/srclib/apr-util
if $USEMACOS; then
	cp ${MP_CONF_DIR}/httpd/layout/config.layout.apr ${TMP_DIR}/httpd/srclib/apr-util/config.layout
fi

# PCRE
mkdir ${TMP_DIR}/pcre
tar xvfz ${SRC_DIR}/${PCRE_SW} --strip 1 -C ${TMP_DIR}/pcre

if [ ! -d "${MP_BUILD_DIR}" ]; then
	mkdir -p "${MP_BUILD_DIR}"
fi

# ------------------------------------------------------------
# Verify Xcode
# This is due to a issue with Mac OS X 8 and Xcode.
# ------------------------------------------------------------
if $USEMACOS; then
	if [ -d "/Applications/Xcode.app/Contents/Developer/Toolchains/OSX10.8.xctoolchain" ]; then
		ln -s "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain" "/Applications/Xcode.app/Contents/Developer/Toolchains/OSX10.8.xctoolchain"
	fi
fi

# ------------------------------------------------------------
# Compile PCRE
# ------------------------------------------------------------

# Remove old PCRE before compile
if [ -d "${MP_PCRE_DIR}" ]; then
	rm -rf "${MP_PCRE_DIR}"
fi

echo "[STEP]: Build and Compile PCRE..."
cd ${TMP_DIR}/pcre
./configure --prefix=${MP_PCRE_DIR}
make
make install

# ------------------------------------------------------------
# Compile HTTPD
# ------------------------------------------------------------

# Remove old HTTPD before compile
if [ -d "${MP_HTTPD_DIR}" ]; then
	rm -rf "${MP_HTTPD_DIR}"
fi


echo "[STEP]: Build and Compile HTTPD..."
cd ${TMP_DIR}/httpd

if $USEMACOS; then
./configure -enable-layout=MPHttpServer \
--prefix=/Library/MacPatch/Server/Apache2 \
--with-pcre=/Library/MacPatch/Server/lib/pcre \
--enable-mods-shared=all --with-included-apr
fi 

if $USELINUX; then
./configure \
--prefix=/Library/MacPatch/Server/Apache2 \
--with-pcre=/Library/MacPatch/Server/lib/pcre \
--enable-mods-shared="all ssl proxy" --with-included-apr
fi 

make
make install

# Copy MP conf files over
if $USEMACOS; then
	#cp ${MP_CONF_DIR}/httpd/conf/httpd.conf.mac ${MP_HTTPD_DIR}/conf/httpd.conf
	cp ${MP_CONF_DIR}/httpd/conf/httpd.conf ${MP_HTTPD_DIR}/conf/httpd.conf
fi
if $USELINUX; then
	cp ${MP_CONF_DIR}/httpd/conf/httpd.conf.lnx ${MP_HTTPD_DIR}/conf/httpd.conf
fi

cp ${MP_CONF_DIR}/httpd/conf/extra/httpd-default.conf ${MP_HTTPD_DIR}/conf/extra/httpd-default.conf

if $USELINUX; then
	cp ${MP_CONF_DIR}/httpd/conf/extra/httpd-vhosts.conf.lnx ${MP_HTTPD_DIR}/conf/extra/httpd-vhosts.conf
fi
if $USEMACOS; then
	cp ${MP_CONF_DIR}/httpd/conf/extra/httpd-vhosts.conf ${MP_HTTPD_DIR}/conf/extra/httpd-vhosts.conf
fi

cp ${MP_CONF_DIR}/httpd/conf/extra/httpd-mpm.conf ${MP_HTTPD_DIR}/conf/extra/httpd-mpm.conf

# ------------------------------------------------------------
# Generate self signed certificates
# ------------------------------------------------------------

if [ ! -d "/Library/MacPatch/Server/conf/apacheCerts" ]; then
	mkdir -p /Library/MacPatch/Server/conf/apacheCerts
fi

USER="MacPatch"
EMAIL="admin@localhost"
ORG="MacPatch"
DOMAIN=`hostname`
COUNTRY="NO"
STATE="State"
LOCATION="Country"

OPTS=(/C="$COUNTRY"/ST="$STATE"/L="$LOCATION"/O="$ORG"/OU="$USER"/CN="$DOMAIN"/emailAddress="$EMAIL")

COMMAND=(openssl req -new -x509 -nodes -days 999 -subj "${OPTS[@]}" -newkey rsa:2048 -keyout server.key -out server.crt)

"${COMMAND[@]}"
if (( $? )) ; then
    echo -e "ERROR: Something went wrong!"
    exit 1
else
	cp server.key /Library/MacPatch/Server/conf/apacheCerts/server.key
	cp server.crt /Library/MacPatch/Server/conf/apacheCerts/server.crt
	echo "Done!"
fi

# ------------------------------------------------------------
# Set Permissions
# ------------------------------------------------------------

chown -R $OWNERGRP /Library/MacPatch/Content
chown -R $OWNERGRP /Library/MacPatch
chown -R $OWNERGRP /Library/MacPatch/Server/Apache2
chown -R $OWNERGRP /Library/MacPatch/Server/conf/Content
chown -R $OWNERGRP /Library/MacPatch/Server/conf/apacheCerts

if $USEMACOS; then
	chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.httpd.plist
	chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.httpd.plist
fi

# ------------------------------------------------------------
# Sym-Link the HTTPD LaunchDaemon/init.d
# ------------------------------------------------------------
if $USEMACOS; then
	if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.httpd.plist ]; then
		ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.httpd.plist /Library/LaunchDaemons/gov.llnl.mp.httpd.plist
	fi
fi

if $USELINUX; then

	if [ "$DIST" == "redhat" ]; then
			SFILE1="/Library/MacPatch/Server/conf/init.d/MPApache"
			SUSCP1="systemctl enable MPApache"
		elif [ "$DIST" == "Ubuntu" ]; then
			SFILE1="/Library/MacPatch/Server/conf/init.d/Ubuntu/MPApache"
			SUSCP1="update-rc.d MPApache defaults"
		else
			echo "Distribution not supported. Startup scripts will not be generated."
			exit 1
		fi

	if [ -f "$SFILE1" ]; then
		chmod +x "$SFILE1"
		ln -s "$SFILE1" /etc/init.d/MPApache
		eval $SUSCP1
	fi
fi
