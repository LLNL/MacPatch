//
//  MPSettings.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/12/17.
//
//

#import "MPSettings.h"
#import <IOKit/IOKitLib.h>

#import "Agent.h"
#import "Server.h"
#import "Suserver.h"
#import "Task.h"
#import "MPHTTPRequest.h"

#define SCHEMA_REV  340


#undef  ql_component
#define ql_component lcl_cMPSettings

static MPSettings *_instance;

@interface MPSettings ()

@property (nonatomic, readwrite) NSFileManager *fm;

@property (nonatomic, strong, readwrite) NSString *ccuid;
@property (nonatomic, strong, readwrite) NSString *serialno;
@property (nonatomic, strong, readwrite) NSString *osver;
@property (nonatomic, strong, readwrite) NSString *ostype;
@property (nonatomic, strong, readwrite) NSString *agentVer;
@property (nonatomic, strong, readwrite) NSString *clientVer;

@property (nonatomic, strong, readwrite) Agent *agent;
@property (nonatomic, strong, readwrite) NSArray *servers;
@property (nonatomic, strong, readwrite) NSArray *suservers;
@property (nonatomic, strong, readwrite) NSArray *tasks;

@end

@implementation MPSettings

@synthesize fm;

@synthesize ccuid;
@synthesize serialno;
@synthesize osver;
@synthesize ostype;
@synthesize agentVer;
@synthesize clientVer;

@synthesize agent;
@synthesize servers;
@synthesize suservers;
@synthesize tasks;

+ (MPSettings *)sharedInstance
{
    @synchronized(self)
    {
        if (_instance == nil)
		{
            _instance = [[super allocWithZone:NULL] init];
            _instance = [[MPSettings alloc] init];
            // Perform other initialisation...
            _instance.fm = [NSFileManager defaultManager];
            
            // Set Permissions on db file
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:[NSNumber numberWithInt:511] forKey:NSFilePosixPermissions];
            NSError *error = nil;
            [_instance.fm setAttributes:dict ofItemAtPath:MP_AGENT_SETTINGS error:&error];
            [_instance setCcuid:[_instance clientID]];
            [_instance setSerialno:[_instance clientSerialNumber]];
            [_instance collectOSInfo];
            [_instance settings];
			[_instance collectAgentVersionData];
        }
    }
    return _instance;
}

#pragma mark Singleton Methods

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark - Public
- (BOOL)refresh
{
    return [self settings];
}

- (BOOL)settings
{
    NSDictionary *_settings;
    
    if (![fm fileExistsAtPath:MP_AGENT_SETTINGS])
    {
        // No Settings File, need to download and create
        _settings = [self allSettingsFromServer:YES];
        qlinfo(@"Writing new agent settings to disk.");
        
        if ([fm isWritableFileAtPath:[MP_AGENT_SETTINGS stringByDeletingLastPathComponent]]) {
            [_settings writeToFile:MP_AGENT_SETTINGS atomically:YES];
        } else {
            qlerror(@"Unable to write file to %@",[MP_AGENT_SETTINGS stringByDeletingLastPathComponent]);
            return NO;
        }
    }
    else
    {
        _settings = [NSDictionary dictionaryWithContentsOfFile:MP_AGENT_SETTINGS];
    }
    
    self.agent      = [[Agent alloc] initWithDictionary:_settings[@"settings"][@"agent"][@"data"]];
    self.servers    = [self serversFromDictionary:_settings[@"settings"][@"servers"]];
    self.suservers  = [self suServersFromDictionary:_settings[@"settings"][@"suservers"]];
    self.tasks      = [self tasksFromDictionary:_settings[@"settings"][@"tasks"]];
	
	[self collectAgentVersionData];
    
    return YES;
}

- (NSDictionary *)settingsRevisionsFromServer:(BOOL)useAgentPlist
{
    NSDictionary *data;
    MPHTTPRequest *req;
    MPWSResult *result;
    
    if (useAgentPlist) {
        req = [[MPHTTPRequest alloc] initWithAgentPlist];
    } else {
        req = [[MPHTTPRequest alloc] init];
    }
    
    NSString *urlPath = [@"/api/v1/agent/config/info" stringByAppendingPathComponent:self.ccuid];
    result = [req runSyncGET:urlPath];
    
    if (result.statusCode >= 200 && result.statusCode <= 299) {
        logit(lcl_vInfo,@"Agent Settings data, returned true.");
        data = result.result[@"data"][@"settings"];
    } else {
        logit(lcl_vError,@"Agent Settings data, returned false.");
        logit(lcl_vDebug,@"%@",result.toDictionary);
        return nil;
    }
    
    return data;
}

