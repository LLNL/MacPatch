//
//  Constants.m
/*
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
 */

#import "Constants.h"

// Global
NSString * const SITE_CONFIG                = @"/Library/MacPatch/Server/conf/etc/siteconfig.json";
NSString * const SERVER_VER_FILE            = @"/Library/MacPatch/Server/conf/etc/.serverVersion.json";

// Web Server
NSString * const TOMCAT_SERVER              = @"/Library/MacPatch/Server/apache-tomcat/bin/catalina.sh";
NSString * const LAUNCHD_FILE_TOMCAT        = @"/Library/LaunchDaemons/gov.llnl.mp.tomcat.plist";
NSString * const LAUNCHD_ORIG_TOMCAT        = @"/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.tomcat.plist";
NSString * const SERVICE_TOMCAT             = @"gov.llnl.mp.tomcat";

// Web Server
NSString * const APACHE_WEBSERVER            = @"/Library/MacPatch/Server/Apache2/bin/httpd";
NSString * const LAUNCHD_FILE_WEBSERVER      = @"/Library/LaunchDaemons/gov.llnl.mp.httpd.plist";
NSString * const LAUNCHD_ORIG_WEBSERVER      = @"/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.httpd.plist";
NSString * const SERVICE_WEBSERVER           = @"gov.llnl.mp.httpd";

// Web Admin Console
NSString * const TOMCAT_ADMIN                = @"/Library/MacPatch/Server/tomcat-mpsite/bin/catalina.sh";
NSString * const LAUNCHD_FILE                = @"/Library/LaunchDaemons/gov.llnl.mp.site.plist";
NSString * const LAUNCHD_ORIG                = @"/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.tcsite.plist";
NSString * const SERVICE                     = @"gov.llnl.mp.site";
NSString * const TOMCAT_ADMIN_CONF           = @"/Library/MacPatch/Server/tomcat-mpsite/conf/server.xml";

// Web Service
NSString * const TOMCAT_WS                   = @"/Library/MacPatch/Server/tomcat-mpws/bin/catalina.sh";
NSString * const LAUNCHD_WS_FILE             = @"/Library/LaunchDaemons/gov.llnl.mp.wsl.plist";
NSString * const LAUNCHD_WS_ORIG             = @"/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.tcwsl.plist";
NSString * const SERVICE_WS                  = @"gov.llnl.mp.wsl";
NSString * const TOMCAT_WS_CONF              = @"/Library/MacPatch/Server/tomcat-mpws/conf/server.xml";

NSString * const LAUNCHD_INV_FILE            = @"/Library/LaunchDaemons/gov.llnl.mp.invd.plist";
NSString * const LAUNCHD_INV_ORIG            = @"/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.invd.plist";
NSString * const SERVICE_INV                 = @"gov.llnl.mp.invd";

// Software Update Sync
NSString * const SUS_SYNC_FILE               = @"/Library/MacPatch/Server/conf/scripts/MPSUSPatchSync.py";
NSString * const LAUNCHD_SUS_FILE            = @"/Library/LaunchDaemons/gov.llnl.mp.sus.sync.plist";
NSString * const LAUNCHD_SUS_ORIG            = @"/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sus.sync.plist";
NSString * const SERVICE_SUS                 = @"gov.llnl.mp.sus.sync";
NSString * const SERVICE_SUS_CONF_FILE       = @"/Library/MacPatch/Server/conf/etc/gov.llnl.mp.patchloader.plist";

// ContenSync
NSString * const CONTENT_SYNC_CONF_FILE      = @"/Library/MacPatch/Server/conf/etc/gov.llnl.mp.sync.plist";
NSString * const SERVICE_CONTENT_SYNC        = @"gov.llnl.mp.sync";
NSString * const LAUNCHD_CONTENT_SYNC        = @"/Library/LaunchDaemons/gov.llnl.mp.sync.plist";
NSString * const LAUNCHD_FILE_PATCH_SYNC     = @"/Library/LaunchDaemons/gov.llnl.mp.sync.plist";
NSString * const LAUNCHD_ORIG_PATCH_SYNC     = @"/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.sync.plist";

// Rsyncd
NSString * const RSYNCD_CONF_PLIST           = @"/Library/MacPatch/Server/conf/etc/.mpRsyncd.plist";
NSString * const SERVICE_RSYNCD              = @"org.samba.rsync.mp";
NSString * const LAUNCHD_RSYNCD_FILE         = @"/Library/LaunchDaemons/gov.llnl.mp.rsync.plist";
NSString * const LAUNCHD_RSYNCD_ORIG         = @"/Library/MacPatch/Server/conf/LaunchDaemons/gov.llnl.mp.rsync.plist";

@implementation Constants

@end
