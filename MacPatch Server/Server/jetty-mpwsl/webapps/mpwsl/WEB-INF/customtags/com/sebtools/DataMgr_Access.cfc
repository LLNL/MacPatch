<!--- 2.5 Beta 2 (Build 166) --->
<!--- Last Updated: 2010-12-12 --->
<!--- Created by Steve Bryant 2004-12-08 --->
<cfcomponent extends="DataMgr" displayname="Data Manager for MS Access" hint="I manage data interactions with the MS Access database.">

<cffunction name="getDatabase" access="public" returntype="string" output="no" hint="I return the database platform being used (Access,MS SQL,MySQL etc).">
	<cfreturn "Access">
</cffunction>

<cffunction name="getDatabaseShortString" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "Access">
</cffunction>

<cffunction name="getDatabaseDriver" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "MSAccessJet">
</cffunction>

<cffunction name="sqlCreateColumn" access="public" returntype="any" output="false" hint="">
	<cfargument name="field" type="struct" required="yes">
	
	<cfset var sField = adjustColumnArgs(arguments.field)>
	<cfset var type = getDBDataType(sField.CF_DataType)>
	<cfset var result = "">
	
	<cfsavecontent variable="result"><cfoutput>#escape(sField.ColumnName)# <cfif sField.Increment>COUNTER<cfelseif getTypeOfCFType(sField.CF_DataType) EQ "numeric"><!---  AND StructKeyExists(sField,"scale") AND sField.scale GT 0 ---> float<cfelse>#getDBDataType(sField.CF_DataType)#</cfif><cfif isStringType(type)>(#Min(sField.Length,255)#)</cfif> <cfif sField.PrimaryKey OR NOT sField.AllowNulls>NOT </cfif>NULL</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

<cffunction name="addColumn" access="public" returntype="any" output="no" hint="I add a column to the given table">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table to which a column will be added.">
	<cfargument name="ColumnName" type="string" required="yes" hint="The name of the column to add.">
	<cfargument name="CF_Datatype" type="string" required="yes" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Length" type="numeric" default="50" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Default" type="string" required="no" hint="The default value for the column.">
	
	<cfset var type = getDBDataType(arguments.CF_Datatype)>
	<cfset var sql = "">
	<cfset var FailedSQL = "">
	
	<cfsavecontent variable="sql"><cfoutput>ALTER TABLE #escape(arguments.tablename)# ADD #sqlCreateColumn(arguments)#</cfoutput></cfsavecontent>
	
	<cftry>
		<cfset runSQL(sql)>
		<cfcatch>
			<cfset FailedSQL = ListAppend(FailedSQL,sql,";")>
		</cfcatch>
	</cftry>
	
	<cfif StructKeyExists(arguments,"Default") AND Len(Trim(arguments.Default))>
		<cfsavecontent variable="sql"><cfoutput>UPDATE	#escape(arguments.tablename)#	SET	#escape(arguments.columnname)# = #arguments.Default#</cfoutput></cfsavecontent>
	
		<cftry>
			<cfset runSQL(sql)>
			<cfcatch>
				<cfset FailedSQL = ListAppend(FailedSQL,sql,";")>
			</cfcatch>
		</cftry>
	</cfif>
	
	<cfif Len(FailedSQL)>
		<cfthrow message="Failed to add Column (""#arguments.ColumnName#"")." type="DataMgr" detail="#FailedSQL#">
	</cfif>
	
</cffunction>

<cffunction name="dbtableexists" access="public" returntype="boolean" output="no" hint="I indicate whether or not the given table exists in the database">
	<cfargument name="tablename" type="string" required="true">
	<cfargument name="dbtables" type="string" default="">
	
	<cfset var result = false>
	
	<cfif NOT ( StructKeyExists(arguments,"dbtables") AND Len(Trim(arguments.dbtables)) )>
		<cfset arguments.dbtables = "">
		<cftry><!--- Try to get a list of tables load in DataMgr --->
			<cfset arguments.dbtables = getDatabaseTables()>
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
	<!--- SEB 2010-05-07: Looks like it is needed for MS Access --->
	<cfif NOT result>
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