- (NSDictionary *)allSettingsFromServer:(BOOL)useAgentPlist
{
    NSDictionary *data;
    MPHTTPRequest *req;
    MPWSResult *result;
    
    if (useAgentPlist) {
        logit(lcl_vDebug,@"[MPHTTPRequest] Using Agent Plist");
        req = [[MPHTTPRequest alloc] initWithAgentPlist];
    } else {
        req = [[MPHTTPRequest alloc] init];
    }
    
    NSString *urlPath = [@"/api/v2/agent/config/data" stringByAppendingPathComponent:self.ccuid];
    result = [req runSyncGET:urlPath];
    
    if (result.statusCode >= 200 && result.statusCode <= 299) {
        logit(lcl_vInfo,@"Agent Settings data, returned true.");
        data = result.result[@"data"];
    } else {
        logit(lcl_vError,@"Agent Settings data, returned false.");
        logit(lcl_vDebug,@"%@",result.toDictionary);
        return nil;
    }
    
    return data;
}

- (BOOL)compareAndUpdateSettings:(NSDictionary *)remoteSettingsRevs
{
	[self refresh];
	
    NSDictionary *local = [NSDictionary dictionaryWithContentsOfFile:MP_AGENT_SETTINGS];
    NSDictionary *localRevs = local[@"revs"];
	NSString *localID = self.agent.groupId;
	NSString *remoteID = @"";
	NSDictionary *remoteRevs = remoteSettingsRevs[@"revs"];
	if (!remoteSettingsRevs) {
		qlerror(@"Unable to obtain remote data. Network connection may be down.");
		return NO;
	}
	
    if ([localRevs isEqualToDictionary:remoteRevs])
	{
        qldebug(@"Setting Revisions did match.");
        return YES;
    } else {
        qlinfo(@"Setting Revisions did not match. Updating settings.");
		qlinfo(@"localRevs: %@",localRevs);
		qlinfo(@"remoteSettingsRevs: %@",remoteRevs);
        NSDictionary *remoteSettings = [self allSettingsFromServer:NO];
		
		if (!remoteSettingsRevs[@"id"]) {
			remoteID = remoteSettings[@"settings"][@"agent"][@"data"][@"client_group_id"];
		} else {
			remoteID = remoteSettingsRevs[@"id"];
		}
		
		if (![localID isEqualToString:remoteID])
		{
			// Update all, group id does not match
			qlinfo(@"Client group has been changed. Update all settings.");
			localRevs = @{@"agent":@0,@"servers":@0,@"suservers":@0,@"tasks":@0,@"swrestrictions":@0};
		}
		
        if ([[remoteRevs objectForKey:@"agent"] intValue] != [[localRevs objectForKey:@"agent"] intValue]) {
            // Usdate Agent Settings
            qlinfo(@"Update Agent Settings, settings did not match.");
            [self updateSettingsUsingKey:@"agent" settings:remoteSettings[@"settings"][@"agent"]];
        }
        if ([[remoteRevs objectForKey:@"servers"] intValue] != [[localRevs objectForKey:@"servers"] intValue]) {
            // Usdate Servers
            qlinfo(@"Update Agent Servers, servers did not match.");
			// Massage data before entering it in to the plist
			NSDictionary *d = [self serverSettingsFromDictionary:remoteSettings[@"settings"][@"servers"]];
			[self updateSettingsUsingKey:@"servers" settings:d];
        }
        if ([[remoteRevs objectForKey:@"suservers"] intValue] != [[localRevs objectForKey:@"suservers"] intValue]) {
            // Usdate SUServers
            qlinfo(@"Update Agent SUServers, SUServers did not match.");
            [self updateSettingsUsingKey:@"suservers" settings:remoteSettings[@"settings"][@"suservers"]];
        }
        if ([[remoteRevs objectForKey:@"tasks"] intValue] != [[localRevs objectForKey:@"tasks"] intValue]) {
            // Usdate Tasks
            qlinfo(@"Update Agent tasks, tasks did not match.");
            [self updateSettingsUsingKey:@"tasks" settings:remoteSettings[@"settings"][@"tasks"]];
        }
		if ([[remoteRevs objectForKey:@"swrestrictions"] intValue] != [[self readSoftwareRestrictionRevisionFromFile] intValue]) {
			// Usdate Tasks
			qlinfo(@"Update Software restrictions, restrictions did not match.");
			[self writeNewSoftwareRestritionsFile];
		}
        qlinfo(@"Setting have been updated.");
    }
    
    return YES;
}

