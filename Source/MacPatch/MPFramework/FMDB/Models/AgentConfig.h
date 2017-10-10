//
//  AgentConfig.h
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "FMXModel.h"

@interface AgentConfig : FMXModel

@property (strong, nonatomic) NSNumber *id;
@property (strong, nonatomic) NSString *group_id;
@property (strong, nonatomic) NSString *Description;
@property (strong, nonatomic) NSString *clientGroup;
@property (strong, nonatomic) NSString *patchGroup;
@property (strong, nonatomic) NSString *patchGroupID;
@property (strong, nonatomic) NSString *patchState;
@property (strong, nonatomic) NSNumber *patchClient;
@property (strong, nonatomic) NSNumber *patchServer;
@property (strong, nonatomic) NSNumber *reboot;
@property (strong, nonatomic) NSString *swDistGroup;
@property (strong, nonatomic) NSString *swDistGroupID;
@property (strong, nonatomic) NSString *swDistGroupAdd;
@property (strong, nonatomic) NSString *swDistGroupAddID;
@property (strong, nonatomic) NSNumber *verifySignatures;

@end
