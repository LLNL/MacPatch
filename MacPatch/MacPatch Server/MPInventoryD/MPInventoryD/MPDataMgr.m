//
//  MPDataMgr.m
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

#import "MPDataMgr.h"
#import "MysqlConnection.h"
#import "MysqlServer.h"
#import "MysqlFetch.h"
#import "MysqlExecute.h"
#import "MysqlDelete.h"
#import "MysqlInsert.h"
#import "MysqlUpdate.h"
#import "MySQLTableColumn.h"
#import "DBField.h"

#undef  ql_component
#define ql_component lcl_cMPDataMgr

@interface MPDataMgr ()

@property(retain) MysqlConnection *dbConnection;

@property(retain, readwrite) NSString *tableName;
@property(retain, readwrite) NSDictionary *removeData;
@property(retain, readwrite) NSArray *tableFields;
@property(retain, readwrite) NSArray *tableFieldNames;
@property(retain, readwrite) NSArray *tableRows;
@property(retain, readwrite) NSArray *checkFields;
@property(retain, readwrite) NSString *onExists;
@property(nonatomic, assign) int didDeleteAll;
// DataBase
@property(retain) MysqlServer *dbServer;
@property(retain) NSArray *dbTables;

// DataBase Methods
- (MysqlServer *)setUpMySQLServer;
- (BOOL)setUpMySQLConnection:(MysqlServer *)server error:(NSError **)err;
- (BOOL)getDBTables;
- (NSArray *)getDBTableStructure:(NSString *)aTableName;
- (BOOL)tableExists:(NSString *)aTableName;
- (BOOL)recordExistsInTable:(NSString *)aTableName checkFields:(NSArray *)checkFields row:(NSDictionary *)aRow;
- (BOOL)createTable:(NSString *)aTable fields:(NSArray *)aFields error:(NSError **)err;
- (BOOL)alterSQLAddFieldToTable:(NSString *)aTable field:(DBField *)aField error:(NSError **)err;
- (BOOL)alterSQLChangeFieldInTable:(NSString *)aTable field:(DBField *)aField error:(NSError **)err;
- (NSString *)getDataType:(NSString *)aType;

- (BOOL)compareAndFixTableStructure:(NSArray *)xmlTableFields;
- (NSArray *)findColumnsToAddToTable:(NSArray *)xmlTableCols dbTable:(NSArray *)dbTableCols;
- (NSArray *)findColumnsToUpdateInTable:(NSArray *)xmlTableCols dbTable:(NSArray *)dbTableCols;

// Misc
- (BOOL)stringContains:(NSString *)aString search:(NSString *)aSearchString;
- (NSString *)cleanColumnName:(NSString *)aString;
- (NSDictionary *)cleanRowOfDuplicates:(NSDictionary *)aDict;
@end

@implementation MPDataMgr

- (id)initWithMySQLServer:(MysqlServer *)aServer error:(NSError *__autoreleasing *)error
{
    self = [super init];
    NSError *err = nil;
    [self setUpMySQLConnection:aServer error:&err];
    if (err) {
        if (error != NULL) {
            *error = err;
        }
        qlerror(@"%@",[err description]);
    }
    [self getDBTables];
    return self;
}

- (id)initWithXMLStringAndDB:(NSString *)XMLString server:(MysqlServer *)aServer error:(NSError *__autoreleasing *)error
{
    self = [super init];
    NSError *err = nil;
    _xmlDoc = [[NSXMLDocument alloc] initWithXMLString:XMLString options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA) error:&err];
    if (err) {
        if (error != NULL) {
            *error = err;
        }
        qlerror(@"%@",[err description]);
    }
    err = nil;
    [self setUpMySQLConnection:aServer error:&err];
    if (err) {
        if (error != NULL) {
            *error = err;
        }
        qlerror(@"%@",[err description]);
    }
    [self getDBTables];
    return self;
}

- (id)initWithXMLString:(NSString *)XMLString error:(NSError *__autoreleasing *)error
{
    self = [super init];
    NSError *err = nil;
    _xmlDoc = [[NSXMLDocument alloc] initWithXMLString:XMLString options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA) error:&err];
    if (err) {
        if (error != NULL) {
            *error = err;
        }
        qlerror(@"%@",[err description]);
    }
    err = nil;
    [self setUpMySQLConnection:[self setUpMySQLServer] error:&err];
    if (err) {
        if (error != NULL) {
            *error = err;
        }
        qlerror(@"%@",[err description]);
    }
    [self getDBTables];
    return self;
}

