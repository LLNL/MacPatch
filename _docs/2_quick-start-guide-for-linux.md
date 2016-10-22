---
layout: default
title: "Quick Start Guide for Linux"
---

# MacPatch Server Quick Start Guide for Linux
---

This is a quick start guide to getting MacPatch version 2.8.x installed and running on a Linux based system running Ubuntu or Fedora (RedHat).

Please note, this has been tested on Ubuntu 12.10, Fedora 20, Fedora 21. RHEL 7 is supported but previous versions are not.

## Table of Contents
* [Required Software](#required-software)
	* [Ubuntu](#ubuntu)
	* [Fedora / RHEL](#fedora--redhat-enterprise-linux)
	* [Python](#pip-python-modules)
* [Download and Build](#download-and-build-the-server-software)
* [MySQL Database](#mysql-database)
* [Server Setup](#setup-macpatch-server)
* [Download and Add Patch Content](#download-and-add-patch-content)
* [Console Configuration ](#configure-macpatch---admin-console)

## Required Software
There are a couple of prerequisites to installing the MacPatch server software on Linux. The following packages and Python modules need to be installed. Your welcome to install them before hand or the MPBuildServer.sh script will install the nessasary packages.

**Please Note: JAVA 1.8 is required, please check your version of Linux to make sure you can install it before continuing.**

### Ubuntu

##### Packages
	build-essential, git, openjdk-8-jdk, python-pip

### Fedora / RedHat Enterprise Linux

##### Packages
	gcc-c++, git, java-1.8.0-openjdk-devel, python-pip

#### PIP (Python Modules)
All python modules will be installed during the build script.

	argparse, mysql-connector-python, requests, biplist, wheel, python-crontab

## Download and build the Server software
To download and build the MacPatch server software is just a few Terminal commands. Run the following commands to build and install the software.

	sudo mkdir -p /Library/MacPatch/tmp
	cd /Library/MacPatch/tmp
	sudo git clone https://github.com/LLNL/MacPatch.git
	sudo /Library/MacPatch/tmp/MacPatch/scripts/MPBuildServer.sh

Note: if you get a Error message `error: server certificate verification failed...` on the git clone, a simple fix is to allow the cert using `export GIT_SSL_NO_VERIFY=1`

Once the compile and copy process is completed, the MacPatch server software is now installed and ready to be configured.

## MySQL Database
MacPatch requires the use of MySQL database. The database can be installed on the first server built or it can be installed on a separate host. MySQL version 5.5.x or higher is required. MySQL 5.6.x is recommended due to it's performance enhancements. Also, the MySQL InnoDB engine is required.

#### Setup MacPatch MySQL Database
Run the following script via the Terminal.app. You will need to know the MySQL root user password.

	% /Library/MacPatch/Server/conf/scripts/MPDBSetup.sh

## Setup MacPatch Server
The MacPatch server has a couple of configuration scripts, and they should be run in the given order. The scripts are located on the server in `/Library/MacPatch/Server/conf/scripts/Setup/`.

Script | Description | Server | Required
---|---|---|---
DataBaseLDAPSetup.py | The database setup is required for MacPatch to function. | All | Required
SymantecAntivirusSetup.py | MacPatch supports patching Symantec Antivirus definitions. Not all sites use SAV/SEP so this step is optional. | Master | Optional
StartServices.py | This script will add nessasary startup scripts and start and stop the MacPatch services.<br> --- Setup Services: StartServices.py --setup<br> --- Start All Services: StartServices.py --load All<br> --- Stop All Services - StartServices.py --unload All | Master, Distribution | Required

## Download and Add Patch Content

### Apple Updates
Apple patch content will download eventually on it's own cycle, but for the first time it's recommended to download it manually.

The Apple Software Update content settings are stored in a plist file (/Library/MacPatch/Server/conf/etc/gov.llnl.mp.patchloader.plist). By default Apple patches for 10.7 through 10.10 will be processed and supported.

Run the following command via the Terminal.app on the Master MacPatch server.

	sudo -u www-data /Library/MacPatch/Server/conf/scripts/MPSUSPatchSync.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mp.patchloader.plist

### Custom Patches
To create your own custom patch content please read the "Custom Patch Content" [docs](https://macpatch.github.io/doc/custom-patch-content.html).

To use "AutoPkg" to add patch content please read the "AutoPkg patch content" [docs](https://macpatch.github.io/doc/autopkg-patch-content.html).	 

#### Symantec AntiVirus Defs
If you have elected to deploy Symantec AntiVirus definitions via MacPatch then it's also recommended that you download the content manually for the first time.

	sudo -u www-data /Library/MacPatch/Server/conf/scripts/MPAVDefsSync.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mpavdl.plist

## Configure MacPatch - Admin Console
Now that the MacPatch server is up and running, you will need to configure the environment.

### First Login
The default user name is "mpadmin" and the password is "\*mpadmin\*", Unless it was changed using the "DataBaseLDAPSetup.py" script. You will need to login for the first time with this account to do all of the setup tasks. Once these tasks are completed it's recommended that this accounts password be changed. This can be done by editing the siteconfig.json file, which is located in `/Library/MacPatch/Server/conf/etc/`.

### Default Configuration

#### MacPatch Server Info
Each MacPatch server needs to be added to the environment. The master server is always added automatically.

It is recommended that you login and verify the master server settings. It is common during install that the master server address will be added as localhost or 127.0.0.1. Please make sure that the correct hostname or IP address is set.

* Go to "Admin-> Server -> MacPatch Servers"
* Double Click the row with your server or single click the row and click the "Pencil" button.

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

### Upload the Client Agent
To upload a client agent you will need to build the client first. Please follow the Building the Client document before continuing.

* Go to "Admin-> Client Agents -> Deploy"
* Download the "MacPatch Agent Uploader"
* Double Click the "Agent Uploader.app"
	* Enter the MacPatch Server
	* Choose the agent package (e.g. MPClientInstall.pkg.zip)
	* Click "Upload" button
