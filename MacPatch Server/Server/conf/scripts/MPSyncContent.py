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

import datetime
import logging
import os
import argparse
import plistlib
import sys
import subprocess
import hashlib
import platform

# Define logging for global use
logger = logging.getLogger('MPSyncContent')
logFile = "/Library/MacPatch/Server/Logs/MPSyncContent.log"

# Global OS vars
__version__ = "1.1.0"
os_type = platform.system()
system_name = platform.uname()[1]

def readPlist(plistFile):

    # Make sure the plist file exists
    if not os.path.exists(plistFile):
        print "Unable to open " + plistFile +". File not found."
        sys.exit(1)   

    # Read First Line to check and see if binary and convert
    infile = open(plistFile, 'r')
    if not '<?xml' in infile.readline():
        if os_type == "Darwin":
            # Convert the plist to xml
            os.system('/usr/bin/plutil -convert xml1 ' + plistFile)
        
        elif os_type == "Linux":
            print "Plist file is a binary file, unable to open the file type on Linux."
            print "Exiting script."
            sys.exit(1) 
    
    # Read Plist File and return data
    _pData = plistlib.readPlist(plistFile)
    return _pData


def main():
    '''Main command processing'''
    parser = argparse.ArgumentParser(description='Process some args.')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--plist', help="MacPatch SUS Config file", required=False)
    group.add_argument('--server', help="Rsync Server to Sync from.", required=False)
    parser.add_argument('--checksum', help='Use checksum verificartion', action='store_true')
    parser.add_argument('--dry', help="Outputs results, dry run.", required=False)
    parser.add_argument('--version', action='version', version='%(prog)s {version}'.format(version=__version__))
    args = parser.parse_args()

    # Rsync Path
    SYNC_DIR_NAME="mpContentWeb"
    # Rsync Server
    MASTER_SERVER="localhost"
    # Sync Content to...
    LOCAL_CONTENT="/Library/MacPatch/Content/Web"

    MP_SRV_BASE="/Library/MacPatch/Server"
    MP_SRV_CONF=MP_SRV_BASE+"/conf"
    MP_SYNC_PLIST=MP_SRV_CONF+"/etc/gov.llnl.mp.sync.plist"

    # Setup Logging
    try:
        hdlr = logging.FileHandler(logFile)
        formatter = logging.Formatter('%(asctime)s %(levelname)s --- %(message)s')
        hdlr.setFormatter(formatter)
        logger.addHandler(hdlr) 
        logger.setLevel(logging.INFO)

    except Exception, e:
        print "%s" % e
        sys.exit(1)

    # Set Default Values
    if args.checksum:
        useChecksum="-c"
    else:
        useChecksum=""

    # Set Default Values
    if args.dry:
        useDry="-n"
    else:
        useDry=""
        

    logger.info('# ------------------------------------------------------')
    logger.info('# Starting content sync  '                               )
    logger.info('# ------------------------------------------------------')

    if args.plist != None:
        plistData = readPlist(args.plist)
        if plistData != None:
            if plistData.has_key('MPServerAddress'):
                MASTER_SERVER = plistData['MPServerAddress']
            else:
                logger.error("Error, MPServerAddress was not found in plist config.")
                sys.exit(1)

    elif args.server != None:
        MASTER_SERVER = args.server


    # We dont allow localhost
    if MASTER_SERVER == "localhost":
        logger.error("Error, localhost is not supported.")
        sys.exit(1)
    
    logger.info("Starting Content Sync")
    rStr = "-vai " + useDry + " " + useChecksum + " --delete-before --ignore-errors --exclude=.DS_Store " + MASTER_SERVER + "::" + SYNC_DIR_NAME + " " + LOCAL_CONTENT
    os.system('/usr/bin/rsync ' + rStr)
    logger.info("Content Sync Complete")

    
if __name__ == '__main__':
    main()