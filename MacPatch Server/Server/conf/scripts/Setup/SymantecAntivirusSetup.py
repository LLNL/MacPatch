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
  MacPatch SAV Defs Sync Setup Script
  MacPatch Version 2.5.x
  
  Script Version 1.1.1
'''

import os
import plistlib
import biplist
import platform

MP_SRV_BASE = "/Library/MacPatch/Server"
MP_SRV_CONF = MP_SRV_BASE+"/conf"
MP_DEFAULT_PORT = "3601"
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

server_name = raw_input("MacPatch Server name [" + str(system_name) + "]:") or str(system_name)
server_ssl = raw_input("Use SSL for MacPatch connection [Y]:") or "Y"

if server_ssl == "Y":
	server_ssl = "1"
	server_port = raw_input("MacPatch Port [2600]:") or 2600
else:
	server_ssl = "0"
	server_port = raw_input("MacPatch Port ["+str(MP_DEFAULT_PORT)+"]:") or MP_DEFAULT_PORT

'''	
# ----------------------------------	
# Write the Plist With Changes	
# ----------------------------------
'''

def isBinaryPlist(pathOrFile):
    result = True
    didOpen = 0
    if isinstance(pathOrFile, (str, unicode)):
        pathOrFile = open(pathOrFile)
        didOpen = 1
    header = pathOrFile.read(8)
    pathOrFile.seek(0)
    if header == '<?xml ve' or header[2:] == '<?xml ': #XML plist file, without or with BOM 
        result = False
    elif header == 'bplist00': #binary plist file
        result = True

    return result

theFile = MP_SRV_BASE + "/conf/etc/gov.llnl.mpavdl.plist"
isBinPlist = isBinaryPlist(theFile)

if isBinPlist === True:
	prefs = biplist.readPlist(theFile)
else:
	prefs = plistlib.readPlist(theFile)

prefs['MPServerAddress'] = server_name
prefs['MPServerSSL'] = str(server_ssl)
prefs['MPServerPort'] = str(server_port)
try:
	if isBinPlist === True:
		biplist.writePlist(prefs,theFile)	
	else:
		plistlib.writePlist(prefs,theFile)	
except Exception, e:
	print("Error: %s" % e)	


'''	
# ----------------------------------	
# Enable Startup Scripts
# ----------------------------------
'''
if OS_TYPE == "Darwin":
	if os.path.exists("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.AVDefsSync.plist"):
		if os.path.exists("/Library/LaunchDaemons/gov.llnl.mp.AVDefsSync.plist"):
			os.remove("/Library/LaunchDaemons/gov.llnl.mp.AVDefsSync.plist")
		
		os.symlink("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist","/Library/LaunchDaemons/gov.llnl.mp.AVDefsSync.plist")
		os.chown("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.AVDefsSync.plist", 0, 0)
		os.chmod("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.AVDefsSync.plist", 0644)

if OS_TYPE == "Linux":
	from crontab import CronTab
	cron = CronTab()
	job  = cron.new(command='/Library/MacPatch/Server/conf/scripts/MPAVDefsSync.py -p /Library/MacPatch/Server/conf/etc/gov.llnl.mpavdl.plist -r')
	job.set_comment("MPAVLoader")
	job.hour.every(11)	