//
//  MPDataMgr.m
/*
 Copyright (c) 2017, Lawrence Livermore National Security, LLC.
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

#undef  ql_component
#define ql_component lcl_cMPDataMgr

@implementation MPDataMgr

- (NSString *)GenXMLForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable
{
	NSString *xmlString;
	xmlString = [self GenXMLForDataMgr:aContent
							   dbTable:aTable 
						 dbTablePrefix:@"mpi_" 
						 dbFieldPrefix:@"mpa_" 
						  updateFields:@"cuuid" 
							 deleteCol:@"NA" 
						deleteColValue:@"NA"];
	return xmlString;
}

- (NSString *)GenXMLForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable 
				 dbTablePrefix:(NSString *)aTablePrefix
{
	NSString *xmlString;
	xmlString = [self GenXMLForDataMgr:aContent 
							   dbTable:aTable 
						 dbTablePrefix:@"mpi_" 
						 dbFieldPrefix:@"mpa_" 
						  updateFields:@"cuuid" 
							 deleteCol:@"NA" 
						deleteColValue:@"NA"];
	return xmlString;
}

- (NSString *)GenXMLForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable 
				 dbTablePrefix:(NSString *)aTablePrefix 
				 dbFieldPrefix:(NSString *)aFieldPrefix
{
	NSString *xmlString;
	xmlString = [self GenXMLForDataMgr:aContent
							   dbTable:aTable
						 dbTablePrefix:aTablePrefix
						 dbFieldPrefix:aFieldPrefix
						  updateFields:@"cuuid"
							 deleteCol:@"NA"
						deleteColValue:@"NA"];
	return xmlString;
}

- (NSString *)GenXMLForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable 
				 dbTablePrefix:(NSString *)aTablePrefix 
				 dbFieldPrefix:(NSString *)aFieldPrefix  
				  updateFields:(NSString *)aUpdateFields
{
	NSString *xmlString;
	xmlString = [self GenXMLForDataMgr:aContent
							   dbTable:aTable
						 dbTablePrefix:aTablePrefix
						 dbFieldPrefix:aFieldPrefix
						  updateFields:aUpdateFields
							 deleteCol:@"NA"
						deleteColValue:@"NA"];
	return xmlString;
}

- (NSString *)GenXMLForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable dbTablePrefix:(NSString *)aTablePrefix 
				 dbFieldPrefix:(NSString *)aFieldPrefix 
				  updateFields:(NSString *)aUpdateFields 
					 deleteCol:(NSString *)aDelCol 
				deleteColValue:(NSString *)aDelColVal
{
	NSString *xmlString;
	NSString *vCUUID = [MPSystemInfo clientUUID];
	NSString *l_tableName = [NSString stringWithFormat:@"%@%@",aTablePrefix,aTable];
	
	/*------------------------*/	
	/* Start XML Doc Creation */
	/*------------------------*/
	NSXMLElement *tables = (NSXMLElement *)[NSXMLNode elementWithName:@"tables"];
	NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:tables];
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];
	
	/* remove node      */
	if ([aDelCol isEqualToString:@"NA"] == FALSE) {
		[tables addChild:[self genXMLElement:@"remove" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																   aDelCol,		@"column",
																   aDelColVal,	@"valueEQ", nil]]];
	}	
	
	if ([aContent count] <= 0) {
		[tables addChild:[self genXMLElement:@"removerows" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																	   @"cuuid",	@"column",
																	   vCUUID,		@"value", 
																	   l_tableName,	@"table", nil]]];
	}
	
	
	/* start table node section */
	/* <tables><table>			*/
	NSXMLElement *tableNode = [[NSXMLElement alloc] initWithName:@"table"];
	[tableNode setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:l_tableName, @"name", nil]];
	[tables addChild:tableNode];
	
	/* The first three fields are required for all dataMgr entries  */
	/* fields = rid, cuuid, date									*/
	// <field ColumnName="rid" CF_DATATYPE="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" Length="11"/>
	[tableNode addChild:[self genXMLElement:@"field" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																 @"rid",			@"ColumnName",
																 @"CF_SQL_INTEGER",	@"CF_DATATYPE", 
																 @"true",			@"PrimaryKey",
																 @"true",			@"Increment",
																 @"11",				@"Length", nil]]];
	// <field ColumnName="cuuid" CF_DATATYPE="CF_SQL_VARCHAR" Length="50"/>
	[tableNode addChild:[self genXMLElement:@"field" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																 @"cuuid",			@"ColumnName",
																 @"CF_SQL_VARCHAR",	@"CF_DATATYPE", 
																 @"50",				@"Length", nil]]];
	// <field ColumnName="date" CF_DATATYPE="CF_SQL_TIMESTAMP" Default="0000-00-00 00:00:00"/>
	[tableNode addChild:[self genXMLElement:@"field" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																 @"date",					@"ColumnName",
																 @"CF_SQL_DATE",			@"CF_DATATYPE",
																 @"0000-00-00 00:00:00",	@"Default", nil]]];
	[tableNode addChild:[self genXMLElement:@"field" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																 @"mdate",					@"ColumnName",
																 @"CF_SQL_DATE",			@"CF_DATATYPE",
																 @"0000-00-00 00:00:00",	@"Default", nil]]];
	/* Loop through the dictonary fields and build the table structure */
	/* We will use varchar column type for all data, with len of 255   */
	// <field ColumnName="patch" CF_DATATYPE="CF_SQL_VARCHAR" Length="255"/>
	int i, x;
	if ([aContent count] > 0) {
		for (x = 0; x < [[[aContent objectAtIndex:0] allKeys] count]; x++) {
			[tableNode addChild:[self genXMLElement:@"field" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSString stringWithFormat:@"%@%@",aFieldPrefix,[[[aContent objectAtIndex:0] allKeys] objectAtIndex:x]],
			@"ColumnName",@"CF_SQL_VARCHAR",@"CF_DATATYPE", @"255",@"Length", nil]]];
		}
	}
	/* start the data section, contains the rows */
	/* <tables><data><row>						 */
	
	// First build the data element
	NSXMLElement *dataNode = [[NSXMLElement alloc] initWithName:@"data"];
	[dataNode setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
										 l_tableName,			@"table",
										 @"true",				@"permanentRows",
										 aUpdateFields,			@"checkFields",
										 @"update",				@"onexists", nil]];
	[tables addChild:dataNode];
	
	// Now We Loop through the field values and add the rows
	NSDictionary *theDict;
	NSArray *theKeys;
	NSXMLElement *rowElement;
	
	if ([aContent count] > 0) {
		for (i = 0; i < [aContent count]; i++) {
			theDict = [NSDictionary dictionaryWithDictionary:[aContent objectAtIndex:i]];
			theKeys = [NSArray arrayWithArray:[theDict allKeys]];
			rowElement = [[NSXMLElement alloc] initWithName:@"row"];
			[dataNode addChild:rowElement];
			
			[rowElement addChild:[self genXMLElement:@"field" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																		  @"cuuid",		@"name",
																		  vCUUID,		@"value", nil]]];
			[rowElement addChild:[self genXMLElement:@"field" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																		  @"date",					@"name",
																		  [MPDate dateTimeStamp],	@"value", nil]]];
			[rowElement addChild:[self genXMLElement:@"field" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																		  @"mdate",					@"name",
																		  [MPDate dateTimeStamp],	@"value", nil]]];
			for (x = 0; x < [theKeys count]; x++) {
				[rowElement addChild:[self genXMLElement:@"field" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			  [NSString stringWithFormat:@"%@%@",aFieldPrefix,[theKeys objectAtIndex:x]],@"name",															  				
																			  [theDict valueForKey:[theKeys objectAtIndex:x]],@"value", nil]]];
			}
		}
	}
	
	
	/* Example data/row output 
	 <data table="mp_client_patches" permanentRows="true" checkFields="cuuid,patch" onexists="update">
	 <row>
	 <field name="cuuid" value="15334227-C3FF-5C67-B783-ED6521C20A3A"/>
	 <field name="date" value="2010-05-11 12:03:20"/>
	 </row>
	 </data>
	 */
	
	// Return the data
	NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
	xmlString = [[NSString alloc] initWithData:xmlData encoding:NSASCIIStringEncoding];
    qldebug(@"%@",xmlString);
	return xmlString;
}

