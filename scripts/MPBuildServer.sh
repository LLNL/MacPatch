#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildServer.sh
# Version: 2.0.3
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
# 1.6.5:	More ubuntu updates
# 2.0.0:	Apache HTTPD removed
#			Single Tomcat Instance, supports webservices and console
# 2.0.1:	Updated java version check
# 2.0.2:	Updated linux package requirements
# 2.0.3:	Added Mac PKG support
#
# -------------------------------------------------------------

# -------------------------------------------------------------
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
# -------------------------------------------------------------

MPBASE="/Library/MacPatch"
MPSERVERBASE="/Library/MacPatch/Server"
GITROOT="/Library/MacPatch/tmp/MacPatch"
BUILDROOT="/Library/MacPatch/tmp/build/Server"
SRC_DIR="${MPSERVERBASE}/conf/src"
J2EE_SW=`find "${GITROOT}/MacPatch Server" -name "apache-tomcat-"* -type f -exec basename {} \; | head -n 1`

# PKG Variables
MP_MAC_PKG=false
MP_SERVER_PKG_VER="1.2.0.0"
CODESIGNIDENTITY="*"
CODESIGNIDENTITYPLIST="/Library/Preferences/mp.build.server.plist"
if [ -f "$CODESIGNIDENTITYPLIST" ]; then
	CODESIGNIDENTITYALT=`defaults read ${CODESIGNIDENTITYPLIST} name`
fi

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

usage() { echo "Usage: $0 [-p Build Mac PKG]" 1>&2; exit 1; }

while getopts "ph" opt; do
	case $opt in
		p)
			MP_MAC_PKG=true
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
echo "Begin MacPatch Server build."


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


# ------------------
# Link & Set Permissions
# ------------------
ln -s ${MPSERVERBASE}/conf/Content/Doc ${MPBASE}/Content/Doc
chown -R $OWNERGRP ${MPSERVERBASE}

mkdir -p ${MPSERVERBASE}/apache-tomcat/InvData/Files
mkdir -p ${MPSERVERBASE}/apache-tomcat/InvData/Errors
mkdir -p ${MPSERVERBASE}/apache-tomcat/InvData/Processed