- (void)updateSettingsUsingKey:(NSString *)key settings:(NSDictionary *)agentSettings
{
	if (agentSettings)
	{
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:MP_AGENT_SETTINGS];
		[dict[@"settings"] setObject:agentSettings forKey:key];
		[dict[@"revs"] setObject:agentSettings[@"rev"] forKey:key];
		[dict writeToFile:MP_AGENT_SETTINGS atomically:YES];
	}
	else
	{
		qlerror(@"Unable to update setting for key \"%@\", value was null.",key);
	}
}

#pragma mark - Private

- (NSString *)clientID
{
    NSString *result = NULL;
    io_struct_inband_t iokit_entry;
    uint32_t bufferSize = 4096; // this signals the longest entry we will take
    io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
    IORegistryEntryGetProperty(ioRegistryRoot, kIOPlatformUUIDKey, iokit_entry, &bufferSize);
    result = [NSString stringWithCString:iokit_entry encoding:NSASCIIStringEncoding];
    
    IOObjectRelease((unsigned int) iokit_entry);
    IOObjectRelease(ioRegistryRoot);
    
    return result;
}

- (NSString *)clientSerialNumber
{
    NSString *result = nil;
    
    io_registry_entry_t rootEntry = IORegistryEntryFromPath( kIOMasterPortDefault, "IOService:/" );
    CFTypeRef serialAsCFString = NULL;
    
    serialAsCFString = IORegistryEntryCreateCFProperty( rootEntry,
                                                       CFSTR(kIOPlatformSerialNumberKey),
                                                       kCFAllocatorDefault,
                                                       0);
    
    IOObjectRelease( rootEntry );
    if (serialAsCFString == NULL) {
        result = @"NA";
    } else {
        result = [NSString stringWithFormat:@"%@",(__bridge NSString *)serialAsCFString];
        CFRelease(serialAsCFString);
    }
    
    return result;
}

- (void)collectOSInfo
{
    self.osver = @"10.0.0";
    self.ostype = @"Mac OS X";
    
    NSDictionary *results = nil;
    
    NSString *clientVerPath = @"/System/Library/CoreServices/SystemVersion.plist";
    NSString *serverVerPath = @"/System/Library/CoreServices/ServerVersion.plist";
    
    if ([fm fileExistsAtPath:serverVerPath] == TRUE) {
        results = [NSDictionary dictionaryWithContentsOfFile:serverVerPath];
    } else {
        if ([fm fileExistsAtPath:clientVerPath] == TRUE) {
            results = [NSDictionary dictionaryWithContentsOfFile:clientVerPath];
        }
    }
    
    if (results) {
        if ([results objectForKey:@"ProductVersion"]) self.osver = [results objectForKey:@"ProductVersion"];
        if ([results objectForKey:@"ProductName"]) self.ostype = [results objectForKey:@"ProductName"];
    }
}

- (NSDictionary *)settingsRevisionsFromFile
{
    NSDictionary *result = nil;
    if ([fm fileExistsAtPath:MP_AGENT_SETTINGS])
    {
        NSDictionary *_settingsDict = [NSDictionary dictionaryWithContentsOfFile:MP_AGENT_SETTINGS];
        if ([_settingsDict objectForKey:@"revs"]) {
            result = [_settingsDict objectForKey:@"revs"];
        }
    }
    return result;
}

- (NSArray *)serversFromDictionary:(NSDictionary *)settings
{
	
	NSMutableArray *_srvs = [NSMutableArray new];
	NSMutableArray *_srvsRaw = [NSMutableArray new];
	NSArray *_raw_srvs = settings[@"data"];
	
	NSDictionary *_master = nil;
	NSDictionary *_proxy = nil;
	
	for (NSDictionary *_srv in _raw_srvs)
	{
		if ([_srv[@"serverType"] integerValue] == 0) {
			_master = [_srv copy];
			continue;
		}
		
		if ([_srv[@"serverType"] integerValue] == 2) {
			_proxy = [_srv copy];
			continue;
		}
		
		[_srvsRaw addObject:[_srv copy]];
	}
	
	// Randomize the array of servers
	//_srvsRaw = [[self randomizeArray:_srvsRaw] mutableCopy];
	if (_master) [_srvsRaw addObject:_master]; // Add the master
	if (_proxy) [_srvsRaw addObject:_proxy]; // Add the proxy
	
	for (NSDictionary *s in _srvsRaw)
	{
		[_srvs addObject:[[Server alloc] initWithDictionary:s]];
	}
	
	// Now we just read the plist, it's server list is randomized on version rev
	return (NSArray *)_srvs;
}