- (id)initWithXMLDoc:(NSString *)XMLFilePath error:(NSError *__autoreleasing *)error
{
    self = [super init];
    NSError *err = nil;
    _xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:XMLFilePath] options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA) error:&err];
    if (err) {
        if (error != NULL) {
            *error = err;
        }
        qlerror(@"%@",[err description]);
    }
    return self;
}

#pragma mark - DataBase 

- (MysqlServer *)setUpMySQLServer
{
    MysqlServer *server = [[MysqlServer alloc] init];
    [server setHost:@"127.0.0.1"];
    [server setUser:@"mpdbadm"];
    [server setPassword:@""];
    [server setSchema:@"MacPatchDB"];
    [self setDbServer:server];
    return server;
}

- (BOOL)setUpMySQLConnection:(MysqlServer *)server error:(NSError **)err
{
    @try {
        _dbConnection = [MysqlConnection connectToServer:server];
        [_dbConnection disableTransactions];
        [self setDbServer:server];
    }
    @catch (NSException *exception) {
        qlerror(@"%@",exception);
        NSError *iError = [NSError errorWithDomain:@"setUpMySQLConnection"
                                              code:1
                                          userInfo:[NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey]];
        if (err != NULL) {
            *err = iError;
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)getDBTables
{
    /*
     Used to get all of the table names in the database
     */
    BOOL result = YES;
    NSMutableArray *tables;
    NSString *sqlText = [NSString stringWithFormat:@"SELECT table_name " \
                         "FROM information_schema.tables " \
                         "WHERE table_schema = '%@' AND " \
                         "table_type = 'BASE TABLE'",self.dbServer.schema];
    @try {
        MysqlFetch *fetch = [MysqlFetch fetchWithCommand:sqlText onConnection:self.dbConnection];
        tables = [[NSMutableArray alloc] init];
        for (NSDictionary *userRow in fetch.results)
        {
            [tables addObject:[userRow objectForKey:@"table_name"]];
        }
    }
    @catch (NSException *exception) {
        qlerror(@"%@",exception);
        result = NO;
    }
    [self setDbTables:[NSArray arrayWithArray:tables]];
    return result;
}

- (NSArray *)getDBTableStructure:(NSString *)aTableName
{
    NSArray *result = nil;
    NSMutableArray *cols = [[NSMutableArray alloc] init];
    MySQLTableColumn *col;
    
    NSString *sqlText = [NSString stringWithFormat:@"DESCRIBE %@;",aTableName];
    MysqlFetch *fetch = [MysqlFetch fetchWithCommand:sqlText onConnection:self.dbConnection];
    for (NSDictionary *row in fetch.results)
    {
        col = [[MySQLTableColumn alloc] initWithFetchResults:row];
        [cols addObject:col];
    }
    
    result = [NSArray arrayWithArray:cols];
    return result;
}

- (BOOL)tableExists:(NSString *)aTableName
{
    BOOL result = NO;
    for (NSString *table in self.dbTables)
    {
        if ([[table lowercaseString] isEqualToString:[aTableName lowercaseString]])
        {
            result = YES;
            break;
        }
    }
    return result;
}

- (BOOL)recordExistsInTable:(NSString *)aTableName checkFields:(NSArray *)checkFields row:(NSDictionary *)aRow
{
    BOOL result = NO;
    @autoreleasepool
    {
        NSMutableString *sql = [[NSMutableString alloc] init];
        [sql appendFormat:@"SELECT %@ FROM %@ WHERE 0 = 0 ",[checkFields componentsJoinedByString:@","],aTableName];
        for (NSString *ckey in checkFields) {
            if ([[aRow allKeys] containsObject:ckey]) {
                [sql appendFormat:@"AND %@ = '%@' ",ckey,[aRow objectForKey:ckey]];
            } else {
                if ([ckey isEqualToString:@"rid"]) {
                    [sql appendFormat:@"AND %@ = 0 ",ckey];
                }
            }
        }
        MysqlFetch *fetch;
        @try {
             fetch = [MysqlFetch fetchWithCommand:sql onConnection:self.dbConnection];
        }
        @catch (NSException *exception) {
            qlerror(@"%@",exception);
            return result;
        }

        if (fetch.results.count != 0) {
            result = YES;
        }
    }
    return result;
}

- (BOOL)createTable:(NSString *)aTable fields:(NSArray *)aFields error:(NSError **)err
{
    NSMutableArray *pKey = [[NSMutableArray alloc] init];
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendFormat:@"CREATE TABLE %@ (",aTable];
    for (DBField *field in aFields) {
        if ([[field.name uppercaseString] isEqualToString:[@"rid" uppercaseString]]) {
            [sql appendFormat:@"%@ bigint ",field.name];
        } else {
            [sql appendFormat:@"%@ %@ ",field.name, field.dataType];
        }
        if ([self stringContains:field.dataType search:@"date"] == NO && [self stringContains:field.dataType search:@"time"] == NO) {
            if ([[field.name uppercaseString] isEqualToString:[@"rid" uppercaseString]]) {
                [sql appendFormat:@"(20) %@ ", field.dataTypeExt];
            } else {
                [sql appendFormat:@"(%@) %@ ",field.length, field.dataTypeExt];
            }   
        }
        if ([field.allowNull isEqualToString:@"NOT NULL"]) {
            [sql appendFormat:@"%@ ",field.allowNull];
        }
        if ([field.autoIncrement isEqualToString:@""] == NO) {
            [sql appendFormat:@"%@ ",field.autoIncrement];
        }
        if ([field.defaultValue isEqualToString:@""] == NO) {
            [sql appendFormat:@"DEFAULT '%@' ",field.defaultValue];
        }
        if ([field.primaryKey isEqualToString:@""] == NO) {
            [pKey addObject:field.name];
        }
        [sql appendString:@","];
    }
    [sql appendFormat:@"PRIMARY KEY (%@),",[pKey componentsJoinedByString:@","]];
    [sql appendString:@"INDEX pri_idx (cuuid, date))"];
    
    @try {
        MysqlExecute *exe = [MysqlExecute sqlExecuteWithConnection:self.dbConnection];
        [exe executeSQL:sql];
    }
    @catch (NSException *exception)
    {
        if (err != NULL)
        {
            NSError *iError = [NSError errorWithDomain:@"sqlExecuteWithConnection" code:1
                                              userInfo:[NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey]];
            *err = iError;
        }
        
        qlerror(@"%@",exception);
        return NO;
    }
    
    return YES;
}

- (BOOL)alterSQLAddFieldToTable:(NSString *)aTable field:(DBField *)aField error:(NSError **)err
{
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendFormat:@"ALTER TABLE `%@` ",aTable];
    [sql appendFormat:@"ADD COLUMN `%@` %@ ",aField.name, aField.dataType];
    if ([self stringContains:aField.dataType search:@"date"] == NO && [self stringContains:aField.dataType search:@"time"] == NO) {
        [sql appendFormat:@"(%@) %@ ",aField.length, aField.dataTypeExt];
    }
    if ([aField.allowNull isEqualToString:@"NOT NULL"]) {
        [sql appendFormat:@"%@ ",aField.allowNull];
    }
    if ([aField.defaultValue isEqualToString:@""] == NO) {
        [sql appendFormat:@"DEFAULT '%@' ",aField.defaultValue];
    }
    
    @try {
        MysqlExecute *exe = [MysqlExecute sqlExecuteWithConnection:self.dbConnection];
        [exe executeSQL:sql];
        qltrace(@"%@",sql);
    }
    @catch (NSException *exception)
    {
        if (err != NULL)
        {
            NSError *iError = [NSError errorWithDomain:@"sqlExecuteWithConnection" code:1
                                              userInfo:[NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey]];
            *err = iError;
        }
        
        qlerror(@"%@",exception);
        return NO;
    }
    
    return YES;
}

