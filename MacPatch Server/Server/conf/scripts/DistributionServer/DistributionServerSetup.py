#!/usr/bin/env python

'''
 Copyright (c) 2013, Lawrence Livermore National Security, LLC.
 Produced at the Lawrence Livermore National Laboratory (cf, DISCLAIMER).
 Written by Charles Heizer <heizer1 at llnl.gov>.
 LLNL-CODE-636469 All rights reserved.
 
 This file is part of MacPatch, a program for installing and patching
 software.
 
 MacPatch is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License (as published by the Free
 Software Foundation) version 2, dated June 1991.
 
 MacPatch is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the terms and conditions of the GNU General Public
 License for more details.
 
 You should have received a copy of the GNU General Public License along
 with MacPatch; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
'''

'''
  MacPatch Distribution Server Setup Script
  MacPatch Version 2.5.x
  
  Script Version 1.0.0
'''

import os
import plistlib
import platform

MP_SRV_BASE = "/Library/MacPatch/Server"
MP_SRV_CONF = MP_SRV_BASE+"/conf"
OS_TYPE = platform.system()
system_name = platform.uname()[1]

'''	
# ----------------------------------	
# Script Requires ROOT
# ----------------------------------
'''
if os.geteuid() != 0:
    exit("\nYou must be an admin user to run this script.\nPlease re-run the script using sudo.\n")

'''	
# ----------------------------------	
# Enable Startup Scripts / Cron Job
# ----------------------------------
'''
if OS_TYPE == "Darwin":
	if not os.path.exists("/Library/MacPatch/Content/Web"):
		
		os.symlink("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist","/Library/LaunchDaemons/gov.llnl.mploader.plist")
		os.chown("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist", 0, 0)
		os.chmod("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist", 0644)

if OS_TYPE == "Linux":
	exit("Not Supported, YET!")

	
print "\nPlease note, if you wish to replicate content from your own Apple SoftwareUpdate server"
print "you will need to edit the "+MP_SRV_BASE+"/conf/etc/gov.llnl.mp.patchloader.plist"
print "file. \n"

