<!--- 2.2.0.2 (Build 151) --->
<!--- Last Updated: 2009-06-13 --->
<!--- Created by Steve Bryant 2004-12-08 --->
<!--- Created by Salvatore Fusto 2010-03-02 --->
<cfcomponent extends="DataMgr" displayname="Data Manager for H2" hint="I manage data interactions with the H2 database.">

<cffunction name="getDatabase" access="public" returntype="string" output="no" hint="I return the database platform being used (Access,MS SQL,MySQL etc).">
	<cfreturn "H2">
</cffunction>

<cffunction name="getDatabaseShortString" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "H2">
</cffunction>

<cffunction name="getDatabaseDriver" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "H2">
</cffunction>

<cffunction name="sqlCreateColumn" access="public" returntype="any" output="false" hint="">
	<cfargument name="field" type="struct" required="yes">
	
	<cfset var sField = adjustColumnArgs(arguments.field)>
	<cfset var type = getDBDataType(sField.CF_DataType)>
	<cfset var result = "">
	
	<cfsavecontent variable="result"><cfoutput>#escape(sField.ColumnName)# #type#<cfif isStringType(type)> (#sField.Length#)<cfelseif getTypeOfCFType(sField.CF_DataType) EQ "numeric" AND StructKeyExists(sField,"scale") AND StructKeyExists(sField,"precision")>(#Val(sField.precision)#,#Val(sField.scale)#)</cfif><cfif sField.Increment> IDENTITY (1, 1)</cfif><cfif Len(Trim(sField.Default))> DEFAULT #sField.Default#<cfelseif sField.PrimaryKey AND sField.CF_DataType EQ "CF_SQL_IDSTAMP"> DEFAULT (newid())</cfif> <cfif sField.PrimaryKey OR NOT sField.AllowNulls>NOT </cfif>NULL</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

<cffunction name="getCreateSQL" access="public" returntype="string" output="no" hint="I return the SQL to create the given table.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var ii = 0><!--- generic counter --->
	<cfset var arrFields = getFields(arguments.tablename)><!--- table structure --->
	<cfset var CreateSQL = ""><!--- holds sql to create table --->
	<cfset var pkfields = "">
	<cfset var thisField = "">
	
	<!--- Find Primary Key fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(arrFields)#" step="1">
		<cfif arrFields[ii].PrimaryKey>
			<cfset pkfields = ListAppend(pkfields,arrFields[ii].ColumnName)>
		</cfif>
	</cfloop>
	
	<!--- create sql to create table --->
	<cfsavecontent variable="CreateSQL"><cfoutput>
	<!--- IF NOT EXISTS(SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '#arguments.tablename#') --->
	CREATE TABLE IF NOT EXISTS #escape(arguments.tablename)# (<cfloop index="ii" from="1" to="#ArrayLen(arrFields)#" step="1">
		#sqlCreateColumn(arrFields[ii])#<cfif ii LT ArrayLen(arrFields) OR Len(pkfields)>,</cfif></cfloop>
		<cfif Len(pkfields)>primary key (#pkfields#)</cfif>
	)
	<!--- GO --->
	</cfoutput></cfsavecontent>
	
	<cfreturn CreateSQL>
</cffunction>