- (NSXMLElement *)genXMLElement:(NSString *)aName attributes:(NSDictionary *)aDict
{
	NSXMLElement *xNode = (NSXMLElement *)[NSXMLNode elementWithName:aName];
	[xNode setAttributesAsDictionary:aDict];
	return xNode;
}

#pragma mark - JSON DataMgr Code

- (NSString *)GenJSONForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable
{
	NSString *jsonString;
	jsonString = [self GenJSONForDataMgr:aContent
							   dbTable:aTable
						 dbTablePrefix:@"mpi_"
						 dbFieldPrefix:@"mpa_"
						  updateFields:@"cuuid"
							 deleteCol:@"NA"
						deleteColValue:@"NA"];
	return jsonString;
}

- (NSString *)GenJSONForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable
				 dbTablePrefix:(NSString *)aTablePrefix
{
	NSString *jsonString;
	jsonString = [self GenJSONForDataMgr:aContent
							   dbTable:aTable
						 dbTablePrefix:@"mpi_"
						 dbFieldPrefix:@"mpa_"
						  updateFields:@"cuuid"
							 deleteCol:@"NA"
						deleteColValue:@"NA"];
	return jsonString;
}

- (NSString *)GenJSONForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable
				 dbTablePrefix:(NSString *)aTablePrefix
				 dbFieldPrefix:(NSString *)aFieldPrefix
				  updateFields:(NSString *)aUpdateFields
{
	NSString *jsonString;
	jsonString = [self GenJSONForDataMgr:aContent
							   dbTable:aTable
						 dbTablePrefix:aTablePrefix
						 dbFieldPrefix:aFieldPrefix
						  updateFields:aUpdateFields
							 deleteCol:@"NA"
						deleteColValue:@"NA"];
	return jsonString;
}

