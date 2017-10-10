//
//  SUServer.h
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "FMXModel.h"

@interface SUServer : FMXModel

@property (strong, nonatomic) NSNumber *id;
@property (strong, nonatomic) NSString *CatalogURL;
@property (strong, nonatomic) NSNumber *serverType;
@property (strong, nonatomic) NSNumber *osmajor;
@property (strong, nonatomic) NSNumber *osminor;

@end
