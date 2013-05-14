//
//  MPSoap.m
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

#import "MPSoap.h"

#undef  ql_component
#define ql_component lcl_cMPSoap

@interface NSURLRequest (SomePrivateAPIs)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(id)fp8;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)fp8 forHost:(id)fp12;
@end

@implementation MPSoap

@synthesize theURL;
@synthesize theNameSpace;
@synthesize theMethodName;

#pragma mark -
#pragma mark init
//=========================================================== 
//  init 
//=========================================================== 
- (id)initWithURL:(NSURL *)aTheURL nameSpace:(NSString *)nm
{
	self = [super init];
    if (self) 
    {
		[self setTheURL:aTheURL];
		[self setTheNameSpace:nm];
    }
    return self;
}

#pragma mark -
#pragma mark Class Methods
//=========================================================== 
//  methods
//===========================================================

- (NSString *)createSOAPMessage:(NSString *)aMethod argName:(NSString *)aArgName argType:(NSString *)aArgType argValue:(NSString *)aArgValue
{
	qldebug(@"argName: %@", aArgName);
	qldebug(@"argType: %@", aArgType);
	qldebug(@"argValue: %@", aArgValue);
	
	[self setTheMethodName:aMethod];
	
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
	[str appendString:@"<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"];
	[str appendString:@"<SOAP-ENV:Body>"];
	
	[str appendFormat:@"<m:%@ xmlns:m=\"%@\">",aMethod,[self theNameSpace]]; // Method -- Start
	
	// Input Arg & Arg Type -- Start
	[str appendFormat:@"<%@ xsi:type=\"xsd:%@\">%@</%@>",aArgName,aArgType,aArgValue,aArgName];
	// Input Arg & Arg Type -- End
	
	[str appendFormat:@"</m:%@>",aMethod]; // Method -- End
	[str appendString:@"</SOAP-ENV:Body>"];
	[str appendString:@"</SOAP-ENV:Envelope>"];
	
	qltrace(@"SOAPMessage: %@", str);
	return [str autorelease];
}

- (NSString *)createBasicSOAPMessage:(NSString *)aMethod argDictionary:(NSDictionary *)aDict
{
	[self setTheMethodName:aMethod];
	
	qldebug(@"argDictionary: %@", aDict);
	
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
	[str appendString:@"<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"];
	[str appendString:@"<SOAP-ENV:Body>"];
	
	[str appendFormat:@"<m:%@ xmlns:m=\"%@\">",aMethod,[self theNameSpace]]; // Method -- Start
	
	// Input Arg & Arg Type -- Start
	NSArray *keys;
	keys = [aDict allKeys];
	for (int x = 0; x < [keys count]; x++)
	{	
		[str appendFormat:@"<%@ xsi:type=\"xsd:%@\">%@</%@>",[keys objectAtIndex:x],@"string",[aDict objectForKey:[keys objectAtIndex:x]],[keys objectAtIndex:x]];		
	}
	// Input Arg & Arg Type -- End
	
	[str appendFormat:@"</m:%@>",aMethod]; // Method -- End
	[str appendString:@"</SOAP-ENV:Body>"];
	[str appendString:@"</SOAP-ENV:Envelope>"];
	qldebug(@"BasicSOAPMessage: %@", str);
	return [str autorelease];
}

