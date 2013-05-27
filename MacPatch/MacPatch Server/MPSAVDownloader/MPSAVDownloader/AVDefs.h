//
//  AVDefs.h
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


@interface AVDefs : NSObject {
	NSMutableDictionary		*avDefsDict;
	NSMutableArray			*avDefsDictArray;
	NSData					*rawHttpResults;
	NSString				*remoteAVURL;
	NSString				*remoteAVInfoURL;
	NSXMLDocument			*avXMLData;
	NSString				*dlFilePath;
	NSString				*dlFilePathDir;
@private
	NSString				*avTempData;
}

@property (nonatomic, retain) NSString				*remoteAVURL;
@property (nonatomic, retain) NSString				*remoteAVInfoURL;
@property (nonatomic, retain) NSString				*dlFilePath;
@property (nonatomic, retain) NSString				*dlFilePathDir;
@property (nonatomic, retain) NSMutableDictionary	*avDefsDict; 
@property (nonatomic, retain) NSMutableArray		*avDefsDictArray;
@property (nonatomic, retain) NSData				*rawHttpResults;
@property (nonatomic, retain) NSXMLDocument			*avXMLData;

@property (nonatomic, retain) NSString				*avTempData;

- (id)initWithURL:(NSURL *)theURL;
- (void)remoteAVData;
- (int)getRemoteAVDataViaFtp;
- (void)parseRemoteAVData;

- (NSArray *)itemsInCollection:(NSArray *)collection containingWord:(NSString *)word;
- (NSString *)returnAVDefsFileDate:(NSString *)avFileName;
- (NSXMLDocument *)createAVXMLDoc:(NSArray *)theArray;
- (NSString *)getFileHash:(NSString *)localFilePath hashType:(NSString *)type;

@end