- (BOOL)alterSQLChangeFieldInTable:(NSString *)aTable field:(DBField *)aField error:(NSError **)err
{
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendFormat:@"ALTER TABLE `%@` ",aTable];
    [sql appendFormat:@"CHANGE COLUMN `%@` `%@` %@ ", aField.name, aField.name, aField.dataType];
    if ([self stringContains:aField.dataType search:@"date"] == NO && [self stringContains:aField.dataType search:@"time"] == NO) {
        [sql appendFormat:@"(%@) %@ ",aField.length, aField.dataTypeExt];
    }
    if ([aField.allowNull isEqualToString:@"NOT NULL"]) {
        [sql appendFormat:@"%@ ",aField.allowNull];
    }
    if ([aField.defaultValue isEqualToString:@""] == NO) {
        [sql appendFormat:@"DEFAULT '%@' ",aField.defaultValue];
    }
    
    @try {
        MysqlExecute *exe = [MysqlExecute sqlExecuteWithConnection:self.dbConnection];
        [exe executeSQL:sql];
    }
    @catch (NSException *exception)
    {
        if (err != NULL)
        {
            NSError *iError = [NSError errorWithDomain:@"sqlExecuteWithConnection" code:1
                                              userInfo:[NSDictionary dictionaryWithObject:exception forKey:NSLocalizedDescriptionKey]];
            *err = iError;
        }
        
        qlerror(@"%@",exception);
        return NO;
    }
    
    qltrace(@"[alterSQLChangeFieldInTable][SQL]: %@",sql);
    return YES;
}

