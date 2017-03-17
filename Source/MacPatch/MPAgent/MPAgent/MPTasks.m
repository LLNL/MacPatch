//
//  MPTasks.m
/*
 Copyright (c) 2017, Lawrence Livermore National Security, LLC.
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

#import "MPTasks.h"
#import "MPTaskValidate.h"

#define MP_TASKS_PLIST				@"/Library/MacPatch/Client/.tasks/gov.llnl.mp.tasks.plist"
#define MP_TASKS_ALT_PLIST			@"/Library/MacPatch/Client/MPTasks.plist"

@implementation MPTasks

@synthesize _taskPlist;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        si = [MPAgent sharedInstance];
		if ([[NSFileManager defaultManager] fileExistsAtPath:MP_TASKS_PLIST] == NO) {
			if ([[NSFileManager defaultManager] fileExistsAtPath:[@"~/Desktop/MPTasks.plist" stringByExpandingTildeInPath]] == YES) { 
				[self set_taskPlist:[@"~/Desktop/MPTasks.plist" stringByExpandingTildeInPath]];
			} else if ([[NSFileManager defaultManager] fileExistsAtPath:MP_TASKS_ALT_PLIST] == YES) { 
				[self set_taskPlist:MP_TASKS_ALT_PLIST];	
			} else {
				[self set_taskPlist:MP_TASKS_PLIST];	
			}
		} else {
			[self set_taskPlist:MP_TASKS_PLIST];
		}	
		logit(lcl_vDebug,@"Using tasks from %@",_taskPlist);	
    }
    
    return self;
}

- (int)validateTasksPlist
{
	// Read the plist
	NSString *error;
	NSPropertyListFormat format;
	NSData *data = [NSData dataWithContentsOfFile:_taskPlist];
	NSMutableDictionary *thePlist = [NSPropertyListSerialization propertyListFromData:data 
																	 mutabilityOption:NSPropertyListImmutable 
																			   format:&format 
																	 errorDescription:&error];
	if (!thePlist) {
		logit(lcl_vError,@"Error reading plist from file '%@', error = '%@'",_taskPlist,error);
		return 1;
	} 
	
	int	w = 0;
	int i = 0;
	int x = 0;
	NSDictionary *rDict;
	NSMutableArray *_newTasks = [[NSMutableArray alloc] initWithArray:[thePlist objectForKey:@"mpTasks"]];
	MPTaskValidate *taskValidate = [[MPTaskValidate alloc] init];
	//	Return Codes
	//	0 = Valid	
	//	1 = Error, replace with default cmd
	//	2 = Invalid Interval, we will reset startdate and endate as well
	//	99 = Not a valid command type, should disable it.
	for (i=0;i<[_newTasks count]; i++) {
		x = [taskValidate validateTask:[_newTasks objectAtIndex:i]];
		if (x == 0) {
			continue;
		} else if (x == 1) {
			logit(lcl_vInfo,@"Restoring task id: %@",[[_newTasks objectAtIndex:i] objectForKey:@"id"]);
			w++;
			rDict = nil;
			rDict = [taskValidate resetTaskFromDefaults:[[_newTasks objectAtIndex:i] objectForKey:@"cmd"]];
			if (rDict) {
				[_newTasks replaceObjectAtIndex:i withObject:rDict];
			} else {
				logit(lcl_vError,@"Unable to replace %@, with default value.",[_newTasks objectAtIndex:i]);
			}
		} else if (x == 2) {
			logit(lcl_vInfo,@"Updating interval data for task id: %@",[[_newTasks objectAtIndex:i] objectForKey:@"id"]);
			logit(lcl_vDebug,@"Old:\n%@",[_newTasks objectAtIndex:i]);
			w++;
			rDict = nil;
			rDict = [taskValidate updateTaskIntervalForCommand:[_newTasks objectAtIndex:i] cmd:[[_newTasks objectAtIndex:i] objectForKey:@"cmd"]];
			logit(lcl_vDebug,@"New:\n%@",rDict);
			if (rDict) {
				[_newTasks replaceObjectAtIndex:i withObject:rDict];
			} else {
				logit(lcl_vError,@"Unable to replace %@, with default value.",[_newTasks objectAtIndex:i]);
			}
		} else if (x == 3) {
			logit(lcl_vInfo,@"Updating end date data for task id: %@",[[_newTasks objectAtIndex:i] objectForKey:@"id"]);
			logit(lcl_vDebug,@"Old:\n%@",[_newTasks objectAtIndex:i]);
			w++;
			rDict = nil;
			rDict = [taskValidate updateEndDateForTask:[_newTasks objectAtIndex:i]];
			logit(lcl_vDebug,@"New:\n%@",rDict);
			if (rDict) {
				[_newTasks replaceObjectAtIndex:i withObject:rDict];
			} else {
				logit(lcl_vError,@"Unable to replace %@, with default value.",[_newTasks objectAtIndex:i]);
			}	
		} else if (x == 99) {
			// Disable
			logit(lcl_vInfo,@"Disabling (99) task id: %@",[[_newTasks objectAtIndex:i] objectForKey:@"id"]);
			w++;
			rDict = nil;
			rDict = [taskValidate disableTask:[_newTasks objectAtIndex:i]];
			if (rDict) {
				[_newTasks replaceObjectAtIndex:i withObject:rDict];
			} else {
				logit(lcl_vError,@"Unable to replace %@, with default value.",[_newTasks objectAtIndex:i]);
			}
		} else {
			// Disable
			logit(lcl_vInfo,@"Disabling task id: %@",[[_newTasks objectAtIndex:i] objectForKey:@"id"]);
			w++;
			rDict = nil;
			rDict = [taskValidate disableTask:[_newTasks objectAtIndex:i]];
			if (rDict) {
				[_newTasks replaceObjectAtIndex:i withObject:rDict];
			} else {
				logit(lcl_vError,@"Unable to replace %@, with default value.",[_newTasks objectAtIndex:i]);
			}
		}
	}
	// Write out new/updated tasks file
	if (w > 0) {
		logit(lcl_vDebug,@"Writting out new tasks file.\n%@",_newTasks);
		NSDictionary *_updatedDict = [NSDictionary dictionaryWithObject:_newTasks forKey:@"mpTasks"];
		[_updatedDict writeToFile:MP_TASKS_PLIST atomically:YES];
	}
	return 0;
}

- (void)readAndSetTasksFromPlist
{
	[self validateTasksPlist];
	
	NSDictionary *result = nil;
	NSFileManager *fm = [NSFileManager defaultManager];
	// See if the plist exists
	if ([fm fileExistsAtPath:_taskPlist] == NO)
	{
		logit(lcl_vError,@"Error plist file '%@' does not exist.",_taskPlist);
		return;
	}
	
	// Read the plist
	NSString *error;
	NSPropertyListFormat format;
	NSData *data = [NSData dataWithContentsOfFile:_taskPlist];
	NSMutableDictionary *thePlist = [NSPropertyListSerialization propertyListFromData:data 
																	 mutabilityOption:NSPropertyListImmutable 
																			   format:&format 
																	 errorDescription:&error];
	if (!thePlist) {
		logit(lcl_vError,@"Error reading plist from file '%@', error = '%@'",_taskPlist,error);
		return;
	} 
	
	result = [NSDictionary dictionaryWithDictionary:thePlist];
	[self loadTasks:[result objectForKey:@"mpTasks"]];
}

- (void)updateTasksPlist
{
    NSDictionary *tmpDict = [NSDictionary dictionaryWithObject:[si g_Tasks] forKey:@"tasks"];
	@try {
		[tmpDict writeToFile:_taskPlist atomically:YES];
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"Error updating config plist, %@",_taskPlist);
	}
}

- (void)loadTasks:(NSArray *)aTasks
{
	NSMutableArray *tmpArr = [[NSMutableArray alloc] init];
	NSMutableDictionary *tmpDict;
	int i = 0;
	double sd, ed = 0;
	for (i=0;i<[aTasks count];i++)
	{
		tmpDict = [[NSMutableDictionary alloc] initWithDictionary:[aTasks objectAtIndex:i]];
		sd = [[NSDate shortDateFromString:[tmpDict objectForKey:@"startdate"]] timeIntervalSince1970];
		ed = [[NSDate shortDateFromString:[tmpDict objectForKey:@"enddate"]] timeIntervalSince1970];
		[tmpDict setObject:[NSNumber numberWithDouble:sd] forKey:@"startDateInt"];
		[tmpDict setObject:[NSNumber numberWithDouble:ed] forKey:@"endDateInt"];
		[tmpArr addObject:[self genNextRunAt:tmpDict]];
		logit(lcl_vDebug,@"Task loaded: %@",tmpDict);
		tmpDict = nil;
	}
    [si setG_Tasks:tmpArr];
}

- (NSDictionary *)genNextRunAt:(NSDictionary *)aTask
{
	NSString *_dt = nil;
	NSMutableDictionary *tmpDict = nil;
	tmpDict = [[NSMutableDictionary alloc] initWithDictionary:aTask];
	//unsigned int next_run = 0;
	double next_run = 0;
	
	/* Once@Time; Recurring@Daily,Weekly,Monthly@Time;Every@seconds */
	NSArray *intervalArray = [[tmpDict objectForKey:@"interval"] componentsSeparatedByString:@"@"];
	
	// Check length and nulls
	if ([intervalArray count] >= 2) {
		// Validate Interval Attribute, if fail set to default value
		if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPCheckIn"]) {
			if ([intervalArray count] == 2) {
				if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
					[tmpDict setObject:@"Every@900" forKey:@"interval"];
				}
			} else if ([intervalArray count] == 3) {
				[tmpDict setObject:@"Every@900" forKey:@"interval"];
			}
		} else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPAgentCheck"]) {
			if ([intervalArray count] == 2) {
				if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
					[tmpDict setObject:@"Every@3600" forKey:@"interval"];
				}
			} else if ([intervalArray count] == 3) {
				[tmpDict setObject:@"Every@3600" forKey:@"interval"];
			}
		} else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPVulScan"]) {
			if ([intervalArray count] == 3) {
				if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL || [intervalArray objectAtIndex:2] == NULL) {
					[tmpDict setObject:@"RECURRING@Daily@12:00:00" forKey:@"interval"];
				}
			} else {
				[tmpDict setObject:@"RECURRING@Daily@12:00:00" forKey:@"interval"];
			}
		} else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPVulUpdate"]) {
			if ([intervalArray count] == 3) {
				if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL || [intervalArray objectAtIndex:2] == NULL) {
					[tmpDict setObject:@"RECURRING@Daily@12:30:00" forKey:@"interval"];
				}
			} else {
				[tmpDict setObject:@"RECURRING@Daily@12:30:00" forKey:@"interval"];
			}
		} else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPAVCheck"]) {
			if ([intervalArray count] == 2) {
				if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
					[tmpDict setObject:@"EVERYRAND@14400" forKey:@"interval"];
				}
			} else if ([intervalArray count] == 3) {
				[tmpDict setObject:@"EVERYRAND@14400" forKey:@"interval"];
			}
        } else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPAVInfo"]) {
			if ([intervalArray count] == 2) {
				if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
					[tmpDict setObject:@"EVERYRAND@1800" forKey:@"interval"];
				}
			} else if ([intervalArray count] == 3) {
				[tmpDict setObject:@"EVERYRAND@14400" forKey:@"interval"];
			}
		} else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPInvScan"]) {
			if ([intervalArray count] == 2) {
				if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
					[tmpDict setObject:@"EVERY@21600" forKey:@"interval"];
				}
			} else if ([intervalArray count] == 3) {
				[tmpDict setObject:@"EVERY@21600" forKey:@"interval"];
			}
		} else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPProfiles"]) {
			if ([intervalArray count] == 2) {
				if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
					[tmpDict setObject:@"EVERY@1800" forKey:@"interval"];
				}
			} else if ([intervalArray count] == 3) {
				[tmpDict setObject:@"EVERY@1800" forKey:@"interval"];
			}
        }  else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPSrvList"]) {
            if ([intervalArray count] == 2) {
                if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
                    [tmpDict setObject:@"EVERY@600" forKey:@"interval"];
                }
            } else if ([intervalArray count] == 3) {
                [tmpDict setObject:@"EVERY@600" forKey:@"interval"];
            }
        }  else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPSUSrvList"]) {
            if ([intervalArray count] == 2) {
                if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
                    [tmpDict setObject:@"EVERY@900" forKey:@"interval"];
                }
            } else if ([intervalArray count] == 3) {
                [tmpDict setObject:@"EVERY@900" forKey:@"interval"];
            }
        }  else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPAppStore"]) {
            if ([intervalArray count] == 2) {
                if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
                    [tmpDict setObject:@"EVERY@7200" forKey:@"interval"];
                }
            } else if ([intervalArray count] == 3) {
                [tmpDict setObject:@"EVERY@900" forKey:@"interval"];
            }
        } else if ([[tmpDict objectForKey:@"cmd"] isEqualToString:@"kMPPatchCrit"]) {
            if ([intervalArray count] == 2) {
                if ([intervalArray objectAtIndex:0] == NULL || [intervalArray objectAtIndex:1] == NULL) {
                    [tmpDict setObject:@"EVERY@1800" forKey:@"interval"];
                }
            } else if ([intervalArray count] == 3) {
                [tmpDict setObject:@"EVERY@1800" forKey:@"interval"];
            }
        }
        
	} else {
		logit(lcl_vError,@"Could not validate interval. Not enough arguments (%@)",[tmpDict objectForKey:@"interval"]);
		logit(lcl_vError,@"Changing task (%@) state to inactive.",[tmpDict objectForKey:@"name"]);
		[tmpDict setObject:@"0" forKey:@"active"];
		NSDictionary *results = [NSDictionary dictionaryWithDictionary:tmpDict];
		tmpDict = nil;
		
		return results;	
	}
	
	if ([[[intervalArray objectAtIndex:0] uppercaseString] isEqualToString:@"EVERY"]) 
	{
		next_run = (double)[[NSDate date] timeIntervalSince1970] + [[intervalArray objectAtIndex:1] intValue];
	} 
	else if ([[[intervalArray objectAtIndex:0] uppercaseString] isEqualToString:@"EVERYRAND"]) 
	{
		int r = arc4random() % [[intervalArray objectAtIndex:1] intValue];
		next_run = (double)[[NSDate date] timeIntervalSince1970] + r;
	}
	else if ([[[intervalArray objectAtIndex:0] uppercaseString] isEqualToString:@"RECURRING"]) 
	{
		_dt = [NSString stringWithFormat:@"%@ %@",[NSDate stringFromDate:[NSDate now] withFormat:@"yyyy-MM-dd"],[intervalArray objectAtIndex:2]]; // Default for Daily
		
		if ([[[intervalArray objectAtIndex:1] uppercaseString] isEqualToString:@"DAILY"]) 
		{
			if (![tmpDict objectForKey:@"nextrun"]) {
				// If Less than right now ...
				logit(lcl_vTrace,@"%ld < %ld",(long)[[NSDate dateFromString:_dt] timeIntervalSince1970], (long)[[NSDate date] timeIntervalSince1970]);
				if ([[NSDate dateFromString:_dt] timeIntervalSince1970] > [[NSDate date] timeIntervalSince1970]) {
					next_run = 	(double)[[NSDate dateFromString:_dt] timeIntervalSince1970];
				} else {
					next_run = [[NSDate addDayToInterval:[[NSDate dateFromString:_dt] timeIntervalSince1970]] timeIntervalSince1970];
				}
			} else {
				next_run = [[NSDate addDayToInterval:[[tmpDict objectForKey:@"nextrun"] intValue]] timeIntervalSince1970];
			}
		}
		else if ([[[intervalArray objectAtIndex:1] uppercaseString] isEqualToString:@"WEEKLY"]) 
		{
			NSString *_sdt = [NSString stringWithFormat:@"%@ %@",[tmpDict objectForKey:@"startdate"],[intervalArray objectAtIndex:2]];
			if (![tmpDict objectForKey:@"nextrun"]) {
				// If Less than right now ...
				if ([[NSDate dateFromString:_sdt] timeIntervalSince1970] > [[NSDate date] timeIntervalSince1970]) {
					next_run = (double)[[NSDate dateFromString:_dt] timeIntervalSince1970];
				} else {
					next_run = [[[NSDate date] weeklyNextRun:[NSDate dateWithSQLDateString:_sdt]] timeIntervalSince1970];
				}
			} else {
				next_run = [[[NSDate date] weeklyNextRun:[NSDate dateWithSQLDateString:_sdt]] timeIntervalSince1970];
			}
		}
		else if ([[[intervalArray objectAtIndex:1] uppercaseString] isEqualToString:@"MONTHLY"]) 
		{
			NSString *_sdt = [NSString stringWithFormat:@"%@ %@",[tmpDict objectForKey:@"startdate"],[intervalArray objectAtIndex:2]];
			if (![tmpDict objectForKey:@"nextrun"]) {
				// If Less than right now ...
				if ([[NSDate dateFromString:_dt] timeIntervalSince1970] > [[NSDate date] timeIntervalSince1970]) {
					next_run = 	(double)[[NSDate dateFromString:_dt] timeIntervalSince1970];
				} else {
					next_run = [[[NSDate date] monthlyNextRun:[NSDate dateWithSQLDateString:_sdt]] timeIntervalSince1970];
				}
			} else {
				next_run = [[[NSDate date] monthlyNextRun:[NSDate dateWithSQLDateString:_sdt]] timeIntervalSince1970];
			}
		} else {
			logit(lcl_vError,@"Configuration error. RECURRING value will be set to \"Daily\".");
			if (![tmpDict objectForKey:@"nextrun"]) {
				// If Less than right now ...
				if ([[NSDate dateFromString:_dt] timeIntervalSince1970] > [[NSDate date] timeIntervalSince1970]) {
					next_run = 	(double)[[NSDate dateFromString:_dt] timeIntervalSince1970];
				} else {
					next_run = [[NSDate addDayToInterval:[[NSDate dateFromString:_dt] timeIntervalSince1970]] timeIntervalSince1970];
				}
			} else {
				next_run = [[NSDate addDayToInterval:[[tmpDict objectForKey:@"nextrun"] intValue]] timeIntervalSince1970];
			}
		}

	}
	else if ([[[intervalArray objectAtIndex:0] uppercaseString] isEqualToString:@"ONCE"]) 
	{
		next_run = [[tmpDict objectForKey:@"nextrun"] doubleValue]; // Leave the value as is
		if ([[tmpDict objectForKey:@"nextrun"] doubleValue] < [[NSDate date] timeIntervalSince1970])
		{
			[tmpDict setObject:@"0" forKey:@"active"]; // Disable the task
		}
	}
	logit(lcl_vInfo,@"%@ next run at %@",[tmpDict objectForKey:@"name"],[[NSDate dateWithTimeIntervalSince1970:next_run] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"
																																			  timeZone:[NSTimeZone localTimeZone]
																																				locale:nil]);

	[tmpDict setObject:[NSNumber numberWithDouble:next_run] forKey:@"nextrun"];
	NSDictionary *results = [NSDictionary dictionaryWithDictionary:tmpDict];
	tmpDict = nil;
	
	return results;
}

