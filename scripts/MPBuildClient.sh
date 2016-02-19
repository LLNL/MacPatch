#!/bin/bash
#
# -------------------------------------------------------------
# Script: MPBuildClient.sh
# Version: 1.2
#
# Description:
# This is a very simple script to demonstrate how to automate
# the build process of the MacPatch Agent.
#
# Info:
# Simply modify the GITROOT and BUILDROOT variables also
# please set the component package version numbers as well.
#
# History:
#	1.1		Added Code Signbing Support
#   1.2		Added ability to save CODESIGNIDENTITY
#
# -------------------------------------------------------------

GITROOT="/Library/MacPatch/tmp/MacPatch"
BUILDROOT="/Library/MacPatch/tmp/Client"
BASEPKGVER="2.7.0.0"
UPDTPKGVER="2.7.0.0"
CODESIGNIDENTITY="*"
CODESIGNIDENTITYPLIST="/Library/Preferences/mp.build.client.plist"
if [ -f "$CODESIGNIDENTITYPLIST" ]; then
	CODESIGNIDENTITYALT=`defaults read ${CODESIGNIDENTITYPLIST} name`
fi

if [ -d "$BUILDROOT" ]; then
	rm -rf ${BUILDROOT}
else
	mkdir -p ${BUILDROOT}	
fi	
echo "A valid code siginging identidy is required."
read -p "Would you like to code sign all binaries (Y/N)? [N]: " SIGNCODE
SIGNCODE=${SIGNCODE:-N}

if [ "$SIGNCODE" == "n" ] || [ "$SIGNCODE" == "N" ] || [ "$SIGNCODE" == "y" ] || [ "$SIGNCODE" == "Y" ]; then

	if [ "$SIGNCODE" == "y" ] || [ "$SIGNCODE" == "Y" ] ; then
		# Compile the agent components
		read -p "Please enter your code sigining identity [$CODESIGNIDENTITYALT]: " CODESIGNIDENTITY
		CODESIGNIDENTITY=${CODESIGNIDENTITY:-$CODESIGNIDENTITYALT}
		if [ "$CODESIGNIDENTITY" != "$CODESIGNIDENTITYALT" ]; then
			defaults write ${CODESIGNIDENTITYPLIST} name "${CODESIGNIDENTITY}"
		fi
		
		#if [ "${CODESIGNIDENTITY}" == "*" ]; then
		#	read -p "Please enter you code sigining identity: " CODESIGNIDENTITY
		#fi
		xcodebuild clean build -configuration Release -project ${GITROOT}/MacPatch/MacPatch.xcodeproj -target AGENT_BUILD SYMROOT=${BUILDROOT} CODE_SIGN_IDENTITY="${CODESIGNIDENTITY}"
	else
		# Compile the agent components
		xcodebuild clean build -configuration Release -project ${GITROOT}/MacPatch/MacPatch.xcodeproj -target AGENT_BUILD SYMROOT=${BUILDROOT}
	fi
else
	echo "Invalid entry, now exiting."
	exit 1
fi

# Remove the build and symbol files
find ${BUILDROOT} -name "*.build" -print | xargs -I{} rm -rf {}
find ${BUILDROOT} -name "*.dSYM" -print | xargs -I{} rm -rf {}

# Remove the static library and header files
rm ${BUILDROOT}/Release/libMacPatch.a
rm ${BUILDROOT}/Release/libcrypto.a
rm ${BUILDROOT}/Release/libssl.a
rm -r ${BUILDROOT}/Release/usr

cp -R ${GITROOT}/MacPatch\ PKG/Base ${BUILDROOT}
cp -R ${GITROOT}/MacPatch\ PKG/Updater ${BUILDROOT}
cp -R ${GITROOT}/MacPatch\ PKG/Combined ${BUILDROOT}

mv ${BUILDROOT}/Release/ccusr ${BUILDROOT}/Base/Scripts/ccusr
mv ${BUILDROOT}/Release/MPPrefMigrate ${BUILDROOT}/Base/Scripts/MPPrefMigrate
mv ${BUILDROOT}/Release/MPAgentUp2Date ${BUILDROOT}/Updater/Files/Library/MacPatch/Updater/
mv ${BUILDROOT}/Release/MPLoginAgent.app ${BUILDROOT}/Base/Files/Library/PrivilegedHelperTools/
cp -R ${BUILDROOT}/Release/* ${BUILDROOT}/Base/Files/Library/MacPatch/Client/

# Find and remove .mpRM files, these are here as place holders so that GIT will keep the
# directory structure
find ${BUILDROOT} -name ".mpRM" -print | xargs -I{} rm -rf {}

# Remove the compiled Release directory now that all of the files have been copied
rm -r ${BUILDROOT}/Release

mkdir ${BUILDROOT}/Combined/Packages

# Create the Base Agent pkg
pkgbuild --root ${BUILDROOT}/Base/Files/Library \
--component-plist ${BUILDROOT}/Base/Components.plist \
--identifier gov.llnl.mp.agent.base \
--install-location /Library \
--scripts ${BUILDROOT}/Base/Scripts \
--version $BASEPKGVER \
${BUILDROOT}/Combined/Packages/Base.pkg

# Create the Updater pkg
pkgbuild --root ${BUILDROOT}/Updater/Files/Library \
--identifier gov.llnl.mp.agent.updater \
--install-location /Library \
--scripts ${BUILDROOT}/Updater/Scripts \
--version $UPDTPKGVER \
${BUILDROOT}/Combined/Packages/Updater.pkg

# Create the almost final package
productbuild --distribution ${BUILDROOT}/Combined/Distribution \
--resources ${BUILDROOT}/Combined/Resources \
--package-path ${BUILDROOT}/Combined/Packages \
${BUILDROOT}/Combined/MPClientInstall.pkg

# Expand the newly created package so we can add the nessasary files
pkgutil --expand ${BUILDROOT}/Combined/MPClientInstall.pkg ${BUILDROOT}/Combined/.MPClientInstall

# Backup Original Package
mv ${BUILDROOT}/Combined/MPClientInstall.pkg ${BUILDROOT}/Combined/.MPClientInstall.pkg

# Copy MacPatch Package Info file for the web service
cp ${BUILDROOT}/Combined/Resources/mpInfo.ini ${BUILDROOT}/Combined/.MPClientInstall/Resources/mpInfo.ini
cp ${BUILDROOT}/Combined/Resources/mpInfo.plist ${BUILDROOT}/Combined/.MPClientInstall/Resources/mpInfo.plist

# Re-compress expanded package
pkgutil --flatten ${BUILDROOT}/Combined/.MPClientInstall ${BUILDROOT}/Combined/MPClientInstall.pkg

# Clean Up 
rm -rf ${BUILDROOT}/Combined/.MPClientInstall
#rm -rf ${BUILDROOT}/Combined/.MPClientInstall.pkg

# Compress for upload
ditto -c -k ${BUILDROOT}/Combined/MPClientInstall.pkg ${BUILDROOT}/Combined/MPClientInstall.pkg.zip