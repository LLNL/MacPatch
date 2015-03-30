//
//  AppDelegate.m
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
#import "AppDelegate.h"
#import "PreferenceController.h"
#import "MPCrypto.h"
#import "NSString+Helper.h"
#import "WebRequest.h"

#define MPADM_URI @"Service/MPAdminService.cfc"

@interface AppDelegate (Private)

- (IBAction)showPreferencePanel:(id)sender;
- (void)populateFromDefaults;
- (void)populateDefaults;

- (void)extractPKG:(NSString *)aPath;
- (void)writePlistForPackage:(NSString *)aPlist;
- (void)showAlertForMissingIdentity;

- (NSString *)encodeURLString:(NSString *)aString;

@end

@implementation AppDelegate

@synthesize extractImage;
@synthesize agentConfigImage;
@synthesize writeConfigImage;
@synthesize flattenPackagesImage;
@synthesize compressPackgesImage;
@synthesize postPackagesImage;
@synthesize progressBar;
@synthesize serverAddress;
@synthesize serverPort;
@synthesize useSSL;
@synthesize extratContentsStatus;
@synthesize getAgentConfStatus;
@synthesize writeConfStatus;
@synthesize flattenPkgStatus;
@synthesize compressPkgStatus;
@synthesize postPkgStatus;
@synthesize uploadButton;
@synthesize identityName;
@synthesize signPKG;
@synthesize tmpDir = _tmpDir;
@synthesize agentID = _agentID;
@synthesize agentDict = _agentDict;
@synthesize updaterDict = _updaterDict;
@synthesize authToken = _authToken;
@synthesize authUserName;
@synthesize authUserPass;
@synthesize authStatus;
@synthesize authProgressWheel;
@synthesize authRequestButton;

- (void)awakeFromNib
{
    fm = [NSFileManager defaultManager];
    [uploadButton setEnabled:NO];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(authTextDidChange:) name:NSControlTextDidChangeNotification object:authUserPass];
    [center addObserver:self selector:@selector(hostTextDidChange:) name:NSControlTextDidChangeNotification object:serverAddress];
    //[self populateFromDefaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (IBAction)showPreferencePanel:(id)sender
{
    // Is preferenceController nil?
    if (!preferenceController) {
        preferenceController = [[PreferenceController alloc] init];
    }
    [preferenceController showWindow:self];
}

- (void)populateFromDefaults
{
    // User Defaults
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d objectForKey:@"dServerAddressState"]) {
        if ([d objectForKey:@"dServerAddress"]) {
            [serverAddress setStringValue:[d objectForKey:@"dServerAddress"]];
        }
    }
    if ([d objectForKey:@"dServerPortState"]) {
        if ([d objectForKey:@"dServerPort"]) {
            [serverPort setStringValue:[d objectForKey:@"dServerPort"]];
        }
    }
    if ([d objectForKey:@"dServerSSLState"]) {
        if ([d objectForKey:@"dServerSSL"]) {
            [useSSL setState:(NSInteger)[d objectForKey:@"dServerSSL"]];
        }
    }
    if ([d objectForKey:@"dIdentityState"]) {
        if ([d objectForKey:@"dIdentity"]) {
            [identityName setStringValue:[d objectForKey:@"dIdentity"]];
        }
    }
}

