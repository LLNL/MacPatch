//
//  MPNetUtils.m
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

#import "MPNetUtils.h"
#include <CoreFoundation/CoreFoundation.h>
#include <SystemConfiguration/SCNetworkReachability.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <poll.h>

#undef  ql_component
#define ql_component lcl_cMPNetUtils

#define DEFAULT_TIMEOUT 3
static int isalive(struct sockaddr_in scanaddr);

static NSString *SOAP_CONTROLLER_FILE = @"MPWSControllerCocoa.cfc";
static NSString *JSON_CONTROLLER_FILE = @"Services/MPWSControllerCocoa.cfc";

@implementation MPNetUtils

static int isalive(struct sockaddr_in scanaddr)
{
    short int sock;          /* our main socket */
    long arg;                /* for non-block */
    fd_set wset;             /* file handle for bloc mode */
    struct timeval timeout;  /* timeout struct for connect() */
    
    sock = -1;
    
    sock = socket(AF_INET, SOCK_STREAM, 0);
    
    if( (arg = fcntl(sock, F_GETFL, NULL)) < 0) { 
        fprintf(stderr,"Error fcntl(..., F_GETFL) (%s)\n",strerror(errno));
        return 1;
    }
    
    arg |= O_NONBLOCK;
    if(fcntl(sock, F_SETFL, arg) < 0) {
        fprintf(stderr,"Error fcntl(..., F_SETFL)  (%s)\n",strerror(errno));
        return 1;
    }
    
    /* 
     * set result stat then try a select if it can take
     * awhile. This is dirty but works 
     */
    int res = connect(sock,(struct sockaddr *)&scanaddr, sizeof(scanaddr));
    
    if (res < 0) {
        if (errno == EINPROGRESS) {
            timeout.tv_sec = DEFAULT_TIMEOUT;
            timeout.tv_usec = 0;
            FD_ZERO(&wset);
            FD_SET(sock, &wset);
            int rc = select(sock + 1, NULL, &wset, NULL, &timeout);
            
            /* This works great on dead hosts */
            if (rc == 0 && errno != EINTR) {
                //printf("Error connecting\n");
                close (sock);
                return 1;
            }
        }
    }
    
    close(sock);
    return 0;
}

#pragma -


+ (BOOL)isHostReachable:(NSString *)aHost
{
	BOOL isValid, result = 0;
	const char *host = [aHost UTF8String];
    
    SCNetworkConnectionFlags flags = 0;
    isValid = SCNetworkCheckReachabilityByName(host, &flags);
    if (isValid && ((flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired))) 
    {
        result = YES;
    }
	
	return result;    
}

+ (BOOL)isHostURLReachable:(NSString *)aURL
{
	BOOL isValid, result = 0;
	
	NSURL *theURL = [NSURL URLWithString:aURL];
	const char *host = [[theURL host] UTF8String];
    
    SCNetworkConnectionFlags flags = 0;
    isValid = SCNetworkCheckReachabilityByName(host, &flags);
    if (isValid && ((flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired))) 
    {
        result = YES;
    }
	
	return result;    
}

+ (BOOL)isURLValid:(NSString *)aURL returnCode:(int)aReturnCode
{
	BOOL result = 0;
	NSURL *theURL = [NSURL URLWithString:aURL];
	NSURLRequest *request = [NSURLRequest requestWithURL:theURL];
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	int statusCode = (int)[((NSHTTPURLResponse *)response) statusCode];
	
	if (statusCode == aReturnCode) {
		result = YES;
	} else {
		result = NO;
	}
	
	return result;
}