/// Read and randomize and sort MacPatch servers. Returns servers in normal
/// dictionary format, serversFromDictionary method will translate to the
/// model format.
///
/// @param settings servers dictionary
- (NSDictionary *)serverSettingsFromDictionary:(NSDictionary *)settings
{
	NSMutableDictionary *_newSettings = [NSMutableDictionary dictionaryWithDictionary:settings];
	NSMutableArray *_srvs = [NSMutableArray new];
	NSArray *_raw_srvs = settings[@"data"];
	
	NSDictionary *_master = nil;
	NSDictionary *_proxy = nil;
	
	for (NSDictionary *_srv in _raw_srvs)
	{
		if ([_srv[@"serverType"] integerValue] == 0) {
			_master = [_srv copy];
			continue;
		}
		
		if ([_srv[@"serverType"] integerValue] == 2) {
			_proxy = [_srv copy];
			continue;
		}
		
		[_srvs addObject:[_srv copy]];
	}
	
	_srvs = [[self randomizeArray:_srvs] mutableCopy]; // Randomize the array of servers
	if (_master) [_srvs addObject:_master]; // Add the master
	if (_proxy) [_srvs addObject:_proxy]; // Add the proxy
	
	_newSettings[@"data"] = _srvs;
	return _newSettings;
}


- (NSArray *)suServersFromDictionary:(NSDictionary *)settings
{
	NSMutableArray *_srvs = [NSMutableArray new];
	if (@available(macOS 10.15, *)) {
		// macOS 10.13 or later code path
		qltrace(@"suServersFromDictionary is no longer supported by Apple.");
	} else {
		// code for earlier than 10.14
		
		NSArray *_raw_srvs = settings[@"data"];
		
		NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:@"serverType" ascending:YES];
		_raw_srvs = [_raw_srvs sortedArrayUsingDescriptors:@[descriptor]];
		
		for (NSDictionary *_srv in _raw_srvs)
		{
			[_srvs addObject:[[Suserver alloc] initWithDictionary:_srv]];
		}
	}
    return (NSArray *)_srvs;
}

- (NSArray *)tasksFromDictionary:(NSDictionary *)settings
{
    return settings[@"data"];
}

- (NSArray *)randomizeArray:(NSArray *)arrayToRandomize
{
    NSMutableArray *_newArray = [[NSMutableArray alloc] initWithArray:arrayToRandomize];
    NSUInteger count = [_newArray count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between i and end of array to swap with.
        NSInteger nElements = count - i;
        NSInteger n = (arc4random() % nElements) + i;
        [_newArray exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
    
    return (NSArray *)_newArray;
}

- (NSString *)readSoftwareRestrictionRevisionFromFile
{
	if (![fm fileExistsAtPath:SW_RESTRICTIONS_PLIST]) return @"0-0";
	
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:SW_RESTRICTIONS_PLIST];
	if ([d objectForKey:@"revision"]) {
		return [d objectForKey:@"revision"];
	}
	
	return @"0-0";
}

- (BOOL)writeNewSoftwareRestritionsFile
{
	NSError *err = nil;
	MPRESTfull *mpr = [MPRESTfull new];
	NSDictionary *res = [mpr getSoftwareRestrictions:&err];
	if (err) {
		qlerror(@"%@",err.localizedDescription);
		return NO;
	}
	[res writeToFile:SW_RESTRICTIONS_PLIST atomically:NO];
	return YES;
}

- (void)collectAgentVersionData
{
	NSDictionary *verData = nil;
	if ([fm fileExistsAtPath:AGENT_VER_PLIST]) {
		if ([fm isReadableFileAtPath:AGENT_VER_PLIST] == NO ) {
			[fm setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0664UL] forKey:NSFilePosixPermissions]
				 ofItemAtPath:AGENT_VER_PLIST
						error:NULL];
		}
		verData = [NSDictionary dictionaryWithContentsOfFile:AGENT_VER_PLIST];
	} else {
		verData = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"NA",@"NA",@"NA",@"NA",@"NA",@"NA",nil]
											   forKeys:[NSArray arrayWithObjects:@"version",@"major",@"minor",@"bug",@"build",@"framework",nil]];
	}
	
	agentVer = [NSString stringWithFormat:@"%@.%@.%@",verData[@"major"],verData[@"minor"],verData[@"bug"]];
	clientVer = [NSString stringWithFormat:@"%@.%@.%@.%@",verData[@"major"],verData[@"minor"],verData[@"bug"],verData[@"build"]];
}
@end
