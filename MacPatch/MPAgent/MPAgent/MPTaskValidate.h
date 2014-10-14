//
//  MPTaskValidate.h
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

extern NSString * const kMPCheckIn;
extern NSString * const kMPAgentCheck;
extern NSString * const kMPVulScan;
extern NSString * const kMPVulUpdate;
extern NSString * const kMPAVCheck;
extern NSString * const kMPInvScan;
extern NSString * const kStartDate;
extern NSString * const kEndDate;

@interface MPTaskValidate : NSObject {
	
@private	
	NSDictionary *defaultTasks;
}

@property (nonatomic, strong) NSDictionary *defaultTasks;

- (int)validateTask:(NSDictionary *)aTask;
- (BOOL)validateInterval:(NSArray *)aInterval;
- (BOOL)validateStateDate:(NSString *)aStringDate;
- (BOOL)validateEndDate:(NSString *)aStringDate;
- (void)readDefaultTasks;
- (NSDictionary *)resetTaskFromDefaults:(NSString *)aCMDName;
- (NSDictionary *)updateTaskIntervalForCommand:(NSDictionary *)aTask cmd:(NSString *)aCMDName;
- (NSDictionary *)updateEndDateForTask:(NSDictionary *)aTask;
- (NSDictionary *)disableTask:(NSDictionary *)aTask;

@end
