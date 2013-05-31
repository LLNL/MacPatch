//
//  MPInv.m
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

#import "MPInv.h"
#import "NSDirectoryServices.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "CHDiskInfo.h"
#import "MPUsersAndGroups.h"
#import "MPFileVaultInfo.h"

#define kSP_DATA_Dir			@"/private/tmp/.mpData"
#define kSP_APP                 @"/usr/sbin/system_profiler"
#define kINV_SUPPORTED_TYPES	@"SPHardwareDataType,SPSoftwareDataType,SPNetworkDataType,SPApplicationsDataType,SPFrameworksDataType,DirectoryServices,InternetPlugins,AppUsage,ClientTasks,DiskInfo,Users,Groups,FileVault"
#define kTasksPlist             @"/Library/MacPatch/Client/.tasks/gov.llnl.mp.tasks.plist"

#define LIBXML_SCHEMAS_ENABLED
#include <libxml/xmlschemastypes.h>

@implementation MPInv

@synthesize invResults;
@synthesize cUUID;

#pragma mark -

- (id)init 
{
	self = [super init];
	if (self) {
		[self setCUUID:[MPSystemInfo clientUUID]];
		mpServerConnection = [[MPServerConnection alloc] init];
        mpSoap = [[MPSoap alloc] initWithURL:[NSURL URLWithString:mpServerConnection.MP_SOAP_URL] nameSpace:@"http://MPWSController.cfc"];
	}	
	return self;
}
 
- (void) dealloc 
{    
	[invResults autorelease];
    [cUUID autorelease];
    [mpSoap release];
	[super dealloc];
}

#pragma mark -

- (int)collectInventoryData
{
	return [self collectInventoryDataForType:@"All"];
}

- (int)collectCustomData
{
	return 0;
}

- (BOOL)validateCollectionType:(NSString *)aColType
{
	BOOL result = NO;
	NSArray *supportedTypes = [kINV_SUPPORTED_TYPES componentsSeparatedByString:@","];
	
	if ([supportedTypes indexOfObject:aColType] != NSNotFound)
		result=YES;
	
	return result;
}

- (int)collectInventoryDataForType:(NSString *)aSPType
{
	NSArray *invColTypes;
	if ([aSPType isEqual:@"All"]) {
		invColTypes = [kINV_SUPPORTED_TYPES componentsSeparatedByString:@","];
	} else {
		if ([self validateCollectionType:aSPType] == NO) {
			logit(lcl_vError,@"Inventory collection type %@ is not supported. Inventory will not run.",aSPType);
			return 1;
		}	
		invColTypes = [NSArray arrayWithObject:aSPType];
	}
	
	
	
	NSMutableArray *resultsArray = [[NSMutableArray alloc] init];
	NSMutableDictionary *result;
	NSError *err = nil;
	NSString *filePath = NULL;
	int i = 0;
	for (i=0;i<[invColTypes count];i++)
	{
		logit(lcl_vInfo,@"Collecting inventory for type %@",[invColTypes objectAtIndex:i]);
		err = nil;
		filePath = [self getProfileData:[invColTypes objectAtIndex:i] error:&err];
		if (err) {
			logit(lcl_vError,@"Gathering inventory for data type %@",[invColTypes objectAtIndex:i]);
			continue;
		} else {
			result = [[NSMutableDictionary alloc] init];
			[result setObject:filePath forKey:@"file"];
			[result setObject:[invColTypes objectAtIndex:i] forKey:@"type"];
			
			// This needs to be cleaned up in the next release, 
			
			if ([[invColTypes objectAtIndex:i] isEqual:@"SPSoftwareDataType"]) {
				[result setObject:@"SPSystemOverview" forKey:@"wstype"];
			} else if ([[invColTypes objectAtIndex:i] isEqual:@"SPHardwareDataType"]) {
				[result setObject:@"SPHardwareOverview" forKey:@"wstype"];
			} else {
				[result setObject:[[invColTypes objectAtIndex:i] replace:@"DataType" replaceString:@""] forKey:@"wstype"];
			}

			[resultsArray addObject:result];
			[result release];
			result = nil;
		}
	}
	
	NSFileManager *fm = [NSFileManager defaultManager];
	MPDataMgr	*dataMgr	= [[MPDataMgr alloc] init];
	NSDictionary *item;
	NSString *dataMgrXML;
	NSArray *tmpArr = nil;
	
	for (i=0;i<[resultsArray count];i++)
	{
		item = [NSDictionary dictionaryWithDictionary:[resultsArray objectAtIndex:i]];
		if ([fm fileExistsAtPath:[item objectForKey:@"file"]]) {
			// Get Array Object, then gen DataMgr String
			if ([[item objectForKey:@"type"] isEqual:@"SPHardwareDataType"] ) {
				tmpArr = [self parseHardwareOverview:[item objectForKey:@"file"]];	
			} else if ([[item objectForKey:@"type"] isEqual:@"SPSoftwareDataType"]) {
				tmpArr = [self parseSystemOverviewData:[item objectForKey:@"file"]];
			} else if ([[item objectForKey:@"type"] isEqual:@"SPNetworkDataType"]) {
				tmpArr = [self parseNetworkData:[item objectForKey:@"file"]];
			} else if ([[item objectForKey:@"type"] isEqual:@"SPApplicationsDataType"]) {
				tmpArr = [self parseApplicationsDataFromXML:[item objectForKey:@"file"]];
			} else if ([[item objectForKey:@"type"] isEqual:@"SPFrameworksDataType"]) {
				tmpArr = [self parseFrameworksDataFromXML:[item objectForKey:@"file"]];	
			} else if ([[item objectForKey:@"type"] isEqual:@"DirectoryServices"]) {	
				tmpArr = [self parseDirectoryServicesData];
			} else if ([[item objectForKey:@"type"] isEqual:@"InternetPlugins"]) {	
				tmpArr = [self parseInternetPlugins];
			} else if ([[item objectForKey:@"type"] isEqual:@"AppUsage"]) {	
				tmpArr = [self parseAppUsageData];
			} else if ([[item objectForKey:@"type"] isEqual:@"ClientTasks"]) {	
				tmpArr = [self parseLocalClientTasks];
			} else if ([[item objectForKey:@"type"] isEqual:@"DiskInfo"]) {	
				tmpArr = [self parseLocalDiskInfo];
			} else if ([[item objectForKey:@"type"] isEqual:@"Users"]) {	
				tmpArr = [self parseLocalUsers];
			} else if ([[item objectForKey:@"type"] isEqual:@"Groups"]) {
				tmpArr = [self parseLocalGroups];
			} else if ([[item objectForKey:@"type"] isEqual:@"FileVault"]) {
				tmpArr = [self parseFileVaultInfo];
			}
			
			if (tmpArr) {
				dataMgrXML = [dataMgr GenXMLForDataMgr:tmpArr
											   dbTable:[item objectForKey:@"wstype"] 
										 dbTablePrefix:@"mpi_" 
										 dbFieldPrefix:@"mpa_"
										  updateFields:@"rid,cuuid"
											 deleteCol:@"cuuid"
										deleteColValue:[self cUUID]];
				
				if ([self sendResultsToWebService:dataMgrXML]) {
					logit(lcl_vInfo,@"Results for %@ posted.",[item objectForKey:@"wstype"]);
				} else {
					logit(lcl_vError,@"Results for %@ not posted.",[item objectForKey:@"wstype"]);
				}
				dataMgrXML = NULL;
			}
		}
	}
	
	// Collect Audit Data
	if ([aSPType isEqual:@"All"]) {
		int x = 0;
		x = [self collectAuditTypeData];
	}

	[resultsArray release];
	[dataMgr release];
	return 0;
}