- (NSString *)getDataType:(NSString *)aType
{
    NSString *_dataType = nil;
    
    if ([aType isEqualToString:@"CF_SQL_BIGINT"]) {
        _dataType = @"bigint";
    } else if ([aType isEqualToString:@"CF_SQL_BIT"]) {
        _dataType = @"tinyint";
    } else if ([aType isEqualToString:@"CF_SQL_CHAR"]) {
        _dataType = @"char";
    } else if ([aType isEqualToString:@"CF_SQL_DATE"]) {
        _dataType = @"datetime";
    } else if ([aType isEqualToString:@"CF_SQL_DECIMAL"]) {
        _dataType = @"decimal";
    } else if ([aType isEqualToString:@"CF_SQL_DOUBLE"]) {
        _dataType = @"double";
    } else if ([aType isEqualToString:@"CF_SQL_FLOAT"]) {
        _dataType = @"float";
    } else if ([aType isEqualToString:@"CF_SQL_IDSTAMP"]) {
        _dataType = @"varchar";
    } else if ([aType isEqualToString:@"CF_SQL_INTEGER"]) {
        _dataType = @"int";
    } else if ([aType isEqualToString:@"CF_SQL_LONGVARCHAR"]) {
        _dataType = @"text";
    } else if ([aType isEqualToString:@"CF_SQL_MONEY"]) {
        _dataType = @"money";
    } else if ([aType isEqualToString:@"CF_SQL_MONEY4"]) {
        _dataType = @"smallmoney";
    } else if ([aType isEqualToString:@"CF_SQL_NUMERIC"]) {
        _dataType = @"numeric";
    } else if ([aType isEqualToString:@"CF_SQL_REAL"]) {
        _dataType = @"real";
    } else if ([aType isEqualToString:@"CF_SQL_SMALLINT"]) {
        _dataType = @"smallint";
    } else if ([aType isEqualToString:@"CF_SQL_TIMESTAMP"]) {
        _dataType = @"timestamp";
    } else if ([aType isEqualToString:@"CF_SQL_TINYINT"]) {
        _dataType = @"tinyint";
    } else if ([aType isEqualToString:@"CF_SQL_VARCHAR"]) {
        _dataType = @"varchar";
    } else {
        _dataType = @"varchar";
    }
    
    return _dataType;
}

#pragma mark - XML 

- (BOOL)pasreXMLDocFromPath:(NSString *)xmlDocPath
{
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlDocPath];
    NSString *xmlString = [[NSString alloc] initWithData:xmlData encoding:NSASCIIStringEncoding];
    return [self pasreXMLString:xmlString];
}

- (BOOL)pasreXMLString:(NSString *)XMLString
{
    NSError *err = nil;
    _xmlDoc = [[NSXMLDocument alloc] initWithXMLString:XMLString options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA) error:&err];
    if (err) {
        qlerror(@"%@",[err description]);
        return FALSE;
    }
    
    return [self pasreXMLDoc];
}

