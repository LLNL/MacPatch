#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildProxyServer.sh
# Version: 1.2.0
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
BUILDROOT="/Library/MacPatch/tmp/build/Server"
SRC_DIR="${MPSERVERBASE}/conf/src"
J2EE_SW=`find "${GITROOT}/MacPatch Server" -name "apache-tomcat-"* -type f -exec basename {} \; | head -n 1`

XOSTYPE=`uname -s`
USELINUX=false
USERHEL=false
USEUBUNTU=false
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

# -----------------------------------
# Java Check
# -----------------------------------

if type -p java; then
    echo found java executable in PATH
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo found java executable in JAVA_HOME     
    _java="$JAVA_HOME/bin/java"
else
    echo "no java"
    echo "please install the latest version of java 1.8.x jdk"
    exit 1
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo version "$version"
    if [[ "$version" > "1.8" ]]; then
        echo "version is more than 1.8"
    else         
        echo "java version is less than 1.8"
        echo "please install the latest version of java 1.8.x jdk"
        exit 1
    fi
fi

# -----------------------------------
# Main
# -----------------------------------
clear
echo "Begin MacPatch Proxy Server build."


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
# Copy files
# ------------------
cp -R ${GITROOT}/MacPatch\ Server/Server ${MPBASE}

# ------------------
# Install required packages
# ------------------

if [ $XOSTYPE == "Linux" ]; then
	if [ -f "/etc/redhat-release" ]; then
		USERHEL=true
		# Check if needed packges are installed or install
		pkgs=("gcc-c++" "python-pip" "mysql-connector-python")
	
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
	    	USEUBUNTU=true
	    	# Install mysql python connector
	    	DEBPKGDIR="${SRC_DIR}/linux/ubuntu"
	    	MYDEBPYPKG="mysql-connector-python_2.0.4-1ubuntu14.10_all.deb"

	    	for P in `ls $DEBPKGDIR/*.deb`
	    	do
	    		if [[ $P == *$VERSION_ID* ]]; then
					MYDEBPYPKG=$P
					dpkg -i $MYDEBPYPKG   			
	    		fi
	    	done

	        pkgs=("build-essential" "python-pip")
	        for i in "${pkgs[@]}"
			do
				p=`dpkg -l | grep '^ii' | grep ${i} | head -n 1 | awk '{print $2}' | grep ^${i}`
				if [ -z $p ]; then
					echo
					echo "Install $i"
					echo
					apt-get build-dep ${i} -y
				fi
			done
	    fi
	else
		echo "Not running a supported version of Linux."
		exit 1;
	fi
fi

# ------------------
# Find JDK Java_Home
# ------------------

if [ $XOSTYPE == "Linux" ]; then
	if $USERHEL; then
		JHOME="/usr/lib/jvm/java-openjdk"
		if [ ! -d "/usr/lib/jvm/java-openjdk" ]; then
			read -p "Unable to find JAVA Home, please enter JAVA Home path: " JHOME
			if [ ! -d "$JHOME" ]; then
				echo "$JHOME not found. Please verify your JDK path and start again."
				exit 1;
			fi
		fi
	fi
	if $USEUBUNTU; then
		JHOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
		if [ ! -d $JHOME ]; then
			read -p "Unable to find JAVA Home, please enter JAVA Home path: " JHOME
			if [ ! -d "$JHOME" ]; then
				echo "$JHOME not found. Please verify your JDK path and start again."
				exit 1;
			fi
		fi
	fi
else
	JHOME=`/usr/libexec/java_home`
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

clear

# ------------------
# Build OpenSSL
# ------------------
MP_OSSL_DIR=${MPSERVERBASE}/lib/openssl

SSL_SW=`find "${SRC_DIR}" -name "openssl"* -type f -exec basename {} \; | head -n 1`
mkdir -p ${BUILDROOT}/openssl
tar xvfz ${SRC_DIR}/${SSL_SW} --strip 1 -C ${BUILDROOT}/openssl

if [ -d "${MP_OSSL_DIR}" ]; then
	rm -rf "${MP_OSSL_DIR}"
fi

echo "[STEP]: Build and Compile OpenSSL..."
cd ${BUILDROOT}/openssl
if [ $XOSTYPE == "Linux" ]; then
	make clean && make dclean
	export CFLAGS=-fPIC
	./config -shared --prefix=${MP_OSSL_DIR} \
	--openssldir=${MP_OSSL_DIR}
else
	./Configure darwin64-x86_64-cc -shared --prefix=${MP_OSSL_DIR} \
	--openssldir=${MP_OSSL_DIR}
fi

make
make install

# ------------------
# Build APR
# ------------------
MP_APR_DIR=${MPSERVERBASE}/lib/apr
APR_SW=`find "${SRC_DIR}" -name "apr-"* -type f -exec basename {} \; | head -n 1`

# APR
mkdir -p ${BUILDROOT}/apr
tar xvfz ${SRC_DIR}/${APR_SW} --strip 1 -C ${BUILDROOT}/apr
cd ${BUILDROOT}/apr