- (BOOL)sendResultsToWebService:(NSString *)aDataMgrXML
{
	BOOL result = NO;
	MPDataMgr	*dataMgr	= [[MPDataMgr alloc] init];
	
	// Encode to base64 and send to web service	
	NSString	*cleanXMLString = [aDataMgrXML validXMLString];
	NSString	*xmlB64String	= [[cleanXMLString dataUsingEncoding:NSUTF8StringEncoding] encodeBase64WithNewlines:NO];
	if (!xmlB64String) {
		logit(lcl_vError,@"Unable to encode xml data.");
		[dataMgr release];
		dataMgr = nil;
		return result;	
	}
	NSDictionary	*msgParams	= [NSDictionary dictionaryWithObject:xmlB64String forKey:@"encodedXML"];
	NSString		*message	= [mpSoap createBasicSOAPMessage:@"ProcessXML" argDictionary:msgParams];
	if (!message) {
		logit(lcl_vError,@"Soap message was nil.");
		[dataMgr release];
		dataMgr = nil;
		return result;	
	}
	
	NSError *err = nil;
	NSData *soapResult = [mpSoap invoke:message isBase64:NO error:&err];
	NSString *ws = [[NSString alloc] initWithData:soapResult encoding:NSUTF8StringEncoding];
	sleep(2); // Quick Sleep "-|
	if (err) {
		logit(lcl_vError,@"%@",[err localizedDescription]);
	} else {
		if ([ws isEqualTo:@"1"] == TRUE || [ws isEqualTo:@"true"] == TRUE) {
			logit(lcl_vInfo,@"Results posted to webservice.");
			result = YES;
		} else {
			logit(lcl_vError,@"Results posted to webservice returned false.");
			result = NO;
		}
	}
	[ws release];
	ws = nil;
	
	[dataMgr release];
	dataMgr = nil;
	
	return result;
}

