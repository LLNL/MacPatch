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
    Script: MPSUSPatchSync
    Version: 1.0.3

    Description: This Script read all of the patch information
    from the apple software update sucatlog files and post the 
    info to the MacPatch database.    

    Requirements:
    Python, the requests Library is required use pip or easy_install

    Sample Config Plist:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>ASUSServer</key>
        <string>http://swscan.apple.com</string>
        <key>Catalogs</key>
        <array>
            <dict>
                <key>catalogurl</key>
                <string>content/catalogs/others/index-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog</string>
                <key>osver</key>
                <string>10.9</string>
            </dict>
        </array>
        <key>MPServerAddress</key>
        <string>localhost</string>
        <key>MPServerPort</key>
        <string>2600</string>
        <key>MPServerUseSSL</key>
        <true/>
    </dict>
    </plist>
'''

import datetime
import logging
import os
import argparse
import plistlib
import re 
import json
import requests
import xml.etree.ElementTree as ET
import base64
import sys
import subprocess
import hashlib
from pprint import pprint


# Define logging for global use
logger = logging.getLogger('MPSUSPatchSync')
logFile = "/Library/MacPatch/Server/Logs/MPSUSPatchSync.log"

# Variables That Can be Changed
ignorePatches = ['MultiLingualVoice'] # List of Patches containing to not include in the results
wsPostKey = '0' # The MD5 Hashed Key from the siteconfig.xml

# Do not Change
susConfig = {}
wsPostAPI = '/Service/MPServerService.cfc?method=PostApplePatchContent'
wsPostKeyHash = hashlib.md5(wsPostKey).hexdigest()
wsPostVersion = "1.0.0"

# --------------------------------------------
# Define Main Methods
# --------------------------------------------

def returnVersionFromCDATAString(aStr):
    _str = aStr.replace("'", '')
    _str = _str.replace("\"", '')
    _str = _str.replace(";", '')
    return _str.split("=")[1].strip()

def returnDateTimeAsString(aDate):
    # Converts a datetime object to string, needed for JSON
    return aDate.strftime('%Y-%m-%d %H:%M:%S')

def readServerMetadata(metaURL):

    title = 'NA'
    version = '1.0.0'
    description = 'NA'

    r = requests.get(metaURL)
    if r.status_code == requests.codes.ok:
        
        plist = plistlib.readPlistFromString(r.text.encode('utf-8'))

        if plist.has_key("CFBundleShortVersionString"):
            version = str(plist["CFBundleShortVersionString"])

        localization = {}
        try:
            _loc = plist.get('localization',None)
            if _loc == None:
                _loc = plist.get('localizations',None)
            
            if _loc != None:
                if _loc.has_key("English"):
                    localization = _loc["English"]
                elif _loc.has_key("en"):
                    localization = _loc["en"]
                else:
                    localization = None

                if localization != None:
                    if localization.has_key('title'):
                        title = localization['title']
                    if localization.has_key('description'):
                        description = base64.b64encode(str(localization['description']).encode('utf-8'))
        
        except Exception, e:
            logger.error("Error: %s" % e)
            logger.error("Offending URL: %s" % metaURL)

    metaData = {}
    metaData['title'] = title
    metaData['version'] = version
    metaData['description'] = description

    return metaData

def readDistributionFile(distURL):

    distData = {}
    distData['name'] = ''
    distData['suname'] = ''
    distData['restart'] = 'NoRestart'
    distData['version'] = None
    distData['titleAlt'] = 'NA'

    r = requests.get(distURL)
    if r.status_code == requests.codes.ok:

        root = ET.fromstring(r.text.encode('utf-8'))
        c = root.findall("./choice[@suDisabledGroupID]")
        if len(c) == 1:
            for x in c:
                distData['name'] = x.get('suDisabledGroupID','')
                
                if len(x) >= 1:
                    distData['restart'] = x[0].get('onConclusion','NoRestart')
                    distData['version'] = x[0].get('version','')
                    distData['suname'] = distData['name'] + "-" + distData['version']

        if distData['version'] == None or distData['version'] == '':
            # Find the CDATA
            d = root.findall("./localization/strings")
            enList = [x for x in d if x.get('language') == 'en' or x.get('language') == 'English']
            # if the strings are in English/en
            if len(enList) == 1:
                # Find the SU_VER ... Matches both SU_VERS & SU_VERSION
                m = re.findall(r'.\bSU_VER.*',enList[0].text)
                # Clean the found string
                tmpVer = returnVersionFromCDATAString(m[0])
                # If we have found string
                if tmpVer != "":
                    distData['version'] = tmpVer
                    distData['suname'] = distData['name'] + "-" + distData['version']

                t = re.findall(r'.\SU_TITLE.*',enList[0].text)
                tmpTitle = returnVersionFromCDATAString(t[0])
                if tmpTitle != "":
                    # Clean the found string
                    distData['titleAlt'] = tmpTitle
    else:
        print "Error reading distribution file."            

    return distData

def postDataToWebService(patches, config):

    httpPrefix = "http"
    if config['MPServerUseSSL'] == True:
        httpPrefix = "https"
    
    _url = httpPrefix + "://" + str(config['MPServerAddress']) + ":" + str(config['MPServerPort']) + wsPostAPI
    logger.debug("Post URL: "+ _url)

    payload = {'type': 'json' , 'data': json.dumps(patches)}
    headers = {'MPClient-API': wsPostKey, 'MPVersion-API': wsPostVersion}

    try:
        request = requests.post(_url, data=payload, verify=False, headers=headers)

        if request.status_code == requests.codes.ok:
            logger.info("Data post was successful.")
            logger.info(request.text)
        else:
            logger.error("Data post was not successful.")
            logger.error(request.text)

    except requests.exceptions.RequestException as e:
        logger.error(e)   

def readSUSCatalogFile(sucatalog, asFile=False):

    if asFile:
        prefs = plistlib.readPlist(sucatalog)
    else:
        r = requests.get(sucatalog)
        if r.status_code == requests.codes.ok:
            prefs = plistlib.readPlistFromString(r.text.encode('utf-8'))    

    if not prefs:
        return None

    productKeys = prefs['Products'].keys()
    patches = []

    logger.info("Found " + str(len(productKeys)) + " to process." )

    for key in productKeys:
        
        logger.info("Processing key " + key )

        patch = {}
        patch['akey'] = key
        if prefs['Products'][key].has_key("PostDate"):
            patch['postdate'] = returnDateTimeAsString(prefs['Products'][key]['PostDate'])
        else:
            patch['postdate'] = '1984-01-01 00:00:00'
        if len(prefs['Products'][key]['Packages']) > 0 and prefs['Products'][key]['Packages'][0].has_key("Size"): 
            patch['size'] = str(prefs['Products'][key]['Packages'][0]['Size'])
        else:
            patch['size'] = '0'
        patch['title'] = 'NA'
        patch['description'] = base64.b64encode('NA')
        patch['name'] = ''
        patch['suname'] = 'NA'
        patch['restart'] = ''
        patch['version'] = '1.0.0'
        
        if prefs['Products'][key].has_key("ServerMetadataURL"):
            patch['ServerMetadataURL'] = prefs['Products'][key]["ServerMetadataURL"]
        else:
            patch['ServerMetadataURL'] = ""

        if prefs['Products'][key].has_key("Distributions"):
            if prefs['Products'][key]["Distributions"].has_key("en"):
                patch['Distribution'] = prefs['Products'][key]["Distributions"]['en']
            elif prefs['Products'][key]["Distributions"].has_key("English"):
                patch['Distribution'] = prefs['Products'][key]["Distributions"]['English']
            else:
                patch['Distribution'] = ""
        else:   
            patch['Distribution'] = ""

        if len(patch['Distribution']) >= 1:
            df = readDistributionFile(patch['Distribution'])
            patch.update(df.copy())

        if len(patch['ServerMetadataURL']) >= 1:
            md = readServerMetadata(patch['ServerMetadataURL'])
            patch.update(md.copy())

        # Make sure we dont have an empty patch name
        if len(patch['name']) <= 2:
            patch['name'] = patch['akey']
            patch['suname'] = patch['akey']+'-'+patch['version']

        # If we end up with a empty title check to see if we got one from the dist file
        if patch['title'] == 'NA':
            if patch['titleAlt'] != 'NA':
                patch['title'] = patch['titleAlt']     


        patch.pop("titleAlt", None)
        patch.pop("ServerMetadataURL", None)
        patch.pop("Distribution", None)
        patches.append(patch)
        pprint("Adding patch: " + patch['suname'])

        
        containsWordFound = 0
        if len(ignorePatches) >= 1:
            for i in ignorePatches:
                if i.upper() in patch['name'].upper():
                    containsWordFound += 1

        if containsWordFound <= 0:
            patches.append(patch)         

    return patches

def main():
    '''Main command processing'''
    parser = argparse.ArgumentParser(description='Process some args.')
    parser.add_argument('--plist', help="MacPatch SUS Config file", required=False, default="/Library/MacPatch/Server/conf/etc/gov.llnl.mp.patchloader.plist")
    parser.add_argument('--debug', help='Set log level to debug', action='store_true')
    parser.add_argument('--data', help="JSON results file", required=False)
    parser.add_argument('--save', help='Saves patches as JSON file', action='store_true')
    args = parser.parse_args()

    # Setup Logging
    try:
        hdlr = logging.FileHandler(logFile)
        formatter = logging.Formatter('%(asctime)s %(levelname)s --- %(message)s')
        hdlr.setFormatter(formatter)
        logger.addHandler(hdlr) 
        
        if args.debug:
            logger.setLevel(logging.DEBUG)
        else:
            logger.setLevel(logging.INFO)

    except Exception, e:
        print "%s" % e
        sys.exit(1)

    # Make Sure the Config Plist Exists
    if args.plist:
        if not os.path.exists(args.plist):
            print "Unable to open " + args.plist +". File not found."
            sys.exit(1)   

        # Read First Line to check and see if binary and convert
        infile = open(args.plist, 'r')
        if not '<?xml' in infile.readline():
            os.system('/usr/bin/plutil -convert xml1 ' + args.plist)
        
        # ReadPlist and create config Object
        susConfig = plistlib.readPlist(args.plist)
        

    logger.info('# ------------------------------------------------------')
    logger.info('# Starting SUS patch sync'                               )
    logger.info('# ------------------------------------------------------')
    
    if args.data != None:
        if os.path.exists(args.data):
            file = open(args.data, 'r')
            patches = json.loads(file.read())
        else:
            print "Unable to open " + args.data +". File not found."
            sys.exit(1)
    else:
        # Build the Catalogs Array to get the Patches from
        catalogs = []
        if susConfig.has_key('Catalogs'):
            for cat in susConfig['Catalogs']:
                catalogs.append(susConfig['ASUSServer']+'/'+cat['catalogurl'])
        else:
            logger.error('Cant find Catalogs key.')
            sys.exit(0)

        # Read each catalog and parse each patch
        _patches = []
        patchesRaw = []
        for catalog in catalogs:
            logger.info("Parsing catalog %s" % os.path.basename(catalog))
            _patches = readSUSCatalogFile(catalog)
            patchesRaw.extend(_patches)

        # Remove any duplicate keys from the array before posting
        logger.info("Total patches found %d, begin removing duplicates." % len(patchesRaw))
        patches = {v['akey']:v for v in patchesRaw}.values()
        logger.info("Total patches %d to post to web service." % len(patches))
    
    logger.info("Posting patches to web service")
    postDataToWebService(patches,susConfig)

    if args.save:
        file = open("/tmp/SUSPatches.json", "w")
        file.write(json.dumps(patches))
        file.close()
    
if __name__ == '__main__':
    main()