//
//  MPServer.h
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "FMXModel.h"

@interface Server : FMXModel

@property (strong, nonatomic) NSNumber *id;
@property (strong, nonatomic) NSString *hostname;
@property (strong, nonatomic) NSNumber *port;
@property (strong, nonatomic) NSNumber *usessl;
@property (strong, nonatomic) NSNumber *useclientcert;
@property (strong, nonatomic) NSNumber *isproxy;

@end
