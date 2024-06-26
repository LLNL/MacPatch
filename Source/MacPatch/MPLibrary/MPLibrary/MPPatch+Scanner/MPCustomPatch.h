//
//  MPCustomPatch.h
/*
 Copyright (c) 2024, Lawrence Livermore National Security, LLC.
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

#import <Foundation/Foundation.h>

@interface MPCustomPatch : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *cuuid;
@property (nonatomic, strong) NSString *patch;
@property (nonatomic, strong, readonly) NSString *type;
@property (nonatomic, strong) NSString *patchDescription;
@property (nonatomic, strong) NSString *size;
@property (nonatomic, strong) NSString *recommended;
@property (nonatomic, strong) NSString *restart;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *patch_id;
@property (nonatomic, strong) NSString *bundleID;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)patchAsDictionary;

@end