- (BOOL)pasreXMLDoc
{
    BOOL l_CreateTable = NO;
    
    if (!_xmlDoc) {
        return NO;
    }
    // **************************
    // Get Table Name
    NSError *err = nil;
    NSString *lTableName = @"ERROR";
    NSArray *tb_nodes = [_xmlDoc nodesForXPath:@"//table" error:&err];
    if (!err) {
        if ([tb_nodes count] >= 1) {
            lTableName = [[[tb_nodes objectAtIndex:0] attributeForName:@"name"] stringValue];
        } else {
            qlerror(@"Error table name was not found.");
            return NO;
        }
    } else {
        qlerror(@"%@",[err description]);
        return NO;
    }
    [self setTableName:lTableName];
    
    // **************************
    // Does Table Exist
    if (![self tableExists:lTableName])
    {
        qlerror(@"Table %@ Does Not Exist",lTableName);
        l_CreateTable = YES;
    }
    
    // **************************
    // Data to remove prior to insert
    err = nil;
    NSDictionary *removeDataKeyPair = nil;
    NSArray *rm_nodes = [_xmlDoc nodesForXPath:@"//remove" error:&err];
    if (!err) {
        if ([rm_nodes count] >= 1) {
            removeDataKeyPair = [NSDictionary dictionaryWithObject:[[[rm_nodes objectAtIndex:0] attributeForName:@"valueEQ"] stringValue]
                                                        forKey:[[[rm_nodes objectAtIndex:0] attributeForName:@"column"] stringValue]];
        }
    } else {
        qlerror(@"%@",[err description]);
    }
    [self setRemoveData:removeDataKeyPair];
    
    // **************************
    // Get Table Fields
    NSArray *fd_nodes = [_xmlDoc nodesForXPath:@"//table/field" error:&err];
    NSMutableArray *fieldNamesArray = [[NSMutableArray alloc] init];
    if (!err) {
        if ([rm_nodes count] >= 1) {
            NSMutableArray *a = [[NSMutableArray alloc] init];
            DBField *field;
            for (NSXMLElement *e in fd_nodes)
            {
                field = [[DBField alloc] init];
                if ([e attributeForName:@"ColumnName"])
                {    
                    [field setName:[self cleanColumnName:[[e attributeForName:@"ColumnName"] stringValue]]];
                    [fieldNamesArray addObject:[self cleanColumnName:[[e attributeForName:@"ColumnName"] stringValue]]];
                }
                if ([e attributeForName:@"CF_DATATYPE"]) {
                    [field setDataType:[self getDataType:[[e attributeForName:@"CF_DATATYPE"] stringValue]]];
                }
                if ([e attributeForName:@"Length"]) {
                    [field setLength:[[e attributeForName:@"Length"] stringValue]];
                }
                if ([e attributeForName:@"CF_DATATYPE_EXT"]) {
                    [field setDataTypeExt:[[e attributeForName:@"CF_DATATYPE_EXT"] stringValue]];
                }
                if ([e attributeForName:@"Increment"]) {
                    [field setAutoIncrement:([[[e attributeForName:@"Increment"] stringValue] isEqualToString:@"true"] ? @"AUTO_INCREMENT" : @" ")];
                }
                if ([e attributeForName:@"PrimaryKey"]) {
                    [field setPrimaryKey:([[[e attributeForName:@"PrimaryKey"] stringValue] isEqualToString:@"true"] ? @"PRI" : @" ")];
                }
                if ([e attributeForName:@"AllowNull"]) {
                    [field setPrimaryKey:([[[e attributeForName:@"AllowNull"] stringValue] isEqualToString:@"true"] ? @"NULL" : @"NOT NULL")];
                }
                // Quick Fix in Date/Time Fields
                if ([self stringContains:[field dataType] search:@"date"] || [self stringContains:[field dataType] search:@"time"]) {
                    // Empty the default value of 255
                    [field setLength:@""];
                }
                qltrace(@"fieldDescription: %@",[field fieldDescription]);
                [a addObject:field];
                field = nil;
            }
            if (a != nil) {
                if ([a count] >= 3) {
                    [self setTableFields:a];
                }
            }
        }
    }
    [self setTableFieldNames:(NSArray *)fieldNamesArray];
    
    // **************************
    // Row Data Action
    err = nil;
    NSArray *rwa_nodes = [_xmlDoc nodesForXPath:@"//data" error:&err];
    if (!err) {
        if ([rwa_nodes count] >= 1) {
            if ([[rwa_nodes objectAtIndex:0] attributeForName:@"checkFields"]) {
                [self setCheckFields:[[[[rwa_nodes objectAtIndex:0] attributeForName:@"checkFields"] stringValue] componentsSeparatedByString:@","]];
            }
            if ([[rwa_nodes objectAtIndex:0] attributeForName:@"onexists"]) {
                [self setOnExists:[[[rwa_nodes objectAtIndex:0] attributeForName:@"onexists"] stringValue]];
            }
        }
    } else {
        qlerror(@"%@",[err description]);
    }
    
    // **************************
    // Get Row Data
    NSArray *rw_nodes = [_xmlDoc nodesForXPath:@"//data/row" error:&err];
    NSMutableArray *rowsArray = [[NSMutableArray alloc] init];
    int hasObj = 0;
    for (NSXMLNode *n in rw_nodes)
    {
        NSMutableDictionary *r = [[NSMutableDictionary alloc] init];
        for (NSXMLElement *f in [n children]) {
            // Fields in a row
            NSArray *c = [f attributes];
            if ([c count] == 2) {
                // Verify that the table contains the field
                hasObj = 0;
                for (NSString *_tFieldName in _tableFieldNames) {
                    if ([_tFieldName isEqualToString:[[[c objectAtIndex:0] stringValue] lowercaseString]]) {
                        hasObj++;
                        break;
                    }
                }
                
                if (hasObj >= 1) {
                    [r setObject:[[c objectAtIndex:1] stringValue] forKey:[[c objectAtIndex:0] stringValue]];
                } else {
                    NSLog(@"Data contains extra column %@ (%@)",[[c objectAtIndex:0] stringValue],[[c objectAtIndex:1] stringValue]);
                }
            }
        }
        [rowsArray addObject:r];
    }
    [self setTableRows:rowsArray];
    
    // ****************************************************
    // Process Data
    
    // **************************
    // Create Table
    if (l_CreateTable == YES) {
        NSError *ctError = nil;
        [self createTable:self.tableName fields:self.tableFields error:&ctError];
        if (ctError) {
            qlerror(@"%@",[err description]);
            return NO;
        }
    } else {
        // Verify, Fix Table and cols
        if ([self compareAndFixTableStructure:self.tableFields] == NO) {
            qlerror(@"Error trying to validate/repair database table schema.");
            return NO;
        }
    }
    
    // **************************
    // Remove Data
    _didDeleteAll = -1;
    if (removeDataKeyPair != nil) {
        @try {
            qldebug(@"Removing existing records for '%@'",[removeDataKeyPair objectForKey:[[removeDataKeyPair allKeys] objectAtIndex:0]]);
            MysqlDelete *delete = [MysqlDelete deleteWithConnection:self.dbConnection];
            delete.tableName=self.tableName;
            delete.qualifier=[NSString stringWithFormat:@"%@ = '%@'",[[removeDataKeyPair allKeys] objectAtIndex:0],[removeDataKeyPair objectForKey:[[removeDataKeyPair allKeys] objectAtIndex:0]]];
            qltrace(@"Delete Qualifier [%@]: %@",self.tableName,delete.qualifier);
            [delete execute];
            //[delete executeUsingQuick];
            _didDeleteAll = 0;
            qldebug(@"Removing existing records complete.");
        }
        @catch (NSException *exception) {
            qlerror(@"%@",exception);
            _didDeleteAll = 1;
        }
    }
    
    // **************************
    // Insert/Update Data
    if (self.tableRows.count > 1000) {
        //[self.dbConnection enableTransactions];
    }
    for (NSDictionary *row in self.tableRows)
    {
        if (_didDeleteAll == 0) {
            @try {
                MysqlInsert *insert = [MysqlInsert insertWithConnection:self.dbConnection];
                insert.table=self.tableName;
                insert.rowData=[self cleanRowOfDuplicates:row];
                [insert execute];
            }
            @catch (NSException *exception) {
                qlerror(@"Error: %@",exception);
            }
        } else if ([self recordExistsInTable:self.tableName checkFields:self.checkFields row:row]) {
            // Need to update/remove/insert record
            if ([self.onExists isEqualToString:@"update"]) {
                @try {
                    // Create Update Qualifier
                    NSMutableDictionary *upQualifier = [[NSMutableDictionary alloc] init];
                    for (NSString *ckey in self.checkFields) {
                        for (NSString *rkey in [row allKeys]) {
                            if ([ckey isEqualToString:rkey]) {
                                [upQualifier setObject:[row objectForKey:ckey] forKey:ckey];
                            }
                        }
                    }
                    
                    MysqlUpdate *update = [MysqlUpdate updateWithConnection:self.dbConnection];
                    update.table=self.tableName;
                    update.rowData=row;
                    update.qualifier=upQualifier;
                    [update execute];
                }
                @catch (NSException *exception) {
                    qlerror(@"Error: %@",exception);
                }
            } else if ([self.onExists isEqualToString:@"remove"]) {
                @try {
                    
                    // Create Remove Qualifier
                    NSMutableString *rmQualifier = [[NSMutableString alloc] init];
                    [rmQualifier appendString:@"AND 0=0"];
                    for (NSString *ckey in self.checkFields) {
                        for (NSString *rkey in [row allKeys]) {
                            if ([ckey isEqualToString:rkey]) {
                                [rmQualifier appendFormat:@" AND %@ = '%@' ",ckey,[row objectForKey:ckey]];
                            }
                        }
                    }
                    
                    MysqlInsert *insert = [MysqlInsert insertWithConnection:self.dbConnection];
                    insert.table=self.tableName;
                    insert.rowData=row;
                    [insert execute];
                }
                @catch (NSException *exception) {
                    qlerror(@"Error: %@",exception);
                }
            } else if ([self.onExists isEqualToString:@"insert"]) {
                @try {
                    MysqlInsert *insert = [MysqlInsert insertWithConnection:self.dbConnection];
                    insert.table=self.tableName;
                    insert.rowData=row;
                    [insert execute];
                }
                @catch (NSException *exception) {
                    qlerror(@"Error: %@",exception);
                }
            }
        } else {
            // Insert Record
            @try {
                MysqlInsert *insert = [MysqlInsert insertWithConnection:self.dbConnection];
                insert.table=self.tableName;
                insert.rowData=row;
                [insert execute];
            }
            @catch (NSException *exception) {
                qlerror(@"Error: %@",exception);
            }
        }
        if (self.tableRows.count > 1000)
        {
            //[self.dbConnection commitTransaction];
            //[self.dbConnection disableTransactions];
        }
        
        
    }
    
    return YES;
}

