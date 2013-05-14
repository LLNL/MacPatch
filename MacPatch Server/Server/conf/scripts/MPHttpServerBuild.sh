#!/bin/bash
#
# Will Download and Compile PCRE & Apache 2.4.x for MacPatch Server
#

MP_BUILD_DIR=/Library/MacPatch/Server
MP_CONF_DIR=${MP_BUILD_DIR}/conf
MP_HTTPD_DIR=/Library/MacPatch/Server/Apache2
MP_PCRE_DIR=${MP_BUILD_DIR}/lib/pcre
TMP_DIR=/private/var/tmp/MPApache

function checkHostConfig () {
	if [ "`whoami`" != "root" ] ; then   # If not root user,
	   # Run this script again as root
	   echo
	   echo "You must be an admin user to run this script."
	   echo "Please re-run the script using sudo."
	   echo
	   #exit 1;
	fi
	
	osType=`sw_vers -productName`
	osVer=`sw_vers -productVersion | cut -d . -f 2`
	if [ "$osType" != "Mac OS X Server" ]; then
		echo "System is not running Mac OS X Server. Server is recommended."
		#exit 1
	fi
	if [ "$osVer" -le "5" ]; then
		echo "System is not running Mac OS X (Server) 10.6 or higher. Setup can not continue."
		exit 1
	fi
}

# -----------------------------------
# Main
# -----------------------------------

checkHostConfig

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

# Download Software
curl -L -O http://www.us.apache.org/dist/httpd/httpd-2.4.3.tar.gz
curl -L -O http://www.us.apache.org/dist/apr/apr-1.4.6.tar.gz
curl -L -O http://www.us.apache.org/dist/apr/apr-util-1.4.1.tar.gz
curl -L -O http://voxel.dl.sourceforge.net/project/pcre/pcre/8.31/pcre-8.31.tar.gz

# Apache HTTPD
mkdir ${TMP_DIR}/httpd
tar xvfz ${TMP_DIR}/httpd-2.4.3.tar.gz --strip 1 -C ${TMP_DIR}/httpd
cp ${MP_CONF_DIR}/httpd/layout/config.layout.httpd ${TMP_DIR}/httpd/config.layout

# APR
mkdir ${TMP_DIR}/apr
tar xvfz ${TMP_DIR}/apr-1.4.6.tar.gz --strip 1 -C ${TMP_DIR}/apr
cp -R ${TMP_DIR}/apr ${TMP_DIR}/httpd/srclib/apr
cp ${MP_CONF_DIR}/httpd/layout/config.layout.apr ${TMP_DIR}/httpd/srclib/apr/config.layout

# APR-UTIL
mkdir ${TMP_DIR}/apr-util
tar xvfz ${TMP_DIR}/apr-util-1.4.1.tar.gz --strip 1 -C ${TMP_DIR}/apr-util
cp -R ${TMP_DIR}/apr-util ${TMP_DIR}/httpd/srclib/apr-util
cp ${MP_CONF_DIR}/httpd/layout/config.layout.apr ${TMP_DIR}/httpd/srclib/apr-util/config.layout

# PCRE
mkdir ${TMP_DIR}/pcre
tar xvfz ${TMP_DIR}/pcre-8.31.tar.gz --strip 1 -C ${TMP_DIR}/pcre

if [ ! -d "${MP_BUILD_DIR}" ]; then
	mkdir -p "${MP_BUILD_DIR}"
fi

# ------------------------------------------------------------
# Verify Xcode
# This is due to a issue with Mac OS X 8 and Xcode.
# ------------------------------------------------------------
if [ -d "/Applications/Xcode.app/Contents/Developer/Toolchains/OSX10.8.xctoolchain" ]; then
	ln -s "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain" "/Applications/Xcode.app/Contents/Developer/Toolchains/OSX10.8.xctoolchain"
fi

# ------------------------------------------------------------
# Compile PCRE
# ------------------------------------------------------------

# Remove old PCRE before compile
if [ -d "${MP_PCRE_DIR}" ]; then
	rm -rf "${MP_PCRE_DIR}"
fi

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

cd ${TMP_DIR}/httpd
./configure -enable-layout=MPHttpServer \
--prefix=/Library/MacPatch/Server/Apache2 \
--with-pcre=/Library/MacPatch/Server/lib/pcre \
--enable-mods-shared=all --with-included-apr

make
make install

# Copy MP conf files over
cp ${MP_CONF_DIR}/httpd/conf/httpd.conf ${MP_HTTPD_DIR}/conf/httpd.conf
cp ${MP_CONF_DIR}/httpd/conf/extra/httpd-default.conf ${MP_HTTPD_DIR}/conf/extra/httpd-default.conf
cp ${MP_CONF_DIR}/httpd/conf/extra/httpd-vhosts.conf ${MP_HTTPD_DIR}/conf/extra/httpd-vhosts.conf
cp ${MP_CONF_DIR}/httpd/conf/extra/httpd-mpm.conf ${MP_HTTPD_DIR}/conf/extra/httpd-mpm.conf

# ------------------------------------------------------------
# Generate self signed certificates
# ------------------------------------------------------------

USER="MacPatch"
EMAIL="admin@localhost"
ORG="MacPatch"
DOMAIN=`hostname`
COUNTRY="NO"
STATE="State"
LOCATION="Country"

OPTS=(/C="$COUNTRY"/ST="$STATE"/L="$LOCATION"/O="$ORG"/OU="$DOMAIN"/CN="$USER"/emailAddress="$EMAIL")

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

chown -R 70:79 /Library/MacPatch/Content
chown 70:79 /Library/MacPatch
chown -R 70:79 /Library/MacPatch/Server/Apache2
chown -R 70:79 /Library/MacPatch/Server/conf/Content
chown -R 70:79 /Library/MacPatch/Server/conf/apacheCerts

chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.httpd.plist
chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.httpd.plist

# ------------------------------------------------------------
# Sym-Link the HTTPD LaunchDaemon
# ------------------------------------------------------------

if [ -f /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.httpd.plist ]; then
	ln -s /Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.httpd.plist /Library/LaunchDaemons/gov.llnl.mp.httpd.plist
fi