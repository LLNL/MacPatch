//
//  TaskWrapper.h
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

@protocol TaskWrapperController

// Your controller's implementation of this method will be called when output arrives from the NSTask.
// Output will come from both stdout and stderr, per the TaskWrapper implementation.
- (void)appendOutput:(NSString *)output;

// This method is a callback which your controller can use to do other initialization when a process
// is launched.
- (void)installProcessStarted;

// This method is a callback which your controller can use to do other cleanup when a process
// is halted.
- (void)installProcessFinished;

@end

@interface TaskWrapper : NSObject {

	id              <TaskWrapperController>controller;
	NSTask          *task;
	NSDictionary	*approvedPatch;
	
	int				osMajor;
	int				osMinor;
	
	BOOL			taskIsRunning;
	int				taskResult;
	
}

@property (assign) int taskResult;
@property (nonatomic, retain) NSDictionary *approvedPatch;

- (id)initWithController:(id <TaskWrapperController>)controller patch:(NSDictionary *)aPatch;

// This method launches the process, setting up asynchronous feedback notifications.
- (void)startProcessCustomUsingDictionary:(NSDictionary *)aDict;
- (void)startProcessCustom:(NSString *)aPkg;
- (void)startProcess;

- (void)preProcessFailed;
// This method stops the process, stoping asynchronous feedback notifications.
- (void)stopProcess;

- (void)getOSVersion;
- (int)startPreCriteria;
- (int)startPostCriteria;

@end