<cffunction name="getCreateSQL" access="public" returntype="string" output="no" hint="I return the SQL to create the given table.">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table to create.">
	
	<cfset var ii = 0><!--- generic counter --->
	<cfset var arrFields = getFields(arguments.tablename)><!--- structure of table --->
	<cfset var CreateSQL = ""><!--- holds sql used for creation, allows us to return it in an error --->
	<cfset var pkfields = ""><!--- primary key fields --->
	<cfset var thisField = ""><!--- current field holder --->
	
	<!--- Find Primary Key fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(arrFields)#" step="1">
		<cfif arrFields[ii].PrimaryKey>
			<cfset pkfields = ListAppend(pkfields,arrFields[ii].ColumnName)>
		</cfif>
	</cfloop>
	
	<!--- create the sql to create the table --->
	<cfsavecontent variable="CreateSQL"><cfoutput>
	CREATE TABLE #escape(arguments.tablename)# (<cfloop index="ii" from="1" to="#ArrayLen(arrFields)#" step="1">
		#sqlCreateColumn(arrFields[ii])#<cfif ii LT ArrayLen(arrFields)> ,</cfif></cfloop>
		<cfif Len(pkfields)>,
		CONSTRAINT [PK_#tablename#] PRIMARY KEY 
		(<cfloop index="ii" from="1" to="#ListLen(pkfields)#" step="1"><cfset thisField = ListGetAt(pkfields,ii)>
			#thisField#<cfif ii lt ListLen(pkfields)>,</cfif></cfloop>
		)
		</cfif>
	)<!--- <cfif Len(pkfields)> ON [PRIMARY]</cfif> --->
	</cfoutput></cfsavecontent>
	
	<cfreturn CreateSQL>
</cffunction>

<cffunction name="getNewSortNum" access="public" returntype="numeric" output="no" hint="I get the value an increment higher than the highest value in the given field to put a record at the end of the sort order.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="sortfield" type="string" required="yes" hint="The field holding the sort order.">
	
	<cfset var qLast = 0>
	<cfset var result = 0>
	
	<cfset qLast = runSQL("SELECT TOP 1 #escape(arguments.sortfield)# FROM #escape(arguments.tablename)#")>
	
	<cfif qLast.RecordCount and isNumeric(qLast[arguments.sortfield][1])>
		<cfset result = qLast[arguments.sortfield][1] + 1>
	<cfelse>
		<cfset result = 1>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="concat" access="public" returntype="string" output="no" hint="I return the SQL to concatenate the given fields with the given delimeter.">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="delimeter" type="string" default="">
	
	<cfset var colname = "">
	<cfset var result = "">
	
	<cfloop index="colname" list="#arguments.fields#">
		<cfif Len(result)>
			<cfset result =  "#result# & '#arguments.delimeter#' & CSTR(#colname#)">
		<cfelse>
			<cfset result = "CSTR(#colname#)">
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
			<cfset ArrayAppend(aSQL," & '#arguments.delimeter#' & ")>
		</cfif>
		<cfif isSimpleValue(fieldSQL)>
			<cfset ArrayAppend(aSQL,"CSTR(#fieldSQL#)")>
		<cfelse>
			<cfset ArrayAppend(aSQL,"CSTR(")>
			<cfset ArrayAppend(aSQL,fieldSQL)>
			<cfset ArrayAppend(aSQL,")")>
		</cfif>
	</cfloop>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="escape" access="public" returntype="string" output="no" hint="I return an escaped value for a table or field.">
	<cfargument name="name" type="string" required="yes">
	
	<cfset var result = "">
	<cfset var item = "">
	
	<cfloop index="item" list="#arguments.name#" delimiters=".">
		<cfset result = ListAppend(result,"[#item#]",".")>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getDatabaseTables" access="public" returntype="string" output="yes" hint="I get a list of all tables in the current database.">

	<cfset var qTables = 0>
	
	<cftry>
		<cfset qTables = runSQL("SELECT Name FROM MSysObjects WHERE Type = 1 AND Flags = 0")>
		<cfcatch>
			<cfif cfcatch.detail CONTAINS "no read permission">
				<cfthrow message="Your Access database doesn't have appropriate permissions to use tables without loading them via loadXML()." type="DataMgr" detail="In order to allow this method, open your database using MS Access and check the 'System objects' box under Tools/Options/View. You may also need to make sure 'Read Data' is checked for every table in Tools/Security/User and Group Permissions.">
			<cfelse>
				<cfrethrow>
			</cfif>
		</cfcatch>
	</cftry>
	
	<cfreturn ValueList(qTables.Name)>