- (BOOL)compareAndFixTableStructure:(NSArray *)xmlTableFields
{
    NSMutableArray *tAltAdd;
    NSMutableArray *tAltMod;
    
    int intResult = 0;
    NSError *iErr = nil;
    NSArray *tableFields = [self getDBTableStructure:self.tableName];
    
    // Add Missing Fields
    tAltAdd = [NSMutableArray arrayWithArray:[self findColumnsToAddToTable:xmlTableFields dbTable:tableFields]];
    if (tAltAdd != nil) {
        if ([tAltAdd count] > 0) {
            for (DBField *item in tAltAdd) {
                if ([item.name isEqualToString:@"dateInt"] == NO) { // Dont know why, this is legacy
                    iErr = nil;
                    [self alterSQLAddFieldToTable:self.tableName field:item error:&iErr];
                    if (iErr) {
                        qlerror(@"%@",[iErr description]);
                        intResult++;
                    }
                }
            }
        }
    }
    
    // Modify/Change Fields
    tAltMod = [NSMutableArray arrayWithArray:[self findColumnsToUpdateInTable:xmlTableFields dbTable:tableFields]];
    if (tAltMod != nil) {
        if ([tAltMod count] > 0) {
            for (DBField *item in tAltMod) {
                if ([item.name isEqualToString:@"dateInt"] == NO) { // Dont know why, this is legacy
                    iErr = nil;
                    [self alterSQLChangeFieldInTable:self.tableName field:item error:&iErr];
                    if (iErr) {
                        qlerror(@"%@",[iErr description]);
                        intResult++;
                    }
                }
            }
        }
    }
    
    return YES;
}