- (void)populateDefaults
{
    // User Defaults
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d objectForKey:@"dServerAddressState"]) {
        if ((NSInteger)[d objectForKey:@"dServerAddressState"] == NSOnState) {
            [d setObject:serverAddress.stringValue forKey:@"dServerAddress"];
        } else {
            [d removeObjectForKey:@"dServerAddress"];
        }
    }
    if ([d objectForKey:@"dServerPort"]) {
        if ((NSInteger)[d objectForKey:@"dServerPortState"] == NSOnState) {
            [d setObject:serverPort.stringValue forKey:@"dServerPort"];
        } else {
            [d removeObjectForKey:@"dServerPort"];
        }
    }
    if ([d objectForKey:@"dServerPort"]) {
        if ((NSInteger)[d objectForKey:@"dServerSSLState"] == NSOnState) {
            [d setInteger:useSSL.state forKey:@"dServerSSL"];
        } else {
            [d removeObjectForKey:@"dServerSSL"];
        }
    }
    if ([d objectForKey:@"dServerPort"]) {
        if ((NSInteger)[d objectForKey:@"dIdentityState"] == NSOnState) {
            [d setObject:identityName.stringValue forKey:@"dIdentity"];
        } else {
            [d removeObjectForKey:@"dIdentity"];
        }
    }
    [d synchronize];
}

#pragma mark - sheet

-(IBAction)cancelAuthSheet:(id)sender
{
    [NSApp endSheet:authSheet];
    [authSheet orderOut:sender];
}