</cffunction>

<cffunction name="getDBTableStruct" access="public" returntype="array" output="no" hint="I return the structure of the given table in the database.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfscript>
	var qRawFetch = 0;
	var arrStructure = 0;
	var sField = StructNew();
	var ii = 0;

	var PrimaryKeys = 0;
	var TableData = ArrayNew(1);
	</cfscript>
	
	<cfset qRawFetch = runSQL("SELECT TOP 1 * FROM #arguments.tablename#")>
	<cfset arrStructure = getMetaData(qRawFetch)>
	
	<cfif isArray(arrStructure)>
		<cfloop index="ii" from="1" to="#ArrayLen(arrStructure)#" step="1">
			<cfset sField = StructNew()>
			<cfset sField["ColumnName"] = arrStructure[ii].Name>
			<cfset sField["CF_DataType"] = getCFDataType(arrStructure[ii].TypeName)>
			<!--- %% Ugly guess --->
			<cfif arrStructure[ii].TypeName eq "COUNTER" OR ( ii EQ 1 AND arrStructure[ii].TypeName EQ "INT" AND Right(arrStructure[ii].Name,2) EQ "ID" )>
				<cfset sField["PrimaryKey"] = true>
				<cfset sField["Increment"] = true>
				<cfset sField["AllowNulls"] = false>
			</cfif>
			<!--- %% Ugly guess --->
			<cfif isStringType(arrStructure[ii].TypeName) AND NOT sField["CF_DataType"] EQ "CF_SQL_LONGVARCHAR">
				<cfset sField["length"] = 255>
			</cfif>
			
			<cfif Len(sField.CF_DataType)>
				<cfset ArrayAppend(TableData,adjustColumnArgs(sField))>
			</cfif>
		</cfloop>
	<cfelse>
		<cfthrow message="DataMgr can currently only support MS Access on ColdFusion MX 7 and above unless tables are loaded using loadXML(). Sorry for the trouble." type="DataMgr" detail="NoMSAccesSupport">
	</cfif>
	
	<cfreturn TableData>
</cffunction>

