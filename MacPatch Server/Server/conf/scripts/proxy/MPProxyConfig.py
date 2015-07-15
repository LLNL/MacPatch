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
  MacPatch Proxy server Setup Script
  Script Version 1.0.0
'''

import os
import sys
import json
import plistlib
import biplist
import platform
from pprint import pprint
import argparse
import commands

MP_SRV_BASE = "/Library/MacPatch/Server"
MP_SRV_CONF = MP_SRV_BASE+"/conf"
proxy_services = ['gov.llnl.mp.httpd.plist', 'gov.llnl.mp.proxy.plist', 'gov.llnl.mp.ProxySync.plist']
OS_TYPE = platform.system()
system_name = platform.uname()[1]
dist_type = platform.dist()[1]

# ----------------------------------
# Enable Startup Scripts
# ----------------------------------
def setup_startup_scripts(services):
    if OS_TYPE == "Darwin":
        for item in services:
            sys_file = "/Library/LaunchDaemons/" + item
            mp_file = MP_SRV_CONF + "/LaunchDaemons/" + item

            if os.path.exists(mp_file):
                if os.path.exists(sys_file):
                    os.remove(sys_file)

                os.chown(mp_file, 0, 0)
                os.chmod(mp_file, 0644)
                os.symlink(mp_file,sys_file)
            else:
                print "Error, %s not found" % mp_file
                exit()

    if OS_TYPE == "Linux":
        print("Linux is not supported yet.")

        '''
        from crontab import CronTab
        cron = CronTab()
        job  = cron.new(command='/Library/MacPatch/Server/conf/scripts/MPAVDefsSync.py -p /Library/MacPatch/Server/conf/etc/gov.llnl.mpavdl.plist -r')
        job.set_comment("MPAVLoader")
        job.hour.every(11)
        '''

# -----------------------------------
# Add Certs To KeyStore
# -----------------------------------

def downloadAndAddCertForServers (servers):
    # Input is server:port
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

# -----------------------------------
# Add Server Info to plist
# -----------------------------------
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

# -----------------------------------
# Services
# -----------------------------------
def serviceControl(action,services):
    if OS_TYPE == "Darwin":
        for item in services:
            print("Attempting to start %s service." % item)
            theLaunchDaemonFile="/Library/LaunchDaemons/" + item

            if os.path.exists(theLaunchDaemonFile):
                os.chown(theLaunchDaemonFile, 0, 0)
                os.chmod(theLaunchDaemonFile, 0644)
                launchctl="launchctl " + action + " -w " + theLaunchDaemonFile
                os.system(launchctl)
                os.system("sleep 3")
            else:
                print("Error: Could not find %s" % theLaunchDaemonFile)

# ------------------------------
# Configure Proxy Server
# ------------------------------
def ConfigureServer():
    # Setup Services
    setup_startup_scripts(proxy_services)

    # Add Certs To KeyStore
    os.system('clear')
    print("Get Certificate from master MacPatch Server...")
    server_name = raw_input("MacPatch Master Server name: ")
    server_port = raw_input("MacPatch Master Server Port Number [2600]:") or 2600
    server_and_port=server_name+":"+str(server_port)
    downloadAndAddCertForServers(server_and_port)

    # Add Master Server Key
    os.system('clear')
    seed_key = raw_input("MacPatch Proxy Server ID Key: ")

    json_file="/Library/MacPatch/Server/conf/etc/siteconfig.json"
    json_data=open(json_file)
    cData = json.load(json_data)
    json_data.close()

    print("Writing configuration data to file ...")
    cData["settings"]["proxyServer"]["primaryServer"] = server_name
    cData["settings"]["proxyServer"]["primaryServerPort"] = str(server_port)
    cData["settings"]["proxyServer"]["seedKey"] = seed_key

    with open(json_file, "w") as outfile:
        json.dump(cData, outfile, indent=4)

    # Add Host Info to Sync Plist
    theFile = MP_SRV_BASE + "/conf/etc/gov.llnl.MPProxySync.plist"
    isBinPlist = isBinaryPlist(theFile)

    if isBinPlist == True:
        prefs = biplist.readPlist(theFile)
    else:
        prefs = plistlib.readPlist(theFile)

    # Apply The Settings
    prefs['MPServerAddress'] = server_name
    prefs['MPServerPort'] = str(server_port)

    try:
        if isBinPlist == True:
            biplist.writePlist(prefs,theFile)
        else:
            plistlib.writePlist(prefs,theFile)
    except Exception, e:
        print("Error: %s" % e)

# ------------------------------
# Main Methods
# ------------------------------
def main():
    # Args Parser
    parser = argparse.ArgumentParser(description='Process Arguments for MP Proxy Server Setup')
    parser.add_argument('--setup', help='Configure MPProxy Server', action='store_false')
    parser.add_argument('--services', help="All | http | server | sync", required=False, default="none")
    parser.add_argument('--action', help="start | stop", required=False, default="none")
    args = parser.parse_args()

    try:
        # ----------------------------------
        # Script Requires ROOT
        # ----------------------------------
        os.system('clear')
        if os.geteuid() != 0:
            print "GO"
            #exit("\nYou must be an admin user to run this script.\nPlease re-run the script using sudo.\n")

        if OS_TYPE == "Linux":
            exit("\nLinux is not supported yet.\n")

        # Setup
        if args.setup:
            ConfigureServer()
            start_services = raw_input("Use SSL for MacPatch connection [Y]:") or "Y"
            if start_services == "Y":
                args.services='All'
                args.action='start'
            else:
                print("To start the proxy server services run the following command.")
                print("MPProxyConfig.py --services All --action start")
                sys.exit(0)

        # Service control
        if args.services != 'none' and args.action != 'none':
            the_services = []
            if args.services == 'All':
                the_services.extend(proxy_services)
            elif args.services == 'http':
                the_services.append(proxy_services[0])
            elif args.services == 'server':
                the_services.append(proxy_services[1])
            elif args.services == 'sync':
                the_services.append(proxy_services[2])
            else:
                exit("\nInvalid Service type.\n")

            # Start or Stop the services
            serviceControl(args.action,the_services)

    except Exception, e:
        print "%s" % e
        sys.exit(1)

if __name__ == '__main__':
    main()
