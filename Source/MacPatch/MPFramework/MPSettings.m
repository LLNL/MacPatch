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
#import "MPHTTPRequest.h"

#define SCHEMA_REV  310


#undef  ql_component
#define ql_component lcl_cMPSettings

static NSString *MP_SETTINGS_FILE = @"/Library/Preferences/gov.llnl.mp.plist";

@interface MPSettings ()

@property (nonatomic, readwrite) NSFileManager *fm;

@property (nonatomic, strong, readwrite) NSString *ccuid;
@property (nonatomic, strong, readwrite) NSString *serialno;

@property (nonatomic, strong, readwrite) Agent *agent;
@property (nonatomic, strong, readwrite) Server *server;
@property (nonatomic, strong, readwrite) Suserver *suserver;
@property (nonatomic, strong, readwrite) Task *task;

@end

@implementation MPSettings

@synthesize fm;

@synthesize ccuid;
@synthesize serialno;

@synthesize agent;
@synthesize server;
@synthesize suserver;
@synthesize task;

+ (instancetype)settings
{
    static MPSettings *settings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = [[MPSettings alloc] init];
        // Perform other initialisation...
        settings.fm = [NSFileManager defaultManager];
        
        // Set Permissions on db file
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[NSNumber numberWithInt:511] forKey:NSFilePosixPermissions];
        NSError *error = nil;
        [settings.fm setAttributes:dict ofItemAtPath:MP_SETTINGS_FILE error:&error];
        
        settings.ccuid = [settings clientID];
        settings.serialno = [settings clientSerialNumber];
    });
    return settings;
}

- (id)init
{
    return [MPSettings settings];
}

- (BOOL)settings
{
    if ([fm fileExistsAtPath:MP_SETTINGS_FILE])
    {
        NSDictionary *_sf = [NSDictionary dictionaryWithContentsOfFile:MP_SETTINGS_FILE];
        if ([_sf objectForKey:@"schema"])
        {
            if ([[_sf objectForKey:@"schema"] intValue] != (int)SCHEMA_REV)
            {
                // Schema does not match, need to re-write it
            }
        }
        else
        {
            return FALSE;
        }
    }
    else
    {
        // No Settings File, need to download and create
    }
    
    return FALSE;
}

- (NSDictionary *)allSettingsFromServer:(BOOL)useAgentPlist
{
    MPHTTPRequest *req;
    MPWSResult *result;
    
    if (useAgentPlist) {
        req = [[MPHTTPRequest alloc] initWithAgentPlist];
    } else {
        req = [[MPHTTPRequest alloc] init];
    }
    
    NSString *urlPath = [@"/api/v1/agent/config/data" stringByAppendingPathComponent:self.ccuid];
    result = [req runSyncGET:urlPath];
    
    if (result.statusCode >= 200 && result.statusCode <= 299) {
        logit(lcl_vInfo,@"Agent Settings data, returned true.");
    } else {
        logit(lcl_vError,@"Agent Settings data, returned false.");
        logit(lcl_vDebug,@"%@",result.toDictionary);
        return nil;
    }
    
    return result.result;
}

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


/*
- (int)populateDefaultData:(NSString *)aFile error:(NSError **)error
{
    NSError *err = nil;
    NSData *jData = [NSData dataWithContentsOfFile:aFile];
    NSDictionary *jDict = [NSJSONSerialization JSONObjectWithData:jData options:kNilOptions error:&err];
    if (err) {
        if (error != NULL) *error = err;
    }
    
    if ([jDict objectForKey:@"AgentConfigInfo"]) {
        int res = [self addAgentConfigInfo:[jDict objectForKey:@"AgentConfigInfo"]];
        if (res == 0) {
            // New record added, add config
            if ([jDict objectForKey:@"AgentConfig"]) {
                int resAdd = [self addAgentConfig:[jDict objectForKey:@"AgentConfig"]];
                if (resAdd != 0) {
                    NSLog(@"Possible Issue with add.");
                }
            }
        }
    } else if ([jDict objectForKey:@"MPServersInfo"]) {
        int res = [self addMPServersInfo:[jDict objectForKey:@"MPServersInfo"]];
        if (res == 0) {
            // New record added, add config
            if ([jDict objectForKey:@"MPServers"]) {
                int resAdd = [self addMPServers:[jDict objectForKey:@"MPServers"]];
                if (resAdd != 0) {
                    NSLog(@"Possible Issue with add.");
                }
            }
        }
    }
    
    return 0;
}


- (int)addAgentConfig:(NSDictionary *)aData
{
    // Add New Config Data
    Agent *ac = [[Agent alloc] init];
    ac.groupId          = aData[@"group_id"];
    ac.patchClient      = [self numberValueTest:aData[@"allow_client"]] ? (NSInteger)aData[@"allow_client"] : 1;
    ac.reboot           = [self numberValueTest:aData[@"allow_reboot"]] ? (NSInteger)aData[@"allow_reboot"] : 1;
    ac.patchServer      = [self numberValueTest:aData[@"allow_server"]] ? (NSInteger)aData[@"allow_server"] : 0;
    ac.swDistGroupAdd   = aData[@"inherited_software_group"] ?: @"NA";
    ac.swDistGroupAddID = aData[@"inherited_software_group_id"] ?: @"0";
    ac.patchGroup       = aData[@"patch_group"] ?: @"NA";
    ac.patchState       = [self numberValueTest:aData[@"patch_state"]] ? (NSInteger)aData[@"patch_state"] : 0;
    ac.swDistGroup      = aData[@"software_group"] ?: @"NA";
    ac.swDistGroupID    = aData[@"software_group_id"] ?: @"0";
    ac.verifySignatures = [self numberValueTest:aData[@"verify_signatures"]] ? (NSInteger)aData[@"verify_signatures"] : 1;
    
    return 0;
}

- (BOOL)numberValueTest:(id)valToTest
{
    if (!valToTest)
        return NO;
    
    if ([valToTest isKindOfClass:[NSNull class]])
        return NO;
    
    return YES
}

- (int)agentConfigVersion
{
    @try
    {
        AgentConfig *ac = (AgentConfig *)[AgentConfig modelByPrimaryKey:@(1)];
        AgentConfigInfo *aci = (AgentConfigInfo *)[AgentConfigInfo modelWhere:@"group_id = :group_id" parameters:@{@"group_id": ac.group_id}];
        NSNumber *local_config_rev = aci.rev;
        return [local_config_rev intValue] ? :0;
        
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
        return 0;
    }
    
}

#define TODO
- (int)addMPServersInfo:(NSDictionary *)aData
{
    return 0;
}

#define TODO
- (int)addMPServers:(NSDictionary *)aData
{
    return 0;
}

#define TODO
- (int)mpServersVersion
{
    return 0;
}

#define TODO
- (int)addSUServersInfo:(NSDictionary *)aData
{
    return 0;
}

#define TODO
- (int)addSUServers:(NSDictionary *)aData
{
    return 0;
}

#define TODO
- (int)suServersVersion
{
    return 0;
}

#define TODO
- (int)addAgentTasksInfo:(NSDictionary *)aData
{
    return 0;
}

#define TODO
- (int)addAgentTasks:(NSDictionary *)aData
{
    return 0;
}

#define TODO
- (int)addAgentTask:(NSDictionary *)aData
{
    return 0;
}

#define TODO
- (int)agentTasksVersion
{
    return 0;
}
 */
@end
