<!--- 2.5 Beta 2 (Build 166) --->
<!--- Last Updated: 2010-12-12 --->
<!--- Created by Steve Bryant 2004-12-08 --->
<!--- Information: sebtools.com --->
<cfcomponent displayname="Data Manager" hint="I manage data interactions with the database. I can be used to handle inserts/updates.">

<cfset variables.DataMgrVersion = "2.5 Beta 1">
<cfset variables.DefaultDatasource = getDefaultDatasource()>

<cffunction name="init" access="public" returntype="DataMgr" output="no" hint="I instantiate and return this object.">
	<cfargument name="datasource" type="string" required="no" default="#variables.DefaultDatasource#">
	<cfargument name="database" type="string" required="no">
	<cfargument name="username" type="string" required="no">
	<cfargument name="password" type="string" required="no">
	<cfargument name="SmartCache" type="boolean" default="false">
	<cfargument name="SpecialDateType" type="string" default="CF">
	<cfargument name="XmlData" type="string" required="no">
	
	<cfset var me = 0>
	
	<cfset variables.datasource = arguments.datasource>
	<cfset variables.CFServer = Server.ColdFusion.ProductName>
	<cfset variables.CFVersion = ListFirst(Server.ColdFusion.ProductVersion)>
	<cfset variables.SpecialDateType = arguments.SpecialDateType>
	
	<cfif StructKeyExists(arguments,"username") AND StructKeyExists(arguments,"password")>
		<cfset variables.username = arguments.username>
		<cfset variables.password = arguments.password>
	</cfif>
	
	<cfif StructKeyExists(arguments,"defaultdatabase")>
		<cfset variables.defaultdatabase = arguments.defaultdatabase>
	</cfif>
	
	<cfset variables.SmartCache = arguments.SmartCache>
	
	<cfset variables.dbprops = getProps()>
	<cfset variables.tables = StructNew()><!--- Used to internally keep track of table fields used by DataMgr --->
	<cfset variables.tableprops = StructNew()><!--- Used to internally keep track of tables properties used by DataMgr --->
	<cfset setCacheDate()><!--- Used to internally keep track caching --->
	
	<!--- instructions for special processing decisions --->
	<cfset variables.nocomparetypes = "CF_SQL_LONGVARCHAR,CF_SQL_CLOB"><!--- Don't run comparisons against fields of these cf_datatypes for queries --->
	<cfset variables.dectypes = "CF_SQL_DECIMAL"><!--- Decimal types (shouldn't be rounded by DataMgr) --->
	<cfset variables.aggregates = "avg,count,max,min,sum">
	
	<!--- Information for logging --->
	<cfset variables.doLogging = false>
	<cfset variables.logtable = "datamgrLogs">
	<cfset variables.UUID = CreateUUID()>
	
	<!--- Code to run only if not in a database adaptor already --->
	<cfif ListLast(getMetaData(this).name,".") EQ "DataMgr">
		<cfif NOT StructKeyExists(arguments,"database")>
			<cfset addEngineEnhancements(true)>
			<cfset arguments.database = getDatabase()>
		</cfif>
		
		<!--- This will make sure that if a database is passed the component for that database is returned --->
		<cfif StructKeyExists(arguments,"database")>
			<cfif StructKeyExists(variables,"username") AND StructKeyExists(variables,"password")>
				<cfset me = CreateObject("component","DataMgr_#arguments.database#").init(datasource=arguments.datasource,username=arguments.username,password=arguments.password)>
			<cfelse>
				<cfset me = CreateObject("component","DataMgr_#arguments.database#").init(arguments.datasource)>
			</cfif>
		</cfif>
	<cfelse>
		<cfset addEngineEnhancements(false)>
		<cfset me = this>
	</cfif>
	
	<cfif StructKeyExists(arguments,"XmlData")>
		<cfset me.loadXml(arguments.XmlData,true,true)/>
	</cfif>
	
	<cfreturn me>
</cffunction>

<cffunction name="addEngineEnhancements" access="private" returntype="void" output="no">
	<cfargument name="isLoadingDatabaseType" type="boolean" default="false">
	
	<cfset var oMixer = 0>
	<cfset var key = "">
	
	<cfif ListFirst(variables.CFServer," ") EQ "ColdFusion" AND variables.CFVersion GTE 8>
		<cfset oMixer = CreateObject("component","DataMgrEngine_cf8")>
	<cfelseif variables.CFServer EQ "BlueDragon">
		<cfset oMixer = CreateObject("component","DataMgrEngine_openbd")>
	<cfelseif variables.CFServer EQ "Railo">
		<cfset oMixer = CreateObject("component","DataMgrEngine_railo")>
	</cfif>
	
	<cfif isObject(oMixer)>
		<cfloop collection="#oMixer#" item="key">
			<cfif key NEQ "getDatabase" OR arguments.isLoadingDatabaseType>
				<cfset variables[key] = oMixer[key]>
				<cfif StructKeyExists(This,key)>
					<cfset This[key] = oMixer[key]>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	
</cffunction>

<cffunction name="setCacheDate" access="public" returntype="void" output="no">
	<cfset variables.CacheDate = now()>
</cffunction>

<cffunction name="getDefaultDatasource" access="public" returntype="string" output="no">
	
	<cfset var result = "">
	
	<cftry>
		<cfif isDefined("Application") AND StructKeyExists(Application,"Datasource")>
			<cfset result = Application.Datasource>
		</cfif>
	<cfcatch>
	</cfcatch>
	</cftry>
	
	<cfreturn result>
</cffunction>

<cffunction name="clean" access="public" returntype="struct" output="no" hint="I return a clean version (stripped of MS-Word characters) of the given structure.">
	<cfargument name="Struct" type="struct" required="yes">
	
	<cfset var key = "">
	<cfset var sResult = StructNew()>
	
	<cfscript>
	for (key in arguments.Struct) {
		if ( Len(key) AND StructKeyExists(arguments.Struct,key) AND isSimpleValue(arguments.Struct[key]) ) {
			// Trim the field value. -- Don't do it! This causes trouble with encrypted strings
			//sResult[key] = Trim(sResult[key]);
			// Replace the special characters that Microsoft uses.
			sResult[key] = arguments.Struct[key];
			sResult[key] = Replace(sResult[key], Chr(8211), "-", "ALL");// dashes
			sResult[key] = Replace(sResult[key], Chr(8212), "-", "ALL");// dashes
			sResult[key] = Replace(sResult[key], Chr(8216), Chr(39), "ALL");// apostrophe / single-quote
			sResult[key] = Replace(sResult[key], Chr(8217), Chr(39), "ALL");// apostrophe / single-quote
			sResult[key] = Replace(sResult[key], Chr(8220), Chr(34), "ALL");// quotes
			sResult[key] = Replace(sResult[key], Chr(8221), Chr(34), "ALL");// quotes
			sResult[key] = Replace(sResult[key], Chr(8230), "...", "ALL");// elipses
			sResult[key] = Replace(sResult[key], Chr(8482), "&trade;", "ALL");// trademark
			
			sResult[key] = Replace(sResult[key], "&##39;", Chr(39), "ALL");// apostrophe / single-quote
			sResult[key] = Replace(sResult[key], "&##160;", Chr(39), "ALL");// space
			sResult[key] = Replace(sResult[key], "&##8211;", "-", "ALL");// dashes
			sResult[key] = Replace(sResult[key], "&##8212;", "-", "ALL");// dashes
			sResult[key] = Replace(sResult[key], "&##8216;", Chr(39), "ALL");// apostrophe / single-quote
			sResult[key] = Replace(sResult[key], "&##8217;", Chr(39), "ALL");// apostrophe / single-quote
			sResult[key] = Replace(sResult[key], "&##8220;", Chr(34), "ALL");// quotes
			sResult[key] = Replace(sResult[key], "&##8221;", Chr(34), "ALL");// quotes
			sResult[key] = Replace(sResult[key], "&##8230;", "...", "ALL");// elipses
			sResult[key] = Replace(sResult[key], "&##8482;", "&trade;", "ALL");// trademark
		}
	}
	</cfscript>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="createTable" access="public" returntype="string" output="no" hint="I take a table (for which the structure has been loaded) and create the table in the database.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var CreateSQL = getCreateSQL(arguments.tablename)>
	<cfset var thisSQL = "">
	
	<cfset var ii = 0><!--- generic counter --->
	<cfset var arrFields = getFields(arguments.tablename)><!--- table structure --->
	<cfset var increments = 0>
	
	<!--- Make sure table has no more than one increment field --->
	<cfloop index="ii" from="1" to="#ArrayLen(arrFields)#" step="1">
		<cfif arrFields[ii].Increment>
			<cfset increments = increments + 1>
		</cfif>
	</cfloop>
	<cfif increments GT 1>
		<cfset throwDMError("#arguments.tablename# has more than one increment field. A table is limited to only one increment field.","MultipleIncrements")>
	</cfif>
	
	<cfset StructDelete(variables,"cache_dbtables")>
	
	<!--- try to create table --->
	<cftry>
		<cfloop index="thisSQL" list="#CreateSQL#" delimiters=";"><cfif thisSQL CONTAINS " ">
			<!--- Ugly hack to get around Oracle's need for a semi-colon in SQL that doesn't split up SQL commands --->
			<cfset thisSQL = ReplaceNoCase(thisSQL,"|DataMgr_SemiColon|",";","ALL")>
			<cfset runSQL(thisSQL)>
		</cfif></cfloop>
		<cfcatch><!--- If the ceation fails, throw an error with the sql code used to create the database. --->
			<cfif NOT (
					CFCATCH.Message CONTAINS "There is already an object named"
				OR	(
							StructKeyExists(CFCATCH,"Cause")
						AND	StructKeyExists(CFCATCH.Cause,"Message")
						AND	CFCATCH.Cause.Message CONTAINS "There is already an object named"
					)
			)>
				<cfset throwDMError("SQL Error in Creation. Verify Datasource (#chr(34)##variables.datasource##chr(34)#) is valid.","CreateFailed",CreateSQL)>
			</cfif>
		</cfcatch>
	</cftry>
	
	<cfset setCacheDate()>
	
	<cfreturn CreateSQL>
</cffunction>

<cffunction name="dbtableexists" access="public" returntype="boolean" output="no" hint="I indicate whether or not the given table exists in the database">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="dbtables" type="string" default="">
	
	<cfset var result = false>
	
	<cfif NOT ( StructKeyExists(arguments,"dbtables") AND Len(Trim(arguments.dbtables)) )>
		<cfset arguments.dbtables = "">
		<cftry><!--- Try to get a list of tables load in DataMgr --->
			<cfset arguments.dbtables = getDatabaseTablesCache()>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfif Len(arguments.dbtables)><!--- If we have tables loaded in DataMgr --->
		<cfif ListFindNoCase(arguments.dbtables, arguments.tablename)>
			<cfset result = true>
		</cfif>
	</cfif>
	<!--- SEB 2010-04-25: This seems a tad aggresive (a lot of penalty for a just in case measure). Let's ditch it unless it proves essential. --->
	<cfif false AND NOT result>
		<cfset result = true>
		<cftry><!--- create any table on which a select statement errors --->
			<cfset qTest = runSQL("SELECT #getMaxRowsPrefix(1)# #escape(variables.tables[arguments.tablename][1].ColumnName)# FROM #escape(arguments.tablename)# #getMaxRowsSuffix(1)#")>
			<cfcatch>
				<cfset result = false>
			</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="CreateTables" access="public" returntype="void" output="no" hint="I create any tables that I know should exist in the database but don't.">
	<cfargument name="tables" type="string" required="no" hint="I am a list of tables to create. If I am not provided createTables will try to create any table that has been loaded into it but does not exist in the database.">
	<cfargument name="dbtables" type="string" required="false">
	
	<cfset var table = "">
	<cfset var tablesExist = StructNew()>
	<cfset var qTest = 0>
	<cfset var FailedSQL = "">
	<cfset var DBErr = "">
	
	<cfif NOT StructKeyExists(arguments,"tables")>
		<cfset arguments.tables = StructKeyList(variables.tables)>
	</cfif>
	
	<cfif NOT ( StructKeyExists(arguments,"dbtables") AND Len(Trim(arguments.dbtables)) )>
		<cfset arguments.dbtables = "">
		<cftry><!--- Try to get a list of tables load in DataMgr --->
			<cfset arguments.dbtables = getDatabaseTablesCache()>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfloop index="table" list="#arguments.tables#">
		<!--- Create table if it doesn't exist --->
		<cfif NOT dbtableexists(table,arguments.dbtables)>
			<cftry>
				<cfset createTable(table)>
				<cfset arguments.dbtables = ListAppend(arguments.dbtables,table)> 
				<cfcatch type="DataMgr">
					<cfif Len(CFCATCH.Detail)>
						<cfset FailedSQL = ListAppend(FailedSQL,CFCATCH.Detail,";")>
					<cfelse>
						<cfset FailedSQL = ListAppend(FailedSQL,CFCATCH.Message,";")>
					</cfif>
					<cfif Len(CFCATCH.ExtendedInfo)>
						<cfset DBErr = CFCATCH.ExtendedInfo>
					</cfif>
				</cfcatch>
			</cftry>
		</cfif>
	</cfloop>
	
	<cfif Len(FailedSQL)>
		<cfset throwDMError("SQL Error in Creation. Verify Datasource (#chr(34)##variables.datasource##chr(34)#) is valid.","CreateFailed",FailedSQL,DBErr)>
	</cfif>
	
</cffunction>

<cffunction name="deleteRecord" access="public" returntype="void" output="no" hint="I delete the record with the given Primary Key(s).">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table from which to delete a record.">
	<cfargument name="data" type="struct" required="yes" hint="A structure indicating the record to delete. A key indicates a field. The structure should have a key for each primary key in the table.">
	
	<cfset var i = 0><!--- just a counter --->
	<cfset var fields = getUpdateableFields(arguments.tablename)>
	<cfset var pkfields = getPKFields(arguments.tablename)><!--- the primary key fields for this table --->
	<cfset var rfields = getRelationFields(arguments.tablename)><!--- relation fields in table --->
	<cfset var in = arguments.data><!--- The incoming data structure --->
	<cfset var isLogicalDelete = isLogicalDeletion(arguments.tablename)>
	<cfset var qRecord = 0>
	<cfset var sqlarray = ArrayNew(1)>
	<cfset var out = 0>
	<cfset var temp2 = 0>
	<!---<cfset var qRelationList = 0>--->
	<!---<cfset var subdatum = StructNew()>--->
	<!---<cfset var sArgs = StructNew()>--->
	<cfset var conflicttables = "">
	<cfset var sCascadeDeletions = 0>
	
	<cfset var pklist = getPrimaryKeyFieldNames(arguments.tablename)>
	
	<!--- Throw exception if any pkfields are missing from incoming data --->
	<cfloop index="i" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif NOT StructKeyExists(in,pkfields[i].ColumnName)>
			<cfset throwDMError("All Primary Key fields (#pklist#) must be used when deleting a record. (Passed = #StructKeyList(in)#, Table=#arguments.tablename#)","RequiresAllPkFields")>
		</cfif>
	</cfloop>
	
	<!--- Only get records by primary key --->
	<cfloop collection="#in#" item="temp2">
		<cfif NOT ListFindNoCase(pklist,temp2)>
			<cfset StructDelete(in,temp2)>
		</cfif>
	</cfloop>
	<cfset arguments.data = in>
	
	<!--- Get the record containing the given data --->
	<cfset qRecord = getRecord(arguments.tablename,in)>
	
	<cfif qRecord.RecordCount EQ 1>
		<!--- Look for onDelete errors --->
		<cfset conflicttables = getDeletionConflicts(tablename=arguments.tablename,data=arguments.data,qRecord=qRecord)>
		<cfif Len(conflicttables)>
			<cfset throwDMError("You cannot delete a record in #arguments.tablename# when associated records exist in #conflicttables#.","NoDeletesWithRelated")>
		</cfif>
		<!---
		SEB 2010-10-25: Replaced with above 3 lines (pending testing)
		<cfloop index="i" from="1" to="#ArrayLen(rfields)#" step="1">
			<cfif StructKeyExists(rfields[i].Relation,"onDelete") AND StructKeyExists(rfields[i].Relation,"onDelete") AND rfields[i].Relation["onDelete"] EQ "Error">
				<cfif rfields[i].Relation["type"] EQ "list" OR ListFindNoCase(variables.aggregates,rfields[i].Relation["type"])>
					
					<cfset subdatum.data = StructNew()>
					<cfset subdatum.advsql = StructNew()>
					
					<cfif StructKeyExists(rfields[i].Relation,"join-table")>
						<cfset subdatum.subadvsql = StructNew()>
						<cfset subdatum.subadvsql.WHERE = "#escape( rfields[i].Relation['join-table'] & '.' & rfields[i].Relation['join-table-field-remote'] )# = #escape( rfields[i].Relation['table'] & '.' & rfields[i].Relation['remote-table-join-field'] )#">
						<cfset subdatum.data[rfields[i].Relation["local-table-join-field"]] = qRecord[rfields[i].Relation["join-table-field-local"]][1]>
						<cfset subdatum.advsql.WHERE = ArrayNew(1)>
						<cfset ArrayAppend(subdatum.advsql.WHERE,"EXISTS (")>
						<cfset ArrayAppend(subdatum.advsql.WHERE,getRecordsSQL(tablename=rfields[i].Relation["join-table"],data=subdatum.data,advsql=subdatum.subadvsql,isInExists=true))>
						<cfset ArrayAppend(subdatum.advsql.WHERE,")")>
					<cfelse>
						<cfset subdatum.data[rfields[i].Relation["join-field-remote"]] = qRecord[rfields[i].Relation["join-field-local"]][1]>
					</cfif>
					
					<cfset sArgs["tablename"] = rfields[i].Relation["table"]>
					<cfset sArgs["data"] = subdatum.data>
					<cfset sArgs["fieldlist"] = rfields[i].Relation["field"]>
					<cfset sArgs["advsql"] = subdatum.advsql>
					<cfif StructKeyExists(rfields[i].Relation,"filters") AND isArray(rfields[i].Relation.filters)>
						<cfset sArgs["filters"] = rfields[i].Relation.filters>
					</cfif>
					
					<cfset qRelationList = getRecords(argumentCollection=sArgs)>
					
					<cfif qRelationList.RecordCount>
						<cfset throwDMError("You cannot delete a record in #arguments.tablename# when associated records exist in #rfields[i].Relation.table#.","NoDeletesWithRelated")>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>--->
		
		<!--- Look for onDelete cascade --->
		<cfset sCascadeDeletions = getCascadeDeletions(tablename=arguments.tablename,data=arguments.data,qRecord=qRecord)>
		<cfloop item="temp2" collection="#sCascadeDeletions#">
			<cfset deleteRecords(tablename=temp2,data=sCascadeDeletions[temp2])>
		</cfloop>
		<!---
		SEB 2010-10-25: Replaced with above 3 lines (pending testing)
		<cfloop index="i" from="1" to="#ArrayLen(rfields)#" step="1">
			<cfif
					(
							StructKeyExists(rfields[i].Relation,"onDelete")
						AND	rfields[i].Relation["onDelete"] EQ "Cascade"
					)
				AND	(
							rfields[i].Relation["type"] EQ "list"
						OR	ListFindNoCase(variables.aggregates,rfields[i].Relation["type"])
					)
			>
				<cfset out = StructNew()>
				
				<cfif StructKeyExists(rfields[i].Relation,"join-table")>
					<cfset out[rfields[i].Relation["join-table-field-local"]] = in[rfields[i].Relation["local-table-join-field"]]>
					<cfset deleteRecords(rfields[i].Relation["join-table"],out)>
				<cfelse>
					<cfset out[rfields[i].Relation["join-field-remote"]] = qRecord[rfields[i].Relation["join-field-local"]][1]>
					<cfset deleteRecords(rfields[i].Relation["table"],out)>
				</cfif>
			</cfif>
		</cfloop>
		--->
		
		<!--- Perform the delete --->
		<cfif isLogicalDelete>
			<!--- Look for DeletionMark field --->
			<cfloop index="i" from="1" to="#ArrayLen(fields)#" step="1">
				<cfif StructKeyExists(fields[i],"Special") AND fields[i].Special EQ "DeletionMark">
					<cfif fields[i].CF_DataType EQ "CF_SQL_BIT">
						<cfset in[fields[i].ColumnName] = 1>
					<cfelseif fields[i].CF_DataType EQ "CF_SQL_DATE" OR fields[i].CF_DataType EQ "CF_SQL_DATETIME">
						<cfset in[fields[i].ColumnName] = now()>
					</cfif>
				</cfif>
			</cfloop>
			<cfset updateRecord(arguments.tablename,in)>
		<cfelse>
			<!--- Delete Record --->
			<cfset sqlarray = ArrayNew(1)>
			<cfset ArrayAppend(sqlarray,"DELETE FROM	#escape(arguments.tablename)# WHERE	1 = 1")>
			<cfset ArrayAppend(sqlarray,getWhereSQL(argumentCollection=arguments))>
			<cfset runSQLArray(sqlarray)>
			
			<!--- Log delete --->
			<cfif variables.doLogging AND NOT arguments.tablename EQ variables.logtable>
				<cfinvoke method="logAction">
					<cfinvokeargument name="tablename" value="#arguments.tablename#">
					<cfif ArrayLen(pkfields) EQ 1 AND StructKeyExists(in,pkfields[1].ColumnName)>
						<cfinvokeargument name="pkval" value="#in[pkfields[1].ColumnName]#">
					</cfif>
					<cfinvokeargument name="action" value="delete">
					<cfinvokeargument name="data" value="#in#">
					<cfinvokeargument name="sql" value="#sqlarray#">
				</cfinvoke>
			</cfif>
			
		</cfif>
		
		<cfset setCacheDate()>
	</cfif>

</cffunction>

<cffunction name="deleteRecords" access="public" returntype="void" output="no" hint="I delete the records with the given data.">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table from which to delete a record.">
	<cfargument name="data" type="struct" default="#StructNew()#" hint="A structure indicating the record to delete. A key indicates a field. The structure should have a key for each primary key in the table.">
	
	<cfset var qRecords = getRecords(tablename=arguments.tablename,data=arguments.data,fieldlist=getPrimaryKeyFieldNames(arguments.tablename))>
	<cfset var out = StructNew()>
	
	<cfoutput query="qRecords">
		<cfset out = QueryRowToStruct(qRecords,CurrentRow)>
		<cfset deleteRecord(arguments.tablename,out)>
	</cfoutput>
	
</cffunction>

<cffunction name="getBooleanSqlValue" access="public" returntype="string" output="no">
	<cfargument name="value" type="string" required="yes">
	
	<cfset var result = "NULL">
	
	<cfif isBoolean(arguments.value)>
		<cfif arguments.value>
			<cfset result = "1">
		<cfelse>
			<cfset result = "0">
		</cfif>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getCascadeDeletions" access="public" returntype="struct" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table from which to delete a record.">
	<cfargument name="data" type="struct" required="yes" hint="A structure indicating the record to delete. A key indicates a field. The structure should have a key for each primary key in the table.">

	<cfset var rfields = getRelationFields(arguments.tablename)><!--- relation fields in table --->
	<cfset var ii = 0>
	<cfset var sResult = StructNew()>
	
	<cfif NOT StructKeyExists(arguments,"qRecord")>
		<cfset arguments.qRecord = getRecord(tablename=arguments.tablename,data=arguments.data)>
	</cfif>
	
	<cfloop index="ii" from="1" to="#ArrayLen(rfields)#" step="1">
		<cfif
				(
						ListFindNoCase(variables.aggregates,rfields[ii].Relation["type"])
					OR	rfields[ii].Relation["type"] EQ "list"
				)
			AND	(
						(
								StructKeyExists(rfields[ii].Relation,"onDelete")
							AND	rfields[ii].Relation["onDelete"] EQ "Cascade"
						)
					OR	(
								StructKeyExists(rfields[ii].Relation,"join-table")
							AND	NOT (
										StructKeyExists(rfields[ii].Relation,"onDelete")
									AND	rfields[ii].Relation["onDelete"] NEQ "Cascade"
								)
						)
				)
			AND	(
						StructKeyExists(rfields[ii].Relation,"table")
					AND	NOT StructKeyExists(sResult,rfields[ii].Relation["table"])
				)
		>
			<cfif StructKeyExists(rfields[ii].Relation,"join-table")>
				<cfset sResult[rfields[ii].Relation["join-table"]] = StructNew()>
				<cfset sResult[rfields[ii].Relation["join-table"]][rfields[ii].Relation["join-table-field-local"]] = arguments.qRecord[rfields[ii].Relation["local-table-join-field"]][1]>
			<cfelse>
				<cfset sResult[rfields[ii].Relation["table"]] = StructNew()>
				<cfset sResult[rfields[ii].Relation["table"]][rfields[ii].Relation["join-field-remote"]] = arguments.qRecord[rfields[ii].Relation["join-field-local"]][1]>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getDataBase" access="public" returntype="string" output="no" hint="I return the database platform being used.">
	
	<cfset var connection = 0>
	<cfset var db = "">
	<cfset var type = "">
	<!---<cfset var qDatabases = getSupportedDatabases()>--->
	
	<cfif Len(variables.datasource)>
		<cftry>
			<cfset connection = getConnection()>
		<cfcatch>
			<cfif StructKeyExists(variables,"defaultdatabase")>
				<cfset type = variables.defaultdatabase>
			<cfelse>
				<cfif cfcatch.Message CONTAINS "Permission denied">
					<cfset throwDMError("DataMgr was unable to determine database type.","DatabaseTypeRequired","DataMgr was unable to determine database type. Please pass the database argument (second argument of init method) to DataMgr.")>
				<cfelse>
					<cfrethrow>
				</cfif>
			</cfif>
		</cfcatch>
		</cftry>
		<cfset db = connection.getMetaData().getDatabaseProductName()>
		<cfset connection.close()>
		
		<cfswitch expression="#db#">
		<cfcase value="Microsoft SQL Server">
			<cfset type = "MSSQL">
		</cfcase>
		<cfcase value="MySQL">
			<cfset type = "MYSQL">
		</cfcase>
		<cfcase value="PostgreSQL">
			<cfset type = "PostGreSQL">
		</cfcase>
		<cfcase value="Oracle">
			<cfset type = "Oracle">
		</cfcase>
		<cfcase value="MS Jet">
			<cfset type = "Access">
		</cfcase>
		<cfcase value="Apache Derby">
			<cfset type = "Derby">
		</cfcase>
		<cfdefaultcase>
			<cfif ListFirst(db,"/") EQ "DB2">
				<cfset type = "DB2">
			<cfelse>
				<cfset type = "unknown">
				<cfset type = db>
			</cfif>
		</cfdefaultcase>
		</cfswitch>
	<cfelse>
		<cfset type = "Sim">
	</cfif>
	
	<cfreturn type>
</cffunction>

<cffunction name="getDatabaseProperties" access="public" returntype="struct" output="no" hint="I return some properties about this database">
	
	<cfset var sProps = StructNew()>
	
	<cfreturn sProps>
</cffunction>

<cffunction name="getDatabaseShortString" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "unknown"><!--- This method will get overridden in database-specific DataMgr components --->
</cffunction>

<cffunction name="getDatabaseDriver" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "">
</cffunction>

<cffunction name="getDatasource" access="public" returntype="string" output="no" hint="I return the datasource used by this Data Manager.">
	<cfreturn variables.datasource>
</cffunction>

<cffunction name="getDBFieldList" access="public" returntype="string" output="no" hint="I return a list of fields in the database for the given table.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var qFields = runSQL("SELECT	#getMaxRowsPrefix(1)# * FROM #escape(arguments.tablename)# #getMaxRowsSuffix(1)#")>
	
	<cfreturn qFields.ColumnList>
</cffunction>

<cffunction name="getDefaultValues" access="public" returntype="struct" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var sFields = 0>
	<cfset var aFields = 0>
	<cfset var ii = 0>
	
	<!--- If fields data if stored --->
	<cfif StructKeyExists(variables.tableprops,arguments.tablename) AND StructKeyExists(variables.tableprops[arguments.tablename],"fielddefaults")>
		<cfset sFields = variables.tableprops[arguments.tablename]["fielddefaults"]>
	<cfelse>
		<cfset aFields = getFields(arguments.tablename)>
		<cfset sFields = StructNew()>
		<!--- Get fields with length and set key appropriately --->
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<cfif StructKeyExists(aFields[ii],"Default") AND Len(aFields[ii].Default)>
				<cfset sFields[aFields[ii].ColumnName] = aFields[ii].Default>
			<cfelse>
				<cfset sFields[aFields[ii].ColumnName] = "">
			</cfif>
		</cfloop>
		<cfset variables.tableprops[arguments.tablename]["fielddefaults"] = sFields>
	</cfif>
	
	<cfreturn sFields>
</cffunction>

<cffunction name="getDeletionConflicts" access="public" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table from which to delete a record.">
	<cfargument name="data" type="struct" required="yes" hint="A structure indicating the record to delete. A key indicates a field. The structure should have a key for each primary key in the table.">
	
	<cfset var rfields = getRelationFields(arguments.tablename)><!--- relation fields in table --->
	<cfset var ii = 0>
	<cfset var subdatum = 0>
	<cfset var sArgs = 0>
	<cfset var qRelationList = 0>
	<cfset var result = "">
	
	<cfif NOT StructKeyExists(arguments,"qRecord")>
		<cfset arguments.qRecord = getRecord(tablename=arguments.tablename,data=arguments.data)>
	</cfif>
	
	<cfloop index="ii" from="1" to="#ArrayLen(rfields)#" step="1">
		<cfif
				(
						StructKeyExists(rfields[ii].Relation,"onDelete")
					AND	rfields[ii].Relation["onDelete"] EQ "Error"
				)
			AND	(
						StructKeyExists(rfields[ii].Relation,"table")
					AND	NOT ListFindNoCase(result,rfields[ii].Relation["table"])
				)
			AND	(
						rfields[ii].Relation["type"] EQ "list"
					OR	ListFindNoCase(variables.aggregates,rfields[ii].Relation["type"])
				)
		>
			<cfset sArgs = StructNew()>
			<cfset subdatum = StructNew()>
			<cfset subdatum.data = StructNew()>
			<cfset subdatum.advsql = StructNew()>
			
			<cfif StructKeyExists(rfields[ii].Relation,"join-table")>
				<cfset subdatum.subadvsql = StructNew()>
				<cfset subdatum.subadvsql.WHERE = "#escape( rfields[ii].Relation['join-table'] & '.' & rfields[ii].Relation['join-table-field-remote'] )# = #escape( rfields[ii].Relation['table'] & '.' & rfields[ii].Relation['remote-table-join-field'] )#">
				<cfset subdatum.data[rfields[ii].Relation["local-table-join-field"]] = qRecord[rfields[ii].Relation["join-table-field-local"]][1]>
				<cfset subdatum.advsql.WHERE = ArrayNew(1)>
				<cfset ArrayAppend(subdatum.advsql.WHERE,"EXISTS (")>
				<cfset ArrayAppend(subdatum.advsql.WHERE,getRecordsSQL(tablename=rfields[ii].Relation["join-table"],data=subdatum.data,advsql=subdatum.subadvsql,isInExists=true))>
				<cfset ArrayAppend(subdatum.advsql.WHERE,")")>
			<cfelse>
				<cfset subdatum.data[rfields[ii].Relation["join-field-remote"]] = arguments.qRecord[rfields[ii].Relation["join-field-local"]][1]>
			</cfif>
			
			<cfset sArgs["tablename"] = rfields[ii].Relation["table"]>
			<cfset sArgs["data"] = subdatum.data>
			<cfset sArgs["fieldlist"] = rfields[ii].Relation["field"]>
			<cfset sArgs["advsql"] = subdatum.advsql>
			<cfif StructKeyExists(rfields[ii].Relation,"filters") AND isArray(rfields[ii].Relation.filters)>
				<cfset sArgs["filters"] = rfields[ii].Relation.filters>
			</cfif>
			
			<cfset qRelationList = getRecords(argumentCollection=sArgs)>
			
			<cfif qRelationList.RecordCount>
				<cfset result = ListAppend(result,rfields[ii].Relation.table)>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getIsDeletableSQL" access="public" returntype="array" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table from which to delete a record.">
	
	<cfset var rfields = getRelationFields(arguments.tablename)><!--- relation fields in table --->
	<cfset var ii = 0>
	<cfset var sArgs = 0>
	<cfset var aSQL = ArrayNew(1)>
	<cfset var tables = "">
	<cfset var hasNestedSQL = false>
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>
	
	<cfif StructKeyExists(arguments,"ignore")>
		<cfset tables = arguments.ignore>
	</cfif>
	
	<cfset ArrayAppend(
		aSQL,
		"
		(
			CASE
			WHEN (
					1 = 1
		"
	)>
	<cfloop index="ii" from="1" to="#ArrayLen(rfields)#" step="1">
		<cfif
				(
						StructKeyExists(rfields[ii].Relation,"table")
					AND	NOT ListFindNoCase(tables,rfields[ii].Relation["table"])
				)
			AND	(
						rfields[ii].Relation["type"] EQ "list"
					OR	ListFindNoCase(variables.aggregates,rfields[ii].Relation["type"])
				)
			AND	(
						StructKeyExists(rfields[ii].Relation,"onDelete")
					AND	(
								rfields[ii].Relation["onDelete"] EQ "Error"
							OR	rfields[ii].Relation["onDelete"] EQ "Cascade"
						)
				)
		>
			<cfset tables = ListAppend(tables,rfields[ii].Relation["table"])>
			<cfif rfields[ii].Relation["onDelete"] EQ "Error">
				<cfset sArgs = StructNew()>
				<cfset sArgs["tablename"] = rfields[ii].Relation["table"]>
				<cfset sArgs["tablealias"] = rfields[ii].Relation["table"]>
				<cfif sArgs["tablealias"] EQ arguments.tablealias>
					<cfset sArgs["tablealias"] = sArgs["tablealias"] & "_DataMgr_inner">
				</cfif>
				<cfset sArgs["isInExists"] = true>
				<cfset sArgs["fieldlist"] = rfields[ii].Relation["field"]>
				<cfif StructKeyExists(rfields[ii].Relation,"filters") AND isArray(rfields[ii].Relation.filters)>
					<cfset sArgs["filters"] = rfields[ii].Relation.filters>
				</cfif>
				<cfset sArgs["advsql"] = StructNew()>
				<cfset sArgs["advsql"]["WHERE"] = ArrayNew(1)>
				<cfif StructKeyExists(rfields[ii].Relation,"join-table")>
					<cfset sArgs["join"] = StructNew()>
					<cfset sArgs["join"]["table"] = rfields[ii].Relation["join-table"]>
					<cfset sArgs["join"]["type"] = "INNER">
					<cfset sArgs["join"]["onleft"] = rfields[ii].Relation["remote-table-join-field"]>
					<cfset sArgs["join"]["onright"] = rfields[ii].Relation["join-table-field-remote"]>
					<cfset ArrayAppend(sArgs["advsql"]["WHERE"],getFieldSelectSQL(tablename=rfields[ii].Relation["join-table"],field=rfields[ii].Relation["join-table-field-local"],tablealias=rfields[ii].Relation["join-table"],useFieldAlias=false))>
					<cfset ArrayAppend(sArgs["advsql"]["WHERE"]," = ")>
					<cfset ArrayAppend(sArgs["advsql"]["WHERE"],getFieldSelectSQL(tablename=arguments.tablename,field=rfields[ii].Relation['local-table-join-field'],tablealias=arguments.tablealias,useFieldAlias=false))>
				<cfelse>
					<cfset ArrayAppend(sArgs["advsql"]["WHERE"],getFieldSelectSQL(tablename=sArgs.tablename,field=rfields[ii].Relation['join-field-remote'],tablealias=sArgs.tablealias,useFieldAlias=false))>
					<cfset ArrayAppend(sArgs["advsql"]["WHERE"]," = ")>
					<cfset ArrayAppend(sArgs["advsql"]["WHERE"],getFieldSelectSQL(tablename=arguments.tablename,field=rfields[ii].Relation['join-field-local'],tablealias=arguments.tablealias,useFieldAlias=false))>
				</cfif>
				
				<cfset ArrayAppend(aSQL,"AND	NOT EXISTS (")>
					<cfset ArrayAppend(aSQL,getRecordsSQL(argumentCollection=sArgs))>
				<cfset ArrayAppend(aSQL,")")>
			<cfelse>
				<cfset sArgs = StructNew()>
				<cfset sArgs["tablename"] = rfields[ii].Relation["table"]>
				<cfset sArgs["tablealias"] = sArgs["tablename"]>
				<cfif sArgs["tablealias"] EQ arguments.tablealias>
					<cfset sArgs["tablealias"] = sArgs["tablealias"] & "_DataMgr_inner">
				</cfif>
				<cfset sArgs["ignore"] = arguments.tablename>
				<cfset ArrayAppend(aSQL,"
					AND	(
							NOT EXISTS (
								SELECT	1
								FROM	#escape(rfields[ii].Relation['table'])#
								WHERE	1 = 1
									AND	(
												1 = 0
											OR	(
				")>
				<cfset ArrayAppend(aSQL,getIsDeletableSQL(argumentCollection=sArgs))>
				<cfset ArrayAppend(aSQL,"
												) = 0
										)
							)
						)
				")>
			</cfif>
			<cfset hasNestedSQL = true>
		</cfif>
	</cfloop>
	<cfset ArrayAppend(
		aSQL,
		"
			)
			THEN #getBooleanSqlValue(true)#
			ELSE #getBooleanSqlValue(false)#
			END
		)
		"
	)>
	
	<cfif NOT hasNestedSQL>
		<cfset aSQL = ArrayNew(1)>
		<cfset ArrayAppend(aSQL,getBooleanSqlValue(true))>
	</cfif>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="getFieldList" access="public" returntype="string" output="no" hint="I get a list of fields in DataMgr for the given table.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var i = 0>
	<cfset var fieldlist = "">
	<cfset var bTable = checkTable(arguments.tablename)>
	
	<cfif StructKeyExists(variables.tableprops,arguments.tablename) AND StructKeyExists(variables.tableprops[arguments.tablename],"fieldlist")>
		<cfset fieldlist = variables.tableprops[arguments.tablename]["fieldlist"]>
	<cfelse>
		<!--- Loop over the fields in the table and make a list of them --->
		<cfif StructKeyExists(variables.tables,arguments.tablename)>
			<cfloop index="i" from="1" to="#ArrayLen(variables.tables[arguments.tablename])#" step="1">
				<cfset fieldlist = ListAppend(fieldlist, variables.tables[arguments.tablename][i].ColumnName)>
			</cfloop>
		</cfif>
		<cfset variables.tableprops[arguments.tablename]["fieldlist"] = fieldlist>
	</cfif>
	
	<cfreturn fieldlist>
</cffunction>

<cffunction name="getFieldLengths" access="public" returntype="struct" output="no" hint="I return a structure of the field lengths for fields where this is relevant.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var sFields = 0>
	<cfset var aFields = 0>
	<cfset var ii = 0>
	
	<!--- If fields data if stored --->
	<cfif StructKeyExists(variables.tableprops,arguments.tablename) AND StructKeyExists(variables.tableprops[arguments.tablename],"fieldlengths")>
		<cfset sFields = variables.tableprops[arguments.tablename]["fieldlengths"]>
	<cfelse>
		<cfset aFields = getFields(arguments.tablename)>
		<cfset sFields = StructNew()>
		<!--- Get fields with length and set key appropriately --->
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<cfif
					StructKeyExists(aFields[ii],"Length")
				AND	isNumeric(aFields[ii].Length)
				AND	aFields[ii].Length GT 0
				AND	FindNoCase("char",aFields[ii].CF_DataType)
				AND NOT FindNoCase("long",aFields[ii].CF_DataType)
			>
				<cfset sFields[aFields[ii].ColumnName] = aFields[ii].Length>
			</cfif>
		</cfloop>
		<cfset variables.tableprops[arguments.tablename]["fieldlengths"] = sFields>
	</cfif>
	
	<cfreturn sFields>
</cffunction>

<cffunction name="getFields" access="public" returntype="array" output="no" hint="I return an array of all real fields in the given table in DataMgr.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var ii = 0><!--- counter --->
	<cfset var arrFields = ArrayNew(1)><!--- array of fields --->
	<cfset var bTable = checkTable(arguments.tablename)><!--- Check whether table is loaded --->
	
	<!--- If fields data if stored --->
	<cfif StructKeyExists(variables.tableprops,arguments.tablename) AND StructKeyExists(variables.tableprops[arguments.tablename],"fields")>
		<cfset arrFields = variables.tableprops[arguments.tablename]["fields"]>
	<cfelse>
		<!--- Loop over the fields and make an array of them --->
		<cfloop index="ii" from="1" to="#ArrayLen(variables.tables[arguments.tablename])#" step="1">
			<cfif StructKeyExists(variables.tables[arguments.tablename][ii],"CF_DataType") AND NOT StructKeyExists(variables.tables[arguments.tablename][ii],"Relation")>
				<cfset ArrayAppend(arrFields, variables.tables[arguments.tablename][ii])>
			</cfif>
		</cfloop>
		<cfset variables.tableprops[arguments.tablename]["fields"] = arrFields>
	</cfif>
	
	<cfreturn arrFields>
</cffunction>

<cffunction name="getMaxRowsPrefix" access="public" returntype="string" output="no" hint="I get the SQL before the field list in the select statement to limit the number of rows.">
	<cfargument name="maxrows" type="numeric" required="yes">
	<cfargument name="offset" type="numeric" default="0">
	
	<cfreturn "TOP #arguments.maxrows+arguments.offset# ">
</cffunction>

<cffunction name="getMaxRowsSuffix" access="public" returntype="string" output="no" hint="I get the SQL after the query to limit the number of rows.">
	<cfargument name="maxrows" type="numeric" required="yes">
	<cfargument name="offset" type="numeric" default="0">
	
	<cfreturn "">
</cffunction>

<cffunction name="getMaxRowsWhere" access="public" returntype="string" output="no" hint="I get the SQL in the where statement to limit the number of rows.">
	<cfargument name="maxrows" type="numeric" required="yes">
	<cfargument name="offset" type="numeric" default="0">
	
	<cfreturn "1 = 1">
</cffunction>

<cffunction name="getNewSortNum" access="public" returntype="numeric" output="no" hint="I get the value an increment higher than the highest value in the given field to put a record at the end of the sort order.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="sortfield" type="string" required="yes" hint="The field holding the sort order.">
	
	<cfset var qLast = 0>
	<cfset var result = 0>
	
	<cfset qLast = runSQL("SELECT Max(#escape(arguments.sortfield)#) AS #escape(arguments.sortfield)# FROM #escape(arguments.tablename)#")>
	
	<cfif qLast.RecordCount and isNumeric(qLast[arguments.sortfield][1])>
		<cfset result = qLast[arguments.sortfield][1] + 1>
	<cfelse>
		<cfset result = 1>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getPKFields" access="public" returntype="array" output="no" hint="I return an array of primary key fields.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var bTable = checkTable(arguments.tablename)><!--- Check whether table is loaded --->
	<cfset var ii = 0><!--- counter --->
	<cfset var arrFields = ArrayNew(1)><!--- array of primarykey fields --->
	
	<!--- If pkfields data if stored --->
	<cfif StructKeyExists(variables.tableprops,arguments.tablename) AND StructKeyExists(variables.tableprops[arguments.tablename],"pkfields")>
		<cfset arrFields = variables.tableprops[arguments.tablename]["pkfields"]>
	<cfelse>
		<cfloop index="ii" from="1" to="#ArrayLen(variables.tables[arguments.tablename])#" step="1">
			<cfif StructKeyExists(variables.tables[arguments.tablename][ii],"PrimaryKey") AND variables.tables[arguments.tablename][ii].PrimaryKey>
				<cfset ArrayAppend(arrFields, variables.tables[arguments.tablename][ii])>
			</cfif>
		</cfloop>
		<cfset variables.tableprops[arguments.tablename]["pkfields"] = arrFields>
	</cfif>
	
	<cfreturn arrFields>
</cffunction>

<cffunction name="getPrimaryKeyField" access="public" returntype="struct" output="no" hint="I return primary key field for this table.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a primary key.">
	
	<cfset var aPKFields = getPKFields(arguments.tablename)>
	
	<cfif ArrayLen(aPKFields) NEQ 1>
		<cfset throwDMError("The #arguments.tablename# does not have a simple primary key and so it cannot be used for this purpose.","NoSimplePrimaryKey")>
	</cfif>
	
	<cfreturn aPKFields[1]>
</cffunction>

<cffunction name="getPrimaryKeyFieldName" access="public" returntype="string" output="no" hint="I return primary key field for this table.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a primary key.">
	
	<cfset var sField = getPrimaryKeyField(arguments.tablename)>
	
	<cfreturn sField.ColumnName>
</cffunction>

<cffunction name="getPrimaryKeyFieldNames" access="public" returntype="string" output="no" hint="I return a list of primary key field for this table.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a primary key.">
	
	<cfset var pkfields = getPKFields(arguments.tablename)><!--- the primary key fields for this table --->
	<cfset var result = "">
	<cfset var ii = 0>
	
	<!--- Make list of primary key fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfset result = ListAppend(result,pkfields[ii].ColumnName)>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getPKFromData" access="public" returntype="string" output="no" hint="I get the primary key of the record matching the given data.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a primary key.">
	<cfargument name="fielddata" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	
	<cfset var qPK = 0><!--- The query used to get the primary key --->
	<cfset var fields = getUpdateableFields(arguments.tablename)><!--- The (non-primarykey) fields for this table --->
	<cfset var pkfields = getPKFields(arguments.tablename)><!--- The primary key field(s) for this table --->
	<cfset var result = 0><!--- The result of this method --->
	
	<!--- This method is only to be used on fields with one pkfield --->
	<cfif ArrayLen(pkfields) NEQ 1>
		<cfset throwDMError("This method can only be used on tables with exactly one primary key field.","NeedOnePKField")>
	</cfif>
	<!--- This method can only be used on tables with updateable fields --->
	<cfif NOT ArrayLen(fields)>
		<cfset throwDMError("This method can only be used on tables with updateable fields.","NeedUpdateableField")>
	</cfif>
	
	<!--- Run query to get primary key value from data fields --->
	<cfset qPK = getRecords(tablename=arguments.tablename,data=arguments.fielddata,fieldlist=pkfields[1].ColumnName)>
	
	<cfif qPK.RecordCount EQ 1>
		<cfset result = qPK[pkfields[1].ColumnName][1]>
	<cfelse>
		<cfset throwDMError("Data Manager: A unique record could not be identified from the given data.","NoUniqueRecord")>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getRecord" access="public" returntype="query" output="no" hint="I get a recordset based on the primary key value(s) given.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key. Every primary key field should be included.">
	<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
	
	<cfset var ii = 0><!--- A generic counter --->
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var fields = getUpdateableFields(arguments.tablename)>
	<cfset var in = arguments.data>
	<cfset var totalfields = 0><!--- count of fields --->
	<cfset var DataString = "">
	
	<!--- Figure count of fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif StructKeyExists(in,pkfields[ii].ColumnName) AND isOfType(in[pkfields[ii].ColumnName],pkfields[ii].CF_DataType)>
			<cfset totalfields = totalfields + 1>
		</cfif>
	</cfloop>
	<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif StructKeyExists(in,fields[ii].ColumnName) AND isOfType(in[fields[ii].ColumnName],fields[ii].CF_DataType)>
			<cfset totalfields = totalfields + 1>
		</cfif>
	</cfloop>
	
	<!--- Make sure at least one field is passed in --->
	<cfif totalfields EQ 0>
		<cfloop collection="#arguments.data#" item="ii">
			<cfif isSimpleValue(arguments.data[ii])>
				<cfset DataString = ListAppend(DataString,"#ii#=#arguments.data[ii]#",";")>
			<cfelse>
				<cfset DataString = ListAppend(DataString,"#ii#=(complex)",";")>
			</cfif>
		</cfloop>
		<cfset throwDMError("The data argument of getRecord must contain at least one field from the #arguments.tablename# table. To get all records, use the getRecords method.","NeedWhereFields","(data passed in: #DataString#)")>
	</cfif>
	
	<cfreturn getRecords(tablename=arguments.tablename,data=in,fieldlist=arguments.fieldlist,maxrows=1)>
</cffunction>

<cffunction name="getRecords" access="public" returntype="query" output="no" hint="I get a recordset based on the data given.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="any" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="orderBy" type="string" default="">
	<cfargument name="maxrows" type="numeric" required="no">
	<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
	<cfargument name="advsql" type="struct" hint="A structure of sqlarrays for each area of a query (SELECT,FROM,WHERE,ORDER BY).">
	<cfargument name="filters" type="array">
	<cfargument name="offset" type="numeric" default="0">
	<cfargument name="function" type="string" default="" hint="A function to run against the results.">
	<cfargument name="FunctionAlias" type="string" required="false" hint="An alias for the column returned by a function (only if function argument is used).">
	
	<cfset var qRecords = 0><!--- The recordset to return --->
	
	<!--- Get records --->
	<cfinvoke returnvariable="qRecords" method="runSQLArray">
		<cfinvokeargument name="sqlarray" value="#getRecordsSQL(argumentCollection=arguments)#">
		<!--- We'll pass maxrows, but it will only be used for databases that don't support this in SQL (currently just Derby) --->
		<cfif StructKeyExists(arguments,"maxrows")>
			<cfinvokeargument name="maxrows" value="#arguments.maxrows#">
		</cfif>
		<cfif arguments.offset GT 0>
			<cfinvokeargument name="offset" value="#arguments.offset#">
		</cfif>
	</cfinvoke>
	
	<cfset qRecords = applyListRelations(arguments.tablename,qRecords)>
	
	<!--- Manage offset --->
	<cfif arguments.offset GT 0 AND NOT dbHasOffset()>
		<cfif arguments.offset GTE qRecords.RecordCount>
			<cfset qRecords = QueryNew(qRecords.ColumnList)>
		<cfelse>
			<cfset qRecords = QuerySliceAndDice(qRecords,arguments.offset+1,qRecords.RecordCount)>
		</cfif>
	</cfif>
	
	<cfreturn qRecords>
</cffunction>

<cffunction name="getRecordsSQL" access="public" returntype="array" output="no" hint="I get the SQL to get a recordset based on the data given.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="any" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="orderBy" type="string" default="">
	<cfargument name="maxrows" type="numeric" default="0">
	<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
	<cfargument name="function" type="string" default="" hint="A function to run against the results.">
	<cfargument name="advsql" type="struct" hint="A structure of sqlarrays for each area of a query (SELECT,FROM,WHERE,ORDER BY).">
	<cfargument name="filters" type="array">
	<cfargument name="offset" type="numeric" default="0">
	<cfargument name="FunctionAlias" type="string" required="false" hint="An alias for the column returned by a function (only if function argument is used).">
	
	<cfset var sqlarray = ArrayNew(1)>
	<cfset var aOrderBySQL = 0>
	
	<cfset arguments.fieldlist = Trim(arguments.fieldlist)>
	
	<cfif NOT ( StructKeyExists(arguments,"isInExists") AND isBoolean(arguments.isInExists) )>
		<cfset arguments.isInExists = false>
	</cfif>
	<cfif arguments.isInExists OR ( Len(arguments.function) AND NOT Len(arguments.fieldlist) )>
		<cfset arguments.noorder = true>
	</cfif>
	<cfif NOT ( StructKeyExists(arguments,"noorder") AND isBoolean(arguments.noorder) )>
		<cfset arguments.noorder = false>
	</cfif>
	<cfif NOT arguments.noorder>
		<cfset aOrderBySQL = getOrderBySQL(argumentCollection=arguments)>
	</cfif>
	
	<!--- Get Records --->
	<cfset ArrayAppend(sqlarray,"SELECT")>
	<cfif arguments.isInExists IS true>
		<cfset ArrayAppend(sqlarray," 1")>
	<cfelse>
	
		<cfset ArrayAppend(sqlarray,This.getSelectSQL(argumentCollection=arguments))>
	</cfif>
	<cfset ArrayAppend(sqlarray,"FROM")>
	<cfset ArrayAppend(sqlarray,getFromSQL(argumentCollection=arguments))>
	<cfif arguments.maxrows GT 0>
		<cfset ArrayAppend(sqlarray,"WHERE		#getMaxRowsWhere(arguments.maxrows,arguments.offset)#")>
	<cfelse>
		<cfset ArrayAppend(sqlarray,"WHERE		1 = 1")>
	</cfif>
	<cfset ArrayAppend(sqlarray,getWhereSQL(argumentCollection=arguments))>
	<cfif StructKeyExists(arguments,"advsql") AND StructKeyExists(arguments.advsql,"GROUP BY")>
		<cfset ArrayAppend(sqlarray,"GROUP BY ")>
		<cfset ArrayAppend(sqlarray,arguments.advsql["GROUP BY"])>
	</cfif>
	<cfif StructKeyExists(arguments,"advsql") AND StructKeyExists(arguments.advsql,"HAVING")>
		<cfset ArrayAppend(sqlarray,"HAVING ")>
		<cfset ArrayAppend(sqlarray,arguments.advsql["HAVING"])>
	</cfif>
	<cfif (NOT arguments.noorder) AND ArrayLen(aOrderBySQL)>
		<cfset ArrayAppend(sqlarray,"ORDER BY ")>
		<cfset ArrayAppend(sqlarray,aOrderBySQL)>
	</cfif>
	<cfif arguments.maxrows GT 0 OR arguments.offset GT 0>
		<cfset ArrayAppend(sqlarray,"#getMaxRowsSuffix(arguments.maxrows,arguments.offset)#")>
	</cfif>
	
	<cfreturn sqlarray>
</cffunction>

<cffunction name="getFromSQL" access="public" returntype="array" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="any" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="orderBy" type="string" default="">
	<cfargument name="maxrows" type="numeric" default="0">
	<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
	<cfargument name="function" type="string" default="" hint="A function to run against the results.">
	<cfargument name="advsql" type="struct" hint="A structure of sqlarrays for each area of a query (SELECT,FROM,WHERE,ORDER BY).">
	
	<cfset var sqlarray = ArrayNew(1)>
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>
	
	<cfset ArrayAppend(sqlarray,"#escape(arguments.tablename)#")>
	<cfif arguments.tablealias NEQ arguments.tablename>
		<cfset ArrayAppend(sqlarray," #escape(arguments.tablealias)#")>
	</cfif>
	<cfif StructKeyExists(arguments,"advsql") AND StructKeyExists(arguments.advsql,"FROM")>
		<cfset ArrayAppend(sqlarray,arguments.advsql["FROM"])>
	</cfif>
	<cfif StructKeyExists(arguments,"join") AND StructKeyExists(arguments.join,"table")>
		<cfif StructKeyExists(arguments.join,"type") AND ListFindNoCase("inner,left,right", arguments.join.type)>
			<cfset ArrayAppend(sqlarray,"#UCase(arguments.join.type)# JOIN #escape(arguments.join.table)#")>
		<cfelse>
			<cfset ArrayAppend(sqlarray,"INNER JOIN #escape(arguments.join.table)#")>
		</cfif>
		<cfset ArrayAppend(sqlarray,"	ON		#escape( arguments.tablealias & '.' & arguments.join.onleft )# = #escape( arguments.join.table & '.' & arguments.join.onright )#")>
	</cfif>
	
	<cfreturn sqlarray>
</cffunction>

<cffunction name="getRelationTypes" access="public" returntype="struct" output="no">
	
	<cfset var sTypes = StructNew()>
	
	<cfset sTypes["label"] = StructNew()><cfset sTypes["label"]["atts_req"] = "table,field,join-field-local,join-field-remote"><cfset sTypes["label"]["atts_opt"] = ""><cfset sTypes["label"]["gentypes"] = ""><cfset sTypes["label"]["cfsqltype"] = "CF_SQL_VARCHAR">
	<cfset sTypes["concat"] = StructNew()><cfset sTypes["concat"]["atts_req"] = "fields"><cfset sTypes["concat"]["atts_opt"] = "delimiter"><cfset sTypes["concat"]["gentypes"] = ""><cfset sTypes["concat"]["cfsqltype"] = "CF_SQL_VARCHAR">
	<cfset sTypes["list"] = StructNew()><cfset sTypes["list"]["atts_req"] = "table,field"><cfset sTypes["list"]["atts_opt"] = "join-field-local,join-field-remote,delimiter,sort-field,bidirectional,join-table"><cfset sTypes["list"]["gentypes"] = ""><cfset sTypes["list"]["cfsqltype"] = "">
	<cfset sTypes["avg"] = StructNew()><cfset sTypes["avg"]["atts_req"] = "table,field,join-field-local,join-field-remote"><cfset sTypes["avg"]["atts_opt"] = ""><cfset sTypes["avg"]["gentypes"] = "numeric"><cfset sTypes["avg"]["cfsqltype"] = "CF_SQL_FLOAT">
	<cfset sTypes["count"] = StructNew()><cfset sTypes["count"]["atts_req"] = "table,field,join-field-local,join-field-remote"><cfset sTypes["count"]["atts_opt"] = ""><cfset sTypes["count"]["gentypes"] = ""><cfset sTypes["count"]["cfsqltype"] = "CF_SQL_BIGINT">
	<cfset sTypes["max"] = StructNew()><cfset sTypes["max"]["atts_req"] = "table,field,join-field-local,join-field-remote"><cfset sTypes["max"]["atts_opt"] = ""><cfset sTypes["max"]["gentypes"] = "numeric,boolean,date"><cfset sTypes["max"]["cfsqltype"] = "CF_SQL_FLOAT">
	<cfset sTypes["min"] = StructNew()><cfset sTypes["min"]["atts_req"] = "table,field,join-field-local,join-field-remote"><cfset sTypes["min"]["atts_opt"] = ""><cfset sTypes["min"]["gentypes"] = "numeric,boolean,date"><cfset sTypes["min"]["cfsqltype"] = "CF_SQL_FLOAT">
	<cfset sTypes["sum"] = StructNew()><cfset sTypes["sum"]["atts_req"] = "table,field,join-field-local,join-field-remote"><cfset sTypes["sum"]["atts_opt"] = ""><cfset sTypes["sum"]["gentypes"] = "numeric,boolean"><cfset sTypes["sum"]["cfsqltype"] = "CF_SQL_FLOAT">
	<cfset sTypes["has"] = StructNew()><cfset sTypes["has"]["atts_req"] = "field"><cfset sTypes["has"]["atts_opt"] = ""><cfset sTypes["has"]["gentypes"] = ""><cfset sTypes["has"]["cfsqltype"] = "CF_SQL_BIT">
	<cfset sTypes["hasnot"] = StructNew()><cfset sTypes["hasnot"]["atts_req"] = "field"><cfset sTypes["hasnot"]["atts_opt"] = ""><cfset sTypes["hasnot"]["gentypes"] = ""><cfset sTypes["hasnot"]["cfsqltype"] = "CF_SQL_BIT">
	<cfset sTypes["math"] = StructNew()><cfset sTypes["math"]["atts_req"] = "field1,field2,operator"><cfset sTypes["math"]["atts_opt"] = ""><cfset sTypes["math"]["gentypes"] = "numeric"><cfset sTypes["math"]["cfsqltype"] = "CF_SQL_FLOAT">
	<cfset sTypes["now"] = StructNew()><cfset sTypes["now"]["atts_req"] = ""><cfset sTypes["now"]["atts_opt"] = ""><cfset sTypes["now"]["gentypes"] = ""><cfset sTypes["now"]["cfsqltype"] = "CF_SQL_DATE">
	<cfset sTypes["custom"] = StructNew()><cfset sTypes["custom"]["atts_req"] = ""><cfset sTypes["custom"]["atts_opt"] = "sql,CF_Datatype"><cfset sTypes["custom"]["gentypes"] = ""><cfset sTypes["custom"]["cfsqltype"] = "">
	
	<cfreturn sTypes>
</cffunction>

<cffunction name="getOrderBySQL" access="public" returntype="array" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="any" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="orderBy" type="string" default="">
	<cfargument name="maxrows" type="numeric" default="0">
	<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
	<cfargument name="function" type="string" default="" hint="A function to run against the results.">
	<cfargument name="advsql" type="struct" default="#StructNew()#" hint="A structure of sqlarrays for each area of a query (SELECT,FROM,WHERE,ORDER BY).">
	
	<cfset var aResults = ArrayNew(1)>
	<cfset var fields = getUpdateableFields(arguments.tablename)><!--- non primary-key fields in table --->
	<cfset var pkfields = getPKFields(arguments.tablename)><!--- primary key fields in table --->
	<cfset var ii = 0>
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>
	
	<cfif StructKeyExists(arguments,"noorder") AND arguments.noorder EQ true>
		<cfset aResults = ArrayNew(1)>
	<cfelseif StructKeyExists(arguments.advsql,"ORDER BY")>
		<cfset aResults = arguments.advsql["ORDER BY"]>
	<cfelse>
		<!--- Check for Sorter --->
		<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
			<cfif StructKeyExists(fields[ii],"Special") AND fields[ii].Special EQ "Sorter">
				<cfif
						( NOT Len(arguments.function) AND NOT ( StructKeyExists(arguments,"Distinct") AND arguments.Distinct IS true ) )
					OR	(
								Len(arguments.fieldlist) EQ 0
							OR	ListFindNoCase(arguments.fieldlist, fields[ii].ColumnName)
						)
				>
					<!--- Load field in sort order, if not there already --->
					<cfif NOT (
								ListFindNoCase(arguments.orderBy,fields[ii].ColumnName)
							OR	ListFindNoCase(arguments.orderBy,escape(fields[ii].ColumnName))
							OR	ListFindNoCase(arguments.orderBy,"#fields[ii].ColumnName# DESC")
							OR	ListFindNoCase(arguments.orderBy,"#escape(fields[ii].ColumnName)# DESC")
							OR	ListFindNoCase(arguments.orderBy,"#fields[ii].ColumnName# ASC")
							OR	ListFindNoCase(arguments.orderBy,"#escape(fields[ii].ColumnName)# ASC")
							OR	ListFindNoCase(arguments.orderBy,"#escape(arguments.tablealias & '.' & fields[ii].ColumnName)#")
						)
					>
						<cfset arguments.orderBy = ListAppend(arguments.orderBy,"#escape(arguments.tablealias & '.' & fields[ii].ColumnName)#")>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<!--- Continue with conditionals --->
		<cfif Len(arguments.orderBy)>
			<cfset aResults = getOrderByArray(arguments.tablename,arguments.orderby,arguments.tablealias)>
		<!--- ** USE AT YOUR OWN RISK! **: This is highly experimental and not supported on all database --->
		<cfelseif
				StructKeyExists(arguments,"sortfield")
			AND	(
						( NOT Len(arguments.function) AND NOT ( StructKeyExists(arguments,"Distinct") AND arguments.Distinct IS true ) )
					OR	(
								Len(arguments.fieldlist) EQ 0
							OR	ListFindNoCase(arguments.fieldlist, arguments.sortfield)
						)
				)
		>
			<cfset ArrayAppend(aResults,getFieldSelectSQL(tablename=arguments.tablename,field=arguments.sortfield,tablealias=arguments.tablealias,useFieldAlias=false))>
			<cfif StructKeyExists(arguments,"sortdir") AND (arguments.sortdir EQ "ASC" OR arguments.sortdir EQ "DESC")>
				<cfset ArrayAppend(aResults," #arguments.sortdir#")>
			</cfif>
			<!--- Fixing a bug in MS Access --->
			<cfif getDatabase() EQ "Access" AND arguments.sortfield NEQ pkfields[1].ColumnName>
				<cfset ArrayAppend(aResults,",")>
				<cfset ArrayAppend(aResults,getFieldSelectSQL(tablename=arguments.tablename,field=pkfields[1].ColumnName,tablealias=arguments.tablealias,useFieldAlias=false))>
			</cfif>
		<cfelseif arguments.maxrows GT 0>
			<cfset aResults = getDefaultOrderBySQL(argumentCollection=arguments)>
		</cfif>
	</cfif>
	
	<cfreturn aResults>
</cffunction>

<cffunction name="getSelectSQL" access="public" returntype="array" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="any" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="orderBy" type="string" default="">
	<cfargument name="maxrows" type="numeric" default="0">
	<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
	<cfargument name="function" type="string" default="" hint="A function to run against the results.">
	<cfargument name="advsql" type="struct" hint="A structure of sqlarrays for each area of a query (SELECT,FROM,WHERE,ORDER BY).">
	<cfargument name="filters" type="array">
	<cfargument name="offset" type="numeric" default="0">
	<cfargument name="FunctionAlias" type="string" required="false" hint="An alias for the column returned by a function (only if function argument is used).">
	
	<cfset var bTable = checkTable(arguments.tablename)><!--- Check whether table is loaded --->
	<cfset var sqlarray = ArrayNew(1)>
	<cfset var adjustedfieldlist = "">
	<cfset var numcols = 0>
	<cfset var ii = 0>
	<cfset var aFields = variables.tables[arguments.tablename]>
	<cfset var temp = "">
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>
	
	<cfif NOT StructKeyExists(arguments,"FunctionAlias")>
		<cfset arguments.FunctionAlias = "DataMgr_FunctionResult">
	</cfif>
	
	<cfif Len(arguments.fieldlist)>
		<cfloop list="#arguments.fieldlist#" index="temp">
			<cfset adjustedfieldlist = ListAppend(adjustedfieldlist,escape(arguments.tablealias & '.' & temp))>
		</cfloop>
	</cfif>
	
	<cfif arguments.maxrows GT 0>
		<cfset ArrayAppend(sqlarray,getMaxRowsPrefix(arguments.maxrows,arguments.offset))>
	</cfif>
	<cfif StructKeyExists(arguments,"distinct") AND arguments.distinct EQ "true">
		<cfset ArrayAppend(sqlarray,"DISTINCT")>
	</cfif>
	<cfif Len(arguments.function)>
		<cfif Len(arguments.fieldlist)>
			<cfset ArrayAppend(sqlarray,"#arguments.function#(#adjustedfieldlist#) AS #arguments.FunctionAlias#")>
		<cfelse>
			<cfset ArrayAppend(sqlarray,"#arguments.function#(*) AS #arguments.FunctionAlias#")>
		</cfif>
		<cfset numcols = numcols + 1>
	<cfelse>
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<cfif isFieldInSelect(aFields[ii],arguments.fieldlist,arguments.maxrows)>
				<cfif numcols GT 0><cfset ArrayAppend(sqlarray,",")></cfif>
				<cfset numcols = numcols + 1>
				<cfset ArrayAppend(sqlarray,getFieldSelectSQL(arguments.tablename,aFields[ii]["ColumnName"],arguments.tablealias))>
			</cfif>
		</cfloop>
		<cfif
				( StructKeyExists(variables.tableprops[arguments.tablename],"deletable") AND Len(variables.tableprops[arguments.tablename].deletable) )
			AND	NOT ListFindNoCase(getFieldList(arguments.tablename),variables.tableprops[arguments.tablename].deletable)
			AND	(
						Len(arguments.fieldlist) EQ 0
					OR	ListFindNoCase(arguments.fieldlist,variables.tableprops[arguments.tablename].deletable)
				)
		>
			<cfif numcols GT 0><cfset ArrayAppend(sqlarray,",")></cfif>
			<cfset numcols = numcols + 1>
			<cfset ArrayAppend(sqlarray,getIsDeletableSQL(tablename=arguments.tablename,tablealias=arguments.tablealias))>
			<cfset ArrayAppend(sqlarray," AS ")>
			<cfset ArrayAppend(sqlarray,escape(variables.tableprops[arguments.tablename].deletable))>
		</cfif>
	</cfif>
	<cfif StructKeyExists(arguments,"advsql") AND StructKeyExists(arguments.advsql,"SELECT")>
		<cfset ArrayAppend(sqlarray,",")><cfset numcols = numcols + 1>
		<cfset ArrayAppend(sqlarray,arguments.advsql["SELECT"])>
	</cfif>
	
	<!--- Make sure at least one field is retrieved --->
	<cfif numcols EQ 0>
		<cfset throwDMError("At least one valid field must be retrieved from the #arguments.tablename# table (actual fields in table are: #getDBFieldList(arguments.tablename)#) (requested fields: #arguments.fieldlist#).","NeedSelectFields")>
	</cfif>
	
	<cfreturn sqlarray>
</cffunction>

<cffunction name="getWhereSQL" access="public" returntype="array" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="any" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="advsql" type="struct" hint="A structure of sqlarrays for each area of a query (SELECT,FROM,WHERE,ORDER BY).">
	<cfargument name="filters" type="array">
	
	<cfset var fields = getUpdateableFields(arguments.tablename)><!--- non primary-key fields in table --->
	<cfset var in = 0><!--- holder for incoming data (just for readability) --->
	<cfset var pkfields = getPKFields(arguments.tablename)><!--- primary key fields in table --->
	<cfset var rfields = getRelationFields(arguments.tablename)><!--- relation fields in table --->
	<cfset var ii = 0><!--- Generic counter --->
	<cfset var sqlarray = ArrayNew(1)>
	<cfset var sArgs = 0>
	<cfset var temp = "">
	<cfset var joiner = "AND">
	
	<!--- Convert data argument to "in" struct --->
	<cfif StructKeyExists(arguments,"data")>
		<cfif isStruct(arguments.data)>
			<cfset in = arguments.data>
		<cfelseif isSimpleValue(arguments.data)>
			<cfif ArrayLen(pkfields) EQ 1>
				<cfset in = StructNew()>
				<cfset in[pkfields[1].ColumnName] = arguments.data>
			<cfelse>
				<cfset throwDMError("Data argument can only be a string for tables with simple (single column) primary keys.")>
			</cfif>
		<cfelse>
			<cfset throwDMError("Data argument must be either a struct or a string.")>
		</cfif>
	<cfelse>
		<cfset in = StructNew()>
	</cfif>
	
	<cfif NOT StructKeyExists(arguments,"filters")>
		<cfset arguments.filters = ArrayNew(1)>
	</cfif>
	<!--- Named Filters --->
	<cfif StructCount(variables.tableprops[arguments.tablename]["filters"])>
		<cfloop collection="#variables.tableprops[arguments.tablename].filters#" item="ii">
			<cfif StructKeyExists(in,ii)>
				<cfset ArrayAppend(arguments.filters,StructCopy(variables.tableprops[arguments.tablename].filters[ii]))>
				<cfset arguments.filters[ArrayLen(arguments.filters)].value = in[ii]>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>

	<!--- filter by primary keys --->
	<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif StructKeyExists(in,pkfields[ii].ColumnName) AND isOfType(in[pkfields[ii].ColumnName],pkfields[ii].CF_DataType)>
			<cfset ArrayAppend(sqlarray,"#joiner#		#escape(arguments.tablealias & '.' & pkfields[ii].ColumnName)# = ")>
			<cfset ArrayAppend(sqlarray,sval(pkfields[ii],in))>
		</cfif>
	</cfloop>
	<!--- filter by updateable fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif NOT ListFindNoCase(variables.nocomparetypes,fields[ii].CF_DataType)>
			<cfif useField(in,fields[ii]) OR ( StructKeyExists(in,fields[ii].ColumnName) AND NOT Len(in[fields[ii].ColumnName]) )>
				<!---<cfset ArrayAppend(sqlarray,"AND		#escape(arguments.tablealias & '.' & fields[ii].ColumnName)# = ")>
				<cfset ArrayAppend(sqlarray,sval(fields[ii],in))>--->
				<cfset ArrayAppend(sqlarray,joiner)>
				<cfset ArrayAppend(sqlarray,getFieldWhereSQL(tablename=arguments.tablename,field=fields[ii].ColumnName,value=in[fields[ii].ColumnName],tablealias=arguments.tablealias))>
			<cfelseif StructKeyExists(in,fields[ii].ColumnName) AND NOT Len(Trim(in[fields[ii].ColumnName]))>
				<cfset ArrayAppend(sqlarray,"#joiner#		#escape(arguments.tablealias & '.' & fields[ii].ColumnName)# IS NULL")>
			<cfelseif StructKeyExists(fields[ii],"Special") AND fields[ii].Special EQ "DeletionMark">
				<!--- Make sure not to get records that have been logically deleted --->
				<cfif fields[ii].CF_DataType EQ "CF_SQL_BIT">
					<cfset ArrayAppend(sqlarray,"#joiner#		(#escape(arguments.tablealias & '.' & fields[ii].ColumnName)# = #getBooleanSqlValue(0)# OR #escape(arguments.tablealias & '.' & fields[ii].ColumnName)# IS NULL)")>
				<cfelseif fields[ii].CF_DataType EQ "CF_SQL_DATE" OR fields[ii].CF_DataType EQ "CF_SQL_DATETIME">
					<cfset ArrayAppend(sqlarray,"#joiner#		(#escape(arguments.tablealias & '.' & fields[ii].ColumnName)# = 0 OR #escape(arguments.tablealias & '.' & fields[ii].ColumnName)# IS NULL )")>
				</cfif>
			</cfif>
		</cfif>
	</cfloop>
	<!--- Filter by relations --->
	<cfloop index="ii" from="1" to="#ArrayLen(rfields)#" step="1">
		<cfif useField(in,rfields[ii]) OR ( StructKeyExists(in,rfields[ii].ColumnName) AND NOT Len(in[rfields[ii].ColumnName]) )>
			<cfset ArrayAppend(sqlarray," #joiner# ")>
			<cfif StructKeyExists(arguments,"join") AND StructKeyExists(arguments.join,"table")>
				<cfset ArrayAppend(sqlarray,getFieldWhereSQL(tablename=arguments.tablename,field=rfields[ii]["ColumnName"],value=in[rfields[ii]["ColumnName"]],tablealias=arguments.tablealias,joinedtable=arguments.join.table))>
			<cfelse>
				<cfset ArrayAppend(sqlarray,getFieldWhereSQL(tablename=arguments.tablename,field=rfields[ii]["ColumnName"],value=in[rfields[ii]["ColumnName"]],tablealias=arguments.tablealias))>
			</cfif>
		</cfif>
	</cfloop>
	<!--- Filter by filters --->
	<cfif StructKeyExists(arguments,"filters") AND ArrayLen(arguments.filters)>
		<cfloop index="ii" from="1" to="#ArrayLen(arguments.filters)#" step="1">
			<!--- Make sure this is a valid filter (has a field and a value <which either has length or equality operator>) --->
			<cfif
					StructKeyExists(arguments.filters[ii],"field")
				AND	Len(arguments.filters[ii]["field"])
				AND	StructKeyExists(arguments.filters[ii],"value")
				AND	(
							Len(arguments.filters[ii]["value"])
						OR	NOT ( StructKeyExists(arguments.filters[ii],"operator") AND Len(arguments.filters[ii]["operator"]) )
						OR	arguments.filters[ii]["operator"] EQ "="
						OR	arguments.filters[ii]["operator"] EQ "<>"
						OR	arguments.filters[ii]["operator"] EQ ">"
					)
			>
				<!--- Determine the arguments of the where clause call --->
				<cfset sArgs = StructNew()>
				<cfif StructKeyExists(arguments.filters[ii],"table") AND Len(arguments.filters[ii]["table"])>
					<cfset sArgs["tablename"] = arguments.filters[ii].table>
				<cfelse>
					<cfset sArgs["tablename"] = arguments.tablename>
					<cfset sArgs["tablealias"] = arguments.tablealias>
				</cfif>
				<cfset sArgs["field"] = arguments.filters[ii].field>
				<cfset sArgs["value"] = arguments.filters[ii].value>
				<cfif StructKeyExists(arguments.filters[ii],"operator") AND Len(arguments.filters[ii]["operator"])>
					<cfset sArgs["operator"] = arguments.filters[ii].operator>
				</cfif>
				<cfif StructKeyExists(arguments,"join") AND StructKeyExists(arguments.join,"table")>
					<cfset sArgs["joinedtable"] = arguments.join.table>
				</cfif>
				<!--- Only filter if the field is in the table --->
				<cfif ListFindNoCase(getFieldList(sArgs["tablename"]),sArgs["field"])>
					<cfinvoke returnvariable="temp" method="getFieldWhereSQL" argumentCollection="#sArgs#">
					</cfinvoke>
					<!--- Only filter if the where clause returned something --->
					<cfif ( isArray(temp) AND ArrayLen(temp) ) OR ( isSimpleValue(temp) AND Len(Trim(temp)) )>
						<cfset ArrayAppend(sqlarray," #joiner# ")>
						<cfset ArrayAppend(sqlarray,temp)>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	<!--- Filter by deletable property --->
	<cfif
			( StructKeyExists(variables.tableprops[arguments.tablename],"deletable") AND Len(variables.tableprops[arguments.tablename].deletable) )
		AND	NOT ListFindNoCase(getFieldList(arguments.tablename),variables.tableprops[arguments.tablename].deletable)
		AND	NOT ( StructKeyExists(variables.tableprops[arguments.tablename],"filters") AND StructKeyExists(variables.tableprops[arguments.tablename]["filters"],variables.tableprops[arguments.tablename].deletable) )
		AND	(
					StructKeyExists(in,variables.tableprops[arguments.tablename].deletable)
				AND	isBoolean(in[variables.tableprops[arguments.tablename].deletable])
			)
	>
		<cfset ArrayAppend(sqlarray," #joiner# ")>
		<cfset ArrayAppend(sqlarray,getIsDeletableSQL(tablename=arguments.tablename,tablealias=arguments.tablealias))>
		<cfset ArrayAppend(sqlarray," = ")>
		<cfset ArrayAppend(sqlarray,getBooleanSQLValue(in[variables.tableprops[arguments.tablename].deletable]))>
	</cfif>
	<cfif StructKeyExists(arguments,"advsql") AND StructKeyExists(arguments.advsql,"WHERE") AND ( ( isArray(arguments.advsql["WHERE"]) AND ArrayLen(arguments.advsql["WHERE"]) ) OR ( isSimpleValue(arguments.advsql["WHERE"]) AND Len(Trim(arguments.advsql["WHERE"])) ) )>
		<cfif NOT ( isSimpleValue(arguments.advsql["WHERE"]) AND Left(Trim(arguments.advsql["WHERE"]),3) EQ "AND" )>
			<cfset ArrayAppend(sqlarray,joiner)>
		</cfif>
		<cfset ArrayAppend(sqlarray,arguments.advsql["WHERE"])>
	</cfif>
	
	<cfreturn sqlarray>
</cffunction>

<cffunction name="getFieldSelectSQL" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="tablealias" type="string" required="no">
	<cfargument name="useFieldAlias" type="boolean" default="true">
	
	<cfset var ttemp = fillOutJoinTableRelations(arguments.tablename)>
	<cfset var sField = 0>
	<cfset var aSQL = ArrayNew(1)>
	<cfset var sAdvSQL = StructNew()>
	<cfset var sJoin = StructNew()>
	<cfset var sArgs = StructNew()>
	<cfset var temp = "">
	
	<cfif isNumeric(arguments.field)>
		<cfset aSQL = arguments.field>
	<cfelse>
		<cfset sField = getField(arguments.tablename,arguments.field)>
		
		<cfif NOT StructKeyExists(arguments,"tablealias")>
			<cfset arguments.tablealias = arguments.tablename>
		</cfif>
		
		<cfset sArgs["noorder"] = NOT variables.dbprops["areSubqueriesSortable"]>
		
		<cfif StructKeyExists(sField,"Relation") AND StructKeyExists(sField.Relation,"type")>
			<cfset sField.Relation = expandRelationStruct(sField.Relation,sField)>
			<cfif StructKeyExists(sField["Relation"],"filters") AND isArray(sField["Relation"].filters)>
				<cfset sArgs["filters"] = sField["Relation"].filters>
			</cfif>
			<cfset ArrayAppend(aSQL,"(")>
			<cfswitch expression="#sField.Relation.type#">
			<cfcase value="label">
				<cfif StructKeyExists(sField.Relation,"sort-field")>
					<cfset sArgs["sortfield"] = sField.Relation["sort-field"]>
					<cfif StructKeyExists(sField.Relation,"sort-dir")>
						<cfset sArgs["sortdir"] = sField.Relation["sort-dir"]>
					</cfif>
				<cfelseif getDatabase() EQ "Access">
					<cfset sArgs["noorder"] = true>
				</cfif>
				<cfset sArgs["tablename"] = sField.Relation["table"]>
				<cfset sArgs["fieldlist"] = sField.Relation["field"]>
				<cfif arguments.tablealias EQ sField.Relation["table"]>
					<cfset sArgs["tablealias"] = sField.Relation["table"] & "_DataMgr_inner">
				<cfelse>
					<cfset sArgs["tablealias"] = sField.Relation["table"]>
				</cfif>
				<!--- Only one record for fields in database (otherwise nesting will occur and it could cause trouble but not give any benefit) --->
				<!--- <cfif ListFindNoCase(getDBFieldList(sField.Relation["table"]),sField.Relation["field"])> --->
					<cfset sArgs["maxrows"] = 1>
				<!--- </cfif> --->
				<cfset sAdvSQL = StructNew()>
				<cfset sAdvSQL["WHERE"] = ArrayNew(1)>
				<cfset ArrayAppend(sAdvSQL["WHERE"], getFieldSelectSQL(tablename=sField.Relation['table'],field=sField.Relation['join-field-remote'],tablealias=sArgs.tablealias,useFieldAlias=false) )>
				<cfset ArrayAppend(sAdvSQL["WHERE"], " = " )>
				<!--- <cfset ArrayAppend(sAdvSQL["WHERE"], "#escape(arguments.tablealias & '.' & sField.Relation['join-field-local'])#" )> --->
				<cfset ArrayAppend(sAdvSQL["WHERE"], getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['join-field-local'],tablealias=arguments.tablealias,useFieldAlias=false) )>
				<cfset sArgs["advsql"] = sAdvSQL>
				<cfset ArrayAppend(aSQL,getRecordsSQL(argumentCollection=sArgs))>
			</cfcase>
			<cfcase value="list">
				<cfif StructKeyExists(sField.Relation,"join-table")>
					<cfset temp = getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation["local-table-join-field"],tablealias=arguments.tablealias,useFieldAlias=false)>
					<!--- <cfset temp = escape( arguments.tablealias & "." & sField.Relation["local-table-join-field"] )> --->
				<cfelse>
					<cfset temp = getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation["join-field-local"],tablealias=arguments.tablealias,useFieldAlias=false)>
					<!--- <cfset temp = escape( arguments.tablealias & "." & sField.Relation["join-field-local"] )> --->
				</cfif>
				<cfset temp = readableSQL(temp)>
				<cfif NOT Len(Trim(temp)) >
					<cfset ArrayAppend(aSQL,"''")>
				<cfelse>
					<cfset ArrayAppend(aSQL,concat(temp))>
				</cfif>
			</cfcase>
			<cfcase value="concat">
				<cfset ArrayAppend(aSQL,"#concatFields(arguments.tablename,sField.Relation['fields'],sField.Relation['delimiter'],arguments.tablealias)#")>
			</cfcase>
			<cfcase value="avg,count,max,min,sum" delimiters=",">
				<cfset sAdvSQL = StructNew()>
				<cfif arguments.tablename EQ sField.Relation["table"]>
					<cfset sArgs["tablealias"] = sField.Relation["table"] & "_datamgr_inner_table">
				<cfelse>
					<cfset sArgs["tablealias"] = sField.Relation["table"]>
				</cfif>
				<cfif StructKeyExists(sField.Relation,"join-table")>
					<cfset sJoin = StructNew()>
					<cfset sJoin["table"] = sField.Relation["join-table"]>
					<cfset sJoin["onLeft"] = sField.Relation["remote-table-join-field"]>
					<cfset sJoin["onRight"] = sField.Relation["join-table-field-remote"]>
					<!--- <cfset sAdvSQL["WHERE"] = "#escape(sField.Relation['join-table'] & '.' & sField.Relation['join-table-field-local'].ColumnName)# = #escape(arguments.tablealias & '.' & sField.Relation['local-table-join-field'])#"> --->
					<cfset sAdvSQL["WHERE"] = ArrayNew(1)>
					<cfset ArrayAppend(sAdvSQL["WHERE"],getFieldSelectSQL(sField.Relation['join-table'],sField.Relation['join-table-field-local'],sField.Relation['join-table'],false))>
					<cfset ArrayAppend(sAdvSQL["WHERE"]," = ")>
					<cfset ArrayAppend(sAdvSQL["WHERE"],getFieldSelectSQL(arguments.tablename,sField.Relation['local-table-join-field'],arguments.tablealias,false))>
				<cfelse>
					<!--- <cfset sAdvSQL["WHERE"] = "#escape(sField.Relation['table'] & '.' & sField.Relation['join-field-remote'])# = #escape(arguments.tablealias & '.' & sField.Relation['join-field-local'])#"> --->
					<cfset sAdvSQL["WHERE"] = ArrayNew(1)>
					<cfset ArrayAppend(sAdvSQL["WHERE"],getFieldSelectSQL(sField.Relation['table'],sField.Relation['join-field-remote'],sArgs.tablealias,false))>
					<cfset ArrayAppend(sAdvSQL["WHERE"]," = ")>
					<cfset ArrayAppend(sAdvSQL["WHERE"],getFieldSelectSQL(arguments.tablename,sField.Relation['join-field-local'],arguments.tablealias,false))>
					<!--- <cfset sAdvSQL["WHERE"] = "#escape(sField.Relation['table'] & '.' & sField.Relation['join-field-remote'])# = #escape(arguments.tablealias & '.' & sField.Relation['join-field-local'])#"> --->
				</cfif>
				<cfif StructKeyExists(sField.Relation,"sort-field")>
					<cfset sArgs["sortfield"] = sField.Relation["sort-field"]>
					<cfif StructKeyExists(sField.Relation,"sort-dir")>
						<cfset sArgs["sortdir"] = sField.Relation["sort-dir"]>
					</cfif>
				</cfif>
				<cfset sArgs["tablename"] = sField.Relation["table"]>
				<cfset sArgs["fieldlist"] = sField.Relation["field"]>
				<cfset sArgs["function"] = sField.Relation["type"]>
				<cfset sArgs["advsql"] = sAdvSQL>
				<cfset sArgs["join"] = sJoin>
				<cfif arguments.tablename EQ sField.Relation["table"]>
					<cfset sArgs["tablealias"] = sField.Relation["table"]& "_datamgr_inner_table">
				</cfif>
				<cfset ArrayAppend(aSQL,getRecordsSQL(argumentCollection=sArgs))>
			</cfcase>
			<cfcase value="has">
				<cfset ArrayAppend(aSQL,getFieldSQL_Has(argumentCollection=arguments))>
			</cfcase>
			<cfcase value="math">
				<cfset ArrayAppend(aSQL,getFieldSQL_Math(argumentCollection=arguments))>
			</cfcase>
			<cfcase value="now">
				<cfset ArrayAppend(aSQL,getNowSQL())>
			</cfcase>
			<cfcase value="custom">
				<cfif StructKeyExists(sField.Relation,"sql") AND Len(sField.Relation.sql)>
					<cfset ArrayAppend(aSQL,"#sField.Relation.sql#")>
				<cfelse>
					<cfset ArrayAppend(aSQL,"''")>
				</cfif>
			</cfcase>
			<cfdefaultcase>
				<cfset ArrayAppend(aSQL,"''")>
			</cfdefaultcase>
			</cfswitch>
			<cfset ArrayAppend(aSQL,")")>
			<cfif arguments.useFieldAlias AND Len(Trim(sField['ColumnName']))>
				<cfset ArrayAppend(aSQL," AS #escape(sField['ColumnName'])#")>
			</cfif>
		<cfelse>
			<cfset ArrayAppend(aSQL,escape(arguments.tablealias & "." & sField["ColumnName"]))>
		</cfif>
	</cfif>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="getFieldSQL_Has" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="tablealias" type="string" required="no">
	
	<cfset var sField = getField(arguments.tablename,arguments.field)>
	<cfset var aSQL = 0>
	
	<cfinvoke returnvariable="aSQL" method="getHasFieldSQL">
		<cfinvokeargument name="tablename" value="#arguments.tablename#">
		<cfinvokeargument name="field" value="#sField.Relation.field#">
		<cfif StructKeyExists(arguments,"tablealias")>
			<cfinvokeargument name="tablealias" value="#arguments.tablealias#">
		<cfelse>
			<cfinvokeargument name="tablealias" value="#arguments.tablename#">
		</cfif>
	</cfinvoke>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="getHasFieldSQL" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="tablealias" type="string" required="no">
	
	<cfset var dtype = getEffectiveDataType(arguments.tablename,arguments.field)>
	<cfset var aSQL = ArrayNew(1)>
	<cfset var sAdvSQL = StructNew()>
	<cfset var sJoin = StructNew()>
	<cfset var sArgs = StructNew()>
	<cfset var temp = "">
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>
	
	<cfswitch expression="#dtype#">
	<cfcase value="numeric">
		<cfset ArrayAppend(aSQL,"isnull(CASE WHEN (")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=arguments.field,tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,") > 0 THEN 1 ELSE 0 END,0)")>
	</cfcase>
	<cfcase value="string">
		<cfset ArrayAppend(aSQL,"isnull(len(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=arguments.field,tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,"),0)")>
	</cfcase>
	<cfcase value="date">
		<cfset ArrayAppend(aSQL,"CASE WHEN (")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=arguments.field,tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,") IS NULL THEN 0 ELSE 1 END")>
	</cfcase>
	<cfcase value="boolean">
		<cfset ArrayAppend(aSQL,"isnull(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=arguments.field,tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,",0)")>
	</cfcase>
	</cfswitch>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="getFieldWhereSQL" access="public" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="tablealias" type="string" required="no">
	<cfargument name="operator" type="string" default="=">
	
	<cfset var sField = getField(arguments.tablename,arguments.field)>
	<cfset var aSQL = ArrayNew(1)>
	<cfset var sArgs = StructNew()>
	<cfset var temp = 0>
	<cfset var sAllField = 0>
	<cfset var operators = "=,>,<,>=,<=,LIKE,NOT LIKE,<>,IN,NOT IN">
	<cfset var operators_cf = "EQUAL,EQ,NEQ,GT,GTE,LT,LTE,IS,IS NOT,NOT">
	<cfset var operators_sql = "=,=,<>,>,>=,<,<=,=,<>,<>">
	<cfset var fieldval = arguments.value>
	<cfset var sRelationTypes = getRelationTypes()>
	<cfset var sAdvSQL = 0>
	<cfset var inops = "IN,NOT IN">
	<cfset var dtype = getEffectiveDataType(arguments.tablename,arguments.field)>
	
	<cfif NOT ( ListFindNoCase(operators,arguments.operator) OR ListFindNoCase(operators_cf,arguments.operator) )>
		<cfset throwDMError("#arguments.operator# is not a valid operator. Valid operators are: #operators#,#operators_cf#","InvalidOperator")>
	</cfif>
	
	<!--- Convert ColdFusion operator to SQL operator --->
	<cfif ListFindNoCase(operators_cf,arguments.operator)>
		<cfset arguments.operator = ListGetAt(operators_sql,ListFindNoCase(operators_cf,arguments.operator))>
	</cfif>
	
	<cfif arguments.operator CONTAINS "LIKE" AND dtype NEQ "string">
		<cfset throwDMError("LIKE comparisons are only valid on string fields","LikeOnlyOnStrings")>
	</cfif>
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>
	
	<cfset sArgs["noorder"] = NOT variables.dbprops["areSubqueriesSortable"]>
	
	<cfif StructKeyExists(sField,"Relation") AND StructKeyExists(sField.Relation,"type")>
		<cfset sField.Relation = expandRelationStruct(sField.Relation,sField)>
		<cfif StructKeyExists(sField["Relation"],"filters") AND isArray(sField["Relation"].filters)>
			<cfset sArgs["filters"] = sField["Relation"].filters>
		<cfelse>
			<cfset sArgs["filters"] = ArrayNew(1)>
		</cfif>
		<cfswitch expression="#sField.Relation.type#">
		<cfcase value="label">
			<cfset sArgs.tablename = sField.Relation["table"]>
			<cfset sArgs.fieldlist = sField.Relation["field"]>
			<cfset sArgs.maxrows = 1>
			<cfset sArgs.advsql = StructNew()>
			<cfset sArgs.data = StructNew()>
			
			<cfset ArrayAppend(aSQL,"EXISTS (")>
				<cfset sArgs.operator = arguments.operator>
				<cfset sArgs.noorder = true>
				<cfset sArgs.isInExists = true>
				<cfset temp = StructNew()>
				<!--- <cfset ArrayAppend(temp,StructNew())> --->
				<cfset temp.field = sField.Relation["field"]>
				<cfset temp.value = fieldval>
				<cfset temp.operator = arguments.operator>
				<cfif arguments.tablealias EQ sField.Relation["table"]>
					<cfset sArgs["tablealias"] = sField.Relation["table"] & "_datamgr_inner">
				<cfelse>
					<cfset sArgs["tablealias"] = sField.Relation["table"]>
				</cfif>
				<cfset ArrayAppend(sArgs.filters,temp)>
				<!--- <cfset sArgs.advsql["WHERE"] = "#escape(sField.Relation['table'] & '.' & sField.Relation['join-field-remote'])# = #escape(arguments.tablealias & '.' & sField.Relation['join-field-local'])#"> --->
				<!--- <cfset sArgs.advsql["WHERE"] = "#escape(arguments.tablealias & '.' & sField.Relation['join-field-local'])# = #escape(sField.Relation['table'] & '.' & sField.Relation['join-field-remote'])#"> --->
				<cfset sArgs.advsql["WHERE"] = ArrayNew(1)>
				<cfset ArrayAppend(sArgs.advsql["WHERE"],getFieldSelectSQL(sField.Relation['table'],sField.Relation['join-field-remote'],sArgs.tablealias,false))>
				<cfset ArrayAppend(sArgs.advsql["WHERE"]," = ")>
				<cfif StructKeyExists(arguments,"joinedtable") AND Len(arguments.joinedtable)>
					<cfset ArrayAppend(sArgs.advsql["WHERE"],getFieldSelectSQL(arguments.joinedtable,sField.Relation['join-field-local'],arguments.joinedtable,false))>
				<cfelse>
					<cfset ArrayAppend(sArgs.advsql["WHERE"],getFieldSelectSQL(arguments.tablename,sField.Relation['join-field-local'],arguments.tablealias,false))>
				</cfif>
				<cfset ArrayAppend(aSQL,getRecordsSQL(argumentCollection=sArgs))>
			<cfset ArrayAppend(aSQL,")")>
		</cfcase>
		<cfcase value="list">
			<cfset sArgs.isInExists = true>
			<cfset sArgs.noorder = true>
			<cfset sArgs.tablename = sField.Relation["table"]>
			<cfset sArgs.fieldlist = sField.Relation["field"]>
			<cfset sArgs.maxrows = 1>
			<cfset sArgs.join = StructNew()>
			<!--- <cfset sArgs.filters = ArrayNew(1)> --->
			<cfset sArgs.advsql = StructNew()>
			<cfset sArgs.advsql.WHERE = ArrayNew(1)>
			<cfset temp = ArrayNew(1)>
			
			<cfif StructKeyExists(sField.Relation,"join-table")>
				<cfset sArgs.join.table = sField.Relation["join-table"]>
				<cfset sArgs.join.onLeft = sField.Relation["remote-table-join-field"]>
				<cfset sArgs.join.onRight = sField.Relation["join-table-field-remote"]>
				
				<cfset ArrayAppend(sArgs.advsql.WHERE,getFieldSelectSQL(sField.Relation['join-table'],sField.Relation['join-table-field-local'],sField.Relation['join-table'],false))>
				<cfset ArrayAppend(sArgs.advsql.WHERE," = ")>
				<cfset ArrayAppend(sArgs.advsql.WHERE,getFieldSelectSQL(arguments.tablename,sField.Relation['local-table-join-field'],arguments.tablealias,false))>
				<!--- <cfset ArrayAppend(sArgs.advsql.WHERE,"#escape(sField.Relation['join-table'] & '.' & sField.Relation['join-table-field-local'])# = #escape(arguments.tablealias & '.' & sField.Relation['local-table-join-field'])#")> --->
			<cfelse>
				<cfset ArrayAppend(sArgs.advsql.WHERE,getFieldSelectSQL(sField.Relation['table'],sField.Relation['join-field-remote'],sField.Relation['table'],false))>
				<cfset ArrayAppend(sArgs.advsql.WHERE," = ")>
				<cfset ArrayAppend(sArgs.advsql.WHERE,getFieldSelectSQL(arguments.tablename,sField.Relation['join-field-local'],arguments.tablealias,false))>
				<!--- <cfset ArrayAppend(sArgs.advsql.WHERE,"#escape(sField.Relation['table'] & '.' & sField.Relation['join-field-remote'])# = #escape(arguments.tablealias & '.' & sField.Relation['join-field-local'])#")> --->
			</cfif>
			<cfif Len(arguments.value)>
				<cfset ArrayAppend(sArgs.advsql.WHERE,"			AND		(")>
				<cfset ArrayAppend(sArgs.advsql.WHERE,"							1 = 0")>
				<cfloop index="temp" list="#fieldval#">
					<cfset ArrayAppend(sArgs.advsql.WHERE,"					OR")>
					<!--- <cfset ArrayAppend(sArgs.advsql.WHERE,"#escape(sField.Relation['table'] & '.' & sField.Relation['field'])#")> --->
					<cfset ArrayAppend(sArgs.advsql.WHERE,"#getFieldSelectSQL(sField.Relation['table'],sField.Relation['field'],sField.Relation['table'],false)#")>
					<cfset ArrayAppend(sArgs.advsql.WHERE," = ")><!--- %%TODO: Needs to work for any operator --->
					<cfset ArrayAppend(sArgs.advsql.WHERE,sval(getField(sField.Relation["table"],sField.Relation["field"]),temp))>
				</cfloop>
				<cfset ArrayAppend(sArgs.advsql.WHERE,"					)")>
			</cfif>
			<cfif NOT Len(arguments.value)>
				<cfset ArrayAppend(aSQL," NOT ")>
			</cfif>
			<cfset ArrayAppend(aSQL,"EXISTS (")>
				<cfset ArrayAppend(aSQL,getRecordsSQL(argumentCollection=sArgs))>
			<cfset ArrayAppend(aSQL,"		)")>
		</cfcase>
		<cfcase value="concat">
			<!---
			SEB 2009-1113: Replaced by below
			<cfset ArrayAppend(aSQL,"(")>
				<cfset ArrayAppend(aSQL,"#concat(sField.Relation['fields'],sField.Relation['delimiter'])#")>
			<cfset ArrayAppend(aSQL,")")>
			--->
			<cfset ArrayAppend(aSQL,getFieldSelectSQL(arguments.tablename,arguments.field,arguments.tablealias,false))>
			<!---
			SEB 2009-1113: Replaced by below
			<cfif ListFindNoCase(inops,arguments.operator)>
				<cfset ArrayAppend(aSQL," #arguments.operator# (")>
				<cfset ArrayAppend(aSQL,queryparam(cfsqltype="CF_SQL_VARCHAR",value=fieldval,list=true))>
				<cfset ArrayAppend(aSQL," )")>
			<cfelse>
				<cfset ArrayAppend(aSQL," #arguments.operator#")>
				<cfset ArrayAppend(aSQL,queryparam("CF_SQL_VARCHAR",fieldval))>
			</cfif>
			--->
			<cfset ArrayAppend(aSQL,getComparatorSQL(fieldval,"CF_SQL_VARCHAR",arguments.operator))>
		</cfcase>
		<cfcase value="avg,count,max,min,sum" delimiters=",">
			<cfset sArgs.tablename = sField.Relation["table"]>
			<cfset sArgs.fieldlist = sField.Relation["field"]>
			<cfset sArgs.advsql = StructNew()>
			<cfset sArgs.join = StructNew()>
		
			<cfset sAdvSQL = StructNew()>
			<cfif StructKeyExists(sField.Relation,"join-table")>
				<cfset sArgs.join["table"] = sField.Relation["join-table"]>
				<cfset sArgs.join["onLeft"] = sField.Relation["remote-table-join-field"]>
				<cfset sArgs.join["onRight"] = sField.Relation["join-table-field-remote"]>
				<cfset sArgs.advsql["WHERE"] = ArrayNew(1)>
				<cfset ArrayAppend(sArgs.advsql["WHERE"],getFieldSelectSQL(sField.Relation['join-table'],sField.Relation['join-table-field-local'],sField.Relation['join-table'],false))>
				<cfset ArrayAppend(sArgs.advsql["WHERE"]," = ")>
				<cfset ArrayAppend(sArgs.advsql["WHERE"],getFieldSelectSQL(arguments.tablename,sField.Relation['local-table-join-field'],arguments.tablealias,false))>
			<cfelse>
				<cfset sArgs.advsql["WHERE"] = ArrayNew(1)>
				<cfset ArrayAppend(sArgs.advsql["WHERE"],getFieldSelectSQL(sField.Relation['table'],sField.Relation['join-field-remote'],sField.Relation['table'],false))>
				<cfset ArrayAppend(sArgs.advsql["WHERE"]," = ")>
				<cfset ArrayAppend(sArgs.advsql["WHERE"],getFieldSelectSQL(arguments.tablename,sField.Relation['join-field-local'],arguments.tablealias,false))>
			</cfif>
			<cfset sArgs["function"] = sField.Relation["type"]>
			<cfif arguments.tablename EQ sField.Relation["table"]>
				<cfset sArgs["tablealias"] = sField.Relation["table"] & "_datamgr_inner_table">
			</cfif>
			<cfset ArrayAppend(aSQL,"(")>
				<cfset ArrayAppend(aSQL,getRecordsSQL(argumentCollection=sArgs))>
			<cfset ArrayAppend(aSQL,")")>
			<!---
			SEB 2009-11-13: Replaced by below
			<cfif ListFindNoCase(inops,arguments.operator)>
				<cfset ArrayAppend(aSQL," #arguments.operator# (")>
				<cfset ArrayAppend(aSQL,queryparam(cfsqltype="CF_SQL_NUMERIC",value=fieldval,list=true))>
				<cfset ArrayAppend(aSQL," )")>
			<cfelse>
				<cfset ArrayAppend(aSQL," #arguments.operator#")>
				<cfset ArrayAppend(aSQL,Val(fieldval))>
			</cfif>
			--->
			<cfset ArrayAppend(aSQL,getComparatorSQL(fieldval,"CF_SQL_NUMERIC",arguments.operator))>
		</cfcase>
		<cfcase value="custom">
			<cfif StructKeyExists(sField.Relation,"sql") AND Len(sField.Relation.sql) AND StructKeyExists(sField.Relation,"CF_DataType")>
				<cfset ArrayAppend(aSQL,"(")>
				<cfset ArrayAppend(aSQL,"#sField.Relation.sql#")>
				<cfset ArrayAppend(aSQL,")")>
				<!---
				SEB 2009-11-13: Replaced by below
				<cfif ListFindNoCase(inops,arguments.operator)>
					<cfset ArrayAppend(aSQL," #arguments.operator# (")>
					<cfset ArrayAppend(aSQL,queryparam(cfsqltype=sField.Relation["CF_DataType"],value=fieldval,list=true))>
					<cfset ArrayAppend(aSQL," )")>
				<cfelse>
					<cfset ArrayAppend(aSQL,arguments.operator)>
					<cfset ArrayAppend(aSQL,queryparam(cfsqltype=sField.Relation["CF_DataType"],value=fieldval))>
				</cfif>
				--->
				<cfset ArrayAppend(aSQL,getComparatorSQL(fieldval,sField.Relation["CF_DataType"],arguments.operator))>
			<cfelse>
				<cfset ArrayAppend(aSQL,"1 = 1")>
			</cfif>
		</cfcase>
		<cfdefaultcase>
			<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=arguments.field,tablealias=arguments.tablealias,useFieldAlias=false) )>
			<!---
			SEB 2009-11-13: Replaced by below
			<cfif ListFindNoCase(inops,arguments.operator)>
				<cfset ArrayAppend(aSQL," #arguments.operator# (")>
				<cfif StructKeyExists(sRelationTypes,sField.Relation.type) AND Len(sRelationTypes[sField.Relation.type].cfsqltype)>
					<cfset ArrayAppend(aSQL,queryparam(cfsqltype=sRelationTypes[sField.Relation.type].cfsqltype,value=fieldval,list=yes))>
				<cfelse>
					<cfset ArrayAppend(aSQL,queryparam(cfsqltype="CF_SQL_NUMERIC",value=fieldval,list=yes))>
				</cfif>
				<cfset ArrayAppend(aSQL," )")>
			<cfelse>
				<cfset ArrayAppend(aSQL,arguments.operator)>
				<cfif StructKeyExists(sRelationTypes,sField.Relation.type) AND Len(sRelationTypes[sField.Relation.type].cfsqltype)>
					<cfset ArrayAppend(aSQL,queryparam(sRelationTypes[sField.Relation.type].cfsqltype,fieldval))>
				<cfelse>
					<cfset ArrayAppend(aSQL,Val(fieldval))>
				</cfif>
			</cfif>
			--->
			<cfif StructKeyExists(sRelationTypes,sField.Relation.type) AND Len(sRelationTypes[sField.Relation.type].cfsqltype)>
				<cfset ArrayAppend(aSQL,getComparatorSQL(fieldval,sRelationTypes[sField.Relation.type].cfsqltype,arguments.operator))>
			<cfelse>
				<cfset ArrayAppend(aSQL,getComparatorSQL(Val(fieldval),"CF_SQL_NUMERIC",arguments.operator))>
			</cfif>
		</cfdefaultcase>
		</cfswitch>
		<cfif StructKeyExists(sField.Relation,"all-field")>
			<cfset sAllField = getField(arguments.tablename,sField.Relation["all-field"])>
			<cfset sArgs = arguments>
			<cfset sArgs.field = sField.Relation["all-field"]>
			<cfset sArgs.value = 1>
			<cfif isStruct(sAllField)>
				<cfset ArrayPrepend(aSQL," OR ")>
				<cfset ArrayPrepend(aSQL,getFieldWhereSQL(argumentCollection=sArgs))>
				<cfset ArrayPrepend(aSQL,"(")>
				<cfset ArrayAppend(aSQL,")")>
			</cfif>
		</cfif>
	<cfelse>
		<cfif getDatabase() EQ "Access" AND sField.CF_Datatype EQ "CF_SQL_BIT">
			<cfset ArrayAppend(aSQL,"abs(#escape(arguments.tablealias & '.' & sField.ColumnName)#)")>
		<cfelse>
			<cfset ArrayAppend(aSQL,"#escape(arguments.tablealias & '.' & sField.ColumnName)#")>
		</cfif>
		<cfif getDatabase() EQ "Derby" AND arguments.operator CONTAINS "LIKE">
			<cfset ArrayPrepend(aSQL,"LOWER(")>
			<cfset ArrayAppend(aSQL,")")>
			<cfset fieldval = LCase(fieldval)>
		</cfif>
		<!---
		SEB 2009-11-13: Replaced by below
		<cfif Len(Trim(fieldval)) OR NOT sField.AllowNULLs>
			<cfif ListFindNoCase(inops,arguments.operator)>
				<cfset ArrayAppend(aSQL," #arguments.operator# (")>
				<cfset ArrayAppend(aSQL,queryparam(cfsqltype=sField.CF_Datatype,value=fieldval,list=true))>
				<cfset ArrayAppend(aSQL," )")>
			<cfelse>
				<cfset ArrayAppend(aSQL," #arguments.operator#")>
				<cfset ArrayAppend(aSQL,queryparam(sField.CF_Datatype,fieldval))>
			</cfif>
		<cfelse>
			<cfif arguments.operator EQ "=">
				<cfset ArrayAppend(aSQL," IS")>
			<cfelse>
				<cfset ArrayAppend(aSQL," IS NOT")>
			</cfif>
			<cfset ArrayAppend(aSQL," NULL")>
		</cfif>
		--->
		<cfset ArrayAppend(aSQL,getComparatorSQL(fieldval,sField.CF_Datatype,arguments.operator))>
	</cfif>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="getStringTypes" access="public" returntype="string" output="no" hint="I return a list of datypes that hold strings / character values."><cfreturn ""></cffunction>

