---
layout: default
title: "Install Distribution Server"
---

# MacPatch - Install Distribution Server
---

When the first server ("Master") is compiled and built it will create a file called `MacPatch_Server.zip` in `/Library/MacPatch`. This zip file is a complete copy of the master server build in a unconfigured state. Simply copy the `MacPatch_Server.zip` to your new distribution server.

## Table of Contents
* [Required Software](#a1)
* [Download and Build](#a2) 
* [Server Setup](#a3)
* [Console Configuration](#a4)

<a name='a1'></a>   
## Requirements

- Mac OS X 10.9.x or higher
- Linux Distributions: RHEL 7, Fedora 20 or higher, Ubuntu 14 or higher
- 8 Gig or RAM or higher
- 200 or more Gig of disk space, number of patches and software items will determin size
- Java 1.8 JDK
- Python 2.7.x

<a name='a2'></a>    
## Download and build the Server software 
To download and build the MacPatch server software is just a few Terminal commands. Run the following commands to build and install the software.

	sudo mkdir -p /Library/MacPatch/tmp
	cd /Library/MacPatch/tmp
	sudo git clone https://github.com/SMSG-MAC-DEV/MacPatch.git
	sudo /Library/MacPatch/tmp/MacPatch/scripts/MPBuildServer.sh
    
Note: if you get a Error message `error: server certificate verification failed...` on the git clone, a simple fix is to allow the cert using `export GIT_SSL_NO_VERIFY=1`

Once the compile and copy process is completed, the MacPatch server software is now installed and ready to be configured.


<a name='a2'></a>
## Server Setup 

The MacPatch server has a couple of configuration scripts, and they should be run in the given order. The scripts are located on the server in `/Library/MacPatch/Server/conf/scripts/Setup/`.

Script	| Description | Server | Required
---|---|---|---
DataBaseLDAPSetup.py | The database setup is required for MacPatch to function. | All | Required
StartServices.py | This script will add nessasary startup scripts and start and stop the MacPatch services.<ul><li>Setup Services: StartServices.py --setup</li><li>Start All Services: StartServices.py --load All</li><li>Stop All Services - StartServices.py --unload All</li></lu> | Master, Distribution | Required

	
<a name='a2'></a>  	
## Console Configuration 
Add the server(s) via the Admin console

Login to the MacPatch admin console with a admin account and go to "Admin->Server->MacPatch Server" and add the new server.