-(IBAction)makeAuthRequest:(id)sender
{
    [authProgressWheel setUsesThreadedAnimation:YES];
    [authProgressWheel startAnimation:authProgressWheel];
    [self.authStatus setStringValue:@"Authenticating..."];
    
    NSString *_host = serverAddress.stringValue;
    NSString *_port = serverPort.stringValue;
    NSString *_ssl = @"https";
    if (useSSL.state == NSOffState) {
        _ssl = @"http";
    } else {
        _ssl = @"https";
    }
    
    //-- Convert string into URL
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@/%@?method=GetAuthToken&authUser=%@&authPass=%@",_ssl,_host,_port,MPADM_URI,[authUserName.stringValue urlEncode],[authUserPass.stringValue urlEncode]];
    NSMutableURLRequest *request =[[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    
    NSError *error = nil;
    NSURLResponse *response;
    WebRequest *req = [[WebRequest alloc] init];
    NSData *responseData = [req sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error)
    {
        NSLog(@"%@",error.localizedDescription);
        [self.authStatus setStringValue:error.localizedDescription];
        [self.authStatus setToolTip:error.localizedDescription];
        [self.authStatus performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
        [authProgressWheel stopAnimation:authProgressWheel];
        return;
    }
    
    //-- JSON Parsing with response data
    error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
    NSLog(@"[makeAuthRequest]: %@",result);
    if ([result objectForKey:@"result"]) {
        if ([result objectForKey:@"errorno"]) {
            if ([[result objectForKey:@"errorno"] intValue] == 0)
            {
                [self setAuthToken:[result objectForKey:@"result"]];
            }
            else
            {
                [authStatus setStringValue:[result objectForKey:@"errormsg"]];
                [authStatus setToolTip:[result objectForKey:@"errormsg"]];
                [authStatus performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
                [authProgressWheel stopAnimation:authProgressWheel];
                return;
            }
        }
    }
    
    [NSApp endSheet:authSheet];
    [authSheet orderOut:sender];
    [authProgressWheel stopAnimation:authProgressWheel];
    [self.authStatus setStringValue:@" "];
}

- (void)authTextDidChange:(NSNotification *)aNotification
{
    if ([[authUserName stringValue]length]>3 && [[authUserPass stringValue]length]>3) {
        [authRequestButton setEnabled:YES];
    } else {
        [authRequestButton setEnabled:NO];
    }
}

- (void)hostTextDidChange:(NSNotification *)aNotification
{
    /*
     if ([[serverAddress stringValue]length]>3) {
     [authRequestButton setEnabled:YES];
     } else {
     [authRequestButton setEnabled:NO];
     }
     */
}

#pragma mark - Main

- (void)resetInterface
{
    [uploadButton setEnabled:YES];
    [progressBar setIndeterminate:YES];
    [progressBar performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
    [extractImage setImage:[NSImage imageNamed:@"ClearDot"]];
    [extractImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
    [extratContentsStatus setStringValue:@""];
    [agentConfigImage setImage:[NSImage imageNamed:@"ClearDot"]];
    [agentConfigImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
    [getAgentConfStatus setStringValue:@""];
    [writeConfigImage setImage:[NSImage imageNamed:@"ClearDot"]];
    [writeConfigImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
    [writeConfStatus setStringValue:@""];
    [flattenPackagesImage setImage:[NSImage imageNamed:@"ClearDot"]];
    [flattenPackagesImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
    [flattenPkgStatus setStringValue:@""];
    [compressPackgesImage setImage:[NSImage imageNamed:@"ClearDot"]];
    [compressPackgesImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
    [compressPkgStatus setStringValue:@""];
    [postPackagesImage setImage:[NSImage imageNamed:@"ClearDot"]];
    [postPackagesImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
    [postPkgStatus setStringValue:@""];
}

- (IBAction)choosePackage:(id)sender
{
    NSString *fileName;
    int i; // Loop counter.
    
    // Create the File Open Dialog class.
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    
    // Display the dialog.  If the OK button was pressed,
    // process the files.
    if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
    {
        NSArray* files = [openDlg filenames];
        for( i = 0; i < [files count]; i++ )
        {
            fileName = [files objectAtIndex:i];
        }
        
        _packagePathField.stringValue = fileName;
        [uploadButton setEnabled:YES];
    }
}

- (IBAction)uploadPackage:(id)sender
{
    if (!_authToken)
    {
        [NSApp beginSheet:authSheet modalForWindow:(NSWindow *)_window modalDelegate:self didEndSelector:@selector(beginUploadPackage) contextInfo:nil];
    } else {
        [NSThread detachNewThreadSelector:@selector(uploadPackageThread) toTarget:self withObject:nil];
    }
}

- (void)beginUploadPackage
{
    if (_authToken)
    {
        [NSThread detachNewThreadSelector:@selector(uploadPackageThread) toTarget:self withObject:nil];
    }
}

- (void)uploadPackageThread
{
    @autoreleasepool
    {
        if (signPKG.state == NSOnState) {
            if ([identityName.stringValue length] <= 0) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:@"Missing Identity"];
                [alert setInformativeText:@"You have choosen to sign the packages but did not enter an identity name. Please enter an identity name and try again."];
                [alert addButtonWithTitle:@"OK"];
                [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
                return;
            }
        }
        
        [self resetInterface];
        
        NSString *_host = serverAddress.stringValue;
        NSString *_port = serverPort.stringValue;
        NSString *_ssl = @"https";
        if (useSSL.state == NSOffState) {
            _ssl = @"http";
        } else {
            _ssl = @"https";
        }
        
        [uploadButton setEnabled:NO];
        [progressBar setUsesThreadedAnimation:YES];
        [progressBar setIndeterminate:YES];
        [progressBar startAnimation:progressBar];
        
        [extractImage setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
        [extractImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
        [self extractPKG:_packagePathField.stringValue];
        
        [agentConfigImage setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
        [agentConfigImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
        __block NSString *result = nil;
        // NSURLSession *session = [NSURLSession sharedSession];
        NSString *_url = [NSString stringWithFormat:@"%@://%@:%@/%@?method=AgentConfig&token=%@&user=%@",_ssl,_host,_port,MPADM_URI,[self encodeURLString:_authToken],authUserName.stringValue];
        
        NSMutableURLRequest *request =[[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:_url]];
        [request setHTTPMethod:@"GET"];
        //-- Getting response form server
        NSError *error = nil;
        NSURLResponse *response;
        WebRequest *req = [[WebRequest alloc] init];
        NSData *responseData = [req sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error)
        {
            NSLog(@"%@",error.localizedDescription);
            [progressBar stopAnimation:progressBar];
            [agentConfigImage setImage:[NSImage imageNamed:@"NoIcon"]];
            [uploadButton setEnabled:YES];
            [progressBar stopAnimation:progressBar];
            return;
        }
        
        NSError *bErr = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&bErr];
        if (bErr) {
            [agentConfigImage setImage:[NSImage imageNamed:@"NoIcon"]];
            [uploadButton setEnabled:YES];
            [progressBar stopAnimation:progressBar];
            return;
        }
        [agentConfigImage setImage:[NSImage imageNamed:@"YesIcon"]];
        result = [json objectForKey:@"result"];
        
        bErr = nil;
        NSString *_reqID = [self getRequestID:authUserName.stringValue error:&bErr];
        if (bErr) {
            [agentConfigImage setImage:[NSImage imageNamed:@"NoIcon"]];
            [uploadButton setEnabled:YES];
            [progressBar stopAnimation:progressBar];
            return;
        }
        
        [self setAgentID:_reqID];
        NSArray *pkgs1;
        
        bErr = nil;
        [writeConfigImage setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
        [writeConfigImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
        pkgs1 = [self writePlistForPackage:result error:&bErr];
        if (bErr) {
            [writeConfigImage setImage:[NSImage imageNamed:@"NoIcon"]];
            [uploadButton setEnabled:YES];
            [progressBar stopAnimation:progressBar];
            return;
        } else {
            [writeConfigImage setImage:[NSImage imageNamed:@"YesIcon"]];
        }
        
        NSArray *pkgs2;
        bErr = nil;
        [flattenPackagesImage setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
        [flattenPackagesImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
        pkgs2 = [self flattenPackages:pkgs1 error:&bErr];
        if (bErr) {
            [flattenPackagesImage setImage:[NSImage imageNamed:@"NoIcon"]];
            [uploadButton setEnabled:YES];
            [progressBar stopAnimation:progressBar];
            return;
        } else {
            [flattenPackagesImage setImage:[NSImage imageNamed:@"YesIcon"]];
        }
        
        NSArray *pkgs3;
        bErr = nil;
        [compressPackgesImage setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
        [compressPackgesImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
        pkgs3 = [self compressPackages:pkgs2 error:&bErr];
        if (bErr) {
            [compressPackgesImage setImage:[NSImage imageNamed:@"NoIcon"]];
            [uploadButton setEnabled:YES];
            [progressBar stopAnimation:progressBar];
            return;
        } else {
            [compressPackgesImage setImage:[NSImage imageNamed:@"YesIcon"]];
        }
        
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        if ([d objectForKey:@"dDoNotUpload"]) {
            if ([[d objectForKey:@"dDoNotUpload"] integerValue] == 1)
            {
                NSString *p = [[pkgs3 objectAtIndex:0] stringByDeletingLastPathComponent];
                [[NSWorkspace sharedWorkspace] openFile:p];
                [progressBar stopAnimation:progressBar];
                [uploadButton setEnabled:YES];
                return;
            }
        }
        
        [postPackagesImage setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
        [postPackagesImage performSelectorOnMainThread:@selector(needsDisplay) withObject:nil waitUntilDone:YES];
        [self postFiles:(NSArray *)pkgs3 requestID:_reqID userID:authUserName.stringValue];
        [self postAgentPKGData:pkgs3];
        
        [progressBar stopAnimation:progressBar];
        [uploadButton setEnabled:YES];
    }
}

- (void)extractPKG:(NSString *)aPath
{
    _tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mpPkg"];
    if ([fm fileExistsAtPath:_tmpDir]) {
        [fm removeItemAtPath:_tmpDir error:NULL];
    }
    [fm createDirectoryAtPath:_tmpDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Unzip it
    NSArray *tArgs = [NSArray arrayWithObjects:@"-x",@"-k",aPath,_tmpDir, nil];
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/ditto" arguments:tArgs];
    
    [NSThread sleepForTimeInterval:2.0];
    
    NSString *pkgName = [[_tmpDir stringByAppendingPathComponent:[aPath lastPathComponent]] stringByDeletingPathExtension];
    NSString *pkgExName = [_tmpDir stringByAppendingPathComponent:@"MPClientInstall"];
    NSArray *tArgs2 = [NSArray arrayWithObjects:@"--expand", pkgName, pkgExName, nil];
    [NSTask launchedTaskWithLaunchPath:@"/usr/sbin/pkgutil" arguments:tArgs2];
    [NSThread sleepForTimeInterval:2.0];
    
    [extractImage setImage:[NSImage imageNamed:@"YesIcon"]];
}

- (void)flattenPKG:(NSString *)aPKG
{
    BOOL signIt = NO;
    if (signPKG.state == NSOnState) {
        signIt = YES;
    }
    
    NSString *pkgName;
    if (signIt == YES) {
        pkgName = [NSString stringWithFormat:@"toSign_%@",[aPKG lastPathComponent]];
    } else {
        pkgName = [aPKG lastPathComponent];
    }
    
    NSString *pkgExName;
    if ([[pkgName pathExtension] isEqualToString:@"pkg"]) {
        pkgExName = [_tmpDir stringByAppendingPathComponent:pkgName];
    } else {
        pkgExName = [_tmpDir stringByAppendingPathComponent:[pkgName stringByAppendingPathExtension:@"pkg"]];
    }
    
    // Flatten the PKG
    NSArray *tArgs2 = [NSArray arrayWithObjects:@"--flatten", aPKG, pkgExName, nil];
    [NSTask launchedTaskWithLaunchPath:@"/usr/sbin/pkgutil" arguments:tArgs2];
    [NSThread sleepForTimeInterval:1.0];
    
    // If Sign, then sign each pkg
    if (signIt == YES) {
        NSString *signedPkgName = [pkgExName stringByReplacingOccurrencesOfString:@"toSign_" withString:@""];
        NSArray *sArgs = [NSArray arrayWithObjects:@"--sign", identityName.stringValue, pkgExName, signedPkgName, nil];
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/productsign" arguments:sArgs];
        [NSThread sleepForTimeInterval:1.0];
    }
}

- (void)compressPKG:(NSString *)aPKG
{
    NSArray *tArgs = [NSArray arrayWithObjects:@"-c",@"-k",aPKG,[aPKG stringByAppendingPathExtension:@"zip"], nil];
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/ditto" arguments:tArgs];
    [NSThread sleepForTimeInterval:2.0];
}

- (NSArray *)writePlistForPackage:(NSString *)aPlist error:(NSError **)err
{
    NSMutableArray *pkgs = [[NSMutableArray alloc] init];
    
    NSArray *dirFiles = [fm contentsOfDirectoryAtPath:[_tmpDir stringByAppendingPathComponent:@"MPClientInstall"] error:nil];
    NSArray *pkgFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.pkg'"]];
    NSString *fullPathScripts;
    NSString *fullPathPKG;
    for (NSString *pkg in pkgFiles)
    {
        fullPathPKG = [[_tmpDir stringByAppendingPathComponent:@"MPClientInstall"] stringByAppendingPathComponent:pkg];
        fullPathScripts = [fullPathPKG stringByAppendingPathComponent:@"Scripts/gov.llnl.mpagent.plist"];
        [aPlist writeToFile:fullPathScripts atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        NSLog(@"Write plist to %@",fullPathScripts);
        
        if ([fm fileExistsAtPath:[fullPathPKG stringByAppendingPathComponent:@"Scripts"]])
        {
            NSString *t;
            if ([[pkg lastPathComponent] isEqualToString:@"Base.pkg"]) {
                t = @"Agent";
            } else {
                t = @"Updater";
            }
            [self readAndWriteVersionPlistToPath:[[_tmpDir stringByAppendingPathComponent:@"MPClientInstall"] stringByAppendingPathComponent:@"Resources/mpInfo.plist"] writeTo:[fullPathPKG stringByAppendingPathComponent:@"Scripts"] pkgType:t];
        }
        
        [pkgs addObject:fullPathPKG];
    }
    
    [pkgs addObject:[_tmpDir stringByAppendingPathComponent:@"MPClientInstall"]];
    
    return (NSArray *)pkgs;
}

- (void)readAndWriteVersionPlistToPath:(NSString *)aInfoPath writeTo:(NSString *)aVerPath pkgType:(NSString *)aType
{
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:aInfoPath];
    NSDictionary *a = [NSDictionary dictionaryWithDictionary:[d objectForKey:aType]];
    NSMutableDictionary *da = [[NSMutableDictionary alloc] init];
    
    [da setObject:[a objectForKey:@"build"] forKey:@"build"];
    [da setObject:@"0" forKey:@"framework"];
    [da setObject:[[[a objectForKey:@"agent_version"] componentsSeparatedByString:@"."] objectAtIndex:0] forKey:@"major"];
    [da setObject:[[[a objectForKey:@"agent_version"] componentsSeparatedByString:@"."] objectAtIndex:1] forKey:@"minor"];
    [da setObject:[[[a objectForKey:@"agent_version"] componentsSeparatedByString:@"."] objectAtIndex:2] forKey:@"bug"];
    [da setObject:[a objectForKey:@"agent_version"] forKey:@"version"];
    
    [da writeToFile:[aVerPath stringByAppendingPathComponent:@".mpVersion.plist"] atomically:NO];
    
    if ([aType isEqualToString:@"Agent"]) {
        [da setObject:@"Base.pkg" forKey:@"pkg_name"];
        [da setObject:@"app" forKey:@"type"];
        [da setObject:[a objectForKey:@"osver"] forKey:@"osver"];
        [da setObject:[a objectForKey:@"agent_version"] forKey:@"agent_ver"];
        [da setObject:[a objectForKey:@"version"] forKey:@"ver"];
        [self setAgentDict:da];
    } else {
        [da setObject:@"Updater.pkg" forKey:@"pkg_name"];
        [da setObject:@"update" forKey:@"type"];
        [da setObject:[a objectForKey:@"osver"] forKey:@"osver"];
        [da setObject:[a objectForKey:@"agent_version"] forKey:@"agent_ver"];
        [da setObject:[a objectForKey:@"version"] forKey:@"ver"];
        [self setUpdaterDict:da];
    }
    
}

- (NSArray *)flattenPackages:(NSArray *)aPKGs error:(NSError **)err
{
    NSMutableArray *_pkgs = [[NSMutableArray alloc] init];
    
    for (NSString *pkg in aPKGs)
    {
        [self flattenPKG:pkg];
        if ([[[pkg lastPathComponent] pathExtension] isEqualToString:@"pkg"]) {
            [_pkgs addObject:[_tmpDir stringByAppendingPathComponent:[pkg lastPathComponent]]];
        } else {
            [_pkgs addObject:[_tmpDir stringByAppendingPathComponent:[[pkg lastPathComponent] stringByAppendingPathExtension:@"pkg"]]];
        }
    }
    
    return (NSArray *)_pkgs;
}

- (NSArray *)compressPackages:(NSArray *)aPKGs error:(NSError **)err
{
    NSMutableArray *_pkgs = [[NSMutableArray alloc] init];
    
    for (NSString *pkg in aPKGs)
    {
        [self compressPKG:pkg];
        [_pkgs addObject:[pkg stringByAppendingPathExtension:@"zip"]];
    }
    
    return (NSArray *)_pkgs;
}

- (void)postFiles:(NSArray *)aFiles requestID:(NSString *)aReqID userID:(NSString *)aUserID
{
    if (!aReqID) {
        NSLog(@"Error: request id was nil.");
        [postPackagesImage setImage:[NSImage imageNamed:@"NoIcon"]];
        return;
    }
    
    NSString *_host = serverAddress.stringValue;
    NSString *_port = serverPort.stringValue;
    NSString *_ssl = @"https";
    if (useSSL.state == NSOffState) {
        _ssl = @"http";
    } else {
        _ssl = @"https";
    }
    
    //-- Convert string into URL
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@/Service/MPAgentFilePost.cfm",_ssl,_host,_port];
    //NSString *urlString = [NSString stringWithFormat:@"http://mplnx.llnl.gov:3601/Service/MPAgentFilePost.cfm"];
    NSMutableURLRequest *request =[[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    //-- Append data into posr url using following method
    NSMutableData *body = [NSMutableData data];
    
    //-- For Sending text
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",@"requestID"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@",aReqID] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",@"userID"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@",aUserID] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",@"token"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@",_authToken] dataUsingEncoding:NSUTF8StringEncoding]];
    
    for (NSString *_pkg in aFiles)
    {
        NSString *frmName;
        if ([[_pkg lastPathComponent] isEqualToString:@"Base.pkg.zip"]) {
            frmName = @"fBase";
        } else if ([[_pkg lastPathComponent] isEqualToString:@"Updater.pkg.zip"])
        {
            frmName = @"fUpdate";
        } else if ([[_pkg lastPathComponent] isEqualToString:@"MPClientInstall.pkg.zip"])
        {
            frmName = @"fComplete";
        }
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition:form-data; name=\"%@\"; filename=\"%@\"\r\n",frmName,[_pkg lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithContentsOfFile:_pkg]];
    }
    
    //-- Sending data into server through URL
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
    
    //-- Getting response form server
    //NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    NSError *error = nil;
    NSURLResponse *response;
    WebRequest *req = [[WebRequest alloc] init];
    NSData *responseData = [req sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error)
    {
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }
        
        [postPackagesImage setImage:[NSImage imageNamed:@"NoIcon"]];
        return;
    }
    
    //-- JSON Parsing with response data
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"[postFiles]: %@",result);
    if ([result objectForKey:@"errorno"]) {
        if ([[result objectForKey:@"errorno"] intValue] != 0) {
            [postPkgStatus setStringValue:[result objectForKey:@"errormsg"]];
            [postPackagesImage setImage:[NSImage imageNamed:@"NoIcon"]];
            return;
        } else {
            [postPackagesImage setImage:[NSImage imageNamed:@"YesIcon"]];
            return;
        }
    }
    
    [postPackagesImage setImage:[NSImage imageNamed:@"NoIcon"]];
}

- (void)postAgentPKGData:(NSArray *)aPKGs
{
    
    MPCrypto *mpc = [[MPCrypto alloc] init];
    NSMutableDictionary *d;
    NSString *pkgName;
    for (NSString *p in aPKGs)
    {
        pkgName = [[p lastPathComponent] stringByDeletingPathExtension];
        d = [[NSMutableDictionary alloc] init];
        [d setObject:self.agentID forKey:@"puuid"];
        [d setObject:pkgName forKey:@"pkg_name"];
        if ([pkgName isEqualToString:@"Base.pkg"]) {
            [d setObject:@"app" forKey:@"type"];
            [d setObject:[_agentDict objectForKey:@"agent_ver"] forKey:@"agent_ver"];
            [d setObject:[_agentDict objectForKey:@"ver"] forKey:@"version"];
            [d setObject:[_agentDict objectForKey:@"build"] forKey:@"build"];
            [d setObject:[mpc sha1HashForFile:p] forKey:@"pkg_hash"];
            [d setObject:[_agentDict objectForKey:@"osver"] forKey:@"osver"];
        } else if ([pkgName isEqualToString:@"Updater.pkg"]) {
            [d setObject:@"update" forKey:@"type"];
            [d setObject:[_agentDict objectForKey:@"agent_ver"] forKey:@"agent_ver"];
            [d setObject:[_agentDict objectForKey:@"ver"] forKey:@"version"];
            [d setObject:[_agentDict objectForKey:@"build"] forKey:@"build"];
            [d setObject:[mpc sha1HashForFile:p] forKey:@"pkg_hash"];
            [d setObject:[_agentDict objectForKey:@"osver"] forKey:@"osver"];
        } else {
            continue;
        }
        if (![self postAgentData:(NSDictionary *)d]) {
            break;
        }
    }
}

- (BOOL)postAgentData:(NSDictionary *)aConfig
{
    NSString *_host = serverAddress.stringValue;
    NSString *_port = serverPort.stringValue;
    NSString *_ssl = @"https";
    if (useSSL.state == NSOffState) {
        _ssl = @"http";
    } else {
        _ssl = @"https";
    }
    
    NSDictionary *d = [NSDictionary dictionaryWithDictionary:aConfig];
    
    //-- Convert string into URL
    NSString *dURL = [NSString stringWithFormat:@"&puuid=%@&type=%@&agent_ver=%@&version=%@&build=%@&pkg_name=%@&pkg_hash=%@&osver=%@",[d objectForKey:@"puuid"],[d objectForKey:@"type"],[d objectForKey:@"agent_ver"],[d objectForKey:@"version"],[d objectForKey:@"build"],[d objectForKey:@"pkg_name"],[d objectForKey:@"pkg_hash"],[d objectForKey:@"osver"]];
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@/%@?method=postAgentData&%@&user=%@&token=%@",_ssl,_host,_port,MPADM_URI,dURL,authUserName.stringValue,[self encodeURLString:_authToken]];
    NSMutableURLRequest *request =[[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    
    //-- Getting response form server
    NSError *error = nil;
    NSURLResponse *response;
    WebRequest *req = [[WebRequest alloc] init];
    NSData *responseData = [req sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error)
    {
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }
        return NO;
    }
    
    //-- JSON Parsing with response data
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"[postAgentData]: %@",result);
    if ([result objectForKey:@"errorno"]) {
        if ([[result objectForKey:@"errorno"] intValue] != 0) {
            [postPkgStatus setStringValue:[result objectForKey:@"errormsg"]];
            [postPackagesImage setImage:[NSImage imageNamed:@"NoIcon"]];
            return NO;
        } else {
            [postPackagesImage setImage:[NSImage imageNamed:@"YesIcon"]];
            return YES;
        }
    }
    
    [postPackagesImage setImage:[NSImage imageNamed:@"NoIcon"]];
    return NO;
}

- (NSString *)getRequestID:(NSString *)aUserID error:(NSError **)err
{
    NSString *_host = serverAddress.stringValue;
    NSString *_port = serverPort.stringValue;
    NSString *_ssl = @"https";
    if (useSSL.state == NSOffState) {
        _ssl = @"http";
    } else {
        _ssl = @"https";
    }
    
    //-- Convert string into URL
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@/%@?method=postAgentFiles&user=%@&token=%@",_ssl,_host,_port,MPADM_URI,authUserName.stringValue,[self encodeURLString:_authToken]];
    NSMutableURLRequest *request =[[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    
    //-- Getting response form server
    NSError *error = nil;
    NSURLResponse *response;
    WebRequest *req = [[WebRequest alloc] init];
    NSData *responseData = [req sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error)
    {
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }
        return nil;
    }
    
    //-- JSON Parsing with response data
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"[getRequestID]: %@",result);
    if ([result objectForKey:@"errorno"]) {
        if ([[result objectForKey:@"errorno"] intValue] != 0) {
            NSMutableDictionary *errDetails = [NSMutableDictionary dictionary];
            [errDetails setValue:[result objectForKey:@"errormsg"] forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            *err = [NSError errorWithDomain:@"world" code:[[result objectForKey:@"errorno"] intValue] userInfo:errDetails];
            return nil;
        }
    }
    
    if ([result objectForKey:@"result"]) {
        return [result objectForKey:@"result"];
    } else {
        return nil;
    }
}

- (NSString *)encodeURLString:(NSString *)aString
{
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                    NULL,
                                                                                                    (CFStringRef)aString,
                                                                                                    NULL,
                                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                    kCFStringEncodingUTF8 ));
    return encodedString;
}

@end