<cffunction name="getSupportedDatabases" access="public" returntype="query" output="no" hint="I return the databases supported by this installation of DataMgr.">
	
	<cfset var qComponents = 0>
	<cfset var aComps = ArrayNew(1)>
	<cfset var i = 0>
	<cfset var qDatabases = QueryNew("Database,DatabaseName,shortstring,driver")>
	
	<cfif StructKeyExists(variables,"databases") AND isQuery(variables.databases)>
		<cfset qDatabases = variables.databases>
	<cfelse>
		<cfdirectory action="LIST" directory="#GetDirectoryFromPath(GetCurrentTemplatePath())#" name="qComponents" filter="*.cfc">
		<cfloop query="qComponents">
			<cfif name CONTAINS "DataMgr_">
				<cftry>
					<cfset ArrayAppend(aComps,CreateObject("component","#ListFirst(name,'.')#").init(""))>
					<cfset QueryAddRow(qDatabases)>
					<cfset QuerySetCell(qDatabases, "Database", ReplaceNoCase(ListFirst(name,"."),"DataMgr_","") )>
					<cfset QuerySetCell(qDatabases, "DatabaseName", aComps[ArrayLen(aComps)].getDatabase() )>
					<cfset QuerySetCell(qDatabases, "shortstring", aComps[ArrayLen(aComps)].getDatabaseShortString() )>
					<cfset QuerySetCell(qDatabases, "driver", aComps[ArrayLen(aComps)].getDatabaseDriver() )>
					<cfcatch>
					</cfcatch>
				</cftry>
			</cfif>
		</cfloop>
		<cfset variables.databases = qDatabases>
	</cfif>

	<cfreturn qDatabases>