<cffunction name="concat" access="public" returntype="string" output="no" hint="I return the SQL to concatenate the given fields with the given delimeter.">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="delimeter" type="string" default="">
	
	<cfset var colname = "">
	<cfset var result = "">
	
	<cfloop index="colname" list="#arguments.fields#">
		<cfif Len(result)>
			<cfset result =  "#result# + '#arguments.delimeter#' + CAST(#colname# AS varchar(500))">
		<cfelse>
			<cfset result = "CAST(#colname# AS varchar(500))">
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="concatFields" access="public" returntype="array" output="no" hint="I return the SQL to concatenate the given fields with the given delimeter.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="delimeter" type="string" default=",">
	<cfargument name="tablealias" type="string" required="no">
	
	<cfset var col = "">
	<cfset var aSQL = ArrayNew(1)>
	<cfset var fieldSQL = 0>
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>
	
	<cfloop index="col" list="#arguments.fields#">
		<cfset fieldSQL = getFieldSelectSQL(tablename=arguments.tablename,field=col,tablealias=arguments.tablealias,useFieldAlias=false)>
		<cfif ArrayLen(aSQL)>
			<cfset ArrayAppend(aSQL," + '#arguments.delimeter#' + ")>
		</cfif>
		<cfif isSimpleValue(fieldSQL)>
			<cfset ArrayAppend(aSQL,"ISNULL(CAST(#fieldSQL# AS varchar(500)),'')")>
		<cfelse>
			<cfset ArrayAppend(aSQL,"ISNULL(CAST(")>
			<cfset ArrayAppend(aSQL,fieldSQL)>
			<cfset ArrayAppend(aSQL," AS varchar(500)),'')")>
		</cfif>
	</cfloop>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="escape" access="public" returntype="string" output="no" hint="I return an escaped value for a table or field.">
	<cfargument name="name" type="string" required="yes">
	
	<cfset var result = "">
	<cfset var item = "">
	
	<cfloop index="item" list="#arguments.name#" delimiters=".">
		<cfset result = ListAppend(result,"#item#",".")>
	</cfloop>
	<cfreturn result>
</cffunction>

<cffunction name="getDatabaseTables" access="public" returntype="string" output="no" hint="I get a list of all tables in the current database.">

	<cfset var qTables = 0>
	
	<cfset qTables = runSQL("SELECT Table_Name FROM INFORMATION_SCHEMA.TABLES WHERE table_type = 'table'")>
	<cfreturn ValueList(qTables.Table_Name)>
</cffunction>

<cffunction name="getDBTableStruct" access="public" returntype="array" output="no" hint="I return the structure of the given table in the database.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfscript>
	var qStructure = 0;
	var qPrimaryKeys = 0;
	var qIndices = 0;
	var TableData = ArrayNew(1);
	var tmpStruct = StructNew();
	var PrimaryKeys = "";
	var sqlarray = ArrayNew(1);
	</cfscript>
	
	<cfset sqlarray = ArrayNew(1)>
	<cfset ArrayAppend(sqlarray,"SELECT")>
	<cfset ArrayAppend(sqlarray,"			COLUMN_NAME AS Field,")>
	<cfset ArrayAppend(sqlarray,"			TYPE_NAME AS Type,")>
	<cfset ArrayAppend(sqlarray,"			CHARACTER_MAXIMUM_LENGTH AS MaxLength,")>
	<cfset ArrayAppend(sqlarray,"			IS_NULLABLE AS AllowNulls,")>
	<cfset ArrayAppend(sqlarray,"			Column_Default as #escape("Default")#,")>	
	<cfset ArrayAppend(sqlarray,"			NUMERIC_PRECISION AS Precision,")>
	<cfset ArrayAppend(sqlarray,"			NUMERIC_SCALE AS Scale")>
	<cfset ArrayAppend(sqlarray,"FROM		INFORMATION_SCHEMA.COLUMNS")>
	<cfset ArrayAppend(sqlarray,"WHERE		table_name = '#arguments.tablename#'")>
	<cfset ArrayAppend(sqlarray,"ORDER BY	Ordinal_Position")>
	<cfset qStructure = runSQLArray(sqlarray)>
	
	<cfif qStructure.RecordCount eq 0>
		<cfthrow message="Data Manager: No such table (#arguments.tablename#). Trying to load a table that doesn't exist." type="DataMgr">
	</cfif>
	
	<cfset sqlarray = ArrayNew(1)>
	<cfset ArrayAppend(sqlarray,"SELECT		Column_Name")>
	<cfset ArrayAppend(sqlarray," FROM		INFORMATION_SCHEMA.INDEXES")>
	<cfset ArrayAppend(sqlarray," WHERE		INFORMATION_SCHEMA.INDEXES.Table_Name = '#arguments.tablename#'")>
	<cfset ArrayAppend(sqlarray," AND		INFORMATION_SCHEMA.INDEXES.PRIMARY_KEY = 'TRUE'")>
	<cfset qPrimaryKeys = runSQLArray(sqlarray)>
