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
  MacPatch Version 2.7.x
  
  Script Version 1.6.3
'''

import os
import plistlib
import platform
import argparse
import pwd
import grp
import shutil

MP_SRV_BASE = "/Library/MacPatch/Server"
MP_SRV_CONF = MP_SRV_BASE+"/conf"
os_type = platform.system()
system_name = platform.uname()[1]
dist_type = "Mac"
macServices=["gov.llnl.mp.wsl.plist","gov.llnl.mp.invd.plist","gov.llnl.mp.site.plist","gov.llnl.mploader.plist","gov.llnl.mpavdl.plist","gov.llnl.mp.httpd.plist","gov.llnl.mp.rsync.plist","gov.llnl.mp.sync.plist"]
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
	_initFile = "/etc/init.d/"+service
	if os.path.exists(_initFile):
		print "Loading service "+service
		os.system("/etc/init.d/"+service+" start")

def linuxUnLoadInitServices(service):
	# UnLoad Init Services
	_initFile = "/etc/init.d/"+service
	if os.path.exists(_initFile):
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
		_launchdFile = "/Library/LaunchDaemons/"+srvc
		if os.path.exists(_launchdFile):
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
		_launchdFile = "/Library/LaunchDaemons/"+srvc
		if os.path.exists(_launchdFile):
			print "UnLoading service "+srvc
			os.system("/bin/launchctl unload -wF /Library/LaunchDaemons/"+srvc)

def setupRsyncFromMaster():
	os.system('clear')
	print("\nConfigure this server to syncronize data from the \"Master\" MacPatch server.\n")
	server_name = raw_input("MacPatch Server \"hostname\" or \"IP Address\" TO sync data from: ")

	'''	Write the Plist With Changes '''
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

	''' Enable Startup Scripts '''
	if os_type == "Darwin":
		if os.path.exists("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sync.plist"):
			if os.path.exists("/Library/LaunchDaemons/gov.llnl.mp.sync.plist"):
				os.remove("/Library/LaunchDaemons/gov.llnl.mp.sync.plist")
			
			os.symlink("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sync.plist","/Library/LaunchDaemons/gov.llnl.mp.sync.plist")
			os.chown("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sync.plist", 0, 0)
			os.chmod("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sync.plist", 0644)

	if os_type == "Linux":
		from crontab import CronTab
		cron = CronTab()
		job  = cron.new(command='/Library/MacPatch/Server/conf/scripts/MPSyncContent.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mp.sync.plist')
		job.set_comment("MPSyncContent")
		job.every(15).minute()	
		cron.write()

def setupPatchLoader():

	'''	Write the Plist With Changes '''
	prefs = dict()
	theFile = MP_SRV_BASE + "/conf/etc/gov.llnl.mp.patchloader.plist"
	if os.path.exists(theFile):
		prefs = plistlib.readPlist(theFile)

	prefs['MPServerAddress'] = '127.0.0.1'
	prefs['MPServerUseSSL'] = 'N'
	prefs['MPServerPort'] = '3601'

	try:
		plistlib.writePlist(prefs,theFile)	
	except Exception, e:
		print("Error: %s" % e)

	''' Enable Startup Scripts '''
	if os_type == "Darwin":
		if os.path.exists("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist"):
			if os.path.exists("/Library/LaunchDaemons/gov.llnl.mploader.plist"):
				os.remove("/Library/LaunchDaemons/gov.llnl.mploader.plist")
			
			os.symlink("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist","/Library/LaunchDaemons/gov.llnl.mploader.plist")
			os.chown("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist", 0, 0)
			os.chmod("/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mploader.plist", 0644)

	if os_type == "Linux":
		from crontab import CronTab
		cron = CronTab()
		job  = cron.new(command='/Library/MacPatch/Server/conf/scripts/MPSUSPatchSync.py --plist /Library/MacPatch/Server/conf/etc/gov.llnl.mp.patchloader.plist')
		job.set_comment("MPPatchLoader")
		job.hour.every(6)
		cron.write()
   
def setupServices():

	srvsList = []
	print "You will be asked which services you would like to load"
	print "on system startup."
	print ""

	# Master or Distribution
	masterType = True
	srvType = raw_input('Is this a Master or Distribution server [M/D]?')
	if srvType.lower() == "m" or srvType.lower() == "master":
		masterType = True
	elif srvType.lower() == "d" or srvType.lower() == "distribution":
		masterType = False

	# Web Server
	_HTTPD = 'Y'
	webServer = raw_input('Start Web Server [%s]' % _HTTPD)
	webServer = webServer or _HTTPD
	if webServer.lower() == 'y':
		if os_type == 'Darwin':
			srvsList.append('gov.llnl.mp.httpd.plist')
		else:
			linkStartupScripts('MPApache')
			srvsList.append('MPApache')
	
	# Web Services
	_WEBSERVICES = 'Y' 
	webService = raw_input('Start Web Services [%s]' % _WEBSERVICES)
	webService = webService or _WEBSERVICES
	if webService.lower() == 'y':
		if os_type == 'Darwin':
			srvsList.append('gov.llnl.mp.wsl.plist')
			srvsList.append('gov.llnl.mp.invd.plist')
		else:
			linkStartupScripts('MPTomcatWS')
			srvsList.append('MPTomcatWS')
			linkStartupScripts('MPInventoryD')
			srvsList.append('MPInventoryD')

	# Content Sync
	_CONTENT = 'Y' if masterType else 'N'  
	print "Content sync allows distribution servers to sync from the master server."
	cRsync = raw_input('Start Content Sync Service (Master Only) [%s]' % _CONTENT)
	cRsync = cRsync or _CONTENT
	if cRsync.lower() == 'y':
		srvsList.append('gov.llnl.mp.rsync.plist')
		
	# Web Admin Console
	_ADMINCONSOLE = 'Y' if masterType else 'N'  
	adminConsole = raw_input('Start Admin Console Application [%s]' % _ADMINCONSOLE)
	adminConsole = adminConsole or _ADMINCONSOLE
	if adminConsole.lower() == 'y':
		if os_type == 'Darwin':
			srvsList.append('gov.llnl.mp.site.plist')
		else:
			linkStartupScripts('MPTomcatSite')
			srvsList.append('MPTomcatSite')
	
	# Patch Loader
	_PATCHLOAD = 'Y' if masterType else 'N'
	patchLoader = raw_input('ASUS Patch Content Loader [%s]' % _PATCHLOAD)
	patchLoader = patchLoader or _PATCHLOAD
	if patchLoader.lower() == 'y':
		setupPatchLoader()
		if os_type == 'Darwin':
			srvsList.append('gov.llnl.mp.mploader.plist')
	
	# Sync From Master
	if masterType == False:
		_RSYNC = 'Y'
		mpRsync = raw_input('Sync Content from Master server (Recommended) [%s]' % _RSYNC)
		mpRsync = mpRsync or _RSYNC
		if mpRsync.lower() == 'y':
			setupRsyncFromMaster()
			if os_type == 'Darwin':
				srvsList.append('gov.llnl.mp.sync.plist')

	return srvsList

def linkStartupScripts(service):
	_initFile = "/etc/init.d/"+service
	if not os.path.exists(_initFile):
		script = "/Library/MacPatch/Server/conf/init.d/"+service
		link = "/etc/init.d/"+service 
		os.chown(script, 0, 0)
		os.chmod(script, 0755)
		os.symlink(script,link)
		if platform.dist()[0] == "redhat":
			os.system("/bin/systemctl enable "+service)

		elif platform.dist()[0] == "Ubuntu":
			os.system("update-rc.d "+service+" defaults")

		else:
			print "Unable to start service ("+service+") at start up. OS("+platform.dist()[0]+") is unsupported."
				
		print "Copy Startup Script for "+service
		


def main():
	'''Main command processing'''

	'''	
	# ----------------------------------	
	# Script Requires ROOT
	# ----------------------------------
	'''
	if os.geteuid() != 0:
		print "No Root"
		#exit("\nYou must be an admin user to run this script.\nPlease re-run the script using sudo.\n")

	parser = argparse.ArgumentParser(description='Process some args.')
	group = parser.add_mutually_exclusive_group(required=True)
	group.add_argument('--setup', help="Setup Services", required=False, action='store_true')
	group.add_argument('--load', help="Load/Start Services", required=False)
	group.add_argument('--unload', help='Unload/Stop Services', required=False)
	args = parser.parse_args()

	# First Repair permissions
	# repairPermissions()

	if os_type == 'Darwin':
		if args.setup != False:
			srvList = setupServices()
			for srvc in srvList:
				osxLoadServices(srvc)
		elif args.load != None:
			osxLoadServices(args.load)
		elif args.unload != None:
			osxUnLoadServices(args.unload)
	elif os_type == 'Linux':
		if args.setup != False:
			srvList = setupServices()
			for srvc in srvList:
				linuxLoadServices(srvc)
		if args.load != None:
			linuxLoadServices(args.load)
		elif args.unload != None:
			linuxUnLoadServices(args.unload)

def usage():
	print "StartServices.py --setup or --load/--unload [All - Service]\n"
	print "\t--setup\t\tSetup all services to start on boot and any configuration needed. Will load selected services."
	print "\t--load\t\tLoads a Service or All services with the key word 'All'"
	print "\t--unload\tUn-Loads a Service or All services with the key word 'All'\n"


if __name__ == '__main__':
	main()
	