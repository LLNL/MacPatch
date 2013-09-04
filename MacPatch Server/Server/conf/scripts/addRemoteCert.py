#!/usr/bin/env python

import sys, getopt
import os
import commands

Version="2.0.0"
MP_SRV_BASE="/Library/MacPatch/Server"
MP_SRV_CONF=MP_SRV_BASE+"/conf"

def main(argv):

	try:
		opts, args = getopt.getopt(argv,"hc:b:v")
	except getopt.GetoptError:
		usage()
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			usage()
			sys.exit()
		elif opt == '-v':
			print 'getOpt.py version ' + Version
			sys.exit()	
		elif opt in ("-c"):
			getCerts(arg)
		elif opt in ("-b"):
			global MP_SRV_BASE
			global MP_SRV_CONF
			MP_SRV_BASE = arg
			MP_SRV_CONF = MP_SRV_BASE+"/conf"	
	
	sys.exit()
			
def getCerts (servers):
	
	if not os.path.exists(MP_SRV_CONF+"/jsseCerts"):
		os.makedirs(MP_SRV_CONF+"/jsseCerts")
	
	# Make a list of the server input arg
	_servers = []
	_servers = servers.split(' ')
	
	# Download and add the cert for each server
	for server in _servers:
		addCert(server)
		
	print 
	print "Certificates have been download, and a jssecacerts file has been created."
	print 
	print "****************** NOTE ******************"
	print "A reboot of the J2EE services will be requirerd for the application server to recognize the new cert(s)."
	print	
				

def addCert(host):
	
	fileName = host.replace(':','_')
	hostNameShort = fileName.split('.')[0]
	
	if os.path.exists(MP_SRV_CONF+"/jsseCerts/"+host+".cer"):
		os.remove(MP_SRV_CONF+"/jsseCerts/"+host+".cer")
		
	# Download the new cert
	(ret, out) = commands.getstatusoutput('echo | openssl s_client -connect '+host+' 2>/dev/null | sed -ne \'/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p\' > "'+MP_SRV_CONF+'/jsseCerts/'+fileName+'.cer"')
	if ret == 0:
		print "Import "+host+" to jssecacerts"
		# if the jssecacerts file does not exist dont delete anything
		if os.path.exists(MP_SRV_CONF+'/jsseCerts/jssecacerts'):
			# Delete the alias if it exists, it's easier to just delete and re-add it
			(delRet, delOut) = commands.getstatusoutput('keytool -delete -alias "'+hostNameShort+'" -keystore "'+MP_SRV_CONF+'/jsseCerts/jssecacerts" -storepass changeit -trustcacerts -noprompt')
			if (delRet != 0):
				print "Error deleting alias for "+hostNameShort+ " " +delOut
		
		# Add the downloaded cert		
		(addRet, addOut) = commands.getstatusoutput('keytool -import -file "'+MP_SRV_CONF+'/jsseCerts/'+fileName+'.cer" -alias "'+hostNameShort+'" -keystore "'+MP_SRV_CONF+'/jsseCerts/jssecacerts" -storepass changeit -trustcacerts -noprompt')
		if (addRet != 0):
			print "Error adding cert for "+hostNameShort+ " " +addOut
	else:
		print "Error getting cert for "+host+". "+out

def usage ():
	print ""
	print "USAGE: "
	print "    getRemoteCerts.sh [-?] [-c]"
	print ""
	print "OPTIONS:"
	print "    -c  List Of Domain Controller(s) to get the cert from."
	print "    -b  Specify a base path to download the certs and create the jssecacerts file."
	print "    -?  this usage information"
	print ""
	print "EXAMPLE:"
	print "    getRemoteCerts.sh -c \"dc1.example.com:3269 dc2.example.com:3269\""
	print ""


if __name__ == "__main__":
	main(sys.argv[1:])