<!--- 	
	<cfset ArrayAppend(sqlarray,"SELECT		Column_Name")>
	<cfset ArrayAppend(sqlarray,"FROM		INFORMATION_SCHEMA.TABLE_CONSTRAINTS")>
	<cfset ArrayAppend(sqlarray,"INNER JOIN	INFORMATION_SCHEMA.KEY_COLUMN_USAGE")>
	<cfset ArrayAppend(sqlarray,"	ON		INFORMATION_SCHEMA.TABLE_CONSTRAINTS.CONSTRAINT_NAME = INFORMATION_SCHEMA.KEY_COLUMN_USAGE.CONSTRAINT_NAME")>
	<cfset ArrayAppend(sqlarray,"WHERE		INFORMATION_SCHEMA.TABLE_CONSTRAINTS.Table_Name = '#arguments.tablename#'")>
	<cfset ArrayAppend(sqlarray,"	AND		CONSTRAINT_TYPE = 'PRIMARY KEY'")>
	
	<cfset qPrimaryKeys = runSQLArray(sqlarray)>
 --->	
	<cfif qPrimaryKeys.RecordCount>
		<cfset PrimaryKeys = ValueList(qPrimaryKeys.Column_Name)>
	</cfif>
	<!--- <cfdump var="#qStructure#"><cfabort> --->
	<cfoutput query="qStructure">
		<cfset tmpStruct = StructNew()>
		<cfset tmpStruct["ColumnName"] = Field>
		<cfset tmpStruct["CF_DataType"] = getCFDataType(Type)>
		<cfif ListFindNoCase(PrimaryKeys,Field)>
			<cfset tmpStruct["PrimaryKey"] = true>
			<cfset tmpStruct["Increment"] = true>
		<cfelse>
			<cfset tmpStruct["PrimaryKey"] = false>
			<cfset tmpStruct["Increment"] = false>
		</cfif>
<!---  	
		<cfif isBoolean(Trim(IsIdentity))>
			<cfset tmpStruct["Increment"] = IsIdentity>
		<cfelse>
			<cfset tmpStruct["Increment"] = false>
		</cfif>
--->			
		<cfif Len(MaxLength) AND isNumeric(MaxLength) AND NOT tmpStruct["CF_DataType"] eq "CF_SQL_LONGVARCHAR">
			<cfset tmpStruct["length"] = MaxLength>
		</cfif>
		<cfif isBoolean(Trim(AllowNulls))>
			<cfset tmpStruct["AllowNulls"] = Trim(AllowNulls)>
		<cfelse>
			<cfset tmpStruct["AllowNulls"] = true>
		</cfif>
		<cfset tmpStruct["Precision"] = Precision>
		<cfset tmpStruct["Scale"] = Scale>
		<cfif Len(Default)>
			<cfset tmpStruct["Default"] = Default>
		</cfif>
		<cfset tmpStruct["Special"] = "">
		
		<cfif Len(tmpStruct.CF_DataType)>
			<cfset ArrayAppend(TableData,StructCopy(tmpStruct))>
		</cfif>
	</cfoutput>
	<!--- <cfdump var="#tabledata#"><cfabort> --->
	<cfreturn TableData>
</cffunction>

