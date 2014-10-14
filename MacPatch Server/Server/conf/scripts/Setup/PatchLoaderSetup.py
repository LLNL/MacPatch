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
  MacPatch Patch Loader Setup Script
  MacPatch Version 2.5.x
  
  Script Version 1.5.0
'''

import os
import plistlib
import platform

MP_SRV_BASE = "/Library/MacPatch/Server"
MP_SRV_CONF = MP_SRV_BASE+"/conf"
MP_DEFAULT_PORT = "3601"
OS_TYPE = platform.system()
system_name = platform.uname()[1]

'''	
# ----------------------------------	
# Script Requires ROOT
# ----------------------------------
'''
if os.geteuid() != 0:
    exit("\nYou must be an admin user to run this script.\nPlease re-run the script using sudo.\n")

server_name = raw_input("Please enter name [" + str(system_name) + "]:") or str(system_name)
server_ssl = raw_input("Use SSL for MacPatch connection [Y]:") or "Y"

if server_ssl == "Y":
	server_ssl = True
	server_port = raw_input("MacPatch Port [2600]:") or 2600
else:
	server_ssl = False
	server_port = raw_input("MacPatch Port ["+str(MP_DEFAULT_PORT)+"]:") or MP_DEFAULT_PORT

'''	
# ----------------------------------	
# Write the Plist With Changes	
# ----------------------------------
'''
theFile = MP_SRV_BASE + "/conf/etc/gov.llnl.mp.patchloader.plist"
prefs = plistlib.readPlist(theFile)
prefs['MPServerAddress'] = server_name
prefs['MPServerUseSSL'] = server_ssl
prefs['MPServerPort'] = server_port
try:
	plistlib.writePlist(prefs,theFile)	
except Exception, e:
	print("Error: %s" % e)

'''	
# ----------------------------------	
# Enable Startup Scripts / Cron Job
# ----------------------------------
'''
if OS_TYPE == "Darwin":
	if os.path.exists("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist"):
		if os.path.exists("/Library/LaunchDaemons/gov.llnl.mploader.plist"):
			os.remove("/Library/LaunchDaemons/gov.llnl.mploader.plist")
		
		os.symlink("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist","/Library/LaunchDaemons/gov.llnl.mploader.plist")
		os.chown("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist", 0, 0)
		os.chmod("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist", 0644)

if OS_TYPE == "Linux":
	from crontab import CronTab
	cron = CronTab()
	job  = cron.new(command='/Library/MacPatch/Server/conf/scripts/MPSUSPatchSync.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mp.patchloader.plist')
	job.set_comment("MPPatchLoader")
	job.hour.every(8)

	
print "\nPlease note, if you wish to replicate content from your own Apple SoftwareUpdate server"
print "you will need to edit the "+MP_SRV_BASE+"/conf/etc/gov.llnl.mp.patchloader.plist"
print "file. \n"