</cffunction>

<cffunction name="getTableData" access="public" returntype="struct" output="no" hint="I return information about all of the tables currently loaded into this instance of Data Manager.">
	<cfargument name="tablename" type="string" required="no">
	
	<cfset var sResult = 0>
	
	<cfif StructKeyExists(arguments,"tablename") AND Len(arguments.tablename)>
		<cfset checkTable(arguments.tablename)><!--- Check whether table is loaded --->
		<cfset sResult = StructNew()>
		<cfif ListFindNoCase(StructKeyList(variables.tables),arguments.tablename)> 
			<cfset sResult[arguments.tablename] = variables.tables[arguments.tablename]>
		</cfif>
	<cfelse>
		<cfset sResult = variables.tables>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getUpdateableFields" access="public" returntype="array" output="no" hint="I return an array of fields that can be updated.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var bTable = checkTable(arguments.tablename)><!--- Check whether table is loaded --->
	<cfset var ii = 0><!--- counter --->
	<cfset var arrFields = ArrayNew(1)><!--- array of udateable fields --->
	
	<cfif StructKeyExists(variables.tableprops,arguments.tablename) AND StructKeyExists(variables.tableprops[arguments.tablename],"updatefields")>
		<cfset arrFields = variables.tableprops[arguments.tablename]["updatefields"]>
	<cfelse>
		<cfloop index="ii" from="1" to="#ArrayLen(variables.tables[arguments.tablename])#" step="1">
			<!--- Make sure field isn't a relation --->
			<cfif StructKeyExists(variables.tables[arguments.tablename][ii],"CF_Datatype") AND NOT StructKeyExists(variables.tables[arguments.tablename][ii],"Relation")>
				<!--- Make sure field isn't a primary key --->
				<cfif NOT StructKeyExists(variables.tables[arguments.tablename][ii],"PrimaryKey") OR NOT variables.tables[arguments.tablename][ii].PrimaryKey>
					<cfset ArrayAppend(arrFields, variables.tables[arguments.tablename][ii])>
				</cfif>
			</cfif>
		</cfloop>
		<cfset variables.tableprops[arguments.tablename]["updatefields"] = arrFields>
	</cfif>
	
	<cfreturn arrFields>
