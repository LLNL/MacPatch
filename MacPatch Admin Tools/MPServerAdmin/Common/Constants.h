//
//  Constants.h
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

#import <Cocoa/Cocoa.h>

// Global
extern NSString * const SITE_CONFIG;
extern NSString * const SERVER_VER_FILE;

// TOMCAT Server
extern NSString * const TOMCAT_SERVER;
extern NSString * const LAUNCHD_FILE_TOMCAT;
extern NSString * const LAUNCHD_ORIG_TOMCAT;
extern NSString * const SERVICE_TOMCAT;

// Web Server
extern NSString * const APACHE_WEBSERVER;
extern NSString * const LAUNCHD_FILE_WEBSERVER;
extern NSString * const LAUNCHD_ORIG_WEBSERVER;
extern NSString * const SERVICE_WEBSERVER;

// Web Admin Console
extern NSString * const TOMCAT_ADMIN;
extern NSString * const LAUNCHD_FILE;
extern NSString * const LAUNCHD_ORIG;
extern NSString * const SERVICE;
extern NSString * const TOMCAT_ADMIN_CONF;

// Web Service
extern NSString * const TOMCAT_WS;
extern NSString * const LAUNCHD_WS_FILE;
extern NSString * const LAUNCHD_WS_ORIG;
extern NSString * const SERVICE_WS;
extern NSString * const TOMCAT_WS_CONF;

extern NSString * const LAUNCHD_INV_FILE;
extern NSString * const LAUNCHD_INV_ORIG;
extern NSString * const SERVICE_INV;

// Software Update Sync
extern NSString * const SUS_SYNC_FILE;
extern NSString * const LAUNCHD_SUS_FILE;
extern NSString * const LAUNCHD_SUS_ORIG;
extern NSString * const SERVICE_SUS;
extern NSString * const SERVICE_SUS_CONF_FILE;

// ContenSync
extern NSString * const CONTENT_SYNC_CONF_FILE;
extern NSString * const SERVICE_CONTENT_SYNC;
extern NSString * const LAUNCHD_CONTENT_SYNC;
extern NSString * const LAUNCHD_FILE_PATCH_SYNC;
extern NSString * const LAUNCHD_ORIG_PATCH_SYNC;

// Rsyncd
extern NSString * const RSYNCD_CONF_PLIST;
extern NSString * const SERVICE_RSYNCD;
extern NSString * const LAUNCHD_RSYNCD_FILE;
extern NSString * const LAUNCHD_RSYNCD_ORIG;

@interface Constants : NSObject {

}

@end