<cffunction name="getCFDataType" access="public" returntype="string" output="no" hint="I return the cfqueryparam datatype from the database datatype.">
	<cfargument name="type" type="string" required="yes" hint="The database data type.">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.type#">
		<cfcase value="binary,image"><cfthrow message="DataMgr object cannot handle this data type." type="DataMgr" detail="DataMgr cannot handle data type '#arguments.type#'" errorcode="InvalidDataType"></cfcase>
		<cfcase value="bit"><cfset result = "CF_SQL_BIT"></cfcase>
		<cfcase value="char,varchar"><cfset result = "CF_SQL_VARCHAR"></cfcase>
		<cfcase value="counter"><cfset result = "CF_SQL_INTEGER"></cfcase>
		<cfcase value="datetime"><cfset result = "CF_SQL_DATE"></cfcase>
		<cfcase value="decimal"><cfset result = "CF_SQL_DECIMAL"></cfcase>
		<cfcase value="double"><cfset result = "CF_SQL_DOUBLE"></cfcase>
		<cfcase value="float"><cfset result = "CF_SQL_FLOAT"></cfcase>
		<cfcase value="int,integer"><cfset result = "CF_SQL_INTEGER"></cfcase>
		<cfcase value="longchar"><cfset result = "CF_SQL_LONGVARCHAR"></cfcase>
		<cfcase value="memo,text"><cfset result = "CF_SQL_CLOB"></cfcase>
		<cfcase value="money"><cfset result = "CF_SQL_MONEY"></cfcase>
		<cfcase value="real"><cfset result = "CF_SQL_REAL"></cfcase>
		<cfcase value="smallint"><cfset result = "CF_SQL_SMALLINT"></cfcase>
		<cfcase value="tinyint"><cfset result = "CF_SQL_TINYINT"></cfcase>
		<cfcase value="uniqueidentifier"><cfset result = "CF_SQL_IDSTAMP"></cfcase>
		<cfdefaultcase><cfset result = ""></cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getDBDataType" access="public" returntype="string" output="no" hint="I return the database datatype from the cfqueryparam datatype.">
	<cfargument name="CF_Datatype" type="string" required="yes">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.CF_Datatype#">
		<cfcase value="CF_SQL_BIGINT"><cfset result = "integer"></cfcase>
		<cfcase value="CF_SQL_BIT"><cfset result = "bit"></cfcase>
		<cfcase value="CF_SQL_CHAR"><cfset result = "char"></cfcase>
		<cfcase value="CF_SQL_DATE"><cfset result = "datetime"></cfcase>
		<cfcase value="CF_SQL_DECIMAL"><cfset result = "decimal"></cfcase>
		<cfcase value="CF_SQL_DOUBLE"><cfset result = "double"></cfcase>
		<cfcase value="CF_SQL_FLOAT"><cfset result = "float"></cfcase>
		<cfcase value="CF_SQL_IDSTAMP"><cfset result = "uniqueidentifier"></cfcase>
		<cfcase value="CF_SQL_INTEGER"><cfset result = "integer"></cfcase>
		<cfcase value="CF_SQL_CLOB,CF_SQL_LONGVARCHAR"><cfset result = "memo"></cfcase>
		<cfcase value="CF_SQL_MONEY"><cfset result = "money"></cfcase>
		<cfcase value="CF_SQL_MONEY4"><cfset result = "money"></cfcase>
		<cfcase value="CF_SQL_NUMERIC"><cfset result = "float"></cfcase>
		<cfcase value="CF_SQL_REAL"><cfset result = "real"></cfcase>
		<cfcase value="CF_SQL_SMALLINT"><cfset result = "smallint"></cfcase>
		<cfcase value="CF_SQL_TINYINT"><cfset result = "tinyint"></cfcase>
		<cfcase value="CF_SQL_VARCHAR"><cfset result = "varchar"></cfcase>
		<cfdefaultcase><cfthrow message="DataMgr object cannot handle this data type." type="DataMgr" detail="DataMgr cannot handle data type '#arguments.CF_Datatype#'" errorcode="InvalidDataType"></cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getNowSQL" access="public" returntype="string" output="no" hint="I return the SQL for the current date/time.">
	<cfreturn "Now()">
</cffunction>

