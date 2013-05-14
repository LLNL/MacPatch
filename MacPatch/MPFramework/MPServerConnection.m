//
//  MPServerConnection.m
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

#import "MPServerConnection.h"
#import "MPNetworkUtils.h"
#import "MPDefaults.h"

@interface MPServerConnection ()

@property (nonatomic, readwrite, retain) NSString *HTTP_PREFIX;
@property (nonatomic, readwrite, retain) NSString *HTTP_HOST;
@property (nonatomic, readwrite, retain) NSString *HTTP_HOST_PORT;
@property (nonatomic, readwrite, retain) NSString *HTTP_HOST_REACHABLE;
@property (nonatomic, readwrite, retain) NSString *MP_SOAP_URL;
@property (nonatomic, readwrite, retain) NSString *MP_JSON_URL;
@property (nonatomic, readwrite, retain) NSString *MP_JSON_URL_PLAIN;
@property (nonatomic, readwrite, retain) NSDictionary *mpConnection;
@property (nonatomic, readwrite, retain) NSDictionary *mpDefaults;


- (void)createServerObject;

@end

@implementation MPServerConnection

@synthesize HTTP_PREFIX;
@synthesize HTTP_HOST;
@synthesize HTTP_HOST_PORT;
@synthesize HTTP_HOST_REACHABLE;
@synthesize MP_SOAP_URL;
@synthesize MP_JSON_URL;
@synthesize MP_JSON_URL_PLAIN;
@synthesize mpConnection;
@synthesize mpDefaults;

- (id)init
{
    self = [super init];
    if (self) 
    {
        [self createServerObject];
    }
    return self;
}

- (id)initWithNilServerObj
{
    self = [super init];
    if (self) 
    {
        MPDefaults *mpd = [[MPDefaults alloc] init];
        [self setMpDefaults:[mpd defaults]];
        [mpd release];
    }
    return self;
}

- (void)createServerObject
{
    MPDefaults *mpd = [[MPDefaults alloc] init];
    MPNetworkUtils *mpn = [[MPNetworkUtils alloc] init];
    NSDictionary *netHostInfo = [mpn mpHostConfig];
    NSMutableDictionary *tmpInfo = [[NSMutableDictionary alloc] init];
    [tmpInfo setObject:[netHostInfo objectForKey:@"HTTP_PREFIX"] forKey:@"HTTP_PREFIX"];
    [self setHTTP_PREFIX:[netHostInfo objectForKey:@"HTTP_PREFIX"]];
    [tmpInfo setObject:[netHostInfo objectForKey:@"HTTP_HOST"] forKey:@"HTTP_HOST"];
    [self setHTTP_HOST:[netHostInfo objectForKey:@"HTTP_HOST"]];
    [tmpInfo setObject:[netHostInfo objectForKey:@"HTTP_HOST_PORT"] forKey:@"HTTP_HOST_PORT"];
    [self setHTTP_HOST_PORT:[netHostInfo objectForKey:@"HTTP_HOST_PORT"]];
    [tmpInfo setObject:[netHostInfo objectForKey:@"HTTP_HOST_REACHABLE"] forKey:@"HTTP_HOST_REACHABLE"];
    [self setHTTP_HOST_REACHABLE:[netHostInfo objectForKey:@"HTTP_HOST_REACHABLE"]];
    [tmpInfo setObject:[netHostInfo objectForKey:@"MP_SOAP_URL"] forKey:@"MP_SOAP_URL"];
    [self setMP_SOAP_URL:[netHostInfo objectForKey:@"MP_SOAP_URL"]];
    [tmpInfo setObject:[netHostInfo objectForKey:@"MP_JSON_URL"] forKey:@"MP_JSON_URL"];
    [self setMP_JSON_URL:[netHostInfo objectForKey:@"MP_JSON_URL"]];
    [tmpInfo setObject:[netHostInfo objectForKey:@"MP_JSON_URL_PLAIN"] forKey:@"MP_JSON_URL_PLAIN"];
    [self setMP_JSON_URL_PLAIN:[netHostInfo objectForKey:@"MP_JSON_URL_PLAIN"]];
    [self setMpConnection:[NSDictionary dictionaryWithDictionary:tmpInfo]];
    [self setMpDefaults:[mpd defaults]];
    [mpd release];
    [mpn release];
    [tmpInfo release];
}

- (int)refreshServerObject
{
    [self createServerObject];
    return 0;
}


@end
