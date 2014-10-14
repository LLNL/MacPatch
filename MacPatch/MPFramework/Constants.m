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

NSString * const MP_ROOT                    = @"/Library/MacPatch";
NSString * const MP_ROOT_CLIENT				= @"/Library/MacPatch/Client";
NSString * const MP_ROOT_SERVER				= @"/Library/MacPatch/Server";
NSString * const MP_ROOT_UPDATE             = @"/Library/MacPatch/Updater";

NSString * const AGENT_EXEC                 = @"/Library/MacPatch/Client/MPAgentExec";
NSString * const AGENT_VER_PLIST			= @"/Library/MacPatch/Client/.mpVersion.plist";
NSString * const AGENT_PREFS_PLIST			= @"/Library/Preferences/gov.llnl.mpagent.plist";
NSString * const AGENT_FRAMEWORK_PATH		= @"/Library/Frameworks/MPFramework.framework/Resources/Info.plist";
NSString * const AGENT_SERVERS_PLIST        = @"/Library/MacPatch/Client/lib/Servers.plist";
NSString * const APP_PREFS_PLIST			= @"/Library/Preferences/gov.llnl.MPClientStatus.plist";
NSString * const PATCHES_NEEDED_PLIST       = @"/Library/MacPatch/Client/Data/.neededPatches.plist";

NSString * const WS_CLIENT_REG              = @"/MPRegister.cfc";
NSString * const WS_CLIENT_FILE             = @"/Service/MPClientService.cfc";
NSString * const WS_SERVER_FILE             = @"/Service/MPServerService.cfc";
NSString * const WS_FAILED_REQ_PLIST        = @"/Library/MacPatch/Client/lib/WebRequests.plist";

NSString * const ASUS_BIN_PATH				= @"/usr/sbin/softwareupdate";
NSString * const ASUS_APP_PATH				= @"/System/Library/CoreServices/Software Update.app";
NSString * const ASUS_PLIST_PATH			= @"/Library/Preferences/com.apple.SoftwareUpdate.plist";

NSString * const CLIENT_PATCH_STATUS_FILE	= @"~/Library/Application Support/.mpUpdateCStatus";
NSString * const SELF_PATCH_PATH			= @"/Library/MacPatch/Client/Self Patch.app";
NSString * const MPREBOOT_APP_PATH			= @"/Library/MacPatch/Client/MPReboot.app";
NSString * const MPLOGOUT_APP_PATH			= @"/Library/MacPatch/Client/MPLogout.app";
NSString * const MPLOGOUT_BIN_PATH			= @"/Library/MacPatch/Client/MPLogout.app/Contents/MacOS/MPLogout";
NSString * const MPLOGOUT_HOOK_PLIST		= @"/var/root/Library/Preferences/com.apple.loginwindow.plist";

NSString * const SWDIST_APP_PATH            = @"/Library/MacPatch/Client/MPCatalog.app";
NSString * const MP_SWDIST_WORK_DIR			= @"/private/tmp/.mp/Data";

NSString * const SYSPROFILE_BIN_PATH		= @"/usr/sbin/system_profiler";
NSString * const INSTALLER_BIN_PATH			= @"/usr/sbin/installer";

NSString * const kMPPatchSCAN               = @".mpScanRunning";
NSString * const kMPPatchUPDATE             = @".mpUpdateRunning";
NSString * const kMPInventory               = @".mpInventoryRunning";
NSString * const kMPAVUpdate                = @".mpAVUpdateRunning";

NSString * const MP_XSD_AUDIT                = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\
<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" attributeFormDefault=\"unqualified\" elementFormDefault=\"qualified\">\
<xs:element name=\"tables\">\
<xs:complexType>\
<xs:sequence>\
<xs:element name=\"remove\" minOccurs=\"0\" maxOccurs=\"unbounded\">\
<xs:complexType>\
<xs:simpleContent>\
<xs:extension base=\"xs:string\">\
<xs:attribute type=\"xs:string\" name=\"valueEQ\"/>\
<xs:attribute type=\"xs:string\" name=\"column\"/>\
</xs:extension>\
</xs:simpleContent>\
</xs:complexType>\
</xs:element>\
<xs:element name=\"table\">\
<xs:complexType>\
<xs:sequence>\
<xs:element type=\"xs:string\" name=\"mpColReq\" minOccurs=\"0\" maxOccurs=\"unbounded\"/>\
<xs:element name=\"field\" minOccurs=\"0\" maxOccurs=\"unbounded\">\
<xs:complexType>\
<xs:simpleContent>\
<xs:extension base=\"xs:string\">\
<xs:attribute type=\"xs:string\" name=\"Increment\" use=\"optional\"/>\
<xs:attribute type=\"xs:string\" name=\"PrimaryKey\" use=\"optional\"/>\
<xs:attribute type=\"xs:string\" name=\"Default\" use=\"optional\"/>\
<xs:attribute type=\"xs:string\" name=\"ColumnName\"/>\
<xs:attribute type=\"xs:short\" name=\"Length\"/>\
<xs:attribute type=\"xs:string\" name=\"CF_DATATYPE\"/>\
</xs:extension>\
</xs:simpleContent>\
</xs:complexType>\
</xs:element>\
</xs:sequence>\
<xs:attribute type=\"xs:string\" name=\"name\"/>\
</xs:complexType>\
</xs:element>\
<xs:element name=\"data\">\
<xs:complexType>\
<xs:sequence>\
<xs:element name=\"row\" maxOccurs=\"unbounded\">\
<xs:complexType>\
<xs:sequence>\
<xs:element type=\"xs:string\" name=\"mpColRowReq\" minOccurs=\"0\" maxOccurs=\"unbounded\"/>\
<xs:element name=\"field\" minOccurs=\"0\" maxOccurs=\"unbounded\">\
<xs:complexType>\
<xs:simpleContent>\
<xs:extension base=\"xs:string\">\
<xs:attribute type=\"xs:string\" name=\"name\"/>\
<xs:attribute type=\"xs:string\" name=\"value\"/>\
</xs:extension>\
</xs:simpleContent>\
</xs:complexType>\
</xs:element>\
</xs:sequence>\
</xs:complexType>\
</xs:element>\
</xs:sequence>\
<xs:attribute type=\"xs:string\" name=\"permanentRows\"/>\
<xs:attribute type=\"xs:string\" name=\"checkFields\"/>\
<xs:attribute type=\"xs:string\" name=\"table\"/>\
<xs:attribute type=\"xs:string\" name=\"onexists\"/>\
</xs:complexType>\
</xs:element>\
</xs:sequence>\
</xs:complexType>\
</xs:element>\
</xs:schema>";


@implementation Constants

@end
