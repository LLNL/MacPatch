//
//  MPSWTasks.m
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

#import "MPSWTasks.h"
#import "MPServerConnection.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"

@interface MPSWTasks () 

@end

@implementation MPSWTasks

@synthesize mpHostConfigInfo;

@synthesize groupHash;
@synthesize groupName;

- (id)init
{
    return [self initWithGroupAndHash:nil hash:@"NA"];
}

- (id)initWithGroupAndHash:(NSString *)aGroup hash:(NSString *)aHash;
{
    self = [super init];
    if (self)
    {
        mpServerConnection = [[MPServerConnection alloc] init];
        [self setMpHostConfigInfo:[mpServerConnection mpConnection]];


        if (aGroup) {
            [self setGroupName:aGroup];
        } else {
            if ([mpServerConnection.mpDefaults objectForKey:@"SWDistGroup"]) {
                [self setGroupName:[mpServerConnection.mpDefaults objectForKey:@"SWDistGroup"]];
            } else {
                [self setGroupName:@"NA"];
            }
        }    
        [self setGroupHash:aHash];
    }
    return self;
}

- (void)dealloc 
{
    [groupHash release];
    groupHash = nil;
    [groupName release];
    groupName = nil;
    [mpServerConnection release];
    [super dealloc];
}

- (void)main 
{
    NSError *error = nil;
    NSString *_remoteGroupHash = nil;
    _remoteGroupHash = [self getHashForGroup:&error];
    if (error) {
        qlerror(@"Error [getHashForGroup]: %@",[error description]);
        return;
    }
    
    if ([groupHash isEqualTo:NULL] || ([groupHash isEqualToString:_remoteGroupHash] == NO)) {
        error = nil;
        id jResult = [self getSWTasksForGroupFromServer:&error]; 
        if (error) {
            qlerror(@"Error [getSWTasksForGroupFromServer]: %@",[error description]);
            return;
        }
        if (jResult != nil) {
            [jResult writeToFile:[NSString stringWithFormat:@"%@/Data/.swTasks.plist",MP_ROOT_CLIENT] 
                      atomically:YES 
                        encoding:NSUTF8StringEncoding error:NULL];
        }
    }
    
}

- (NSString *)getHashForGroup:(NSError **)err
{
    NSString *result = @"NA";
    NSDictionary *jsonResult = nil;
    // Create JSON Request URL
	NSString *urlString = [NSString stringWithFormat:@"%@?method=GetSoftwareTasksForGroupHash&GroupName=%@",mpServerConnection.MP_JSON_URL,groupName];
    qldebug(@"JSON URL: %@",urlString);
    
	// Create http request
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
	[request setValidatesSecureCertificate:NO];	
	[request setTimeOutSeconds:120];
	[request startSynchronous];
	
	NSDictionary *userInfoDict;
	NSError *error = [request error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp" code:[error code]  userInfo:userInfoDict];
		qlerror(@"%@",[error localizedDescription]);
		goto done;
	}
    
    error = nil;
    jsonResult = [[request responseString] objectFromJSONStringWithParseOptions:JKParseOptionNone error:&error];
    if (error) {
        userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp" code:[error code]  userInfo:userInfoDict];
        qlerror(@"%@",[error localizedDescription]);
        goto done;
    }
    
done:
    if (!jsonResult) {
        return result;
    } else {
        // First Check to make sure we have the errorno object and then check to 
        // see if the return value is 0, else error.
        if ([jsonResult hasKey:@"errorno"]) {
            if ([[jsonResult objectForKey:@"errorno"] integerValue] != 0) {
                userInfoDict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Error[%d]: %@",(int)[jsonResult objectForKey:@"errorno"],[jsonResult objectForKey:@"errormsg"]] forKey:NSLocalizedDescriptionKey];
                if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp" code:(int)[jsonResult objectForKey:@"errorno"]  userInfo:userInfoDict];
                qlerror(@"%@",[userInfoDict objectForKey:NSLocalizedDescriptionKey]);
                return result;
            }
        }
        // Now that the error code is 0, lets try and read the result
        // Does it have the right key?
        if ([jsonResult hasKey:@"result"]) {
            if ([[jsonResult objectForKey:@"result"] hasKey:@"hash"]) {
                userInfoDict = [NSDictionary dictionaryWithObject:@"\"hash\" key is missing." forKey:NSLocalizedDescriptionKey];
                if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp" code:1  userInfo:userInfoDict];
                qlerror(@"%@",[userInfoDict objectForKey:NSLocalizedDescriptionKey]);
                return result;   
            } else {
                result = [[jsonResult objectForKey:@"result"] objectForKey:@"hash"];
            }
        }
    }
    
    qldebug(@"Result: %@",result);
    return result;    
}