+(BOOL)isPortReachable:(int)aPort host:(NSString *)aHost
{
	BOOL result = NO;
	@try {
		const char *addr = [aHost cStringUsingEncoding:NSASCIIStringEncoding];
		
		short int sock = -1;        /* the socket descriptor */
		struct hostent *host_info;  /* host info structure */
		struct sockaddr_in address; /* address structures */
		
		bzero((char *)&address, sizeof(address));  /* init addr struct */
		address.sin_addr.s_addr = inet_addr(addr); /* assign the address */
		address.sin_port = htons(aPort);            /* translate int2port num */
		
		/* Hostname resolution */
		if ((host_info = gethostbyname(addr))) {
			bcopy(host_info->h_addr,(char *)&address.sin_addr,host_info->h_length);
		} else if ((address.sin_addr.s_addr = inet_addr(addr)) == INADDR_NONE) {
			qlinfo(@"Could not resolve host, %@",aHost);
			goto done;
		}
		
		if (isalive(address)) {
			result = NO;
			goto done;
		}
		
		/* So far so good - the host exists and is up; check the port and report */
		close (sock);
		sock = socket(AF_INET, SOCK_STREAM, 0);
		if (connect(sock,(struct sockaddr *)&address,sizeof(address)) == 0) {
			//printf("%i is open on %s\n", port, argv[2]);
			result = YES;
		} else {
			//printf("%i is not open on %s\n", port, argv[2]);
			qlinfo(@"%d is not open on %@",aPort,aHost);
		}
		
		close(sock);
	}
	@catch (NSException * e) {
		qlerror(@"%@",[e description]);
	}

done:
	return result;
}

+(BOOL)pingHostWithPort:(NSString *)aHost port:(int)aPort
{
	if ([MPNetUtils isHostReachable:aHost] == NO) {
		return NO;
	}
	if ([MPNetUtils isPortReachable:aPort host:aHost] == NO) {
		return NO;
	}
	// The only way I got here is if both were true
	return YES;
}

+ (NSDictionary *)mpHostConfig
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:AGENT_PLIST]) {
        NSDictionary *_defaults = [NSDictionary dictionaryWithContentsOfFile:AGENT_PLIST];
        return [MPNetUtils mpHostConfig:_defaults];
    } else {
        qlerror(@"Error, %@ was not found.", AGENT_PLIST);
        return nil;
    }
}

