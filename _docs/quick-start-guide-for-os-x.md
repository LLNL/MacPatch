---
layout: default
title: "Quick Start Guide for OS X"
---

# MacPatch Server Quick Start Guide for OS X


This is a quick start guide to getting MacPatch version 2.8.x installed and running on a Mac OS X based system. For the purpose of this guide we will be installing on a Mac OS X 10.9.x system.

## Table of Contents

* [Required Software](#a1)
	* [Java](#a1a)
	* [Xcode](#a1b)
	* [Python](#a1c)
* [Download and Build](#a2) 
* [MySQL Database](#a3)
* [Server Setup](#a4)
* [Download and Add Patch Content](#a5)
* [Console Configuration ](#a6)


<a name='a1'></a>

## Required Software

There are two prerequisites to installing the MacPatch server software. Java 8 and Xcode command line tools need to be installed.

<a name='a1a'></a>

### Java

Java can be downloaded from Oracle at [http://www.oracle.com/technetwork/java/javase/downloads/index.html](http://www.oracle.com/technetwork/java/javase/downloads/index.html).

<!-- 
Java 7 (JDK) is recommended. Java 8 has not been tested at this time. Once the Java 7 JDK has been installed the "Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files 7" are needed as well. These files can be found on the same location.
-->

<a name='a1b'></a>

### Xcode

Xcode is required to build the MacPatch software for Mac OS X. While you can install the GUI version of Xcode and download and install the command line tools from within Xcode. You will be installing the Xcode command line tools from the Terminal.app.

Test for Xcode

	% xcode-select --version

If you get back a version they are installed .

Install Xcode

	% xcode-select --install

<a name='a1c'></a>

### PIP (Python Modules)

The server build script will install the python modules needed.
	
	pip, argparse, mysql-connector-python, requests, biplist, wheel

<a name='a2'></a>

## Download and build the Server software
To download and build the MacPatch server software is just a few Terminal commands. Run the following commands to build and install the software.

	sudo mkdir -p /Library/MacPatch/tmp
	cd /Library/MacPatch/tmp
	sudo git clone https://github.com/SMSG-MAC-DEV/MacPatch.git
	sudo /Library/MacPatch/tmp/MacPatch/scripts/MPBuildServer.sh
	
Note: if you get a Error message `error: server certificate verification failed...` on the git clone, a simple fix is to allow the cert using `export GIT_SSL_NO_VERIFY=1`
    
Once the compile and copy process is completed, the MacPatch server software is now installed and ready to be configured.

<a name='a3'></a>

## MySQL Database 

MacPatch requires the use of MySQL database. The database can be installed on the first server built or it can be installed on a separate host. MySQL version 5.5.x or higher is required. MySQL 5.6.x is recommended due to it's performance enhancements. Also, the MySQL InnoDB engine is required.

#### Setup MacPatch MySQL Database

Run the following script via the Terminal.app. You will need to know the MySQL root user password.
	
	% /Library/MacPatch/Server/conf/scripts/MPDBSetup.sh

<a name='a4'></a>     

## Setup MacPatch Server

The MacPatch server has five configuration script and should be run in the given order. The scripts are located on the server in `/Library/MacPatch/Server/conf/scripts/Setup/`.

Script	| Description | Server | Required
---|---|---|---
DataBaseLDAPSetup.py | The database setup is required for MacPatch to function. | All | Required
SymantecAntivirusSetup.py | MacPatch supports patching Symantec Antivirus definitions. Not all sites use SAV/SEP so this step is optional. | Master | Optional
StartServices.py | This script will add nessasary startup scripts and start and stop the MacPatch services.<ul><li>Setup Services: StartServices.py --setup</li><li>Start All Services: StartServices.py --load All</li><li>Stop All Services - StartServices.py --unload All</li></lu> | Master, Distribution | Required

<a name='a5'></a> 
## Download and Add Patch Content
#### Apple Updates
Apple patch content will download eventually on it's own cycle, but for the first time it's recommended to download it manually.

The Apple Software Update content settings are stored in a plist file (/Library/MacPatch/Server/conf/etc/gov.llnl.mp.patchloader.plist). By default Apple patches for 10.7 through 10.10 will be processed and supported. 

Run the following command via the Terminal.app on the Master MacPatch server.

	sudo -u _appserver /Library/MacPatch/Server/conf/scripts/MPSUSPatchSync.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mp.patchloader.plist
	
### Custom Patches
To create your own custom patch content please read the "Custom Patch Content" [docs](https://macpatch.github.io/doc/custom-patch-content.html).

To use "AutoPkg" to add patch content please read the "AutoPkg patch content" [docs](https://macpatch.github.io/doc/autopkg-patch-content.html).	 
    
#### Symantec AntiVirus Defs
If you have elected to deploy Symantec AntiVirus definitions via MacPatch then it's also recommended that you download the content manually for the first time.

	sudo -u _appserver /Library/MacPatch/Server/conf/scripts/MPAVDefsSync.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mpavdl.plist

<a name='a6'></a>    
## Configure MacPatch - Admin Console
Now that the MacPatch server is up and running, you will need to configure the environment.

### First Login
The default user name is "mpadmin" and the password is "\*mpadmin\*". You will need to login for the first time with this account to do all of the setup tasks. Once these tasks are completed it's recommended that this accounts password be changed. This can be done by editing the siteconfig.json file, which is located in /Library/MacPatch/Server/conf/etc/.

### Default Configuration
#### MacPatch Server Info
Each MacPatch server needs to be added to the environment. The master server is always added automatically. 

It is recommended that you login and verify the master server settings. It is common during install that the master server address will be added as localhost or 127.0.0.1. Please make sure that the correct hostname or IP address is set.

* Go to "Admin-> Server -> MacPatch Servers"
* Click the "Plus" button to add a new server

Example data for Master server:

* Server: server1.macpatch.com
* Port: 2600
* Use SSL: Yes
* Use SSL Auth: NO (Not Supported Yet)
* Allow Self-Signed Cert: Yes
* Is Master: Yes
* Is Proxy: No
* Active: Yes

####Create Default Patch Group

A default patch group will be created during install. The name of the default patch group is "Default". You may use it or create a new one.

To edit the contents for the patch group simply click the "Pencil" icon next to the group name. To add patches click the check boxes to add or subtract patches from the group. When done click the "**Save**" icon. (**Important Step**)

**Please note:** Only production patches will be visible to a production group.

### Client Agent Configuration
A default agent configuration is added during the install. Please verify the client agent configuration before the client agent is uploaded. 

**Recommended**

* Go to "Admin -> Client Agents -> Configure"
* Set the following 3 properties to be enforced
	* MPServerAddress
	* MPServerPort
	* MPServerSSL
* Verify the "**PatchGroup**" setting. If you have changed it set it before you upload the client agent.
* Click the save button
* Click the icon in the "Default" column for the default configuration. (Important Step)

Only the default agent configuration will get added to the client agent upon upload.


#### Upload the Client Agent
To upload a client agent you will need to build the client first. Please follow the Building the Client document before continuing.

* Go to "Admin-> Client Agents -> Deploy"
* Download the "MacPatch Agent Uploader"
* Double Click the "Agent Uploader.app"
	* Enter the MacPatch Server
	* Choose the agent package (e.g. MPClientInstall.pkg.zip)
	* Click "Upload" button