- (NSString *)getProfileData:(NSString *)profileType error:(NSError **)error
{	
	
	// SystemProfiler Output file Name
	NSString *spFileName;
	spFileName = [NSString stringWithFormat:@"%@.spx",profileType];
	
    NSTask *spTask = [[NSTask alloc] init];
    [spTask setLaunchPath: kSP_APP];
	
	// Should it be XML or Text
	if ([profileType isEqualToString:@"SPApplicationsDataType"] || [profileType isEqualToString:@"SPFrameworksDataType"]) {
		[spTask setArguments:[NSArray arrayWithObjects:profileType,@"-xml",nil]];
		spFileName = [NSString stringWithFormat:@"%@.plist",profileType];
	} else {
		[spTask setArguments:[NSArray arrayWithObjects:profileType,nil]];
	}
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	BOOL isDir;
	if (([fm fileExistsAtPath:kSP_DATA_Dir isDirectory:&isDir] && isDir) == NO) {
        [fm createDirectoryAtPath:kSP_DATA_Dir withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	if (![fm isWritableFileAtPath:kSP_DATA_Dir]) {
		logit(lcl_vError, @"Temp directory (%@) is not writable. Inventory will no get processed properly.",kSP_DATA_Dir);
	}
	
	// If File Exists then delete it
	if ([fm fileExistsAtPath:[kSP_DATA_Dir stringByAppendingPathComponent:spFileName] isDirectory:NO]) {
        [fm removeItemAtPath:[kSP_DATA_Dir stringByAppendingPathComponent:spFileName] error:NULL];
	}

	NSPipe *pipe;
    pipe = [NSPipe pipe];
    [spTask setStandardOutput: pipe];
	
	NSFileHandle *file;
    file = [pipe fileHandleForReading];
	
	[spTask launch];

	NSData *data = [file readDataToEndOfFile];
	
    NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	logit(lcl_vInfo,@"Writing result to %@",[kSP_DATA_Dir stringByAppendingPathComponent:spFileName]);
	[string writeToFile:[kSP_DATA_Dir stringByAppendingPathComponent:spFileName] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	[string release];
	
	[spTask release];
	
	return [kSP_DATA_Dir stringByAppendingPathComponent:spFileName];
}

#pragma mark -

- (int)collectAuditTypeData
{
	logit(lcl_vInfo,@"Collecting and processing audit files."); 
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableArray *files = [NSMutableArray array];
	NSString *thePath = [NSString pathWithComponents:[NSArray arrayWithObjects:MP_ROOT_CLIENT,@"Data",@"inv",nil]];
	NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:thePath];
	id file;
	while (file = [enumerator nextObject])
	{
		if ([[file pathExtension] isEqual:@"xml"])
		{
			// Do something with file.xml
			[files addObject:[thePath stringByAppendingPathComponent:file]];
		}
	}
	
	logit(lcl_vInfo,@"%d audit files found to process.",(int)[files count]);
	int i = 0;
	NSString *xmlText;
	for (i=0; i<[files count]; i++)
	{
		if ([self validateDataMgrXML:[files objectAtIndex:i]]) {
		 	xmlText = [self replaceXMLVariables:[files objectAtIndex:i]];
			if ([self sendResultsToWebService:xmlText]) {
				logit(lcl_vInfo,@"Results for %@ posted.",[[files objectAtIndex:i] lastPathComponent]);
                NSError *rmError = nil;
				[fm removeItemAtPath:[files objectAtIndex:i] error:&rmError];
                if (rmError) {
                    logit(lcl_vError,@"%@",[rmError localizedDescription]);
                }
			} else {
				logit(lcl_vError,@"Results for %@ not posted.",[[files objectAtIndex:i] lastPathComponent]);
			}
		}
	}

	return 0;	
}

- (NSString *)replaceXMLVariables:(NSString *)aFilePath
{
    NSString *tmpStr = NULL;
    tmpStr = [NSString stringWithContentsOfFile:aFilePath encoding:NSUTF8StringEncoding error:NULL];
    
    NSString *_chkFields = @"rid,cuuid";
    NSString *_length = @"255";
    NSString *_dataType = @"CF_SQL_VARCHAR";
    NSString *_mpColReq = @"<field Increment=\"true\" Length=\"11\" ColumnName=\"rid\" CF_DATATYPE=\"CF_SQL_INTEGER\" PrimaryKey=\"true\"></field> \
    <field ColumnName=\"cuuid\" Length=\"50\" CF_DATATYPE=\"CF_SQL_VARCHAR\"></field> \
    <field ColumnName=\"date\" Default=\"0000-00-00 00:00:00\" CF_DATATYPE=\"CF_SQL_DATE\"></field> \
    <field ColumnName=\"mdate\" Default=\"0000-00-00 00:00:00\" CF_DATATYPE=\"CF_SQL_DATE\"></field>";
	
    NSString *_mpColRowReq = @"<field name=\"cuuid\" value=\"$cuuid\"></field>\
    <field name=\"date\" value=\"$date\"></field>\
    <field name=\"mdate\" value=\"$date\"></field>";
    
	// Replace variables for table, cuuid and ,date
    tmpStr = [tmpStr replaceAll:@"<mpColReq />" replaceString:_mpColReq];
    tmpStr = [tmpStr replaceAll:@"<mpColRowReq />" replaceString:_mpColRowReq];
    tmpStr = [tmpStr replaceAll:@"$table" replaceString:[NSString stringWithFormat:@"mpi_%@",[[aFilePath lastPathComponent] stringByDeletingPathExtension]]];
    tmpStr = [tmpStr replaceAll:@"$cuuid" replaceString:[self cUUID]];
    tmpStr = [tmpStr replaceAll:@"$date" replaceString:[MPDate dateTimeStamp]];
    tmpStr = [tmpStr replaceAll:@"$mdate" replaceString:[MPDate dateTimeStamp]];
    tmpStr = [tmpStr replaceAll:@"$checkfields" replaceString:_chkFields];
    tmpStr = [tmpStr replaceAll:@"$length" replaceString:_length];
    tmpStr = [tmpStr replaceAll:@"$datatype" replaceString:_dataType];
	
    return tmpStr;
}

- (BOOL)validateDataMgrXML:(NSString *)aFilePath
{
    BOOL isValid = YES;
	if ([[NSFileManager defaultManager] fileExistsAtPath:aFilePath] == NO) {
		logit(lcl_vError,@"File (%@) to validate is missing.",aFilePath);
		return NO;
	}
    
    NSString *xsdFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mpAudit.xsd"];
    [MP_XSD_AUDIT writeToFile:xsdFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    xmlDocPtr doc;
    xmlSchemaPtr schema = NULL;
    xmlSchemaParserCtxtPtr ctxt;
    
    xmlLineNumbersDefault(1);
    
    ctxt = xmlSchemaNewParserCtxt([xsdFile UTF8String]);
    
    xmlSchemaSetParserErrors(ctxt, (xmlSchemaValidityErrorFunc) fprintf, (xmlSchemaValidityWarningFunc) fprintf, stderr);
    schema = xmlSchemaParse(ctxt);
    xmlSchemaFreeParserCtxt(ctxt);
    //xmlSchemaDump(stdout, schema); //To print schema dump
    
    doc = xmlReadFile([aFilePath UTF8String], NULL, 0);
    if (doc == NULL)
    {
        logit(lcl_vError,@"Could not parse XML file.");
        return NO;
    } else {
        xmlSchemaValidCtxtPtr ctxt;
        int ret;
        
        ctxt = xmlSchemaNewValidCtxt(schema);
        xmlSchemaSetValidErrors(ctxt, (xmlSchemaValidityErrorFunc) fprintf, (xmlSchemaValidityWarningFunc) fprintf, stderr);
        ret = xmlSchemaValidateDoc(ctxt, doc);
        if (ret == 0)
        {
            logit(lcl_vDebug,@"Valid Inventory XML file.");
        }
        else if (ret > 0)
        {
            logit(lcl_vError,@"Could not validate XML file.");
            isValid = NO;
        }
        else
        {
            logit(lcl_vError,@"Validation generated an internal error.");
            isValid = NO;
        }
        xmlSchemaFreeValidCtxt(ctxt);
        xmlFreeDoc(doc);
    }
    
    // free the resource
    if(schema != NULL)
        xmlSchemaFree(schema);
    
    xmlSchemaCleanupTypes();
    xmlCleanupParser();
    xmlMemoryDump();

	return isValid;
}

#pragma mark -

// Parse Profiler Data
- (NSArray *)parseHardwareOverview:(NSString *)fileToParse
{
	NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
	[d setObject:@"NA" forKey:@"Model_Name"];
	[d setObject:@"NA" forKey:@"Model_Identifier"];
	[d setObject:@"NA" forKey:@"Processor_Name"];
	[d setObject:@"NA" forKey:@"Processor_Speed"];
	[d setObject:@"NA" forKey:@"Number_Of_Processors"];
	[d setObject:@"NA" forKey:@"Total_Number_Of_Cores"];
	[d setObject:@"NA" forKey:@"L2_Cache"];
	[d setObject:@"NA" forKey:@"Memory"];
	[d setObject:@"NA" forKey:@"Bus_Speed"];
	[d setObject:@"NA" forKey:@"Boot_ROM_Version"];
	[d setObject:@"NA" forKey:@"SMC_Version"];
	[d setObject:@"NA" forKey:@"Serial_Number"];

	NSString *dataString = [[NSString alloc] initWithContentsOfFile:fileToParse encoding:NSUTF8StringEncoding error:NULL];
	NSArray *lines = [dataString componentsSeparatedByString:@"\n"];
	[dataString release];
	
	NSEnumerator *enumerator = [lines objectEnumerator];
	id obj;
	NSString *title;
	NSString *value;
	while (obj = [enumerator nextObject]) {
		if ([[obj trim] length] >=1)
		{
			title = NULL;
			value = NULL;
			if ([[obj trim] isEqual:@"Hardware:"] == NO)
			{
				if ([[obj trim] isEqual:@"Hardware Overview:"])
				{
					// Nothing
				} else if ([[obj trim] containsString:@"Number Of CPUs"]) {
					title = @"Number_Of_Processors";
					value = [[[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:1] trim];
				} else if ([[obj trim] containsString:@"L2 Cache"]) {
					title = @"L2_Cache";
					value = [[[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:1] trim];
				} else if ([[obj trim] containsString:@"(system):"]) {
					title = [[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:0];
					title = [[[title trim] replaceAll:@" " replaceString:@"_"] trim];
					title = [[[title trim] replaceAll:@"_(system)" replaceString:@""] trim];
					value = [[[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:1] trim];
				} else {
					title = [[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:0];
					title = [[[title trim] replaceAll:@" " replaceString:@"_"] trim];
					value = [[[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:1] trim];
				} // if, hardware overview
				
				if ([[title trim] length] > 2)
				{
					[d setObject:value forKey:title];
				} // if, title len
			} // if, Hardware 
		} // if, length
	} // end while

	NSDictionary *result = [NSDictionary dictionaryWithDictionary:d];
	[d autorelease];
	return [NSArray arrayWithObject:result];
}

- (NSArray *)parseNetworkData:(NSString *)fileToParse
{
	NSMutableArray *networkData = [[NSMutableArray alloc] init];
	NSMutableDictionary *d = nil;
	
	// Read contents of the file...
	NSString *dataString = [[NSString alloc] initWithContentsOfFile:fileToParse encoding:NSUTF8StringEncoding error:NULL];
	
	// Parse by line endings and put in to an array
	NSArray *lines = [dataString componentsSeparatedByString:@"\n"];
	[dataString release];
	
	NSEnumerator *enumerator = [lines objectEnumerator];
	id obj;
	NSString *tmpTxt;
	NSString *tmpTxt2;
	NSString *title;
	NSString *value;
	NSString *valPrefix = @"";
	while (obj = [enumerator nextObject]) {
		if ([[obj trim] length] >=1)
		{
			if ([[obj trim] isEqual:@"Network:"] == NO)
			{
				if ([[obj midStartAt:4 end:1] isEqual:@" "] == NO)
				{						
					// Add entry 
					if (d) {
						[networkData addObject:d];
						[d release];
						d = nil;
					}
					
					d = [[NSMutableDictionary alloc] init];
					[d setObject:[[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:0] forKey:@"Name"];
					[d setObject:@"NA" forKey:@"Type"];
					[d setObject:@"NA" forKey:@"Hardware"];
					[d setObject:@"NA" forKey:@"BSD_Device_Name"];
					[d setObject:@"NA" forKey:@"Has_IP_Assigned"];
					[d setObject:@"NA" forKey:@"IPv4_Addresses"];
					[d setObject:@"NA" forKey:@"IPv4_Configuration_Method"];
					[d setObject:@"NA" forKey:@"IPv4_Interface_Name"];
					[d setObject:@"NA" forKey:@"IPv4_NetworkSignature"];
					[d setObject:@"NA" forKey:@"IPv4_Router"];
					[d setObject:@"NA" forKey:@"IPv4_Subnet_Masks"];
					[d setObject:@"NA" forKey:@"AppleTalk_Configuration_Method"];
					[d setObject:@"NA" forKey:@"AppleTalk_Default_Zone"];
					[d setObject:@"NA" forKey:@"AppleTalk_Interface_Name"];
					[d setObject:@"NA" forKey:@"AppleTalk_Network_ID"];
					[d setObject:@"NA" forKey:@"AppleTalk_Node_ID"];
					[d setObject:@"NA" forKey:@"DNS_Search_Domains"];
					[d setObject:@"NA" forKey:@"DNS_Server_Addresses"];
					[d setObject:@"NA" forKey:@"Proxies_Exceptions_List"];
					[d setObject:@"NA" forKey:@"Proxies_FTP_Passive_Mode"];
					[d setObject:@"NA" forKey:@"Proxies_HTTP_Proxy_Enabled"];
					[d setObject:@"NA" forKey:@"Proxies_HTTP_Proxy_Port"];
					[d setObject:@"NA" forKey:@"Proxies_HTTP_Proxy_Server"];
					[d setObject:@"NA" forKey:@"Ethernet_MAC_Address"];
					[d setObject:@"NA" forKey:@"Ethernet_Media_Options"];
					[d setObject:@"NA" forKey:@"Ethernet_Media_Subtype"];
				} else {
					if ([[[[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:1] trim] length] == 0) {
						// Set the valPrefix
						tmpTxt2 = [[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:0];
						if ([tmpTxt2 isEqual:@"IPv4"] || [tmpTxt2 isEqual:@"DHCP Server Responses"] || [tmpTxt2 isEqual:@"AirPort"] || [tmpTxt2 isEqual:@"AppleTalk"] || [tmpTxt2 isEqual:@"DNS"] || [tmpTxt2 isEqual:@"Proxies"] || [tmpTxt2 isEqual:@"Ethernet"] ) {
							if ([tmpTxt2 isEqual:@"DHCP Server Responses"])
								tmpTxt2 = @"DHCP";
							valPrefix = [NSString stringWithFormat:@"%@_",tmpTxt2];
						} else {
							valPrefix = @"";
						}
					} else {
						title = NULL;
						value = NULL;
						tmpTxt = [[obj trim] replace:@":" replaceString:@"^"];
						title = [[[tmpTxt componentsSeparatedByString:@"^"] objectAtIndex:0] replaceAll:@" " replaceString:@"_"]; 
						title = [title replaceAll:@"(" replaceString:@""];
						title = [title replaceAll:@")" replaceString:@""];
						title = [NSString stringWithFormat:@"%@%@",valPrefix,title];
						value = [[[tmpTxt componentsSeparatedByString:@"^"] objectAtIndex:1] trim];
						value = [value replaceAll:@"(" replaceString:@""];
						value = [value replaceAll:@")" replaceString:@""];
						[d setObject:value forKey:title];
					}
				} // if, mid
			} // if, Network 
		} // if, length
	} // end while
	
	// Add the last record
	if (d) {
		[networkData addObject:d];
		[d release];
		d = nil;
	}
	NSArray *result = nil;
	if (networkData)
		result = [NSArray arrayWithArray:networkData];
	
	[networkData release];
	return result;
}

- (NSArray *)parseSystemOverviewData:(NSString *)fileToParse
{
	NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
	[d setObject:@"NA" forKey:@"Name"];
	[d setObject:@"NA" forKey:@"System_Version"];
	[d setObject:@"NA" forKey:@"Kernel_Version"];
	[d setObject:@"NA" forKey:@"Boot_Volume"];
	[d setObject:@"NA" forKey:@"Boot_Mode"];
	[d setObject:@"NA" forKey:@"Computer_Name"];
	[d setObject:@"NA" forKey:@"User_Name"];
	[d setObject:@"NA" forKey:@"Time_since_boot"];
	
	
	NSString *dataString = [[NSString alloc] initWithContentsOfFile:fileToParse encoding:NSUTF8StringEncoding error:NULL];
	NSArray *lines = [dataString componentsSeparatedByString:@"\n"];
	[dataString release];
	
	NSEnumerator *enumerator = [lines objectEnumerator];
	id obj;
	NSString *title;
	NSString *value;
	while (obj = [enumerator nextObject]) {
		if ([[obj trim] length] >=1)
		{
			title = @"";
			value = @"";
			if ([[obj trim] isEqual:@"Software:"] == NO)
			{
				if ([[obj trim] isEqual:@"System Software Overview:"])
				{
					title = @"Name";
					value = [[[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:1] trim];
				} else {
					title = [[[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:0] trim];
					title = [[[title trim] replaceAll:@" " replaceString:@"_"] trim];
					value = [[[[obj trim] componentsSeparatedByString:@":"] objectAtIndex:1] trim];
				} // if, Software overview
				
				if ([[title trim] length] > 2)
				{
					[d setObject:value forKey:title];
				} // if, title len
			} // if, Software 
		} // if, length
	} // end while
	
	NSDictionary *result = [NSDictionary dictionaryWithDictionary:d];
	[d release];
	return [NSArray arrayWithObject:result];
}

- (NSArray *)parseApplicationsDataFromXML:(NSString *)xmlFileToParse
{
	NSArray *result = nil;
	NSFileManager *dm = [NSFileManager defaultManager];
	if ([dm fileExistsAtPath:xmlFileToParse] == NO)
	{
		logit(lcl_vError,@"Inventory cache file was not found. Data will not be parsed.");
		goto done;
	}
	
	NSArray *spX = [NSArray arrayWithContentsOfFile:xmlFileToParse];
	NSDictionary *rootDict = [spX objectAtIndex:0];
 	NSArray *itemsArray = [rootDict objectForKey:@"_items"];
	
	NSArray *tmpKeys = [NSArray arrayWithObjects:@"Version",@"Last_Modified",@"Kind",@"Get_Info_String",@"Location",nil];
	NSArray *tmpObj = [NSArray arrayWithObjects:@"NA",@"NA",@"NA",@"NA",@"NA",nil];
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjects:tmpObj forKeys:tmpKeys];
	
	NSMutableArray *newItemsArray = [[NSMutableArray alloc] init];
	NSMutableDictionary *rec;
	NSDictionary *curItem;
	int i = 0;
	for (i=0;i<[itemsArray count];i++)
	{
		curItem = [itemsArray objectAtIndex:i];
		rec = [[NSMutableDictionary alloc] initWithDictionary:tmpDict];

		if ([[curItem allKeys] containsObject:@"_name"]) {
			[rec setObject:[curItem objectForKey:@"_name"] forKey:@"Name"];
		}	
		if ([[curItem allKeys] containsObject:@"version"]) {
			[rec setObject:[curItem objectForKey:@"version"] forKey:@"Version"];
		}	
		if ([[curItem allKeys] containsObject:@"lastModified"]) {
			[rec setObject:[curItem objectForKey:@"lastModified"] forKey:@"Last_Modified"];
		}	
		if ([[curItem allKeys] containsObject:@"runtime_environment"]) {
			[rec setObject:[curItem objectForKey:@"runtime_environment"] forKey:@"Kind"];
		}	
		if ([[curItem allKeys] containsObject:@"path"]) {
			[rec setObject:[curItem objectForKey:@"path"] forKey:@"Location"];
		}	
		
		[newItemsArray addObject:rec];
		[rec release];
		rec = nil;
	}
	
	result = [NSArray arrayWithArray:newItemsArray];
	[newItemsArray release];
	
done:
	return result;	
}

- (NSArray *)parseFrameworksDataFromXML:(NSString *)xmlFileToParse
{
	NSArray *result = nil;
	NSFileManager *dm = [NSFileManager defaultManager];
	if ([dm fileExistsAtPath:xmlFileToParse] == NO)
	{
		logit(lcl_vError,@"Inventory cache file was not found. Data will not be parsed.");
		return result;
	}
	/*
	 <dict>
		 <key>_name</key>
		 <key>has64BitIntelCode</key>
		 <key>info</key>
		 <key>lastModified</key>
		 <key>path</key>
		 <key>private_framework</key>
		 <key>runtime_environment</key>
		 <key>version</key>
	 </dict>
	*/	
	
	NSArray *spX = [NSArray arrayWithContentsOfFile:xmlFileToParse];
	NSDictionary *rootDict = [spX objectAtIndex:0];
 	NSArray *itemsArray = [rootDict objectForKey:@"_items"];
	
	NSArray *tmpKeys = [NSArray arrayWithObjects:@"Name",@"has64BitIntelCode",@"lastModified",@"Location",@"Private_Framework",@"Kind",@"Version",nil];
	NSArray *tmpObj = [NSArray arrayWithObjects:@"NA",@"NA",@"NA",@"NA",@"NA",@"NA",@"NA",nil];
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjects:tmpObj forKeys:tmpKeys];
	
	NSMutableArray *newItemsArray = [[NSMutableArray alloc] init];
	NSMutableDictionary *rec;
	NSDictionary *curItem;
	int i = 0;
	for (i=0;i<[itemsArray count];i++)
	{
		curItem = [itemsArray objectAtIndex:i];
		rec = [[NSMutableDictionary alloc] initWithDictionary:tmpDict];

		if ([[curItem allKeys] containsObject:@"_name"]) {
			[rec setObject:[curItem objectForKey:@"_name"] forKey:@"Name"];
		}	
		if ([[curItem allKeys] containsObject:@"version"]) {
			[rec setObject:[curItem objectForKey:@"version"] forKey:@"Version"];
		}	
		if ([[curItem allKeys] containsObject:@"lastModified"]) {
			[rec setObject:[curItem objectForKey:@"lastModified"] forKey:@"lastModified"];
		}	
		if ([[curItem allKeys] containsObject:@"runtime_environment"]) {
			[rec setObject:[curItem objectForKey:@"runtime_environment"] forKey:@"Kind"];
		}	
		if ([[curItem allKeys] containsObject:@"private_framework"]) {
			[rec setObject:[curItem objectForKey:@"private_framework"] forKey:@"Private_Framework"];
		}	
		if ([[curItem allKeys] containsObject:@"path"]) {
			[rec setObject:[curItem objectForKey:@"path"] forKey:@"Location"];
		}	
		if ([[curItem allKeys] containsObject:@"has64BitIntelCode"]) {
			[rec setObject:[curItem objectForKey:@"has64BitIntelCode"] forKey:@"has64BitIntelCode"];
		}	
		
		[newItemsArray addObject:rec];
		[rec release];
		rec = nil;
	}
	
	result = [NSArray arrayWithArray:newItemsArray];
	[newItemsArray release];
	
	return result;	
}

- (NSArray *)parseApplicationsData:(NSString *)fileToParse
{
	NSMutableArray *applicationData = [[NSMutableArray alloc] init];
	NSMutableDictionary *d = nil;
	
	// Read contents of the file...
	NSString *dataString = [[NSString alloc] initWithContentsOfFile:fileToParse encoding:NSUTF8StringEncoding error:NULL];
	
	// This is done to remove unicode chars
	NSData *asciiData = [dataString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	[dataString release];
	
	NSString *asciiString = [[[NSString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
	
	// Parse by line endings and put in to an array
	NSArray *lines = [asciiString componentsSeparatedByString:@"\n"];
	
	NSString *nextVal;
	NSString *nValue;
	NSString *line = @"";
	
	int i = 0;
	int l = 0;
	for (i = 0;i < [lines count]; i++)
	{
		line = [NSString stringWithString:[[lines objectAtIndex:i] trim]];
		if ([line length] >=1)
		{
			if ([[line componentsSeparatedByString:@":"] count] > 1 && [[[[line componentsSeparatedByString:@":"] objectAtIndex:1] trim] length] == 0)
			{
				if ([line isEqual:@"Applications:"] == NO && [line containsString:@":"] == YES)
				{
					@try 
					{
						d = [[NSMutableDictionary alloc] init];
						[d setObject:[[line componentsSeparatedByString:@":"] objectAtIndex:0] forKey:@"Name"];
						[d setObject:@"NA" forKey:@"Version"];
						[d setObject:@"NA" forKey:@"Last_Modified"];
						[d setObject:@"NA" forKey:@"Kind"];
						[d setObject:@"NA" forKey:@"Get_Info_String"];
						[d setObject:@"NA" forKey:@"Location"];
						
						for (l = (i+1);l < (i+16); l++)
						{	
							nextVal = @"";
							//First Make Sure the line has a : to Separate the attr title
							if ([line containsString:@":"])
							{
								// Replace the Title delimiter with a new Charater so that Date & Time shows right
								nValue = [[[lines objectAtIndex:l] trim] replace:@":" replaceString:@"^"];
								// ----------------------------------------
								// Look for data that matches the defined
								// attributes using if and In string exists
								// ----------------------------------------
								if ([[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:0] trim] containsString:@"Version"]) {
									// If next line is true, add it to the current line
									if ([[lines objectAtIndex:(l+1)] containsString:@":"]) {
										nextVal = [NSString stringWithString:[lines objectAtIndex:(l+1)]];
									}
									[d setObject:[NSString stringWithFormat:@"%@%@",[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:1] trim], nextVal] forKey:@"Version"];
									
								} else if ([[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:0] trim] containsString:@"Last Modified"]) {
									// If next line is true, add it to the current line
									if ([[lines objectAtIndex:(l+1)] containsString:@":"]) {
										nextVal = [NSString stringWithString:[lines objectAtIndex:(l+1)]];
									}
									[d setObject:[NSString stringWithFormat:@"%@%@",[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:1] trim], nextVal] forKey:@"Last_Modified"];
									
								} else if ([[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:0] trim] containsString:@"Kind"]) {
									// If next line is true, add it to the current line
									if ([[lines objectAtIndex:(l+1)] containsString:@":"]) {
										nextVal = [NSString stringWithString:[lines objectAtIndex:(l+1)]];
									}
									[d setObject:[NSString stringWithFormat:@"%@%@",[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:1] trim], nextVal] forKey:@"Kind"];
									
								} else if ([[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:0] trim] containsString:@"Get Info String"]) {
									// If next line is true, add it to the current line
									if ([[lines objectAtIndex:(l+1)] containsString:@":"]) {
										nextVal = [NSString stringWithString:[lines objectAtIndex:(l+1)]];
									}
									[d setObject:[NSString stringWithFormat:@"%@%@",[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:1] trim], nextVal] forKey:@"Get_Info_String"];
									
								} else if ([[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:0] trim] containsString:@"Location"]) {
									// If next line is true, add it to the current line
									if ([[lines objectAtIndex:(l+1)] containsString:@":"]) {
										nextVal = [NSString stringWithString:[lines objectAtIndex:(l+1)]];
									}
									[d setObject:[NSString stringWithFormat:@"%@%@",[[[nValue componentsSeparatedByString:@"^"] objectAtIndex:1] trim], nextVal] forKey:@"Location"];
									break;
								} // Attributes if
							} // if line contains :
						} // for loop
						[applicationData addObject:d];
						[d release];
						d = nil;
					}	
					@catch (NSException * e) {
						logit(lcl_vError,@"Error: %@",[e description]);
						[d release];
						d = nil;
					}
				}
			}
		}
	}
	
	
	NSArray *result = [NSArray arrayWithArray:applicationData];
	[applicationData release];
	return result;
}

- (NSDictionary *)emptyDirectoryServicesDataRecord
{
	NSDictionary *result = nil;
	NSMutableDictionary *record = [[NSMutableDictionary alloc] init];
	[record setObject:@"NA" forKey:@"distinguishedName"];
	[record setObject:@"NA" forKey:@"cn"];
	[record setObject:@"NA" forKey:@"DNSName"];
	[record setObject:@"NA" forKey:@"ADDomain"];
	[record setObject:@"0" forKey:@"HasSLAM"];
	[record setObject:@"NA" forKey:@"AD_Computer_ID"];
	[record setObject:@"NA" forKey:@"AD_Kerberos_ID"];
	[record setObject:@"0" forKey:@"Bound_To_Domain"];
	result = [NSDictionary dictionaryWithDictionary:record];
	[record release];
	return result;
}

- (NSArray *)parseDirectoryServicesData
{	
	NSDictionary *osVerInfo = [MPSystemInfo osVersionOctets];
	if ([[osVerInfo objectForKey:@"minor"] intValue] <= 6) {
		logit(lcl_vDebug,@"parseDirectoryServicesData <= 6");
		return [self parseDirectoryServicesDataForPreLion];
	}
	if ([[osVerInfo objectForKey:@"minor"] intValue] >= 7) {
		logit(lcl_vDebug,@"parseDirectoryServicesData >= 7");
		return [self parseDirectoryServicesDataForLion];
	}
	
	logit(lcl_vError,@"parseDirectoryServicesData, did not figure out os version for parsing.");
	return nil;
}

- (NSArray *)parseDirectoryServicesDataForLion
{
	NSArray *result;
	NSMutableDictionary *record = [[NSMutableDictionary alloc] initWithDictionary:[self emptyDirectoryServicesDataRecord]];
	
	@try {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *dirPath = @"/Library/Preferences/OpenDirectory/Configurations/Active Directory";
		NSArray *dirContents = [fm contentsOfDirectoryAtPath:dirPath error:NULL];
		if ([dirContents count] >= 1) {
			[record setObject:@"1" forKey:@"Bound_To_Domain"];
		}
		NSString *adPlist = [NSString stringWithFormat:@"%@/%@",dirPath,[dirContents objectAtIndex:0]];
		if (![fm fileExistsAtPath:adPlist])
			goto done;
		NSDictionary *adInfo = [NSDictionary dictionaryWithContentsOfFile:adPlist];
		// Computer Name
		if ([[adInfo allKeys] containsObject:@"trustaccount"]) {
			[record setObject:[adInfo objectForKey:@"trustaccount"] forKey:@"AD_Computer_ID"];
		}
		// Kerbname
		if ([[adInfo allKeys] containsObject:@"trustkerberosprincipal"]) {
			[record setObject:[adInfo objectForKey:@"trustkerberosprincipal"] forKey:@"AD_Kerberos_ID"];
		}
		// AD Domain Name
		if ([[adInfo allKeys] containsObject:@"module options"]) {
			if ([[[adInfo objectForKey:@"module options"] allKeys] containsObject:@"ActiveDirectory"]) {
				if ([[[[adInfo objectForKey:@"module options"] objectForKey:@"ActiveDirectory"] allKeys] containsObject:@"domain"]) {	
					[record setObject:[[[adInfo objectForKey:@"module options"] objectForKey:@"ActiveDirectory"] objectForKey:@"domain"] forKey:@"ADDomain"];
				}	
			}	
		}	
			
		
		NSDirectoryServices *dsSearch = [[[NSDirectoryServices alloc] init] autorelease];
		NSDictionary *computerAccountInfo = [dsSearch getRecord:[adInfo objectForKey:@"trustaccount"] ofType:DHDSComputerAccountType fromNode:DHDSSEARCHNODE];
		
		if ([computerAccountInfo objectForKey:@"dsAttrTypeNative:distinguishedName"]) {
			[record setObject:[computerAccountInfo objectForKey:@"dsAttrTypeNative:distinguishedName"] forKey:@"distinguishedName"];
		} else {
			[record setObject:@"NA" forKey:@"distinguishedName"];
		}
		if ([computerAccountInfo objectForKey:@"dsAttrTypeNative:cn"]) {
			[record setObject:[computerAccountInfo objectForKey:@"dsAttrTypeNative:cn"] forKey:@"cn"];
		} else {
			[record setObject:@"NA" forKey:@"cn"];
		}
		if ([computerAccountInfo objectForKey:@"dsAttrTypeNative:DNSName"]) {
			[record setObject:[computerAccountInfo objectForKey:@"dsAttrTypeNative:DNSName"] forKey:@"DNSName"];
		} else {
			[record setObject:@"NA" forKey:@"DNSName"];
		}
		
		if ([computerAccountInfo objectForKey:@"dsAttrTypeNative:llnlHosts"]) {
			if ([[computerAccountInfo objectForKey:@"dsAttrTypeNative:llnlHosts"] count] > 0) {
				[record setObject:@"1" forKey:@"HasSLAM"];	
			}
		} else {
			[record setObject:@"0" forKey:@"HasSLAM"];	
		}
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"%@",[e description]);
	}	

done:	
	logit(lcl_vDebug,@"%@",record);
	result = [NSArray arrayWithObject:record];
	return result;	
}

- (NSArray *)parseDirectoryServicesDataForPreLion
{
	NSArray *result;
	NSDictionary *adPlist;
	NSMutableDictionary *record = [[NSMutableDictionary alloc] initWithDictionary:[self emptyDirectoryServicesDataRecord]];
	NSString *computerName = @"NA";
	
	@try {
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Preferences/DirectoryService/ActiveDirectory.plist"] == NO) 
			goto done;
		
		// Will need to change for 10.7 support
		
		adPlist = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Preferences/DirectoryService/ActiveDirectory.plist"];
		// Is Bound
		if ([[adPlist allKeys] containsObject:@"AD Bound to Domain"]) {
			if ([[adPlist valueForKey:@"AD Bound to Domain"] boolValue] == TRUE) {
				[record setObject:@"1" forKey:@"Bound_To_Domain"];
			} else {
				goto done;
			}
		}
		// Computer Name
		if ([[adPlist allKeys] containsObject:@"AD Computer ID"]) {
			computerName = [NSString stringWithString:[adPlist objectForKey:@"AD Computer ID"]];
			[record setObject:computerName forKey:@"AD_Computer_ID"];
		}
		// Kerbname
		if ([[adPlist allKeys] containsObject:@"AD Computer Kerberos ID"]) {
			[record setObject:[adPlist objectForKey:@"AD Computer Kerberos ID"] forKey:@"AD_Kerberos_ID"];
		}
		
		NSDirectoryServices *dsSearch = [[[NSDirectoryServices alloc] init] autorelease];
		NSDictionary *computerAccountInfo = [dsSearch getRecord:computerName ofType:DHDSComputerAccountType fromNode:DHDSSEARCHNODE];
		
		if ([computerAccountInfo objectForKey:@"dsAttrTypeNative:distinguishedName"]) {
			[record setObject:[computerAccountInfo objectForKey:@"dsAttrTypeNative:distinguishedName"] forKey:@"distinguishedName"];
		} else {
			[record setObject:@"NA" forKey:@"distinguishedName"];
		}
		if ([computerAccountInfo objectForKey:@"dsAttrTypeNative:cn"]) {
			[record setObject:[computerAccountInfo objectForKey:@"dsAttrTypeNative:cn"] forKey:@"cn"];
		} else {
			[record setObject:@"NA" forKey:@"cn"];
		}
		if ([computerAccountInfo objectForKey:@"dsAttrTypeNative:DNSName"]) {
			[record setObject:[computerAccountInfo objectForKey:@"dsAttrTypeNative:DNSName"] forKey:@"DNSName"];
		} else {
			[record setObject:@"NA" forKey:@"DNSName"];
		}
		if ([computerAccountInfo objectForKey:@"dsAttrTypeNative:ADDomain"]) {
			[record setObject:[computerAccountInfo objectForKey:@"dsAttrTypeNative:ADDomain"] forKey:@"ADDomain"];
		} else {
			[record setObject:@"NA" forKey:@"ADDomain"];
		}
		
		if ([computerAccountInfo objectForKey:@"dsAttrTypeNative:llnlHosts"]) {
			if ([[computerAccountInfo objectForKey:@"dsAttrTypeNative:llnlHosts"] count] > 0) {
				[record setObject:@"1" forKey:@"HasSLAM"];	
			}
		} else {
			[record setObject:@"0" forKey:@"HasSLAM"];	
		}
		
	}
	@catch (NSException * e) {
		logit(lcl_vError,@"%@",[e description]);
	}		
	
done:
	logit(lcl_vDebug,@"%@",record);
	result = [NSArray arrayWithObject:record];
	return result;
}

- (NSArray *)parseAppUsageData
{
	logit(lcl_vInfo, @"Begin parsing application usage data.");
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *appSupportDir = @"/Library/Application Support/MPClientStatus";
	NSString *appDB = [appSupportDir stringByAppendingPathComponent:@"mpapp.db"];
	
	if ([fm fileExistsAtPath:appSupportDir] == NO) {
		logit(lcl_vInfo, @"No application usage data to parse.");
		return nil;
	}
	
	if ([fm fileExistsAtPath:appDB] == NO) {
		logit(lcl_vError, @"Application usage data is missing.");
		return nil;
	}
	NSMutableArray *rows = [[NSMutableArray alloc] init];
	NSMutableDictionary *_rec = nil;
	NSArray *columns = [NSArray arrayWithObjects:@"app_name",@"app_path",@"app_version",@"last_launched",@"times_launched",nil];
	FMDatabase *db = [FMDatabase databaseWithPath:appDB];
	if (![db open]) {
        logit(lcl_vError,@"Could not open app usage data file.");
		[rows release];
        return nil;
    }
	FMResultSet *rs = [db executeQuery:@"select app_name,app_path,app_version,last_launched,times_launched from appUsage"];
    while ([rs next]) {
		_rec = [[NSMutableDictionary alloc] init];
		for (id col in columns) {
			if ([rs stringForColumn:col]) {
				[_rec setObject:[rs stringForColumn:col] forKey:col];
			} else {
				[_rec setObject:@"" forKey:col];
			}
		}
		logit(lcl_vDebug, @"App Usage Row: %@",_rec);
		[rows addObject:_rec];
		[_rec release];
		_rec = nil;
    }
    // close the result set.
    // it'll also close when it's dealloc'd, but we're closing the database before
    // the autorelease pool closes, so sqlite will complain about it.
    [rs close]; 
	[db close];
	NSArray *results = [NSArray arrayWithArray:rows];
	[rows release];
	rows = nil;
	logit(lcl_vDebug, @"App Usage results: %@",results);
	return results;
}

- (NSArray *)parseInternetPlugins
{
	/*
	 *	Locations
	 *	/Library/Internet Plug-Ins
	 *	/System/Library/Internet Plug-Ins
	 *	~/Library/Internet Plug-Ins
	*/ 
	/*
	 *	Data Struct 
		<dict>
			<key>name</key>
			<key>path</key>
			<key>path_real</key>
			<key>version</key>
			<key>lastModified</key>
			<key>WebPluginName</key>
			<key>BundleIdentifier</key>
		</dict>
	*/
	NSArray *plugins = nil;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSArray *searchPaths = [NSArray arrayWithObjects:@"/Library/Internet Plug-Ins",@"/System/Library/Internet Plug-Ins",nil];
	NSPredicate *pluginPredicate = [NSPredicate predicateWithFormat:@"(SELF ENDSWITH 'plugin') OR (SELF ENDSWITH 'webplugin')"];
	
	NSMutableArray *plugInsTmp = [[NSMutableArray alloc] init];
	NSMutableArray *plugInsDictArray = [[NSMutableArray alloc] init];
	NSArray *curDirPlugins;
	
	for (NSString *path in searchPaths) { 
		curDirPlugins = [[fm contentsOfDirectoryAtPath:path error:NULL] filteredArrayUsingPredicate:pluginPredicate];
		for (NSString *p_path in curDirPlugins) {
			[plugInsTmp addObject:[NSString stringWithFormat:@"%@/%@",path,p_path]];
		}	
	}	
	
	// Build Array of Internet Plugin Info
	NSMutableDictionary *tmpPluginDict;
	for (NSString *plugin in plugInsTmp) {
		tmpPluginDict = [[NSMutableDictionary alloc] init];
		[tmpPluginDict setObject:[plugin lastPathComponent] forKey:@"name"];
		[tmpPluginDict setObject:plugin forKey:@"path"];
		[tmpPluginDict setObject:plugin forKey:@"path_real"];
		
		// If the path is a sym link we need the full path to get attributes
		if ([[[fm attributesOfItemAtPath:plugin error:NULL] fileType] isEqualToString:NSFileTypeSymbolicLink]) {
			[tmpPluginDict setObject:[fm destinationOfSymbolicLinkAtPath:plugin error:NULL] forKey:@"path_real"];		
		}
		
		[tmpPluginDict setObject:[[fm attributesOfItemAtPath:plugin error:NULL] fileModificationDate] forKey:@"lastModified"];
		[tmpPluginDict setObject:[self readKeyFromFile:[tmpPluginDict objectForKey:@"path_real"] key:@"WebPluginName" error:NULL] forKey:@"WebPluginName"];
		[tmpPluginDict setObject:[self readKeyFromFile:[tmpPluginDict objectForKey:@"path_real"] key:@"CFBundleShortVersionString" error:NULL] forKey:@"version"];
		[tmpPluginDict setObject:[self readKeyFromFile:[tmpPluginDict objectForKey:@"path_real"] key:@"CFBundleIdentifier" error:NULL] forKey:@"BundleIdentifier"];
		
		[plugInsDictArray addObject:tmpPluginDict];
		[tmpPluginDict release];
		tmpPluginDict=nil;
	}	
	[plugInsTmp release];
	
		
	plugins = [NSArray arrayWithArray:plugInsDictArray];
	[plugInsDictArray release];
	
	return plugins;
}

- (NSArray *)parseLocalClientTasks
{
	NSArray *_tasks = nil;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if ([fm fileExistsAtPath:kTasksPlist]) {
		NSDictionary *_tasksDict = [NSDictionary dictionaryWithContentsOfFile:kTasksPlist];
		_tasks = [NSArray arrayWithArray:[_tasksDict objectForKey:@"mpTasks"]];
	}
	
	return _tasks;
}

- (NSString *)readKeyFromFile:(NSString *)aPath key:(NSString *)aKey error:(NSError **)err
{
	NSString *result = @"NA";
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableDictionary *details;
	NSString *pathContents = [aPath stringByAppendingPathComponent:@"Contents"];
	NSString *pathInfo = [pathContents stringByAppendingPathComponent:@"Info.plist"];
	
	if ([fm fileExistsAtPath:pathInfo]) {
		
	} else {
		if (err != NULL) {
			// populate the error object with the details
			details = [NSMutableDictionary dictionary];
			[details setValue:[NSString stringWithFormat:@"File %@ does not exist.",pathInfo] forKey:NSLocalizedDescriptionKey];
			if (err != NULL)  *err = [NSError errorWithDomain:@"world" code:1 userInfo:details];
			logit(lcl_vError, @"File %@ does not exist.",pathInfo);
		}
		goto done;
	}
	
	NSString *l_error = NULL;
	NSPropertyListFormat format;
	NSData *data = [NSData dataWithContentsOfFile:pathInfo];
	NSMutableDictionary *thePlist = [NSPropertyListSerialization propertyListFromData:data 
																	 mutabilityOption:NSPropertyListImmutable 
																			   format:&format 
																	 errorDescription:&l_error];
	
	if (!thePlist) {
		details = [NSMutableDictionary dictionary];
		[details setValue:[NSString stringWithFormat:@"Error, %@ reading plist %@.",l_error, pathInfo] forKey:NSLocalizedDescriptionKey];
		if (err != NULL) *err = [NSError errorWithDomain:@"world" code:2 userInfo:details];
		logit(lcl_vError, @"Error, %@ reading plist %@.",l_error, pathInfo);
		goto done;
	} 
	
	if ([thePlist objectForKey:aKey]) {
		result = [NSString stringWithString:[thePlist objectForKey:aKey]];
	}	
	
done:	
	return result;
}

- (NSArray *)parseLocalDiskInfo
{
    CHDiskInfo *cdi = [CHDiskInfo new];
    NSArray *_disks = [NSArray arrayWithArray:[cdi collectDiskInfoForLocalDisks]];
    return _disks;
}

- (NSArray *)parseLocalUsers
{
    MPUsersAndGroups *m = [[MPUsersAndGroups alloc] init];
    NSError *err = nil;
    NSArray *_users = [m getLocalUsers:&err];
    if (err) {
        logit(lcl_vError,@"Getting local users, %@",[err description]);
        return nil;
    }
    [m release];
    return _users;
}

- (NSArray *)parseLocalGroups
{
    MPUsersAndGroups *m = [[MPUsersAndGroups alloc] init];
    NSError *err = nil;
    NSArray *_groups = [m getLocalGroups:&err];
    if (err) {
        logit(lcl_vError,@"Getting local groups, %@",[err description]);
        return nil;
    }
    [m release];
    return _groups;
}

- (NSArray *)parseFileVaultInfo
{
    MPFileVaultInfo *fv = [[MPFileVaultInfo alloc] init];
    NSMutableDictionary *fvDict = [[[NSMutableDictionary alloc] init] autorelease];
    [fvDict setObject:[NSString stringWithFormat:@"%d",[fv state]] forKey:@"state" defaultObject:@"0"];
    [fvDict setObject:[fv status] forKey:@"status" defaultObject:@"na"];
    [fvDict setObject:[fv users] forKey:@"users" defaultObject:@"na"];
    
    NSArray *res = [NSArray arrayWithObject:(NSDictionary *)fvDict];
    [fv release];
    return res;
}

- (NSDictionary *)pwrSchema
{
    NSMutableDictionary *newDic = [[NSMutableDictionary alloc] init];
    [newDic setObject:@"" forKey:@"profile_name" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"autopoweroff_delay" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"autopoweroff_enabled" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"darkwakebackgroundtasks" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"disk_sleep_timer" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"display_sleep_timer" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"display_sleep_uses_dim" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"gpuswitch" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"hibernate_file" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"hibernate_mode" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"prioritizenetworkreachabilityoversleep" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"standby_delay" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"standby_enabled" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"system_sleep_timer" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"ttyspreventsleep" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"wake_on_ac_change" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"wake_on_clamshell_open" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"wake_on_lan" defaultObject:@"na"];
    [newDic setObject:@"" forKey:@"reducebrightness" defaultObject:@"na"];
    
    return (NSDictionary *)newDic;
}

- (NSArray *)parsePowerManagmentInfo
{
    NSArray *pwrData = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableDictionary *details;
	NSString *pmPlist = @"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist";
	
	if ([fm fileExistsAtPath:pmPlist])
    {
        NSDictionary *pmDataRaw = [NSDictionary dictionaryWithContentsOfFile:pmPlist];
        if ([pmDataRaw objectForKey:@"Custom Profile"]) {
            
        }
	} else {
        logit(lcl_vError, @"File %@ does not exist.",pmPlist);
	}
    
    return pwrData;
}

#pragma mark Helper

- (NSDictionary *)stringToDict:(NSString *)theString theDelimiter:(NSString *)theDelimiter
{
	//First, we want to split out based on line endings
	NSMutableDictionary *keyValData = [NSMutableDictionary dictionary];
	NSArray *lines = [theString componentsSeparatedByString:@"\n"];
	
	int i = 0;
	for (i=0;i<[lines count];i++)
	{
		NSArray *split = [[lines objectAtIndex:i] componentsSeparatedByString:theDelimiter];
		if ([split count] == 2) {
			[keyValData setObject:[split lastObject] forKey:[split objectAtIndex:0]];
		}
	}

	return (NSDictionary *)keyValData;
}



@end