<cffunction name="getCFDataType" access="public" returntype="string" output="no" hint="I return the cfqueryparam datatype from the database datatype.">
	<cfargument name="type" type="string" required="yes" hint="The database data type.">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.type#">
		<cfcase value="bigint"><cfset result = "CF_SQL_BIGINT"></cfcase>
		<cfcase value="binary,image,sql_variant,sysname,varbinary"><cfset result = ""></cfcase>
		<cfcase value="bit"><cfset result = "CF_SQL_BIT"></cfcase>
		<cfcase value="char"><cfset result = "CF_SQL_CHAR"></cfcase>
		<cfcase value="datetime"><cfset result = "CF_SQL_DATE"></cfcase>
		<cfcase value="decimal"><cfset result = "CF_SQL_DECIMAL"></cfcase>
		<cfcase value="float"><cfset result = "CF_SQL_FLOAT"></cfcase>
		<cfcase value="int"><cfset result = "CF_SQL_INTEGER"></cfcase>
		<cfcase value="money"><cfset result = "CF_SQL_MONEY"></cfcase>
		<cfcase value="nchar"><cfset result = "CF_SQL_CHAR"></cfcase>
		<cfcase value="ntext"><cfset result = "CF_SQL_LONGVARCHAR"></cfcase>
		<cfcase value="numeric"><cfset result = "CF_SQL_NUMERIC"></cfcase>
		<cfcase value="nvarchar"><cfset result = "CF_SQL_VARCHAR"></cfcase>
		<cfcase value="real"><cfset result = "CF_SQL_REAL"></cfcase>
		<cfcase value="smalldatetime"><cfset result = "CF_SQL_DATE"></cfcase>
		<cfcase value="smallint"><cfset result = "CF_SQL_SMALLINT"></cfcase>
		<cfcase value="smallmoney"><cfset result = "CF_SQL_MONEY4"></cfcase>
		<cfcase value="text"><cfset result = "CF_SQL_LONGVARCHAR"></cfcase>
		<cfcase value="timestamp"><cfset result = "CF_SQL_TIMESTAMP"></cfcase>
		<cfcase value="tinyint"><cfset result = "CF_SQL_TINYINT"></cfcase>
		<cfcase value="uniqueidentifier"><cfset result = "CF_SQL_IDSTAMP"></cfcase>
		<cfcase value="varchar"><cfset result = "CF_SQL_VARCHAR"></cfcase>
		<cfdefaultcase><cfset result = ""></cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getDBDataType" access="public" returntype="string" output="no" hint="I return the database datatype from the cfqueryparam datatype.">
	<cfargument name="CF_Datatype" type="string" required="yes">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.CF_Datatype#">
		<cfcase value="CF_SQL_BIGINT"><cfset result = "bigint"></cfcase>
		<cfcase value="CF_SQL_BIT"><cfset result = "bit"></cfcase>
		<cfcase value="CF_SQL_CHAR"><cfset result = "char"></cfcase>
		<cfcase value="CF_SQL_DATE"><cfset result = "datetime"></cfcase>
		<cfcase value="CF_SQL_DECIMAL"><cfset result = "decimal"></cfcase>
		<cfcase value="CF_SQL_DOUBLE"><cfset result = "float"></cfcase>
		<cfcase value="CF_SQL_FLOAT"><cfset result = "float"></cfcase>
		<cfcase value="CF_SQL_IDSTAMP"><cfset result = "uniqueidentifier"></cfcase>
		<cfcase value="CF_SQL_INTEGER"><cfset result = "int"></cfcase>
		<cfcase value="CF_SQL_LONGVARCHAR"><cfset result = "text"></cfcase>
		<cfcase value="CF_SQL_MONEY"><cfset result = "money"></cfcase>
		<cfcase value="CF_SQL_MONEY4"><cfset result = "smallmoney"></cfcase>
		<cfcase value="CF_SQL_NUMERIC"><cfset result = "numeric"></cfcase>
		<cfcase value="CF_SQL_REAL"><cfset result = "real"></cfcase>
		<cfcase value="CF_SQL_SMALLINT"><cfset result = "smallint"></cfcase>
		<cfcase value="CF_SQL_TIMESTAMP"><cfset result = "timestamp"></cfcase>
		<cfcase value="CF_SQL_TINYINT"><cfset result = "tinyint"></cfcase>
		<cfcase value="CF_SQL_VARCHAR"><cfset result = "varchar"></cfcase>
		<cfdefaultcase><cfthrow message="DataMgr object cannot handle this data type." type="DataMgr" detail="DataMgr cannot handle data type '#arguments.CF_Datatype#'" errorcode="InvalidDataType"></cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldSQL_Has" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="tablealias" type="string" required="no">
	
	<cfset var sField = getField(arguments.tablename,arguments.field)>
	<cfset var dtype = getEffectiveDataType(arguments.tablename,sField.Relation.field)>
	<cfset var aSQL = ArrayNew(1)>
	<cfset var sAdvSQL = StructNew()>
	<cfset var sJoin = StructNew()>
	<cfset var sArgs = StructNew()>
	<cfset var temp = "">
	
	<cfswitch expression="#dtype#">
	<cfcase value="numeric">
		<cfset ArrayAppend(aSQL,"CASE WHEN (")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,") > 0 THEN 1 ELSE 0 END")>
	</cfcase>
	<cfcase value="string">
		<cfset ArrayAppend(aSQL,"CASE WHEN ( isnull(len(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,"),0) ) > 0 THEN 1 ELSE 0 END")>
	</cfcase>
	<cfcase value="date">
		<cfset ArrayAppend(aSQL,"CASE WHEN (")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,") IS NULL THEN 0 ELSE 1 END")>
	</cfcase>
	<cfcase value="boolean">
		<cfset ArrayAppend(aSQL,"isnull(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,",0)")>
	</cfcase>
	</cfswitch>
	
	<cfreturn aSQL>	
