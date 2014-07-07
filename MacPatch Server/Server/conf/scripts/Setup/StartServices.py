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
import argparse
import pwd
import grp

MP_SRV_BASE = "/Library/MacPatch/Server"
MP_SRV_CONF = MP_SRV_BASE+"/conf"
os_type = platform.system()
system_name = platform.uname()[1]
dist_type = "Mac"
macServices=["gov.llnl.mp.wsl.plist","gov.llnl.mp.invd.plist","gov.llnl.mp.site.plist","gov.llnl.mploader.plist","gov.llnl.mpavdl.plist","gov.llnl.mp.httpd.plist"]
lnxServices=["MPApache","MPTomcatSite","MPTomcatWS","MPInventoryD"]
lnxCronSrvs=["MPPatchLoader","MPAVLoader"]
gUID = 79
gGID = 70

if os_type == "Linux":
	# OS is Linux, I need the dist type...
	dist_type = platform.dist()[0]
	try:
		pw = pwd.getpwnam('www-data')
		if pw:
			gUID = pw.pw_uid
			
		gw = grp.getgrnam('www-data')
		if gw:
			gGID = gw.gr_gid
			
	except KeyError:
		print('User someusr does not exist.')

def repairPermissions():
	try:
		if os_type == "Darwin":
			os.system("/usr/sbin/dseditgroup -o edit -a _appserver -t user _www")
			os.system("/usr/sbin/dseditgroup -o edit -a _www -t user _appserverusr")

		# Change Permissions for Linux & Mac		  
		for root, dirs, files in os.walk(MP_SRV_BASE):  
			for momo in dirs:  
				os.chown(os.path.join(root, momo), gUID, gGID)
			for momo in files:
				os.chown(os.path.join(root, momo), gUID, gGID)
	
		os.chmod("/Library/MacPatch/Server", 0775)
		os.chmod("/Library/MacPatch/Server/Logs", 0775)
		os.system("chmod -R 0775 /Library/MacPatch/Content/Web")
		
		if os_type == "Darwin":
			os.system("chown root:wheel /Library/MacPatch/Server/conf/LaunchDaemons/*")
			os.system("chmod 644 /Library/MacPatch/Server/conf/LaunchDaemons/*")
	except Exception, e:
		print("Error: %s" % e)
		
		
def linuxLoadServices(service):

	_services = None
	_servicesC = None
	
	if service == "All":
		_services = lnxServices
		_servicesC = lnxCronSrvs
	else:
		if service in lnxServices:
			_services = service
		elif service in lnxCronSrvs:
			_servicesC = service

	# Load Init.d Services
	if _services != None:
		for srvs in _services:
			linuxLoadInitServices(srvs)
	
	# Load Cron Services
	if _servicesC != None:
		for srvs in _servicesC:
			linuxLoadCronServices(srvs)

def linuxUnLoadServices(service):

	_services = None
	_servicesC = None
	
	if service == "All":
		_services = lnxServices
		_servicesC = lnxCronSrvs
	else:
		if service in lnxServices:
			_services = service
		elif service in lnxCronSrvs:
			_servicesC = service

	# Load Init.d Services
	if _services != None:
		for srvs in _services:
			linuxUnLoadInitServices(srvs)
	
	# Load Cron Services
	if _servicesC != None:
		for srvs in _servicesC:
			removeCronJob(srvs)

def linuxLoadInitServices(service):
	# Load Init Services
	print "Loading service "+service
	os.system("/etc/init.d/"+service+" start")

def linuxUnLoadInitServices(service):
	# UnLoad Init Services
	print "UnLoading service "+service
	os.system("/etc/init.d/"+service+" stop")

def linuxLoadCronServices(service):
	from crontab import CronTab
	cron = CronTab()
	
	if service == "MPPatchLoader":
		print("Loading MPPatchLoader")
		job  = cron.new(command='/Library/MacPatch/Server/conf/scripts/MPSUSPatchSync.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mp.patchloader.plist')
		job.set_comment("MPPatchLoader")
		job.hour.every(8)
		job.enable()
		cron.write()
	
	if service == "MPAVLoader":
		print("Loading MPAVLoader")
		job  = cron.new(command='/Library/MacPatch/Server/conf/scripts/MPAVDefsSync.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mpavdl.plist')
		job.set_comment("MPAVLoader")
		job.hour.every(11)
		job.enable()
		cron.write()

def removeCronJob(comment):
	from crontab import CronTab
	cron = CronTab()

	for job in cron:
		if job.comment == comment:
			print "Removing Cron Job" + comment
			cron.remove (job)

def osxLoadServices(service):
	_services = None
	
	if service == "All":
		_services = macServices
	else:
		if service in macServices:
			_services = service
			
	for srvc in _services:
		print "Loading service "+srvc
		os.system("/bin/launchctl load -w /Library/LaunchDaemons/"+srvc)
			
def osxUnLoadServices(service):

	_services = []
	if service == "All":
		_services = macServices
	else:
		if service in macServices:
			_services = service
			
	for srvc in _services:
		print "UnLoading service "+srvc
		os.system("/bin/launchctl unload -wF /Library/LaunchDaemons/"+srvc)
   

def main():
	'''Main command processing'''

	'''	
	# ----------------------------------	
	# Script Requires ROOT
	# ----------------------------------
	'''
	if os.geteuid() != 0:
		exit("\nYou must be an admin user to run this script.\nPlease re-run the script using sudo.\n")

	parser = argparse.ArgumentParser(description='Process some args.')
	parser.add_argument('--load', help="Load/Start Services", required=False)
	parser.add_argument('--unload', help='Unload/Stop Services', required=False)
	args = parser.parse_args()

	if args.load == None and args.unload == None:
		usage()
		exit("\nOne argument load/unload is required.\n")
	
	if args.load != None and args.unload != None:	
		usage()
		exit("\nOnly one argument load/unload maybe used at a time.\n")
	
	# First Repair permissions
	repairPermissions()

	if os_type == 'Darwin':
		if args.load != None:
			osxLoadServices(args.load)
		elif args.unload != None:
			osxUnLoadServices(args.unload)
	elif os_type == 'Linux':
		if args.load != None:
			linuxLoadServices(args.load)
		elif args.unload != None:
			linuxUnLoadServices(args.unload)

def usage():
	print "StartServices.py --load/--unload [All - Service]\n"
	print "\t--load\t\tLoads a Service or All services with the key word 'All'"
	print "\t--unload\tUn-Loads a Service or All services with the key word 'All'\n"


if __name__ == '__main__':
	main()
	