</cffunction>

<cffunction name="getVersion" access="public" returntype="string" output="no">
	<cfreturn variables.DataMgrVersion>
</cffunction>

<cffunction name="insertRecord" access="public" returntype="string" output="no" hint="I insert a record into the given table with the provided data and do my best to return the primary key of the inserted record.">
	<cfargument name="tablename" type="string" required="yes" hint="The table in which to insert data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="OnExists" type="string" default="insert" hint="The action to take if a record with the given values exists. Possible values: insert (inserts another record), error (throws an error), update (updates the matching record), skip (performs no action), save (updates only for matching primary key)).">
	<cfargument name="fieldlist" type="string" default="" hint="A list of insertable fields. If left blank, any field can be inserted.">
	<cfargument name="truncate" type="boolean" default="false" hint="Should the field values be automatically truncated to fit in the available space for each field?">
	
	<cfset var OnExistsValues = "insert,error,update,skip"><!--- possible values for OnExists argument --->
	<cfset var ii = 0><!--- generic counter --->
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var in = arguments.data><!--- holder for incoming data (just for readability) --->
	<cfset var inPK = StructNew()><!--- holder for incoming pk data (just for readability) --->
	<cfset var qGetRecords = QueryNew('none')>
	<cfset var result = ""><!--- will hold primary key --->
	<cfset var qCheckKey = 0><!--- Used to get primary key --->
	<cfset var sqlarray = ArrayNew(1)>
	
	<cfif arguments.truncate>
		<cfset in = variables.truncate(arguments.tablename,in)>
	</cfif>
	
	<!--- Check for existing records if an action other than insert should be take if one exists --->
	<cfif arguments.OnExists NEQ "insert">
		<cfif ArrayLen(pkfields)>
			<!--- Load up all primary key fields in temp structure --->
			<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
				<cfif StructKeyHasLen(in,pkfields[ii].ColumnName)>
					<cfset inPK[pkfields[ii].ColumnName] = in[pkfields[ii].ColumnName]>
				</cfif>
			</cfloop>
		</cfif>
		
		<!--- Try to get existing record with given data --->
		<cfif arguments.OnExists NEQ "save">
			<!--- Use only pkfields if all are passed in, otherwise use all data available --->
			<cfif ArrayLen(pkfields)>
				<cfif StructCount(inPK) EQ ArrayLen(pkfields)>
					<cfset qGetRecords = getRecords(tablename=arguments.tablename,data=inPK,fieldlist=StructKeyList(inPK))>
				<cfelse>
					<cfset qGetRecords = getRecords(tablename=arguments.tablename,data=in,fieldlist=StructKeyList(inPK))>
				</cfif>
			<cfelse>
				<cfset qGetRecords = getRecords(tablename=arguments.tablename,data=in,fieldlist=StructKeyList(in))>
			</cfif>
		</cfif>
		
		<!--- If no matching records by all fields, Check for existing record by primary keys --->
		<cfif arguments.OnExists EQ "save" OR qGetRecords.RecordCount EQ 0>
			<cfif ArrayLen(pkfields)>
				<!--- All all primary key fields exist, check for record --->
				<cfif StructCount(inPK) EQ ArrayLen(pkfields)>
					<cfset qGetRecords = getRecord(tablename=arguments.tablename,data=inPK,fieldlist=StructKeyList(inPK))>
				</cfif>
			</cfif>
		</cfif>
	</cfif>
	
	<!--- Check for existing records --->
	<cfif qGetRecords.RecordCount GT 0>
		<cfswitch expression="#arguments.OnExists#">
		<cfcase value="error">
			<cfset throwDMError("#arguments.tablename#: A record with these criteria already exists.")>
		</cfcase>
		<cfcase value="update,save">
			<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
				<cfset in[pkfields[ii].ColumnName] = qGetRecords[pkfields[ii].ColumnName][1]>
			</cfloop>
			<cfset result = updateRecord(arguments.tablename,in)>
			<cfreturn result>
		</cfcase>
		<cfcase value="skip">
			<cfif ArrayLen(pkfields)>
				<cfreturn qGetRecords[pkfields[1].ColumnName][1]>
			<cfelse>
				<cfreturn 0>
			</cfif>
		</cfcase>
		</cfswitch>
	</cfif>
	
	<!--- Perform insert --->
	<cfset aInsertSQL = insertRecordSQL(tablename=arguments.tablename,data=in,fieldlist=arguments.fieldlist)>
	<cfif ArrayLen(aInsertSQL)>
		<cfset qCheckKey = runSQLArray(aInsertSQL)>
	</cfif>
	
	<cfif isDefined("qCheckKey") AND isQuery(qCheckKey) AND qCheckKey.RecordCount AND ListFindNoCase(qCheckKey.ColumnList,"NewID")>
		<cfset result = qCheckKey.NewID>
	</cfif>
	
	<!--- Get primary key --->
	<cfif Len(result) EQ 0>
		<cfif ArrayLen(pkfields) AND StructKeyExists(in,pkfields[1].ColumnName) AND useField(in,pkfields[1]) AND NOT isIdentityField(pkfields[1])>
			<cfset result = in[pkfields[1].ColumnName]>
		<cfelseif ArrayLen(pkfields) AND StructKeyExists(pkfields[1],"Increment") AND isBoolean(pkfields[1].Increment) AND pkfields[1].Increment>
			<cfset result = getInsertedIdentity(arguments.tablename,pkfields[1].ColumnName)>
		<cfelse>
			<cftry>
				<cfset result = getPKFromData(arguments.tablename,in)>
			<cfcatch>
				<cfset result = "">
			</cfcatch>
			</cftry>
		</cfif>
	</cfif>
	
	<!--- set pkfield so that we can save relation data --->
	<cfif ArrayLen(pkfields)>
		<cfif ArrayLen(pkfields) EQ 1 AND NOT Len(result)>
			<cfset result = getPKFromData(arguments.tablename,in)>
		</cfif>
		<cfset in[pkfields[1].ColumnName] = result>
		<cfif Len(Trim(result))>
			<cfset saveRelations(arguments.tablename,in,pkfields[1],result)>
		</cfif>
	</cfif>
	
	<!--- Log insert --->
	<cfif variables.doLogging AND NOT arguments.tablename EQ variables.logtable>
		<cfinvoke method="logAction">
			<cfinvokeargument name="tablename" value="#arguments.tablename#">
			<cfif ArrayLen(pkfields) EQ 1 AND StructKeyExists(in,pkfields[1].ColumnName)>
				<cfinvokeargument name="pkval" value="#in[pkfields[1].ColumnName]#">
			</cfif>
			<cfinvokeargument name="action" value="insert">
			<cfinvokeargument name="data" value="#in#">
			<cfinvokeargument name="sql" value="#sqlarray#">
		</cfinvoke>
	</cfif>
	
	<cfset setCacheDate()>
	
	<cfreturn result>
</cffunction>

<cffunction name="insertRecordSQL" access="public" returntype="array" output="no" hint="I insert a record into the given table with the provided data and do my best to return the primary key of the inserted record.">
	<cfargument name="tablename" type="string" required="yes" hint="The table in which to insert data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="fieldlist" type="string" default="" hint="A list of insertable fields. If left blank, any field can be inserted.">
	
	<cfreturn insertRecordsSQL(tablename=arguments.tablename,data_set=arguments.data,fieldlist=arguments.fieldlist)>
</cffunction>

<cffunction name="insertRecordsSQL" access="public" returntype="array" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data_set" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="data_where" type="struct" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="fieldlist" type="string" default="" hint="A list of insertable fields. If left blank, any field can be inserted.">
	<cfargument name="filters" type="array" default="#ArrayNew(1)#">
	
	<cfset var bSetGuid = false>
	<cfset var bGetNewSeqId = false><!--- Alternate set GUID approach for newsequentialid() support (SQL Server specific) --->
	<cfset var GuidVar = "">
	<cfset var sqlarray = ArrayNew(1)>
	<cfset var ii = 0>
	<cfset var fieldcount = 0>
	<cfset var bUseSubquery = false>
	<cfset var fields = getUpdateableFields(arguments.tablename)>
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var in = clean(arguments.data_set)><!--- holder for incoming data (just for readability) --->
	<cfset var inf = "">
	<cfset var Specials = "CreationDate,LastUpdatedDate,Sorter,UUID">
	
	<!--- Restrict data to fieldlist --->
	<cfif Len(Trim(arguments.fieldlist))>
		<cfloop item="ii" collection="#in#">
			<cfif NOT ListFindNoCase(arguments.fieldlist,ii)>
				<cfset StructDelete(in,ii)>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfset in = getRelationValues(arguments.tablename,in)>
	
	<!--- Create GUID for insert SQL Server where the table has on primary key field and it is a GUID --->
	<cfif ArrayLen(pkfields) EQ 1 AND pkfields[1].CF_Datatype EQ "CF_SQL_IDSTAMP" AND getDatabase() EQ "MS SQL" AND NOT StructKeyExists(in,pkfields[1].ColumnName)>
		<cfif StructKeyExists(pkfields[1], "default") and pkfields[1].Default contains "newsequentialid">
			<cfset bGetNewSeqId = true>
		<cfelse>
			<cfset bSetGuid = true>
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(arguments,"data_where") AND StructCount(arguments.data_where)>
		<cfset bUseSubquery = true>
	</cfif>
	
	<!--- Create variable to hold GUID for SQL Server GUID inserts --->
	<cfif bSetGuid OR bGetNewSeqId>
		<cflock timeout="30" throwontimeout="No" name="DataMgr_GuidNum" type="EXCLUSIVE">
			<!--- %%I cant figure out a way to safely increment the variable to make it unique for a transaction w/0 the use of request scope --->
			<cfif isDefined("request.DataMgr_GuidNum")>
				<cfset request.DataMgr_GuidNum = Val(request.DataMgr_GuidNum) + 1>
			<cfelse>
				<cfset request.DataMgr_GuidNum = 1>
			</cfif>
			<cfset GuidVar = "GUID#request.DataMgr_GuidNum#">
		</cflock>
	</cfif>
	
	<!--- Insert record --->
	<cfif bSetGuid>
		<cfset ArrayAppend(sqlarray,"DECLARE @#GuidVar# uniqueidentifier")>
		<cfset ArrayAppend(sqlarray,"SET @#GuidVar# = NEWID()")>
	<cfelseif bGetNewSeqId>
		<cfset ArrayAppend(sqlarray, "DECLARE @#GuidVar# TABLE (inserted_guid uniqueidentifier);")>
	</cfif>
	<cfset ArrayAppend(sqlarray,"INSERT INTO #escape(arguments.tablename)# (")>
	
	<!--- Loop through all updateable fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif
				( useField(in,fields[ii]) OR (StructKeyExists(fields[ii],"Default") AND Len(fields[ii].Default) AND getDatabase() EQ "Access") )
			OR	NOT ( useField(in,fields[ii]) OR StructKeyExists(fields[ii],"Default") OR fields[ii].AllowNulls )
			OR	( StructKeyExists(fields[ii],"Special") AND Len(fields[ii].Special) AND ListFindNoCase(Specials,fields[ii]["Special"]) ) 
		><!--- Include the field in SQL if it has appropriate data --->
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,escape(fields[ii].ColumnName))>
		</cfif>
	</cfloop>
	<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif ( useField(in,pkfields[ii]) AND NOT isIdentityField(pkfields[ii]) ) OR ( pkfields[ii].CF_Datatype EQ "CF_SQL_IDSTAMP" AND bSetGuid )><!--- Include the field in SQL if it has appropriate data --->
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,"#escape(pkfields[ii].ColumnName)#")>
		</cfif>
	</cfloop>
	<cfset ArrayAppend(sqlarray,")")>
	<cfif bGetNewSeqId>
		<cfset ArrayAppend(sqlarray, "OUTPUT INSERTED.#escape(pkfields[1].ColumnName)# INTO @#GuidVar#")>
	</cfif>
	<cfif bUseSubquery>
		<cfset ArrayAppend(sqlarray,"SELECT ")>
	<cfelse>
		<cfset ArrayAppend(sqlarray,"VALUES (")>
	</cfif>
	<cfset fieldcount = 0>
	<!--- Loop through all updateable fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif useField(in,fields[ii])><!--- Include the field in SQL if it has appropriate data --->
			<cfset checkLength(fields[ii],in[fields[ii].ColumnName])>
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,sval(fields[ii],in))>
		<cfelseif StructKeyExists(fields[ii],"Special") AND Len(fields[ii].Special) AND ListFindNoCase(Specials,fields[ii]["Special"])>
			<!--- Set fields based on specials --->
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfswitch expression="#fields[ii].Special#">
			<cfcase value="CreationDate">
				<cfset ArrayAppend(sqlarray,getFieldNowValue(arguments.tablename,fields[ii]))>
			</cfcase>
			<cfcase value="LastUpdatedDate">
				<cfset ArrayAppend(sqlarray,getFieldNowValue(arguments.tablename,fields[ii]))>
			</cfcase>
			<cfcase value="Sorter">
				<cfset ArrayAppend(sqlarray,getNewSortNum(arguments.tablename,fields[ii].ColumnName))>
			</cfcase>
			<cfcase value="UUID">
				<cfif structKeyExists(fields[ii],"CF_DataType")>
					<cfset ArrayAppend(sqlarray,queryparam(cfsqltype=fields[ii].CF_DataType,value=CreateUUID()))>
				<cfelse>
					<cfset ArrayAppend(sqlarray,queryparam(cfsqltype="CF_SQL_VARCHAR",value=CreateUUID()))>
				</cfif>
			</cfcase>
			</cfswitch>
		<cfelseif StructKeyExists(fields[ii],"Default") AND Len(fields[ii].Default) AND getDatabase() EQ "Access">
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,fields[ii].Default)>
		<cfelseif NOT ( useField(in,fields[ii]) OR StructKeyExists(fields[ii],"Default") OR fields[ii].AllowNulls )>
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,"''")>
		</cfif>
	</cfloop>
	<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif useField(in,pkfields[ii]) AND NOT isIdentityField(pkfields[ii])><!--- Include the field in SQL if it has appropriate data --->
			<cfset checkLength(pkfields[ii],in[pkfields[ii].ColumnName])>
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,sval(pkfields[ii],in))>
		<cfelseif pkfields[ii].CF_Datatype EQ "CF_SQL_IDSTAMP" AND bSetGuid>
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,"@#GuidVar#")>
		</cfif>
	</cfloop>
	<cfif fieldcount EQ 0>
		<!---<cfsavecontent variable="inf"><cfdump var="#in#"></cfsavecontent>--->
		<cfset throwDMError("You must pass in at least one field that can be inserted into the database. Fields: #StructKeyList(in)#","NeedInsertFields")>
	</cfif>
	<cfif bUseSubquery>
		<cfset ArrayAppend(sqlarray,"WHERE NOT EXISTS (")>
			<cfset ArrayAppend(sqlarray,"SELECT 1")>
			<cfset ArrayAppend(sqlarray,"FROM #escape(arguments.tablename)#")>
			<cfset ArrayAppend(sqlarray,"WHERE 1 = 1")>
			<cfset ArrayAppend(sqlarray,getWhereSQL(tablename=arguments.tablename,data=arguments.data_where,filters=arguments.filters))>
		<cfset ArrayAppend(sqlarray,")")>
	<cfelse>
		<cfset ArrayAppend(sqlarray,")")>
	</cfif>
	<cfif bSetGuid>
		<cfset ArrayAppend(sqlarray,";")>
		<cfset ArrayAppend(sqlarray,"SELECT @#GuidVar# AS NewID")>
	<cfelseif bGetNewSeqId>
		<cfset ArrayAppend(sqlarray,";")>
		<cfset ArrayAppend(sqlarray, "SELECT inserted_guid AS NewID FROM @#GuidVar#;")>
	</cfif>
	
	<cfif fieldcount EQ 0>
		<cfset sqlarray = ArrayNew(1)>
	</cfif>
	
	<cfreturn sqlarray>
</cffunction>

<cffunction name="isDeletable" access="public" returntype="boolean" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table from which to delete a record.">
	<cfargument name="data" type="struct" required="yes" hint="A structure indicating the record to delete. A key indicates a field. The structure should have a key for each primary key in the table.">
	
	<cfreturn ( Len(getDeletionConflicts(argumentCollection=arguments)) EQ 0 )>
</cffunction>

<cffunction name="isLogging" access="public" returntype="boolean" output="no">
	
	<cfif NOT isDefined("doLogging")>
		<cfset variables.doLogging = false>
	</cfif>
	
	<cfreturn variables.doLogging>
</cffunction>

<cffunction name="isLogicalDeletion" access="public" returntype="boolean" output="no">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var fields = getUpdateableFields(arguments.tablename)>
	<cfset var ii = 0>
	<cfset var result = false>
	
	<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif
				( StructKeyExists(fields[ii],"Special") AND fields[ii].Special EQ "DeletionMark" )
			AND	(
						fields[ii].CF_DataType EQ "CF_SQL_BIT"
					AND	(
								fields[ii].CF_DataType EQ "CF_SQL_DATE"
							OR	fields[ii].CF_DataType EQ "CF_SQL_DATETIME"
						)
				)
		>
			<cfset result = true>
			<cfbreak>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="isValidDate" access="public" returntype="boolean" output="no">
	<cfargument name="value" type="string" required="yes">
	
	<cfset var result = (
			isDate(arguments.value)
		OR	(
					isNumeric(arguments.value)
				AND	arguments.value GT 0
				AND	arguments.value LT 65538
			)
	)>
	
	<cfreturn result>
</cffunction>

<cffunction name="loadTable" access="public" returntype="void" output="no" hint="I load a table from the database into DataMgr.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="ErrorOnNotExists" type="boolean" default="true">
	
	<cfset var ii = 0>
	<cfset var arrTableStruct = 0>
	
	<cftry>
		<cfset arrTableStruct = getDBTableStruct(arguments.tablename)>
		
		<cfloop index="ii" from="1" to="#ArrayLen(arrTableStruct)#" step="1">
			<cfif StructKeyExists(arrTableStruct[ii],"Default") AND Len(arrTableStruct[ii]["Default"])>
				<cfset arrTableStruct[ii]["Default"] = makeDefaultValue(arrTableStruct[ii]["Default"],arrTableStruct[ii].CF_DataType)>
			</cfif>
		</cfloop>
		<cfset addTable(arguments.tablename,arrTableStruct)>
		
		<cfset setCacheDate()>
	<cfcatch>
		<cfif arguments.ErrorOnNotExists>
			<cfrethrow />
		</cfif>
	</cfcatch>
	</cftry>
	
</cffunction>