</cffunction>

<cffunction name="getNowSQL" access="public" returntype="string" output="no" hint="I return the SQL for the current date/time.">
	<cfreturn "getDate()">
</cffunction>

<cffunction name="insertRecord2" access="public" returntype="string" output="no" hint="I insert a record into the given table with the provided data and do my best to return the primary key of the inserted record.">
	<cfargument name="tablename" type="string" required="yes" hint="The table in which to insert data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="OnExists" type="string" default="insert" hint="The action to take if a record with the given values exists. Possible values: insert (inserts another record), error (throws an error), update (updates the matching record), skip (performs no action), save (updates only for matching primary key)).">
	
	<cfset var OnExistsValues = "insert,error,update,skip"><!--- possible values for OnExists argument --->
	<cfset var i = 0><!--- generic counter --->
	<cfset var fieldcount = 0><!--- count of fields --->
	<cfset var fields = getUpdateableFields(arguments.tablename)>
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var in = clean(arguments.data)><!--- holder for incoming data (just for readability) --->
	<cfset var inPK = StructNew()><!--- holder for incoming pk data (just for readability) --->
	<cfset var qGetRecords = QueryNew('none')>
	<cfset var result = ""><!--- will hold primary key --->
	<cfset var qCheckKey = 0><!--- Used to get primary key --->
	<cfset var bSetGuid = false><!--- Set GUID (SQL Server specific) --->
	<cfset var GuidVar = "GUID"><!--- var to create variable name for GUID (SQL Server specific) --->
	<cfset var inf = "">
	<cfset var sqlarray = ArrayNew(1)>
	
	<!--- Create GUID for insert SQL Server where the table has on primary key field and it is a GUID --->
	<cfif ArrayLen(pkfields) EQ 1 AND pkfields[1].CF_Datatype eq "CF_SQL_IDSTAMP" AND getDatabase() eq "MS SQL" AND NOT StructKeyExists(in,pkfields[1].ColumnName)>
		<cfset bSetGuid = true>
	</cfif>
	
	<!--- Create variable to hold GUID for SQL Server GUID inserts --->
	<cfif bSetGuid>
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
	
	<!--- Check for existing records if an action other than insert should be take if one exists --->
	<cfif arguments.OnExists NEQ "insert">
		<cfif ArrayLen(pkfields)>
			<!--- Load up all primary key fields in temp structure --->
			<cfloop index="i" from="1" to="#ArrayLen(pkfields)#" step="1">
				<cfif StructKeyHasLen(in,pkfields[i].ColumnName)>
					<cfset inPK[pkfields[i].ColumnName] = in[pkfields[i].ColumnName]>
				</cfif>
			</cfloop>
		</cfif>
		
		<!--- Try to get existing record with given data --->
		<cfif arguments.OnExists NEQ "save" AND arguments.OnExists NEQ "skip">
				<!--- Use only pkfields if all are passed in, otherwise use all data available --->
				<cfif ArrayLen(pkfields)>
					<cfif StructCount(inPK) EQ ArrayLen(pkfields)>
						<cflock name="DataMgr_InsertCheck_#arguments.tablename#" timeout="30">
							<cfset qGetRecords = getRecords(tablename=arguments.tablename,data=inPK,fieldlist=StructKeyList(inPK))>
						</cflock>
					<cfelse>
						<cflock name="DataMgr_InsertCheck_#arguments.tablename#" timeout="30">
							<cfset qGetRecords = getRecords(tablename=arguments.tablename,data=in,fieldlist=StructKeyList(inPK))>
						</cflock>
					</cfif>
				<cfelse>
					<cflock name="DataMgr_InsertCheck_#arguments.tablename#" timeout="30">
						<cfset qGetRecords = getRecords(tablename=arguments.tablename,data=in,fieldlist=StructKeyList(in))>
					</cflock>
				</cfif>
		</cfif>
		
		<!--- If no matching records by all fields, Check for existing record by primary keys --->
		<cfif arguments.OnExists EQ "save" OR arguments.OnExists EQ "update" OR qGetRecords.RecordCount EQ 0>
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
			<cfthrow message="#arguments.tablename#: A record with these criteria already exists." type="DataMgr">
		</cfcase>
		<cfcase value="update,save">
			<cfloop index="i" from="1" to="#ArrayLen(pkfields)#" step="1">
				<cfset in[pkfields[i].ColumnName] = qGetRecords[pkfields[i].ColumnName][1]>
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
	<cflock timeout="30" throwontimeout="No" name="DataMgr_Insert_#arguments.tablename#" type="EXCLUSIVE">
		<cfset sqlarray = getInsertRecordsSQL(tablename=arguments.tablename,data_set=in,data_where=in)>
		<cfinvoke returnvariable="sqlarray" method="getInsertRecordsSQL">
			<cfinvokeargument name="tablename" value="#arguments.tablename#">
			<cfinvokeargument name="data_set" value="#in#">
			<cfif ListFindNoCase("update,save,skip",arguments.OnExists)>
				<cfif StructCount(inPK)>
					<cfinvokeargument name="data_where" value="#inPK#">
				<cfelse>
					<cfinvokeargument name="data_where" value="#in#">
				</cfif>
			</cfif>
		</cfinvoke>
		<cfset qCheckKey = runSQLArray(sqlarray)>
	</cflock>
	
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
	<cfif Len(result) AND ArrayLen(pkfields)>
		<cfset in[pkfields[1].ColumnName] = result>
		<cfset saveRelations(arguments.tablename,in,pkfields[1],result)>
	</cfif>
	
	<!--- Log insert --->
	<cfif variables.doLogging AND NOT arguments.tablename eq variables.logtable>
		<cfinvoke method="logAction">
			<cfinvokeargument name="tablename" value="#arguments.tablename#">
			<cfif ArrayLen(pkfields) eq 1 AND StructKeyExists(in,pkfields[1].ColumnName)>
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