- (void)updateTaskRunAt:(NSString *)aTaskID
{
	NSMutableDictionary *tmpDict;
	int i = 0;
	double next_run = 0;
	for (i=0;i<[[si g_Tasks] count];i++)
	{
		tmpDict = [[NSMutableDictionary alloc] initWithDictionary:[[si g_Tasks] objectAtIndex:i]];
		if ([[tmpDict objectForKey:@"id"] isEqualToString:aTaskID])
		{
			/* Once@Time; Recurring@Daily,Weekly,Monthly@Time;Every@seconds */
			NSArray *intervalArray = [[tmpDict objectForKey:@"interval"] componentsSeparatedByString:@"@"];
			if ([[[intervalArray objectAtIndex:0] uppercaseString] isEqualToString:@"EVERY"]) 
			{
				next_run = [[tmpDict objectForKey:@"nextrun"] doubleValue] + [[intervalArray objectAtIndex:1] intValue];
			} 
			else if ([[[intervalArray objectAtIndex:0] uppercaseString] isEqualToString:@"EVERYRAND"]) 
			{
				int r = arc4random() % [[intervalArray objectAtIndex:1] intValue];
				next_run = [[tmpDict objectForKey:@"nextrun"] doubleValue] + r;
			}
			else if ([[[intervalArray objectAtIndex:0] uppercaseString] isEqualToString:@"RECURRING"]) 
			{
				if ([[[intervalArray objectAtIndex:1] uppercaseString] isEqualToString:@"DAILY"]) 
				{
					next_run = [[NSDate addDayToInterval:[[tmpDict objectForKey:@"nextrun"] doubleValue]] timeIntervalSince1970];
				}
				else if ([[[intervalArray objectAtIndex:1] uppercaseString] isEqualToString:@"WEEKLY"]) 
				{
					next_run = [[NSDate addWeekToInterval:[[tmpDict objectForKey:@"nextrun"] doubleValue]] timeIntervalSince1970];
				}
				else if ([[[intervalArray objectAtIndex:1] uppercaseString] isEqualToString:@"MONTHLY"]) 
				{
					next_run = [[NSDate addMonthToInterval:[[tmpDict objectForKey:@"nextrun"] doubleValue]] timeIntervalSince1970];
				}
			}
			else if ([[[intervalArray objectAtIndex:0] uppercaseString] isEqualToString:@"ONCE"]) 
			{
				next_run = [[tmpDict objectForKey:@"nextrun"] doubleValue]; // Leave the value as is
				if ([[tmpDict objectForKey:@"nextrun"] doubleValue] < [[NSDate date] timeIntervalSince1970])
				{
					[tmpDict setObject:@"0" forKey:@"active"]; // Disable the task
				}
			}
			
			logit(lcl_vInfo,@"%@ next run at %@",[tmpDict objectForKey:@"name"],[[NSDate dateWithTimeIntervalSince1970:next_run] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"
																																					  timeZone:[NSTimeZone localTimeZone]
																																						locale:nil]);
			[tmpDict setObject:[NSNumber numberWithDouble:next_run] forKey:@"nextrun"];
			[[si g_Tasks] replaceObjectAtIndex:i withObject:[NSDictionary dictionaryWithDictionary:tmpDict]];
			tmpDict = nil;
			break;
		}
		tmpDict = nil;	 
	}
	
	
}