<cffunction name="loadXML" access="public" returntype="any" output="false" hint="I add tables from XML and optionally create tables/columns as needed (I can also load data to a table upon its creation).">
	<cfargument name="xmldata" type="string" required="yes" hint="XML data of tables and columns to load into DataMgr. Follows schema: http://www.bryantwebconsulting.com/cfcs/DataMgr.xsd">
	<cfargument name="docreate" type="boolean" default="false" hint="I indicate if the table should be created in the database if it doesn't already exist.">
	<cfargument name="addcolumns" type="boolean" default="false" hint="I indicate if missing columns should be be created.">
	
	<cfscript>
	var xmlstring = "";
	var dbtables = "";
	var MyTables = StructNew();
	var varXML = 0;
	var xTables = 0;
	var xData = 0;
	
	var i = 0;
	var j = 0;
	var k = 0;
	var mytable = 0;
	var xTable = 0;
	var sTable = 0;
	var thisTableName = 0;
	var thisField = 0;
	var sFieldDef = 0;
	var aTableNames = 0;
	var sDBTableFields = StructNew();
	
	var tables = "";
	var fields = StructNew();
	var fieldlist = "";
	//var qTest = 0;
	
	var colExists = false;
	//var arrDbTable = 0;
	
	var FailedSQL = "";
	var DBErrs = "";
	var sArgs = 0;
	var sFilter = 0;
	var sTablesFilters = StructNew();
	var sTablesProps = StructNew();
	var key = "";
	
	var sDBTableData = 0;
	</cfscript>
	
	<cfif isSimpleValue(arguments.xmldata)>
		<cfif arguments.xmldata CONTAINS "</tables>">
			<cfset xmlstring = arguments.xmldata>
		<cfelseif FileExists(arguments.xmldata)>
			<cffile action="read" file="#arguments.xmldata#" variable="xmlstring">
		<cfelse>
			<cfset throwDMError("xmldata argument for LoadXML must be a valid XML or a path to a file holding a valid XML string.","LoadFailed")>
		</cfif>
		<cfset varXML = XmlParse(xmlstring,"no")>
	<cfelseif isXmlDoc(arguments.xmldata)>
		<cfset varXML = arguments.xmldata>
	<cfelse>
		<cfset throwDMError("xmldata argument for LoadXML must be a valid XML or a path to a file holding a valid XML string.","LoadFailed")>
	</cfif>
	
	<cfscript>
	xTables = varXML.XmlRoot.XmlChildren;
	xData = XmlSearch(varXML, "//data");
	aTableNames = XmlSearch(varXML, "//table/@name");
	
	for (i=1; i LTE ArrayLen(aTableNames);i=i+1) {
		tables = ListAppend(tables,aTableNames[i].XmlValue);
	}
	</cfscript>
	
	<cfif StructKeyExists(variables,"getDBFieldLists")>
		<cfset sDBTableFields = getDBFieldLists(tables)>
		<cfset dbtables = StructKeyList(sDBTableFields)>
	<cfelse>
		<cftry>
			<cfset dbtables = getDatabaseTablesCache()>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfscript>
	//  Loop over all root elements in XML
	for (i=1; i LTE ArrayLen(xTables);i=i+1) {
		//  If element is a table and has a name, add it to the data
		if ( xTables[i].XmlName EQ "table" AND StructKeyExists(xTables[i].XmlAttributes,"name") ) {
			//temp variable to reference this table
			xTable = xTables[i];
			if ( StructKeyExists(xTables[i],"XmlAttributes") AND StructCount(xTables[i].XmlAttributes) ) {
				sTable = StructNew();
				for ( key in xTables[i].XmlAttributes ) {
					sTable[key] = xTables[i].XmlAttributes[key];
				}
			}
			sTable["filters"] = StructNew();
			//table name
			thisTableName = xTable.XmlAttributes["name"];
			//Add table to list
			tables = ListAppend(tables,thisTableName);
			//introspect table
			if ( ListFindNoCase(dbtables,thisTableName) AND StructKeyExists(xTables[i].XmlAttributes,"introspect") AND isBoolean(xTables[i].XmlAttributes.introspect) AND xTables[i].XmlAttributes.introspect ) {
				loadTable(thisTableName,false);
			}
			//  Only add to struct if table doesn't exist or if cols should be altered
			//if ( NOT StructKeyExists(variables.tables,thisTableName) ) {//arguments.addcolumns OR NOT ( StructKeyExists(variables.tables,thisTableName) OR ListFindNoCase(dbtables,thisTableName) ) 
				//Add to array of tables to add/alter
				if ( NOT StructKeyExists(MyTables,thisTableName) ) {
					MyTables[thisTableName] = ArrayNew(1);
				}
				if ( NOT StructKeyExists(fields,thisTableName) ) {
					fields[thisTableName] = "";
				}
				//  Loop through fields in table
				for (j=1; j LTE ArrayLen(xTable.XmlChildren);j=j+1) {
					//  If this xml tag is a field
					if ( xTable.XmlChildren[j].XmlName EQ "field" OR xTable.XmlChildren[j].XmlName EQ "column" ) {
						thisField = xTable.XmlChildren[j].XmlAttributes;
						sFieldDef = StructNew();
						sFieldDef["tablename"] = thisTableName;
						//If "name" attribute exists, but "ColumnName" att doesn't use name as ColumnName
						if ( StructKeyExists(thisField,"name") AND NOT StructKeyExists(thisField,"ColumnName") ) {
							thisField["ColumnName"] = thisField["name"];
						}
						if ( StructKeyExists(thisField,"ColumnName") ) {
							//Set ColumnName
							sFieldDef["ColumnName"] = thisField["ColumnName"];
							//If "cfsqltype" attribute exists, but "CF_DataType" att doesn't use name as CF_DataType
							if ( StructKeyExists(thisField,"cfsqltype") AND NOT StructKeyExists(thisField,"CF_DataType") ) {
								thisField["CF_DataType"] = thisField["cfsqltype"];
							}
							//Set CF_DataType
							if ( StructKeyExists(thisField,"CF_DataType") ) {
								sFieldDef["CF_DataType"] = thisField["CF_DataType"];
							}
							if ( StructKeyExists(sFieldDef,"CF_DataType") ) {
								//Set PrimaryKey (defaults to false)
								if ( StructKeyExists(thisField,"PrimaryKey") AND isBoolean(thisField["PrimaryKey"]) AND thisField["PrimaryKey"] ) {
									sFieldDef["PrimaryKey"] = true;
								} else {
									sFieldDef["PrimaryKey"] = false;
								}
								//Set AllowNulls (defaults to true)
								if ( StructKeyExists(thisField,"AllowNulls") AND isBoolean(thisField["AllowNulls"]) AND NOT thisField["AllowNulls"] ) {
									sFieldDef["AllowNulls"] = false;
								} else {
									sFieldDef["AllowNulls"] = true;
								}
								//Set length (if it exists and isnumeric)
								if ( StructKeyExists(thisField,"Length") AND isNumeric(thisField["Length"]) AND NOT sFieldDef["CF_DataType"] EQ "CF_SQL_LONGVARCHAR" ) {
									sFieldDef["Length"] = Val(thisField["Length"]);
								} else {
									sFieldDef["Length"] = 0;
								}
								//Set increment (if exists and true)
								if ( StructKeyExists(thisField,"Increment") AND isBoolean(thisField["Increment"]) AND thisField["Increment"] ) {
									sFieldDef["Increment"] = true;
								} else {
									sFieldDef["Increment"] = false;
								}
								//Set precision (if exists and true)
								if ( StructKeyExists(thisField,"Precision") AND isNumeric(thisField["Precision"]) ) {
									sFieldDef["Precision"] = Val(thisField["Precision"]);
								} else {
									sFieldDef["Precision"] = "";
								}
								//Set scale (if exists and true)
								if ( StructKeyExists(thisField,"Scale") AND isNumeric(thisField["Scale"]) ) {
									sFieldDef["Scale"] = Val(thisField["Scale"]);
								} else {
									sFieldDef["Scale"] = "";
								}
							}
							//Set default (if exists)
							if ( StructKeyExists(thisField,"Default") AND Len(thisField["Default"]) ) {
								//sFieldDef["Default"] = makeDefaultValue(thisField["Default"],sFieldDef["CF_DataType"]);
								sFieldDef["Default"] = thisField["Default"];
							//} else {
							//	sFieldDef["Default"] = "";
							}
							//Set Special (if exists)
							if ( StructKeyExists(thisField,"Special") ) {
								sFieldDef["Special"] = Trim(thisField["Special"]);
							}
							if ( StructKeyExists(thisField,"SpecialDateType") ) {
								sFieldDef["SpecialDateType"] = Trim(thisField["SpecialDateType"]);
							}
							if ( StructKeyExists(thisField,"useInMultiRecordsets") AND isBoolean(thisField.useInMultiRecordsets) AND NOT thisField.useInMultiRecordsets ) {
								sFieldDef["useInMultiRecordsets"] = false;
							} else {
								sFieldDef["useInMultiRecordsets"] = true;
							}
							//Set alias (if exists)
							if ( StructKeyHasLen(thisField,"alias") ) {
								sFieldDef["alias"] = Trim(thisField["alias"]);
							}
							if ( StructKeyExists(thisField,"ftable") ) {
								sFieldDef["ftable"] = Trim(thisField["ftable"]);
							}
							//Set relation (if exists)
							if ( ArrayLen(xTable.XmlChildren[j].XmlChildren) EQ 1 AND xTable.XmlChildren[j].XmlChildren[1].XmlName EQ "relation" ) {
								//sFieldDef["Relation"] = expandRelationStruct(xTable.XmlChildren[j].XmlChildren[1].XmlAttributes,sFieldDef);
								sFieldDef["Relation"] = StructFromArgs(xTable.XmlChildren[j].XmlChildren[1].XmlAttributes);
								if ( StructKeyExists(xTable.XmlChildren[j].XmlChildren[1],"filter") ) {
									sFieldDef["Relation"]["filters"] = ArrayNew(1);
									for ( k=1; k LTE ArrayLen(xTable.XmlChildren[j].XmlChildren[1].filter); k=k+1 ) {
										ArrayAppend(sFieldDef["Relation"]["filters"],xTable.XmlChildren[j].XmlChildren[1].filter[k].XmlAttributes);
									}
								}
							}
							//Copy data set in temporary structure to result storage
							if (
										( NOT ListFindNoCase(fields[thisTableName], sFieldDef["ColumnName"]) )
									AND	NOT (
													StructKeyExists(variables.tableprops,thisTableName)
												AND	StructKeyExists(variables.tableprops[thisTableName],"fieldlist")
												AND	ListFindNoCase(variables.tableprops[thisTableName]["fieldlist"], sFieldDef["ColumnName"])
											)
								) {
								fields[thisTableName] = ListAppend(fields[thisTableName],sFieldDef["ColumnName"]);
								ArrayAppend(MyTables[thisTableName], convertColumnAtts(argumentCollection=sFieldDef));
								//MyTables[thisTableName][ArrayLen(MyTables[thisTableName])] = Duplicate(sFieldDef);
							}
						}
					}// /If this xml tag is a field
					//  If this xml tag is a filter
					if ( xTable.XmlChildren[j].XmlName EQ "filter" ) {
						if (
								StructKeyExists(xTable.XmlChildren[j].XmlAttributes,"name") AND Len(Trim(xTable.XmlChildren[j].XmlAttributes["name"]))
							AND	StructKeyExists(xTable.XmlChildren[j].XmlAttributes,"field") AND Len(Trim(xTable.XmlChildren[j].XmlAttributes["field"]))
							AND	StructKeyExists(xTable.XmlChildren[j].XmlAttributes,"operator") AND Len(Trim(xTable.XmlChildren[j].XmlAttributes["operator"]))
						) {
							sFilter = StructNew();
							sFilter["field"] = xTable.XmlChildren[j].XmlAttributes["field"];
							sFilter["operator"] = xTable.XmlChildren[j].XmlAttributes["operator"];
							sTable["filters"][xTable.XmlChildren[j].XmlAttributes["name"]] = sFilter;
						}
					}
				}// /Loop through fields in table
			//}// /Only add to struct if table doesn't exist or if cols should be altered
			sTablesFilters[thisTableName] = sTable["filters"];
			sTablesProps[thisTableName] = sTable;
			StructDelete(sTablesProps[thisTableName],"filters");
		}// /If element is a table and has a name, add it to the data
	}// /Loop over all root elements in XML
	
	//Add tables to DataMgr
	for ( mytable in MyTables ) {
		addTable(mytable,MyTables[mytable],sTablesFilters[mytable],sTablesProps[mytable]);
	}
	
	//Create tables if requested to do so.
	if ( arguments.docreate ) {
		//Try to create the tables, if that fails we'll load up the failed SQL in a variable so it can be returned in a handy lump.
		try {
			CreateTables(tables,dbtables);
		} catch (DataMgr exception) {
			if ( Len(exception.Detail) ) {
				FailedSQL = ListAppend(FailedSQL,exception.Detail,";");
			} else {
				FailedSQL = ListAppend(FailedSQL,exception.Message,";");
			}
			if ( Len(exception.extendedinfo) ) {
				DBErrs = ListAppend(DBErrs,exception.Message,";");
			}
		}
		
	}// if
	</cfscript>
	<cfif Len(FailedSQL)>
		<cfset throwDMError("LoadXML Failed (verify datasource ""#variables.datasource#"" is correct) #DBErrs#","LoadFailed",FailedSQL,DBErrs)>
	</cfif>
	<cfscript>
	//Add columns to tables as needed if requested to do so.
	if ( arguments.addcolumns ) {
		//Loop over tables (from XML)
		for ( mytable in MyTables ) {
			// get list of fields in table
			if ( StructKeyExists(sDBTableFields,mytable) ) {
				fieldlist = sDBTableFields[mytable];
			} else {
				fieldlist = getDBFieldList(mytable);
			}
			//Loop over fields (from XML)
			for ( i=1; i LTE ArrayLen(MyTables[mytable]); i=i+1 ) {
				colExists = false;
				//check for existence of this field
				if ( ListFindNoCase(fieldlist,MyTables[mytable][i].ColumnName) OR StructKeyExists(MyTables[mytable][i],"Relation") OR NOT StructKeyExists(MyTables[mytable][i],"CF_DataType") ) {
					colExists = true;
				}
				//If no match, add column
				if ( NOT colExists ) {
					try {
						sArgs = StructNew();
						sArgs["tablename"] = mytable;
						sArgs["dbfields"] = fieldlist;
						StructAppend(sArgs,MyTables[mytable][i],"no");
						setColumn(argumentCollection=sArgs);
						/*
						sArgs["tablename"] = mytable;
						if ( StructKeyExists(MyTables[mytable][i],"Default") AND Len(MyTables[mytable][i]["Default"]) ) {
							setColumn(mytable,MyTables[mytable][i].ColumnName,MyTables[mytable][i].CF_DataType,MyTables[mytable][i].Length,MyTables[mytable][i]["Default"]);
						} else {
							setColumn(mytable,MyTables[mytable][i].ColumnName,MyTables[mytable][i].CF_DataType,MyTables[mytable][i].Length);
						}
						*/
					} catch (DataMgr exception) {
						FailedSQL = ListAppend(FailedSQL,exception.Detail,";");
					}
				}
			}
		}
	}
	</cfscript>
	<cfif Len(FailedSQL)>
		<cfset throwDMError("LoadXML Failed","LoadFailed",FailedSQL)>
	</cfif>
	
	<cfscript>
	if ( arguments.docreate ) {
		seedData(varXML,tables);
		seedIndexes(varXML);
	}
	</cfscript>
	
	<cfset setCacheDate()>
	
	<cfreturn This>
</cffunction>

<cffunction name="queryparam" access="public" returntype="struct" output="no" hint="I run the given SQL.">
	<cfargument name="cfsqltype" type="string" required="no">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="maxLength" type="string" required="no">
	<cfargument name="scale" type="string" default="0">
	<cfargument name="null" type="boolean" default="no">
	<cfargument name="list" type="boolean" default="no">
	<cfargument name="separator" type="string" default=",">
	
	<cfif NOT StructKeyExists(arguments,"cfsqltype")>
		<cfif StructKeyExists(arguments,"CF_DataType")>
			<cfset arguments["cfsqltype"] = arguments["CF_DataType"]>
		<cfelseif StructKeyExists(arguments,"Relation")>
			<cfif StructKeyExists(arguments.Relation,"CF_DataType")>
				<cfset arguments["cfsqltype"] = arguments.Relation["CF_DataType"]>
			<cfelseif StructKeyExists(arguments.Relation,"table") AND StructKeyExists(arguments.Relation,"field")>
				<cfset arguments["cfsqltype"] = getEffectiveDataType(argumentCollection=arguments)>
			</cfif>
		</cfif>
	</cfif>
	
	<cfif isStruct(arguments.value) AND StructKeyExists(arguments.value,"value")>
		<cfset arguments.value = arguments.value.value>
	</cfif>
	
	<cfif NOT isSimpleValue(arguments.value)>
		<cfset throwDMError("arguments.value must be a simple value","ValueMustBeSimple")>
	</cfif>
	
	<cfif NOT StructKeyExists(arguments,"maxLength")>
		<cfset arguments.maxLength = Len(arguments.value)>
	</cfif>
	
	<cfif StructKeyExists(arguments,"maxLength")>
		<cfset arguments.maxlength = Int(Val(arguments.maxlength))>
		<cfif NOT arguments.maxlength GT 0>
			<cfset arguments.maxlength = Len(arguments.value)>
		</cfif>
		<cfif NOT arguments.maxlength GT 0>
			<cfset arguments.maxlength = 100>
			<cfset arguments.null = "yes">
			<cfset arguments.null = "no">
		</cfif>
	</cfif>
	
	<cfif NOT StructKeyExists(arguments,"null")>
		<cfset arguments.null = "no">
	</cfif>
	
	<cfset arguments.scale = Max(int(val(arguments.scale)),2)>
	
	<cfreturn StructFromArgs(arguments)>
</cffunction>

<cffunction name="removeColumn" access="public" returntype="any" output="false" hint="I remove a column from a table.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	
	<cfset var ii = 0>
	
	<cfif ListFindNoCase(getDBFieldList(arguments.tablename),arguments.field)>
		<cfset runSQL("ALTER TABLE #escape(arguments.tablename)# DROP COLUMN #escape(arguments.field)#")>
	</cfif>
	
	<!--- Reset table properties --->
	<cfset resetTableProps(arguments.tablename)>
	
	<!--- Remove field from internal definition of table --->
	<cfif StructKeyExists(variables.tables,arguments.tablename)>
		<cfloop index="ii" from="1" to="#ArrayLen(variables.tables[arguments.tablename])#">
			<cfif
					StructKeyExists(variables.tables[arguments.tablename][ii],"ColumnName")
				AND	variables.tables[arguments.tablename][ii]["ColumnName"] EQ arguments.field
			>
				<cfset ArrayDeleteAt(variables.tables[arguments.tablename],ii)>
			</cfif>
		</cfloop>
	</cfif>
	
</cffunction>

<cffunction name="removeTable" access="public" returntype="any" output="false" hint="I remove a table.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var ii = 0>
	
	<cfset runSQL("DROP TABLE #escape(arguments.tablename)#")>
	
	<!--- Remove table properties --->
	<cfset StructDelete(variables.tableprops,arguments.tablename)>
	<!--- Remote internal table representation --->
	<cfset StructDelete(variables.tables,arguments.tablename)>
	
</cffunction>

<cffunction name="runSQL" access="public" returntype="any" output="no" hint="I run the given SQL.">
	<cfargument name="sql" type="string" required="yes">
	
	<cfset var qQuery = 0>
	<cfset var thisSQL = "">
	
	<cfif Len(arguments.sql)>
		<cfif StructKeyExists(variables,"username") AND StructKeyExists(variables,"password")>
			<cfquery name="qQuery" datasource="#variables.datasource#" username="#variables.username#" password="#variables.password#">#Trim(DMPreserveSingleQuotes(arguments.sql))#</cfquery>
		<cfelse>
			<cfquery name="qQuery" datasource="#variables.datasource#">#Trim(DMPreserveSingleQuotes(arguments.sql))#</cfquery>
		</cfif>
	</cfif>
	
	<cfif IsDefined("qQuery") AND isQuery(qQuery)>
		<cfreturn qQuery>
	</cfif>
	
</cffunction>

<cffunction name="runSQLArray" access="public" returntype="any" output="no" hint="I run the given array representing SQL code (structures in the array represent params).">
	<cfargument name="sqlarray" type="array" required="yes">
	
	<cfset var qQuery = 0>
	<cfset var ii = 0>
	<cfset var temp = "">
	<cfset var aSQL = cleanSQLArray(arguments.sqlarray)>
	
	<cftry>
		<cfif ArrayLen(aSQL)>
			<cfif StructKeyExists(variables,"username") AND StructKeyExists(variables,"password")>
				<cfquery name="qQuery" datasource="#variables.datasource#" username="#variables.username#" password="#variables.password#"><cfloop index="ii" from="1" to="#ArrayLen(aSQL)#" step="1"><cfif IsSimpleValue(aSQL[ii])><cfset temp = aSQL[ii]>#Trim(DMPreserveSingleQuotes(temp))#<cfelseif IsStruct(aSQL[ii])><cfset aSQL[ii] = queryparam(argumentCollection=aSQL[ii])><cfswitch expression="#aSQL[ii].cfsqltype#"><cfcase value="CF_SQL_BIT">#getBooleanSqlValue(aSQL[ii].value)#</cfcase><cfcase value="CF_SQL_DATE,CF_SQL_DATETIME">#CreateODBCDateTime(aSQL[ii].value)#</cfcase><cfdefaultcase><!--- <cfif ListFindNoCase(variables.dectypes,aSQL[ii].cfsqltype)>#Val(aSQL[ii].value)#<cfelse> ---><cfqueryparam value="#aSQL[ii].value#" cfsqltype="#aSQL[ii].cfsqltype#" maxlength="#aSQL[ii].maxlength#" scale="#aSQL[ii].scale#" null="#aSQL[ii].null#" list="#aSQL[ii].list#" separator="#aSQL[ii].separator#"><!--- </cfif> ---></cfdefaultcase></cfswitch></cfif> </cfloop></cfquery>
			<cfelse>
				<cfquery name="qQuery" datasource="#variables.datasource#"><cfloop index="ii" from="1" to="#ArrayLen(aSQL)#" step="1"><cfif IsSimpleValue(aSQL[ii])><cfset temp = aSQL[ii]>#Trim(DMPreserveSingleQuotes(temp))#<cfelseif IsStruct(aSQL[ii])><cfset aSQL[ii] = queryparam(argumentCollection=aSQL[ii])><cfswitch expression="#aSQL[ii].cfsqltype#"><cfcase value="CF_SQL_BIT">#getBooleanSqlValue(aSQL[ii].value)#</cfcase><cfcase value="CF_SQL_DATE,CF_SQL_DATETIME">#CreateODBCDateTime(aSQL[ii].value)#</cfcase><cfdefaultcase><!--- <cfif ListFindNoCase(variables.dectypes,aSQL[ii].cfsqltype)>#Val(aSQL[ii].value)#<cfelse> ---><cfqueryparam value="#aSQL[ii].value#" cfsqltype="#aSQL[ii].cfsqltype#" maxlength="#aSQL[ii].maxlength#" scale="#aSQL[ii].scale#" null="#aSQL[ii].null#" list="#aSQL[ii].list#" separator="#aSQL[ii].separator#"><!--- </cfif> ---></cfdefaultcase></cfswitch></cfif> </cfloop></cfquery>
			</cfif>
		</cfif>
	<cfcatch>
		<cfthrow message="#CFCATCH.Message#" detail="#CFCATCH.detail#" extendedinfo="#readableSQL(aSQL)#">
	</cfcatch>
	</cftry>
	
	<cfif IsDefined("qQuery") AND isQuery(qQuery)>
		<cfreturn qQuery>
	</cfif>
	
</cffunction>

<cffunction name="readableSQL" access="public" returntype="string" output="no" hint="I return human-readable SQL from a SQL array (not to be sent to the database).">
	<cfargument name="sqlarray" type="array" required="yes">
	
	<cfset var aSQL = cleanSQLArray(arguments.sqlarray)>
	<cfset var ii = 0>
	<cfset var result = "">
	
	<cfloop index="ii" from="1" to="#ArrayLen(aSQL)#" step="1">
		<cfif IsSimpleValue(aSQL[ii])>
			<cfset result = result & " " & aSQL[ii]>
		<cfelseif IsStruct(aSQL[ii])>
			<cfset result = result & " " & "(#aSQL[ii].value#)">
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="setColumn" access="public" returntype="any" output="no" hint="I set a column in the given table">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table to which a column will be added.">
	<cfargument name="columnname" type="string" required="yes" hint="The name of the column to add.">
	<cfargument name="CF_Datatype" type="string" required="no" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Length" type="numeric" default="0" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Default" type="string" required="no" hint="The default value for the column.">
	<cfargument name="Special" type="string" required="no" hint="The special behavior for the column.">
	<cfargument name="Relation" type="struct" required="no" hint="Relationship information for this column.">
	<cfargument name="PrimaryKey" type="boolean" required="no" hint="Indicates whether this column is a primary key.">
	<cfargument name="AllowNulls" type="boolean" default="true">
	<cfargument name="useInMultiRecordsets" type="boolean" default="true">
	
	<cfset var type = "">
	<cfset var sql = "">
	<cfset var FailedSQL = "">
	<cfset var FieldIndex = 0>
	<cfset var aTable = 0>
	
	<cfset var sArgs = convertColumnAtts(argumentCollection=arguments)>
	
	<cfif NOT ( StructKeyExists(arguments,"dbfields") AND Len(arguments.dbfields) )>
		<cfset arguments.dbfields = getDBFieldList(sArgs.tablename)>
	</cfif>
	
	<cfif StructKeyExists(sArgs,"CF_Datatype")>
		<cfif NOT ListFindNoCase(arguments.dbfields,sArgs.columnname)>
			<cfsavecontent variable="sql"><cfoutput>ALTER TABLE #escape(sArgs.tablename)# ADD #sqlCreateColumn(sArgs)#</cfoutput></cfsavecontent>
			<cftry>
				<cfset runSQL(sql)>
				<cfcatch>
					<cfset FailedSQL = ListAppend(FailedSQL,sql,";")>
				</cfcatch>
			</cftry>
			<cfif Len(FailedSQL)>
				<cfset throwDMError(message="Failed to add Column (""#arguments.columnname#"").",detail=FailedSQL)>
			</cfif>
			<cfif StructKeyExists(sArgs,"Default") AND Len(Trim(sArgs.Default))>
				<cfsavecontent variable="sql"><cfoutput>
				UPDATE	#escape(sArgs.tablename)#
				SET		#escape(sArgs.columnname)# = #sArgs.Default#
				WHERE	#escape(sArgs.columnname)# IS NULL
				</cfoutput></cfsavecontent>
			
				<cftry>
					<cfset runSQL(sql)>
					<cfcatch>
						<cfset FailedSQL = ListAppend(FailedSQL,sql,";")>
					</cfcatch>
				</cftry>
			</cfif>
		</cfif>
	</cfif>
	
	<cfset FieldIndex = getColumnIndex(arguments.tablename,arguments.columnname)>
	
	<cfif NOT Len(FailedSQL)>
		<!--- Add the field to DataMgr if DataMgr doesn't know about the field --->
		<cfif NOT FieldIndex>
			<cfset ArrayAppend(variables.tables[arguments.tablename], sArgs)>
			<cfset FieldIndex = ArrayLen(variables.tables[arguments.tablename])>
		</cfif>
		<cfset aTable = variables.tables[arguments.tablename]>
		
		<cfif StructKeyExists(sArgs,"Special") AND Len(sArgs.Special)>
			<cfset aTable[FieldIndex]["Special"] = sArgs.Special>
		</cfif>
		<cfif StructKeyExists(sArgs,"Relation")>
			<!--- If the field exists but a relation is passed, set the relation --->
			<!---<cfset aTable[FieldIndex]["Relation"] = expandRelationStruct(sArgs.Relation,aTable[FieldIndex])>--->
			<cfset aTable[FieldIndex]["Relation"] = sArgs.Relation>
		</cfif>
		<cfif StructKeyExists(sArgs,"PrimaryKey") AND isBoolean(sArgs.PrimaryKey) AND sArgs.PrimaryKey>
			<!--- If the field exists but a primary key is passed, set the primary key --->
			<cfset aTable[FieldIndex]["PrimaryKey"] = true>
		</cfif>
		<cfif StructKeyExists(sArgs,"useInMultiRecordsets") AND isBoolean(sArgs.useInMultiRecordsets)>
			<!--- If the field exists but a primary key is passed, set the primary key --->
			<cfset aTable[FieldIndex]["useInMultiRecordsets"] = sArgs.useInMultiRecordsets>
		</cfif>
	</cfif>
	
	<cfset resetTableProps(arguments.tablename)>
	
</cffunction>

<cffunction name="saveRecord" access="public" returntype="string" output="no" hint="I insert or update a record in the given table (update if a matching record is found) with the provided data and return the primary key of the updated record.">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="fieldlist" type="string" default="" hint="A list of insertable fields. If left blank, any field can be inserted.">
	<cfargument name="truncate" type="boolean" default="false" hint="Should the field values be automatically truncated to fit in the available space for each field?">
	
	<cfreturn insertRecord(arguments.tablename,arguments.data,"update",arguments.fieldlist,arguments.truncate)>
</cffunction>

<cffunction name="saveRelationList" access="public" returntype="void" output="no" hint="I save a many-to-many relationship.">
	<cfargument name="tablename" type="string" required="yes" hint="The table holding the many-to-many relationships.">
	<cfargument name="keyfield" type="string" required="yes" hint="The field holding our key value for relationships.">
	<cfargument name="keyvalue" type="string" required="yes" hint="The value of out primary field.">
	<cfargument name="multifield" type="string" required="yes" hint="The field holding our many relationships for the given key.">
	<cfargument name="multilist" type="string" required="yes" hint="The list of related values for our key.">
	<cfargument name="reverse" type="boolean" default="false" hint="Should the reverse of the relationship by run as well (for self-joins)?s.">
	
	<cfset var bTable = checkTable(arguments.tablename)><!--- Check whether table is loaded --->
	<cfset var getStruct = StructNew()>
	<cfset var setStruct = StructNew()>
	<cfset var qExistingRecords = 0>
	<cfset var item = "">
	<cfset var ExistingList = "">
	
	<!--- Make sure a value is passed in for the primary key value --->
	<cfif NOT Len(Trim(arguments.keyvalue))>
		<cfset throwDMError("You must pass in a value for keyvalue of saveRelationList","NoKeyValueForSaveRelationList")>
	</cfif>
	
	<cfif arguments.reverse>
		<cfinvoke method="saveRelationList">
			<cfinvokeargument name="tablename" value="#arguments.tablename#">
			<cfinvokeargument name="keyfield" value="#arguments.multifield#">
			<cfinvokeargument name="keyvalue" value="#arguments.keyvalue#">
			<cfinvokeargument name="multifield" value="#arguments.keyfield#">
			<cfinvokeargument name="multilist" value="#arguments.multilist#">
		</cfinvoke>
	</cfif>
	
	<!--- Get existing records --->
	<cfset getStruct[arguments.keyfield] = arguments.keyvalue>
	<cfset qExistingRecords = getRecords(arguments.tablename,getStruct)>
	
	<!--- Remove existing records not in list --->
	<cfoutput query="qExistingRecords">
		<cfset ExistingList = ListAppend(ExistingList,qExistingRecords[arguments.multifield][CurrentRow])>
		<cfif NOT ListFindNoCase(arguments.multilist,qExistingRecords[arguments.multifield][CurrentRow])>
			<cfset setStruct = StructNew()>
			<cfset setStruct[arguments.keyfield] = arguments.keyvalue>
			<cfset setStruct[arguments.multifield] = qExistingRecords[arguments.multifield][CurrentRow]>
			<cfset deleteRecords(arguments.tablename,setStruct)>
		</cfif>
	</cfoutput>
	
	<!--- Add records from list that don't exist --->
	<cfloop index="item" list="#arguments.multilist#">
		<cfif isOfType(item,getEffectiveDataType(arguments.tablename,arguments.multifield)) AND NOT ListFindNoCase(ExistingList,item)>
			<cfset setStruct = StructNew()>
			<cfset setStruct[arguments.keyfield] = arguments.keyvalue>
			<cfset setStruct[arguments.multifield] = item>
			<cfset insertRecord(arguments.tablename,setStruct,"skip")>
			<cfset ExistingList = ListAppend(ExistingList,item)><!--- in case list has one item more than once (4/26/06) --->
		</cfif>
	</cfloop>
	
	<cfset setCacheDate()>
	
</cffunction>

<cffunction name="saveSortOrder" access="public" returntype="void" output="no" hint="I save the sort order of records - putting them in the same order as the list of primary key values.">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="sortfield" type="string" required="yes" hint="The field holding the sort order.">
	<cfargument name="sortlist" type="string" required="yes" hint="The list of primary key field values in sort order.">
	<cfargument name="PrecedingRecords" type="numeric" default="0" hint="The number of records preceding those being sorted.">
	
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var ii = 0>
	<cfset var keyval = 0>
	<cfset var sqlarray = ArrayNew(1)>
	<cfset var sqlStatements = "">
	
	<cfset arguments.PrecedingRecords = Int(arguments.PrecedingRecords)>
	<cfif arguments.PrecedingRecords LT 0>
		<cfset arguments.PrecedingRecords = 0>
	</cfif>
	
	<cfif ArrayLen(pkfields) NEQ 1>
		<cfset throwDMError("This method can only be used on tables with exactly one primary key field.","SortWithOneKey")>
	</cfif>
	
	<cfloop index="ii" from="1" to="#ListLen(arguments.sortlist)#" step="1">
		<cfset keyval = ListGetAt(arguments.sortlist,ii)>
		<cfset sqlarray = ArrayNew(1)>
		<cfset ArrayAppend(sqlarray,"UPDATE	#escape(arguments.tablename)#")>
		<cfset ArrayAppend(sqlarray,"SET		#escape(arguments.sortfield)# = #Val(ii)+arguments.PrecedingRecords#")>
		<cfset ArrayAppend(sqlarray,"WHERE	#escape(pkfields[1].ColumnName)# = ")>
		<cfset ArrayAppend(sqlarray,sval(pkfields[1],keyval))>
		<cfset runSQLArray(sqlarray)>
		<cfset sqlStatements = ListAppend(sqlStatements,readableSQL(sqlarray),";")>
	</cfloop>
	
	<cfif variables.doLogging AND ListLen(arguments.sortlist)>
		<cfinvoke method="logAction">
			<cfinvokeargument name="tablename" value="#arguments.tablename#">
			<cfinvokeargument name="action" value="sort">
			<cfinvokeargument name="data" value="#arguments#">
			<cfinvokeargument name="sql" value="#sqlStatements#">
		</cfinvoke>
	</cfif>
	
	<cfset setCacheDate()>
	
</cffunction>

<cffunction name="logAction" access="public" returntype="any" output="no" hint="I log an action in the database.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="pkval" type="string" required="no">
	<cfargument name="action" type="string" required="yes">
	<cfargument name="data" type="struct" required="no">
	<cfargument name="sql" type="any" required="no">
	
	<cfif NOT arguments.tablename EQ variables.logtable>
		
		<cfif StructKeyExists(arguments,"data")>
			<cfwddx action="CFML2WDDX" input="#arguments.data#" output="arguments.data">
		</cfif>
		
		<cfif StructKeyExists(arguments,"sql")>
			<cfif isSimpleValue(arguments.sql)>
				<cfset arguments.sql = arguments.sql>
			<cfelseif isArray(arguments.sql)>
				<cfset arguments.sql = readableSQL(arguments.sql)>
			<cfelse>
				<cfset throwDMError("The sql argument logAction method must be a string of SQL code or a DataMgr SQL Array.","LogActionSQLDataType")>
			</cfif>
		</cfif>
		
		<cfset insertRecord(variables.logtable,arguments)>
	</cfif>
	
</cffunction>

<cffunction name="setNamedFilter" access="public" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="operator" type="string" required="yes">
	
	<cfset variables.tableprops[arguments.tablename]["filters"][arguments.name] = StructNew()>
	<cfset variables.tableprops[arguments.tablename]["filters"][arguments.name]["field"] = arguments.field>
	<cfset variables.tableprops[arguments.tablename]["filters"][arguments.name]["operator"] = arguments.operator>
	
</cffunction>

<cffunction name="startLogging" access="public" returntype="void" output="no" hint="I turn on logging.">
	<cfargument name="logtable" type="string" default="#variables.logtable#">
	
	<cfset var dbxml = "">
	
	<cfset variables.doLogging = true>
	<cfset variables.logtable = arguments.logtable>
	
	<cfsavecontent variable="dbxml"><cfoutput>
	<tables>
		<table name="#variables.logtable#">
			<field ColumnName="LogID" CF_DataType="CF_SQL_INTEGER" PrimaryKey="true" Increment="true" />
			<field ColumnName="tablename" CF_DataType="CF_SQL_VARCHAR" Length="180" />
			<field ColumnName="pkval" CF_DataType="CF_SQL_VARCHAR" Length="250" />
			<field ColumnName="action" CF_DataType="CF_SQL_VARCHAR" Length="60" />
			<field ColumnName="DatePerformed" CF_DataType="CF_SQL_DATE" Special="CreationDate" />
			<field ColumnName="data" CF_DataType="CF_SQL_LONGVARCHAR" />
			<field ColumnName="sql" CF_DataType="CF_SQL_LONGVARCHAR" />
		</table>
	</tables>
	</cfoutput></cfsavecontent>
	
	<cfset loadXML(dbxml,true,true)>
	
</cffunction>

<cffunction name="stopLogging" access="public" returntype="void" output="no" hint="I turn off logging.">
	<cfset variables.doLogging = false>
</cffunction>

<cffunction name="truncate" access="public" returntype="struct" output="no" hint="I return the structure with the values truncated to the limit of the fields in the table.">
	<cfargument name="tablename" type="string" required="yes" hint="The table for which to truncate data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	
	<cfscript>
	var bTable = checkTable(arguments.tablename);//Check whether table is loaded
	var sTables = getTableData();
	var aColumns = sTables[arguments.tablename];
	var ii = 0;
	
	for ( ii=1; ii LTE ArrayLen(aColumns); ii=ii+1 ) {
		if ( StructKeyExists(arguments.data,aColumns[ii].ColumnName) ) {
			if ( StructKeyExists(aColumns[ii],"Length") AND aColumns[ii].Length AND aColumns[ii].CF_DataType NEQ "CF_SQL_LONGVARCHAR" ) {
				arguments.data[aColumns[ii].ColumnName] = Left(arguments.data[aColumns[ii].ColumnName],aColumns[ii].Length);
			}
		}
	}
	</cfscript>
	
	<cfreturn arguments.data>
</cffunction>