- (NSArray *)findColumnsToAddToTable:(NSArray *)xmlTableCols dbTable:(NSArray *)dbTableCols
{
    NSMutableArray *colsToAdd = [[NSMutableArray alloc] init];
    NSMutableArray *colNames = [[NSMutableArray alloc] init];
    for (MySQLTableColumn *col in dbTableCols) {
        [colNames addObject:[col.Field lowercaseString]];
    }
    
    for (DBField *field in xmlTableCols) {
        if ([colNames containsObject:[field.name lowercaseString]] == NO) {
            qldebug(@"%@ is missing from table.",field.name);
            [colsToAdd addObject:field];
        }
    }
    
    return (NSArray *)colsToAdd;
}

- (NSArray *)findColumnsToUpdateInTable:(NSArray *)xmlTableCols dbTable:(NSArray *)dbTableCols
{
    NSMutableArray *colsToMod = [[NSMutableArray alloc] init];
    unsigned int aCount = 0;
    for (DBField *xmlField in xmlTableCols)
    {
        NSDictionary *xmlFieldsDict = xmlField.fieldDescription;
        NSString *xmlFieldName = [[xmlFieldsDict objectForKey:@"name"] uppercaseString];
        aCount = 0;
        for (MySQLTableColumn *dbField in dbTableCols)
        {
            NSDictionary *dbFieldsDict = dbField.colDescription;
            NSString *dbFieldName = [[dbFieldsDict objectForKey:@"name"] uppercaseString];
            // They are equal, we need to compare
            if ([xmlFieldName isEqualToString:dbFieldName])
            {
                //NSLog(@"compare: %@",xmlFieldName);
                for (NSString *key in xmlFieldsDict.allKeys)
                {
                    if ([key isEqualToString:@"allowNull"]) {
                        // skip it, this has to be fixed
                        continue;
                    }
                    if ([key isEqualToString:@"defaultValue"]) {
                        // skip it, this has to be fixed
                        continue;
                    }
                    if ([[[xmlFieldsDict objectForKey:key] uppercaseString] isEqualToString:[[dbFieldsDict objectForKey:key] uppercaseString]])
                    {
                        // same, go to the next
                        continue;
                    }
                    else
                    {
                        if ([xmlFieldName isEqualToString:@"RID"] && [key isEqualToString:@"length"])
                        {
                            if ([[xmlFieldsDict objectForKey:key] intValue] < [[dbFieldsDict objectForKey:key] intValue])
                            {
                                continue;
                            }
                        }
                        if ([xmlFieldName isEqualToString:@"RID"] && [key isEqualToString:@"dataType"])
                        {
                            if ([self stringContains:[dbFieldsDict objectForKey:key] search:[xmlFieldsDict objectForKey:key]])
                            {
                                continue;
                            }
                        }
                        if ([xmlFieldName isEqualToString:@"RID"] && [key isEqualToString:@"dataTypeExt"])
                        {
                            continue;
                        }
                        if ([key isEqualToString:@"primaryKey"])
                        {
                            if ([[xmlFieldsDict objectForKey:key] length] == 0)
                            {
                                // A key was set via the database, not via XML. The database over rules this.
                                continue;
                            }
                        }
                        qldebug(@"Need to change %@: %@ != %@",key,[xmlFieldsDict objectForKey:key],[dbFieldsDict objectForKey:key] );
                        aCount = 1;
                    }
                }
            }
        }
        if (aCount == 1) {
            [colsToMod addObject:xmlField];
        }
        
    }
    if ([colsToMod count] > 0) {
        qlinfo(@"Items to fix %ld",[colsToMod count]);
    }
    return (NSArray *)colsToMod;
}