<cffunction name="getInsertRecordsSQL" access="public" returntype="array" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="data_set" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="data_where" type="struct" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="filters" type="array" default="#ArrayNew(1)#">
	
	<cfset var bSetGuid = false>
	<cfset var GuidVar = "">
	<cfset var sqlarray = ArrayNew(1)>
	<cfset var ii = 0>
	<cfset var fieldcount = 0>
	<cfset var bUseSubquery = false>
	<cfset var fields = getUpdateableFields(arguments.tablename)>
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var in = arguments.data_set><!--- holder for incoming data (just for readability) --->
	<cfset var inf = "">
	
	<cfset in = getRelationValues(arguments.tablename,in)>
	
	<cfif StructKeyExists(arguments,"guid") AND isBoolean(arguments.guid) AND arguments.guid>
		<cfset bSetGuid = true>
	</cfif>
	
	<cfif StructKeyExists(arguments,"data_where") AND StructCount(arguments.data_where)>
		<cfset bUseSubquery = true>
	</cfif>
	
	<!--- Create variable to hold GUID for SQL Server GUID inserts --->
	<cfif bSetGuid>
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
	
	<!--- Check for specials --->
	<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif StructKeyExists(fields[ii],"Special") AND Len(fields[ii].Special) AND NOT StructKeyExists(in,fields[ii].ColumnName)>
			<!--- Set fields based on specials --->
			<!--- CreationDate has db default as of 2.2, but won't if fields were created earlier (or if no real db) --->
			<cfswitch expression="#fields[ii].Special#">
			<cfcase value="CreationDate">
				<cfset in[fields[ii].ColumnName] = now()>
			</cfcase>
			<cfcase value="LastUpdatedDate">
				<cfset in[fields[ii].ColumnName] = now()>
			</cfcase>
			<cfcase value="Sorter">
				<cfset in[fields[ii].ColumnName] = getNewSortNum(arguments.tablename,fields[ii].ColumnName)>
			</cfcase>
			</cfswitch>
		</cfif>
	</cfloop>
	
	<!--- Insert record --->
	<cfif bSetGuid>
		<cfset ArrayAppend(sqlarray,"DECLARE @#GuidVar# uniqueidentifier")>
		<cfset ArrayAppend(sqlarray,"SET @#GuidVar# = NEWID()")>
	</cfif>
	<cfset ArrayAppend(sqlarray,"INSERT INTO #escape(arguments.tablename)# (")>
	
	<!--- Loop through all updateable fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif
				( useField(in,fields[ii]) OR (StructKeyExists(fields[ii],"Default") AND Len(fields[ii].Default) AND getDatabase() EQ "Access") )
			OR	NOT ( useField(in,fields[ii]) OR StructKeyExists(fields[ii],"Default") OR fields[ii].AllowNulls )
		><!--- Include the field in SQL if it has appropriate data --->
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,escape(fields[ii].ColumnName))>
		</cfif>
	</cfloop>
	<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif ( useField(in,pkfields[ii]) AND NOT isIdentityField(pkfields[ii]) ) OR ( pkfields[ii].CF_Datatype eq "CF_SQL_IDSTAMP" AND bSetGuid )><!--- Include the field in SQL if it has appropriate data --->
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,"#escape(pkfields[ii].ColumnName)#")>
		</cfif>
	</cfloop>
	<cfset ArrayAppend(sqlarray,")")>
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
		<cfelseif pkfields[ii].CF_Datatype eq "CF_SQL_IDSTAMP" AND bSetGuid>
			<cfset fieldcount = fieldcount + 1>
			<cfif fieldcount GT 1>
				<cfset ArrayAppend(sqlarray,",")><!--- put a comma before every field after the first --->
			</cfif>
			<cfset ArrayAppend(sqlarray,"@#GuidVar#")>
		</cfif>
	</cfloop><cfif fieldcount eq 0><cfsavecontent variable="inf"><cfdump var="#in#"></cfsavecontent><cfthrow message="You must pass in at least one field that can be inserted into the database. Fields: #inf#" type="DataMgr" errorcode="NeedInsertFields"></cfif>
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
	</cfif>
	
	<cfreturn sqlarray>
