//
//  MPNetRequest.h
//  MPAgentNewWin
//
//  Created by Heizer, Charles on 3/18/14.
//  Copyright (c) 2014 Lawrence Livermore National Laboratory. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MPNetServer;


@protocol MPNetRequestController

- (void)appendDownloadProgress:(double)aNumber;
- (void)appendDownloadProgressPercent:(NSString *)aPercent;
- (void)downloadStarted;
- (void)downloadFinished;
- (void)downloadError;

@end

@interface MPNetRequest : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    id				<MPNetRequestController>controller;
    BOOL            useController;

    MPNetServer     *mpServer;
    NSArray         *mpServerArray;
    NSString        *httpMethod;
    NSString        *method;
    NSString        *apiURI;
    NSDictionary    *apiArgs;


    // User Auth 
    NSString        *userName;
    NSString        *userPass;

    // TLS Auth
    NSString        *tlsCert;
    NSString        *tlsCertPass;

    // Misc
    NSNumber        *dlSize;
    NSNumber        *dlRecievedData;
    NSMutableData   *receivedData;
	BOOL			isRunning;
    int             errorCode;
}

@property (nonatomic, assign, readonly) BOOL useController;
@property (nonatomic, assign, readonly) int errorCode;

@property (nonatomic, strong) MPNetServer *mpServer;
@property (nonatomic, strong) NSArray *mpServerArray;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *apiURI;
@property (nonatomic, strong) NSDictionary *apiArgs;
@property (nonatomic, strong) NSMutableData *receiveData;
@property (nonatomic, assign) BOOL internetActive;
@property (nonatomic, assign, readonly) BOOL isFileDownload;
@property (nonatomic, strong, readonly) NSString *dlFilePath;

// User Auth
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userPass;
// TLS Auth
@property (nonatomic, strong) NSString *tlsCert;
@property (nonatomic, strong) NSString *tlsCertPass;

- (id)initWithMPServer:(MPNetServer *)aServer;
- (id)initWithMPServerArray:(NSArray *)aServerArray;
- (id)initWithMPServerAndController:(id <MPNetRequestController>)cont server:(MPNetServer *)aServer;
- (id)initWithMPServerArrayAndController:(id <MPNetRequestController>)controller servers:(NSArray *)aServerArray;

- (NSURLRequest *)buildRequestForWebServiceMethod:(NSString *)wsMethodName formData:(NSDictionary *)paramDict error:(NSError **)error;
- (NSURLRequest *)buildGetRequestForWebServiceMethod:(NSString *)wsMethodName formData:(NSDictionary *)paramDict error:(NSError **)error;
- (NSURLRequest *)buildDownloadRequest:(NSString *)url;
- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;
- (NSString *)downloadFileRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;
@end