if [ $XOSTYPE == "Linux" ]; then
	./configure --prefix=${MP_APR_DIR}
else
	CFLAGS='-arch x86_64' ./configure --prefix=${MP_APR_DIR}
fi

make
make install

# ------------------
# Build Tomcat Native Library
# ------------------
cd ${MPSERVERBASE}/apache-tomcat/bin
tar -xvzf tomcat-native.tar.gz
TCATNATIVE=`find ${MPSERVERBASE}/apache-tomcat/bin -type d -name "tomcat-native*"`
if [ -z "$TCATNATIVE" ]; then
	echo "Unable to get tomcat native dir in ${MPSERVERBASE}/apache-tomcat/bin"
	exit 1;
fi
if [ -d "${TCATNATIVE}/jni/native" ]; then
	cd ${TCATNATIVE}/jni/native
else
	echo "${TCATNATIVE}/jni/native not found"
	exit 1;
fi	

# Compile Tomcat Native Lib
if [ $XOSTYPE == "Linux" ]; then
	./configure --with-apr=${MP_APR_DIR} --with-ssl=${MP_OSSL_DIR} \
	--with-java-home=${JHOME}
else
	CFLAGS='-arch x86_64' ./configure --with-apr=${MP_APR_DIR} \
	--with-ssl=${MP_OSSL_DIR} \
	--with-java-home=${JHOME}
fi

make
mkdir -p ${MPSERVERBASE}/lib/java

if [ $XOSTYPE == "Linux" ]; then
	cp .libs/libtcnative-*.so ${MPSERVERBASE}/lib/java
	cd ${MPSERVERBASE}/lib/java
	ln -sfhv libtcnative-1.so libtcnative-1.jnilib
else
	cp .libs/libtcnative-*.dylib ${MPSERVERBASE}/lib/java
	cd ${MPSERVERBASE}/lib/java
	ln -sfhv libtcnative-1.dylib libtcnative-1.jnilib
fi

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
cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/conf/app/.proxy/WEB-INF/lib/systemcommand.jar"
chmod -R 0775 "${MPSERVERBASE}/conf/app/.proxy"
chown -R $OWNERGRP "${MPSERVERBASE}/conf/app/.proxy"
jar cf "${MPSERVERBASE}/conf/app/war/proxy/ROOT.war" -C "${MPSERVERBASE}/conf/app/.proxy" .

# Tomcat Config
MPCONF="${MPSERVERBASE}/conf/tomcat/proxy"
MPTOMCAT="${MPSERVERBASE}/apache-tomcat"
cp "${MPSERVERBASE}/conf/app/war/proxy/ROOT.war" "${MPTOMCAT}/webapps"
cp "${MPCONF}/bin/setenv.sh" "${MPTOMCAT}/bin/setenv.sh"
cp "${MPCONF}/bin/launchdTomcat.sh" "${MPTOMCAT}/bin/launchdTomcat.sh"
cp -r "${MPCONF}/conf/Catalina" "${MPTOMCAT}/conf/"
cp -r "${MPCONF}/conf/server.xml" "${MPTOMCAT}/conf/server.xml"
cp -r "${MPCONF}/conf/web.xml" "${MPTOMCAT}/conf/web.xml"
chmod -R 0775 "${MPTOMCAT}"
chown -R $OWNERGRP "${MPTOMCAT}"

# Set Permissions
if $USEMACOS; then
	chown -R $OWNERGRP ${MPSERVERBASE}/Logs
	chmod 0775 ${MPSERVERBASE}
	chown root:wheel ${MPSERVERBASE}/conf/LaunchDaemons/*.plist
	chmod 0644 ${MPSERVERBASE}/conf/LaunchDaemons/*.plist
fi

# ------------------------------------
# Install Python Packages
# ------------------------------------
if [ -f "/usr/bin/easy_install" ]; then
	${MPSERVERBASE}/conf/scripts/InstallPyMods.sh
fi

# ------------------------------------------------------------
# Generate self signed certificates
# ------------------------------------------------------------
clear
echo
echo "Creating self signed SSL certificate"
echo
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

cd /Library/MacPatch/Server/conf/apacheCerts
OPTS=(/C="$COUNTRY"/ST="$STATE"/L="$LOCATION"/O="$ORG"/OU="$USER"/CN="$DOMAIN"/emailAddress="$EMAIL")
COMMAND=(openssl req -new -sha256 -x509 -nodes -days 999 -subj "${OPTS[@]}" -newkey rsa:2048 -keyout server.key -out server.crt)

"${COMMAND[@]}"
if (( $? )) ; then
    echo -e "ERROR: Something went wrong!"
    exit 1
else
	echo "Done!"
	echo
	echo "NOTE: It's strongly recommended that an actual signed certificate be installed"
	echo "if running in a production environment."
	echo
fi

# ------------------
# Clean up structure place holders
# ------------------
find ${MPSERVERBASE} -name ".mpRM" -print | xargs -I{} rm -rf {}

# ------------------
# Set Permissions
# ------------------
echo "Setting Permissions..."
/Library/MacPatch/Server/conf/scripts/Permissions.sh