- (void)updateMissedTaskRunAt:(NSString *)aTaskID
{
	NSMutableDictionary *tmpDict;
	NSDate *d = [NSDate now];

	int i = 0;
	unsigned int x = (int)[d timeIntervalSince1970];
	x = x + 30; // Add 30 seconds
	for (i=0;i<[[si g_Tasks] count];i++)
	{
		tmpDict = [[NSMutableDictionary alloc] initWithDictionary:[[si g_Tasks] objectAtIndex:i]];
		if ([[tmpDict objectForKey:@"id"] isEqualToString:aTaskID])
		{
			[tmpDict setObject:[NSNumber numberWithInt:x] forKey:@"nextrun"];
			[[si g_Tasks] replaceObjectAtIndex:i withObject:[NSDictionary dictionaryWithDictionary:tmpDict]];
			tmpDict = nil;
			break;
		}
		tmpDict = nil;	 
	}
}

# pragma mark Date Methods
- (NSInteger)weekDayFromDate:(NSDate *)aDate
{
	NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [gregorianCal components:NSWeekdayCalendarUnit fromDate:aDate];
	NSInteger dateWeekDay = [components weekday];
	return dateWeekDay;
}

- (NSDate *)weeklyNextRun:(NSDate *)startDate
{
	NSDate *today = [[NSDate alloc] init];
	NSInteger startDateWeekDay = [self weekDayFromDate:startDate];
	NSInteger todayWeekDay = [self weekDayFromDate:today];
	NSInteger daysToAdd = 0;
	
	if (startDateWeekDay == todayWeekDay)
	{
		daysToAdd = 7;
	}
	else if (startDateWeekDay < todayWeekDay ) 
	{
		daysToAdd = (7 - (todayWeekDay - startDateWeekDay));
	}
	else if (startDateWeekDay > todayWeekDay ) 
	{
		daysToAdd = (startDateWeekDay - todayWeekDay);
	}
	
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setDay:daysToAdd];
	
	NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDate *newDate = [gregorianCal dateByAddingComponents:components toDate:today options:0];
	
	return newDate;
}

@end
