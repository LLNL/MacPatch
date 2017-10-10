//
//  MPSettingsSchema.m
//  MPLibrary
//
//  Created by Charles Heizer on 6/14/17.
//
//

#import "MPSettingsSchema.h"

@implementation MPSettingsSchema

- (void)migrate
{
    [self upToVersion:1 action:^(FMDatabase *db)
    {
        [db executeUpdate:@""
         "create table agent_config ("
         "id integer primary key autoincrement,"
         "group_id text not null,"
         "Description text,"
         "clientGroup text,"
         "patchGroup text,"
         "patchState integer(1,0) DEFAULT 0,"
         "patchClient integer(1,0) DEFAULT 1,"
         "patchServer integer(1,0) DEFAULT 0,"
         "reboot integer(1,0) DEFAULT 1,"
         "swDistGroup text,"
         "swDistGroupID text,"
         "swDistGroupAdd text,"
         "swDistGroupAddID text"
         ")"];
        
        [db executeUpdate:@""
         "create table agent_config_info ("
         "id integer primary key autoincrement,"
         "rev integer,"
         "group_id text,"
         "mdate text not null"
         ")"];
        
        [db executeUpdate:@""
         "create table tasks ("
         "id integer primary key autoincrement,"
         "tid integer not null," // task id
         "tidrev integer not null," // task id rev
         "name text not null,"
         "Description text,"
         "cmd text not null," // task command name
         "data text," // data for query based on type
         "active integer not null,"
         "interval text not null,"
         "startdate text,"
         "enddate text,"
         "type integer," // type 0 is default task, 1 is group task used data for id to query for action
         "lastrun text,"
         "lastreturncode text,"
         "lasterror text,"
         "group_id text not null"
         ")"];
        
        [db executeUpdate:@""
         "create table tasks_info ("
         "id integer primary key autoincrement,"
         "group_id text not null,"
         "rev integer not null,"
         "mdate text not null"
         ")"];
        
        
        [db executeUpdate:@""
         "create table mp_servers ("
         "id integer primary key autoincrement,"
         "hostname text not null,"
         "port integer not null,"
         "usessl integer(1,0) DEFAULT 1,"
         "useclientcert integer(1,0) DEFAULT 1,"
         "isproxy integer(1,0) DEFAULT 0"
         ")"];
        
        [db executeUpdate:@""
         "create table mp_servers_info ("
         "id integer primary key autoincrement,"
         "version integer not null,"
         "mdate text not null"
         ")"];
        
        [db executeUpdate:@""
         "create table su_servers ("
         "id integer primary key autoincrement,"
         "CatalogURL text not null,"
         "serverType integer(1,0) DEFAULT 0," // 0 normal, 1 proxy
         "osmajor integer,"
         "osminor integer"
         ")"];
        
        [db executeUpdate:@""
         "create table su_servers_info ("
         "id integer primary key autoincrement,"
         "version text not null,"
         "mdate text not null"
         ")"];
    }];
    
    /* Example Alter
    [self upToVersion:2 action:^(FMDatabase *db){
        // ... schema changes for version 2
        [db executeUpdate:@""
         "ALTER TABLE users ADD COLUMN description text;"
         ];
    }];
     */
}

@end
