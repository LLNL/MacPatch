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
  MacPatch Patch Database Setup Script
  MacPatch Version 2.5.43 and higher
  
  Script Version 1.0.2
'''

import os
import json
import platform
from pprint import pprint

MP_SRV_BASE = "/Library/MacPatch/Server"
OS_TYPE = platform.system()
system_name = platform.uname()[1]

json_file="/Library/MacPatch/Server/conf/etc/siteconfig.json"
json_data=open(json_file)
cData = json.load(json_data)
json_data.close()

'''	
# ----------------------------------	
# Script Requires ROOT
# ----------------------------------
'''
if os.geteuid() != 0:
    exit("\nYou must be an admin user to run this script.\nPlease re-run the script using sudo.\n")

'''	
# ----------------------------------	
# Admin Name & Password
# ----------------------------------
'''
os.system('clear')
print "Set Default Admin name and password..."    
set_admin_info = raw_input("Would you like to set the admin name and password [Y]:").upper() or "Y"
if set_admin_info == "Y":
	mp_adm_name = raw_input("MacPatch Default Admin Account Name [mpadmin]: ") or "mpadmin"
	cData["settings"]["users"]["admin"]["name"] = mp_adm_name
	mp_adm_pass = raw_input("MacPatch MacPatch Default Admin Account Password: ")
	cData["settings"]["users"]["admin"]["pass"] = mp_adm_pass

'''	
# ----------------------------------	
# Database Config
# ----------------------------------
'''
os.system('clear')
print "Configure MacPatch Database Info..."
mp_db_hostname = raw_input("MacPatch Database Server Hostname:  [" + str(system_name) + "]: ") or str(system_name)
cData["settings"]["database"]["prod"]["dbHost"] = mp_db_hostname
cData["settings"]["database"]["ro"]["dbHost"] = mp_db_hostname
mp_db_port = raw_input("MacPatch Database Server Port Number [3306]: ") or "3306"
cData["settings"]["database"]["prod"]["dbPort"] = mp_db_port
cData["settings"]["database"]["ro"]["dbPort"] = mp_db_port
mp_db_name = raw_input("MacPatch Database Name [MacPatchDB]: ") or "MacPatchDB"
cData["settings"]["database"]["prod"]["dbName"] = mp_db_name
cData["settings"]["database"]["ro"]["dbName"] = mp_db_name
mp_db_usr = raw_input("MacPatch Database User Name [mpdbadm]: ") or "mpdbadm"
cData["settings"]["database"]["prod"]["username"] = mp_db_usr
mp_db_pas = raw_input("MacPatch Database User Password: ")
cData["settings"]["database"]["prod"]["password"] = mp_db_pas
mp_db_pas_ro = raw_input("MacPatch Database Read Only User Password: ")
cData["settings"]["database"]["ro"]["password"] = mp_db_pas_ro

'''	
# ----------------------------------	
# LDAP/AD Config
# ----------------------------------
'''
os.system('clear')
print "Configure MacPatch Login Source..."
use_ldap = raw_input("Would you like to use Active Directory/LDAP for login? [Y]:").upper() or "Y"

if use_ldap == "Y":
	ldap_hostname = raw_input("Active Directory/LDAP server hostname: ")
	cData["settings"]["ldap"]["server"] = ldap_hostname
	print "Common ports for LDAP non secure is 389, secure is 636."
	print "Common ports for Active Directory non secure is 3268, secure is 3269"
	ldap_port = raw_input("Active Directory/LDAP server port number: ")
	cData["settings"]["ldap"]["port"] = ldap_port
	use_ldap_ssl = raw_input("Active Directory/LDAP use ssl? [Y]: ").upper() or "Y"
	
	if use_ldap_ssl == "Y":
		print "Please note, you will need to run the addRemoteCert.py script prior to starting the MacPatch Web Admin Console."
		ldap_ssl = "CFSSL_BASIC"
		cData["settings"]["ldap"]["secure"] = ldap_ssl
	else:
		ldap_ssl = "NONE"
		cData["settings"]["ldap"]["secure"] = ldap_ssl

	ldap_searchbase = raw_input("Active Directory/LDAP Search Base: ")
	cData["settings"]["ldap"]["searchbase"] = ldap_searchbase
	ldap_lgnattr = raw_input("Active Directory/LDAP Login Attribute [userPrincipalName]: ") or "userPrincipalName"
	cData["settings"]["ldap"]["loginAttr"] = ldap_lgnattr
	ldap_lgnpre = raw_input("Active Directory/LDAP Login User Name Prefix [None]: ") or ""
	cData["settings"]["ldap"]["loginUsrPrefix"] = ldap_lgnpre
	ldap_lgnsuf = raw_input("Active Directory/LDAP Login User Name Suffix [None]: ") or ""
	cData["settings"]["ldap"]["loginUsrSufix"] = ldap_lgnsuf
else:
	cData["settings"]["ldap"]["enabled"] = "NO"

'''	
# ----------------------------------	
# Write the Plist With Changes	
# ----------------------------------
'''
print " "
print "Writing configuration data to file ..."
with open(json_file, "w") as outfile:
    json.dump(cData, outfile, indent=4)