- (NSData *)invoke:(NSString *)SOAPMessage isBase64:(BOOL)b64 error:(NSError **)error
{	
	// Setup error info
	NSError *err = nil;
	NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
	
	qldebug(@"WSDL URL: %@", [self theURL]);
	qldebug(@"SOAPMessage: %@", SOAPMessage);
	
	if ([[[self theURL] absoluteString] hasPrefix:@"https"]) {
		[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[[self theURL] host]];
	}
	
	NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[self theURL]];
	[req setTimeoutInterval:120];
	[req setHTTPMethod: @"POST"];
	[req setHTTPBody: [SOAPMessage dataUsingEncoding: NSUTF8StringEncoding]];
	[req addValue: @"\"\"" forHTTPHeaderField: @"SOAPAction"];
	[req addValue: @"text/xml; charset=utf-8" forHTTPHeaderField: @"Content-Type"];	
	[req setCachePolicy: NSURLRequestReloadIgnoringCacheData];
	
	
	NSData *returnData = NULL;
	NSURLResponse *response = nil;
	err = nil;
	NSData *resultsData = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&err];
	NSString *rawResults = [[NSString alloc] initWithData:resultsData encoding:NSASCIIStringEncoding];
	qldebug(@"URL Connection Results:\n%@",rawResults);
	[rawResults release];
	
	if (err) {
		qlerror(@"Error sending SOAP request: %@", err);
		qldebug(@"WSDL URL: %@", [self theURL]);
		if (error != NULL) *error = err;
		[req release];
		return [@"" dataUsingEncoding:NSASCIIStringEncoding];
	}
	
	err = nil;
	NSXMLDocument *xmlDoc = [[[NSXMLDocument alloc] initWithData:resultsData options:0 error:&err] autorelease]; 
	if (err || !xmlDoc){
		qlerror(@"Error creating XML doc: %@", err);
		[errorDetail setValue:[NSString stringWithFormat:@"Error creating XML doc."] forKey:NSLocalizedDescriptionKey];
		if (error != NULL) *error = [NSError errorWithDomain:@"SOAP:INVOKE" code:1 userInfo:errorDetail];
		[req release];
		return [@"" dataUsingEncoding:NSASCIIStringEncoding];
	}
	
	// parse data from document
	// First, we look to see if we have a Fault code from the WebService, if so we bail.
	// Second, we look for the MethodName with Suffix of Return, and if it's 0 then bail.
	err = nil;
	NSArray *errNodes = nil;
	errNodes = [NSArray arrayWithArray:[[xmlDoc rootDocument] nodesForXPath:@"//*[contains(name(),'Fault')]" error:&err]];
	if (err) {
		qlerror(@"Error parse SOAP result: %@", err);
		if (error != NULL) *error = err;
		[req release];
		return returnData;
	}
	if ([errNodes count] > 0) {
		qlerror(@"Error: Fault found in XML.\nError: %@", [[errNodes lastObject] stringValue]);
		qlerror(@"Error: %@",xmlDoc);
		qlerror(@"Error [SPOAP Message]: %@",SOAPMessage);
		[errorDetail setValue:[NSString stringWithFormat:@"Error: Fault found in XML.\nError: %@", [[errNodes lastObject] stringValue]] forKey:NSLocalizedDescriptionKey];
		if (error != NULL) *error = [NSError errorWithDomain:@"SOAP:INVOKE" code:1 userInfo:errorDetail];
		
		[req release];
		return returnData;
	}
	
	err = nil;
	NSArray *nodes = nil;
	nodes = [NSArray arrayWithArray:[[xmlDoc rootDocument] nodesForXPath:[NSString stringWithFormat:@"//%@Return",theMethodName] error:&err]];
	if (err) {
		qlerror(@"Error parse SOAP Return: %@", err);
		if (error != NULL) *error = err;
		[req release];
		return returnData;
	}
	
	if ([nodes count] > 0){
		NSString *incomingText;
		if (b64) 
		{
			//Base64 data that needs decoding
			returnData = [[[nodes lastObject] stringValue] decodeBase64WithNewlines:NO];
			incomingText = [[NSString alloc] initWithData:returnData encoding:NSASCIIStringEncoding];
			qltrace(@"Base64 data is: %@", incomingText);
			[incomingText release];
		} else {
			returnData = [[[nodes lastObject] stringValue] dataUsingEncoding:NSUTF8StringEncoding];
			incomingText = [[NSString alloc] initWithData:returnData encoding:NSASCIIStringEncoding];
			qltrace(@"NonBase64 data is: %@", incomingText);
			[incomingText release];
		}
	}
	
done:	
	[req release];
	return returnData;
}

- (NSString *)createBasicXMLFromDictionary:(NSDictionary *)aDict
{
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
	[str appendString:@"<root>"];
	
	// Input Arg & Arg Type -- Start
	NSArray *keys = [NSArray arrayWithArray:[aDict allKeys]];
	for (int x = 0; x < [keys count]; x++)
	//for (id _key in [aDict allKeys])
	{	
		[str appendFormat:@"<%@>%@</%@>",[keys objectAtIndex:x],[aDict objectForKey:[keys objectAtIndex:x]],[keys objectAtIndex:x]];		
	}
	[str appendString:@"</root>"];
	
	NSString *_xmlStr = [NSString stringWithString:str];
	[str release];
	qldebug(@"XML: %@", _xmlStr);
	return _xmlStr;
}

- (void)dealloc 
{
	[super dealloc];
}
@end