<cffunction name="updateRecord" access="public" returntype="string" output="no" hint="I update a record in the given table with the provided data and return the primary key of the updated record.">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="advsql" type="struct" hint="A structure of sqlarrays for each area of a query (SET,WHERE).">
	<cfargument name="truncate" type="boolean" default="false" hint="Should the field values be automatically truncated to fit in the available space for each field?">
	<cfargument name="fieldlist" type="string" default="" hint="A list of updateable fields. If left blank, any field can be updated.">
	
	<cfset var bTable = checkTable(arguments.tablename)>
	<cfset var ii = 0><!--- generic counter --->
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var in = clean(arguments.data)><!--- holds incoming data for ease of use --->
	<cfset var qGetUpdateRecord = 0><!--- used to check for existing record --->
	<cfset var temp = "">
	<cfset var result = 0>
	<cfset var sqlarray = ArrayNew(1)>
	
	<cfif arguments.truncate>
		<cfset in = variables.truncate(arguments.tablename,in)>
	</cfif>
	
	<cfif NOT ArrayLen(pkfields)>
		<cfset throwDMError("#arguments.tablename# has no primary key fields. updateRecord and saveRecord can only be called on tables with primary key fields. Use updateRecords or insertRecord (without OnExists of 'update' or 'save') instead.","NoPkFields")>
	</cfif>
	
	<!--- Check for existing record --->
	<cfset sqlarray = ArrayNew(1)>
	<cfset ArrayAppend(sqlarray,"SELECT	#escape(pkfields[1].ColumnName)#")>
	<cfset ArrayAppend(sqlarray,"FROM	#escape(arguments.tablename)#")>
	<cfset ArrayAppend(sqlarray,"WHERE	1 = 1")>
	<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfset ArrayAppend(sqlarray,"AND	#escape(pkfields[ii].ColumnName)# = ")>
		<cfset ArrayAppend(sqlarray,sval(pkfields[ii],in))>
	</cfloop>
	<cfset qGetUpdateRecord = runSQLArray(sqlarray)>
	
	<!--- Make sure record exists to update --->
	<cfif NOT qGetUpdateRecord.RecordCount>
		<cfset temp = "">
		<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
			<cfset temp = ListAppend(temp,"#escape(pkfields[ii].ColumnName)#=#in[pkfields[ii].ColumnName]#")>
		</cfloop>
		<cfset throwDMError("No record exists for update criteria (#temp#).","NoUpdateRecord")>
	</cfif>
	
	<cfset sqlarray = updateRecordSQL(argumentCollection=arguments)>
	
	<cfif ArrayLen(sqlarray)>
		<cfset runSQLArray(sqlarray)>
	</cfif>
	
	<cfset result = qGetUpdateRecord[pkfields[1].ColumnName][1]>
	
	<!--- set pkfield so that we can save relation data --->
	<cfset in[pkfields[1].ColumnName] = result>
	
	<!--- Save any relations --->
	<cfset saveRelations(arguments.tablename,in,pkfields[1],result)>
	
	<!--- Log update --->
	<cfif variables.doLogging AND NOT arguments.tablename EQ variables.logtable>
		<cfinvoke method="logAction">
			<cfinvokeargument name="tablename" value="#arguments.tablename#">
			<cfinvokeargument name="pkval" value="#result#">
			<cfinvokeargument name="action" value="update">
			<cfinvokeargument name="data" value="#in#">
			<cfinvokeargument name="sql" value="#sqlarray#">
		</cfinvoke>
	</cfif>
	
	<cfset setCacheDate()>
	
	<cfreturn result>
</cffunction>

<cffunction name="updateRecordSQL" access="public" returntype="array" output="no" hint="I update a record in the given table with the provided data and return the primary key of the updated record.">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="fieldlist" type="string" default="" hint="A list of updateable fields. If left blank, any field can be updated.">
	<cfargument name="advsql" type="struct" default="#StructNew()#" hint="A structure of sqlarrays for each area of a query (SET,WHERE).">
	
	<cfset var bTable = checkTable(arguments.tablename)>
	<cfset var fields = getUpdateableFields(arguments.tablename)>
	<cfset var ii = 0><!--- generic counter --->
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var in = clean(arguments.data)><!--- holds incoming data for ease of use --->
	<cfset var data_set = StructNew()>
	<cfset var data_where = StructNew()>
	
	<cfset in = getRelationValues(arguments.tablename,in)>
	
	<!--- This method requires at least on primary key --->
	<cfif NOT ArrayLen(pkfields)>
		<cfset throwDMError("his method can only be used on tables with at least one primary key field.","NeedPKField")>
	</cfif>
	<!--- All primary key values must be provided --->
	<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif NOT StructKeyExists(in,pkfields[ii].ColumnName)>
			<cfset throwDMError("All Primary Key fields must be used when updating a record.","RequiresAllPkFields")>
		</cfif>
		<cfset data_where[pkfields[ii].ColumnName] = in[pkfields[ii].ColumnName]>
	</cfloop>
	<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif StructKeyExists(in,fields[ii].ColumnName)>
			<cfset data_set[fields[ii].ColumnName] = in[fields[ii].ColumnName]>
		</cfif>
	</cfloop>
	
	<cfreturn updateRecordsSQL(tablename=arguments.tablename,data_set=data_set,data_where=data_where,fieldlist=arguments.fieldlist,advsql=arguments.advsql)>
</cffunction>

<cffunction name="updateRecords" access="public" returntype="void" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="data_set" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="data_where" type="struct" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="filters" type="array" default="#ArrayNew(1)#">
	<cfargument name="fieldlist" type="string" default="" hint="A list of updateable fields. If left blank, any field can be updated.">
	<cfargument name="advsql" type="struct" default="#StructNew()#" hint="A structure of sqlarrays for each area of a query (SET,WHERE).">
	
	<cfset var sqlarray = updateRecordsSQL(argumentCollection=arguments)>
	
	<cfif ArrayLen(sqlarray)>
		<cfset runSQLArray(sqlarray)>
	</cfif>
	
	<cfset setCacheDate()>
	
</cffunction>

<cffunction name="updateRecordsSQL" access="public" returntype="array" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="data_set" type="struct" default="#StructNew()#" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="data_where" type="struct" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="filters" type="array" default="#ArrayNew(1)#">
	<cfargument name="fieldlist" type="string" default="" hint="A list of updateable fields. If left blank, any field can be updated.">
	<cfargument name="advsql" type="struct" default="#StructNew()#" hint="A structure of sqlarrays for each area of a query (SET,WHERE).">
	
	<cfset var bTable = checkTable(arguments.tablename)>
	<cfset var fields = getUpdateableFields(arguments.tablename)>
	<cfset var ii = 0><!--- generic counter --->
	<cfset var fieldcount = 0><!--- number of fields --->
	<cfset var in = clean(arguments.data_set)><!--- holds incoming data for ease of use --->
	<cfset var sqlarray = ArrayNew(1)>
	<cfset var Specials = "LastUpdatedDate">
	
	<cfif NOT StructKeyExists(arguments,"data_where")>
		<cfset arguments.data_where = StructNew()>
	</cfif>
	
	<!--- Restrict data to fieldlist --->
	<cfif Len(Trim(arguments.fieldlist))>
		<cfloop item="ii" collection="#in#">
			<cfif NOT ListFindNoCase(arguments.fieldlist,ii)>
				<cfset StructDelete(in,ii)>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfset in = getRelationValues(arguments.tablename,in)>
	
	<!--- Throw exception on any attempt to update a table with no updateable fields --->
	<cfif NOT ArrayLen(fields)>
		<cfset throwDMError("This table does not have any updateable fields.","NoUpdateableFields")>
	</cfif>
	
	<cfset ArrayAppend(sqlarray,"UPDATE	#escape(arguments.tablename)#")>
	<cfset ArrayAppend(sqlarray,"SET")>
	<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif useField(in,fields[ii])><!--- Include update if this is valid data --->
			<cfset checkLength(fields[ii],in[fields[ii].ColumnName])>
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")>
			</cfif>
			<cfset ArrayAppend(sqlarray,"#escape(fields[ii].ColumnName)# = ")>
			<cfset ArrayAppend(sqlarray,sval(fields[ii],in))>
		<cfelseif isBlankValue(in,fields[ii])><!--- Or if it is passed in as empty value and null are allowed --->
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")>
			</cfif>
			<cfif StructKeyExists(fields[ii],"AllowNulls") AND isBoolean(fields[ii].AllowNulls) AND NOT fields[ii].AllowNulls>
				<cfset ArrayAppend(sqlarray,"#escape(fields[ii].ColumnName)# = ''")>
			<cfelse>
				<cfset ArrayAppend(sqlarray,"#escape(fields[ii].ColumnName)# = NULL")>
			</cfif>
		<cfelseif StructKeyExists(fields[ii],"Special") AND Len(fields[ii].Special) AND ListFindNoCase(Specials,fields[ii].Special)>
			<cfif fields[ii]["Special"] EQ "LastUpdatedDate">
				<cfset fieldcount = fieldcount + 1>
				<cfif fieldcount GT 1>
					<cfset ArrayAppend(sqlarray,",")>
				</cfif>
				<cfset ArrayAppend(sqlarray,"#escape(fields[ii].ColumnName)# = ")>
				<cfset ArrayAppend(sqlarray,getFieldNowValue(arguments.tablename,fields[ii]))>
			</cfif>
		</cfif>
	</cfloop>
	<cfif StructKeyExists(arguments,"advsql") AND StructKeyExists(arguments.advsql,"SET")>
		<cfif fieldcount>
			<cfset ArrayAppend(sqlarray,",")><cfset colnum = colnum + 1>
		</cfif>
		<cfset fieldcount = fieldcount + 1>
		<cfset ArrayAppend(sqlarray,arguments.advsql["SET"])>
	</cfif>
	<!---<cfif fieldcount EQ 0>
		<cfthrow message="You must include at least one field to be updated (passed fields = '#StructKeyList(in)#')." type="DataMgr">
	</cfif>--->
	<!--- <cfset fieldcount = 0> --->
	<cfset ArrayAppend(sqlarray,"WHERE	1 = 1")>
	<cfset ArrayAppend(sqlarray,getWhereSQL(tablename=arguments.tablename,data=arguments.data_where,filters=arguments.filters))>
	<cfif fieldcount>
		<cfset fieldcount = 0>
	<cfelse>
		<cfset sqlarray = ArrayNew(1)>
	</cfif>
	
	<cfreturn sqlarray>
</cffunction>

<cffunction name="addColumn" access="public" returntype="any" output="no" hint="I add a column to the given table (deprecated in favor of setColumn).">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table to which a column will be added.">
	<cfargument name="columnname" type="string" required="yes" hint="The name of the column to add.">
	<cfargument name="CF_Datatype" type="string" required="no" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Length" type="numeric" default="50" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Default" type="string" required="no" hint="The default value for the column.">
	
	<cfset setColumn(argumentCollection=arguments)>
	
</cffunction>

<cffunction name="addTable" access="private" returntype="boolean" output="no" hint="I add a table to the Data Manager.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fielddata" type="array" required="yes">
	<cfargument name="filters" type="struct" required="no">
	<cfargument name="props" type="struct" required="no">
	
	<cfset var isTableAdded = false>
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var hasField = false>
	
	<cfif StructKeyExists(variables.tables,arguments.tablename)>
		<!--- If the table exists, add new columns --->
		<cfloop index="i" from="1" to="#ArrayLen(arguments.fielddata)#" step="1">
			<cfset hasField = false>
			<cfloop index="j" from="1" to="#ArrayLen(variables.tables[arguments.tablename])#" step="1">
				<cfif arguments.fielddata[i]["ColumnName"] EQ variables.tables[arguments.tablename][j]["ColumnName"]>
					<cfset hasField = true>
					<cfset variables.tables[arguments.tablename][j] = arguments.fielddata[i]>
				</cfif>
			</cfloop>
			<cfif NOT hasField>
				<cfset ArrayAppend(variables.tables[arguments.tablename],arguments.fielddata[i])>
			</cfif>
		</cfloop>
	<cfelse>
		<!--- If the table doesn't exist, just add it as given --->
		<cfset variables.tables[arguments.tablename] = arguments.fielddata>
	</cfif>
	
	<cfset resetTableProps(arguments.tablename)>
	
	<cfif StructKeyExists(arguments,"filters") AND StructCount(arguments.filters)>
		<cfset StructAppend(variables.tableprops[arguments.tablename]["filters"],arguments.filters,true)>
	</cfif>
	
	<cfif StructKeyExists(arguments,"props") AND StructCount(arguments.props)>
		<cfset setTableProps(arguments.tablename,arguments.props)>
	</cfif>
	
	<cfset isTableAdded = true>
	
	<cfset setCacheDate()>
	
	<cfreturn isTableAdded>
</cffunction>

<cffunction name="adjustColumnArgs" access="private" returntype="any" output="false" hint="">
	<cfargument name="args" type="struct" required="yes">
	
	<cfset var sArgs = StructCopy(arguments.args)>
	
	<!--- Require ColumnName --->
	<cfif NOT ( StructKeyExists(sArgs,"ColumnName") AND Len(Trim(sArgs.ColumnName)) )>
		<cfset throwDMError("ColumnName is required")>
	</cfif>
	<!--- Require CF_Datatype --->
	<cfif NOT ( StructKeyExists(sArgs,"CF_Datatype") AND Len(Trim(sArgs.CF_Datatype)) GT 7 AND Left(sArgs.CF_Datatype,7) EQ "CF_SQL_" )>
		<cfset throwDMError("CF_Datatype is required")>
	</cfif>
	<cfif NOT ( StructKeyExists(sArgs,"Length") AND isNumeric(sArgs.Length) AND Int(sArgs.Length) GT 0 )>
		<cfset sArgs.Length = 255>
	</cfif>
	<cfif NOT isStringType(getDBDataType(sArgs.CF_DataType))>
		<cfset StructDelete(sArgs,"Length")>
	</cfif>
	<cfif NOT ( StructKeyExists(sArgs,"PrimaryKey") AND isBoolean(sArgs.PrimaryKey) )>
		<cfset sArgs.PrimaryKey = false>
	</cfif>
	<cfif NOT ( StructKeyExists(sArgs,"Increment") AND isBoolean(sArgs.Increment) )>
		<cfset sArgs.Increment = false>
	</cfif>
	<cfif NOT ( StructKeyExists(sArgs,"Default") )>
		<cfset sArgs.Default = "">
	</cfif>
	<cfif NOT ( StructKeyExists(sArgs,"Special") )>
		<cfset sArgs.Special = "">
	</cfif>
	<cfif NOT ( StructKeyExists(sArgs,"useInMultiRecordsets") )>
		<cfset sArgs.useInMultiRecordsets = true>
	</cfif>
	<cfif NOT ( StructKeyExists(sArgs,"AllowNulls") AND isBoolean(sArgs.AllowNulls) )>
		<cfset sArgs.AllowNulls = true>
	</cfif>
	<cfif StructKeyExists(sArgs,"Length")>
		<cfset sArgs.Length = Int(sArgs.Length)>
	</cfif>
	<cfif StructKeyExists(sArgs,"precision") OR StructKeyExists(sArgs,"scale")>
		<cfif NOT ( StructKeyExists(sArgs,"precision") AND Val(sArgs.precision) NEQ 0 )>
			<cfset sArgs.precision = 12>
		</cfif>
		<cfif NOT ( StructKeyExists(sArgs,"scale") AND Val(sArgs.scale) NEQ 0 )>
			<cfset sArgs.scale = 2>
		</cfif>
	</cfif>
	
	<cfreturn sArgs>
</cffunction>

<cffunction name="applyListRelations" access="public" returntype="query" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="query" type="query" required="yes">

	<cfset var qRecords = arguments.query>
	<cfset var rfields = getRelationFields(arguments.tablename)><!--- relation fields in table --->
	<cfset var i = 0><!--- Generic counter --->
	<cfset var hasLists = false>
	<cfset var qRelationList = 0>
	<cfset var temp = 0>
	
	<!--- Check for list values in recordset --->
	<cfloop index="i" from="1" to="#ArrayLen(rfields)#" step="1">
		<cfif ListFindNoCase(qRecords.ColumnList,rfields[i].ColumnName)>
			<cfif rfields[i].Relation.type EQ "list">
				<cfset hasLists = true>
			</cfif>
		</cfif>
	</cfloop>
	
	<!--- Get list values --->
	<cfif hasLists>
		<cfloop query="qRecords">
			<cfloop index="i" from="1" to="#ArrayLen(rfields)#" step="1">
				<cfif rfields[i].Relation["type"] EQ "list" AND ListFindNoCase(qRecords.ColumnList,rfields[i].ColumnName)>
					<cfset fillOutJoinTableRelations(arguments.tablename)>
					<cfset temp = StructNew()>
					<cfset temp.tablename = rfields[i].Relation["table"]>
					<cfset temp.fieldlist = rfields[i].Relation["field"]>
					<cfif StructKeyExists(rfields[i].Relation,"distinct") AND rfields[i].Relation["distinct"] EQ true>
						<cfset temp.distinct = true>
						<cfset temp["sortfield"] = rfields[i].Relation["field"]>
					</cfif>
					<cfset temp.advsql = StructNew()>
					<cfif StructKeyExists(rfields[i].Relation,"sort-field")>
						<cfset temp["sortfield"] = rfields[i].Relation["sort-field"]>
						<cfif StructKeyExists(rfields[i].Relation,"sort-dir")>
							<cfset temp["sortdir"] = rfields[i].Relation["sort-dir"]>
						</cfif>
					</cfif>
					
					<cfset temp.filters = ArrayNew(1)>
					<cfif StructKeyExists(rfields[i].Relation,"filters")>
						<cfset temp.filters = rfields[i].Relation["filters"]>
					</cfif>
					<cfif StructKeyExists(rfields[i].Relation,"join-table")>
						<cfset temp.join = StructNew()>
						<cfset temp.join["table"] = rfields[i].Relation["join-table"]>
						<cfset temp.join["onleft"] = rfields[i].Relation["remote-table-join-field"]>
						<cfset temp.join["onright"] = rfields[i].Relation["join-table-field-remote"]>
						<!--- Use filters for extra join fielter --->
						<cfset ArrayAppend(temp.filters,StructNew())>
						<cfset temp.filters[ArrayLen(temp.filters)].table = rfields[i].Relation["join-table"]>
						<cfset temp.filters[ArrayLen(temp.filters)].field = rfields[i].Relation["join-table-field-local"]>
						<cfset temp.filters[ArrayLen(temp.filters)].operator = "=">
						<cfset temp.filters[ArrayLen(temp.filters)].value = qRecords[rfields[i].ColumnName][CurrentRow]>
					<cfelse>
						<!--- Use filters for extra join fielter --->
						<cfset ArrayAppend(temp.filters,StructNew())>
						<cfset temp.filters[ArrayLen(temp.filters)].table = rfields[i].Relation["table"]>
						<cfset temp.filters[ArrayLen(temp.filters)].field = rfields[i].Relation["join-field-remote"]>
						<cfset temp.filters[ArrayLen(temp.filters)].operator = "=">
						<cfset temp.filters[ArrayLen(temp.filters)].value = qRecords[rfields[i].ColumnName][CurrentRow]>
					</cfif>
					<cfset qRelationList = getRecords(argumentCollection=temp)>
					
					<cfset temp = "">
					<cfoutput query="qRelationList">
						<cfif Len(qRelationList[rfields[i].Relation["field"]][CurrentRow])>
							<cfif StructKeyExists(rfields[i].Relation,"delimiter")>
								<cfset temp = ListAppend(temp,qRelationList[rfields[i].Relation["field"]][CurrentRow],rfields[i].Relation["delimiter"])>
							<cfelse>
								<cfset temp = ListAppend(temp,qRelationList[rfields[i].Relation["field"]][CurrentRow])>
							</cfif>
						</cfif>
					</cfoutput>
					<cfset QuerySetCell(qRecords, rfields[i].ColumnName, temp, CurrentRow)>
					
				</cfif>
			</cfloop>
		</cfloop>
	</cfif>
	
	<cfreturn qRecords>
</cffunction>

<cffunction name="convertColumnAtts" access="private" returntype="struct" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table to which a column will be added.">
	<cfargument name="columnname" type="string" required="yes" hint="The name of the column to add.">
	<cfargument name="CF_Datatype" type="string" required="no" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Length" type="numeric" default="0" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Default" type="string" required="no" hint="The default value for the column.">
	<cfargument name="Special" type="string" required="no" hint="The special behavior for the column.">
	<cfargument name="Relation" type="struct" required="no" hint="Relationship information for this column.">
	<cfargument name="PrimaryKey" type="boolean" required="no" hint="Indicates whether this column is a primary key.">
	<cfargument name="AllowNulls" type="boolean" default="true">
	<cfargument name="useInMultiRecordsets" type="boolean" default="true">
	
	<!--- Default length to 255 (only used for text types) --->
	<cfif arguments.Length EQ 0 AND StructKeyExists(arguments,"CF_Datatype")>
		<cfset arguments.Length = 255>
	</cfif>
	
	<cfif StructKeyExists(arguments,"CF_Datatype")>
		<cfset arguments.CF_Datatype = UCase(arguments.CF_Datatype)>
		<cfscript>
		//Set default (if exists)
		if ( StructKeyExists(arguments,"Default") AND Len(arguments["Default"]) ) {
			arguments["Default"] = makeDefaultValue(arguments["Default"],arguments["CF_DataType"]);
		}
		//Set Special (if exists)
		if ( StructKeyExists(arguments,"Special") ) {
			arguments["Special"] = Trim(arguments["Special"]);
			//Sorter or DeletionMark should default to zero/false
			if (  NOT StructKeyExists(arguments,"Default") ) {
				if ( arguments["Special"] EQ "Sorter" OR ( arguments["Special"] EQ "DeletionMark" AND arguments["CF_Datatype"] EQ "CF_SQL_BOOLEAN" ) ) {
					arguments["Default"] = makeDefaultValue(0,arguments["CF_DataType"]);
				}
				if ( arguments["Special"] EQ "CreationDate" OR arguments["Special"] EQ "LastUpdatedDate" ) {
					arguments["Default"] = getNowSQL();
				}
			}
		} else {
			arguments["Special"] = "";
		}
		</cfscript>
	</cfif>
	
	<cfreturn StructFromArgs(arguments)>
</cffunction>

<cffunction name="getComparatorSQL" access="private" returntype="array" output="no">
	<cfargument name="value" type="string" required="true">
	<cfargument name="cfsqltype" type="string" required="true">
	<cfargument name="operator" type="string" default="=">
	<cfargument name="nullable" type="boolean" default="true">
	
	<cfset var aSQL = ArrayNew(1)>
	<cfset var inops = "IN,NOT IN">
	<cfset var posops = "=,IN,LIKE,>,>=">
	
	<cfif Len(Trim(arguments.value)) OR NOT arguments.nullable>
		<cfif ListFindNoCase(inops,arguments.operator)>
			<cfset ArrayAppend(aSQL," #arguments.operator# (")>
			<cfset ArrayAppend(aSQL,queryparam(cfsqltype=arguments.cfsqltype,value=arguments.value,list=true))>
			<cfset ArrayAppend(aSQL," )")>
		<cfelse>
			<cfset ArrayAppend(aSQL," #arguments.operator#")>
			<cfset ArrayAppend(aSQL,queryparam(arguments.cfsqltype,arguments.value))>
		</cfif>
	<cfelse>
		<cfif ListFindNoCase(posops,arguments.operator)>
			<cfset ArrayAppend(aSQL," IS")>
		<cfelse>
			<cfset ArrayAppend(aSQL," IS NOT")>
		</cfif>
		<cfset ArrayAppend(aSQL," NULL")>
	</cfif>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="getDatabaseTablesCache" access="public" returntype="string" output="no" hint="I get a list of all tables in the current database.">
	
	<cfif NOT StructKeyExists(variables,"cache_dbtables")>
		<cfset variables.cache_dbtables = getDatabaseTables()>
	</cfif>
	
	<cfreturn variables.cache_dbtables>
</cffunction>

<cffunction name="getDefaultOrderBySQL" access="private" returntype="array" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="tablealias" type="string" required="yes">
	<cfargument name="fieldlist" type="string" default="">
	
	<cfset var aResults = ArrayNew(1)>
	<cfset var fields = getUpdateableFields(arguments.tablename)><!--- non primary-key fields in table --->
	<cfset var pkfields = getPKFields(arguments.tablename)><!--- primary key fields in table --->
	<cfset var ii = 0>
	
	<cfif ArrayLen(pkfields) AND pkfields[1].CF_DataType EQ "CF_SQL_INTEGER" AND ( ListFindNoCase(arguments.fieldlist,pkfields[1].ColumnName) OR NOT Len(arguments.fieldlist) )>
		<cfset ArrayAppend(aResults,getFieldSelectSQL(arguments.tablename,pkfields[1].ColumnName,arguments.tablealias,false))>
	<cfelseif Len(arguments.fieldlist)>
		<cfset ArrayAppend(aResults,getOrderbyFieldList(argumentCollection=arguments))>
	<cfelseif ArrayLen(pkfields)>
		<cfset ArrayAppend(aResults,getFieldSelectSQL(arguments.tablename,pkfields[1].ColumnName,arguments.tablealias,false))>
	<cfelse>
		<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
			<cfif fields[ii].CF_DataType NEQ "CF_SQL_LONGVARCHAR">
				<cfset ArrayAppend(aResults,getFieldSelectSQL(arguments.tablename,fields[ii].ColumnName,arguments.tablealias,false))>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfif Len(arguments.function)>
		<cfset ArrayPrepend(aResults,"#arguments.function#(")>
		<cfset ArrayAppend(aResults,")")>
	</cfif>
	
	<cfreturn aResults>
</cffunction>

<cffunction name="getFieldNowValue" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="sField" type="struct" required="yes">
	
	<cfset var result = "">
	<cfset var type = getSpecialDateType(arguments.tablename,arguments.sField)>
	
	<cfswitch expression="#type#">
	<cfcase value="DB,SQL">
		<cfset result = getNowSQL()>
	</cfcase>
	<cfcase value="UTC">
		<cfset result = sval(arguments.sField,DateAdd('s', GetTimezoneInfo().utcTotalOffset, now()))>
	</cfcase>
	<cfdefaultcase>
		<cfset result = sval(arguments.sField,now())>
	</cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFTableFields" access="private" returntype="struct" output="no">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var aFields = 0>
	<cfset var ii = 0>
	<cfset var sResult = 0>
	
	<cfif StructKeyExists(variables.tableprops,arguments.tablename)>
		<cfif NOT StructKeyExists(variables.tableprops[arguments.tablename],"ftablekeys")>
			<cfset variables.tableprops[arguments.tablename]["ftablekeys"] = StructNew()>
			<cfset aFields = getFields(arguments.tablename)>
			<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
				<cfif StructKeyExists(aFields[ii],"ftable")>
					<cfset variables.tableprops[arguments.tablename]["ftablekeys"][aFields[ii].ftable] = aFields[ii].ColumnName>
				</cfif>
			</cfloop>
		</cfif>
		<cfset sResult = variables.tableprops[arguments.tablename]["ftablekeys"]>
	<cfelse>
		<cfset sResult = StructNew()>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="getSpecialDateType" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="sField" type="struct" required="yes">
	
	<cfset var result = "CF">
	<cfset var validtypes = "CF,UTC,DB,SQL">
	
	<cfif StructKeyExists(sField,"SpecialDateType") AND ListFindNoCase(validtypes,sField.SpecialDateType)>
		<cfset result = sField.SpecialDateType>
	<cfelseif StructKeyExists(variables.tableprops[arguments.tablename],"SpecialDateType") AND ListFindNoCase(validtypes,variables.tableprops[arguments.tablename].SpecialDateType)>
		<cfset result = variables.tableprops[arguments.tablename].SpecialDateType>
	<cfelseif StructKeyExists(variables,"SpecialDateType") AND ListFindNoCase(validtypes,variables.SpecialDateType)>
		<cfset result = variables.SpecialDateType>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldSQL_Math" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="tablealias" type="string" required="no">
	
	<cfset var sField = getField(arguments.tablename,arguments.field)>
	<cfset var aSQL = ArrayNew(1)>
	
	<cfset ArrayAppend(aSQL,"(")>
	<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field1'],tablealias=arguments.tablealias,useFieldAlias=false) )>
	<cfset ArrayAppend(aSQL, sField.Relation['operator'] )>
	<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field2'],tablealias=arguments.tablealias,useFieldAlias=false) )>
	<cfset ArrayAppend(aSQL,")")>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="isFieldInSelect" access="private" returntype="boolean" output="no" hint="I determine if the given field is in the select list.">
	<cfargument name="field" type="struct" required="yes">
	<cfargument name="fieldlist" type="string" default="">
	<cfargument name="maxrows" type="numeric" default="0">
	
	<cfset var sField = arguments.field>
	<cfset var result = false>
	
	<cfif
			(
					Len(arguments.fieldlist) EQ 0
				AND	(
							NOT	StructKeyExists(sField,"useInMultiRecordsets")
						OR	sField.useInMultiRecordsets IS true
						OR arguments.maxrows EQ 1
					)
			)
		OR	ListFindNoCase(arguments.fieldlist,sField.ColumnName)
	>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="checkLength" access="private" returntype="void" output="no" hint="I check the length of incoming data to see if it can fit in the designated field (making for a more developer-friendly error messages).">
	<cfargument name="field" type="struct" required="yes">
	<cfargument name="data" type="string" required="yes">
	
	<cfset var type = getDBDataType(field.CF_DataType)>
	
	<cfif isStringType(type) AND StructKeyExists(field,"Length") AND isNumeric(field.Length) AND field.Length GT 0 AND Len(data) GT field.Length>
		<cfset throwDMError("The data for '#field.ColumnName#' must be no more than #field.Length# characters in length.")>
	</cfif>
	
</cffunction>

<cffunction name="checkTable" access="private" returntype="boolean" output="no" hint="I check to see if the given table exists in the Datamgr.">
	<cfargument name="tablename" type="string" required="yes">
	
	<!--- Note that this method is overridden for any database for which DataMgr can introspect the database table --->
	
	<cfif NOT StructKeyExists(variables.tables,arguments.tablename)>
		<cfset throwDMError("The table #arguments.tablename# must be loaded into DataMgr before you can use it.","NoTableLoaded")>
	</cfif>
	
	<cfset checkTablePK(arguments.tablename)>
	
	<cfreturn true>
</cffunction>

<cffunction name="checkTablePK" access="private" returntype="void" output="no" hint="I check to see if the given table has a primary key.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var i = 0><!--- counter --->
	<cfset var arrFields = ArrayNew(1)><!--- array of primarykey fields --->
	
	<!--- If pkfields data if stored --->
	<cfif StructKeyExists(variables.tableprops,arguments.tablename) AND StructKeyExists(variables.tableprops[arguments.tablename],"pkfields")>
		<cfset arrFields = variables.tableprops[arguments.tablename]["pkfields"]>
	<cfelse>
		<cfloop index="i" from="1" to="#ArrayLen(variables.tables[arguments.tablename])#" step="1">
			<cfif StructKeyExists(variables.tables[arguments.tablename][i],"PrimaryKey") AND variables.tables[arguments.tablename][i].PrimaryKey>
				<cfset ArrayAppend(arrFields, variables.tables[arguments.tablename][i])>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfif NOT ArrayLen(arrFields)>
		<cfset throwDMError("The table #arguments.tablename# must have at least one primary key field to be used by DataMgr.","NoPKField")>
	</cfif>
		
</cffunction>

<cffunction name="cleanSQLArray" access="private" returntype="array" output="no" hint="I take a potentially nested SQL array and return a flat SQL array.">
	<cfargument name="sqlarray" type="array" required="yes">
	
	<cfset var result = ArrayNew(1)>
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var temparray = 0>
	
	<cfloop index="i" from="1" to="#ArrayLen(arguments.sqlarray)#" step="1">
		<cfif isArray(arguments.sqlarray[i])>
			<cfset temparray = cleanSQLArray(arguments.sqlarray[i])>
			<cfloop index="j" from="1" to="#ArrayLen(temparray)#" step="1">
				<cfset ArrayAppend(result,temparray[j])>
			</cfloop>
		<cfelseif isStruct(arguments.sqlarray[i])>
			<cfset ArrayAppend(result,queryparam(argumentCollection=arguments.sqlarray[i]))>
		<cfelse>
			<cfset ArrayAppend(result,arguments.sqlarray[i])>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="DMDuplicate" access="private" returntype="any" output="no">
	<cfargument name="var" type="any" required="yes">
	
	<cfset var result = 0>
	<cfset var key = "">
	
	<cfif isStruct(arguments.var)>
		<cfset result = StructCopy(arguments.var)>
	<cfelse>
		<cfset result = arguments.var>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="DMPreserveSingleQuotes" access="private" returntype="string" output="false" hint="">
	<cfargument name="sql" type="any" required="yes">
	
	<cfreturn PreserveSingleQuotes(arguments.sql)>
</cffunction>

<cffunction name="escape" access="private" returntype="string" output="no" hint="I return an escaped value for a table or field.">
	<cfargument name="name" type="string" required="yes">
	<cfreturn "#arguments.name#">
</cffunction>

