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
  Script Version 1.1.0
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
macServices = ['gov.llnl.mp.tomcat.plist', 'gov.llnl.mp.ProxySync.plist']
os_type = platform.system()
system_name = platform.uname()[1]
dist_type = platform.dist()[1]

# ----------------------------------
# Enable Startup Scripts
# ----------------------------------
def setup_startup_scripts(services):
    if os_type == "Darwin":
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

    if os_type == "Linux":
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
    if os_type == "Darwin":
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

def osxLoadServices(service):
    _services = list()
    
    if service.lower() == "all":
        _services = macServices
    else:
        if service in macServices:
            _services.append(service)
        else:
            print service + " was not found. Service will not load."
            return
            
    for srvc in _services:
        _launchdFile = "/Library/LaunchDaemons/"+srvc
        if os.path.exists(_launchdFile):
            print "Loading service "+srvc
            os.system("/bin/launchctl load -w /Library/LaunchDaemons/"+srvc)
        else:

            if os.path.exists("/Library/MacPatch/Server/conf/LaunchDaemons/"+srvc):
                srvc_path = "/Library/MacPatch/Server/conf/LaunchDaemons/"+srvc
            elif os.path.exists("/Library/MacPatch/Server/conf/LaunchDaemons/proxy/"+srvc):
                srvc_path = "/Library/MacPatch/Server/conf/LaunchDaemons/proxy/"+srvc

            if os.path.exists(srvc_path):
                if os.path.exists("/Library/LaunchDaemons/"+srvc):
                    os.remove("/Library/LaunchDaemons/"+srvc)
            
                os.chown(srvc_path, 0, 0)
                os.chmod(srvc_path, 0644)
                os.symlink(srvc_path,"/Library/LaunchDaemons/"+srvc)
                
                print "Loading service "+srvc
                os.system("/bin/launchctl load -w /Library/LaunchDaemons/"+srvc)
                
            else:
                print srvc + " was not found in MacPatch Server directory. Service will not load."
                        
def osxUnLoadServices(service):

    _services = []
    if service.lower() == "all":
        _services = macServices
    else:
        if service in macServices:
            _services = service
            
    for srvc in _services:
        _launchdFile = "/Library/LaunchDaemons/"+srvc
        if os.path.exists(_launchdFile):
            print "UnLoading service "+srvc
            os.system("/bin/launchctl unload -wF /Library/LaunchDaemons/"+srvc)                

# ------------------------------
# Configure Proxy Server
# ------------------------------
def ConfigureServer():

    # Add Certs To KeyStore
    os.system('clear')
    print("Configure Proxy Server Settings\n\n")
    print("Get Certificate from master MacPatch Server...")
    server_name = raw_input("MacPatch Master Server name: ")
    server_port = raw_input("MacPatch Master Server Port Number [2600]:") or 2600
    server_secure = raw_input("Use SSL to Connect [Y/N]:") or "Y"
    server_and_port=server_name+":"+str(server_port)
    downloadAndAddCertForServers(server_and_port)

    # Add Master Server Key
    # os.system('clear')
    seed_key = raw_input("MacPatch Proxy Server ID Key: ")

    # Add SMTP Info
    print("Configure SMTP Server")
    smtp_server = raw_input("SMTP Server: ")
    smtp_user = raw_input("SMTP Username: ")
    smtp_pass = raw_input("SMTP Password: ")
    smtp_enable = raw_input("SMTP Enable[Y/N]: ") or "N"
    if smtp_enable == "Y" or smtp_enable == "Yes":
        smtp_enable = "YES"
    else:
        smtp_enable = "NO"

    json_file="/Library/MacPatch/Server/conf/etc/proxy/siteconfig.json"
    json_data=open(json_file)
    cData = json.load(json_data)
    json_data.close()

    print("Writing configuration data to file ...")
    cData["settings"]["proxyServer"]["primaryServer"] = server_name
    cData["settings"]["proxyServer"]["primaryServerPort"] = str(server_port)
    cData["settings"]["proxyServer"]["seedKey"] = seed_key

    cData["settings"]["mailserver"]["enabled"] = smtp_enable
    cData["settings"]["mailserver"]["server"] = smtp_server
    cData["settings"]["mailserver"]["username"] = smtp_user
    cData["settings"]["mailserver"]["password"] = smtp_pass

    with open(json_file, "w") as outfile:
        json.dump(cData, outfile, indent=4)

    # Add Host Info to Sync Plist
    theFile = MP_SRV_BASE + "/conf/etc/proxy/gov.llnl.MPProxySync.plist"
    isBinPlist = isBinaryPlist(theFile)

    if isBinPlist == True:
        prefs = biplist.readPlist(theFile)
    else:
        prefs = plistlib.readPlist(theFile)

    # Apply The Settings
    prefs['MPServerAddress'] = server_name
    prefs['MPServerPort'] = str(server_port)
    if server_secure == "Y" or server_secure == "Yes":
        prefs['MPServerSSL'] = str(1) 

    try:
        if isBinPlist == True:
            biplist.writePlist(prefs,theFile)
        else:
            plistlib.writePlist(prefs,theFile)
    except Exception, e:
        print("Error: %s" % e)

    return macServices

# ------------------------------
# Main Methods
# ------------------------------
def main():

    # Args Parser
    parser = argparse.ArgumentParser(description='Process some args.')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--setup', help="Configure MPProxy Server", required=False, action='store_true')
    group.add_argument('--load', help="Load/Start Services [All - Service]", required=False)
    group.add_argument('--unload', help='Unload/Stop Services [All - Service]', required=False)
    args = parser.parse_args()

    try:
        # ----------------------------------
        # Script Requires ROOT
        # ----------------------------------
        os.system('clear')
        if os.geteuid() != 0:
            exit("\nYou must be an admin user to run this script.\nPlease re-run the script using sudo.\n")

        if os_type == "Linux":
            exit("\nLinux is not supported yet.\n")

        # Setup & Service control
        if os_type == 'Darwin':
            if args.setup != False:
                srvList = ConfigureServer()
                for srvc in srvList:
                    osxLoadServices(srvc)

            elif args.load != None:
                osxLoadServices(args.load)

            elif args.unload != None:
                osxUnLoadServices(args.unload)

        elif os_type == 'Linux':
            '''
            if args.setup != False:
                srvList = setupServices()
                for srvc in srvList:
                    linuxLoadServices(srvc)
            if args.load != None:
                linuxLoadServices(args.load)
            elif args.unload != None:
                linuxUnLoadServices(args.unload)
            '''
            print "Linux not supported yet."
            sys.exit(1)
            

            # Start or Stop the services
            serviceControl(args.action,the_services)

    except Exception, e:
        print "%s" % e
        sys.exit(1)

if __name__ == '__main__':
    main()
