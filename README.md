#![MPLogo](Images/MPLogo_64x64.png "MPLogo") MacPatch

## Overview
MacPatch simplifies the act of patching and installing software on Mac OS X based systems. The client relies on using the built-in software update application for patching the Mac OS X system updates and it's own scan and patch engine for custom patches. 

MacPatch offers features and functionality that provide Mac OS X administrators with best possible patching solution to meet the challenges of supporting Mac OS X in the enterprise today.

## Features

* Apple Software update server support
* Custom patch creation
* Custom patch groups
* Patch baselines
* Client reboot notification
* Inventory Collection
* Basic Reporting
* End-User Self Patch
* Software Catalog

## Version 2.5.0

###What's New

* Power managment
* Mac OS X Profiles support
* More Inventory
* New Web Admin Console
* Linux Server Support

## System Requirements

###Client
* Mac OS X Intel 32 & 64bit.  
* Mac OS X 10.7.0 and higher.

#####Server Requirements:
* Mac OS X or Mac OS X Server 10.7 or higher 
* Linux Fedora & Unbuntu
* Using Intel Hardware, PPC is not supported
* 4 GB of RAM, 8 GB is recommended
* Java v1.6 or higher
* MySQL version 5.1 or higher, MySQL 5.6.x is recommended.

######*JAVA 7 Issue* 

If your using JAVA 1.7, Oracle did not include the "Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files 7". Apparently they are needed for any stronger keys then 128-bit keys. You can get the Unlimited Strength bundles from the Oracle site ([http://www.oracle.com/technetwork/java/javase/downloads/index.html](http://www.oracle.com/technetwork/java/javase/downloads/index.html)). 
Installing them is as “simple” as dumping them to the "/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home/jre/lib/security/" directory.

#####Server (TCP) Ports Used:


######Default
80, 443, 2600, 3601, 4601
######Configurable
2600, 3601, 4601


## Install and Setup
To get MacPatch up and running first clone the project and review the "MacPatch – Server Install.pdf" file in the docs folder.

```
mkdir -p /Library/MacPatch/tmp
cd /Library/MacPatch/tmp
git clone https://github.com/SMSG-MAC-DEV/MacPatch.git 

```

## License

MacPatch is available under the GNU GPLv2 license. See the [LICENSE](LICENSE "License") file for more info.