- (NSString *)GenJSONForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable
				 dbTablePrefix:(NSString *)aTablePrefix
				 dbFieldPrefix:(NSString *)aFieldPrefix
{
	NSString *jsonString;
	jsonString = [self GenJSONForDataMgr:aContent
							   dbTable:aTable
						 dbTablePrefix:aTablePrefix
						 dbFieldPrefix:aFieldPrefix
						  updateFields:@"cuuid"
							 deleteCol:@"NA"
						deleteColValue:@"NA"];
	return jsonString;
}

- (NSString *)GenJSONForDataMgr:(NSArray *)aContent dbTable:(NSString *)aTable dbTablePrefix:(NSString *)aTablePrefix
				 dbFieldPrefix:(NSString *)aFieldPrefix
				  updateFields:(NSString *)aUpdateFields
					 deleteCol:(NSString *)aDelCol
				deleteColValue:(NSString *)aDelColVal
{
    NSMutableDictionary *invDict = [[NSMutableDictionary alloc] init];
    // Set Key = cuuid
    NSString *_cuuid = [MPSystemInfo clientUUID];
    [invDict setObject:_cuuid forKey:@"key"];
    // Set Table Name
    [invDict setObject:[NSString stringWithFormat:@"%@%@",aTablePrefix,aTable] forKey:@"table"];

    if (aDelCol != NULL) {
        [invDict setObject:[NSNumber numberWithBool:NO] forKey:@"permanentRows"];
    } else {
        [invDict setObject:[NSNumber numberWithBool:YES] forKey:@"permanentRows"];
    }

    // Autofields, this will let the inv processor script add the schema required fields
    [invDict setObject:@"rid,cuuid,mdate" forKey:@"autoFields"];
    [invDict setObject:@"update" forKey:@"onexists"];
    [invDict setObject:@"rid,cuuid" forKey:@"checkFields"];

    NSMutableArray *fields = [[NSMutableArray alloc] init];
	/* Loop through the dictonary fields and build the table structure */
	/* We will use varchar column type for all data, with len of 255   */
	int i, x;
	if ([aContent count] > 0) {
		for (x = 0; x < [[[aContent objectAtIndex:0] allKeys] count]; x++)
        {
            [fields addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                               [NSString stringWithFormat:@"%@%@",aFieldPrefix,[[[aContent objectAtIndex:0] allKeys] objectAtIndex:x]],
                               @"name",@"varchar",@"dataType",@"255",@"length", nil]];
		}
	}
    [invDict setObject:[NSArray arrayWithArray:fields] forKey:@"fields"];

	/* start the data section, contains the rows */
	/* <tables><data><row>						 */

	// Now We Loop through the field values and add the rows
	NSDictionary *theDict;
	NSArray *theKeys;
    NSString *_dateTimeStamp = [MPDate dateTimeStamp];
    NSMutableArray *rows = [[NSMutableArray alloc] init];
    NSMutableDictionary *row;
	if ([aContent count] > 0)
    {
		for (i = 0; i < [aContent count]; i++)
        {
            row = [[NSMutableDictionary alloc] init];
            // Default Row Objects
            [row setObject:_cuuid forKey:@"cuuid"];
            [row setObject:_dateTimeStamp forKey:@"mdate"];

			theDict = [NSDictionary dictionaryWithDictionary:[aContent objectAtIndex:i]];
			theKeys = [NSArray arrayWithArray:[theDict allKeys]];

			for (x = 0; x < [theKeys count]; x++)
            {
                NSString *name = [NSString stringWithFormat:@"%@%@",aFieldPrefix,[theKeys objectAtIndex:x]];
                NSString *value;
                // C
                if ([[theDict valueForKey:[theKeys objectAtIndex:x]] isKindOfClass:[NSDate class]])
                {
                    value = [NSDate stringFromDate:[theDict valueForKey:[theKeys objectAtIndex:x]]];
                }
                else if ([[theDict valueForKey:[theKeys objectAtIndex:x]] isKindOfClass:[NSNumber class]])
                {
                    value = [[theDict valueForKey:[theKeys objectAtIndex:x]] stringValue];
                }
                else
                {
                    value = [[theDict valueForKey:[theKeys objectAtIndex:x]] stringByReplacingOccurrencesOfString:@" +0000" withString:@""];
                }

                [row setObject:value forKey:name];
			}
            [rows addObject:[NSDictionary dictionaryWithDictionary:row]];
		}
	}
    [invDict setObject:[NSArray arrayWithArray:rows] forKey:@"rows"];

    // Create JSON String
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:invDict options:0 error:&error];
    NSString *jsonString = nil;
    if (!jsonData) {
        qlerror(@"JSON Error: %@",error.localizedDescription);
    } else {
        jsonString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }

    return jsonString;
}

@end