+ (NSDictionary *)mpHostConfig:(NSDictionary *)aDefaults
{
	BOOL mpHostIsReachable = NO;
	NSString *aHOST = @"127.0.0.1";
	NSString *aPORT = @"2600";
	NSString *HTTP_PREFIX = @"http";
	
	NSMutableDictionary *_res = [NSMutableDictionary dictionary];
	[_res setObject:HTTP_PREFIX forKey:@"HTTP_PREFIX" defaultObject:@"http"];
	[_res setObject:aHOST forKey:@"HTTP_HOST" defaultObject:@"127.0.0.1"];
	[_res setObject:aPORT forKey:@"HTTP_HOST_PORT" defaultObject:@"2600"];	
	[_res setObject:aPORT forKey:@"HTTP_HOST_REACHABLE" defaultObject:[NSNumber numberWithBool:mpHostIsReachable]];	
	[_res setObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@/%@",HTTP_PREFIX,aHOST,aPORT,SOAP_CONTROLLER_FILE]] forKey:@"MP_SOAP_URL"];
	[_res setObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@/%@",HTTP_PREFIX,aHOST,aPORT,JSON_CONTROLLER_FILE]] forKey:@"MP_JSON_URL"];
	[_res setObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@",HTTP_PREFIX,aHOST,aPORT]] forKey:@"MP_JSON_URL_PLAIN"];
	
	if (!aDefaults) {
		qlerror(@"Defaults dictionary was nil. No config can be checked.");
		return (NSDictionary *)_res;
	}

	// Create the WebService URL Path
	if ([aDefaults hasKey:@"MPServerSSL"]) {
		if ([[aDefaults objectForKey:@"MPServerSSL"] isEqualToString:@"1"] == TRUE) {
			HTTP_PREFIX = @"https";	
		}
	}
	[_res setObject:HTTP_PREFIX forKey:@"HTTP_PREFIX" defaultObject:@"http"];
		
	
	if ([aDefaults hasKey:@"MPServerAddress"]) {
		aHOST = [NSString stringWithString:[aDefaults objectForKey:@"MPServerAddress"]];
	}
	if ([aDefaults hasKey:@"MPServerPort"]) {
		aPORT = [NSString stringWithString:[aDefaults objectForKey:@"MPServerPort"]];
	}
	
	if ([MPNetUtils pingHostWithPort:aHOST port:[aPORT intValue]] == NO) 
	{
		qlinfo(@"%@ is unreachable. Attempting to use proxy.",aHOST);
		if ([aDefaults objectForKey:@"MPProxyEnabled"] || [aDefaults objectForKey:@"MPProxyIsEnabled"]) {
			if ([[aDefaults objectForKey:@"MPProxyEnabled"] isEqual:@"1"] || [[aDefaults objectForKey:@"MPProxyIsEnabled"] isEqual:@"1"]) {
				qlinfo(@"Proxy is enabled, testing if reachable.");
				// Define the server
				if ([aDefaults objectForKey:@"MPProxyServerAddress"]) {
					aHOST = [aDefaults objectForKey:@"MPProxyServerAddress"];
					qlinfo(@"Setting server to %@.", aHOST);
				} else {
					qlinfo(@"Proxy server is not configured, defaulting port to MPServerAddress.");
				}
				// Define the port
				if ([aDefaults objectForKey:@"MPProxyServerPort"]) {
					aPORT = [aDefaults objectForKey:@"MPProxyServerPort"];
					qlinfo(@"Setting server port to %@.", aPORT);
				} else if ([aDefaults objectForKey:@"MPProxyPort"]) {
					aPORT = [aDefaults objectForKey:@"MPProxyPort"];
					qlinfo(@"Setting server port to %@.", aPORT);
				} else {
					qlinfo(@"Proxy port is not configured, defaulting port to MPServerPort.");
					qlinfo(@"Setting server port to %@.", aPORT);
				}
				
				// Now Test the Connection
				if ([MPNetUtils pingHostWithPort:aHOST port:[aPORT intValue]] == NO) {
					qlinfo(@"%@:%@ is unreachable.",aHOST, aPORT);
					mpHostIsReachable = NO;
				} else {
					mpHostIsReachable = YES;
				}
			} else {
				qlinfo(@"MPProxy is configured, but not enabled.");
			}	
		} else {
			qlinfo(@"MPProxy is not enabled.");
		}
	} else {
		mpHostIsReachable = YES;
	}
	[_res setObject:HTTP_PREFIX forKey:@"HTTP_PREFIX" defaultObject:@"http"];
	[_res setObject:aHOST forKey:@"HTTP_HOST" defaultObject:@"127.0.0.1"];
	[_res setObject:aPORT forKey:@"HTTP_HOST_PORT" defaultObject:@"2600"];	
	[_res setObject:aPORT forKey:@"HTTP_HOST_REACHABLE" defaultObject:[NSNumber numberWithBool:mpHostIsReachable]];	
	[_res setObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@/%@",HTTP_PREFIX,aHOST,aPORT,SOAP_CONTROLLER_FILE]] forKey:@"MP_SOAP_URL"];
	[_res setObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@/%@",HTTP_PREFIX,aHOST,aPORT,JSON_CONTROLLER_FILE]] forKey:@"MP_JSON_URL"];
	[_res setObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@",HTTP_PREFIX,aHOST,aPORT]] forKey:@"MP_JSON_URL_PLAIN"];
	NSDictionary *result = [NSDictionary dictionaryWithDictionary:_res];
	qldebug(@"mpHostConfig=%@",result);
	return result;	
}

+ (NSDictionary *)mpHostConfigUsingFile:(NSString *)aDefaultsFile;
{
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:aDefaultsFile]) {
		NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:aDefaultsFile];	
		return [MPNetUtils mpHostConfig:d];
	}
	
	return nil;
}

@end
