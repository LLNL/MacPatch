//
//  MPInstallTask.h
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

#import <Foundation/Foundation.h>

@interface MPInstallTask : NSObject {
	
	NSTask		*_task;
	
	BOOL		taskIsRunning;
	int			taskResult;
	int			taskTimeoutValue;
	
@private
	int			osMajor;
	int			osMinor;
	
	NSTimer		*_timeoutTimer;
	BOOL		taskTimedOut;
}

@property (retain) NSTimer *_timeoutTimer;
@property (nonatomic, assign) int taskTimeoutValue;
@property (nonatomic, assign) BOOL taskTimedOut;

@property (nonatomic, assign) int osMajor;
@property (nonatomic, assign) int osMinor;

- (BOOL)taskIsRunning;
- (void)setTaskIsRunning:(BOOL)flag;

- (int)taskResult;
- (void)setTaskResult:(int)aTaskResult;

- (void)getOSVersion;

- (int)installAppleSoftwareUpdate:(NSString *)approvedUpdate;
- (void)installAppleSoftwareUpdateFromDictionary:(NSDictionary *)approvedUpdate;

- (void)installPkg:(NSString *)pkgPath;

- (int)runTask:(NSString *)aBinPath binArgs:(NSArray *)aBinArgs environment:(NSDictionary *)env;
- (void)taskTimeout:(NSNotification *)aNotification;
@end