# Web Services - App
mkdir -p "${MPSERVERBASE}/conf/app/war/wsl"
mkdir -p "${MPSERVERBASE}/conf/app/.wsl"
unzip "${MPSERVERBASE}/conf/src/openbd/openbd.war" -d "${MPSERVERBASE}/conf/app/.wsl"
rm -rf "${MPSERVERBASE}/conf/app/.wsl/index.cfm"
rm -rf "${MPSERVERBASE}/conf/app/.wsl/manual"
cp -r "${MPSERVERBASE}"/conf/app/wsl/* "${MPSERVERBASE}"/conf/app/.wsl
cp -r "${MPSERVERBASE}"/conf/app/mods/wsl/* "${MPSERVERBASE}"/conf/app/.wsl

cp -r "${MPSERVERBASE}/conf/lib/systemcommand.jar" "${MPSERVERBASE}/conf/app/.wsl/WEB-INF/lib/systemcommand.jar"
chmod -R 0775 "${MPSERVERBASE}/conf/app/.wsl"
chown -R $OWNERGRP "${MPSERVERBASE}/conf/app/.wsl"
jar cf "${MPSERVERBASE}/conf/app/war/wsl/mpws.war" -C "${MPSERVERBASE}/conf/app/.wsl" .

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
jar cf "${MPSERVERBASE}/conf/app/war/site/console.war" -C "${MPSERVERBASE}/conf/app/.site" .

# Tomcat Config
MPCONF="${MPSERVERBASE}/conf/tomcat/server"
MPTOMCAT="${MPSERVERBASE}/apache-tomcat"
cp "${MPSERVERBASE}/conf/app/war/wsl/mpws.war" "${MPTOMCAT}/webapps"
cp "${MPSERVERBASE}/conf/app/war/site/console.war" "${MPTOMCAT}/webapps"
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

# ------------------------------------
# Build MP Server Admin for Mac OS X
# ------------------------------------
if $USEMACOS; then
	if [ -d "${GITROOT}/MacPatch/MacPatch.xcodeproj" ]; then
		clear
		echo "MPServerAdmin requires code signing."
		echo "Hint: (Mac Developer: ...)"
		read -p "Please enter your code sigining identity: " xcodeCODESIGNIDENTITY

		xcodebuild clean build -configuration Release -project ${GITROOT}/MacPatch\ Admin\ Tools/MPServerAdmin/MPServerAdmin.xcodeproj -target "gov.llnl.mp.admin.helper" SYMROOT=${BUILDROOT} CODE_SIGN_IDENTITY="${xcodeCODESIGNIDENTITY}"
		xcodebuild clean build -configuration Release -project ${GITROOT}/MacPatch\ Admin\ Tools/MPServerAdmin/MPServerAdmin.xcodeproj -target "MPServerAdmin" SYMROOT=${BUILDROOT} CODE_SIGN_IDENTITY="${xcodeCODESIGNIDENTITY}"
		ditto -c -k --keepParent ${BUILDROOT}/Release/MPServerAdmin.app ${BUILDROOT}/Release/MPServerAdmin.app.zip
		cp ${BUILDROOT}/Release/MPServerAdmin.app.zip ${MPSERVERBASE}/conf/bin/MPServerAdmin.app.zip 
	fi
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

# ------------------------------------------------------------
# Firewall TCP port redirect 8443 to 443, 8080 to 80
# ------------------------------------------------------------
if $USELINUX; then
	if $USERHEL; then
		echo "Setup Redhat port forwarding..."
	fi
	if $USEUBUNTU; then
		echo "Setup Ubuntu port forwarding..."
	fi
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
clear

# ------------------
# Set Permissions
# ------------------
echo "Setting Permissions..."
/Library/MacPatch/Server/conf/scripts/Permissions.sh

# ------------------
# Currently a Java 8 requirement
# Detect and warn 
# ------------------

if $USELINUX; then
	JAVA_VER_RAW=`java -version 2>&1`
	VERSION=`expr "$JAVA_VER_RAW" : '.*"\(1.[0-9\.]*\)["_]'`
	let VERMINOR=`echo "$VERSION" | awk -F. '{print $2}'`

	if [ $VERMINOR -le 7 ]; then
		echo
		echo "The version of Java installed is $VERSION"
		echo "MacPatch has a minimum Java requirement of Java 1.8."
		echo "Please upgrade or switch your default version of Java."
		echo
	fi	
fi

# ------------------------------------------------------------
# Create Mac OS X, MacPatch Server PKG
# ------------------------------------------------------------
if $MP_MAC_PKG; then
	clear
	echo "Begin creating MacPatch Server PKG for Mac OS X..."
	echo
	echo
	# ------------------
	# Clean up, pre package
	# ------------------
	rm -rf "${MPSERVERBASE}/conf/app/.site"
	rm -rf "${MPSERVERBASE}/conf/app/.wsl"
	find "${MPSERVERBASE}/conf/src" -name apache-tomcat-* -print | xargs -I{} rm {}
	find "${MPSERVERBASE}/conf/src" -name apr* -print | xargs -I{} rm {}
	rm -rf "${MPSERVERBASE}/conf/src/openbd"
	rm -rf "${MPSERVERBASE}/conf/src/linux"
	rm -rf "${MPSERVERBASE}/conf/init"
	rm -rf "${MPSERVERBASE}/conf/init.d"
	rm -rf "${MPSERVERBASE}/conf/systemd"
	rm -rf "${MPSERVERBASE}/conf/tomcat"

	# ------------------
	# Move Files For Packaging
	# ------------------
	PKG_FILES_ROOT_MP="${BUILDROOT}/Server/Files/Library/MacPatch"

	cp -R ${GITROOT}/MacPatch\ PKG/Server ${BUILDROOT}

	mv "${MPSERVERBASE}" "${PKG_FILES_ROOT_MP}/"
	mv "${MPBASE}/Content" "${PKG_FILES_ROOT_MP}/"

	# ------------------
	# Clean up structure place holders
	# ------------------
	echo "Clean up place holder files"
	find ${PKG_FILES_ROOT_MP} -name ".mpRM" -print | xargs -I{} rm -rf {}

	# ------------------
	# Create the Server pkg
	# ------------------
	mkdir -p "${BUILDROOT}/PKG"

	# Create Server base package
	echo "Create Server base package"
	pkgbuild --root "${BUILDROOT}/Server/Files/Library" \
	--identifier gov.llnl.mp.server \
	--install-location /Library \
	--scripts ${BUILDROOT}/Server/Scripts \
	--version $MP_SERVER_PKG_VER \
	${BUILDROOT}/PKG/Server.pkg

	# Create the final package with scripts and resources
	echo "Run product build on MPServer.pkg"
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

		read -p "Please enter you sigining identity [$CODESIGNIDENTITYALT]: " CODESIGNIDENTITY
		CODESIGNIDENTITY=${CODESIGNIDENTITY:-$CODESIGNIDENTITYALT}
		if [ "$CODESIGNIDENTITY" != "$CODESIGNIDENTITYALT" ]; then
			defaults write ${CODESIGNIDENTITYPLIST} name "${CODESIGNIDENTITY}"
		fi

		echo
		echo  "Signing package..."
		/usr/bin/productsign --sign "${CODESIGNIDENTITY}" ${BUILDROOT}/PKG/_MPServer.pkg ${BUILDROOT}/PKG/MPServer.pkg
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

	else
		mv ${BUILDROOT}/PKG/_MPServer.pkg ${BUILDROOT}/PKG/MPServer.pkg
	fi

	# Clean up the base package
	rm ${BUILDROOT}/PKG/Server.pkg

	# Open the build package dir
	open ${BUILDROOT}/PKG
fi
