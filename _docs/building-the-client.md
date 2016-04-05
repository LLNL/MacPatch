---
layout: default
title: "Building the Client"
---

# MacPatch - Building the Client
---

The MacPatch client agent needs to be build on a Mac OS X system running Mac OS X 10.7 or higher. You will also need to upload the finished agent from a Mac OS X system using the `Agent Uploader.app`.

## Required Software
Xcode is the only required software to build the client agent.

### Xcode
Xcode is required to build the MacPatch software for Mac OS X.

**Test for Xcode**

	% xcode-select --version

If you get back a version they are installed.

**Install Xcode**

	% xcode-select --install

**Install Xcode from App Store**

## Download and build the agent
To download and build the MacPatch client agent software there are just a couple of Terminal commands to run.

	sudo mkdir -p /Library/MacPatch/tmp
	cd /Library/MacPatch/tmp
	sudo git clone https://github.com/SMSG-MAC-DEV/MacPatch.git
	sudo /Library/MacPatch/tmp/MacPatch/scripts/MPBuildClient.sh
	
Once the compile and copy process is completed the finished client agent software can be found in `/Library/MacPatch/tmp/Client/Combined/MPClientInstall.pkg.zip`

### Changing Agent Version Info

If you need to update the agent version because you have updated the MacPatch code or just want to test the client update feature you will need to update the `/Library/MacPatch/tmp/MacPatch/MacPatch PKG/Combined/Resources/mpInfo.plist` file. The easiest way to do so is to increment the `build` number.