<cffunction name="expandRelationStruct" access="public" returntype="struct" output="no">
	<cfargument name="Relation" type="struct" required="yes">
	<cfargument name="field" type="struct" required="no">
	
	<cfset var sResult = Duplicate(arguments.Relation)>
	<cfset var key = "">
	<cfset var sField = StructNew()>
	<cfset var sLocalFTables = 0>
	<cfset var sRemoteFTables = 0>
	<cfset var isFtableInUse = false>
	
	<cfif StructKeyExists(arguments,"field")>
		<cfset sField = arguments.field>
	</cfif>
	
	<cfloop collection="#sResult#" item="key">
		<cfif key CONTAINS "_" AND KEY NEQ "CF_Datatype">
			<cfset sResult[ListChangeDelims(key,"-","_")] = sResult[key]>
			<cfset StructDelete(sResult,key)>
		</cfif>
	</cfloop>
	
	<cfscript>
	if ( StructKeyExists(sResult,"join-table") ) {
		if ( StructKeyExists(sResult,"join-field-local") AND Len(sResult["join-field-local"]) AND NOT StructKeyExists(sResult,"join-table-field-local") ) {
			sResult["join-table-field-local"] = sResult["join-field-local"];
		}
		if ( StructKeyExists(sResult,"join-field-remote") AND Len(sResult["join-field-remote"]) AND NOT StructKeyExists(sResult,"join-table-field-remote") ) {
			sResult["join-table-field-remote"] = sResult["join-field-remote"];
		}
		if ( NOT StructKeyExists(sResult,"join-table-field-local") ) {
			sResult["join-table-field-local"] = "";
		}
		if ( NOT StructKeyExists(sResult,"join-table-field-remote") ) {
			sResult["join-table-field-remote"] = "";
		}
		if ( NOT StructKeyExists(sResult,"local-table-join-field") ) {
			sResult["local-table-join-field"] = sResult["join-table-field-local"];
		}
		if ( NOT StructKeyExists(sResult,"remote-table-join-field") ) {
			sResult["remote-table-join-field"] = sResult["join-table-field-remote"];
		}
	} else {
		if ( NOT StructKeyExists(sResult,"join-field") ) {
			if ( StructKeyExists(sField,"tablename") AND StructKeyExists(sResult,"table") ) {
				if ( NOT StructKeyExists(sResult,"join-field-local") ) {
					sLocalFTables = getFTableFields(sField["tablename"]);
					if ( StructKeyExists(sLocalFTables,sResult["table"]) ) {
						sResult["join-field-local"] = sLocalFTables[sResult["table"]];
						isFtableInUse = true;
					}
				}
				if ( NOT StructKeyExists(sResult,"join-field-remote") ) {
					sRemoteFTables = getFTableFields(sResult["table"]);
					if ( StructKeyExists(sRemoteFTables,sField["tablename"]) ) {
						sResult["join-field-remote"] = sRemoteFTables[sField["tablename"]];
						isFtableInUse = true;
					}
				}
				if ( isFtableInUse ) {
					if ( NOT StructKeyExists(sResult,"join-field-local") ) {
						sResult["join-field-local"] = getPrimaryKeyFieldNames(sField["tablename"]);
					}
					if ( NOT StructKeyExists(sResult,"join-field-remote") ) {
						sResult["join-field-remote"] = getPrimaryKeyFieldNames(sResult["table"]);
					}
				}
			}
			if ( StructKeyExists(sResult,"field") AND NOT isFtableInUse ) {
				sResult["join-field"] = sResult["field"];
			}
		}
		if ( StructKeyExists(sResult,"join-field") AND NOT StructKeyExists(sResult,"join-field-local") ) {
			sResult["join-field-local"] = sResult["join-field"];
		}
		if ( StructKeyExists(sResult,"join-field") AND NOT StructKeyExists(sResult,"join-field-remote") ) {
			sResult["join-field-remote"] = sResult["join-field"];
		}
	}
	</cfscript>
	
	<!--- Checking for invalid combinations --->
	<cfif StructKeyExists(sResult,"table") AND StructKeyExists(sResult,"join-table")>
		<cfif Len(sResult.table) AND sResult["table"] EQ sResult["join-table"]>
			<cfset throwDMError("The table and join-table attributes cannot be the same.","RelationAttributesError")>
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(sField,"ColumnName")>
		<cfif StructKeyExists(sResult,"join-field-local") AND sField["ColumnName"] EQ sResult["join-field-local"]>
			<cfset throwDMError("A field cannot refer to itself in a relation.","RelationAttributesError","#sField.ColumnName#")>
		</cfif>
		<cfif StructKeyExists(sResult,"local-table-join-field") AND sField["ColumnName"] EQ sResult["local-table-join-field"]>
			<cfset throwDMError("A field cannot refer to itself in a relation.","RelationAttributesError","#sField.ColumnName#")>
		</cfif>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="fillOutJoinTableRelations" access="private" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var bCheckTable = checkTable(arguments.tablename)>
	<cfset var relates = variables.tables[arguments.tablename]>
	<cfset var ii = 0>
	
	<cfif NOT ( StructKeyExists(variables.tableprops[arguments.tablename],"fillOutJoinTableRelations") )>
		<cfloop index="ii" from="1" to="#ArrayLen(relates)#" step="1">
			<cfif StructKeyExists(relates[ii],"Relation")>
				<cfif
						StructKeyExists(relates[ii].Relation,"table")
					AND	StructKeyExists(relates[ii].Relation,"join-table")>
					<cfset checkTable(relates[ii].Relation["table"])>
					<cfset checkTable(relates[ii].Relation["join-table"])>
					<cfif NOT ( StructKeyExists(relates[ii].Relation,"join-table-field-local") AND Len(relates[ii].Relation["join-table-field-local"]) )>
						<cfset variables.tables[arguments.tablename][ii].Relation["join-table-field-local"] = getPrimaryKeyFieldName(arguments.tablename)>
					</cfif>
					<cfif NOT ( StructKeyExists(relates[ii].Relation,"join-table-field-remote") AND Len(relates[ii].Relation["join-table-field-remote"]) )>
						<cfset variables.tables[arguments.tablename][ii].Relation["join-table-field-remote"] = getPrimaryKeyFieldName(relates[ii].Relation["table"])>
					</cfif>
					<cfif NOT ( StructKeyExists(relates[ii].Relation,"local-table-join-field") AND Len(relates[ii].Relation["local-table-join-field"]) )>
						<cfset variables.tables[arguments.tablename][ii].Relation["local-table-join-field"] = getPrimaryKeyFieldName(arguments.tablename)>
					</cfif>
					<cfif NOT ( StructKeyExists(relates[ii].Relation,"remote-table-join-field") AND Len(relates[ii].Relation["remote-table-join-field"]) )>
						<cfset variables.tables[arguments.tablename][ii].Relation["remote-table-join-field"] = getPrimaryKeyFieldName(relates[ii].Relation["table"])>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<cfset variables.tableprops[arguments.tablename]["fillOutJoinTableRelations"] = true>
	</cfif>
	
</cffunction>

<cffunction name="getColumnIndex" access="private" returntype="numeric" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="columnname" type="string" required="yes">
	
	<cfset var bTable = checkTable(arguments.tablename)>
	<cfset var aTable = 0>
	<cfset var ii = 0>
	<cfset var result = 0>
	
	<cfset aTable = variables.tables[arguments.tablename]>
	
	<cfloop index="ii" from="1" to="#ArrayLen(aTable)#" step="1">
		<cfif aTable[ii].ColumnName EQ arguments.columnname>
			<cfset result = ii>
			<cfbreak>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getConnection" access="private" returntype="any" output="false" hint="Returns a java.sql.Connection (taken from Transfer with permission).">
	<cfscript>
	var datasourceService = createObject("Java", "coldfusion.server.ServiceFactory").getDataSourceService();

	if( StructKeyExists(variables,"username") AND StructKeyExists(variables,"password") ) {
		return datasourceService.getDatasource(variables.datasource).getConnection(variables.username, variables.password);
	} else {
		return datasourceService.getDatasource(variables.datasource).getConnection();
	}
	</cfscript>
</cffunction>

<cffunction name="getDataStruct" access="private" returntype="struct" output="no" hint="I return a struct from a data string or struct for a table.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="any" required="yes">
	
	<cfset var result = 0>
	<cfset var pkfields = 0>
	
	<cfif isStruct(arguments.data)>
		<cfset result = StructCopy(arguments)>
	<cfelseif isSimpleValue(arguments.data)>
		<cfset pkfields = getPKFields(arguments.tablename)>
		<cfif ArrayLen(pkfields) EQ 1>
			<cfset result = StructNew()>
			<cfset result[pkfields[1].ColumnName] = arguments.data>
		</cfif> 
	</cfif>
	
	<cfif isStruct(result)>
		<cfset result = clean(result)>
	<cfelse>
		<cfset throwDMError("The data argument must be a structure or must be a a primary key value for a table with a simple primary key.","InvalidDataArgument")>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getEffectiveDataType" access="private" returntype="string" output="no" hint="I get the generic ColdFusion data type for the given field.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fieldname" type="string" required="yes">
	
	<cfset var sField = 0>
	<cfset var result = "invalid">
	
	<cfif isNumeric(arguments.fieldname)>
		<cfset result="numeric">
	<cfelse>
		<cftry>
			<cfset sField = getField(arguments.tablename,arguments.fieldname)>
			<cfset result = getEffectiveFieldDataType(sField)>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getEffectiveFieldDataType" access="private" returntype="string" output="no" hint="I get the generic ColdFusion data type for the given field.">
	<cfargument name="field" type="struct" required="yes">
	<cfargument name="isInWhere" type="boolean" default="false">
	
	<cfset var sField = arguments.field>
	<cfset var result = "invalid">
	
	<cfif StructKeyExists(sField,"Relation") AND StructKeyExists(sField.Relation,"type")>
		<cfswitch expression="#sField.Relation.type#">
		<cfcase value="label">
			<cfset result = getEffectiveDataType(sField.Relation.table,sField.Relation.field)>
		</cfcase>
		<cfcase value="concat">
			<cfset result = "string">
		</cfcase>
		<cfcase value="list">
			<cfif isInWhere>
				<cfset result = getEffectiveDataType(sField.Relation.table,sField.Relation.field)>
			<cfelse>
				<cfset result = "invalid">
			</cfif>
		</cfcase>
		<cfcase value="avg,count,max,min,sum">
			<cfset result = "numeric">
		</cfcase>
		<cfcase value="has">
			<cfset result = "boolean">
		</cfcase>
		<cfcase value="math">
			<cfset result = "numeric"><!--- Unless I figure out datediff --->
		</cfcase>
		<cfcase value="now">
			<cfset result = "date">
		</cfcase>
		<cfcase value="custom">
			<cfif StructKeyExists(sField.Relation,"CF_Datatype")>
				<cfset result = getGenericType(sField.Relation.CF_Datatype)>
			<cfelse>
				<cfset result = "invalid">
			</cfif>
		</cfcase>
		</cfswitch>
	<cfelseif StructKeyExists(sField,"CF_Datatype")>
		<cfset result = getGenericType(sField.CF_Datatype)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getGenericType" access="private" returntype="string" output="no" hint="I get the generic ColdFusion data type for the given field.">
	<cfargument name="CF_Datatype" type="string" required="true">
	
	<cfset var result = "invalid">
	
	<cfswitch expression="#arguments.CF_Datatype#">
	<cfcase value="CF_SQL_BIGINT,CF_SQL_DECIMAL,CF_SQL_DOUBLE,CF_SQL_FLOAT,CF_SQL_INTEGER,CF_SQL_MONEY,CF_SQL_MONEY4,CF_SQL_NUMERIC,CF_SQL_REAL,CF_SQL_SMALLINT,CF_SQL_TINYINT">
		<cfset result = "numeric">
	</cfcase>
	<cfcase value="CF_SQL_BIT">
		<cfset result = "boolean">
	</cfcase>
	<cfcase value="CF_SQL_CHAR,CF_SQL_IDSTAMP,CF_SQL_VARCHAR">
		<cfset result = "string">
	</cfcase>
	<cfcase value="CF_SQL_DATE,CF_SQL_DATETIME,CF_SQL_TIMESTAMP">
		<cfset result = "date">
	</cfcase>
	<cfcase value="CF_SQL_LONGVARCHAR,CF_SQL_CLOB">
		<cfset result = "invalid">
	</cfcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getField" access="public" returntype="struct" output="no" hint="I the field of the given name.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fieldname" type="string" required="yes">
	
	<cfset var ii = 0>
	<cfset var result = "">
	
	<cftry>
		<cfset checkTable(arguments.tablename)>
	<cfcatch>
		<cfset throwDMError("The #arguments.tablename# table does not exist.","NoSuchTable")>
	</cfcatch>
	</cftry>
	
	<!--- Loop over the fields in the table and make a list of them --->
	<cfif StructKeyExists(variables.tables,arguments.tablename)>
		<cfloop index="ii" from="1" to="#ArrayLen(variables.tables[arguments.tablename])#" step="1">
			<cfif variables.tables[arguments.tablename][ii].ColumnName EQ arguments.fieldname>
				<cfset result = Duplicate(variables.tables[arguments.tablename][ii])>
				<cfset result["tablename"] = arguments.tablename>
				<cfset result["fieldname"] = arguments.fieldname>
				<cfbreak>
			</cfif>
		</cfloop>
		<cfif NOT isStruct(result)>
			<cfset throwDMError("The field #arguments.fieldname# could not be found in the #arguments.tablename# table.","NoSuchField")>
		</cfif>
	<cfelse>
		<cfset throwDMError("The #arguments.tablename# table does not exist.","NoSuchTable")>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getInsertedIdentity" access="private" returntype="string" output="no" hint="I get the value of the identity field that was just inserted into the given table.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="identfield" type="string" required="yes">
	
	<cfset var qCheckKey = 0>
	<cfset var result = 0>
	<cfset var sqlarray = ArrayNew(1)>
	
	<cfset ArrayAppend(sqlarray,"SELECT		Max(#escape(identfield)#) AS NewID")>
	<cfset ArrayAppend(sqlarray,"FROM		#escape(arguments.tablename)#")>
	<cfset qCheckKey = runSQLArray(sqlarray)>
	
	<cfset result = Val(qCheckKey.NewID)>
	
	<cfreturn result>
</cffunction>

<cffunction name="getOrderByArray" access="private" returntype="array" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="orderby" type="string" required="yes">
	<cfargument name="tablealias" type="string" default="#arguments.tablename#">
	
	<cfset var bTable = checkTable(arguments.tablename)>
	<cfset var aResults = ArrayNew(1)>
	<cfset var aFields = getFields(arguments.tablename)>
	<cfset var ii = 0>
	<cfset var OrderClause = "">
	<cfset var SortOrder = "">
	<cfset var aOrderClause = 0>
	<cfset var isFieldFound = false>
	
	<cfloop list="#arguments.orderby#" index="OrderClause">
		<cfset isFieldFound = false>
		
		<!--- Determine sort order --->
		<cfif ListLast(OrderClause," ") EQ "DESC">
			<cfset SortOrder = "DESC">
		<cfelse>
			<cfset SortOrder = "ASC">
		</cfif>
		<!--- Peel off sort order --->
		<cfif ListFindNoCase("ASC,DESC",ListLast(OrderClause," "))>
			<cfset OrderClause = reverse(ListRest(reverse(OrderClause)," "))>
		</cfif>
		<cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1">
			<cfif aFields[ii].ColumnName EQ OrderClause OR aFields[ii].ColumnName EQ Trim(OrderClause)>
				<cfset ArrayAppend(aResults,getFieldSelectSQL(tablename=arguments.tablename,field=aFields[ii].ColumnName,tablealias=arguments.tablealias))>
				<cfset ArrayAppend(aResults,SortOrder)>
				<cfset ArrayAppend(aResults,",")>
				<cfset isFieldFound = true>
				<cfbreak>
				<!--- HERE --->
			</cfif>
		</cfloop>
		<!--- If a field was found, no more work to do --->
		<cfif NOT isFieldFound>
			<!--- Security measure, a semicolon indicates the start of a new SQL statement (this is after the field search so that a field name could contain one) --->
			<cfif OrderClause CONTAINS ";">
				<cfbreak>
			</cfif>
			<cfset ArrayAppend(aResults,OrderClause)>
			<cfset ArrayAppend(aResults,SortOrder)>
			<cfset ArrayAppend(aResults,",")>
		</cfif>
	</cfloop>
	
	<!--- Ditch trailing comma --->
	<cfif ArrayLen(aResults) AND aResults[ArrayLen(aResults)] EQ ",">
		<cfset ArrayDeleteAt(aResults,ArrayLen(aResults))>
	</cfif>
	
	<cfreturn aResults>
</cffunction>

<cffunction name="getOrderbyFieldList" access="private" returntype="array" output="no">
	
	<!---<cfset var adjustedfieldlist = "">--->
	<cfset var orderarray = ArrayNew(1)>
	<cfset var temp = "">
	<!---<cfset var sqlarray = ArrayNew(1)>--->
	
	<cfif Len(arguments.fieldlist)>
		<cfloop list="#arguments.fieldlist#" index="temp">
			<!---<cfset adjustedfieldlist = ListAppend(adjustedfieldlist,escape(arguments.tablealias & '.' & temp))>--->
			<cfif ArrayLen(orderarray) GT 0>
				<cfset ArrayAppend(orderarray,",")>
			</cfif>
			<cfset ArrayAppend(orderarray,getFieldSelectSQL(tablename=arguments.tablename,field=temp,tablealias=arguments.tablealias,useFieldAlias=false))>
		</cfloop>
	</cfif>

	<!---<cfif Len(arguments.function)>
		<cfset ArrayAppend(sqlarray,adjustedfieldlist)>
	<cfelse>
		<cfset ArrayAppend(sqlarray,"#arguments.fieldlist#")>
	</cfif>--->
	
	<cfreturn orderarray>
</cffunction>

<cffunction name="getProps" access="private" returntype="struct" output="no" hint="no">
	
	<cfset var sProps = StructNew()>
	
	<cfset sProps["areSubqueriesSortable"] = true>
	
	<cfset StructAppend(sProps,getDatabaseProperties(),true)>
	
	<cfreturn sProps>
</cffunction>

<cffunction name="getRelationValues" access="private" returntype="struct" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data" type="struct" required="yes">
	
	<cfset var in = DMDuplicate(arguments.data)>
	<cfset var rfields = getRelationFields(arguments.tablename)><!--- relation fields in table --->
	<cfset var i = 0>
	<cfset var qRecords = 0>
	<cfset var temp = 0>
	<cfset var temp2 = 0>
	<cfset var j = 0>
	
	<!--- Check for incoming label values --->
	<cfloop index="i" from="1" to="#ArrayLen(rfields)#" step="1">
		<!--- Perform action for labels where join-field isn't already being given a value --->
		<cfif StructKeyExists(in,rfields[i].ColumnName)>
			<!--- If this is a label and the associated value isn't already set and valid --->
			<cfif
					rfields[i].Relation.type EQ "label"
				AND	NOT useField(in,getField(arguments.tablename,rfields[i].Relation["join-field-local"]))
			><!--- AND NOT useField(in,getField(rfields[i].Relation["table"],rfields[i].Relation["join-field-remote"])) --->
				<!--- Get the value for the relation field --->
				<cfset temp = StructNew()>
				<cfset temp[rfields[i].Relation["field"]] = in[rfields[i].ColumnName]>
				<cfset qRecords = getRecords(tablename=rfields[i].Relation["table"],data=temp,maxrows=1,fieldlist=rfields[i].Relation["join-field-remote"])>
				<!--- If a record is found, set the value --->
				<cfif qRecords.RecordCount>
					<cfset in[rfields[i].Relation["join-field-local"]] = qRecords[rfields[i].Relation["join-field-remote"]][1]>
				<!--- If no record is found, but an "onMissing" att is, take appropriate action --->
				<cfelseif StructKeyExists(rfields[i].Relation,"onMissing")>
					<cfswitch expression="#rfields[i].Relation.onMissing#">
					<cfcase value="insert">
						<cfset temp2 = insertRecord(rfields[i].Relation["table"],temp)>
						<cfset qRecords = getRecords(tablename=rfields[i].Relation["table"],data=temp,maxrows=1,fieldlist=rfields[i].Relation["join-field-remote"])>
						<cfset in[rfields[i].Relation["join-field-local"]] = qRecords[rfields[i].Relation["join-field-remote"]][1]>
					</cfcase>
					<cfcase value="error">
						<cfset throwDMError("""#in[rfields[i].ColumnName]#"" is not a valid value for ""#rfields[i].ColumnName#""","InvalidLabelValue")>
					</cfcase>
					</cfswitch>
				</cfif>
				<!--- ditch this column name from in struct (no longer needed) --->
				<cfset StructDelete(in,rfields[i].ColumnName)>
			<cfelseif
					rfields[i].Relation.type EQ "concat"
				AND	StructKeyExists(rfields[i].Relation,"delimiter")
				AND	StructKeyExists(rfields[i].Relation,"fields")
			>
				<cfif ListLen(rfields[i].Relation["fields"]) EQ ListLen(in[rfields[i].ColumnName],rfields[i].Relation["delimiter"])>
					<!--- Make sure none of the component fields are being passed in. --->
					<cfset temp2 = true>
					<cfloop index="temp" list="#rfields[i].Relation.fields#">
						<cfif StructKeyExists(in, temp)>
							<cfset temp2 = false>
						</cfif>
					</cfloop>
					<!--- If none of the fields are being passed in already, set fields based on concat --->
					<cfif temp2>
						<cfloop index="j" from="1" to="#ListLen(rfields[i].Relation.fields)#" step="1">
							<cfset temp = ListGetAt(rfields[i].Relation.fields,j)>
							<cfset in[temp] = ListGetAt(in[rfields[i].ColumnName],j,rfields[i].Relation["delimiter"])>
						</cfloop>
					</cfif>
				<cfelse>
					<cfset throwDMError("The number of items in #rfields[i].ColumnName# don't match the number of fields.","ConcatListLenMisMatch")>
				</cfif>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfreturn in>
</cffunction>

<cffunction name="getPreSeedRecords" access="private" returntype="query" output="no">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfreturn getRecords(tablename=arguments.tablename,function="count",FunctionAlias="NumRecords")>
</cffunction>

<cffunction name="getRelationFields" access="private" returntype="array" output="no" hint="I return an array of primary key fields.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var i = 0><!--- counter --->
	<cfset var arrFields = ArrayNew(1)><!--- array of primarykey fields --->
	<cfset var bTable = checkTable(arguments.tablename)><!--- Check whether table is loaded --->
	<cfset var novar = fillOutJoinTableRelations(arguments.tablename)>
	<cfset var relates = variables.tables[arguments.tablename]>
	<cfset var mathoperators = "+,-,*,/">
	<cfset var sRelationTypes = getRelationTypes()>
	<cfset var key = "">
	<cfset var fieldatts = "field,field1,field2,fields">
	<cfset var dtype = "">
	<cfset var sThisRelation = 0>
	<cfset var field = "">
	
	<cfif StructKeyExists(variables.tableprops,arguments.tablename) AND StructKeyExists(variables.tableprops[arguments.tablename],"relatefields")>
		<cfset arrFields = variables.tableprops[arguments.tablename]["relatefields"]>
	<cfelse>
		<cfloop index="i" from="1" to="#ArrayLen(relates)#" step="1">
			<cfif StructKeyExists(relates[i],"Relation")>
				<cfset sThisRelation = expandRelationStruct(relates[i].Relation,relates[i])>
				<!--- Make sure relation type exists --->
				<cfif StructKeyExists(sThisRelation,"type")>
					<!--- Make sure all needed attributes exist --->
					<cfif StructKeyExists(sRelationTypes,sThisRelation.type)>
						<cfloop list="#sRelationTypes[sThisRelation.type].atts_req#" index="key">
							<cfif NOT StructKeyExists(sThisRelation,key) AND NOT ( key CONTAINS "join-field" AND ( StructKeyExists(sThisRelation,"join-field") OR StructKeyExists(sThisRelation,"join-table") ) )>
								<cfset throwDMError("There is a problem with the #relates[i].ColumnName# field in the #arguments.tablename# table: The #key# attribute is required for a relation type of #sThisRelation.type#.","RelationTypeMissingAtt")>
							</cfif>
						</cfloop>
					</cfif>
					<!--- Check data types --->
					<cfloop list="#fieldatts#" index="key">
						<cfif StructKeyExists(sThisRelation,key)>
							<cfloop list="#sThisRelation[key]#" index="field">
								<cfif StructKeyExists(sThisRelation,"table")>
									<cfset dtype = getEffectiveDataType(sThisRelation.table,field)>
								<cfelse>
									<cfset dtype = getEffectiveDataType(arguments.tablename,field)>
								</cfif>
								<cfif dtype EQ "invalid" OR ( Len(sRelationTypes[sThisRelation.type].gentypes) AND NOT ListFindNoCase(sRelationTypes[sThisRelation.type].gentypes,dtype) )>
									<cfset throwDMError("There is a problem with the #relates[i].ColumnName# field in the #arguments.tablename# table: #dtype# fields cannot be used with a relation type of #sThisRelation.type#.","InvalidRelationGenericType")>
								</cfif>
							</cfloop>
						</cfif>
					</cfloop>
				<cfelse>
					<cfset throwDMError("There is a problem with the #relates[i].ColumnName# field in the #arguments.tablename# table has no relation type.","NoSuchRelationType")>
				</cfif>
				<cfset ArrayAppend(arrFields, relates[i])>
			</cfif>
		</cfloop>
		<cfset variables.tableprops[arguments.tablename]["relatefields"] = arrFields>
	</cfif>
	
	<cfloop index="i" from="1" to="#ArrayLen(arrFields)#">
		<cfset arrFields[i].Relation = expandRelationStruct(arrFields[i].Relation,arrFields[i])>
	</cfloop>
	
	<cfreturn arrFields>
</cffunction>

<cffunction name="isBlankValue" access="private" returntype="boolean" output="no" hint="I see if the given field is passed in as blank and is a nullable field.">
	<cfargument name="Struct" type="struct" required="yes">
	<cfargument name="Field" type="struct" required="yes">
	
	<cfset var Key = arguments.Field.ColumnName>
	<cfset var result = false>
	
	<cfif
			StructKeyExists(arguments.Struct,Key)
		AND	NOT Len(arguments.Struct[Key])
	>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="isIdentityField" access="private" returntype="boolean" output="no">
	<cfargument name="Field" type="struct" required="yes">
	
	<cfset var result = false>
	
	<cfif StructKeyExists(Field,"Increment") AND Field.Increment>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getTypeOfCFType" access="private" returntype="any" output="false" hint="">
	<cfargument name="CF_DataType" type="string" required="yes">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.CF_DataType#">
	<cfcase value="CF_SQL_BIT">
		<cfset result = "boolean">
	</cfcase>
	<cfcase value="CF_SQL_DECIMAL,CF_SQL_DOUBLE,CF_SQL_FLOAT,CF_SQL_NUMERIC">
		<cfset result = "numeric">
	</cfcase>
	<cfcase value="CF_SQL_BIGINT,CF_SQL_INTEGER,CF_SQL_SMALLINT,CF_SQL_TINYINT">
		<cfset result = "integer">
	</cfcase>
	<cfcase value="CF_SQL_DATE,CF_SQL_DATETIME">
		<cfset result = "date">
	</cfcase>
	<cfdefaultcase>
		<cfset result = arguments.CF_DataType>
	</cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="isOfType" access="private" returntype="boolean" output="no" hint="I check if the given value is of the given data type.">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="CF_DataType" type="string" required="yes">
	
	<cfset var datum = arguments.value>
	<cfset var typetype = getTypeOfCFType(arguments.CF_DataType)>
	<cfset var isOK = false>
	
	<cfif isStruct(datum) AND StructKeyExists(datum,"value")>
		<cfset datum = datum.value>
	</cfif>
	
	<cfswitch expression="#typetype#">
	<cfcase value="boolean">
		<cfset isOK = isBoolean(datum)>
	</cfcase>
	<cfcase value="numeric">
		<cfset isOK = isNumeric(datum) OR isBoolean(datum)>
	</cfcase>
	<cfcase value="integer">
		<cfset isOK = (isNumeric(datum) OR isBoolean(datum)) AND ( datum EQ Int(datum) )>
	</cfcase>
	<cfcase value="date">
		<cfset isOK = isValidDate(datum)>
	</cfcase>
	<cfdefaultcase>
		<cfset isOK = true>
	</cfdefaultcase>
	</cfswitch>
	
	<cfreturn isOK>
</cffunction>

<cffunction name="makeDefaultValue" access="private" returntype="string" output="no" hint="I return the value of the default for the given datatype and raw value.">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="CF_DataType" type="string" required="yes">
	
	<cfset var result = Trim(arguments.value)>
	<cfset var type = getDBDataType(arguments.CF_DataType)>
	<cfset var isFunction = true>
	
	<!--- If default isn't a string and is in parens, remove it from parens --->
	<cfscript>
	while ( Left(result,1) EQ "(" AND Right(result,1) EQ ")" ) {
		result = Mid(result,2,Len(result)-2);
	}
	</cfscript>
	
	<!--- If default is in single quotes, remove it from single quotes --->
	<cfif Left(result,1) EQ "'" AND Right(result,1) EQ "'">
		<cfset result = Mid(result,2,Len(result)-2)>
		<cfset isFunction = false><!--- Functions aren't in single quotes --->
	</cfif>
	
	<!--- Functions must have an opening paren and end with a closing paren --->
	<cfif isFunction AND NOT (FindNoCase("(", result) AND Right(result,1) EQ ")")>
		<cfset isFunction = false>
	</cfif>
	<!--- Functions don't start with a paren --->
	<cfif isFunction AND Left(result,1) EQ "(">
		<cfset isFunction = false>
	</cfif>
	
	<!--- boolean values should be stored as one or zero --->
	<cfif arguments.CF_DataType EQ "CF_SQL_BIT">
		<cfset result = getBooleanSqlValue(result)>
	</cfif>
	
	<!--- string values that aren't functions, should be in single quotes. --->
	<cfif isStringType(type) AND NOT isFunction>
		<cfset result = ReplaceNoCase(result, "'", "''", "ALL")>
		<cfset result = "'#result#'">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="readyTable" access="private" returntype="void" output="no" hint="I get the internal table representation ready for use by DataMgr.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset checkTable()>
	
	<cfif NOT ( StructKeyExists(variables.tableprops,arguments.tablename) AND StructCount(variables.tableprops[arguments.tablename]) )>
		<cfset getFieldList(arguments.tablename)>
		<cfset getPKFields(arguments.tablename)>
		<cfset getUpdateableFields(arguments.tablename)>
		<cfset getRelationFields()>
		<cfset makeFieldSQLs()>
	</cfif>
</cffunction>

<cffunction name="getTableProps" access="public" returntype="struct" output="no" hint="I get the internal table representation ready for use by DataMgr.">
	<cfargument name="tablename" type="string" required="no">
	
	<cfif StructKeyExists(arguments,"tablename")>
		<cfreturn variables.tableprops[arguments.tablename]>
	<cfelse>
		<cfreturn variables.tableprops>
	</cfif>
	
</cffunction>

<cffunction name="dbHasOffset" access="public" returntype="boolean" output="no" hint="I indicate if the current database natively supports offsets">
	<cfreturn false>
</cffunction>

<cffunction name="resetTableProps" access="private" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfscript>
	var keys = "fielddefaults,fieldlist,fieldlengths,fields,pkfields,updatefields,fillOutJoinTableRelations,relatefields";
	var key = "";
	
	if ( NOT StructKeyExists(variables.tableprops,arguments.tablename) ) {
		variables.tableprops[arguments.tablename] = StructNew();
	}
	if ( NOT StructKeyExists(variables.tableprops[arguments.tablename],"filters") ) {
		variables.tableprops[arguments.tablename]["filters"] = StructNew();
	}
	</cfscript>
	
	<cfloop list="#keys#" index="key">
		<cfset StructDelete(variables.tableprops[arguments.tablename],key)>
	</cfloop>
	
</cffunction>

<cffunction name="setTableProps" access="private" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="props" type="struct" required="yes">
	
	<cfscript>
	var keys = "fielddefaults,fieldlist,fieldlengths,fields,pkfields,updatefields,fillOutJoinTableRelations,relatefields";
	var key = "";
	
	for ( key in arguments.props ) {
		if ( NOT ListFindNoCase(keys,key) ) {
			variables.tableprops[arguments.tablename][key] = arguments.props[key];
		}
	}
	</cfscript>
	
</cffunction>

<cffunction name="saveRelations" access="private" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="pkfield" type="struct" required="yes" hint="The primary key field for the record.">
	<cfargument name="pkval" type="string" required="yes" hint="The primary key for the record.">
	
	<cfset var relates = getRelationFields(arguments.tablename)>
	<cfset var i = 0>
	<cfset var in = DMDuplicate(arguments.data)>
	<cfset var rtablePKeys = 0>
	<cfset var temp = "">
	<cfset var val = "">
	<cfset var list = "">
	<cfset var fieldPK = "">
	<cfset var fieldMulti = "">
	<cfset var reverse = false>
	<cfset var qRecords = 0>
	<cfset var qRecord = 0>
	
	<cfif ArrayLen(relates) AND Len(arguments.pkval)>
		<cfloop index="i" from="1" to="#ArrayLen(relates)#" step="1">
			<!--- Make sure all needed attributes exist --->
			<cfif
					StructKeyExists(in,relates[i].ColumnName)
				AND	relates[i].Relation["type"] EQ "list"
				AND	StructKeyExists(relates[i].Relation,"join-table")
			>
				<cfset rtablePKeys = getPKFields(relates[i].Relation["table"])>
				<cfif NOT ArrayLen(rtablePKeys)>
					<cfset rtablePKeys = getUpdateableFields(relates[i].Relation["table"])>
				</cfif>
				
				<cfif Len(relates[i].Relation["join-table-field-local"])>
					<cfset fieldPK = relates[i].Relation["join-table-field-local"]>
					<cfif relates[i].Relation["join-table-field-local"] NEQ getPrimaryKeyFieldName(arguments.tablename)>
						<cfset temp = StructNew()>
						<cfset temp[getPrimaryKeyFieldName(arguments.tablename)] = arguments.pkval>
						<cfset qRecord = getRecords(tablename=arguments.tablename,data=temp,fieldlist=fieldPK)>
						<cfset arguments.pkval = qRecord[fieldPK][1]>
					</cfif>
				<cfelse>
					<cfset fieldPK = getPrimaryKeyFieldName(arguments.tablename)>
				</cfif>
				
				<cfif Len(relates[i].Relation["join-table-field-remote"])>
					<cfset fieldMulti = relates[i].Relation["join-table-field-remote"]>
				<cfelse>
					<cfset fieldMulti = getPrimaryKeyFieldName(relates[i].Relation["table"])>
				</cfif>
				
				<cfif
						arguments.tablename EQ relates[i].Relation["table"]
					AND	StructKeyExists(relates[i].Relation,"bidirectional")
					AND	isBoolean(relates[i].Relation["bidirectional"])
					AND	relates[i].Relation["bidirectional"]
				>
					<cfset reverse = true>
				<cfelse>
					<cfset reverse = false>
				</cfif>
				
				<!--- If relate column is pk, use saveRelationList normally --->
				<cfif relates[i].Relation["field"] EQ rtablePKeys[1].ColumnName>
					<!--- Save this relation list --->
					<cfset saveRelationList(relates[i].Relation["join-table"],fieldPK,arguments.pkval,fieldMulti,in[relates[i].ColumnName],reverse)>
				<cfelse>
					<cfset list = "">
					<!--- Otherwise, get the values --->
					<cfloop index="val" list="#in[relates[i].ColumnName]#">
						<cfset temp = StructNew()>
						<cfset temp[relates[i].Relation["field"]] = val>
						<cfset qRecords = getRecords(tablename=relates[i].Relation["table"],data=temp,fieldlist=rtablePKeys[1].ColumnName)>
						<cfif qRecords.RecordCount>
							<cfset list = ListAppend(list,qRecords[rtablePKeys[1].ColumnName][1])>
						</cfif>
					</cfloop>
					<cfset saveRelationList(relates[i].Relation["join-table"],fieldPK,arguments.pkval,fieldMulti,list,reverse)>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	
