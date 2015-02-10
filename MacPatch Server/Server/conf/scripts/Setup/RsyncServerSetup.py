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
  MacPatch Rsync Service Setup Script
  MacPatch Version 2.5.x
  
  Script Version 1.1.2
'''

import os
import plistlib
import platform

MP_SRV_BASE = "/Library/MacPatch/Server"
MP_SRV_CONF = MP_SRV_BASE+"/conf"
OS_TYPE = platform.system()
system_name = platform.uname()[1]
dist_type = platform.dist()[1]

'''	
# ----------------------------------	
# Script Requires ROOT
# ----------------------------------
'''
if os.geteuid() != 0:
    exit("\nYou must be an admin user to run this script.\nPlease re-run the script using sudo.\n")

print("This Script will setup this server to syncronize data from the \"Master\" MacPatch server.\n\n")

server_name = raw_input("MacPatch Server name TO sync data from [" + str(system_name) + "]:") or str(system_name)

'''	
# ----------------------------------	
# Write the Plist With Changes	
# ----------------------------------
'''
theFile = MP_SRV_BASE + "/conf/etc/gov.llnl.mp.sync.plist"
if os.path.exists(theFile):
	prefs = plistlib.readPlist(theFile)
else:
	prefs = {}

prefs['MPServerAddress'] = server_name

try:
	plistlib.writePlist(prefs,theFile)	
except Exception, e:
	print("Error: %s" % e)	


'''	
# ----------------------------------	
# Enable Startup Scripts
# ----------------------------------
'''
if OS_TYPE == "Darwin":
	if os.path.exists("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sync.plist"):
		if os.path.exists("/Library/LaunchDaemons/gov.llnl.mp.sync.plist"):
			os.remove("/Library/LaunchDaemons/gov.llnl.mp.sync.plist")
		
		os.symlink("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sync.plist","/Library/LaunchDaemons/gov.llnl.mp.sync.plist")
		os.chown("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sync.plist", 0, 0)
		os.chmod("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sync.plist", 0644)

if OS_TYPE == "Linux":
	from crontab import CronTab
	cron = CronTab()
	job  = cron.new(command='/Library/MacPatch/Server/conf/scripts/MPSyncContent.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mp.sync.plist')
	job.set_comment("MPSyncContent")
	job.hour.every(1)	
	cron.write()