<cffunction name="loadXML" access="public" returntype="void" output="false" hint="I add table/tables from XML and optionally create tables/columns as needed (I can also load data to a table upon its creation).">
	<cfargument name="xmldata" type="string" required="yes" hint="XML data of tables to load into DataMgr follows. Schema: http://www.bryantwebconsulting.com/cfc/DataMgr.xsd">
	<cfargument name="docreate" type="boolean" default="false" hint="I indicate if the table should be created in the database if it doesn't already exist.">
	<cfargument name="addcolumns" type="boolean" default="false" hint="I indicate if missing columns should be be created.">
	
	<cfset var table = "">
	<cfset var i = 0>
	<cfset var tabledata = 0>
	<cfset var fields = 0>
	
	<cfset super.loadXML(xmldata,docreate,addcolumns)>
	
	<cfset tabledata = getTableData()>
	
	<cfloop collection="#tabledata#" item="table">
		<cfset fields = getFields(table)>
		<cfloop index="i" from="1" to="#ArrayLen(fields)#" step="1">
			<cfif fields[i]["CF_DataType"] eq "CF_SQL_LONGVARCHAR">
				<cfset fields[i]["CF_DataType"] = "CF_SQL_CLOB">
			</cfif>
		</cfloop>
	</cfloop>
	
</cffunction>

<cffunction name="checkTable" access="private" returntype="boolean" output="no" hint="I check to see if the given table exists in the Datamgr.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfif NOT StructKeyExists(variables.tables,arguments.tablename)>
		<cfset loadTable(arguments.tablename)>
	</cfif>
	
	<cfreturn true>
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
	
	<cfset ArrayAppend(aSQL,"ABS(")>
	
	<cfswitch expression="#dtype#">
	<cfcase value="numeric">
		<cfset ArrayAppend(aSQL,"IIF(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL," > 0,1,0)")>
	</cfcase>
	<cfcase value="string">
		<cfset ArrayAppend(aSQL,"IIF(Len(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,") IS NULL,0,1) > 0")>
	</cfcase>
	<cfcase value="date">
		<cfset ArrayAppend(aSQL,"IIF(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL," IS NULL,0,1)")>
	</cfcase>
	<cfcase value="boolean">
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
	</cfcase>
	</cfswitch>
	
	<cfset ArrayAppend(aSQL,")")>
	
	<cfreturn aSQL>	
</cffunction>

<cffunction name="getInsertedIdentity" access="private" returntype="string" output="no" hint="I get the value of the identity field that was just inserted into the given table.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="identfield" type="string" required="yes">
	
	<cfset var qCheckKey = 0>
	<cfset var result = 0>
	
	<cfset qCheckKey = runSQL("SELECT TOP 1 #identfield# AS NewID FROM #arguments.tablename# ORDER BY #identfield# DESC")>
	
	<cfset result = qCheckKey.NewID>
	
	<cfreturn result>
</cffunction>

<cffunction name="getOrderbyFieldList" access="private" returntype="array" output="no">
	
	<cfset var adjustedfieldlist = "">
	<cfset var orderarray = ArrayNew(1)>
	<cfset var temp = "">
	<cfset var sqlarray = ArrayNew(1)>
	
	<cfif Len(arguments.fieldlist)>
		<cfloop list="#arguments.fieldlist#" index="temp">
			<cfset adjustedfieldlist = ListAppend(adjustedfieldlist,escape(arguments.tablealias & '.' & temp))>
			<cfif ArrayLen(orderarray) GT 0>
				<cfset ArrayAppend(orderarray,",")>
			</cfif>
			<cfset ArrayAppend(orderarray,getFieldSelectSQL(tablename=arguments.tablename,field=temp,tablealias=arguments.tablealias,useFieldAlias=false))>
		</cfloop>
	</cfif>

	<cfif Len(arguments.function)>
		<cfset ArrayAppend(sqlarray,adjustedfieldlist)>
	<cfelse>
		<cfset ArrayAppend(sqlarray,"#escape(arguments.fieldlist)#")>
	</cfif>
	
	<cfreturn sqlarray>
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

<cffunction name="seedIndex" access="private" returntype="void" output="no" hint="No way to get index meta data from MS Access, so I do nothin.">
	<cfargument name="indexname" type="string" required="yes">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="unique" type="boolean" default="false">
	<cfargument name="clustered" type="boolean" default="false">
	
</cffunction>

</cfcomponent>