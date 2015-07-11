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
Script : MPProxySync
Version : 1.0.0
Description: Sync Content From Master Server

Note:
This script requires the "requests" python module. This is not 
part of the base python deployment. To install it simply run 

$ easy_install requests

For more info: http://docs.python-requests.org/en/latest/user/install/

'''

try:
	import logging
	import plistlib
	import argparse
	import sys
	import os
	import json
	import glob
	import requests
	requests.packages.urllib3.disable_warnings()
	import shutil
	import hashlib
except ImportError, e:
	print "%s" % e
	sys.exit(1)

# ------------------------------
# Global Variables
# ------------------------------

logger 				= logging.getLogger('MPProxySync')
#logFile = "/Library/MacPatch/Server/Logs/MPProxySync.log"
logFile 			= "/tmp/MPProxySync.log"
apiURI 				= '/MPDistribution.cfc'
tmp_sync_dir 		= '/private/tmp/sync'
patch_sync_dir 		= '/private/tmp/Content/patches'
sw_sync_dir 		= '/private/tmp/Content/sw'

MP_SERVER			= 'localhost'
MP_PORT				= '2600'
MP_USE_SSL			= True
MP_TIMEOUT			= 10.0
VERIFY_SELF_SIGN	= False

# ------------------------------
# Classes
# ------------------------------

class ContentSync(object):

	def __init__(self, hostString, sync_dir='/private/tmp/Content', sync_dir_tmp='/private/tmp/sync' ):
		self.hostString = hostString
		self.sync_dir_tmp = sync_dir_tmp
		self.sync_dir = sync_dir
		self.content_length	= 0
		self.items_synced	= 0
		self.sync_type		= 'Patches'
	
	def syncPatchContent(self):

		logger.info("Syncing patch content")
		logger.info("Download tmp dir " + self.sync_dir_tmp)
		
		# Verify Content Dir
		_sync_dir 	= self.sync_dir + "/patches"
		if not os.path.exists(_sync_dir):
			os.makedirs(_sync_dir)

		self.sync_type	= 'Patches'
		logger.info("Download dir " + _sync_dir)

		# Patch Content URL
		_url = self.hostString + apiURI + "?method=getDistributionContentAsJSON"
		logger.debug(_url)

		try:
			r = requests.get(_url, verify=VERIFY_SELF_SIGN, timeout=MP_TIMEOUT)

			if r.status_code == requests.codes.ok:
				request = r.json()
				content = json.loads(request['result']) # result is in json formatting and needs second dump
				self.content_length = len(content['Content'])

				# Check for content and remove/create nessasary folders
				if self.content_length >= 1:
					logger.info( "Processing %s patche(s)" % str(self.content_length) )
					if os.path.exists(tmp_sync_dir):
						logger.info("Removing " + self.sync_dir_tmp)
						shutil.rmtree(self.sync_dir_tmp)
					else:
						logger.info("Creating " + self.sync_dir_tmp)
						os.makedirs(self.sync_dir_tmp)

					# Loop Through Content
					process_count = 1
					for item in content['Content']:
						patch_name = item['pkg_url'].split('/')[-1]
						logger.info("Processing " + patch_name)
						logger.info(str(process_count) + " of " + str(self.content_length))
						i = self.downloadItem(item,'patch')
						if i != None:
							dst_dir = _sync_dir + "/" + item['puuid']
							if not os.path.exists(dst_dir):
								logger.info("Creating directory " + dst_dir)
								os.makedirs(dst_dir)
							dst = dst_dir + "/" + patch_name
							logger.info("Moving " + patch_name + " to " + dst_dir)
							shutil.move(i, dst)
							self.items_synced += 1
						else:
							logger.info("Skipping: " + patch_name)

						process_count += 1

			else:
				logger.error("Error, unable to get content. Return code " + str(r.status_code))
		
		except requests.exceptions.RequestException as e:    # This is the correct syntax
			logger.error(e)
			print e
			sys.exit(1)

	def syncSoftwareContent(self):

		logger.info("Syncing software content")
		logger.info("Download tmp dir " + self.sync_dir_tmp)

		# Verify Content Dir
		_sync_dir 	= self.sync_dir + "/sw"
		if not os.path.exists(_sync_dir):
			os.makedirs(_sync_dir)

		self.sync_type	= 'Software'
		logger.info("Download dir " + _sync_dir)

		# Software Content URL
		_url = self.hostString + apiURI + "?method=getSWDistributionContentAsJSON"
		logger.debug(_url)

		try:
			r = requests.get(_url, verify=VERIFY_SELF_SIGN, timeout=MP_TIMEOUT)

			if r.status_code == requests.codes.ok:
				request = r.json()
				content = json.loads(request['result']) # result is in json formatting and needs second dump
				self.content_length = len(content['Content'])

				# Check for content and remove/create nessasary folders
				if self.content_length >= 1:
					logger.info( "Processing %s patche(s)" % str(self.content_length) )
					if os.path.exists(tmp_sync_dir):
						logger.info("Removing " + self.sync_dir_tmp)
						shutil.rmtree(self.sync_dir_tmp)
					else:
						logger.info("Creating " + self.sync_dir_tmp)
						os.makedirs(self.sync_dir_tmp)

					process_count = 1
					# Loop Through Content
					for item in content['Content']:
						patch_name = item['pkg_url'].split('/')[-1]
						logger.info("Processing " + patch_name)
						logger.info(str(process_count) + " of " + str(self.content_length))
						i = self.downloadItem(item,'sw')
						if i:
							dst_dir = _sync_dir + "/" + item['puuid']
							if not os.path.exists(dst_dir):
								logger.info("Creating directory " + dst_dir)
								os.makedirs(dst_dir)
							dst = dst_dir + "/" + patch_name
							logger.info("Moving " + patch_name + " to " + dst_dir)
							shutil.move(i, dst)
							self.items_synced += 1
						else:
							logger.info("Skipping: " + patch_name)

						process_count += 1

			else:
				logger.error("Error, unable to get content. Return code " + str(r.status_code))

		except requests.exceptions.RequestException as e:    # This is the correct syntax
			logger.error(e)
			print e
			sys.exit(1)

	def downloadItem(self,item,type='patch'):
		''' Gen URL for download '''
		
		item_id 	= item['puuid']
		item_hash	= item['pkg_hash']
		item_url	= item['pkg_url']
		if type == 'patch':
			item_type = 'patches'
		else:
			item_type = 'sw'

		url = self.hostString + "/mp-content" + item_url
		logger.debug("Download " + url)
		
		''' Variables '''
		local_file_name		= url.split('/')[-1]
		local_file_path 	= self.sync_dir + "/" + item_type + "/" + item_id + "/" + local_file_name
		tmp_local_dir		= self.sync_dir_tmp + '/' + item_id
		tmp_local_file_path	= self.sync_dir_tmp + "/" + local_file_name

		if os.path.exists(local_file_path):
			local_md5 = self.md5sum(local_file_path)
			if local_md5:
				logger.debug("Local  MD5: " + local_md5)
				logger.debug("Remote MD5: " + item_hash)
				if local_md5.upper() == item_hash.upper():
					return None
			else:
				logger.error('Error with md5 method')
				return None

		if not os.path.exists(tmp_local_dir):
			logger.debug("Creating directory " + tmp_local_dir)
			os.makedirs(tmp_local_dir)

		
		''' Download the patch and return its name '''
		try:
			r = requests.get(url, stream=True, verify=VERIFY_SELF_SIGN, timeout=MP_TIMEOUT)
			with open(tmp_local_file_path, 'wb') as f:
				for chunk in r.iter_content(chunk_size=1024): 
					if chunk: # filter out keep-alive new chunks
						f.write(chunk)
						f.flush()

		except requests.exceptions.RequestException as e:    # This is the correct syntax
			logger.error(e)
			return None

		return tmp_local_file_path 

	def md5sum(self, filename, blocksize=65536):
		hash = hashlib.md5()
		with open(filename, "r+b") as f:
			for block in iter(lambda: f.read(blocksize), ""):
				hash.update(block)
		return hash.hexdigest()

	def postResults(self):

		logData = 'Results for ' + self.sync_type
		logData = logData + '\n' + str(self.content_length) + ' Items to process'
		logData = logData + '\n' + str(self.items_synced) + ' Items processed'
		_url = self.hostString + apiURI + "?method=postSyncResultsJSON&logType=0&logData=" + logData

		try:
			r = requests.get(_url, verify=VERIFY_SELF_SIGN, timeout=MP_TIMEOUT)
			if r.status_code == requests.codes.ok:
				logger.info("Sync Results Posted Successfully")
			else:
				logger.error("Error posting sync results")
		except requests.exceptions.RequestException as e:    # This is the correct syntax
			logger.error(e)

def hostURL():
	_url = None
	if MP_USE_SSL == True:
		_url = "https://" + str(MP_SERVER) + ":" + str(MP_PORT)
	else:
		_url = "http://" + str(MP_SERVER) + ":" + str(MP_PORT)

	logger.debug("Base URL: " + _url)
	return _url

def readPlist(plist):
	# Make sure the plist path is valid
	if not os.path.exists(plist):
			print "Unable to open " + plist +". File not found."
			logger.info("Unable to open " + plist +". File not found.")
			sys.exit(1)

	# Read First Line to check and see if binary and convert
	infile = open(plist, 'r')
	if not '<?xml' in infile.readline():
		os.system('/usr/bin/plutil -convert xml1 ' + plist)

	global MP_SERVER
	global MP_PORT
	global MP_USE_SSL

	# Read the config plist
	confData = plistlib.readPlist(plist)

	if confData.has_key("MPServerAddress"):
		MP_SERVER = confData["MPServerAddress"]
	else:
		MP_SERVER = "localhost"	

	if confData.has_key("MPServerPort"):	
		MP_PORT = str(confData["MPServerPort"])
	else:
		MP_PORT = "3601"

	if confData.has_key("MPServerSSL"):		
		if confData["MPServerSSL"] == True or confData["MPServerSSL"] == '1':
			MP_USE_SSL = True
		else:
			MP_USE_SSL = False	
	else:
		MP_USE_SSL = False

# ------------------------------
# Main Methods
# ------------------------------
def main():
	'''Main command processing'''

	parser = argparse.ArgumentParser(description='Process some args.')
	parser.add_argument('--debug', help='Set log level to debug', action='store_true')
	parser.add_argument('--type', help="Patches | Software | All", required=False, default="All")
	parser.add_argument('--plist', help="MacPatch SUS Config file", required=False, default="/Library/MacPatch/Server/conf/etc/gov.llnl.MPProxySync.plist")
	args = parser.parse_args()

	try:
		# Setup Logging
		hdlr = logging.FileHandler(logFile)
		formatter = logging.Formatter('%(asctime)s %(levelname)s --- %(message)s')
		hdlr.setFormatter(formatter)
		logger.addHandler(hdlr) 

		if args.plist:
			readPlist(args.plist)

		if args.debug:
			logger.setLevel(logging.DEBUG)
		else:
			logger.setLevel(logging.INFO)


		logger.info("-----------------------------------------")
		logger.info(" Begin Proxy Sync                        ")
		logger.info("-----------------------------------------")

		if not os.path.exists(patch_sync_dir):
			os.makedirs(patch_sync_dir)
		
		contentSync = ContentSync(hostURL())
		if args.type == 'All' or args.type == 'Patches':
			contentSync.items_synced = 0
			contentSync.syncPatchContent()
			logger.info("Total numer of patches synced " + str(contentSync.items_synced))
			contentSync.postResults()
		
		if args.type == 'All' or args.type == 'Software':
			contentSync.items_synced = 0
			contentSync.syncSoftwareContent()
			logger.info("Total numer of softwares synced " + str(contentSync.items_synced))
			contentSync.postResults()

	except Exception, e:
	    print "%s" % e
	    sys.exit(1)

if __name__ == '__main__':
    main()