- (id)getSWTasksForGroupFromServer:(NSError **)err
{
    id result = nil;
    NSDictionary *userInfoDict;
    NSDictionary *jsonResult = nil;
    // Create JSON Request URL
    NSString *urlString = [NSString stringWithFormat:@"%@?method=GetSoftwareTasksForGroup&GroupName=%@",mpServerConnection.MP_JSON_URL,groupName];
    qldebug(@"JSON URL: %@",urlString);
    
	// Create http request
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
	[request setValidatesSecureCertificate:NO];	
	[request setTimeOutSeconds:120];
	[request startSynchronous];
	
	NSError *error = [request error];
	if (error) {
		userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp" code:[error code]  userInfo:userInfoDict];
		qlerror(@"%@",[error localizedDescription]);
		goto done;
	}
    
    error = nil;
    jsonResult = [[request responseString] objectFromJSONStringWithParseOptions:JKParseOptionNone error:&error];
    if (error) {
        userInfoDict = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
        if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp" code:[error code]  userInfo:userInfoDict];
        qlerror(@"%@",[error localizedDescription]);
        goto done;
    }
	
done:
    if (!jsonResult) {
        return result;
    } else {
        // First Check to make sure we have the errorno object and then check to 
        // see if the return value is 0, else error.
        if ([jsonResult hasKey:@"errorno"]) {
            if ([[jsonResult objectForKey:@"errorno"] integerValue] != 0) {
                userInfoDict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Error[%d]: %@",(int)[jsonResult objectForKey:@"errorno"],[jsonResult objectForKey:@"errormsg"]] forKey:NSLocalizedDescriptionKey];
                if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp" code:(int)[jsonResult objectForKey:@"errorno"]  userInfo:userInfoDict];
                qlerror(@"%@",[userInfoDict objectForKey:NSLocalizedDescriptionKey]);
                return result;
            }
        }
        // Now that the error code is 0, lets try and read the result
        // Does it have the right key?
        if ([jsonResult hasKey:@"result"]) {
            result = [jsonResult objectForKey:@"result"];
        } else {
            userInfoDict = [NSDictionary dictionaryWithObject:@"\"result\" key is missing." forKey:NSLocalizedDescriptionKey];
            if (err != NULL) *err = [NSError errorWithDomain:@"gov.llnl.mp" code:1  userInfo:userInfoDict];
            qlerror(@"%@",[userInfoDict objectForKey:NSLocalizedDescriptionKey]);
            return result;   
        }
        
        // Todo, set hash value of result. So, that the next time it's run it uses the last known value.
        // Or just use alt method and do  validation.
    }
    
    qldebug(@"Result: %@",result);
    return result;
}

- (int)postInstallResults:(int)resultNo resultText:(NSString *)resultString task:(NSDictionary *)taskDict
{
    NSString *urlString = [NSString stringWithFormat:@"%@",mpServerConnection.MP_JSON_URL];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:urlString]];
    logit(lcl_vDebug,@"POST JSON Result:%@",urlString);
    [request setUserAgent:@"MacPatchAgent"];
    [request setPostValue:@"PostSoftwareInstallResults" forKey:@"method"];
    [request setPostValue:@"json" forKey:@"type"];
    [request setPostValue:[MPSystemInfo clientUUID] forKey:@"ClientID"];
    [request setPostValue:[taskDict objectForKey:@"id"] forKey:@"SWTaskID"];
    [request setPostValue:[taskDict valueForKeyPath:@"Software.sid"] forKey:@"SWDistID"];
    [request setPostValue:[NSNumber numberWithInt:resultNo] forKey:@"ResultNo"];
    [request setPostValue:resultString forKey:@"ResultString"];
    [request setPostValue:@"i" forKey:@"Action"];
    [request setValidatesSecureCertificate:NO];	
    [request setTimeOutSeconds:15];
    [request startSynchronous];
    
    NSString *requestString;
    requestString = [request responseString];
    qldebug(@"POST JSON Result:%@",requestString);
     
     if ([request responseStatusCode] == 0) {
         // Need to parse results to see if the error code is 0
         return 0;
     } else {
         return 1;
     }
}

- (int)postUnInstallResults:(int)resultNo resultText:(NSString *)resultString task:(NSDictionary *)taskDict
{
    NSString *urlString = [NSString stringWithFormat:@"%@",mpServerConnection.MP_JSON_URL];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:urlString]];
    logit(lcl_vDebug,@"POST JSON Result:%@",urlString);
    [request setUserAgent:@"MacPatchAgent"];
    [request setPostValue:@"PostSoftwareInstallResults" forKey:@"method"];
    [request setPostValue:@"json" forKey:@"type"];
    [request setPostValue:[MPSystemInfo clientUUID] forKey:@"ClientID"];
    [request setPostValue:[taskDict objectForKey:@"id"] forKey:@"SWTaskID"];
    [request setPostValue:[taskDict valueForKeyPath:@"Software.sid"] forKey:@"SWDistID"];
    [request setPostValue:[NSNumber numberWithInt:resultNo] forKey:@"ResultNo"];
    [request setPostValue:resultString forKey:@"ResultString"];
    [request setPostValue:@"u" forKey:@"Action"];
    [request setValidatesSecureCertificate:NO];	
    [request setTimeOutSeconds:15];
    [request startSynchronous];
    
    NSString *requestString;
    requestString = [request responseString];
    qldebug(@"POST JSON Result:%@",requestString);
    
    if ([request responseStatusCode] == 0) {
        // Need to parse results to see if the error code is 0
        return 0;
    } else {
        return 1;
    }
}

@end
