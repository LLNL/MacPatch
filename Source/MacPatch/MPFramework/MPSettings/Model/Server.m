//
//	Server.m
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

#import "Server.h"

NSString *const kServerHostname      = @"hostname";
NSString *const kServerIsproxy       = @"isproxy";
NSString *const kServerPort          = @"port";
NSString *const kServerUseclientcert = @"useclientcert";
NSString *const kServerUsessl        = @"usessl";

@interface Server ()
@end

@implementation Server

/**
 * Instantiate the instance using the passed dictionary values to set the properties values
 */

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
	self = [super init];
	if(![dictionary[kServerHostname] isKindOfClass:[NSNull class]]){
		self.hostname = dictionary[kServerHostname];
	}

	if(![dictionary[kServerIsproxy] isKindOfClass:[NSNull class]]){
		self.isproxy = [dictionary[kServerIsproxy] integerValue];
	}

	if(![dictionary[kServerPort] isKindOfClass:[NSNull class]]){
		self.port = [dictionary[kServerPort] integerValue];
	}

	if(![dictionary[kServerUseclientcert] isKindOfClass:[NSNull class]]){
		self.useclientcert = [dictionary[kServerUseclientcert] integerValue];
	}

	if(![dictionary[kServerUsessl] isKindOfClass:[NSNull class]]){
		self.usessl = [dictionary[kServerUsessl] integerValue];
	}

	return self;
}


/**
 * Returns all the available property values in the form of NSDictionary object where the key is the approperiate json key and the value is the value of the corresponding property
 */
-(NSDictionary *)toDictionary
{
	NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
	if(self.hostname != nil){
		dictionary[kServerHostname] = self.hostname;
	}
	dictionary[kServerIsproxy] = @(self.isproxy);
	dictionary[kServerPort] = @(self.port);
	dictionary[kServerUseclientcert] = @(self.useclientcert);
	dictionary[kServerUsessl] = @(self.usessl);
	return dictionary;

}

/**
 * Implementation of NSCoding encoding method
 */
/**
 * Returns all the available property values in the form of NSDictionary object where the key is the approperiate json key and the value is the value of the corresponding property
 */
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	if(self.hostname != nil){
		[aCoder encodeObject:self.hostname forKey:kServerHostname];
	}
	[aCoder encodeObject:@(self.isproxy) forKey:kServerIsproxy];
    [aCoder encodeObject:@(self.port) forKey:kServerPort];
    [aCoder encodeObject:@(self.useclientcert) forKey:kServerUseclientcert];
    [aCoder encodeObject:@(self.usessl) forKey:kServerUsessl];
}

/**
 * Implementation of NSCoding initWithCoder: method
 */
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	self.hostname = [aDecoder decodeObjectForKey:kServerHostname];
	self.isproxy = [[aDecoder decodeObjectForKey:kServerIsproxy] integerValue];
	self.port = [[aDecoder decodeObjectForKey:kServerPort] integerValue];
	self.useclientcert = [[aDecoder decodeObjectForKey:kServerUseclientcert] integerValue];
	self.usessl = [[aDecoder decodeObjectForKey:kServerUsessl] integerValue];
	return self;

}

/**
 * Implementation of NSCopying copyWithZone: method
 */
- (instancetype)copyWithZone:(NSZone *)zone
{
	Server *copy = [Server new];

	copy.hostname = [self.hostname copy];
	copy.isproxy = self.isproxy;
	copy.port = self.port;
	copy.useclientcert = self.useclientcert;
	copy.usessl = self.usessl;

	return copy;
}
@end