</cffunction>

<cffunction name="isValidDate" access="public" returntype="boolean" output="no">
	<cfargument name="value" type="string" required="yes">
	
	<cfreturn isDate(arguments.value) AND Year(arguments.value) GTE 1753 AND arguments.value LT CreateDate(2079,6,7)>
</cffunction>

<cffunction name="checkTable" access="private" returntype="boolean" output="no" hint="I check to see if the given table exists in the Datamgr.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfif NOT StructKeyExists(variables.tables,arguments.tablename)>
		<cfset loadTable(arguments.tablename)>
	</cfif>
	
	<cfreturn true>
</cffunction>

<cffunction name="getDBTableIndexes" access="public" returntype="query" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="indexname" type="string" required="no">
	
	<cfset var sql = "">
	<cfset var fields = "">
	<cfset var qRawIndexes = 0>
	<cfset var qIndexes = QueryNew("tablename,indexname,fields,unique,clustered")>
	
	<cfsavecontent variable="sql"><cfoutput>
	SELECT		object_name(i.id) AS table_name,
				col_name(i.id, ik.colid) AS column_name,
				i.name AS index_name,
				indexproperty(i.id, i.name, 'IsClustered') AS isclustered,
				ik.keyno AS index_order,
				INDEXPROPERTY( i.id , i.name , 'IsUnique' ) AS isunique
	FROM		sysindexes i
	JOIN		sysindexkeys ik
		ON		i.id = ik.id
		AND		i.indid = ik.indid
	WHERE		i.indid BETWEEN 1 AND 254
		AND 	indexproperty(i.id, name, 'IsHypothetical') = 0
		AND 	indexproperty(i.id, name, 'IsStatistics') = 0
		AND 	indexproperty(i.id, name, 'IsAutoStatistics') = 0
		AND 	objectproperty(i.id, 'IsMsShipped') = 0
		AND		object_name(i.id) = '#arguments.tablename#'
		<cfif StructKeyExists(arguments,"indexname")>
		AND 	i.name = '#arguments.indexname#'
		</cfif>
		AND		NOT i.name LIKE 'PK_%'
	ORDER BY	table_name, i.id, ik.colid, isclustered DESC, ik.keyno
	</cfoutput></cfsavecontent>
	
	<cfset qRawIndexes = runSQL(sql)>
	
	<cfoutput query="qRawIndexes" group="index_name">
		<cfset fields = "">
		<cfset QueryAddRow(qIndexes)>
		<cfset QuerySetCell(qIndexes,"tablename",table_name)>
		<cfset QuerySetCell(qIndexes,"indexname",index_name)>
		<cfset QuerySetCell(qIndexes,"unique",isunique)>
		<cfset QuerySetCell(qIndexes,"clustered",isclustered)>
		<cfoutput>
			<cfset fields = ListAppend(fields,column_name)>
		</cfoutput>
		<cfset QuerySetCell(qIndexes,"fields",fields)>
	</cfoutput>
	
	<cfreturn qIndexes>
</cffunction>

<cffunction name="getInsertedIdentity" access="private" returntype="string" output="no" hint="I get the value of the identity field that was just inserted into the given table.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="identfield" type="string" required="yes">
	
	<cfset var qCheckKey = 0>
	<cfset var result = 0>
	
	<cfset qCheckKey = runSQL("SELECT IDENTITY() AS newID")>
	<cfset result = qCheckKey.NewID>
	
	<cfreturn result>
</cffunction>

<cffunction name="hasIndex" access="private" returntype="boolean" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="indexname" type="string" required="yes">
	
	<cfset var result = false>
	<cfset var qIndexes = RunSQL("
	SELECT	1
	FROM	sysindexes
	WHERE	name = '#arguments.indexname#'
	")>
	
	<cfif qIndexes.RecordCount>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="isStringType" access="private" returntype="boolean" output="no" hint="I indicate if the given datatype is valid for string data.">
	<cfargument name="type" type="string">

	<cfset var strtypes = "char,nchar,nvarchar,varchar">
	<cfset var result = false>
	<cfif ListFindNoCase(strtypes,arguments.type)>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

</cfcomponent>