</cffunction>

<cffunction name="seedData" access="private" returntype="void" output="no">
	<cfargument name="xmldata" type="any" required="yes" hint="XML data of tables to load into DataMgr follows. Schema: http://www.bryantwebconsulting.com/cfc/DataMgr.xsd">
	<cfargument name="CreatedTables" type="string" required="yes">
	
	<cfset var varXML = arguments.xmldata>
	<cfset var arrData = XmlSearch(varXML, "//data")>
	<cfset var stcData = StructNew()>
	<cfset var tables = "">
	
	<cfset var i = 0>
	<cfset var table = "">
	<cfset var j = 0>
	<cfset var rowElement = 0>
	<cfset var rowdata = 0>
	<cfset var att = "">
	<cfset var k = 0>
	<cfset var fieldElement = 0>
	<cfset var fieldatts = 0>
	<cfset var reldata = 0>
	<cfset var m = 0>
	<cfset var relfieldElement = 0>
	
	<cfset var data = 0>
	<cfset var col = "">
	<cfset var qRecord = 0>
	<cfset var qRecords = 0>
	<cfset var checkFields = "">
	<cfset var onexists = "">
	<cfset var doSeed = false>
	
	<cfif ArrayLen(arrData)>
		<cfscript>
		//  Loop through data elements
		for ( i=1; i LTE ArrayLen(arrData); i=i+1 ) {
			//  Get table name
			if ( StructKeyExists(arrData[i].XmlAttributes,"table") ) {
				table = arrData[i].XmlAttributes["table"];
			} else  if ( StructKeyExists(arrData[i],"XmlParent") AND arrData[i].XmlParent.XmlName EQ "table" AND StructKeyExists(arrData[i].XmlParent.XmlAttributes,"name") ) {
				table = arrData[i].XmlParent.XmlAttributes["name"];
			} else {
				throwDMError("data element must either have a table attribute or be within a table element that has a name attribute.");
			}
			if ( NOT ( StructKeyExists(arrData[i].XmlAttributes,"permanentRows") AND isBoolean(arrData[i].XmlAttributes["permanentRows"]) ) ) {
				arrData[i].XmlAttributes["permanentRows"] = false;
			}
			// /Get table name
			if ( ListFindNoCase(arguments.CreatedTables,table) OR arrData[i].XmlAttributes["permanentRows"] ) {
				//  Make sure structure exists for this table
				if ( NOT StructKeyExists(stcData,table) ) {
					stcData[table] = ArrayNew(1);
					tables = ListAppend(tables,table);
				}
				// /Make sure structure exists for this table
				//  Loop through rows
				for ( j=1; j LTE ArrayLen(arrData[i].XmlChildren); j=j+1 ) {
					//  Make sure this element is a row
					if ( arrData[i].XmlChildren[j].XmlName EQ "row" ) {
						rowElement = arrData[i].XmlChildren[j];
						rowdata = StructNew();
						//  Loop through fields in row tag
						for ( att in rowElement.XmlAttributes ) {
							rowdata[att] = rowElement.XmlAttributes[att];
						}
						// /Loop through fields in row tag
						//  Loop through field tags
						if ( StructKeyExists(rowElement,"XmlChildren") AND ArrayLen(rowElement.XmlChildren) ) {
							//  Loop through field tags
							for ( k=1; k LTE ArrayLen(rowElement.XmlChildren); k=k+1 ) {
								fieldElement = rowElement.XmlChildren[k];
								//  Make sure this element is a field
								if ( fieldElement.XmlName EQ "field" ) {
									fieldatts = "name,value,reltable,relfield";
									reldata = StructNew();
									//  If this field has a name
									if ( StructKeyExists(fieldElement.XmlAttributes,"name") ) {
										if ( StructKeyExists(fieldElement.XmlAttributes,"value") ) {
											rowdata[fieldElement.XmlAttributes["name"]] = fieldElement.XmlAttributes["value"];
										} else if ( StructKeyExists(fieldElement.XmlAttributes,"reltable") ) {
											if ( NOT StructKeyExists(fieldElement.XmlAttributes,"relfield") ) {
												fieldElement.XmlAttributes["relfield"] = fieldElement.XmlAttributes["name"];
											}
											//  Loop through attributes for related fields
											for ( att in fieldElement.XmlAttributes ) {
												if ( NOT ListFindNoCase(fieldatts,att) ) {
													reldata[att] = fieldElement.XmlAttributes[att];
												}
											}
											// /Loop through attributes for related fields
											if ( ArrayLen(fieldElement.XmlChildren) ) {
												//  Loop through relfield elements
												for ( m=1; m LTE ArrayLen(fieldElement.XmlChildren); m=m+1 ) {
													relfieldElement = fieldElement.XmlChildren[m];
													if ( relfieldElement.XmlName EQ "relfield" AND StructKeyExists(relfieldElement.XmlAttributes,"name") AND StructKeyExists(relfieldElement.XmlAttributes,"value") ) {
														reldata[relfieldElement.XmlAttributes["name"]] = relfieldElement.XmlAttributes["value"];
													}
												}
												// /Loop through relfield elements
											}
											rowdata[fieldElement.XmlAttributes["name"]] = StructNew();
											rowdata[fieldElement.XmlAttributes["name"]]["reltable"] = fieldElement.XmlAttributes["reltable"];
											rowdata[fieldElement.XmlAttributes["name"]]["relfield"] = fieldElement.XmlAttributes["relfield"];
											rowdata[fieldElement.XmlAttributes["name"]]["reldata"] = reldata;
										}
									}
									// /If this field has a name
								}
								// /Make sure this element is a field
							}
							// /Loop through field tags
						}
						// /Loop through field tags
						ArrayAppend(stcData[table], rowdata);
					}
					// /Make sure this element is a row
				}
				// /Loop through rows
			}
		}
		// /Loop through data elements
		if ( Len(tables) ) {
			//  Loop through tables
			for ( i=1; i LTE ArrayLen(arrData); i=i+1 ) {
			//for ( i=1; i LTE ListLen(tables); i=i+1 ) {
				//table = ListGetAt(tables,i);
				if ( StructKeyExists(arrData[i].XmlAttributes,"table") ) {
					table = arrData[i].XmlAttributes["table"];
				} else if ( StructKeyExists(arrData[i].XmlParent.XmlAttributes,"name") ) {
					table = arrData[i].XmlParent.XmlAttributes["name"];
				} else {
					da(arrData[i]);				
				}
				
				checkFields = "";
				onexists = "skip";
				if ( StructKeyExists(arrData[i].XmlAttributes,"checkFields") ) {
					checkFields = arrData[i].XmlAttributes["checkFields"];
				}
				if ( StructKeyExists(arrData[i].XmlAttributes,"onexists") AND arrData[i].XmlAttributes["onexists"] EQ "update" ) {
					onexists = "update";
				}
				if ( StructKeyExists(stcData,table) AND ArrayLen(stcData[table]) ) {
					doSeed = arrData[i].XmlAttributes["permanentRows"];
					if ( NOT doSeed ) {
						qRecords = getPreSeedRecords(table);
						doSeed = ( qRecords.NumRecords EQ 0);
					}
				} else {
					doSeed = false;
				}
				
				//  If table has seed records
				if ( doSeed ) {
					//  Loop through seed records
					for ( j=1; j LTE ArrayLen(stcData[table]); j=j+1 ) {
						data = StructNew();
						//  Loop through fields in table
						for ( col in stcData[table][j] ) {
							//  Simple val?
							if ( isSimpleValue(stcData[table][j][col]) ) {
								data[col] = stcData[table][j][col];
							} else {
								//  Struct?
								if ( isStruct(stcData[table][j][col]) ) {
									//  Get record of related data
									qRecord = getRecords(stcData[table][j][col]["reltable"],stcData[table][j][col]["reldata"]);
									if ( qRecord.RecordCount EQ 1 AND ListFindNoCase(qRecord.ColumnList,stcData[table][j][col]["relfield"]) ) {
										data[col] = qRecord[stcData[table][j][col]["relfield"]][1];
									}
								}
								// /Struct?
							}
							// /Simple val?
						}
						// /Loop through fields in table
						if ( StructCount(data) ) {
							seedRecord(table,data,onexists,checkFields);
						}
					}
					// /Loop through seed records
				}
				//  If table has seed records
			}
			// /Loop through tables
		}
		</cfscript>
	</cfif>
	
</cffunction>

<cffunction name="seedData_BAK" access="private" returntype="void" output="no">
	<cfargument name="xmldata" type="any" required="yes" hint="XML data of tables to load into DataMgr follows. Schema: http://www.bryantwebconsulting.com/cfc/DataMgr.xsd">
	<cfargument name="CreatedTables" type="string" required="yes">
	
	<cfset var varXML = arguments.xmldata>
	<cfset var arrData = XmlSearch(varXML, "//data")>
	<cfset var stcData = StructNew()>
	<cfset var tables = "">
	
	<cfset var i = 0>
	<cfset var table = "">
	<cfset var j = 0>
	<cfset var rowElement = 0>
	<cfset var rowdata = 0>
	<cfset var att = "">
	<cfset var k = 0>
	<cfset var fieldElement = 0>
	<cfset var fieldatts = 0>
	<cfset var reldata = 0>
	<cfset var m = 0>
	<cfset var relfieldElement = 0>
	
	<cfset var data = 0>
	<cfset var col = "">
	<cfset var qRecord = 0>
	<cfset var qRecords = 0>
	<cfset var checkFields = "">
	<cfset var onexists = "">
	
	<cfif ArrayLen(arrData)>
		<cfscript>
		//  Loop through data elements
		for ( i=1; i LTE ArrayLen(arrData); i=i+1 ) {
			//  Get table name
			if ( StructKeyExists(arrData[i].XmlAttributes,"table") ) {
				table = arrData[i].XmlAttributes["table"];
			} else  if ( StructKeyExists(arrData[i],"XmlParent") AND arrData[i].XmlParent.XmlName EQ "table" AND StructKeyExists(arrData[i].XmlParent.XmlAttributes,"name") ) {
				table = arrData[i].XmlParent.XmlAttributes["name"];
			} else {
				throwDMError("data element must either have a table attribute or be within a table element that has a name attribute.");
			}
			if ( NOT ( StructKeyExists(arrData[i].XmlAttributes,"permanentRows") AND isBoolean(arrData[i].XmlAttributes["permanentRows"]) ) ) {
				arrData[i].XmlAttributes["permanentRows"] = false;
			}
			// /Get table name
			if ( ListFindNoCase(arguments.CreatedTables,table) OR arrData[i].XmlAttributes["permanentRows"] ) {
				//  Make sure structure exists for this table
				if ( NOT StructKeyExists(stcData,table) ) {
					stcData[table] = ArrayNew(1);
					tables = ListAppend(tables,table);
				}
				// /Make sure structure exists for this table
				//  Loop through rows
				for ( j=1; j LTE ArrayLen(arrData[i].XmlChildren); j=j+1 ) {
					//  Make sure this element is a row
					if ( arrData[i].XmlChildren[j].XmlName EQ "row" ) {
						rowElement = arrData[i].XmlChildren[j];
						rowdata = StructNew();
						//  Loop through fields in row tag
						for ( att in rowElement.XmlAttributes ) {
							rowdata[att] = rowElement.XmlAttributes[att];
						}
						// /Loop through fields in row tag
						//  Loop through field tags
						if ( StructKeyExists(rowElement,"XmlChildren") AND ArrayLen(rowElement.XmlChildren) ) {
							//  Loop through field tags
							for ( k=1; k LTE ArrayLen(rowElement.XmlChildren); k=k+1 ) {
								fieldElement = rowElement.XmlChildren[k];
								//  Make sure this element is a field
								if ( fieldElement.XmlName EQ "field" ) {
									fieldatts = "name,value,reltable,relfield";
									reldata = StructNew();
									//  If this field has a name
									if ( StructKeyExists(fieldElement.XmlAttributes,"name") ) {
										if ( StructKeyExists(fieldElement.XmlAttributes,"value") ) {
											rowdata[fieldElement.XmlAttributes["name"]] = fieldElement.XmlAttributes["value"];
										} else if ( StructKeyExists(fieldElement.XmlAttributes,"reltable") ) {
											if ( NOT StructKeyExists(fieldElement.XmlAttributes,"relfield") ) {
												fieldElement.XmlAttributes["relfield"] = fieldElement.XmlAttributes["name"];
											}
											//  Loop through attributes for related fields
											for ( att in fieldElement.XmlAttributes ) {
												if ( NOT ListFindNoCase(fieldatts,att) ) {
													reldata[att] = fieldElement.XmlAttributes[att];
												}
											}
											// /Loop through attributes for related fields
											if ( ArrayLen(fieldElement.XmlChildren) ) {
												//  Loop through relfield elements
												for ( m=1; m LTE ArrayLen(fieldElement.XmlChildren); m=m+1 ) {
													relfieldElement = fieldElement.XmlChildren[m];
													if ( relfieldElement.XmlName EQ "relfield" AND StructKeyExists(relfieldElement.XmlAttributes,"name") AND StructKeyExists(relfieldElement.XmlAttributes,"value") ) {
														reldata[relfieldElement.XmlAttributes["name"]] = relfieldElement.XmlAttributes["value"];
													}
												}
												// /Loop through relfield elements
											}
											rowdata[fieldElement.XmlAttributes["name"]] = StructNew();
											rowdata[fieldElement.XmlAttributes["name"]]["reltable"] = fieldElement.XmlAttributes["reltable"];
											rowdata[fieldElement.XmlAttributes["name"]]["relfield"] = fieldElement.XmlAttributes["relfield"];
											rowdata[fieldElement.XmlAttributes["name"]]["reldata"] = reldata;
										}
									}
									// /If this field has a name
								}
								// /Make sure this element is a field
							}
							// /Loop through field tags
						}
						// /Loop through field tags
						ArrayAppend(stcData[table], rowdata);
					}
					// /Make sure this element is a row
				}
				// /Loop through rows
			}
		}
		// /Loop through data elements
		if ( Len(tables) ) {
			//  Loop through tables
			for ( i=1; i LTE ArrayLen(arrData); i=i+1 ) {
			//for ( i=1; i LTE ListLen(tables); i=i+1 ) {
				//table = ListGetAt(tables,i);
				table = arrData[i].XmlAttributes["table"];
				checkFields = "";
				onexists = "skip";
				if ( StructKeyExists(arrData[i].XmlAttributes,"checkFields") ) {
					checkFields = arrData[i].XmlAttributes["checkFields"];
				}
				if ( StructKeyExists(arrData[i].XmlAttributes,"onexists") AND arrData[i].XmlAttributes["onexists"] EQ "update" ) {
					onexists = "update";
				}
				qRecords = getPreSeedRecords(table);
				//  If table has seed records
				if ( ( StructKeyExists(stcData,table) AND ArrayLen(stcData[table]) ) AND ( arrData[i].XmlAttributes["permanentRows"] OR NOT qRecords.NumRecords ) ) {
					//  Loop through seed records
					for ( j=1; j LTE ArrayLen(stcData[table]); j=j+1 ) {
						data = StructNew();
						//  Loop through fields in table
						for ( col in stcData[table][j] ) {
							//  Simple val?
							if ( isSimpleValue(stcData[table][j][col]) ) {
								data[col] = stcData[table][j][col];
							} else {
								//  Struct?
								if ( isStruct(stcData[table][j][col]) ) {
									//  Get record of related data
									qRecord = getRecords(stcData[table][j][col]["reltable"],stcData[table][j][col]["reldata"]);
									if ( qRecord.RecordCount EQ 1 AND ListFindNoCase(qRecord.ColumnList,stcData[table][j][col]["relfield"]) ) {
										data[col] = qRecord[stcData[table][j][col]["relfield"]][1];
									}
								}
								// /Struct?
							}
							// /Simple val?
						}
						// /Loop through fields in table
						if ( StructCount(data) ) {
							seedRecord(table,data,onexists,checkFields);
						}
					}
					// /Loop through seed records
				}
				//  If table has seed records
			}
			// /Loop through tables
		}
		</cfscript>
	</cfif>
	
</cffunction>

<cffunction name="seedIndex" access="private" returntype="void" output="no">
	<cfargument name="indexname" type="string" required="yes">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="unique" type="boolean" default="false">
	<cfargument name="clustered" type="boolean" default="false">
	
	<cfset var UniqueSQL = "">
	<cfset var ClusteredSQL = "">
	
	<cfif arguments.unique>
		<cfset UniqueSQL = " unique">
	</cfif>
	<cfif arguments.clustered>
		<cfset ClusteredSQL = " CLUSTERED">
	</cfif>
	
	<cfif NOT hasIndex(arguments.tablename,arguments.indexname)>
		<cfset runSQL("CREATE#UniqueSQL##ClusteredSQL# INDEX #escape(arguments.indexname)# ON #escape(arguments.tablename)# (#arguments.fields#)")>
	</cfif>
	
</cffunction>

<cffunction name="seedIndexes" access="private" returntype="void" output="no">
	<cfargument name="xmldata" type="any" required="yes" hint="XML data of tables to load into DataMgr follows. Schema: http://www.bryantwebconsulting.com/cfc/DataMgr.xsd">
	
	<cfscript>
	var varXML = arguments.xmldata;
	var hasIndexes = false;
	var aIndexes = XmlSearch(varXML, "//index");
	var ii = 0;
	var sIndex = 0;
	
	for ( ii = 1; ii LTE ArrayLen(aIndexes); ii=ii+1 ) {
		if ( StructKeyExists(aIndexes[ii],"XmlAttributes") AND StructKeyExists(aIndexes[ii].XmlAttributes,"indexname") AND StructKeyExists(aIndexes[ii].XmlAttributes,"fields") ) {
			sIndex = aIndexes[ii].XmlAttributes;
			if ( StructKeyExists(aIndexes[ii].XmlAttributes,"table") ) {
				sIndex["tablename"] = aIndexes[ii].XmlAttributes.table;
			} else {
				if ( aIndexes[ii].XmlParent.XmlName EQ "indexes" AND StructKeyExists(aIndexes[ii].XmlParent.XmlAttributes,"table") ) {
					sIndex["tablename"] = aIndexes[ii].XmlParent.XmlAttributes["table"];
				}
				if ( aIndexes[ii].XmlParent.XmlName EQ "table" AND StructKeyExists(aIndexes[ii].XmlParent.XmlAttributes,"name") ) {
					sIndex["tablename"] = aIndexes[ii].XmlParent.XmlAttributes["name"];
				}
			}
			seedIndex(argumentCollection=sIndex);
		}
	}
	</cfscript>
	
</cffunction>

<cffunction name="hasIndex" access="private" returntype="boolean" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="indexname" type="string" required="yes">
	
	<cfreturn true>
</cffunction>

<cffunction name="seedRecord" access="private" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The table in which to insert data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="OnExists" type="string" default="insert" hint="The action to take if a record with the given values exists. Possible values: insert (inserts another record), error (throws an error), update (updates the matching record), skip (performs no action).">
	<cfargument name="checkFields" type="string" default="" hint="The fields to check for a matching record.">
	
	<cfset var result = 0>
	<cfset var key = 0>
	<cfset var sArgs = StructNew()>
	<cfset var qRecord = 0>
	
	<cfif Len(arguments.checkFields)>
		<!--- Compile data for get --->
		<cfloop collection="#arguments.data#" item="key">
			<cfif ListFindNoCase(arguments.checkFields,key)>
				<cfset sArgs[key] = arguments.data[key]>
			</cfif>
		</cfloop>
		<cfset qRecord = getRecords(arguments.tablename,sArgs)>
		<cfif qRecord.RecordCount>
			<cfif arguments.OnExists EQ "update">
				<cfset StructAppend(sArgs,QueryRowToStruct(qRecord),"no")>
				<cfset StructAppend(sArgs,arguments.data,"yes")>
				<cfset result = updateRecord(arguments.tablename,sArgs)>
			</cfif>
		<cfelse>
			<cfset result = insertRecord(argumentCollection=arguments)>
		</cfif>
	<cfelse>
		<cfset result = insertRecord(argumentCollection=arguments)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="skey" access="private" returntype="struct" output="no" hint="I return a structure for use in runSQLArray (I make a value key in the structure with the appropriate value).">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="val" type="string" required="yes">
	
	<cfset var result = StructNew()>
	
	<cfset result[arguments.name] = arguments.val>
	
	<cfreturn result>
</cffunction>

<cffunction name="StructFromArgs" access="private" returntype="struct" output="false" hint="">
	
	<cfset var sTemp = 0>
	<cfset var sResult = StructNew()>
	<cfset var key = "">
	
	<cfif StructCount(arguments) EQ 1 AND isStruct(arguments[1])>
		<cfset sTemp = arguments[1]>
	<cfelse>
		<cfset sTemp = arguments>
	</cfif>
	
	<!--- set all arguments into the return struct --->
	<cfloop collection="#sTemp#" item="key">
		<cfif StructKeyExists(sTemp, key)>
			<cfset sResult[key] = sTemp[key]>
		</cfif>
	</cfloop>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="StructKeyHasLen" access="private" returntype="numeric" output="no" hint="I check to see if the given key of the given structure exists and has a value with any length.">
	<cfargument name="Struct" type="struct" required="yes">
	<cfargument name="Key" type="string" required="yes">
	
	<cfset var result = false>
	
	<cfif StructKeyExists(arguments.Struct,arguments.Key) AND isSimpleValue(arguments.Struct[arguments.Key]) AND Len(arguments.Struct[arguments.Key])>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="sval" access="private" returntype="struct" output="no" hint="I return a structure for use in runSQLArray (I make a value key in the structure with the appropriate value).">
	<cfargument name="struct" type="struct" required="yes">
	<cfargument name="val" type="any" required="yes">
	
	<cfset var currval = DMDuplicate(arguments.val)>
	<cfset var sResult = DMDuplicate(arguments.struct)>
	
	<cfif IsSimpleValue(val)>
		<cfset sResult.value = currval>
	<cfelseif IsStruct(currval) AND StructKeyExists(sResult,"ColumnName") AND StructKeyExists(currval,sResult.ColumnName)>
		<cfset sResult.value = val[struct.ColumnName]>
	<cfelseif IsQuery(currval) AND StructKeyExists(sResult,"ColumnName") AND ListFindNoCase(currval.ColumnList,sResult.ColumnName)>
		<cfset sResult.value = currval[sResult.ColumnName][1]>
	<cfelse>
		<cfset throwDMError("Unable to add data to structure for #sResult.ColumnName#")>
	</cfif>
	
	<cfreturn sResult>
</cffunction>

<cffunction name="throwDMError" access="private" returntype="void" output="no">
	<cfargument name="message" type="string" required="yes">
	<cfargument name="errorcode" type="string" default="">
	<cfargument name="detail" type="string" default="">
	<cfargument name="extendedinfo" type="string" default="">
	
	<cfthrow message="#arguments.message#" errorcode="#arguments.errorcode#" detail="#arguments.detail#" type="DataMgr" extendedinfo="#arguments.extendedinfo#">
	
</cffunction>

<cffunction name="useField" access="private" returntype="boolean" output="no" hint="I check to see if the given field should be used in the SQL statement.">
	<cfargument name="Struct" type="struct" required="yes">
	<cfargument name="Field" type="struct" required="yes">
	
	<cfset var result = false>
	
	<cfif
			StructKeyHasLen(Struct,Field.ColumnName)
		AND	(
					isOfType(Struct[Field.ColumnName],getEffectiveFieldDataType(Field,true))
				OR	(
							StructKeyExists(Field,"Relation")
						AND	StructKeyExists(Field.Relation,"type")
						AND	Field.Relation.type EQ "list"
					)
			)
	>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>
<!---
Returns specific number of records starting with a specific row.
Renamed by RCamden
Version 2 with column name support by Christopher Bradford, christopher.bradford@aliveonline.com

@param theQuery      The query to work with. (Required)
@param StartRow      The row to start on. (Required)
@param NumberOfRows      The number of rows to return. (Required)
@param ColumnList      List of columns to return. Defaults to all the columns. (Optional)
@return Returns a query.
@author Kevin Bridges (christopher.bradford@aliveonline.comcyberswat@orlandoartistry.com)
@version 2, May 23, 2005
--->
<cffunction name="QuerySliceAndDice" access="private" returntype="query" output="false">
    <cfargument name="theQuery" type="query" required="true" />
    <cfargument name="StartRow" type="numeric" required="true" />
    <cfargument name="NumberOfRows" type="numeric" required="true" />
    <cfargument name="ColumnList" type="string" required="false" default="" />
    
    <cfscript>
    var FinalQuery = "";
    var EndRow = StartRow + NumberOfRows;
    var counter = 1;
    var x = "";
    var y = "";

    if (arguments.ColumnList IS "") {
        arguments.ColumnList = theQuery.ColumnList;
    }
    FinalQuery = QueryNew(arguments.ColumnList);
        
    if(EndRow GT theQuery.recordcount) {
        EndRow = theQuery.recordcount+1;
    }
    
    QueryAddRow(FinalQuery,EndRow - StartRow);
    
    for(x = 1; x LTE theQuery.recordcount; x = x + 1){
        if(x GTE StartRow AND x LT EndRow) {
            for(y = 1; y LTE ListLen(arguments.ColumnList); y = y + 1) {
                QuerySetCell(FinalQuery, ListGetAt(arguments.ColumnList, y), theQuery[ListGetAt(arguments.ColumnList, y)][x],counter);
            }
            counter = counter + 1;
        }
    }
        
    return FinalQuery;
    </cfscript>
    
</cffunction>
<cfscript>
/**
 * Makes a row of a query into a structure.
 *
 * @param query 	 The query to work with.
 * @param row 	 Row number to check. Defaults to row 1.
 * @return Returns a structure.
 * @author Nathan Dintenfass (nathan@changemedia.com)
 * @version 1, December 11, 2001
 */
function queryRowToStruct(query){
	//by default, do this to the first row of the query
	var row = 1;
	//a var for looping
	var ii = 1;
	//the cols to loop over
	var cols = listToArray(query.columnList);
	//the struct to return
	var stReturn = structnew();
	//if there is a second argument, use that for the row number
	if(arrayLen(arguments) GT 1)
		row = arguments[2];
	//loop over the cols and build the struct from the query row
	for(ii = 1; ii LTE arraylen(cols); ii = ii + 1){
		stReturn[cols[ii]] = query[cols[ii]][row];
	}
	//return the struct
	return stReturn;
}
</cfscript>

<cffunction name="getDatabaseXml" access="public" returntype="string" output="no" hint="I return the XML for the given table or for all tables in the database.">
	<cfargument name="indexes" type="boolean" default="false">
	
	<cfset var tables = getDatabaseTables()>
	<cfset var table = "">
	<cfset var result = "">
	<cfset var aFields = 0>
	<cfset var sField = 0>
	
<cfsavecontent variable="result"><cfoutput>
<tables><cfloop list="#tables#" index="table"><cfset aFields = getDBTableStruct(table)>
	<table name="#table#"><cfloop index="ii" from="1" to="#ArrayLen(aFields)#" step="1"><cfset sField = aFields[ii]>
		<field ColumnName="#sField.ColumnName#" CF_DataType="#sField.CF_DataType#"<cfif StructKeyExists(sField,"PrimaryKey") AND sField.PrimaryKey IS true> PrimaryKey="true"</cfif><cfif StructKeyExists(sField,"Increment") AND sField.Increment IS true> Increment="true"</cfif><cfif StructKeyExists(sField,"Length") AND isNumeric(sField.Length) AND sField.Length GT 0> Length="#Int(sField.Length)#"</cfif><cfif StructKeyExists(sField,"Default") AND Len(sField.Default)> Default="#sField.Default#"</cfif><cfif StructKeyExists(sField,"Precision") AND isNumeric(sField["Precision"])> Precision="#sField["Precision"]#"</cfif><cfif StructKeyExists(sField,"Scale") AND isNumeric(sField["Scale"])> Scale="#sField["Scale"]#"</cfif> AllowNulls="#sField["AllowNulls"]#" /></cfloop><cfif arguments.indexes AND isDefined("getDBTableIndexes")><cfset qIndexes = getDBTableIndexes(tablename=table)><cfloop query="qIndexes">
		<index indexname="#indexname#" fields="#fields#"<cfif isBoolean(unique) AND unique> unique="true"</cfif><cfif isBoolean(clustered) AND clustered> clustered="true"</cfif> /></cfloop></cfif>
	</table></cfloop>
</tables>
</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

<cffunction name="getXML" access="public" returntype="string" output="no" hint="I return the XML for the given table or for all loaded tables if none given.">
	<cfargument name="tablename" type="string" required="no">
	<cfargument name="indexes" type="boolean" default="false">
	<cfargument name="showroot" type="boolean" default="true">
	
	<cfset var result = "">
	
	<cfset var table = "">
	<cfset var i = 0>
	<cfset var rAtts = "table,type,field,join-table,join-field,join-field-local,join-field-remote,fields,delimiter,onDelete,onMissing">
	<cfset var rKey = "">
	<cfset var sTables = 0>
	<cfset var qIndexes = 0>
	
	<cfif StructKeyExists(arguments,"tablename")>
		<cfset checkTable(arguments.tablename)><!--- Check whether table is loaded --->
	</cfif>
	
	<cfinvoke method="getTableData" returnvariable="sTables">
		<cfif StructKeyExists(arguments,"tablename") AND Len(arguments.tablename)>
			<cfinvokeargument name="tablename" value="#arguments.tablename#">
		</cfif>
	</cfinvoke>

<cfsavecontent variable="result"><cfoutput>
<cfif arguments.showroot><tables></cfif><cfloop collection="#sTables#" item="table">
	<table name="#table#"><cfloop index="i" from="1" to="#ArrayLen(sTables[table])#" step="1"><cfif StructKeyExists(sTables[table][i],"CF_DataType")>
		<field ColumnName="#sTables[table][i].ColumnName#"<cfif StructKeyHasLen(sTables[table][i],"alias")> alias="#sTables[table][i].alias#"</cfif> CF_DataType="#sTables[table][i].CF_DataType#"<cfif StructKeyExists(sTables[table][i],"PrimaryKey") AND isBoolean(sTables[table][i].PrimaryKey) AND sTables[table][i].PrimaryKey> PrimaryKey="true"</cfif><cfif StructKeyExists(sTables[table][i],"Increment") AND isBoolean(sTables[table][i].Increment) AND sTables[table][i].Increment> Increment="true"</cfif><cfif StructKeyExists(sTables[table][i],"Length") AND isNumeric(sTables[table][i].Length) AND sTables[table][i].Length GT 0> Length="#Int(sTables[table][i].Length)#"</cfif><cfif StructKeyExists(sTables[table][i],"Default") AND Len(sTables[table][i].Default)> Default="#sTables[table][i].Default#"</cfif><cfif StructKeyExists(sTables[table][i],"Precision") AND isNumeric(sTables[table][i]["Precision"])> Precision="#sTables[table][i]["Precision"]#"</cfif><cfif StructKeyExists(sTables[table][i],"Scale") AND isNumeric(sTables[table][i]["Scale"])> Scale="#sTables[table][i]["Scale"]#"</cfif> AllowNulls="#sTables[table][i]["AllowNulls"]#"<cfif StructKeyExists(sTables[table][i],"Special") AND Len(sTables[table][i]["Special"])> Special="#sTables[table][i]["Special"]#"</cfif> /><cfelseif StructKeyExists(sTables[table][i],"Relation")>
		<field ColumnName="#sTables[table][i].ColumnName#">
			<relation<cfloop index="rKey" list="#rAtts#"><cfif StructKeyExists(sTables[table][i].Relation,rKey)> #rKey#="#XmlFormat(sTables[table][i].Relation[rKey])#"</cfif></cfloop><cfloop collection="#sTables[table][i].Relation#" item="rKey"><cfif NOT ListFindNoCase(rAtts,rKey)> #LCase(rKey)#="#XmlFormat(sTables[table][i].Relation[rKey])#"</cfif></cfloop> />
		</field></cfif></cfloop><cfif arguments.indexes AND isDefined("getDBTableIndexes")><cfset qIndexes = getDBTableIndexes(tablename=table)><cfloop query="qIndexes">
		<index indexname="#indexname#" fields="#fields#"<cfif isBoolean(unique) AND unique> unique="true"</cfif><cfif isBoolean(clustered) AND clustered> clustered="true"</cfif> /></cfloop></cfif><cfif StructCount(variables.tableprops[table]["filters"])><cfloop collection="#variables.tableprops[table].filters#" item="i">
		<filter name="#i#" field="#variables.tableprops[table].filters[i].field#" operator="#XmlFormat(variables.tableprops[table].filters[i].operator)#" /></cfloop></cfif>
	</table></cfloop><cfif arguments.showroot>
</tables></cfif>
</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

<cffunction name="da" access="private"><cfdump var="#arguments#"><cfabort></cffunction>
</cfcomponent>