#pragma mark - Misc

- (BOOL)stringContains:(NSString *)aString search:(NSString *)aSearchString
{
    NSRange isRange = [aString rangeOfString:aSearchString options:NSCaseInsensitiveSearch];
    if(isRange.location != NSNotFound) {
        return YES;
    } else {
        return NO;
    }
    
    return NO;
}

- (NSString *)cleanColumnName:(NSString *)aString
{
    NSString *xString = [aString stringByReplacingOccurrencesOfString:@"(" withString:@""];
    xString = [xString stringByReplacingOccurrencesOfString:@")" withString:@""];
    xString = [xString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return [xString lowercaseString];
}

- (NSDictionary *)cleanRowOfDuplicates:(NSDictionary *)aDict
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSMutableSet *aSet = [[NSMutableSet alloc] init];
    // Get All Keys
    for (NSString *aKey in [aDict allKeys]) {
        [aSet addObject:[aKey lowercaseString]];
    }
    for (NSString *aKey in [aDict allKeys])
    {
        for (NSString *bKey in aSet)
        {
            if ([[aKey lowercaseString] isEqualToString:bKey]) {
                if (![result objectForKey:bKey]) {
                    [result setObject:@"na" forKey:bKey];
                }
                if ([[[aDict objectForKey:aKey] lowercaseString] isEqualToString:@"na"] == NO) {
                    [result setObject:[aDict objectForKey:aKey] forKey:bKey];
                }
                continue;
            }
        }
    }
    return (NSDictionary *)result;
}

@end
